import {
  ExecutionContext,
  Injectable,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import {
  ThrottlerGuard,
  ThrottlerOptions,
  ThrottlerGetTrackerFunction,
  ThrottlerGenerateKeyFunction,
} from '@nestjs/throttler';

/**
 * Guard global que aplica rate limit mais restrito em endpoints sensíveis.
 *
 * Limites:
 *  - Padrão (qualquer rota):     100 req/min por IP
 *  - Rotas de autenticação:       10 req/min por IP  (login/register/OTP)
 *
 * Implementado sobrescrevendo o ThrottlerGuard para escolher o tracker e
 * o limite efetivo com base no path da requisição — necessário porque o
 * gateway usa um único controller catch-all (@All('*')).
 */
@Injectable()
export class PathAwareThrottlerGuard extends ThrottlerGuard {
  /// Considera o IP do cliente como chave de rate limit.
  /// Diferencia também o "namespace" (default | auth) para que os contadores
  /// não compartilhem o mesmo balde.
  protected async getTracker(req: Record<string, any>): Promise<string> {
    const path: string = req?.path ?? '';
    const ip: string =
      req?.ip ??
      req?.headers?.['x-forwarded-for']?.split(',')[0] ??
      'unknown';
    const ns = this.isAuthPath(path) ? 'auth' : 'default';
    return `${ns}:${ip}`;
  }

  /// Override do limite efetivo: rotas de auth ficam em 10 req/min.
  protected async handleRequest(
    context: ExecutionContext,
    limit: number,
    ttl: number,
    throttler: ThrottlerOptions,
    getTracker: ThrottlerGetTrackerFunction,
    generateKey: ThrottlerGenerateKeyFunction,
  ): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const path: string = req?.path ?? '';
    const effectiveLimit = this.isAuthPath(path) ? 10 : limit;
    return super.handleRequest(
      context,
      effectiveLimit,
      ttl,
      throttler,
      getTracker,
      generateKey,
    );
  }

  /// Resposta no formato canônico do gateway quando 429.
  protected async throwThrottlingException(): Promise<void> {
    throw new HttpException(
      {
        error: {
          code: 'TOO_MANY_REQUESTS',
          message:
            'Muitas requisições em pouco tempo. Aguarde antes de tentar novamente.',
          status: 429,
          timestamp: new Date().toISOString(),
        },
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  private isAuthPath(path: string): boolean {
    return path.startsWith('/api/v1/auth') || path.startsWith('/auth');
  }
}
