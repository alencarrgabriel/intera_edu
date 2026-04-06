import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Chat } from '../database/entities/chat.entity';
import { ChatMember } from '../database/entities/chat-member.entity';
import { Message } from '../database/entities/message.entity';

@Injectable()
export class ChatsService {
  private readonly logger = new Logger(ChatsService.name);

  constructor(
    @InjectRepository(Chat)
    private readonly chatRepo: Repository<Chat>,
    @InjectRepository(ChatMember)
    private readonly memberRepo: Repository<ChatMember>,
    @InjectRepository(Message)
    private readonly messageRepo: Repository<Message>,
  ) {}

  async listChats(userId: string, type?: string, cursor?: string) {
    // Fetch all chats where user is a member
    const memberships = await this.memberRepo.find({ where: { userId } });
    if (!memberships.length) return { data: [], pagination: { cursor: null, has_more: false } };

    const chatIds = memberships.map((m) => m.chatId);
    const chats = await this.chatRepo
      .createQueryBuilder('c')
      .where('c.id IN (:...ids)', { ids: chatIds })
      .orderBy('c.updated_at', 'DESC')
      .take(30)
      .getMany();

    const chatData = await Promise.all(
      chats.map(async (chat) => {
        const members = await this.memberRepo.find({ where: { chatId: chat.id } });
        const lastMessage = await this.messageRepo.findOne({
          where: { chatId: chat.id, deletedAt: IsNull() },
          order: { createdAt: 'DESC' },
        });
        return {
          id: chat.id,
          type: chat.type,
          name: chat.name ?? null,
          members: members.map((m) => ({ user_id: m.userId, role: m.role })),
          last_message: lastMessage
            ? {
                id: lastMessage.id,
                sender_id: lastMessage.senderId,
                content: lastMessage.content,
                created_at: lastMessage.createdAt.toISOString(),
              }
            : null,
          updated_at: chat.updatedAt.toISOString(),
        };
      }),
    );

    return { data: chatData, pagination: { cursor: null, has_more: false } };
  }

  async createChat(dto: { type?: string; member_ids?: string[]; name?: string }, creatorId: string) {
    const type = dto.type === 'group' ? 'group' : 'direct';
    const memberIds: string[] = Array.from(new Set([creatorId, ...(dto.member_ids ?? [])]));

    if (type === 'direct') {
      if (memberIds.length !== 2) throw new BadRequestException('Direct chat requires exactly 2 members.');

      // Check if a direct chat already exists between these two users
      const existing = await this.findDirectChat(memberIds[0], memberIds[1]);
      if (existing) return { id: existing.id, message: 'Existing chat returned' };
    } else {
      if (memberIds.length < 2) throw new BadRequestException('Group chat requires at least 2 members.');
      if (memberIds.length > 50) throw new BadRequestException('Group chat max size is 50.');
    }

    const chat = await this.chatRepo.save({
      type,
      name: type === 'group' ? (dto.name ?? null) : null,
      createdBy: creatorId,
    });

    await this.memberRepo.save(
      memberIds.map((uid) => ({
        chatId: chat.id,
        userId: uid,
        role: uid === creatorId ? 'admin' : 'member',
      })),
    );

    this.logger.log(`Chat created: ${chat.id} by ${creatorId}`);
    return { id: chat.id, message: 'Chat created' };
  }

  async getChat(chatId: string, userId: string) {
    await this.assertMember(chatId, userId);

    const chat = await this.chatRepo.findOne({ where: { id: chatId } });
    if (!chat) throw new NotFoundException('Chat not found');

    const members = await this.memberRepo.find({ where: { chatId } });
    const lastMessage = await this.messageRepo.findOne({
      where: { chatId, deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });

    return {
      id: chat.id,
      type: chat.type,
      name: chat.name ?? null,
      members: members.map((m) => ({ user_id: m.userId, role: m.role })),
      last_message: lastMessage
        ? { id: lastMessage.id, sender_id: lastMessage.senderId, content: lastMessage.content, created_at: lastMessage.createdAt.toISOString() }
        : null,
      created_at: chat.createdAt.toISOString(),
      updated_at: chat.updatedAt.toISOString(),
    };
  }

  async updateChat(chatId: string, dto: { name?: string }, userId: string) {
    await this.assertAdmin(chatId, userId);

    await this.chatRepo.update(chatId, { name: dto.name });
    return { message: 'Chat updated' };
  }

  async getMessages(chatId: string, userId: string, cursor?: string, limit = 50) {
    await this.assertMember(chatId, userId);

    const take = Math.min(Math.max(limit, 1), 100);
    const qb = this.messageRepo
      .createQueryBuilder('m')
      .where('m.chat_id = :chatId', { chatId })
      .andWhere('m.deleted_at IS NULL')
      .orderBy('m.created_at', 'DESC')
      .take(take + 1);

    if (cursor) {
      try {
        const cursorDate = new Date(Buffer.from(cursor, 'base64').toString('utf8'));
        if (!isNaN(cursorDate.getTime())) {
          qb.andWhere('m.created_at < :cursor', { cursor: cursorDate.toISOString() });
        }
      } catch {
        // ignore invalid cursor
      }
    }

    const rows = await qb.getMany();
    const hasMore = rows.length > take;
    const page = rows.slice(0, take);

    const nextCursor = hasMore
      ? Buffer.from(page[page.length - 1].createdAt.toISOString()).toString('base64')
      : null;

    return {
      data: page.map((m) => ({
        id: m.id,
        chat_id: m.chatId,
        sender_id: m.senderId,
        content: m.content,
        file_url: m.fileUrl ?? null,
        created_at: m.createdAt.toISOString(),
      })),
      pagination: { cursor: nextCursor, has_more: hasMore },
    };
  }

  async sendMessage(
    chatId: string,
    dto: { content?: string; file_url?: string },
    senderId: string,
  ) {
    await this.assertMember(chatId, senderId);

    const content = typeof dto?.content === 'string' ? dto.content.trim() : '';
    if (!content && !dto?.file_url) throw new BadRequestException('Message must have content or a file.');

    const message = await this.messageRepo.save({
      chatId,
      senderId,
      content: content || '',
      fileUrl: dto?.file_url ?? null,
    });

    // Touch chat.updated_at for ordering
    await this.chatRepo.update(chatId, { updatedAt: new Date() });

    this.logger.log(`Message sent to chat: ${chatId} by: ${senderId}`);
    return {
      id: message.id,
      chat_id: message.chatId,
      sender_id: message.senderId,
      content: message.content,
      created_at: message.createdAt.toISOString(),
    };
  }

  async addMember(chatId: string, newUserId: string, requesterId: string) {
    await this.assertAdmin(chatId, requesterId);

    const existing = await this.memberRepo.findOne({ where: { chatId, userId: newUserId } });
    if (existing) throw new ConflictException('User is already a member.');

    await this.memberRepo.save({ chatId, userId: newUserId, role: 'member' });
    return { message: 'Member added' };
  }

  async removeMember(chatId: string, targetUserId: string, requesterId: string) {
    // Allow self-leave OR admin removing others
    if (targetUserId !== requesterId) {
      await this.assertAdmin(chatId, requesterId);
    }

    const member = await this.memberRepo.findOne({ where: { chatId, userId: targetUserId } });
    if (!member) throw new NotFoundException('Member not found');

    await this.memberRepo.remove(member);
    return { message: 'Member removed' };
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  private async assertMember(chatId: string, userId: string) {
    const m = await this.memberRepo.findOne({ where: { chatId, userId } });
    if (!m) throw new ForbiddenException('Not a member of this chat.');
  }

  private async assertAdmin(chatId: string, userId: string) {
    const m = await this.memberRepo.findOne({ where: { chatId, userId } });
    if (!m || m.role !== 'admin') throw new ForbiddenException('Admin access required.');
  }

  private async findDirectChat(userA: string, userB: string): Promise<Chat | null> {
    // Find chats where userA is a member, then check if userB is also a member
    const membershipsA = await this.memberRepo.find({ where: { userId: userA } });
    const chatIdsA = membershipsA.map((m) => m.chatId);
    if (!chatIdsA.length) return null;

    const membershipsB = await this.memberRepo.find({ where: { userId: userB } });
    const chatIdsB = new Set(membershipsB.map((m) => m.chatId));

    const commonIds = chatIdsA.filter((id) => chatIdsB.has(id));
    if (!commonIds.length) return null;

    return this.chatRepo.findOne({ where: commonIds.map((id) => ({ id, type: 'direct' as const })) });
  }

  /** Called by the WebSocket gateway to persist a message and broadcast. */
  async persistAndBroadcast(
    chatId: string,
    senderId: string,
    content: string,
  ): Promise<{ id: string; chat_id: string; sender_id: string; content: string; created_at: string } | null> {
    const isMember = await this.memberRepo.findOne({ where: { chatId, userId: senderId } });
    if (!isMember) return null;

    const message = await this.messageRepo.save({ chatId, senderId, content });
    await this.chatRepo.update(chatId, { updatedAt: new Date() });

    return {
      id: message.id,
      chat_id: message.chatId,
      sender_id: message.senderId,
      content: message.content,
      created_at: message.createdAt.toISOString(),
    };
  }

  /** Returns all chat IDs for a given user (used by gateway on connect). */
  async getChatIdsForUser(userId: string): Promise<string[]> {
    const memberships = await this.memberRepo.find({ where: { userId } });
    return memberships.map((m) => m.chatId);
  }
}
