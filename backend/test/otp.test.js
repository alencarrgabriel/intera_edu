const { OtpService } = require('../auth-service/src/otp/otp.service');

describe('OTP: uso único e limites', () => {
  let redis, service;
  beforeEach(() => {
    redis = { get: jest.fn(), set: jest.fn(), del: jest.fn(), incr: jest.fn().mockResolvedValue(1), expire: jest.fn() };
    service = new OtpService(redis);
  });
  test('OTP ausente/expirado é rejeitado', async () => {
    redis.get.mockResolvedValue(null);
    expect(await service.verify('a@usp.br', '123456', 'registration')).toBe(false);
  });
  test('OTP válido é consumido uma única vez', async () => {
    redis.get.mockResolvedValueOnce(null).mockResolvedValueOnce(JSON.stringify({ code: '123456', attempts: 0 }));
    expect(await service.verify('a@usp.br', '123456', 'registration')).toBe(true);
    expect(redis.del).toHaveBeenCalledWith('otp:registration:a@usp.br');
  });
  test('código incorreto incrementa tentativas', async () => {
    redis.get.mockResolvedValueOnce(null).mockResolvedValueOnce(JSON.stringify({ code: '123456', attempts: 0 }));
    expect(await service.verify('a@usp.br', '999999', 'registration')).toBe(false);
    expect(JSON.parse(redis.set.mock.calls[0][1]).attempts).toBe(1);
  });
  test('quinta tentativa aciona bloqueio de 15 minutos', async () => {
    redis.get.mockResolvedValueOnce(null).mockResolvedValueOnce(JSON.stringify({ code: '123456', attempts: 4 }));
    await expect(service.verify('a@usp.br', '999999', 'registration')).rejects.toMatchObject({ status: 429 });
    expect(redis.set).toHaveBeenCalledWith('otp:cooldown:a@usp.br', '1', 900);
    expect(redis.del).toHaveBeenCalled();
  });
  test('cooldown impede verificar e consumir o código', async () => {
    redis.get.mockResolvedValue('1');
    await expect(service.verify('a@usp.br', '123456', 'registration')).rejects.toMatchObject({ status: 429 });
    expect(redis.del).not.toHaveBeenCalled();
  });
  test('quarta solicitação por hora é rejeitada', async () => {
    redis.incr.mockResolvedValue(4);
    await expect(service.generateAndSend('a@usp.br', 'registration')).rejects.toMatchObject({ status: 429 });
    expect(redis.set).not.toHaveBeenCalled();
  });
  test('sem provedor configurado não anuncia envio bem-sucedido', async () => {
    const previous = process.env.RESEND_API_KEY;
    const oldMode = process.env.NODE_ENV;
    delete process.env.RESEND_API_KEY;
    process.env.NODE_ENV = 'production';
    try {
      await expect(service.generateAndSend('a@usp.br', 'registration')).rejects.toMatchObject({ status: 503 });
    } finally {
      if (previous === undefined) delete process.env.RESEND_API_KEY;
      else process.env.RESEND_API_KEY = previous;
      if (oldMode === undefined) delete process.env.NODE_ENV;
      else process.env.NODE_ENV = oldMode;
    }
  });
  test('erro do provedor de email é propagado como indisponibilidade', async () => {
    const previous = process.env.RESEND_API_KEY;
    process.env.RESEND_API_KEY = 'test-only-resend-key';
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({ ok: false, status: 503 });
    try {
      await expect(service.generateAndSend('a@usp.br', 'registration')).rejects.toMatchObject({ status: 503 });
      expect(fetchMock).toHaveBeenCalledTimes(1);
    } finally {
      fetchMock.mockRestore();
      if (previous === undefined) delete process.env.RESEND_API_KEY;
      else process.env.RESEND_API_KEY = previous;
    }
  });
});
