import { Controller, Get, Post, Patch, Delete, Param, Query, Body } from '@nestjs/common';
import { CurrentUser, JwtPayload } from '@interaedu/shared';
import { ConnectionsService } from './connections.service';
import { CreateConnectionDto } from './dto/create-connection.dto';
import { UpdateConnectionDto } from './dto/update-connection.dto';

@Controller('connections')
export class ConnectionsController {
  constructor(private readonly connectionsService: ConnectionsService) {}

  @Get()
  async list(
    @CurrentUser() user: JwtPayload,
    @Query('status') status?: string,
    @Query('direction') direction?: string,
  ) {
    return this.connectionsService.list(user.sub, status, direction);
  }

  @Post()
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateConnectionDto) {
    return this.connectionsService.create(user.sub, dto);
  }

  @Patch(':id')
  async update(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateConnectionDto) {
    return this.connectionsService.update(user.sub, id, dto);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.connectionsService.remove(user.sub, id);
  }
}

