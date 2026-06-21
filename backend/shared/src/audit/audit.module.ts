import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditLog } from './audit-log.entity';
import { AuditInterceptor } from './audit.interceptor';

/// RF-33 — Import em cada serviço para habilitar a trilha de auditoria.
@Module({
  imports: [TypeOrmModule.forFeature([AuditLog])],
  providers: [
    AuditInterceptor,
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ],
  exports: [AuditInterceptor, TypeOrmModule],
})
export class AuditModule {}
