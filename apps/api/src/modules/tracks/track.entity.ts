import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

export enum TrackVisibility {
  PUBLIC = 'public',
  PRIVATE = 'private',
}

export enum TrackStatus {
  PROCESSING = 'processing',
  READY = 'ready',
  FAILED = 'failed',
}

@Entity('tracks')
export class Track {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  title: string;

  @Column({ nullable: true, length: 500 })
  description: string;

  @Column({ nullable: true })
  coverUrl: string;

  @Column({ nullable: true })
  audioUrl: string;

  @Column({ nullable: true })
  originalAudioUrl: string;

  @Column({ nullable: true, type: 'int' })
  duration: number;

  @Column({ nullable: true, type: 'jsonb' })
  waveformData: number[];

  @Column({ nullable: true })
  genre: string;

  @Column({ type: 'simple-array', nullable: true })
  tags: string[];

  @Column({
    type: 'enum',
    enum: TrackVisibility,
    default: TrackVisibility.PUBLIC,
  })
  visibility: TrackVisibility;

  @Column({
    type: 'enum',
    enum: TrackStatus,
    default: TrackStatus.PROCESSING,
  })
  status: TrackStatus;

  @Column({ default: 0 })
  playCount: number;

  @Column({ default: 0 })
  likesCount: number;

  @Column({ default: 0 })
  commentsCount: number;

  @Column({ default: 0 })
  repostsCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
