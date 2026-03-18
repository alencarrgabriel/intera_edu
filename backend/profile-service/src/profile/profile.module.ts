import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';
import { UserProfile } from '../database/entities/user-profile.entity';
import { UserSkill } from '../database/entities/user-skill.entity';
import { Skill } from '../database/entities/skill.entity';
import { UserLink } from '../database/entities/user-link.entity';
import { Connection } from '../database/entities/connection.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserProfile, UserSkill, Skill, UserLink, Connection])],
  controllers: [ProfileController],
  providers: [ProfileService],
  exports: [ProfileService],
})
export class ProfileModule {}
