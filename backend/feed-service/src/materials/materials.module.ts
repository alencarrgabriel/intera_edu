import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MaterialsController } from './materials.controller';
import { MaterialsService } from './materials.service';
import { MaterialEntity } from '../database/entities/material.entity';
import { MaterialRatingEntity } from '../database/entities/material-rating.entity';
import { S3Service } from '../posts/s3.service';
import { GroupsModule } from '../groups/groups.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([MaterialEntity, MaterialRatingEntity]),
    GroupsModule,
  ],
  controllers: [MaterialsController],
  providers: [MaterialsService, S3Service],
})
export class MaterialsModule {}
