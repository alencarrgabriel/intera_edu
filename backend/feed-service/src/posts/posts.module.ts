import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PostsController } from './posts.controller';
import { GroupFeedController } from './group-feed.controller';
import { PostsService } from './posts.service';
import { S3Service } from './s3.service';
import { PostEntity } from '../database/entities/post.entity';
import { ReactionEntity } from '../database/entities/reaction.entity';
import { CommentEntity } from '../database/entities/comment.entity';
import { TagsModule } from '../tags/tags.module';
import { MentionsModule } from '../mentions/mentions.module';
import { BookmarksModule } from '../bookmarks/bookmarks.module';
import { GroupsModule } from '../groups/groups.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PostEntity, ReactionEntity, CommentEntity]),
    TagsModule,
    MentionsModule,
    BookmarksModule,
    GroupsModule,
  ],
  controllers: [PostsController, GroupFeedController],
  providers: [PostsService, S3Service],
  exports: [PostsService],
})
export class PostsModule {}
