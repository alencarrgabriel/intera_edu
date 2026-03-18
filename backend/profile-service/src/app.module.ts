import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule, JwtAuthGuard } from '@interaedu/shared';
import { ProfileModule } from './profile/profile.module';
import { SkillsModule } from './skills/skills.module';
import { ConnectionsModule } from './connections/connections.module';
import { EventsModule } from './events/events.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    RedisModule,
    ProfileModule,
    SkillsModule,
    ConnectionsModule,
    EventsModule,
  ],
  controllers: [],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
