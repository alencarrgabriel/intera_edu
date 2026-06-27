import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, IsNull, DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { JwtPayload } from '@interaedu/shared';
import { UserProfile } from '../database/entities/user-profile.entity';
import { UserSkill } from '../database/entities/user-skill.entity';
import { Skill } from '../database/entities/skill.entity';
import { UserLink } from '../database/entities/user-link.entity';
import { Connection } from '../database/entities/connection.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { S3Service } from './s3.service';

const ALLOWED_AVATAR_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX_AVATAR_BYTES = 5 * 1024 * 1024; // 5 MB

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
    private readonly s3: S3Service,
  ) {}

  /**
   * Faz upload do avatar para o object storage e atualiza o perfil.
   * Retorna a URL pública para uso no cliente.
   */
  async uploadAvatar(
    userId: string,
    file: { buffer: Buffer; mimetype: string; size: number },
  ): Promise<{ avatar_url: string }> {
    if (!file?.buffer) throw new BadRequestException('Arquivo ausente');
    if (!ALLOWED_AVATAR_MIME.has(file.mimetype)) {
      throw new BadRequestException(
        'Formato inválido — use JPEG, PNG ou WebP',
      );
    }
    if (file.size > MAX_AVATAR_BYTES) {
      throw new BadRequestException('Imagem maior que 5 MB');
    }

    const user = await this.userRepo.findOne({
      where: { id: userId, deletedAt: IsNull() },
    });
    if (!user) throw new NotFoundException('Profile not found');

    const ext = file.mimetype === 'image/png'
      ? 'png'
      : file.mimetype === 'image/webp'
        ? 'webp'
        : 'jpg';
    const key = `avatars/${userId}/${uuidv4()}.${ext}`;
    const url = await this.s3.putObject(key, file.buffer, file.mimetype);

    user.avatarUrl = url;
    await this.userRepo.save(user);

    return { avatar_url: url };
  }

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
    if (dto.handle !== undefined && dto.handle && dto.handle !== user.handle) {
      const taken = await this.userRepo.findOne({ where: { handle: dto.handle } });
      if (taken && taken.id !== user.id) {
        throw new ForbiddenException('Handle já em uso');
      }
      user.handle = dto.handle;
    }

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
        handle: u.handle ?? null,
        avatar_url: u.avatarUrl ?? null,
        course: u.course ?? null,
        institution_id: u.institutionId,
      })),
    };
  }

  /// Resolve uma lista de handles ('@usuario') para ids.
  /// Usado por feed-service para criar notificações de mention.
  async findManyByHandles(handles: string[]): Promise<any> {
    if (!handles.length) return { data: [] };
    const users = await this.userRepo.find({
      where: handles.map((h) => ({ handle: h, deletedAt: IsNull() })),
    });
    return {
      data: users.map((u) => ({
        id: u.id,
        handle: u.handle ?? null,
        full_name: u.fullName,
        avatar_url: u.avatarUrl ?? null,
      })),
    };
  }

  async findByHandle(handle: string, viewer: JwtPayload): Promise<any> {
    const target = await this.userRepo.findOne({
      where: { handle: handle.toLowerCase(), deletedAt: IsNull() },
    });
    if (!target) throw new NotFoundException('Profile not found');
    return this.findByIdWithPrivacy(target.id, viewer);
  }

  /// RF-31 — Marca conta para exclusão. Anonymizaçao em 30 dias é executada
  /// pelos subscribers do evento `user.deletion_requested` em cada serviço.
  async requestDeletion(userId: string): Promise<any> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    // 1. Marca soft delete imediato no profile-service.
    user.deletedAt = new Date();
    await this.userRepo.save(user);

    // 2. Limpa relações ativas — RN-10.
    await this.connectionRepo.delete({ requesterId: userId });
    await this.connectionRepo.delete({ addresseeId: userId });

    // 3. Publica evento para os outros serviços anonimizarem em cascata.
    const eventChannel = 'interaedu.events';
    await this.dataSource.query(
      `SELECT pg_notify($1, $2)`,
      [
        eventChannel,
        JSON.stringify({
          type: 'user.deletion_requested',
          payload: { userId, requestedAt: new Date().toISOString() },
          occurredAt: new Date().toISOString(),
        }),
      ],
    );

    this.logger.log(`Deletion requested + cascade triggered: ${userId}`);
    return {
      message:
        'Conta marcada para exclusão. Anonimização em até 30 dias conforme LGPD.',
      deletion_scheduled_at: new Date(
        Date.now() + 30 * 24 * 60 * 60 * 1000,
      ).toISOString(),
    };
  }

  /// RF-30 — Coleta dados do usuário e devolve JSON inline. Para volumes
  /// grandes seria empurrado para um worker BullMQ + upload no MinIO; no
  /// MVP cabe inline por estarmos abaixo do limite de 1MB por usuário.
  async requestDataExport(userId: string): Promise<any> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const skills = await this.userSkillRepo.find({ where: { userId } });
    const skillIds = skills.map((s) => s.skillId);
    const skillRows = skillIds.length
      ? await this.skillRepo.find({ where: { id: In(skillIds) } })
      : [];

    const connections = await this.connectionRepo.find({
      where: [{ requesterId: userId }, { addresseeId: userId }],
    });

    const institution = await this.getInstitution(user.institutionId);

    // Cross-schema: pega posts e mensagens.
    const posts = await this.dataSource.query(
      `SELECT id, content, scope, reaction_count, comment_count, created_at FROM feed.posts WHERE author_id = $1 AND deleted_at IS NULL`,
      [userId],
    );
    const comments = await this.dataSource.query(
      `SELECT id, post_id, content, created_at FROM feed.comments WHERE user_id = $1 AND deleted_at IS NULL`,
      [userId],
    );
    const messages = await this.dataSource.query(
      `SELECT id, chat_id, content, created_at FROM messaging.messages WHERE sender_id = $1`,
      [userId],
    );

    this.logger.log(`Data export generated: ${userId}`);
    return {
      generated_at: new Date().toISOString(),
      message:
        'Pacote LGPD gerado inline. Em produção, link expirável via MinIO/S3.',
      data: {
        profile: {
          id: user.id,
          email: user.email,
          full_name: user.fullName,
          bio: user.bio,
          course: user.course,
          period: user.period,
          privacy_level: user.privacyLevel,
          institution,
          skills: skillRows.map((s) => ({ id: s.id, name: s.name })),
          created_at: user.createdAt,
        },
        connections: connections.map((c) => ({
          id: c.id,
          requester_id: c.requesterId,
          addressee_id: c.addresseeId,
          status: c.status,
          requested_at: c.requestedAt,
        })),
        posts,
        comments,
        messages,
      },
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

    if (!user.handle) {
      user.handle = await this.generateUniqueHandle(user.fullName, user.id);
      await this.userRepo.save(user);
    }

    return {
      data: {
        id: user.id,
        email: user.email ?? '',
        handle: user.handle ?? null,
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
      handle: user.handle ?? null,
      full_name: user.fullName,
      course: user.course ?? null,
      institution: { id: institution.id, name: institution.name, slug: institution.slug },
      skills: skills.map((s) => ({ id: s.id, name: s.name, category: s.category })),
      avatar_url: user.avatarUrl ?? null,
    };
  }

  /// Gera handle único a partir do nome (ex. "Maria Silva" -> "maria_silva").
  /// Em caso de colisão acrescenta um sufixo curto do uuid.
  private async generateUniqueHandle(fullName: string, userId: string): Promise<string> {
    const base = fullName
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 32) || `user_${userId.slice(0, 6)}`;

    for (let i = 0; i < 6; i++) {
      const candidate = i === 0 ? base : `${base}_${userId.replace(/-/g, '').slice(0, 4 + i)}`;
      const exists = await this.userRepo.findOne({ where: { handle: candidate } });
      if (!exists) return candidate;
    }
    return `${base}_${userId.replace(/-/g, '').slice(0, 12)}`;
  }
}
