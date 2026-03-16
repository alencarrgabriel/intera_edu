import {
  IsString,
  IsNotEmpty,
  MinLength,
  MaxLength,
  Matches,
  ValidateNested,
  IsArray,
  IsOptional,
} from 'class-validator';
import { Type } from 'class-transformer';

class ConsentDto {
  @IsString()
  @IsNotEmpty()
  terms_version: string;

  @IsString()
  @IsNotEmpty()
  privacy_version: string;
}

export class CompleteRegistrationDto {
  @IsString()
  @IsNotEmpty()
  temporary_token: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/, {
    message: 'Password must contain uppercase, lowercase, number, and special character',
  })
  password: string;

  @IsString()
  @IsNotEmpty()
  full_name: string;

  @IsString()
  @IsOptional()
  course?: string;

  @IsOptional()
  period?: number;

  @IsArray()
  @IsOptional()
  skill_ids?: string[];

  @ValidateNested()
  @Type(() => ConsentDto)
  consent: ConsentDto;
}
