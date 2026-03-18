import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Skill } from '../database/entities/skill.entity';

@Injectable()
export class SkillsService implements OnModuleInit {
  constructor(
    @InjectRepository(Skill)
    private readonly skillRepo: Repository<Skill>,
    private readonly config: ConfigService,
  ) {}

  async onModuleInit(): Promise<void> {
    const env = this.config.get<string>('NODE_ENV', 'development');
    const shouldSeed =
      this.config.get<string>('SEED_DEV_DATA', env === 'development' ? 'true' : 'false') === 'true';
    if (!shouldSeed) return;

    const count = await this.skillRepo.count();
    if (count > 0) return;

    await this.skillRepo.insert([
      { name: 'Python', slug: 'python', category: 'programming' },
      { name: 'Machine Learning', slug: 'machine-learning', category: 'science' },
      { name: 'React', slug: 'react', category: 'programming' },
      { name: 'Data Analysis', slug: 'data-analysis', category: 'science' },
      { name: 'UI/UX Design', slug: 'ui-ux-design', category: 'design' },
    ]);
  }

  async list(category?: string) {
    const where = category ? { category } : {};
    const skills = await this.skillRepo.find({ where, order: { name: 'ASC' }, take: 500 });
    return { data: skills.map((s) => ({ id: s.id, name: s.name, slug: s.slug, category: s.category })) };
  }

  async search(q: string) {
    const query = (q ?? '').trim().toLowerCase();
    if (!query) return { data: [] };

    const skills = await this.skillRepo
      .createQueryBuilder('s')
      .where('LOWER(s.name) LIKE :q', { q: `%${query}%` })
      .orderBy('s.name', 'ASC')
      .take(50)
      .getMany();

    return { data: skills.map((s) => ({ id: s.id, name: s.name, slug: s.slug, category: s.category })) };
  }
}

