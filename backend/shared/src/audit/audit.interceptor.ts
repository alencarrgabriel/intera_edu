import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Observable, tap } from 'rxjs';
import { AuditLog } from './audit-log.entity';

/// RF-33 — Interceptor que registra mutações em uma trilha de auditoria.
/// Aplicado globalmente em cada serviço via APP_INTERCEPTOR.
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger(AuditInterceptor.name);

  constructor(
    @InjectRepository(AuditLog)
    private readonly auditRepo: Repository<AuditLog>,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const res = context.switchToHttp().getResponse();
    const method: string = req?.method ?? 'GET';

    // Só auditamos mutações.
    if (!['POST', 'PATCH', 'PUT', 'DELETE'].includes(method)) {
      return next.handle();
    }

    return next.handle().pipe(
      tap({
        next: (body) => this.persist(req, res, method, body),
        error: () => this.persist(req, res, method, null),
      }),
    );
  }

  private async persist(
    req: any,
    res: any,
    method: string,
    body: any,
  ): Promise<void> {
    try {
      await this.auditRepo.save({
        userId: req?.user?.sub ?? null,
        method,
        path: String(req?.url ?? req?.path ?? '').slice(0, 255),
        targetType: this.guessTarget(req?.path) ?? null,
        targetId: body?.id ?? req?.params?.id ?? null,
        statusCode: res?.statusCode ?? 0,
        ipAddress: req?.ip ?? null,
        metadata: this.sanitizeBody(req?.body),
      });
    } catch (e) {
      this.logger.warn(`Falha ao auditar: ${String(e)}`);
    }
  }

  private guessTarget(path: string | undefined): string | null {
    if (!path) return null;
    if (path.includes('/users')) return 'user';
    if (path.includes('/posts')) return 'post';
    if (path.includes('/comments')) return 'comment';
    if (path.includes('/chats')) return 'chat';
    if (path.includes('/connections')) return 'connection';
    if (path.includes('/reports')) return 'report';
    if (path.includes('/auth')) return 'auth';
    return 'other';
  }

  private sanitizeBody(body: any): any {
    if (!body || typeof body !== 'object') return null;
    // Remove segredos antes de persistir.
    const out: Record<string, any> = { ...body };
    for (const key of ['password', 'new_password', 'refresh_token', 'token']) {
      if (key in out) out[key] = '[REDACTED]';
    }
    return out;
  }
}
