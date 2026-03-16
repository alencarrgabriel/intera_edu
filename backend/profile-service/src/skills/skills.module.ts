import { Module } from '@nestjs/common';

@Module({
  controllers: [],
  providers: [],
})
export class SkillsModule {}
// TODO: Implement skill taxonomy CRUD
// - GET /skills (list all, by category)
// - GET /skills/search?q=<query>
// - Admin: POST/PATCH/DELETE /skills
