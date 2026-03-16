import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InstitutionService } from './institution.service';
import { Institution } from '../database/entities/institution.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Institution])],
  providers: [InstitutionService],
  exports: [InstitutionService],
})
export class InstitutionModule {}
