import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  Headers,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { v4 as uuidv4 } from 'uuid';
import { PostsService } from './posts.service';
import { S3Service } from './s3.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';
import { CreatePostDto } from './dto/create-post.dto';

const MAX_POST_FILE = 10 * 1024 * 1024;
const ALLOWED_POST_MIME = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
]);

@Controller('posts')
export class PostsController {
  constructor(
    private readonly postsService: PostsService,
    private readonly s3: S3Service,
  ) {}

  @Get()
  async getFeed(
    @Query('scope') scope: string,
    @Query('cursor') cursor: string,
    @Query('limit') limit: number,
    @CurrentUser() user: JwtPayload,
    @Headers('authorization') authToken: string,
  ) {
    return this.postsService.getFeed(scope || 'local', cursor, limit || 20, user, authToken ?? '');
  }

  /// RF-16 — Cria post com texto + arquivo opcional (img/pdf ≤10MB).
  @Post()
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_POST_FILE } }),
  )
  async createPost(
    @Body() dto: CreatePostDto,
    @UploadedFile() file: Express.Multer.File | undefined,
    @CurrentUser() user: JwtPayload,
  ) {
    if (file) {
      if (!ALLOWED_POST_MIME.has(file.mimetype)) {
        throw new BadRequestException(
          'Formato inválido — somente PDF, JPEG, PNG ou WebP.',
        );
      }
      const ext = file.mimetype.split('/')[1];
      const key = `posts/${user.sub}/${uuidv4()}.${ext}`;
      const url = await this.s3.putObject(key, file.buffer, file.mimetype);
      dto.media_urls = [...(dto.media_urls ?? []), url];
    }
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

  @Delete(':id/reactions')
  async removeReaction(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.postsService.removeReaction(id, user.sub);
  }

  @Get(':id/comments')
  async getComments(
    @Param('id') id: string,
    @Query('cursor') cursor: string,
    @Headers('authorization') authToken: string,
  ) {
    return this.postsService.getComments(id, cursor, authToken ?? '');
  }

  @Post(':id/comments')
  async addComment(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.postsService.addComment(id, dto, user.sub);
  }
}
