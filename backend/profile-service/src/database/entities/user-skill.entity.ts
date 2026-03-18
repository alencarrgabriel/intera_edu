import { Entity, PrimaryColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { UserProfile } from './user-profile.entity';
import { Skill } from './skill.entity';

@Entity({ schema: 'profile', name: 'user_skills' })
export class UserSkill {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @PrimaryColumn({ name: 'skill_id', type: 'uuid' })
  skillId: string;

  @ManyToOne(() => UserProfile, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: UserProfile;

  @ManyToOne(() => Skill, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'skill_id' })
  skill?: Skill;
}

