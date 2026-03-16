import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule, RedisModule } from '@interaedu/shared';
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
})
export class AppModule {}
