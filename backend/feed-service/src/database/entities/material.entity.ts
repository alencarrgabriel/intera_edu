import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

export type MaterialKind = 'pdf' | 'image' | 'doc' | 'video' | 'link' | 'other';

@Entity({ schema: 'feed', name: 'materials' })
export class MaterialEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'group_id', type: 'uuid' })
  groupId: string;

  @Index()
  @Column({ name: 'uploader_id', type: 'uuid' })
  uploaderId: string;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column({ name: 'file_url', type: 'text' })
  fileUrl: string;

  @Column({ name: 'file_mime', type: 'varchar', length: 64, nullable: true })
  fileMime?: string | null;

  @Column({ name: 'file_size', type: 'bigint', nullable: true })
  fileSize?: number | null;

  @Column({ type: 'varchar', length: 16, default: 'other' })
  kind: MaterialKind;

  @Column({ name: 'download_count', type: 'int', default: 0 })
  downloadCount: number;

  @Column({ name: 'rating_sum', type: 'int', default: 0 })
  ratingSum: number;

  @Column({ name: 'rating_count', type: 'int', default: 0 })
  ratingCount: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt?: Date | null;
}
