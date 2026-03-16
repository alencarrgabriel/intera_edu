import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UserCredential } from '../database/entities/user-credential.entity';
import { RefreshToken } from '../database/entities/refresh-token.entity';
import { ConsentRecord } from '../database/entities/consent-record.entity';
import { OtpModule } from '../otp/otp.module';
import { InstitutionModule } from '../institution/institution.module';
import { JwtStrategy } from '@interaedu/shared';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: config.get<string>('JWT_ACCESS_EXPIRATION', '15m'),
          issuer: 'interaedu-auth',
        },
      }),
    }),
    TypeOrmModule.forFeature([UserCredential, RefreshToken, ConsentRecord]),
    OtpModule,
    InstitutionModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
