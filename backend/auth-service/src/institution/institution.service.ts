import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Institution } from '../database/entities/institution.entity';

@Injectable()
export class InstitutionService {
  private readonly logger = new Logger(InstitutionService.name);

  constructor(
    @InjectRepository(Institution)
    private readonly institutionRepo: Repository<Institution>,
  ) {}

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
