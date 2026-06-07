import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, ManyToMany,
  JoinColumn, JoinTable, CreateDateColumn, UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Track } from '../tracks/track.entity';

@Entity('playlists')
export class Playlist {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  name: string;

  @Column({ nullable: true, length: 500 })
  description: string;

  @Column({ nullable: true })
  coverUrl: string;

  @Column({ default: 'public' })
  visibility: string;

  @ManyToMany(() => Track, { onDelete: 'CASCADE' })
  @JoinTable({
    name: 'playlist_tracks',
    joinColumn: { name: 'playlistId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'trackId', referencedColumnName: 'id' },
  })
  tracks: Track[];

  @Column({ default: 0 })
  tracksCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
