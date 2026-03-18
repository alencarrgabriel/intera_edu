import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Institution } from '../database/entities/institution.entity';

@Injectable()
export class InstitutionService implements OnModuleInit {
  private readonly logger = new Logger(InstitutionService.name);

  constructor(
    @InjectRepository(Institution)
    private readonly institutionRepo: Repository<Institution>,
    private readonly config: ConfigService,
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
        domains: ['aluno.ufmg.br', 'ufmg.br'],
        isVerified: true,
      },
      {
        name: 'Universidade de São Paulo (USP)',
        slug: 'usp',
        domains: ['usp.br', 'alumni.usp.br'],
        isVerified: true,
      },
    ]);

    this.logger.log('Seeded dev institutions');
  }

  /**
   * Find institution by extracting the domain from an email address.
   * Checks against the `domains` array column.
   */
  async findByEmailDomain(email: string): Promise<Institution | null> {
    const domain = email.split('@')[1]?.toLowerCase();
    if (!domain) {
      return null;
    }

    // Query for institution where the domain array contains this domain
    const institution = await this.institutionRepo
      .createQueryBuilder('institution')
      .where(':domain = ANY(institution.domains)', { domain })
      .andWhere('institution.is_verified = :verified', { verified: true })
      .getOne();

    return institution;
  }

  async findById(id: string): Promise<Institution | null> {
    return this.institutionRepo.findOne({ where: { id } });
  }

  async findAll(): Promise<Institution[]> {
    return this.institutionRepo.find({ where: { isVerified: true } });
  }
}
