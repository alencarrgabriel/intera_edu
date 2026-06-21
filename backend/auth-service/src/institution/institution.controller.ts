import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  ForbiddenException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { InstitutionService } from './institution.service';
import { CurrentUser, JwtPayload, Public } from '@interaedu/shared';

function ensureAdmin(user: JwtPayload) {
  if (!user.roles?.includes('admin')) {
    throw new ForbiddenException('Acesso restrito a administradores.');
  }
}

@Controller('institutions')
export class InstitutionController {
  constructor(private readonly institutions: InstitutionService) {}

  // Listagem pública — qualquer cliente pode descobrir IES disponíveis.
  @Public()
  @Get()
  async list() {
    const data = await this.institutions.findAll();
    return { data };
  }

  // RF-37 — Admin cadastra nova IES.
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: { name: string; slug: string; domains: string[] },
  ) {
    ensureAdmin(user);
    return this.institutions.create(dto);
  }

  // RF-38 — Admin gerencia domínios aceitos.
  @Patch(':id/domains')
  async patchDomains(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: { add?: string[]; remove?: string[] },
  ) {
    ensureAdmin(user);
    return this.institutions.patchDomains(id, body.add ?? [], body.remove ?? []);
  }
}
