import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity({ schema: 'feed', name: 'tags' })
export class TagEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 64 })
  slug: string;

  @Column({ type: 'varchar', length: 64 })
  name: string;

  @Column({ name: 'post_count', type: 'int', default: 0 })
  postCount: number;

  @Column({ name: 'follower_count', type: 'int', default: 0 })
  followerCount: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
