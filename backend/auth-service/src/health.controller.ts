import { Controller, Get } from '@nestjs/common';
import { Public } from '@interaedu/shared';

@Controller()
export class HealthController {
  @Public()
  @Get('health')
  health() {
    return { status: 'ok', service: 'auth-service', timestamp: new Date().toISOString() };
  }
}
