import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { RedisModule } from '@interaedu/shared';
import { ProxyModule } from './proxy/proxy.module';
import { HealthController } from './health.controller';
import { PathAwareThrottlerGuard } from './throttling/path-aware-throttler.guard';
import { MetricsModule } from './metrics/metrics.module';
import { MetricsMiddleware } from './metrics/metrics.middleware';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60000,   // 1 minute
        // 600 req/min em demo (10 req/s) — o app faz muitos GETs em paralelo
        // ao navegar entre Feed/Perfil/Conexões. Em produção, voltar p/ 100.
        limit: 600,
      },
      {
        name: 'auth',
        ttl: 60000,
        limit: 50,
      },
    ]),
    RedisModule,
    ProxyModule,
    MetricsModule,
  ],
  controllers: [HealthController],
  providers: [
    { provide: APP_GUARD, useClass: PathAwareThrottlerGuard },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    // Instala o histograma de duração em todas as rotas.
    consumer.apply(MetricsMiddleware).forRoutes('*');
  }
}
