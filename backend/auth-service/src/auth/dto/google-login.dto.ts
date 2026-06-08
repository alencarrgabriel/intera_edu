import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleLoginDto {
  /// ID Token JWT devolvido pelo Google Identity Services no front-end.
  @IsString()
  @IsNotEmpty()
  id_token: string;
}
