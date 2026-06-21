import {
  Column,
  Entity,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';

/// RF-39 / RF-40 — Tabela de denúncias. Qualquer usuário pode denunciar
/// um conteúdo (post, comentário, perfil ou chat). Moderadores resolvem
/// definindo `status = 'resolved'` ou `'dismissed'` em `resolved_at`.
@Entity({ schema: 'feed', name: 'reports' })
@Index('IDX_reports_status', ['status'])
@Index('IDX_reports_target', ['targetType', 'targetId'])
export class Report {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'reporter_id', type: 'uuid' })
  reporterId: string;

  /// 'post' | 'comment' | 'user' | 'chat'
  @Column({ name: 'target_type', type: 'varchar', length: 16 })
  targetType: string;

  @Column({ name: 'target_id', type: 'uuid' })
  targetId: string;

  /// 'spam' | 'abuse' | 'misinformation' | 'other'
  @Column({ name: 'reason', type: 'varchar', length: 32, default: 'other' })
  reason: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description: string | null;

  /// 'open' | 'resolved' | 'dismissed'
  @Column({ type: 'varchar', length: 16, default: 'open' })
  status: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'resolved_at', type: 'timestamptz', nullable: true })
  resolvedAt: Date | null;

  @Column({ name: 'resolved_by', type: 'uuid', nullable: true })
  resolvedBy: string | null;
}
