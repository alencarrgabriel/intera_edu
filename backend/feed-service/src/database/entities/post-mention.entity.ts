import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

export type MentionSource = 'post' | 'comment';

@Entity({ schema: 'feed', name: 'mentions' })
@Index(['source', 'sourceId'])
export class PostMentionEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 16 })
  source: MentionSource;

  @Column({ name: 'source_id', type: 'uuid' })
  sourceId: string;

  @Index()
  @Column({ name: 'mentioned_user_id', type: 'uuid' })
  mentionedUserId: string;

  @Column({ name: 'author_id', type: 'uuid' })
  authorId: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
