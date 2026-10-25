const { PostsService } = require('../feed-service/src/posts/posts.service');
const { extractHashtags, extractMentions } = require('../feed-service/src/tags/tag-utils');
const { ConnectionsService } = require('../profile-service/src/connections/connections.service');
const { ChatsService } = require('../messaging-service/src/chats/chats.service');

describe('Feed: autoria, reações e comentários', () => {
  let posts, reactions, redis, service;
  beforeEach(() => {
    posts = { findOne: jest.fn(), save: jest.fn() };
    reactions = { findOne: jest.fn(), save: jest.fn(), remove: jest.fn() };
    redis = { get: jest.fn(), del: jest.fn(), scan: jest.fn().mockResolvedValue([]) };
    service = new PostsService(posts, reactions, {}, redis, {}, {}, {}, {});
  });
  test('exclusão rejeita usuário que não é autor', async () => {
    posts.findOne.mockResolvedValue({ authorId: 'owner' });
    await expect(service.softDelete('p', 'intruder')).rejects.toMatchObject({ status: 403 });
    expect(posts.save).not.toHaveBeenCalled();
  });
  test('post inexistente retorna 404', async () => {
    posts.findOne.mockResolvedValue(null);
    await expect(service.findById('missing')).rejects.toMatchObject({ status: 404 });
  });
  test('reação fora do contrato é rejeitada', async () => {
    await expect(service.addReaction('p', 'invalid', 'u')).rejects.toMatchObject({ status: 403 });
    expect(reactions.save).not.toHaveBeenCalled();
  });
  test('reação duplicada não incrementa contador', async () => {
    posts.findOne.mockResolvedValue({ reactionCount: 1 });
    reactions.findOne.mockResolvedValue({ id: 'r' });
    await expect(service.addReaction('p', 'like', 'u')).rejects.toMatchObject({ status: 409 });
    expect(posts.save).not.toHaveBeenCalled();
  });
  test('comentário vazio não é persistido', async () => {
    posts.findOne.mockResolvedValue({ id: 'p' });
    await expect(service.addComment('p', { content: '  ' }, 'u')).rejects.toMatchObject({ status: 403 });
  });
  test('cache do feed isola reações e favoritos de cada usuário', async () => {
    redis.get.mockResolvedValue(JSON.stringify({ data: [] }));
    await service.getFeed('local', '', 20, { sub: 'alice', institution_id: 'usp' }, '');
    await service.getFeed('local', '', 20, { sub: 'bob', institution_id: 'usp' }, '');
    expect(redis.get.mock.calls[0][0]).not.toBe(redis.get.mock.calls[1][0]);
  });
  test('hashtags Unicode são normalizadas e deduplicadas', () => {
    expect(extractHashtags('#Educação #EDUCAÇÃO #IA #a')).toEqual(['educação', 'ia']);
  });
  test('menções curtas são rejeitadas e duplicatas removidas', () => {
    expect(extractMentions('@ana @ANA @ab @joao.silva')).toEqual(['ana', 'joao.silva']);
  });
});

describe('Conexões: permissões e transições', () => {
  let repo, profiles, service;
  beforeEach(() => {
    repo = { findOne: jest.fn(), save: jest.fn() };
    profiles = { findOne: jest.fn() };
    service = new ConnectionsService(repo, profiles, {});
  });
  test('não permite conectar consigo mesmo', async () => {
    await expect(service.create('u', { addressee_id: 'u' })).rejects.toMatchObject({ status: 403 });
  });
  test('não permite conectar com usuário inexistente', async () => {
    profiles.findOne.mockResolvedValue(null);
    await expect(service.create('u', { addressee_id: 'v' })).rejects.toMatchObject({ status: 404 });
  });
  test('não cria segunda solicitação para o mesmo par', async () => {
    profiles.findOne.mockResolvedValue({ id: 'v' });
    repo.findOne.mockResolvedValue({ status: 'pending' });
    await expect(service.create('u', { addressee_id: 'v' })).rejects.toMatchObject({ status: 409 });
  });
  test('somente destinatário pode responder', async () => {
    repo.findOne.mockResolvedValue({ addresseeId: 'v', status: 'pending' });
    await expect(service.update('u', 'c', { action: 'accept' })).rejects.toMatchObject({ status: 403 });
    expect(repo.save).not.toHaveBeenCalled();
  });
  test('conexão já resolvida não pode ser respondida novamente', async () => {
    repo.findOne.mockResolvedValue({ addresseeId: 'v', status: 'accepted' });
    await expect(service.update('v', 'c', { action: 'reject' })).rejects.toMatchObject({ status: 409 });
  });
  test('destinatário pode rejeitar solicitação pendente', async () => {
    repo.findOne.mockResolvedValue({ addresseeId: 'v', status: 'pending' });
    repo.save.mockImplementation(async x => x);
    expect(await service.update('v', 'c', { action: 'reject' })).toMatchObject({ status: 'rejected', respondedAt: expect.any(Date) });
  });
});

describe('Mensagens: membros, conteúdo e administração', () => {
  let chats, members, messages, service;
  beforeEach(() => {
    chats = { save: jest.fn(), update: jest.fn() };
    members = { findOne: jest.fn(), save: jest.fn(), find: jest.fn() };
    messages = { save: jest.fn() };
    service = new ChatsService(chats, members, messages);
  });
  test('chat direto exige dois participantes distintos', async () => {
    await expect(service.createChat({ member_ids: ['u'] }, 'u')).rejects.toMatchObject({ status: 400 });
  });
  test('grupo rejeita mais de 50 participantes', async () => {
    await expect(service.createChat({ type: 'group', member_ids: Array.from({ length: 51 }, (_, i) => String(i)) }, 'u')).rejects.toMatchObject({ status: 400 });
  });
  test('não membro não pode consultar mensagens', async () => {
    members.findOne.mockResolvedValue(null);
    await expect(service.getMessages('c', 'intruder')).rejects.toMatchObject({ status: 403 });
  });
  test('membro não pode enviar mensagem vazia sem arquivo', async () => {
    members.findOne.mockResolvedValue({ userId: 'u' });
    await expect(service.sendMessage('c', { content: ' ' }, 'u')).rejects.toMatchObject({ status: 400 });
    expect(messages.save).not.toHaveBeenCalled();
  });
  test('mensagem válida é normalizada e atualiza a conversa', async () => {
    members.findOne.mockResolvedValue({ userId: 'u' });
    messages.save.mockImplementation(async x => ({ ...x, id: 'm', createdAt: new Date('2026-10-25T12:00:00Z') }));
    expect(await service.sendMessage('c', { content: ' Olá ' }, 'u')).toMatchObject({ content: 'Olá', chat_id: 'c', sender_id: 'u' });
    expect(chats.update).toHaveBeenCalledWith('c', { updatedAt: expect.any(Date) });
  });
  test('somente administrador pode renomear conversa', async () => {
    members.findOne.mockResolvedValue({ role: 'member' });
    await expect(service.updateChat('c', { name: 'Outro' }, 'u')).rejects.toMatchObject({ status: 403 });
    expect(chats.update).not.toHaveBeenCalled();
  });
  test('persistência via WebSocket rejeita remetente externo', async () => {
    members.findOne.mockResolvedValue(null);
    expect(await service.persistAndBroadcast('c', 'intruder', 'x')).toBeNull();
    expect(messages.save).not.toHaveBeenCalled();
  });
});
