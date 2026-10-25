const http = require('node:http');
const { Test } = require('@nestjs/testing');
const { ConfigService } = require('@nestjs/config');
const { ProxyController } = require('../gateway/src/proxy/proxy.controller');
const { ProxyService } = require('../gateway/src/proxy/proxy.service');
const { HealthController } = require('../gateway/src/health.controller');

describe('Integração gateway → servidor HTTP de teste', () => {
  let upstream, app, base, healthy = true;
  beforeAll(async () => {
    upstream = http.createServer((req, res) => {
      res.setHeader('Content-Type', 'application/json');
      if (req.url === '/health') {
        res.writeHead(healthy ? 200 : 503);
        return res.end(JSON.stringify({ status: healthy ? 'ok' : 'down' }));
      }
      if (req.url === '/auth/login') {
        res.writeHead(401);
        return res.end(JSON.stringify({ statusCode: 401, error: 'Unauthorized', message: 'Invalid credentials' }));
      }
      res.end(JSON.stringify({ path: req.url, authorization: req.headers.authorization, requestId: req.headers['x-request-id'] }));
    });
    await new Promise(resolve => upstream.listen(0, '127.0.0.1', resolve));
    const target = `http://127.0.0.1:${upstream.address().port}`;
    const module = await Test.createTestingModule({
      controllers: [HealthController, ProxyController],
      providers: [ProxyService, { provide: ConfigService, useValue: new ConfigService({ PROFILE_SERVICE_URL: target, AUTH_SERVICE_URL: target, FEED_SERVICE_URL: target, MESSAGING_SERVICE_URL: target }) }],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
  });
  afterAll(async () => {
    if (app) await app.close();
    if (upstream) await new Promise(resolve => upstream.close(resolve));
  });
  test('encaminha rota, query e cabeçalhos de identidade', async () => {
    const response = await fetch(`${base}/api/v1/users?limit=5`, { headers: { Authorization: 'Bearer test-only', 'X-Request-ID': 'request-1' } });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ path: '/users?limit=5', authorization: 'Bearer test-only', requestId: 'request-1' });
  });
  test('normaliza erro downstream preservando status HTTP', async () => {
    const response = await fetch(`${base}/api/v1/auth/login`, { method: 'POST' });
    expect(response.status).toBe(401);
    expect(await response.json()).toMatchObject({ error: { code: 'UNAUTHORIZED', message: 'Invalid credentials', status: 401 } });
  });
  test.each(['/unknown', '/users-evil'])('rota %s não é encaminhada por semelhança de prefixo', async path => {
    const response = await fetch(`${base}/api/v1${path}`);
    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({ error: { code: 'NOT_FOUND' } });
  });
  test('readiness consulta os serviços downstream', async () => {
    const response = await fetch(`${base}/api/v1/health/ready`);
    expect(response.status).toBe(200);
    expect(await response.json()).toHaveProperty('services.auth', true);
  });
  test('readiness retorna 503 quando um serviço está indisponível', async () => {
    healthy = false;
    try {
      expect((await fetch(`${base}/api/v1/health/ready`)).status).toBe(503);
      expect((await fetch(`${base}/api/v1/health`)).status).toBe(200);
    } finally { healthy = true; }
  });
});
