import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export type ReactionType = 'like' | 'insightful' | 'support';

@Entity({ schema: 'feed', name: 'reactions' })
@Index(['postId', 'userId'], { unique: true })
export class ReactionEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'post_id', type: 'uuid' })
  postId: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'reaction_type', type: 'varchar', length: 20 })
  reactionType: ReactionType;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}

