import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RedisModule } from '@interaedu/shared';
import { InstitutionService } from './institution.service';
import { InstitutionController } from './institution.controller';
import { Institution } from '../database/entities/institution.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Institution]), RedisModule],
  providers: [InstitutionService],
  controllers: [InstitutionController],
  exports: [InstitutionService],
})
export class InstitutionModule {}
