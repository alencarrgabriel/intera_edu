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
import { Repository } from 'typeorm';
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
import { JwtPayload } from '@interaedu/shared';

const BCRYPT_ROUNDS = 12;

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

    // TODO: Emit 'user.registered' event for Profile Service

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

    // 2. Verify password
    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    // 3. Update last login
    user.lastLoginAt = new Date();
    await this.userRepo.save(user);

    // 4. Issue tokens
    const tokens = await this.issueTokens(user, user.institutionId);

    return { tokens };
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

    // 2. Check if token is in the database and not revoked
    const storedToken = await this.refreshTokenRepo.findOne({
      where: { userId: payload.sub },
    });

    if (!storedToken || storedToken.revokedAt) {
      // Potential replay attack — revoke all tokens for this user
      await this.refreshTokenRepo.update(
        { userId: payload.sub },
        { revokedAt: new Date() },
      );
      throw new UnauthorizedException('Refresh token has been revoked.');
    }

    // 3. Revoke old refresh token
    storedToken.revokedAt = new Date();
    await this.refreshTokenRepo.save(storedToken);

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

    // Store refresh token
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
}
