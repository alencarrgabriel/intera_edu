import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule, JwtAuthGuard, JwtStrategy } from '@interaedu/shared';
import { PostsModule } from './posts/posts.module';
import { FeedModule } from './feed/feed.module';
import { ReportsModule } from './reports/reports.module';
import { GroupsModule } from './groups/groups.module';
import { MaterialsModule } from './materials/materials.module';
import { BookmarksModule } from './bookmarks/bookmarks.module';
import { StoriesModule } from './stories/stories.module';
import { TagsModule } from './tags/tags.module';
import { MentionsModule } from './mentions/mentions.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    RedisModule,
    PostsModule,
    FeedModule,
    ReportsModule,
    GroupsModule,
    MaterialsModule,
    BookmarksModule,
    StoriesModule,
    TagsModule,
    MentionsModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    JwtStrategy,
  ],
})
export class AppModule {}
