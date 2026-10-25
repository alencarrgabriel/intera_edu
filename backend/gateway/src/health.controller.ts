import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ProxyService } from './proxy/proxy.service';

@Controller()
export class HealthController {
  constructor(private readonly proxy: ProxyService) {}
  @Get('health')
  health() {
    return { status: 'ok', service: 'gateway', timestamp: new Date().toISOString() };
  }

  @Get('health/ready')
  async readiness() {
    const services = await this.proxy.checkHealth();
    if (Object.values(services).some(healthy => !healthy)) {
      throw new ServiceUnavailableException({ status: 'degraded', services });
    }
    return { status: 'ok', service: 'gateway', services, timestamp: new Date().toISOString() };
  }
}
