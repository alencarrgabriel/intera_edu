import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity({ schema: 'feed', name: 'discipline_groups' })
export class DisciplineGroupEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'discipline_id', type: 'uuid' })
  disciplineId: string;

  @Index()
  @Column({ name: 'institution_id', type: 'uuid' })
  institutionId: string;

  @Column({ type: 'varchar', length: 160 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column({ name: 'cover_url', type: 'text', nullable: true })
  coverUrl?: string | null;

  @Column({ name: 'member_count', type: 'int', default: 0 })
  memberCount: number;

  @Column({ name: 'post_count', type: 'int', default: 0 })
  postCount: number;

  @Column({ name: 'material_count', type: 'int', default: 0 })
  materialCount: number;

  @Column({ name: 'created_by', type: 'uuid' })
  createdBy: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
