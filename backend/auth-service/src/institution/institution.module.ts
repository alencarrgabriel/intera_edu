import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RedisModule } from '@interaedu/shared';
import { InstitutionService } from './institution.service';
import { Institution } from '../database/entities/institution.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Institution]), RedisModule],
  providers: [InstitutionService],
  exports: [InstitutionService],
})
export class InstitutionModule {}
