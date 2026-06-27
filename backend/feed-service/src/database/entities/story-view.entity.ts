import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity({ schema: 'feed', name: 'story_views' })
@Index(['storyId', 'userId'], { unique: true })
export class StoryViewEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'story_id', type: 'uuid' })
  storyId: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @CreateDateColumn({ name: 'viewed_at', type: 'timestamptz' })
  viewedAt: Date;
}
