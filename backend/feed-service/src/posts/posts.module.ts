import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';
import { S3Service } from './s3.service';
import { PostEntity } from '../database/entities/post.entity';
import { ReactionEntity } from '../database/entities/reaction.entity';
import { CommentEntity } from '../database/entities/comment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PostEntity, ReactionEntity, CommentEntity])],
  controllers: [PostsController],
  providers: [PostsService, S3Service],
  exports: [PostsService],
})
export class PostsModule {}
