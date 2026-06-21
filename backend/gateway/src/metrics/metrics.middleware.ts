import { Injectable, NestMiddleware } from '@nestjs/common';
import { InjectMetric } from '@willsoto/nestjs-prometheus';
import { Histogram } from 'prom-client';
import { Request, Response, NextFunction } from 'express';

/**
 * Mede o tempo de resposta de cada requisição e popula o histograma
 * `http_request_duration_seconds` com labels {method, route, status_code}.
 *
 * "route" é o template do path (ex.: `/api/v1/users/me/avatar`) — não o URL
 * completo, para evitar explosão de cardinalidade.
 */
@Injectable()
export class MetricsMiddleware implements NestMiddleware {
  constructor(
    @InjectMetric('http_request_duration_seconds')
    private readonly histogram: Histogram<string>,
  ) {}

  use(req: Request, res: Response, next: NextFunction): void {
    // Ignora o próprio endpoint /metrics para não inflar contadores.
    if (req.path === '/metrics' || req.path.endsWith('/metrics')) {
      return next();
    }
    const start = process.hrtime.bigint();
    res.on('finish', () => {
      const elapsedSeconds =
        Number(process.hrtime.bigint() - start) / 1_000_000_000;
      // Normaliza a rota — extrai apenas o prefixo lógico para reduzir cardinalidade.
      const route = sanitizeRoute(req.path);
      this.histogram
        .labels(req.method, route, String(res.statusCode))
        .observe(elapsedSeconds);
    });
    next();
  }
}

function sanitizeRoute(path: string): string {
  // Coalesce UUIDs/numéricos no path em `:id` para não criar séries únicas.
  return path
    .replace(/\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '/:id')
    .replace(/\/\d+(?=\/|$)/g, '/:id');
}
