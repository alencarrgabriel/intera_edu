import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export type PostScope = 'local' | 'global';

@Entity({ schema: 'feed', name: 'posts' })
export class PostEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'author_id', type: 'uuid' })
  authorId: string;

  @Index()
  @Column({ name: 'institution_id', type: 'uuid' })
  institutionId: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'varchar', length: 10, default: 'global' })
  scope: PostScope;

  @Column({ name: 'media_urls', type: 'text', array: true, nullable: true })
  mediaUrls?: string[] | null;

  @Column({ name: 'reaction_count', type: 'int', default: 0 })
  reactionCount: number;

  @Column({ name: 'comment_count', type: 'int', default: 0 })
  commentCount: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt?: Date | null;
}

