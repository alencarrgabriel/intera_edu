import { Controller, Get } from '@nestjs/common';
import { SuggestionsService } from './suggestions.service';
import { CurrentUser, JwtPayload } from '@interaedu/shared';

@Controller('users/me/suggestions')
export class SuggestionsController {
  constructor(private readonly suggestions: SuggestionsService) {}

  @Get()
  list(@CurrentUser() user: JwtPayload) {
    return this.suggestions.suggest(user);
  }
}
