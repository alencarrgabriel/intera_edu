import {
  Injectable,
  ConflictException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { UserBlock } from '../database/entities/user-block.entity';

@Injectable()
export class BlocksService {
  constructor(
    @InjectRepository(UserBlock)
    private readonly blockRepo: Repository<UserBlock>,
  ) {}

  async block(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new ForbiddenException('Você não pode bloquear a si mesmo.');
    }
    const existing = await this.blockRepo.findOne({
      where: { blockerId, blockedId },
    });
    if (existing) throw new ConflictException('Usuário já está bloqueado.');
    await this.blockRepo.save({ blockerId, blockedId });
    return { ok: true };
  }

  async unblock(blockerId: string, blockedId: string) {
    const existing = await this.blockRepo.findOne({
      where: { blockerId, blockedId },
    });
    if (!existing) throw new NotFoundException('Bloqueio não encontrado.');
    await this.blockRepo.delete({ blockerId, blockedId });
    return { ok: true };
  }

  async listBlocked(blockerId: string): Promise<string[]> {
    const rows = await this.blockRepo.find({ where: { blockerId } });
    return rows.map((r) => r.blockedId);
  }

  /// Retorna IDs envolvidos em qualquer relação de bloqueio com o usuário —
  /// usado em buscas/feeds para esconder ambas as direções.
  async listBidirectionalIds(userId: string): Promise<Set<string>> {
    const rows = await this.blockRepo.find({
      where: [{ blockerId: userId }, { blockedId: userId }],
    });
    const out = new Set<string>();
    for (const r of rows) {
      out.add(r.blockerId === userId ? r.blockedId : r.blockerId);
    }
    return out;
  }

  async areBlocked(a: string, b: string): Promise<boolean> {
    const row = await this.blockRepo.findOne({
      where: [
        { blockerId: a, blockedId: b },
        { blockerId: b, blockedId: a },
      ],
    });
    return !!row;
  }
}
