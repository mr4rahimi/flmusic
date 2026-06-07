import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Playlist } from './playlist.entity';
import { Track } from '../tracks/track.entity';
import { PlaylistsService } from './playlists.service';
import { PlaylistsController } from './playlists.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Playlist, Track])],
  controllers: [PlaylistsController],
  providers: [PlaylistsService],
  exports: [PlaylistsService],
})
export class PlaylistsModule {}
