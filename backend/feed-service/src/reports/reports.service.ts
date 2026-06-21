import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Report } from './report.entity';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Report)
    private readonly repo: Repository<Report>,
  ) {}

  async create(
    reporterId: string,
    dto: {
      target_type: string;
      target_id: string;
      reason?: string;
      description?: string;
    },
  ) {
    const allowedTypes = ['post', 'comment', 'user', 'chat'];
    const type = allowedTypes.includes(dto.target_type)
      ? dto.target_type
      : 'other';
    const row = await this.repo.save({
      reporterId,
      targetType: type,
      targetId: dto.target_id,
      reason: dto.reason ?? 'other',
      description: dto.description ?? null,
      status: 'open',
    });
    return { id: row.id, status: row.status };
  }

  async listOpen() {
    return this.repo.find({
      where: { status: 'open' },
      order: { createdAt: 'DESC' },
      take: 200,
    });
  }

  async resolve(
    reportId: string,
    moderatorId: string,
    decision: 'resolve' | 'dismiss',
  ) {
    const row = await this.repo.findOne({ where: { id: reportId } });
    if (!row) return null;
    row.status = decision === 'resolve' ? 'resolved' : 'dismissed';
    row.resolvedAt = new Date();
    row.resolvedBy = moderatorId;
    return this.repo.save(row);
  }
}
