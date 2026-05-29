import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Track } from '../tracks/track.entity';

@Entity('likes')
@Unique(['userId', 'trackId'])
export class Like {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  trackId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Track, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'trackId' })
  track: Track;

  @CreateDateColumn()
  createdAt: Date;
}
