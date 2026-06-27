import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MentionsService } from './mentions.service';
import { PostMentionEntity } from '../database/entities/post-mention.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PostMentionEntity])],
  providers: [MentionsService],
  exports: [MentionsService],
})
export class MentionsModule {}
