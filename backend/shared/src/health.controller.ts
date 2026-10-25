import { Controller, Get } from '@nestjs/common';
import { Public } from './auth/current-user.decorator';

/** Liveness only: successful bootstrap does not attest external dependencies. */
@Controller()
export class HealthController {
  @Public()
  @Get('health')
  health() {
    return { status: 'ok', service: process.env.SERVICE_NAME ?? 'interaedu', timestamp: new Date().toISOString() };
  }
}
