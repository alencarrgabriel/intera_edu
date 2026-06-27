import { Controller, Get, Param, Query, Headers } from '@nestjs/common';
import { PostsService } from './posts.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller()
export class GroupFeedController {
  constructor(private readonly postsService: PostsService) {}

  @Get('groups/:id/feed')
  groupFeed(
    @Param('id') id: string,
    @Query('cursor') cursor: string,
    @Query('limit') limit: number,
    @CurrentUser() user: JwtPayload,
    @Headers('authorization') authToken: string,
  ) {
    return this.postsService.getGroupFeed(id, cursor, limit || 20, user, authToken ?? '');
  }
}
