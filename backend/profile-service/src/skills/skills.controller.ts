import { Controller, Get, Query } from '@nestjs/common';
import { SkillsService } from './skills.service';

@Controller('skills')
export class SkillsController {
  constructor(private readonly skillsService: SkillsService) {}

  @Get()
  async list(@Query('category') category?: string) {
    return this.skillsService.list(category);
  }

  @Get('search')
  async search(@Query('q') q: string) {
    return this.skillsService.search(q);
  }
}

