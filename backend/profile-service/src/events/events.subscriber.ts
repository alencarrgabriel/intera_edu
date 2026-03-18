import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RedisService } from '@interaedu/shared';
import { UserProfile } from '../database/entities/user-profile.entity';

const EVENTS_CHANNEL = 'interaedu.events';

type UserRegisteredEvent = {
  type: 'user.registered';
  payload: { userId: string; email: string; institutionId: string };
  occurredAt: string;
};

@Injectable()
export class EventsSubscriber implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EventsSubscriber.name);
  private readonly subscriber = this.redis.getClient().duplicate();

  constructor(
    private readonly redis: RedisService,
    @InjectRepository(UserProfile)
    private readonly userRepo: Repository<UserProfile>,
  ) {}

  async onModuleInit(): Promise<void> {
    this.subscriber.on('error', (err: unknown) => this.logger.error('Redis subscriber error', err));

    await this.subscriber.subscribe(EVENTS_CHANNEL);
    this.subscriber.on('message', async (_channel: string, message: string) => {
      await this.handleMessage(message);
    });

    this.logger.log(`Subscribed to ${EVENTS_CHANNEL}`);
  }

  async onModuleDestroy(): Promise<void> {
    try {
      await this.subscriber.unsubscribe(EVENTS_CHANNEL);
      await this.subscriber.quit();
    } catch {
      // ignore
    }
  }

  private async handleMessage(message: string) {
    let parsed: { type?: string; payload?: unknown };
    try {
      parsed = JSON.parse(message);
    } catch {
      this.logger.warn(`Ignoring non-JSON event: ${message}`);
      return;
    }

    if (parsed.type === 'user.registered') {
      await this.onUserRegistered(parsed as UserRegisteredEvent);
    }
  }

  private async onUserRegistered(evt: UserRegisteredEvent) {
    const { userId, institutionId } = evt.payload;

    const existing = await this.userRepo.findOne({ where: { id: userId } });
    if (existing) return;

    await this.userRepo.save({
      id: userId,
      institutionId,
      fullName: '',
      privacyLevel: 'local_only',
    });

    this.logger.log(`Created initial profile for user ${userId}`);
  }
}

