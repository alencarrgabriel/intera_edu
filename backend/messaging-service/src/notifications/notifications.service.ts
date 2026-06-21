import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Notification } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly repo: Repository<Notification>,
  ) {}

  async create(
    userId: string,
    type: string,
    title: string,
    body: string | null,
    payload?: any,
  ) {
    return this.repo.save({
      userId,
      type,
      title,
      body: body ?? null,
      payload: payload ?? null,
    });
  }

  async list(userId: string, onlyUnread = false) {
    const where = onlyUnread
      ? { userId, readAt: IsNull() }
      : { userId };
    const rows = await this.repo.find({
      where,
      order: { createdAt: 'DESC' },
      take: 100,
    });
    const unread = await this.repo.count({
      where: { userId, readAt: IsNull() },
    });
    return { data: rows, unread };
  }

  async markRead(userId: string, id: string) {
    const row = await this.repo.findOne({ where: { id, userId } });
    if (!row) return null;
    if (!row.readAt) {
      row.readAt = new Date();
      await this.repo.save(row);
    }
    return row;
  }

  async markAllRead(userId: string) {
    await this.repo.update(
      { userId, readAt: IsNull() },
      { readAt: new Date() },
    );
    return { ok: true };
  }
}
