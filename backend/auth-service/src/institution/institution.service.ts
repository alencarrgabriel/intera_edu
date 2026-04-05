import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Institution } from '../database/entities/institution.entity';
import { RedisService } from '@interaedu/shared';

const INSTITUTION_CACHE_TTL = 3600;    // 1 hora — dados mudam raramente
const INSTITUTION_NEGATIVE_TTL = 300;  // 5 min — previne flood de domínios inválidos
const CACHE_NULL = '__null__';

@Injectable()
export class InstitutionService implements OnModuleInit {
  private readonly logger = new Logger(InstitutionService.name);

  constructor(
    @InjectRepository(Institution)
    private readonly institutionRepo: Repository<Institution>,
    private readonly config: ConfigService,
    private readonly redis: RedisService,
  ) {}

  async onModuleInit(): Promise<void> {
    const env = this.config.get<string>('NODE_ENV', 'development');
    const shouldSeed =
      this.config.get<string>('SEED_DEV_DATA', env === 'development' ? 'true' : 'false') === 'true';

    if (!shouldSeed) return;

    const count = await this.institutionRepo.count();
    if (count > 0) return;

    await this.institutionRepo.insert([
      {
        name: 'Universidade Federal de Minas Gerais (UFMG)',
        slug: 'ufmg',
        domains: ['aluno.ufmg.br', 'ufmg.br', 'ufmg.edu.br'],
        isVerified: true,
      },
      {
        name: 'Universidade de São Paulo (USP)',
        slug: 'usp',
        domains: ['usp.br', 'alumni.usp.br', 'usp.edu.br'],
        isVerified: true,
      },
      {
        name: 'Universidade Estadual de Campinas (UNICAMP)',
        slug: 'unicamp',
        domains: ['unicamp.br', 'dac.unicamp.br', 'unicamp.edu.br'],
        isVerified: true,
      },
      {
        name: 'Universidade Federal de São Paulo (UNIFESP)',
        slug: 'unifesp',
        domains: ['unifesp.br', 'unifesp.edu.br'],
        isVerified: true,
      },
      {
        name: 'Centro Universitário de Brasília (CEUB)',
        slug: 'ceub',
        domains: ['ceub.edu.br', 'sempreceub.com'],
        isVerified: true,
      },
      {
        name: 'Universidade de Brasília (UnB)',
        slug: 'unb',
        domains: ['unb.br', 'aluno.unb.br', 'unb.edu.br'],
        isVerified: true,
      },
    ]);

    this.logger.log('Seeded dev institutions');
  }

  /**
   * Busca instituição pelo domínio do e-mail com cache Redis.
   * Cache positivo: 1h | Cache negativo (domínio inválido): 5min.
   */
  async findByEmailDomain(email: string): Promise<Institution | null> {
    const domain = email.split('@')[1]?.toLowerCase();
    if (!domain) return null;

    const cacheKey = `institution:domain:${domain}`;

    // 1. Tentar cache
    const cached = await this.redis.get(cacheKey);
    if (cached !== null) {
      return cached === CACHE_NULL ? null : (JSON.parse(cached) as Institution);
    }

    // 2. Cache miss — consultar banco
    const institution = await this.institutionRepo
      .createQueryBuilder('institution')
      .where(':domain = ANY(institution.domains)', { domain })
      .andWhere('institution.is_verified = :verified', { verified: true })
      .getOne();

    // 3. Armazenar resultado (positivo ou negativo)
    if (institution) {
      await this.redis.set(cacheKey, JSON.stringify(institution), INSTITUTION_CACHE_TTL);
    } else {
      await this.redis.set(cacheKey, CACHE_NULL, INSTITUTION_NEGATIVE_TTL);
    }

    return institution;
  }

  async findById(id: string): Promise<Institution | null> {
    return this.institutionRepo.findOne({ where: { id } });
  }

  async findAll(): Promise<Institution[]> {
    return this.institutionRepo.find({ where: { isVerified: true } });
  }
}
