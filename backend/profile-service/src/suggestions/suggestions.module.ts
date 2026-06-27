import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SuggestionsController } from './suggestions.controller';
import { SuggestionsService } from './suggestions.service';
import { UserProfile } from '../database/entities/user-profile.entity';
import { UserSkill } from '../database/entities/user-skill.entity';
import { Connection } from '../database/entities/connection.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserProfile, UserSkill, Connection])],
  controllers: [SuggestionsController],
  providers: [SuggestionsService],
})
export class SuggestionsModule {}
