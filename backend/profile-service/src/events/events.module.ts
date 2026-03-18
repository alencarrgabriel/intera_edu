import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RedisModule } from '@interaedu/shared';
import { EventsSubscriber } from './events.subscriber';
import { UserProfile } from '../database/entities/user-profile.entity';

@Module({
  imports: [RedisModule, TypeOrmModule.forFeature([UserProfile])],
  providers: [EventsSubscriber],
})
export class EventsModule {}

