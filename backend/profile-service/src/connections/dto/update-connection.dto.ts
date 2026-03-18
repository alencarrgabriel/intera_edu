import { IsIn } from 'class-validator';

export class UpdateConnectionDto {
  @IsIn(['accept', 'reject'])
  action: 'accept' | 'reject';
}

