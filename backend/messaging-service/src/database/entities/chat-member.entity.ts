import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Chat } from './chat.entity';

export type MemberRole = 'admin' | 'member';

@Entity({ schema: 'messaging', name: 'chat_members' })
export class ChatMember {
  @PrimaryColumn({ name: 'chat_id', type: 'uuid' })
  chatId: string;

  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'role', type: 'varchar', length: 10, default: 'member' })
  role: MemberRole;

  @CreateDateColumn({ name: 'joined_at', type: 'timestamptz' })
  joinedAt: Date;

  @ManyToOne(() => Chat, (c) => c.members, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'chat_id' })
  chat: Chat;
}
