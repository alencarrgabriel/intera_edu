import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
} from '@nestjs/common';
import { GroupsService } from './groups.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller()
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) {}

  @Get('disciplines')
  listDisciplines(@CurrentUser() user: JwtPayload, @Query('q') q?: string) {
    return this.groupsService.listDisciplines(user, q);
  }

  @Post('disciplines')
  createDiscipline(@Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.groupsService.createDiscipline(dto, user);
  }

  @Get('groups')
  listGroups(
    @CurrentUser() user: JwtPayload,
    @Query('mine') mine?: string,
    @Query('q') q?: string,
  ) {
    return this.groupsService.listGroups(user, {
      mine: mine === 'true' || mine === '1',
      q,
    });
  }

  @Post('groups')
  createGroup(@Body() dto: any, @CurrentUser() user: JwtPayload) {
    return this.groupsService.createGroup(dto, user);
  }

  @Get('groups/:id')
  getGroup(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.groupsService.getGroup(id, user);
  }

  @Post('groups/:id/join')
  joinGroup(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.groupsService.joinGroup(id, user);
  }

  @Delete('groups/:id/join')
  leaveGroup(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.groupsService.leaveGroup(id, user);
  }

  @Get('groups/:id/members')
  listMembers(@Param('id') id: string) {
    return this.groupsService.listMembers(id);
  }
}
