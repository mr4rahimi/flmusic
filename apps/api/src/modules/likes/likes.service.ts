import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Like } from './like.entity';
import { Track } from '../tracks/track.entity';

@Injectable()
export class LikesService {
  constructor(
    @InjectRepository(Like)
    private readonly likeRepo: Repository<Like>,
    @InjectRepository(Track)
    private readonly trackRepo: Repository<Track>,
  ) {}

  async like(userId: string, trackId: string): Promise<void> {
    const track = await this.trackRepo.findOne({ where: { id: trackId } });
    if (!track) throw new NotFoundException('Track not found');

    const existing = await this.likeRepo.findOne({
      where: { userId, trackId },
    });
    if (existing) throw new ConflictException('Already liked');

    await this.likeRepo.save(this.likeRepo.create({ userId, trackId }));
    await this.trackRepo.increment({ id: trackId }, 'likesCount', 1);
  }

  async unlike(userId: string, trackId: string): Promise<void> {
    const existing = await this.likeRepo.findOne({
      where: { userId, trackId },
    });
    if (!existing) throw new NotFoundException('Like not found');

    await this.likeRepo.remove(existing);
    await this.trackRepo.decrement({ id: trackId }, 'likesCount', 1);
  }

  async isLiked(userId: string, trackId: string): Promise<boolean> {
    const like = await this.likeRepo.findOne({ where: { userId, trackId } });
    return !!like;
  }

  async getLikedTracks(userId: string, page = 1, limit = 20) {
    const [items, total] = await this.likeRepo
      .createQueryBuilder('like')
      .innerJoinAndSelect('like.track', 'track')
      .innerJoinAndSelect('track.user', 'user')
      .where('like.userId = :userId', { userId })
      .orderBy('like.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: items.map((l) => l.track),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
