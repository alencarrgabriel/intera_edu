import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, In, IsNull } from 'typeorm';
import { JwtPayload } from '@interaedu/shared';
import { UserProfile } from '../database/entities/user-profile.entity';
import { UserSkill } from '../database/entities/user-skill.entity';
import { Connection } from '../database/entities/connection.entity';

export interface Suggestion {
  user: any;
  score: number;
  reason: string;
}

@Injectable()
export class SuggestionsService {
  constructor(
    @InjectRepository(UserProfile)
    private readonly userRepo: Repository<UserProfile>,
    @InjectRepository(UserSkill)
    private readonly skillRepo: Repository<UserSkill>,
    @InjectRepository(Connection)
    private readonly connRepo: Repository<Connection>,
  ) {}

  /// Pontuação simples:
  ///   +5 mesmo curso  +3 mesma IES  +2 por skill compartilhada  +1 por mutual
  async suggest(user: JwtPayload): Promise<{ data: Suggestion[] }> {
    const me = await this.userRepo.findOne({
      where: { id: user.sub, deletedAt: IsNull() },
    });
    if (!me) return { data: [] };

    const mySkills = await this.skillRepo.find({ where: { userId: me.id } });
    const mySkillIds = new Set(mySkills.map((s) => s.skillId));

    const conns = await this.connRepo.find({
      where: [{ requesterId: me.id }, { addresseeId: me.id }],
    });
    const myConnIds = new Set<string>();
    conns.forEach((c) => {
      if (c.requesterId === me.id) myConnIds.add(c.addresseeId);
      else myConnIds.add(c.requesterId);
    });

    const candidates = await this.userRepo.find({
      where: {
        institutionId: me.institutionId,
        id: Not(me.id),
        deletedAt: IsNull(),
      },
      take: 200,
    });
    const filtered = candidates.filter((c) => !myConnIds.has(c.id));
    if (!filtered.length) return { data: [] };

    const candidateIds = filtered.map((c) => c.id);
    const candidateSkills = await this.skillRepo.find({
      where: { userId: In(candidateIds) },
    });
    const skillsByUser = new Map<string, Set<string>>();
    candidateSkills.forEach((cs) => {
      const set = skillsByUser.get(cs.userId) ?? new Set();
      set.add(cs.skillId);
      skillsByUser.set(cs.userId, set);
    });

    // Mutuals: connections-of-connections
    const mutualCount = new Map<string, number>();
    if (myConnIds.size) {
      const transitive = await this.connRepo.find({
        where: [
          { requesterId: In([...myConnIds]) },
          { addresseeId: In([...myConnIds]) },
        ],
      });
      transitive.forEach((c) => {
        const other = myConnIds.has(c.requesterId) ? c.addresseeId : c.requesterId;
        if (other === me.id || myConnIds.has(other)) return;
        mutualCount.set(other, (mutualCount.get(other) ?? 0) + 1);
      });
    }

    const scored: Suggestion[] = filtered.map((c) => {
      const skillSet = skillsByUser.get(c.id) ?? new Set();
      const sharedSkills = [...skillSet].filter((s) => mySkillIds.has(s)).length;
      const sameCourse = me.course && c.course && me.course === c.course ? 5 : 0;
      const sameInst = 3;
      const mutuals = mutualCount.get(c.id) ?? 0;
      const score = sameCourse + sameInst + sharedSkills * 2 + mutuals;
      const reason =
        sameCourse > 0
          ? 'Mesmo curso que você'
          : mutuals > 0
            ? `${mutuals} ${mutuals === 1 ? 'conexão em comum' : 'conexões em comum'}`
            : sharedSkills > 0
              ? `${sharedSkills} ${sharedSkills === 1 ? 'habilidade em comum' : 'habilidades em comum'}`
              : 'Da sua instituição';
      return {
        user: {
          id: c.id,
          handle: c.handle ?? null,
          full_name: c.fullName,
          avatar_url: c.avatarUrl ?? null,
          course: c.course ?? null,
          institution_id: c.institutionId,
        },
        score,
        reason,
      };
    });

    scored.sort((a, b) => b.score - a.score);
    return { data: scored.slice(0, 20) };
  }
}
