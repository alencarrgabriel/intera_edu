import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';
import { S3Service } from './s3.service';
import { Chat } from '../database/entities/chat.entity';
import { ChatMember } from '../database/entities/chat-member.entity';
import { Message } from '../database/entities/message.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Chat, ChatMember, Message])],
  controllers: [ChatsController],
  providers: [ChatsService, S3Service],
  exports: [ChatsService],
})
export class ChatsModule {}
