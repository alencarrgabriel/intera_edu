import { Controller, Get, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get('me')
  async getMyProfile(@CurrentUser() user: JwtPayload) {
    return this.profileService.findById(user.sub);
  }

  @Patch('me')
  async updateMyProfile(@CurrentUser() user: JwtPayload, @Body() dto: UpdateProfileDto) {
    return this.profileService.update(user.sub, dto);
  }

  @Delete('me')
  async deleteMyAccount(@CurrentUser() user: JwtPayload) {
    return this.profileService.requestDeletion(user.sub);
  }

  @Get('me/data-export')
  async requestDataExport(@CurrentUser() user: JwtPayload) {
    return this.profileService.requestDataExport(user.sub);
  }

  @Get('search')
  async searchUsers(@Query() query: any, @CurrentUser() user: JwtPayload) {
    return this.profileService.search(query, user);
  }

  /** Internal batch endpoint — used by feed-service to enrich author data. */
  @Get('batch')
  async batchGet(@Query('ids') ids: string) {
    const idList = (ids ?? '').split(',').filter(Boolean).slice(0, 50);
    return this.profileService.findManyByIds(idList);
  }

  @Get(':id')
  async getProfile(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.profileService.findByIdWithPrivacy(id, user);
  }
}
