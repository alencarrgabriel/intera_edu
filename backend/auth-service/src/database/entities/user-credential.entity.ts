import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
} from 'typeorm';

@Entity({ schema: 'auth', name: 'user_credentials' })
export class UserCredential {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 320, unique: true })
  email: string;

  /// Hash bcrypt da senha. Nullable para contas criadas exclusivamente
  /// via OAuth (Google) que ainda não definiram uma senha local.
  @Column({ name: 'password_hash', type: 'varchar', length: 255, nullable: true })
  passwordHash: string | null;

  /// Identificador único do usuário no provedor Google (claim `sub` do ID token).
  /// Único e nullable — só preenchido em contas vinculadas via OAuth.
  @Column({ name: 'google_id', type: 'varchar', length: 64, nullable: true, unique: true })
  googleId: string | null;

  @Column({ name: 'institution_id', type: 'uuid' })
  institutionId: string;

  @Column({ type: 'varchar', length: 20, default: 'active' })
  status: string;

  @Column({ name: 'last_login_at', type: 'timestamptz', nullable: true })
  lastLoginAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date;
}
