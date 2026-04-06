import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { ChatMember } from './chat-member.entity';
import { Message } from './message.entity';

export type ChatType = 'direct' | 'group';

@Entity({ schema: 'messaging', name: 'chats' })
export class Chat {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'type', type: 'varchar', length: 10, default: 'direct' })
  type: ChatType;

  @Column({ name: 'name', type: 'varchar', length: 255, nullable: true })
  name?: string | null;

  @Column({ name: 'created_by', type: 'uuid' })
  createdBy: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @OneToMany(() => ChatMember, (m) => m.chat, { eager: false })
  members: ChatMember[];

  @OneToMany(() => Message, (m) => m.chat, { eager: false })
  messages: Message[];
}
