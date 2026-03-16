import { Module } from '@nestjs/common';

@Module({})
export class FeedModule {}
// TODO: Feed generation pipeline
// - Force Exploration algorithm
// - Redis cache management
// - Feed invalidation on post.created/deleted events
