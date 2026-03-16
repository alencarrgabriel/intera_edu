import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OtpService } from './otp.service';

@Module({
  imports: [],
  providers: [OtpService],
  exports: [OtpService],
})
export class OtpModule {}
