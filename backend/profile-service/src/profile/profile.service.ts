import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, IsNull, DataSource } from 'typeorm';
import { JwtPayload } from '@interaedu/shared';
import { UserProfile } from '../database/entities/user-profile.entity';
import { UserSkill } from '../database/entities/user-skill.entity';
import { Skill } from '../database/entities/skill.entity';
import { UserLink } from '../database/entities/user-link.entity';
import { Connection } from '../database/entities/connection.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfileService {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    @InjectRepository(UserProfile)
    private readonly userRepo: Repository<UserProfile>,
    @InjectRepository(UserSkill)
    private readonly userSkillRepo: Repository<UserSkill>,
    @InjectRepository(Skill)
    private readonly skillRepo: Repository<Skill>,
    @InjectRepository(UserLink)
    private readonly linkRepo: Repository<UserLink>,
    @InjectRepository(Connection)
    private readonly connectionRepo: Repository<Connection>,
    private readonly dataSource: DataSource,
  ) {}

  /** Resolve institution name+slug via cross-schema query (all services share same DB). */
  private async getInstitution(institutionId: string): Promise<{ id: string; name: string; slug: string | null }> {
    const rows = await this.dataSource.query(
      `SELECT id, name, slug FROM auth.institutions WHERE id = $1 LIMIT 1`,
      [institutionId],
    );
    if (rows.length) return { id: rows[0].id, name: rows[0].name, slug: rows[0].slug ?? null };
    return { id: institutionId, name: '', slug: null };
  }

  /** Batch-resolve institution ids → { id, name, slug } map. */
  private async getInstitutionMap(ids: string[]): Promise<Map<string, { name: string; slug: string | null }>> {
    if (!ids.length) return new Map();
    const unique = [...new Set(ids)];
    const rows = await this.dataSource.query(
      `SELECT id, name, slug FROM auth.institutions WHERE id = ANY($1)`,
      [unique],
    );
    return new Map(rows.map((r: any) => [r.id, { name: r.name, slug: r.slug ?? null }]));
  }

  async findById(userId: string): Promise<any> {
    const user = await this.userRepo.findOne({ where: { id: userId, deletedAt: IsNull() } });
    if (!user) throw new NotFoundException('Profile not found');

    return this.toProfileResponse(user, userId);
  }

  async findByIdWithPrivacy(targetId: string, viewer: JwtPayload): Promise<any> {
    const target = await this.userRepo.findOne({ where: { id: targetId, deletedAt: IsNull() } });
    if (!target) throw new NotFoundException('Profile not found');

    if (target.id === viewer.sub) {
      return this.toProfileResponse(target, viewer.sub);
    }

    const sameInstitution = target.institutionId === viewer.institution_id;
    const connected = await this.areUsersConnected(viewer.sub, targetId);

    if (target.privacyLevel === 'public') {
      return this.toProfileResponse(target, viewer.sub);
    }

    if (target.privacyLevel === 'local_only') {
      if (!sameInstitution && !connected) throw new NotFoundException('Profile not found');
      return this.toProfileResponse(target, viewer.sub);
    }

    // private
    if (!connected) throw new NotFoundException('Profile not found');
    return this.toProfileResponse(target, viewer.sub);
  }

  async update(userId: string, dto: UpdateProfileDto): Promise<any> {
    const user = await this.userRepo.findOne({ where: { id: userId, deletedAt: IsNull() } });
    if (!user) throw new NotFoundException('Profile not found');

    if (dto.full_name !== undefined) user.fullName = dto.full_name;
    if (dto.bio !== undefined) user.bio = dto.bio;
    if (dto.course !== undefined) user.course = dto.course;
    if (dto.period !== undefined) user.period = dto.period;
    if (dto.privacy_level !== undefined) user.privacyLevel = dto.privacy_level;
    if (dto.avatar_url !== undefined) user.avatarUrl = dto.avatar_url;

    await this.userRepo.save(user);

    if (dto.skill_ids) {
      // Replace skills atomically-ish (best-effort in MVP; can wrap in txn later)
      await this.userSkillRepo.delete({ userId });

      const uniqueIds = Array.from(new Set(dto.skill_ids));
      const skills = await this.skillRepo.find({ where: { id: In(uniqueIds) } });
      const existingIds = new Set(skills.map((s) => s.id));
      const missing = uniqueIds.filter((id) => !existingIds.has(id));
      if (missing.length) throw new ForbiddenException('One or more skills do not exist.');

      await this.userSkillRepo.insert(uniqueIds.map((skillId) => ({ userId, skillId })));
    }

    return this.toProfileResponse(user, userId);
  }

  async findManyByIds(ids: string[]): Promise<any> {
    if (!ids.length) return { data: [] };
    const users = await this.userRepo.find({ where: ids.map((id) => ({ id, deletedAt: IsNull() })) });
    return {
      data: users.map((u) => ({
        id: u.id,
        full_name: u.fullName,
        avatar_url: u.avatarUrl ?? null,
        course: u.course ?? null,
        institution_id: u.institutionId,
      })),
    };
  }

  async requestDeletion(userId: string): Promise<any> {
    // TODO: Emit user.deleted event, schedule anonymization
    this.logger.log(`Deletion requested: ${userId}`);
    return {
      message: 'Account deletion scheduled. Data will be anonymized within 30 days.',
      deletion_scheduled_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    };
  }

  async requestDataExport(userId: string): Promise<any> {
    // TODO: Queue data export job via BullMQ
    this.logger.log(`Data export requested: ${userId}`);
    return {
      message: 'Data export is being generated. You will receive a download link via email within 48 hours.',
    };
  }

  async search(query: any, viewer: JwtPayload): Promise<any> {
    // MVP search: filters by name (q) + optional institution_id + course.
    // Privacy: exclude targets not visible to viewer per matrix.
    const q = typeof query.q === 'string' ? query.q.trim() : '';
    const institution = typeof query.institution === 'string' ? query.institution.trim() : '';
    const course = typeof query.course === 'string' ? query.course.trim() : '';
    const limit = Math.min(Math.max(parseInt(query.limit ?? '20', 10) || 20, 1), 50);

    const qb = this.userRepo.createQueryBuilder('u').where('u.deleted_at IS NULL');

    if (q) {
      qb.andWhere('LOWER(u.full_name) LIKE :q', { q: `%${q.toLowerCase()}%` });
    }
    if (institution) {
      qb.andWhere('u.institution_id = :inst', { inst: institution });
    }
    if (course) {
      qb.andWhere('LOWER(u.course) LIKE :course', { course: `%${course.toLowerCase()}%` });
    }

    qb.orderBy('u.created_at', 'DESC').take(limit + 1);

    const rows = await qb.getMany();
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    // Privacy filter in-app (connection-aware); for MVP this is OK.
    const visible: UserProfile[] = [];
    for (const candidate of page) {
      if (candidate.id === viewer.sub) continue;
      const sameInstitution = candidate.institutionId === viewer.institution_id;
      const connected = await this.areUsersConnected(viewer.sub, candidate.id);

      if (candidate.privacyLevel === 'public') visible.push(candidate);
      else if (candidate.privacyLevel === 'local_only' && (sameInstitution || connected)) visible.push(candidate);
      else if (candidate.privacyLevel === 'private' && connected) visible.push(candidate);
    }

    return {
      data: await Promise.all(visible.map((u) => this.toProfileCard(u))),
      pagination: { cursor: null, has_more: hasMore },
    };
  }

  private async areUsersConnected(a: string, b: string) {
    const existing = await this.connectionRepo.findOne({
      where: [
        { requesterId: a, addresseeId: b, status: 'accepted' },
        { requesterId: b, addresseeId: a, status: 'accepted' },
      ],
    });
    return !!existing;
  }

  private async toProfileResponse(user: UserProfile, viewerId: string) {
    const [links, userSkills, institution] = await Promise.all([
      this.linkRepo.find({ where: { userId: user.id } }),
      this.userSkillRepo.find({ where: { userId: user.id } }),
      this.getInstitution(user.institutionId),
    ]);
    const skills = userSkills.length
      ? await this.skillRepo.find({ where: { id: In(userSkills.map((us) => us.skillId)) } })
      : [];

    return {
      data: {
        id: user.id,
        email: user.email ?? '',
        full_name: user.fullName,
        bio: user.bio ?? null,
        course: user.course ?? null,
        period: user.period ?? null,
        privacy_level: user.privacyLevel,
        avatar_url: user.avatarUrl ?? null,
        institution: { id: institution.id, name: institution.name, slug: institution.slug },
        skills: skills.map((s) => ({ id: s.id, name: s.name, category: s.category })),
        links: links.map((l) => ({ id: l.id, type: l.linkType, url: l.url })),
        created_at: user.createdAt.toISOString(),
      },
    };
  }

  private async toProfileCard(user: UserProfile) {
    const [userSkills, institution] = await Promise.all([
      this.userSkillRepo.find({ where: { userId: user.id } }),
      this.getInstitution(user.institutionId),
    ]);
    const skills = userSkills.length
      ? await this.skillRepo.find({ where: { id: In(userSkills.map((us) => us.skillId)) }, take: 3 })
      : [];

    return {
      id: user.id,
      full_name: user.fullName,
      course: user.course ?? null,
      institution: { id: institution.id, name: institution.name, slug: institution.slug },
      skills: skills.map((s) => ({ id: s.id, name: s.name, category: s.category })),
      avatar_url: user.avatarUrl ?? null,
    };
  }
}
