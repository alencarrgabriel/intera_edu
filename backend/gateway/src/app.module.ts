import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { RedisModule } from '@interaedu/shared';
import { ProxyModule } from './proxy/proxy.module';
import { HealthController } from './health.controller';
import { PathAwareThrottlerGuard } from './throttling/path-aware-throttler.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60000,   // 1 minute
        limit: 100,   // 100 req/min por IP em rotas não-auth
      },
      // Throttler estrito também precisa estar definido para que o guard
      // possa diferenciar o bucket — efetivamente sobrescrito pela lógica
      // do PathAwareThrottlerGuard para chegar em 10 req/min em /auth/*.
      {
        name: 'auth',
        ttl: 60000,
        limit: 10,
      },
    ]),
    RedisModule,
    ProxyModule,
  ],
  controllers: [HealthController],
  providers: [
    { provide: APP_GUARD, useClass: PathAwareThrottlerGuard },
  ],
})
export class AppModule {}
