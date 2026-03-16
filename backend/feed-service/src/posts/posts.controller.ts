import { Controller, Get, Post, Delete, Body, Param, Query } from '@nestjs/common';
import { PostsService } from './posts.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  async getFeed(
    @Query('scope') scope: string,
    @Query('cursor') cursor: string,
    @Query('limit') limit: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.postsService.getFeed(scope || 'local', cursor, limit || 20, user);
  }

  @Post()
  async createPost(@Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.postsService.create(dto, user);
  }

  @Get(':id')
  async getPost(@Param('id') id: string) {
    return this.postsService.findById(id);
  }

  @Delete(':id')
  async deletePost(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.postsService.softDelete(id, user.sub);
  }

  @Post(':id/reactions')
  async addReaction(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.postsService.addReaction(id, dto.type, user.sub);
  }

  @Get(':id/comments')
  async getComments(@Param('id') id: string, @Query('cursor') cursor: string) {
    return this.postsService.getComments(id, cursor);
  }

  @Post(':id/comments')
  async addComment(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.postsService.addComment(id, dto, user.sub);
  }
}
