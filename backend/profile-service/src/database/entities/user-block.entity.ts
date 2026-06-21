import {
  Column,
  Entity,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  Index,
  Unique,
} from 'typeorm';

/// RF-15 — Tabela de bloqueios. Quem é `blocker_id` deixa de ver/conversar
/// com quem é `blocked_id`. Bloqueio é unidirecional do ponto de vista do
/// bloqueado; o backend aplica em ambas direções nas consultas.
@Entity({ schema: 'profile', name: 'user_blocks' })
@Unique('UQ_user_blocks_blocker_blocked', ['blockerId', 'blockedId'])
@Index('IDX_user_blocks_blocker', ['blockerId'])
@Index('IDX_user_blocks_blocked', ['blockedId'])
export class UserBlock {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'blocker_id', type: 'uuid' })
  blockerId: string;

  @Column({ name: 'blocked_id', type: 'uuid' })
  blockedId: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
