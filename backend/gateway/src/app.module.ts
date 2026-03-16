import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { RedisModule } from '@interaedu/shared';
import { ProxyModule } from './proxy/proxy.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 60000,   // 1 minute
        limit: 100,   // 100 requests per minute
      },
      {
        name: 'long',
        ttl: 3600000,  // 1 hour
        limit: 1000,   // 1000 requests per hour
      },
    ]),
    RedisModule,
    ProxyModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
