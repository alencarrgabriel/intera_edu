import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Headers,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { StoriesService } from './stories.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

const MAX_STORY = 25 * 1024 * 1024;

@Controller('stories')
export class StoriesController {
  constructor(private readonly stories: StoriesService) {}

  @Get()
  list(@CurrentUser() user: JwtPayload, @Headers('authorization') auth: string) {
    return this.stories.listActive(user, auth ?? '');
  }

  @Get('mine')
  mine(@CurrentUser() user: JwtPayload) {
    return this.stories.myStories(user);
  }

  @Post()
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_STORY } }))
  create(
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: any,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.stories.create(file, body, user);
  }

  @Post(':id/view')
  view(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.stories.markViewed(id, user);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.stories.deleteStory(id, user);
  }
}
