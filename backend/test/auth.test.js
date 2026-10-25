const { UnauthorizedException, ForbiddenException, ConflictException } = require('@nestjs/common');
jest.mock('bcrypt', () => ({ compare: jest.fn(), hash: jest.fn().mockResolvedValue('hashed') }));
const bcrypt = require('bcrypt');
const { AuthService } = require('../auth-service/src/auth/auth.service');

describe('AuthService: sessão e cadastro', () => {
  let users, tokens, consent, jwt, otp, institution, redis, service;
  beforeEach(() => {
    users = { findOne: jest.fn(), save: jest.fn(), findOneOrFail: jest.fn() };
    tokens = { find: jest.fn(), update: jest.fn(), save: jest.fn() };
    consent = { find: jest.fn().mockResolvedValue([]), save: jest.fn() };
    jwt = { verify: jest.fn(), sign: jest.fn().mockReturnValue('signed') };
    otp = { generateAndSend: jest.fn(), verify: jest.fn() };
    institution = { findByEmailDomain: jest.fn() };
    redis = { publish: jest.fn() };
    service = new AuthService(users, tokens, consent, jwt, { get: (_, fallback) => fallback }, otp, institution, redis);
  });
  test('rejeita domínio não institucional sem enviar OTP', async () => {
    institution.findByEmailDomain.mockResolvedValue(null);
    await expect(service.register({ email: 'a@example.com' })).rejects.toBeInstanceOf(ForbiddenException);
    expect(otp.generateAndSend).not.toHaveBeenCalled();
  });
  test('rejeita cadastro duplicado', async () => {
    institution.findByEmailDomain.mockResolvedValue({ id: 'i' });
    users.findOne.mockResolvedValue({ id: 'u' });
    await expect(service.register({ email: 'a@usp.br' })).rejects.toBeInstanceOf(ConflictException);
  });
  test('cadastro permitido envia OTP de registro', async () => {
    institution.findByEmailDomain.mockResolvedValue({ id: 'i' });
    users.findOne.mockResolvedValue(null);
    expect(await service.register({ email: 'a@usp.br' })).toMatchObject({ expires_in_seconds: 600 });
    expect(otp.generateAndSend).toHaveBeenCalledWith('a@usp.br', 'registration');
  });
  test('OTP inválido não emite token temporário', async () => {
    otp.verify.mockResolvedValue(false);
    await expect(service.verifyOtp({ email: 'a@usp.br', code: '000000' })).rejects.toBeInstanceOf(UnauthorizedException);
    expect(jwt.sign).not.toHaveBeenCalled();
  });
  test('token temporário usa propósito e validade de 15 minutos', async () => {
    otp.verify.mockResolvedValue(true);
    expect(await service.verifyOtp({ email: 'a@usp.br', code: '123456' })).toMatchObject({ temporary_token: 'signed' });
    expect(jwt.sign).toHaveBeenCalledWith({ email: 'a@usp.br', purpose: 'registration' }, { expiresIn: '15m' });
  });
  test('login desconhecido é rejeitado', async () => {
    users.findOne.mockResolvedValue(null);
    await expect(service.login({ email: 'a@usp.br', password: 'wrong' })).rejects.toBeInstanceOf(UnauthorizedException);
  });
  test('senha incorreta não cria sessão', async () => {
    users.findOne.mockResolvedValue({ passwordHash: 'hash' });
    bcrypt.compare.mockResolvedValue(false);
    await expect(service.login({ email: 'a@usp.br', password: 'wrong' })).rejects.toBeInstanceOf(UnauthorizedException);
    expect(tokens.save).not.toHaveBeenCalled();
  });
  test('login válido armazena refresh como hash', async () => {
    users.findOne.mockResolvedValue({ id: 'u', email: 'a@usp.br', institutionId: 'i', passwordHash: 'hash' });
    bcrypt.compare.mockResolvedValue(true);
    expect(await service.login({ email: 'a@usp.br', password: 'ok' })).toMatchObject({ tokens: { access_token: 'signed' }, requires_consent_update: true });
    expect(tokens.save).toHaveBeenCalledWith(expect.objectContaining({ userId: 'u', tokenHash: 'hashed' }));
  });
  test('refresh inválido é rejeitado antes de consultar tokens', async () => {
    jwt.verify.mockImplementation(() => { throw new Error('expired'); });
    await expect(service.refreshToken({ refresh_token: 'bad' })).rejects.toBeInstanceOf(UnauthorizedException);
    expect(tokens.find).not.toHaveBeenCalled();
  });
  test('replay de refresh revoga a família de tokens', async () => {
    jwt.verify.mockReturnValue({ sub: 'u' });
    tokens.find.mockResolvedValue([{ tokenHash: 'old' }]);
    bcrypt.compare.mockResolvedValue(false);
    await expect(service.refreshToken({ refresh_token: 'replayed' })).rejects.toBeInstanceOf(UnauthorizedException);
    expect(tokens.update).toHaveBeenCalledWith({ userId: 'u' }, { revokedAt: expect.any(Date) });
  });
  test('refresh válido revoga o anterior e emite novo par', async () => {
    jwt.verify.mockReturnValue({ sub: 'u' });
    tokens.find.mockResolvedValue([{ id: 'r', tokenHash: 'old' }]);
    bcrypt.compare.mockResolvedValue(true);
    users.findOneOrFail.mockResolvedValue({ id: 'u', institutionId: 'i' });
    expect(await service.refreshToken({ refresh_token: 'valid' })).toMatchObject({ tokens: { refresh_token: 'signed' } });
    expect(tokens.save).toHaveBeenCalledWith(expect.objectContaining({ id: 'r', revokedAt: expect.any(Date) }));
  });
  test('recuperação de senha não revela conta inexistente', async () => {
    users.findOne.mockResolvedValue(null);
    expect(await service.forgotPassword('missing@usp.br')).toMatchObject({ expires_in_seconds: 600 });
    expect(otp.generateAndSend).not.toHaveBeenCalled();
  });
});
