import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

export enum NotificationType {
  FOLLOW = 'follow',
  LIKE = 'like',
  COMMENT = 'comment',
  REPOST = 'repost',
}

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string; // گیرنده

  @Column()
  actorId: string; // فرستنده

  @Column({ type: 'enum', enum: NotificationType })
  type: NotificationType;

  @Column({ nullable: true })
  entityId: string; // track یا comment id

  @Column({ default: false })
  isRead: boolean;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'actorId' })
  actor: User;

  @CreateDateColumn()
  createdAt: Date;
}
