import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TagsController } from './tags.controller';
import { TagsService } from './tags.service';
import { TagEntity } from '../database/entities/tag.entity';
import { PostTagEntity } from '../database/entities/post-tag.entity';
import { TagFollowEntity } from '../database/entities/tag-follow.entity';
import { PostEntity } from '../database/entities/post.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([TagEntity, PostTagEntity, TagFollowEntity, PostEntity]),
  ],
  controllers: [TagsController],
  providers: [TagsService],
  exports: [TagsService],
})
export class TagsModule {}
