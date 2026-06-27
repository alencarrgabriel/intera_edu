import {
  Injectable,
  Logger,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike, In } from 'typeorm';
import { JwtPayload, RedisService } from '@interaedu/shared';
import { DisciplineEntity } from '../database/entities/discipline.entity';
import { DisciplineGroupEntity } from '../database/entities/discipline-group.entity';
import { GroupMemberEntity } from '../database/entities/group-member.entity';

interface CreateDisciplineDto {
  code: string;
  name: string;
  period?: string;
  description?: string;
}

interface CreateGroupDto {
  discipline_id: string;
  name?: string;
  description?: string;
}

@Injectable()
export class GroupsService {
  private readonly logger = new Logger(GroupsService.name);

  constructor(
    @InjectRepository(DisciplineEntity)
    private readonly disciplineRepo: Repository<DisciplineEntity>,
    @InjectRepository(DisciplineGroupEntity)
    private readonly groupRepo: Repository<DisciplineGroupEntity>,
    @InjectRepository(GroupMemberEntity)
    private readonly memberRepo: Repository<GroupMemberEntity>,
    private readonly redis: RedisService,
  ) {}

  async listDisciplines(user: JwtPayload, q?: string) {
    const where: any = { institutionId: user.institution_id };
    if (q && q.trim()) {
      const term = `%${q.trim()}%`;
      const items = await this.disciplineRepo
        .createQueryBuilder('d')
        .where('d.institution_id = :inst', { inst: user.institution_id })
        .andWhere('(d.name ILIKE :q OR d.code ILIKE :q)', { q: term })
        .orderBy('d.code', 'ASC')
        .limit(50)
        .getMany();
      return { data: items };
    }
    const items = await this.disciplineRepo.find({
      where,
      order: { code: 'ASC' },
      take: 100,
    });
    return { data: items };
  }

  async createDiscipline(dto: CreateDisciplineDto, user: JwtPayload) {
    const exists = await this.disciplineRepo.findOne({
      where: { institutionId: user.institution_id, code: dto.code },
    });
    if (exists) throw new ConflictException('Disciplina já existe');

    const saved = await this.disciplineRepo.save({
      institutionId: user.institution_id,
      code: dto.code,
      name: dto.name,
      period: dto.period ?? null,
      description: dto.description ?? null,
    });
    return saved;
  }

  async createGroup(dto: CreateGroupDto, user: JwtPayload) {
    const discipline = await this.disciplineRepo.findOne({ where: { id: dto.discipline_id } });
    if (!discipline) throw new NotFoundException('Disciplina não encontrada');
    if (discipline.institutionId !== user.institution_id) {
      throw new ForbiddenException('Disciplina de outra instituição');
    }

    const name = dto.name ?? `${discipline.code} — ${discipline.name}`;
    const group = await this.groupRepo.save({
      disciplineId: discipline.id,
      institutionId: user.institution_id,
      name,
      description: dto.description ?? null,
      createdBy: user.sub,
      memberCount: 1,
    });
    await this.memberRepo.save({
      groupId: group.id,
      userId: user.sub,
      role: 'admin',
    });
    return group;
  }

  async listGroups(user: JwtPayload, query: { mine?: boolean; q?: string }) {
    if (query.mine) {
      const memberships = await this.memberRepo.find({ where: { userId: user.sub } });
      const ids = memberships.map((m) => m.groupId);
      if (!ids.length) return { data: [] };
      const groups = await this.groupRepo.find({
        where: { id: In(ids) },
        order: { name: 'ASC' },
      });
      return { data: groups.map((g) => this.toResponse(g, true)) };
    }

    const qb = this.groupRepo
      .createQueryBuilder('g')
      .where('g.institution_id = :inst', { inst: user.institution_id })
      .orderBy('g.member_count', 'DESC')
      .take(50);

    if (query.q && query.q.trim()) {
      qb.andWhere('g.name ILIKE :q', { q: `%${query.q.trim()}%` });
    }
    const groups = await qb.getMany();
    const myMemberships = await this.memberRepo.find({
      where: { userId: user.sub, groupId: In(groups.map((g) => g.id)) },
    });
    const memberIds = new Set(myMemberships.map((m) => m.groupId));
    return { data: groups.map((g) => this.toResponse(g, memberIds.has(g.id))) };
  }

  async getGroup(groupId: string, user: JwtPayload) {
    const group = await this.groupRepo.findOne({ where: { id: groupId } });
    if (!group) throw new NotFoundException('Grupo não encontrado');
    const membership = await this.memberRepo.findOne({
      where: { groupId, userId: user.sub },
    });
    return this.toResponse(group, !!membership);
  }

  async joinGroup(groupId: string, user: JwtPayload) {
    const group = await this.groupRepo.findOne({ where: { id: groupId } });
    if (!group) throw new NotFoundException('Grupo não encontrado');
    const existing = await this.memberRepo.findOne({
      where: { groupId, userId: user.sub },
    });
    if (existing) return { message: 'Já é membro' };

    await this.memberRepo.save({ groupId, userId: user.sub, role: 'member' });
    group.memberCount = (group.memberCount ?? 0) + 1;
    await this.groupRepo.save(group);
    return { message: 'OK' };
  }

  async leaveGroup(groupId: string, user: JwtPayload) {
    const group = await this.groupRepo.findOne({ where: { id: groupId } });
    if (!group) throw new NotFoundException('Grupo não encontrado');
    const existing = await this.memberRepo.findOne({
      where: { groupId, userId: user.sub },
    });
    if (!existing) return { message: 'Não era membro' };
    await this.memberRepo.remove(existing);
    group.memberCount = Math.max(0, (group.memberCount ?? 1) - 1);
    await this.groupRepo.save(group);
    return { message: 'OK' };
  }

  async listMembers(groupId: string) {
    const items = await this.memberRepo.find({
      where: { groupId },
      order: { joinedAt: 'ASC' },
      take: 200,
    });
    return { data: items.map((m) => ({ user_id: m.userId, role: m.role, joined_at: m.joinedAt.toISOString() })) };
  }

  async assertMember(groupId: string, userId: string) {
    const m = await this.memberRepo.findOne({ where: { groupId, userId } });
    if (!m) throw new ForbiddenException('Não é membro do grupo');
    return m;
  }

  async incrementPostCount(groupId: string, delta: number) {
    await this.groupRepo.increment({ id: groupId }, 'postCount', delta);
  }

  async incrementMaterialCount(groupId: string, delta: number) {
    await this.groupRepo.increment({ id: groupId }, 'materialCount', delta);
  }

  private toResponse(g: DisciplineGroupEntity, isMember: boolean) {
    return {
      id: g.id,
      discipline_id: g.disciplineId,
      institution_id: g.institutionId,
      name: g.name,
      description: g.description,
      cover_url: g.coverUrl,
      member_count: g.memberCount,
      post_count: g.postCount,
      material_count: g.materialCount,
      is_member: isMember,
      created_at: g.createdAt.toISOString(),
    };
  }
}
