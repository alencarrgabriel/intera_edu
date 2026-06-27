import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { CurrentUser, JwtPayload, Public } from '@interaedu/shared';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  async list(
    @CurrentUser() user: JwtPayload,
    @Query('unread') unread?: string,
  ) {
    return this.notifications.list(user.sub, unread === 'true');
  }

  @Patch(':id/read')
  @HttpCode(HttpStatus.OK)
  async markRead(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.notifications.markRead(user.sub, id);
  }

  @Patch('read-all')
  @HttpCode(HttpStatus.OK)
  async markAllRead(@CurrentUser() user: JwtPayload) {
    return this.notifications.markAllRead(user.sub);
  }

  /// Internal-service-only endpoint. Trusted callers (feed-service, profile-service)
  /// post mentions/event notifications here. Production deploys should fence this
  /// behind an internal network or a service token; in dev it's open.
  @Public()
  @Post('internal')
  async createInternal(@Body() body: any) {
    if (!body?.user_id || !body?.type || !body?.title) return { ok: false };
    return this.notifications.create(
      body.user_id,
      body.type,
      body.title,
      body.body ?? null,
      body.payload ?? null,
    );
  }
}
