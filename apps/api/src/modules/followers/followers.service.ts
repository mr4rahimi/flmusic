import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Follower } from './follower.entity';
import { User } from '../users/user.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/notification.entity';

@Injectable()
export class FollowersService {
  constructor(
    @InjectRepository(Follower)
    private readonly followerRepo: Repository<Follower>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async follow(currentUserId: string, username: string): Promise<void> {
    const targetUser = await this.userRepo.findOne({ where: { username } });
    if (!targetUser) throw new NotFoundException('User not found');

    if (currentUserId === targetUser.id)
      throw new BadRequestException('Cannot follow yourself');

    const existing = await this.followerRepo.findOne({
      where: { followerId: currentUserId, followingId: targetUser.id },
    });
    if (existing) throw new ConflictException('Already following');

    await this.followerRepo.save(
      this.followerRepo.create({
        followerId: currentUserId,
        followingId: targetUser.id,
      }),
    );

    await this.notificationsService.create(
      targetUser.id,
      currentUserId,
      NotificationType.FOLLOW,
    );
  }

  async unfollow(currentUserId: string, username: string): Promise<void> {
    const targetUser = await this.userRepo.findOne({ where: { username } });
    if (!targetUser) throw new NotFoundException('User not found');

    const existing = await this.followerRepo.findOne({
      where: { followerId: currentUserId, followingId: targetUser.id },
    });
    if (!existing) throw new NotFoundException('Not following');

    await this.followerRepo.remove(existing);
  }

  async getFollowers(username: string, page = 1, limit = 20) {
    const user = await this.userRepo.findOne({ where: { username } });
    if (!user) throw new NotFoundException('User not found');

    const [items, total] = await this.followerRepo
      .createQueryBuilder('f')
      .innerJoinAndSelect('f.follower', 'follower')
      .where('f.followingId = :id', { id: user.id })
      .orderBy('f.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: items.map((f) => ({
        id: f.follower.id,
        username: f.follower.username,
        avatarUrl: f.follower.avatarUrl,
        bio: f.follower.bio,
        verifiedStatus: f.follower.verifiedStatus,
        followedAt: f.createdAt,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getFollowing(username: string, page = 1, limit = 20) {
    const user = await this.userRepo.findOne({ where: { username } });
    if (!user) throw new NotFoundException('User not found');

    const [items, total] = await this.followerRepo
      .createQueryBuilder('f')
      .innerJoinAndSelect('f.following', 'following')
      .where('f.followerId = :id', { id: user.id })
      .orderBy('f.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: items.map((f) => ({
        id: f.following.id,
        username: f.following.username,
        avatarUrl: f.following.avatarUrl,
        bio: f.following.bio,
        verifiedStatus: f.following.verifiedStatus,
        followedAt: f.createdAt,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
