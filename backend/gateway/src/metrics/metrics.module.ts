import { Module } from '@nestjs/common';
import {
  PrometheusModule,
  makeHistogramProvider,
} from '@willsoto/nestjs-prometheus';
import { MetricsMiddleware } from './metrics.middleware';

/**
 * Expõe `/metrics` (Prometheus format) e instala um middleware que
 * preenche o histograma `http_request_duration_seconds` com método,
 * rota e status_code de cada requisição.
 *
 * Configurado para o gateway primeiro (B-06). Demais serviços podem
 * espelhar este módulo conforme forem ganhando instrumentação.
 */
const httpDurationHistogram = makeHistogramProvider({
  name: 'http_request_duration_seconds',
  help: 'Duração das requisições HTTP em segundos (gateway)',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
});

@Module({
  imports: [
    PrometheusModule.register({
      defaultMetrics: { enabled: true },
      // O caminho default `/metrics` já é prefixado pelo `setGlobalPrefix`
      // do main.ts, resultando em /api/v1/metrics.
    }),
  ],
  providers: [MetricsMiddleware, httpDurationHistogram],
  // Exporta histograma e PrometheusModule para que o AppModule consiga
  // resolver as dependências do MetricsMiddleware quando ele é aplicado
  // globalmente via configure(consumer).
  exports: [MetricsMiddleware, httpDurationHistogram, PrometheusModule],
})
export class MetricsModule {}
