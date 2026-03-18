import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule, JwtAuthGuard } from '@interaedu/shared';
import { AuthModule } from './auth/auth.module';
import { OtpModule } from './otp/otp.module';
import { InstitutionModule } from './institution/institution.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    RedisModule,
    AuthModule,
    OtpModule,
    InstitutionModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
