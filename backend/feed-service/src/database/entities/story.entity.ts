import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity({ schema: 'feed', name: 'stories' })
export class StoryEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'author_id', type: 'uuid' })
  authorId: string;

  @Index()
  @Column({ name: 'institution_id', type: 'uuid' })
  institutionId: string;

  @Column({ name: 'media_url', type: 'text', nullable: true })
  mediaUrl?: string | null;

  @Column({ name: 'media_mime', type: 'varchar', length: 64, nullable: true })
  mediaMime?: string | null;

  @Column({ type: 'text', nullable: true })
  caption?: string | null;

  @Column({ name: 'view_count', type: 'int', default: 0 })
  viewCount: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Index()
  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;
}
