import { Controller, Get, Post, Delete, Param, Headers } from '@nestjs/common';
import { BookmarksService } from './bookmarks.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller()
export class BookmarksController {
  constructor(private readonly bookmarks: BookmarksService) {}

  @Get('bookmarks')
  list(@CurrentUser() user: JwtPayload, @Headers('authorization') auth: string) {
    return this.bookmarks.list(user, auth ?? '');
  }

  @Post('posts/:id/bookmark')
  add(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.bookmarks.add(id, user);
  }

  @Delete('posts/:id/bookmark')
  remove(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.bookmarks.remove(id, user);
  }
}
