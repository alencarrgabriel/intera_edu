import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get('health')
  health() {
    return { status: 'ok', service: 'gateway', timestamp: new Date().toISOString() };
  }

  @Get('health/ready')
  readiness() {
    // TODO: Check downstream service connectivity
    return { status: 'ok', service: 'gateway', timestamp: new Date().toISOString() };
  }
}
