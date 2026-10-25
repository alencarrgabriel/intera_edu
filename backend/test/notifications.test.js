const { NotificationsController } = require('../messaging-service/src/notifications/notifications.controller');

describe('Notificações internas: autenticação entre serviços', () => {
  const previous = process.env.INTERNAL_SERVICE_TOKEN;
  let create, controller;
  beforeEach(() => {
    process.env.INTERNAL_SERVICE_TOKEN = 'test-only-internal-token';
    create = jest.fn().mockResolvedValue({ id: 'n' });
    controller = new NotificationsController({ create });
  });
  afterAll(() => {
    if (previous === undefined) delete process.env.INTERNAL_SERVICE_TOKEN;
    else process.env.INTERNAL_SERVICE_TOKEN = previous;
  });
  test.each([undefined, 'wrong-token'])('rejeita token ausente/incorreto (%s)', async token => {
    await expect(controller.createInternal({ user_id: 'u', type: 'mention', title: 'Oi' }, token)).rejects.toMatchObject({ status: 401 });
    expect(create).not.toHaveBeenCalled();
  });
  test('configuração ausente falha de forma fechada', async () => {
    delete process.env.INTERNAL_SERVICE_TOKEN;
    await expect(controller.createInternal({}, '')).rejects.toMatchObject({ status: 401 });
  });
  test('serviço autorizado pode criar notificação', async () => {
    expect(await controller.createInternal({ user_id: 'u', type: 'mention', title: 'Oi' }, 'test-only-internal-token')).toEqual({ id: 'n' });
    expect(create).toHaveBeenCalledWith('u', 'mention', 'Oi', null, null);
  });
});
