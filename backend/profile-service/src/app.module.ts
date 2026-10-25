import { Module } from '@nestjs/common';
import { HealthController } from '@interaedu/shared';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule, JwtAuthGuard, JwtStrategy, AuditModule } from '@interaedu/shared';
import { ProfileModule } from './profile/profile.module';
import { SkillsModule } from './skills/skills.module';
import { ConnectionsModule } from './connections/connections.module';
import { EventsModule } from './events/events.module';
import { BlocksModule } from './blocks/blocks.module';
import { SuggestionsModule } from './suggestions/suggestions.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    RedisModule,
    ProfileModule,
    SkillsModule,
    ConnectionsModule,
    EventsModule,
    BlocksModule,
    SuggestionsModule,
    AuditModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    JwtStrategy,
  ],
})
export class AppModule {}
