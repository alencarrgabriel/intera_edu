import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { v4 as uuidv4 } from 'uuid';
import { ChatsService } from './chats.service';
import { S3Service } from './s3.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

const MAX_CHAT_FILE = 10 * 1024 * 1024; // RN-08 — 10MB
const ALLOWED_MIME = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
]);

@Controller('chats')
export class ChatsController {
  constructor(
    private readonly chatsService: ChatsService,
    private readonly s3: S3Service,
  ) {}

  @Get()
  async listChats(
    @Query('type') type: string,
    @Query('cursor') cursor: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.chatsService.listChats(user.sub, type, cursor);
  }

  @Post()
  async createChat(@Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.chatsService.createChat(dto, user.sub);
  }

  @Get(':id')
  async getChat(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.chatsService.getChat(id, user.sub);
  }

  @Patch(':id')
  async updateChat(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.chatsService.updateChat(id, dto, user.sub);
  }

  @Get(':id/messages')
  async getMessages(
    @Param('id') id: string,
    @Query('cursor') cursor: string,
    @Query('limit') limit: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.chatsService.getMessages(id, user.sub, cursor, limit || 50);
  }

  /// RF-25 — Envia mensagem de texto (JSON) OU RF-27 anexa arquivo (multipart).
  /// O multipart proxy do gateway encaminha o stream original; NestJS detecta
  /// `file` via FileInterceptor quando o Content-Type é multipart.
  @Post(':id/messages')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_CHAT_FILE } }),
  )
  async sendMessage(
    @Param('id') id: string,
    @Body() dto: any,
    @UploadedFile() file: Express.Multer.File | undefined,
    @CurrentUser() user: JwtPayload,
  ) {
    if (file) {
      if (!ALLOWED_MIME.has(file.mimetype)) {
        throw new BadRequestException(
          'Formato inválido — somente PDF, JPEG, PNG ou WebP.',
        );
      }
      const ext = file.mimetype.split('/')[1];
      const key = `chats/${id}/${uuidv4()}.${ext}`;
      const url = await this.s3.putObject(key, file.buffer, file.mimetype);
      return this.chatsService.sendMessage(
        id,
        { content: dto?.content ?? '', file_url: url },
        user.sub,
      );
    }
    return this.chatsService.sendMessage(id, dto, user.sub);
  }

  @Post(':id/members')
  async addMember(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.chatsService.addMember(id, dto.user_id, user.sub);
  }

  @Delete(':id/members/:userId')
  async removeMember(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.chatsService.removeMember(id, userId, user.sub);
  }
}
