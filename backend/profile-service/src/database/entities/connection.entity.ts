import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

export type ConnectionStatus = 'pending' | 'accepted' | 'rejected';

@Entity({ schema: 'profile', name: 'connections' })
@Index(['requesterId', 'addresseeId'], { unique: true })
export class Connection {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'requester_id', type: 'uuid' })
  requesterId: string;

  @Index()
  @Column({ name: 'addressee_id', type: 'uuid' })
  addresseeId: string;

  @Column({ type: 'varchar', length: 20, default: 'pending' })
  status: ConnectionStatus;

  @CreateDateColumn({ name: 'requested_at', type: 'timestamptz' })
  requestedAt: Date;

  @Column({ name: 'responded_at', type: 'timestamptz', nullable: true })
  respondedAt?: Date | null;
}

