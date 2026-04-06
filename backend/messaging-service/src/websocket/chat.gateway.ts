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
import { JwtService } from '@nestjs/jwt';
import { ChatsService } from '../chats/chats.service';
import { JwtPayload } from '@interaedu/shared';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/ws',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  // Map from socket.id → user JwtPayload
  private readonly clients = new Map<string, JwtPayload>();

  constructor(
    private readonly chatsService: ChatsService,
    private readonly jwtService: JwtService,
  ) {}

  async handleConnection(client: Socket) {
    const token = client.handshake.auth?.token as string | undefined;
    if (!token) {
      this.logger.warn(`Socket ${client.id} disconnected: no token`);
      client.disconnect();
      return;
    }

    let payload: JwtPayload;
    try {
      payload = this.jwtService.verify<JwtPayload>(token);
    } catch {
      this.logger.warn(`Socket ${client.id} disconnected: invalid token`);
      client.disconnect();
      return;
    }

    this.clients.set(client.id, payload);

    // Join all chat rooms for this user
    const chatIds = await this.chatsService.getChatIdsForUser(payload.sub);
    for (const chatId of chatIds) {
      await client.join(`chat:${chatId}`);
    }

    this.logger.log(`Client connected: ${client.id} (user ${payload.sub})`);
  }

  async handleDisconnect(client: Socket) {
    this.clients.delete(client.id);
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('message:send')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; content: string },
  ) {
    const user = this.clients.get(client.id);
    if (!user) return { error: 'Unauthorized' };

    if (!data?.chatId || !data?.content?.trim()) {
      return { error: 'chatId and content are required' };
    }

    const message = await this.chatsService.persistAndBroadcast(
      data.chatId,
      user.sub,
      data.content.trim(),
    );

    if (!message) return { error: 'Not a member of this chat' };

    this.server.to(`chat:${data.chatId}`).emit('message:new', message);
    return { status: 'sent', message };
  }

  @SubscribeMessage('typing:start')
  handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string },
  ) {
    const user = this.clients.get(client.id);
    if (!user || !data?.chatId) return;
    client.to(`chat:${data.chatId}`).emit('typing:indicator', {
      chatId: data.chatId,
      userId: user.sub,
      isTyping: true,
    });
  }

  @SubscribeMessage('typing:stop')
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string },
  ) {
    const user = this.clients.get(client.id);
    if (!user || !data?.chatId) return;
    client.to(`chat:${data.chatId}`).emit('typing:indicator', {
      chatId: data.chatId,
      userId: user.sub,
      isTyping: false,
    });
  }

  /** Called externally to add a socket to a new chat room (e.g., after createChat). */
  async joinRoom(userId: string, chatId: string) {
    for (const [socketId, payload] of this.clients.entries()) {
      if (payload.sub === userId) {
        const sockets = await this.server.in(socketId).fetchSockets();
        for (const s of sockets) {
          await s.join(`chat:${chatId}`);
        }
      }
    }
  }
}
