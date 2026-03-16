import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule } from '@interaedu/shared';
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
})
export class AppModule {}
