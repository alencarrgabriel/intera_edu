import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MaterialsService } from './materials.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

const MAX_MATERIAL = 50 * 1024 * 1024;

@Controller()
export class MaterialsController {
  constructor(private readonly materials: MaterialsService) {}

  @Get('groups/:id/materials')
  list(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.materials.list(id, user);
  }

  @Post('groups/:id/materials')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_MATERIAL } }))
  upload(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: any,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.materials.upload(id, file, body, user);
  }

  @Get('materials/:id/download')
  download(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.materials.download(id, user);
  }

  @Post('materials/:id/rate')
  rate(@Param('id') id: string, @Body() body: any, @CurrentUser() user: JwtPayload) {
    return this.materials.rate(id, body.rating, user);
  }

  @Delete('materials/:id')
  remove(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.materials.remove(id, user);
  }
}
