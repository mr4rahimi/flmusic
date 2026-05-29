import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { Track, TrackVisibility } from './track.entity';
import { CreateTrackDto } from './dto/create-track.dto';
import { UpdateTrackDto } from './dto/update-track.dto';
import { SearchService } from '../search/search.service';

@Injectable()
export class TracksService {
  constructor(
    @InjectRepository(Track)
    private readonly trackRepo: Repository<Track>,
    @InjectQueue('audio')
    private readonly audioQueue: Queue,
    private readonly searchService: SearchService,
  ) {}

  async create(
    userId: string,
    dto: CreateTrackDto,
    audioPath: string,
    coverPath?: string,
  ): Promise<Track> {
    const track = this.trackRepo.create({
      userId,
      title: dto.title,
      description: dto.description,
      genre: dto.genre,
      tags: dto.tags,
      visibility: dto.visibility || TrackVisibility.PUBLIC,
      originalAudioUrl: audioPath,
      coverUrl: coverPath ?? undefined,
    });

    const saved = await this.trackRepo.save(track);

    await this.audioQueue.add('process-audio', {
      trackId: saved.id,
      filePath: audioPath,
    });

    return saved;
  }

  async findById(id: string, currentUserId?: string): Promise<Track> {
    const track = await this.trackRepo.findOne({
      where: { id },
      relations: { user: true },
    });
    if (!track) throw new NotFoundException('Track not found');

    if (
      track.visibility === TrackVisibility.PRIVATE &&
      track.userId !== currentUserId
    ) {
      throw new ForbiddenException('This track is private');
    }

    return track;
  }

  async findByUser(username: string, currentUserId?: string) {
    const qb = this.trackRepo
      .createQueryBuilder('track')
      .innerJoinAndSelect('track.user', 'user')
      .where('user.username = :username', { username })
      .orderBy('track.createdAt', 'DESC');

    if (!currentUserId) {
      qb.andWhere('track.visibility = :vis', { vis: TrackVisibility.PUBLIC });
    } else {
      qb.andWhere(
        '(track.visibility = :pub OR track.userId = :uid)',
        { pub: TrackVisibility.PUBLIC, uid: currentUserId },
      );
    }

    return qb.getMany();
  }

  async update(id: string, userId: string, dto: UpdateTrackDto): Promise<Track> {
    const track = await this.trackRepo.findOne({ where: { id } });
    if (!track) throw new NotFoundException('Track not found');
    if (track.userId !== userId) throw new ForbiddenException();

    await this.trackRepo.update(id, dto);
    const updated = await this.trackRepo.findOne({
      where: { id },
      relations: { user: true },
    }) as Track;

    await this.searchService.indexTrack(updated);
    return updated;
  }

  async delete(id: string, userId: string): Promise<void> {
    const track = await this.trackRepo.findOne({ where: { id } });
    if (!track) throw new NotFoundException('Track not found');
    if (track.userId !== userId) throw new ForbiddenException();

    await this.searchService.removeTrack(id);
    await this.trackRepo.remove(track);
  }

  async incrementPlayCount(id: string): Promise<void> {
    await this.trackRepo.increment({ id }, 'playCount', 1);
  }
}
