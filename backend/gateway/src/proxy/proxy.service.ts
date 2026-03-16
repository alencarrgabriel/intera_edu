import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosRequestConfig, AxiosResponse } from 'axios';

@Injectable()
export class ProxyService {
  private readonly logger = new Logger(ProxyService.name);

  private readonly serviceUrls: Record<string, string>;

  constructor(private config: ConfigService) {
    this.serviceUrls = {
      auth: config.get<string>('AUTH_SERVICE_URL', 'http://localhost:3001'),
      profile: config.get<string>('PROFILE_SERVICE_URL', 'http://localhost:3002'),
      feed: config.get<string>('FEED_SERVICE_URL', 'http://localhost:3003'),
      messaging: config.get<string>('MESSAGING_SERVICE_URL', 'http://localhost:3004'),
    };
  }

  async forward(
    service: string,
    method: string,
    path: string,
    headers: Record<string, string>,
    body?: unknown,
    query?: Record<string, string>,
  ): Promise<AxiosResponse> {
    const baseUrl = this.serviceUrls[service];
    if (!baseUrl) {
      throw new Error(`Unknown service: ${service}`);
    }

    const url = `${baseUrl}${path}`;
    const config: AxiosRequestConfig = {
      method: method as AxiosRequestConfig['method'],
      url,
      headers: {
        'Content-Type': 'application/json',
        Authorization: headers['authorization'] || '',
        'X-Request-ID': headers['x-request-id'] || '',
      },
      data: body,
      params: query,
      timeout: 10000,
    };

    this.logger.debug(`Proxying ${method} ${url}`);

    return axios(config);
  }
}
