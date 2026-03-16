import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*', // Configure properly in production
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  async handleConnection(client: Socket) {
    // TODO: Authenticate via JWT in handshake headers
    // const token = client.handshake.auth.token;
    // Validate and extract user info
    // Join user to their chat rooms
    this.logger.log(`Client connected: ${client.id}`);
  }

  async handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('message:send')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; content: string; fileUrl?: string },
  ) {
    // TODO: Persist message to database
    // TODO: Broadcast to chat room via Redis pub/sub

    const message = {
      messageId: 'uuid',
      chatId: data.chatId,
      senderId: 'user-uuid', // Extract from authenticated socket
      content: data.content,
      fileUrl: data.fileUrl,
      sentAt: new Date().toISOString(),
    };

    this.server.to(`chat:${data.chatId}`).emit('message:new', message);

    return { status: 'sent', messageId: message.messageId };
  }

  @SubscribeMessage('message:read')
  async handleReadReceipt(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; lastReadMessageId: string },
  ) {
    // TODO: Update read receipt in database
    this.server.to(`chat:${data.chatId}`).emit('message:read_update', {
      chatId: data.chatId,
      userId: 'user-uuid',
      lastReadMessageId: data.lastReadMessageId,
    });
  }

  @SubscribeMessage('typing:start')
  async handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string },
  ) {
    client.to(`chat:${data.chatId}`).emit('typing:indicator', {
      chatId: data.chatId,
      userId: 'user-uuid',
      isTyping: true,
    });
  }

  @SubscribeMessage('typing:stop')
  async handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string },
  ) {
    client.to(`chat:${data.chatId}`).emit('typing:indicator', {
      chatId: data.chatId,
      userId: 'user-uuid',
      isTyping: false,
    });
  }
}
