import { IsArray, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @MaxLength(5000)
  content: string;

  @IsOptional()
  @IsIn(['local', 'global'])
  scope?: 'local' | 'global';

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  media_urls?: string[];
}

