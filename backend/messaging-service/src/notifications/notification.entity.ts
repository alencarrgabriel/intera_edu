import {
  Column,
  Entity,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';

/// RF-35 — Notificações in-app. São produzidas por eventos do sistema
/// (nova conexão aceita, novo comentário, nova mensagem etc.) e
/// consumidas via GET /notifications + PATCH /notifications/:id/read.
@Entity({ schema: 'messaging', name: 'notifications' })
@Index('IDX_notifications_user_unread', ['userId', 'readAt'])
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  /// 'connection_request' | 'connection_accepted' | 'new_message' |
  /// 'post_comment' | 'post_reaction' | 'system'
  @Column({ type: 'varchar', length: 32 })
  type: string;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  @Column({ type: 'text', nullable: true })
  body: string | null;

  /// JSON livre com IDs (postId, chatId, userId etc.) usados pelo cliente
  /// para abrir a tela correta ao tocar na notificação.
  @Column({ type: 'jsonb', nullable: true })
  payload: any;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
