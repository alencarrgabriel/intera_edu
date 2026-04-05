import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export type PrivacyLevel = 'public' | 'local_only' | 'private';

@Entity({ schema: 'profile', name: 'users' })
export class UserProfile {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @Column({ name: 'institution_id', type: 'uuid' })
  institutionId: string;

  @Column({ name: 'email', type: 'varchar', length: 255, nullable: true })
  email?: string | null;

  @Column({ name: 'full_name', type: 'varchar', length: 255 })
  fullName: string;

  @Column({ type: 'text', nullable: true })
  bio?: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  course?: string | null;

  @Column({ type: 'int', nullable: true })
  period?: number | null;

  @Column({ name: 'privacy_level', type: 'varchar', length: 20, default: 'local_only' })
  privacyLevel: PrivacyLevel;

  @Column({ name: 'avatar_url', type: 'varchar', length: 500, nullable: true })
  avatarUrl?: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt?: Date | null;
}

