import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateConnectionDto {
  @IsUUID()
  addressee_id: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}

