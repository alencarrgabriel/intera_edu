import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { ChatsService } from './chats.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller('chats')
export class ChatsController {
  constructor(private readonly chatsService: ChatsService) {}

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

  @Post(':id/messages')
  async sendMessage(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: JwtPayload) {
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
