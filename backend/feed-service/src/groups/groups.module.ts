import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GroupsController } from './groups.controller';
import { GroupsService } from './groups.service';
import { DisciplineEntity } from '../database/entities/discipline.entity';
import { DisciplineGroupEntity } from '../database/entities/discipline-group.entity';
import { GroupMemberEntity } from '../database/entities/group-member.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([DisciplineEntity, DisciplineGroupEntity, GroupMemberEntity]),
  ],
  controllers: [GroupsController],
  providers: [GroupsService],
  exports: [GroupsService],
})
export class GroupsModule {}
