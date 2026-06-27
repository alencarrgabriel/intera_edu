import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StoriesController } from './stories.controller';
import { StoriesService } from './stories.service';
import { StoryEntity } from '../database/entities/story.entity';
import { StoryViewEntity } from '../database/entities/story-view.entity';
import { S3Service } from '../posts/s3.service';

@Module({
  imports: [TypeOrmModule.forFeature([StoryEntity, StoryViewEntity])],
  controllers: [StoriesController],
  providers: [StoriesService, S3Service],
})
export class StoriesModule {}
