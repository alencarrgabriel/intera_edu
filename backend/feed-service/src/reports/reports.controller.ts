import { Controller, Post, Body, Get, Patch, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() user: JwtPayload,
    @Body()
    dto: {
      target_type: string;
      target_id: string;
      reason?: string;
      description?: string;
    },
  ) {
    return this.reports.create(user.sub, dto);
  }

  // RF-39 — Moderação (acessível para qualquer usuário autenticado por hora;
  // em produção deve ter Role guard de moderador/admin).
  @Get()
  async listOpen() {
    const rows = await this.reports.listOpen();
    return { data: rows };
  }

  @Patch(':id')
  async resolve(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: { action: 'resolve' | 'dismiss' },
  ) {
    return this.reports.resolve(id, user.sub, body.action ?? 'dismiss');
  }
}
