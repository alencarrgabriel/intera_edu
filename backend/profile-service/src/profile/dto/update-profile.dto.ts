import { IsInt, IsOptional, IsString, IsUrl, MaxLength, Min, IsIn, IsArray } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  full_name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  bio?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  course?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  period?: number;

  @IsOptional()
  @IsIn(['public', 'local_only', 'private'])
  privacy_level?: 'public' | 'local_only' | 'private';

  @IsOptional()
  @IsUrl()
  avatar_url?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  skill_ids?: string[];
}

