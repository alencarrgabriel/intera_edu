import {
  Injectable,
  Logger,
  ForbiddenException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { OAuth2Client, TokenPayload } from 'google-auth-library';
import { UserCredential } from '../database/entities/user-credential.entity';
import { RefreshToken } from '../database/entities/refresh-token.entity';
import { InstitutionService } from '../institution/institution.service';
import { JwtPayload, RedisService } from '@interaedu/shared';

const EVENTS_CHANNEL = 'interaedu.events';

/**
 * Lida com login/registro via Google Identity Services.
 *
 * Fluxo:
 *   1. Front-end obtém um ID Token do Google (GIS, `credential` em `CredentialResponse`).
 *   2. POST `/auth/google { id_token }`
 *   3. Aqui verificamos a assinatura com as chaves públicas do Google
 *      e a claim `aud` contra o nosso CLIENT_ID.
 *   4. Validamos o domínio do e-mail contra a tabela de instituições.
 *   5. Find-or-create do `UserCredential` (vinculando `googleId`).
 *   6. Para novo usuário, publicamos `user.registered` no Redis para que
 *      o profile-service crie o perfil base.
 *   7. Devolvemos o par de JWT (access + refresh) com a mesma estrutura
 *      de `AuthService.login()`.
 */
@Injectable()
export class GoogleAuthService {
  private readonly logger = new Logger(GoogleAuthService.name);
  private readonly client: OAuth2Client | null;
  private readonly clientId: string | undefined;

  constructor(
    @InjectRepository(UserCredential)
    private readonly userRepo: Repository<UserCredential>,
    @InjectRepository(RefreshToken)
    private readonly refreshTokenRepo: Repository<RefreshToken>,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly institutionService: InstitutionService,
    private readonly redis: RedisService,
  ) {
    this.clientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    this.client = this.clientId ? new OAuth2Client(this.clientId) : null;
    if (!this.client) {
      this.logger.warn(
        'GOOGLE_CLIENT_ID não configurado — endpoint /auth/google ficará indisponível.',
      );
    }
  }

  async loginWithGoogle(idToken: string) {
    if (!this.client || !this.clientId) {
      throw new ServiceUnavailableException(
        'Login com Google não está configurado neste ambiente.',
      );
    }
    if (!idToken) {
      throw new UnauthorizedException('id_token é obrigatório');
    }

    // 1. Verifica assinatura + audience contra o CLIENT_ID configurado
    let payload: TokenPayload | undefined;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.clientId,
      });
      payload = ticket.getPayload();
    } catch (e) {
      this.logger.warn(`ID token inválido: ${String(e)}`);
      throw new UnauthorizedException('ID token Google inválido');
    }
    if (!payload || !payload.email || !payload.sub) {
      throw new UnauthorizedException('ID token sem email/sub');
    }
    if (payload.email_verified === false) {
      throw new UnauthorizedException('E-mail Google não verificado');
    }

    const email = payload.email.toLowerCase();
    const googleId = payload.sub;

    // 2. Domínio precisa pertencer a uma instituição aprovada
    const institution = await this.institutionService.findByEmailDomain(email);
    if (!institution) {
      throw new ForbiddenException(
        'Domínio de e-mail não pertence a uma instituição aprovada.',
      );
    }

    // 3. Find by googleId or email — vincula se necessário
    let user = await this.userRepo.findOne({ where: { googleId } });
    let isNewUser = false;
    if (!user) {
      user = await this.userRepo.findOne({ where: { email } });
      if (user) {
        // Conta já existia com senha local — vincula a identidade Google
        user.googleId = googleId;
        await this.userRepo.save(user);
      } else {
        // Cria conta nova sem senha (somente OAuth)
        user = this.userRepo.create({
          email,
          passwordHash: null,
          googleId,
          institutionId: institution.id,
          status: 'active',
        });
        await this.userRepo.save(user);
        isNewUser = true;

        // Avisa o profile-service para criar o perfil base
        await this.redis.publish(
          EVENTS_CHANNEL,
          JSON.stringify({
            type: 'user.registered',
            payload: {
              userId: user.id,
              email: user.email,
              institutionId: institution.id,
              institutionName: institution.name,
              source: 'google',
            },
            occurredAt: new Date().toISOString(),
          }),
        );
        this.logger.log(`Usuário registrado via Google: ${user.id} (${email})`);
      }
    }

    user.lastLoginAt = new Date();
    await this.userRepo.save(user);

    const tokens = await this.issueTokens(user, institution.id);

    return {
      user: {
        id: user.id,
        email: user.email,
        institution: { id: institution.id, name: institution.name },
        new_user: isNewUser,
      },
      tokens,
    };
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

    const tokenHash = await bcrypt.hash(refreshToken, 10);
    await this.refreshTokenRepo.save({
      userId: user.id,
      tokenHash,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: 900,
    };
  }
}
