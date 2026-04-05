import { Controller, All, Req, Res, Logger } from '@nestjs/common';
import { Request, Response } from 'express';
import { ProxyService } from './proxy.service';

@Controller()
export class ProxyController {
  private readonly logger = new Logger(ProxyController.name);

  constructor(private readonly proxyService: ProxyService) {}

  /** Normaliza erros downstream para o formato canônico { error: { code, message, status } }.
   *  NestJS por padrão retorna { statusCode, message, error } — isso unifica para todos os clientes. */
  private normalizeError(data: any, status: number): object {
    if (data?.error?.code) return data; // já no formato correto (gateway próprio)
    const rawMessage = data?.message;
    const message = Array.isArray(rawMessage)
      ? rawMessage.join('; ')
      : (rawMessage ?? 'Erro interno do servidor');
    return {
      error: {
        code: (typeof data?.error === 'string' ? data.error.toUpperCase().replace(/\s+/g, '_') : null)
          ?? 'DOWNSTREAM_ERROR',
        message,
        status,
        timestamp: new Date().toISOString(),
      },
    };
  }

  // Route mapping: URL prefix → service name
  private resolveService(path: string): { service: string; servicePath: string } | null {
    const routes: Array<{ prefix: string; service: string }> = [
      { prefix: '/auth', service: 'auth' },
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
        return { service: route.service, servicePath: path };
      }
    }
    return null;
  }

  @All('*')
  async proxy(@Req() req: Request, @Res() res: Response) {
    // Strip the /api/v1 prefix explicitly just in case Express preserves it
    let path = req.path;
    if (path.startsWith('/api/v1')) {
      path = path.replace('/api/v1', '');
    }

    const resolved = this.resolveService(path);
    if (!resolved) {
      const origin = req.headers.origin;
      if (origin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Access-Control-Allow-Credentials', 'true');
      }
      
      return res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: `No service handles path: ${path}`,
          status: 404,
          timestamp: new Date().toISOString(),
        },
      });
    }

    try {
      const response = await this.proxyService.forward(
        resolved.service,
        req.method,
        resolved.servicePath,
        req.headers as Record<string, string>,
        req.body,
        req.query as Record<string, string>,
      );

      // Force CORS headers on proxy responses 
      // since raw Express @Res() sometimes bypasses global interceptors
      const origin = req.headers.origin;
      if (origin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Access-Control-Allow-Credentials', 'true');
      }

      return res.status(response.status).json(response.data);
    } catch (error: any) {
      const origin = req.headers.origin;
      if (origin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Access-Control-Allow-Credentials', 'true');
      }
      
      if (error.response) {
        return res
          .status(error.response.status)
          .json(this.normalizeError(error.response.data, error.response.status));
      }

      this.logger.error(`Proxy error for ${req.method} ${path}`, error.message);
      return res.status(503).json({
        error: {
          code: 'SERVICE_UNAVAILABLE',
          message: 'Downstream service is unavailable',
          status: 503,
          timestamp: new Date().toISOString(),
        },
      });
    }
  }
}
