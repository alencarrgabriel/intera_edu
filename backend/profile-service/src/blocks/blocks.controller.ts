import {
  Controller,
  Post,
  Delete,
  Get,
  Param,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { BlocksService } from './blocks.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller('users/me/blocks')
export class BlocksController {
  constructor(private readonly blocks: BlocksService) {}

  @Get()
  async list(@CurrentUser() user: JwtPayload) {
    const ids = await this.blocks.listBlocked(user.sub);
    return { data: ids };
  }

  @Post(':userId')
  @HttpCode(HttpStatus.CREATED)
  async block(
    @Param('userId') blockedId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.blocks.block(user.sub, blockedId);
  }

  @Delete(':userId')
  @HttpCode(HttpStatus.OK)
  async unblock(
    @Param('userId') blockedId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.blocks.unblock(user.sub, blockedId);
  }
}
