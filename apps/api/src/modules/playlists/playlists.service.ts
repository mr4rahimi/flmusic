import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Playlist } from './playlist.entity';
import { Track } from '../tracks/track.entity';
import { CreatePlaylistDto } from './dto/create-playlist.dto';

@Injectable()
export class PlaylistsService {
  constructor(
    @InjectRepository(Playlist)
    private playlistsRepo: Repository<Playlist>,
    @InjectRepository(Track)
    private tracksRepo: Repository<Track>,
  ) {}

  async create(userId: string, dto: CreatePlaylistDto): Promise<Playlist> {
    const playlist = this.playlistsRepo.create({
      userId,
      name: dto.name,
      description: dto.description,
      visibility: dto.visibility ?? 'public',
    });
    return this.playlistsRepo.save(playlist);
  }

  async findUserPlaylists(userId: string): Promise<Playlist[]> {
    return this.playlistsRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Playlist> {
    const playlist = await this.playlistsRepo.findOne({
      where: { id },
      relations: { tracks: { user: true } }
    });
    if (!playlist) throw new NotFoundException('پلی‌لیست پیدا نشد');
    return playlist;
  }

  async addTrack(playlistId: string, trackId: string, userId: string): Promise<Playlist> {
    const playlist = await this.playlistsRepo.findOne({
      where: { id: playlistId },
      relations: { tracks: true }
    });
    if (!playlist) throw new NotFoundException('پلی‌لیست پیدا نشد');
    if (playlist.userId !== userId) throw new ForbiddenException();

    const track = await this.tracksRepo.findOne({ where: { id: trackId } });
    if (!track) throw new NotFoundException('آهنگ پیدا نشد');

    const already = playlist.tracks.some(t => t.id === trackId);
    if (!already) {
      playlist.tracks.push(track);
      playlist.tracksCount = playlist.tracks.length;
      await this.playlistsRepo.save(playlist);
    }
    return playlist;
  }

  async removeTrack(playlistId: string, trackId: string, userId: string): Promise<void> {
    const playlist = await this.playlistsRepo.findOne({
      where: { id: playlistId },
      relations: { tracks: true }
    });
    if (!playlist) throw new NotFoundException('پلی‌لیست پیدا نشد');
    if (playlist.userId !== userId) throw new ForbiddenException();

    playlist.tracks = playlist.tracks.filter(t => t.id !== trackId);
    playlist.tracksCount = playlist.tracks.length;
    await this.playlistsRepo.save(playlist);
  }

  async delete(playlistId: string, userId: string): Promise<void> {
    const playlist = await this.playlistsRepo.findOne({ where: { id: playlistId } });
    if (!playlist) throw new NotFoundException('پلی‌لیست پیدا نشد');
    if (playlist.userId !== userId) throw new ForbiddenException();
    await this.playlistsRepo.remove(playlist);
  }
}
