import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule, JwtAuthGuard, JwtStrategy } from '@interaedu/shared';
import { APP_GUARD } from '@nestjs/core';
import { ChatsModule } from './chats/chats.module';
import { WebsocketModule } from './websocket/websocket.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    RedisModule,
    ChatsModule,
    WebsocketModule,
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
