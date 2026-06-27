import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookmarksController } from './bookmarks.controller';
import { BookmarksService } from './bookmarks.service';
import { BookmarkEntity } from '../database/entities/bookmark.entity';
import { PostEntity } from '../database/entities/post.entity';

@Module({
  imports: [TypeOrmModule.forFeature([BookmarkEntity, PostEntity])],
  controllers: [BookmarksController],
  providers: [BookmarksService],
  exports: [BookmarksService],
})
export class BookmarksModule {}
