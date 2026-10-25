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
  Headers,
  UnauthorizedException,
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

  /// Service-to-service endpoint: a user JWT is not sufficient authorization.
  @Public()
  @Post('internal')
  async createInternal(@Body() body: any, @Headers('x-internal-token') token?: string) {
    const expected = process.env.INTERNAL_SERVICE_TOKEN;
    if (!expected || token !== expected) throw new UnauthorizedException('Invalid service token');
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
