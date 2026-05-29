import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Track, TrackStatus, TrackVisibility } from '../tracks/track.entity';
import { Follower } from '../followers/follower.entity';

@Injectable()
export class FeedService {
  constructor(
    @InjectRepository(Track)
    private readonly trackRepo: Repository<Track>,
    @InjectRepository(Follower)
    private readonly followerRepo: Repository<Follower>,
  ) {}

  async getFollowingFeed(userId: string, page = 1, limit = 20) {
    const following = await this.followerRepo.find({
      where: { followerId: userId },
      select: { followingId: true },
    });

    if (following.length === 0) {
      return this.buildPaginatedResult([], 0, page, limit);
    }

    const followingIds = following.map((f) => f.followingId);

    const [items, total] = await this.trackRepo
      .createQueryBuilder('track')
      .innerJoinAndSelect('track.user', 'user')
      .where('track.userId IN (:...ids)', { ids: followingIds })
      .andWhere('track.visibility = :vis', { vis: TrackVisibility.PUBLIC })
      .andWhere('track.status = :status', { status: TrackStatus.READY })
      .orderBy('track.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return this.buildPaginatedResult(items, total, page, limit);
  }

  async getTrendingFeed(page = 1, limit = 20) {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const qb = this.trackRepo
      .createQueryBuilder('track')
      .innerJoinAndSelect('track.user', 'user')
      .where('track.visibility = :vis', { vis: TrackVisibility.PUBLIC })
      .andWhere('track.status = :status', { status: TrackStatus.READY })
      .andWhere('track.createdAt >= :since', { since: sevenDaysAgo })
      .addSelect(
        '(track.likesCount * 3 + track.commentsCount * 2 + track.playCount)',
        'score',
      )
      .orderBy('score', 'DESC')
      .addOrderBy('track.createdAt', 'DESC');

    const total = await qb.getCount();
    const items = await qb
      .skip((page - 1) * limit)
      .take(limit)
      .getMany();

    return this.buildPaginatedResult(items, total, page, limit);
  }

  async getNewFeed(page = 1, limit = 20) {
    const [items, total] = await this.trackRepo
      .createQueryBuilder('track')
      .innerJoinAndSelect('track.user', 'user')
      .where('track.visibility = :vis', { vis: TrackVisibility.PUBLIC })
      .andWhere('track.status = :status', { status: TrackStatus.READY })
      .orderBy('track.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return this.buildPaginatedResult(items, total, page, limit);
  }

  private buildPaginatedResult(
    items: Track[],
    total: number,
    page: number,
    limit: number,
  ) {
    return {
      data: items.map((t) => ({
        id: t.id,
        title: t.title,
        description: t.description,
        coverUrl: t.coverUrl,
        audioUrl: t.audioUrl,
        duration: t.duration,
        genre: t.genre,
        tags: t.tags,
        playCount: t.playCount,
        likesCount: t.likesCount,
        commentsCount: t.commentsCount,
        createdAt: t.createdAt,
        user: {
          id: t.user.id,
          username: t.user.username,
          avatarUrl: t.user.avatarUrl,
          verifiedStatus: t.user.verifiedStatus,
        },
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
