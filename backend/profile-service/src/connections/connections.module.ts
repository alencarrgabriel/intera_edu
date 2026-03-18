import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConnectionsController } from './connections.controller';
import { ConnectionsService } from './connections.service';
import { Connection } from '../database/entities/connection.entity';
import { UserProfile } from '../database/entities/user-profile.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Connection, UserProfile])],
  controllers: [ConnectionsController],
  providers: [ConnectionsService],
})
export class ConnectionsModule {}

