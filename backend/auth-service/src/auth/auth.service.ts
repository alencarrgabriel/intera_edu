import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { UserCredential } from '../database/entities/user-credential.entity';
import { RefreshToken } from '../database/entities/refresh-token.entity';
import { ConsentRecord } from '../database/entities/consent-record.entity';
import { OtpService } from '../otp/otp.service';
import { InstitutionService } from '../institution/institution.service';
import { RegisterDto } from './dto/register.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { CompleteRegistrationDto } from './dto/complete-registration.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtPayload, RedisService } from '@interaedu/shared';

const BCRYPT_ROUNDS = 12;
const EVENTS_CHANNEL = 'interaedu.events';

/// RN-09 — Versões correntes dos termos legais. Quando incrementadas,
/// o login retorna `requires_consent_update=true` e o app força o aceite
/// antes de prosseguir.
export const CURRENT_TERMS_VERSION = 'v1.0';
export const CURRENT_PRIVACY_VERSION = 'v1.0';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(UserCredential)
    private readonly userRepo: Repository<UserCredential>,
    @InjectRepository(RefreshToken)
    private readonly refreshTokenRepo: Repository<RefreshToken>,
    @InjectRepository(ConsentRecord)
    private readonly consentRepo: Repository<ConsentRecord>,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly otpService: OtpService,
    private readonly institutionService: InstitutionService,
    private readonly redis: RedisService,
  ) {}

  async register(dto: RegisterDto) {
    // 1. Validate email domain against approved institutions
    const institution = await this.institutionService.findByEmailDomain(dto.email);
    if (!institution) {
      throw new ForbiddenException('Email domain is not an approved educational institution.');
    }

    // 2. Check if email already registered
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('An account with this email already exists.');
    }

    // 3. Generate and send OTP
    await this.otpService.generateAndSend(dto.email, 'registration');

    return {
      message: 'OTP sent to your institutional email',
      expires_in_seconds: 600,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    // Verify OTP code
    const valid = await this.otpService.verify(dto.email, dto.code, 'registration');
    if (!valid) {
      throw new UnauthorizedException('Invalid or expired OTP code.');
    }

    // Issue temporary token for completing registration
    const tempToken = this.jwtService.sign(
      { email: dto.email, purpose: 'registration' },
      { expiresIn: '15m' },
    );

    return {
      temporary_token: tempToken,
      expires_in_seconds: 900,
    };
  }

  async completeRegistration(dto: CompleteRegistrationDto) {
    // 1. Verify temporary token
    let tokenPayload: { email: string; purpose: string };
    try {
      tokenPayload = this.jwtService.verify(dto.temporary_token);
    } catch {
      throw new UnauthorizedException('Invalid or expired registration token.');
    }

    if (tokenPayload.purpose !== 'registration') {
      throw new UnauthorizedException('Invalid token purpose.');
    }

    // 2. Find institution
    const institution = await this.institutionService.findByEmailDomain(tokenPayload.email);
    if (!institution) {
      throw new ForbiddenException('Institution not found.');
    }

    // 3. Hash password
    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);

    // 4. Create user credential
    const user = this.userRepo.create({
      email: tokenPayload.email,
      passwordHash,
      institutionId: institution.id,
      status: 'active',
    });
    await this.userRepo.save(user);

    // 5. Record consent
    await this.consentRepo.save({
      userId: user.id,
      consentType: 'terms_of_service',
      version: dto.consent.terms_version,
    });
    await this.consentRepo.save({
      userId: user.id,
      consentType: 'privacy_policy',
      version: dto.consent.privacy_version,
    });

    // 6. Issue JWT pair
    const tokens = await this.issueTokens(user, institution.id);

    this.logger.log(`User registered: ${user.id} (${user.email})`);

    await this.redis.publish(
      EVENTS_CHANNEL,
      JSON.stringify({
        type: 'user.registered',
        payload: {
          userId: user.id,
          email: user.email,
          institutionId: institution.id,
        },
        occurredAt: new Date().toISOString(),
      }),
    );

    return {
      user: {
        id: user.id,
        email: user.email,
        institution: {
          id: institution.id,
          name: institution.name,
        },
      },
      tokens,
    };
  }

  async login(dto: LoginDto) {
    // 1. Find user
    const user = await this.userRepo.findOne({ where: { email: dto.email, status: 'active' } });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    // 2. Verify password (contas só-OAuth não têm hash local)
    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'Esta conta foi criada via Google. Use "Continuar com Google" para entrar.',
      );
    }
    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    // 3. Update last login
    user.lastLoginAt = new Date();
    await this.userRepo.save(user);

    // 4. Issue tokens
    const tokens = await this.issueTokens(user, user.institutionId);

    // 5. RN-09 — Checa se o usuário precisa reaceitar termos atualizados.
    const requiresConsentUpdate = await this.needsConsentUpdate(user.id);

    return { tokens, requires_consent_update: requiresConsentUpdate };
  }

  /// RN-09 — Retorna `true` se a última versão aceita pelo usuário é
  /// diferente da `CURRENT_TERMS_VERSION` ou `CURRENT_PRIVACY_VERSION`.
  async needsConsentUpdate(userId: string): Promise<boolean> {
    const latest = await this.consentRepo.find({
      where: { userId },
      order: { acceptedAt: 'DESC' },
      take: 10,
    });
    const acceptedTerms = latest.find(
      (c) => c.consentType === 'terms_of_service' && !c.revokedAt,
    );
    const acceptedPrivacy = latest.find(
      (c) => c.consentType === 'privacy_policy' && !c.revokedAt,
    );
    return (
      acceptedTerms?.version !== CURRENT_TERMS_VERSION ||
      acceptedPrivacy?.version !== CURRENT_PRIVACY_VERSION
    );
  }

  /// RN-09 — Registra novo aceite após mudança de termos.
  async acceptTerms(userId: string) {
    await this.consentRepo.save({
      userId,
      consentType: 'terms_of_service',
      version: CURRENT_TERMS_VERSION,
    });
    await this.consentRepo.save({
      userId,
      consentType: 'privacy_policy',
      version: CURRENT_PRIVACY_VERSION,
    });
    return { ok: true };
  }

  /// RF-32 — Revoga consentimento e dispara exclusão. Em produção isso
  /// notifica o profile-service via evento; aqui apenas marca e cliente
  /// chama DELETE /users/me em seguida.
  async revokeConsent(userId: string) {
    const records = await this.consentRepo.find({
      where: { userId, revokedAt: IsNull() },
    });
    const now = new Date();
    for (const r of records) {
      r.revokedAt = now;
    }
    await this.consentRepo.save(records);

    await this.redis.publish(
      EVENTS_CHANNEL,
      JSON.stringify({
        type: 'user.consent_revoked',
        payload: { userId, revokedAt: now.toISOString() },
        occurredAt: now.toISOString(),
      }),
    );

    return {
      message:
        'Consentimento revogado. A conta será excluída e os dados anonimizados conforme a LGPD.',
    };
  }

  /// RF-06 — Inicia recuperação de senha enviando OTP para o e-mail.
  async forgotPassword(email: string) {
    // Não revela se o e-mail existe (anti-enumeração).
    const user = await this.userRepo.findOne({ where: { email, status: 'active' } });
    if (user) {
      await this.otpService.generateAndSend(email, 'password_reset');
    }
    return { message: 'Se o e-mail existir, um código foi enviado.', expires_in_seconds: 600 };
  }

  /// RF-06 — Confirma OTP e redefine senha; revoga refresh tokens existentes.
  async resetPassword(email: string, code: string, newPassword: string) {
    const valid = await this.otpService.verify(email, code, 'password_reset');
    if (!valid) throw new UnauthorizedException('Código inválido ou expirado.');

    const user = await this.userRepo.findOne({ where: { email, status: 'active' } });
    if (!user) throw new UnauthorizedException('Usuário não encontrado.');

    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await this.userRepo.save(user);

    // Invalida todas as sessões ativas — força re-login.
    await this.refreshTokenRepo.update(
      { userId: user.id, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );

    return { message: 'Senha redefinida com sucesso.' };
  }

  async refreshToken(dto: RefreshTokenDto) {
    // 1. Verify refresh token
    let payload: JwtPayload;
    try {
      payload = this.jwtService.verify(dto.refresh_token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token.');
    }

    // 2. Check if this refresh token matches any active stored token for the user
    const activeTokens = await this.refreshTokenRepo.find({
      where: { userId: payload.sub, revokedAt: IsNull() },
      order: { createdAt: 'DESC' },
      take: 20,
    });

    const matched = await this.findMatchingRefreshToken(activeTokens, dto.refresh_token);
    if (!matched) {
      // Potential replay/forgery — revoke the whole token family for the user
      await this.refreshTokenRepo.update({ userId: payload.sub }, { revokedAt: new Date() });
      throw new UnauthorizedException('Refresh token has been revoked.');
    }

    // 3. Revoke the matched refresh token (rotation)
    matched.revokedAt = new Date();
    await this.refreshTokenRepo.save(matched);

    // 4. Find user and issue new tokens
    const user = await this.userRepo.findOneOrFail({ where: { id: payload.sub } });
    return { tokens: await this.issueTokens(user, user.institutionId) };
  }

  async logout(dto: RefreshTokenDto) {
    // Revoke the refresh token
    try {
      const payload = this.jwtService.verify(dto.refresh_token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
      await this.refreshTokenRepo.update(
        { userId: payload.sub },
        { revokedAt: new Date() },
      );
    } catch {
      // Token already expired or invalid — no action needed
    }
  }

  private async issueTokens(user: UserCredential, institutionId: string) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      institution_id: institutionId,
      roles: ['user'],
    };

    const accessToken = this.jwtService.sign(payload);

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRATION', '7d'),
    });

    // Store refresh token as a hash (never store the raw token)
    const tokenHash = await bcrypt.hash(refreshToken, 10);
    await this.refreshTokenRepo.save({
      userId: user.id,
      tokenHash,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: 900, // 15 minutes in seconds
    };
  }

  private async findMatchingRefreshToken(tokens: RefreshToken[], rawToken: string) {
    for (const token of tokens) {
      try {
        const ok = await bcrypt.compare(rawToken, token.tokenHash);
        if (ok) return token;
      } catch {
        // ignore malformed hashes
      }
    }
    return null;
  }
}
