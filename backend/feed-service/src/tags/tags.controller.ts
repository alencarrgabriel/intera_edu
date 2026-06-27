import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Headers,
} from '@nestjs/common';
import { TagsService } from './tags.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller('tags')
export class TagsController {
  constructor(private readonly tags: TagsService) {}

  @Get()
  search(@Query('q') q?: string) {
    return this.tags.search(q);
  }

  @Get('trending')
  trending(@CurrentUser() user: JwtPayload) {
    return this.tags.trending(user);
  }

  @Get('mine')
  mine(@CurrentUser() user: JwtPayload) {
    return this.tags.myFollowed(user);
  }

  @Get(':slug')
  get(@Param('slug') slug: string, @CurrentUser() user: JwtPayload) {
    return this.tags.getBySlug(slug, user);
  }

  @Get(':slug/posts')
  posts(
    @Param('slug') slug: string,
    @Query('cursor') cursor: string,
    @CurrentUser() user: JwtPayload,
    @Headers('authorization') auth: string,
  ) {
    return this.tags.postsByTag(slug, cursor, user, auth ?? '');
  }

  @Post(':slug/follow')
  follow(@Param('slug') slug: string, @CurrentUser() user: JwtPayload) {
    return this.tags.follow(slug, user);
  }

  @Delete(':slug/follow')
  unfollow(@Param('slug') slug: string, @CurrentUser() user: JwtPayload) {
    return this.tags.unfollow(slug, user);
  }
}
