const { Test } = require('@nestjs/testing');
const { ValidationPipe } = require('@nestjs/common');
const { AuthController } = require('../auth-service/src/auth/auth.controller');
const { AuthService } = require('../auth-service/src/auth/auth.service');
const { GoogleAuthService } = require('../auth-service/src/auth/google-auth.service');
const { JwtModule } = require('@nestjs/jwt');
const { JwtStrategy } = require('../shared/src/auth/jwt.strategy');
const { ConfigService } = require('@nestjs/config');
const { APP_GUARD } = require('@nestjs/core');
const { PassportModule } = require('@nestjs/passport');
const { JwtAuthGuard } = require('../shared/src/auth/jwt-auth.guard');
const { HealthController } = require('../shared/src/health.controller');

describe('Integração HTTP Nest: contrato de login e validação real de DTO', () => {
  let app, base, login, acceptTerms, revokeConsent, accessToken;
  beforeAll(async () => {
    login = jest.fn().mockResolvedValue({ tokens: { access_token: 'test-only', refresh_token: 'test-only' } });
    acceptTerms = jest.fn().mockResolvedValue({ ok: true });
    revokeConsent = jest.fn().mockResolvedValue({ ok: true });
    const secret = 'test-only-http-signing-secret';
    const module = await Test.createTestingModule({
      imports: [PassportModule, JwtModule.register({ secret })],
      controllers: [AuthController, HealthController],
      providers: [
        { provide: AuthService, useValue: { login, acceptTerms, revokeConsent } },
        { provide: GoogleAuthService, useValue: {} },
        { provide: ConfigService, useValue: new ConfigService({ JWT_ACCESS_SECRET: secret }) },
        JwtStrategy,
        { provide: APP_GUARD, useClass: JwtAuthGuard },
      ],
    }).compile();
    accessToken = module.get(require('@nestjs/jwt').JwtService).sign({ sub: 'authenticated-user' }, { expiresIn: '1m' });
    app = module.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
  });
  afterAll(async () => { if (app) await app.close(); });
  test('payload válido chega ao serviço e retorna contrato HTTP 200', async () => {
    const response = await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'aluno@usp.br', password: 'Password123!' }) });
    expect(response.status).toBe(200);
    expect(await response.json()).toHaveProperty('tokens.access_token');
    expect(login).toHaveBeenCalledTimes(1);
  });
  test('email inválido retorna 400 sem invocar serviço', async () => {
    const response = await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'invalid', password: 'Password123!' }) });
    expect(response.status).toBe(400);
    expect(login).not.toHaveBeenCalled();
  });
  test('campo extra é rejeitado pela whitelist', async () => {
    const response = await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'aluno@usp.br', password: 'Password123!', role: 'admin' }) });
    expect(response.status).toBe(400);
    expect(login).not.toHaveBeenCalled();
  });
  test('consentimento exige autenticação', async () => {
    const response = await fetch(`${base}/auth/accept-terms`, { method: 'POST' });
    expect(response.status).toBe(401);
    expect(acceptTerms).not.toHaveBeenCalled();
  });
  test('liveness permanece acessível sem JWT', async () => {
    const response = await fetch(`${base}/health`);
    expect(response.status).toBe(200);
    expect(await response.json()).toHaveProperty('status', 'ok');
  });
  test.each(['accept-terms', 'revoke-consent'])('%s usa identidade do JWT, ignorando user_id forjado', async route => {
    const response = await fetch(`${base}/auth/${route}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}` }, body: JSON.stringify({ user_id: 'victim' }) });
    expect(response.status).toBe(200);
    expect(route === 'accept-terms' ? acceptTerms : revokeConsent).toHaveBeenCalledWith('authenticated-user');
  });
});

describe('JWT: assinatura e expiração com implementação real', () => {
  const { JwtService } = require('@nestjs/jwt');
  const secret = 'test-only-secret-never-used-by-application';
  const jwt = new JwtService({ secret });
  const strategy = new JwtStrategy(new ConfigService({ JWT_ACCESS_SECRET: secret }));
  test('token assinado preserva identidade e instituição', async () => {
    const token = jwt.sign({ sub: 'u', email: 'a@usp.br', institution_id: 'i', roles: ['user'] }, { expiresIn: '1m' });
    expect(await strategy.validate(jwt.verify(token))).toMatchObject({ sub: 'u', institution_id: 'i', roles: ['user'] });
  });
  test('token adulterado é rejeitado', () => {
    const token = jwt.sign({ sub: 'u' });
    expect(() => jwt.verify(token, { secret: 'different-test-secret' })).toThrow();
  });
  test('token expirado é rejeitado', () => {
    expect(() => jwt.verify(jwt.sign({ sub: 'u' }, { expiresIn: -1 }))).toThrow();
  });
});
