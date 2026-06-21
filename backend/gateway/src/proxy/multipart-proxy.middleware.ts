import { Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as http from 'http';
import { URL } from 'url';

const logger = new Logger('MultipartProxy');

interface ServiceUrls {
  auth: string;
  profile: string;
  feed: string;
  messaging: string;
}

/**
 * Cria um middleware Express puro que intercepta requisições
 * `multipart/form-data` e as encaminha em streaming para o serviço
 * downstream, preservando o body bruto (o que axios + json-parser do
 * controller padrão não conseguem fazer).
 *
 * Registrado em `main.ts` via `app.use(...)` para garantir que rode
 * antes do roteador do NestJS.
 */
export function createMultipartProxy(urls: ServiceUrls) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const contentType = String(req.headers['content-type'] ?? '');
    if (!contentType.toLowerCase().startsWith('multipart/')) {
      return next();
    }

    const { service, downstreamPath } = resolveService(req.path);
    if (!service) return next();
    const baseUrl = urls[service];
    if (!baseUrl) return next();

    const target = new URL(baseUrl + downstreamPath);
    const query = req.url.includes('?')
      ? req.url.slice(req.url.indexOf('?'))
      : '';

    // Replica headers, sobrescrevendo o Host para o upstream.
    const headers: http.OutgoingHttpHeaders = { ...req.headers };
    headers.host = target.host;

    const options: http.RequestOptions = {
      hostname: target.hostname,
      port: target.port || 80,
      path: target.pathname + query,
      method: req.method,
      headers,
    };

    logger.debug(
      `[multipart] ${req.method} ${req.path} → ${baseUrl}${downstreamPath}`,
    );

    const upstreamReq = http.request(options, (upstreamRes) => {
      const origin = req.headers.origin;
      if (origin) {
        res.setHeader('Access-Control-Allow-Origin', String(origin));
        res.setHeader('Access-Control-Allow-Credentials', 'true');
      }
      res.writeHead(upstreamRes.statusCode ?? 502, upstreamRes.headers);
      upstreamRes.pipe(res);
    });

    upstreamReq.on('error', (err) => {
      logger.error(`Upstream error: ${err.message}`);
      if (!res.headersSent) {
        res.status(502).json({
          error: {
            code: 'BAD_GATEWAY',
            message: 'Falha ao encaminhar para o serviço downstream.',
            status: 502,
            timestamp: new Date().toISOString(),
          },
        });
      }
    });

    req.pipe(upstreamReq);
  };
}

function resolveService(rawPath: string): {
  service: keyof ServiceUrls | null;
  downstreamPath: string;
} {
  let path = rawPath;
  if (path.startsWith('/api/v1')) path = path.slice('/api/v1'.length);

  const routes: Array<{ prefix: string; service: keyof ServiceUrls }> = [
    { prefix: '/auth', service: 'auth' },
    { prefix: '/institutions', service: 'auth' },
    { prefix: '/users', service: 'profile' },
    { prefix: '/connections', service: 'profile' },
    { prefix: '/skills', service: 'profile' },
    { prefix: '/posts', service: 'feed' },
    { prefix: '/comments', service: 'feed' },
    { prefix: '/reports', service: 'feed' },
    { prefix: '/chats', service: 'messaging' },
    { prefix: '/messages', service: 'messaging' },
    { prefix: '/upload', service: 'messaging' },
    { prefix: '/notifications', service: 'messaging' },
  ];

  for (const route of routes) {
    if (path.startsWith(route.prefix)) {
      return { service: route.service, downstreamPath: path };
    }
  }
  return { service: null, downstreamPath: rawPath };
}
