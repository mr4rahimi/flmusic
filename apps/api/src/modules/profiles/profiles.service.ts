import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { Follower } from '../followers/follower.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileResponseDto } from './dto/profile-response.dto';

@Injectable()
export class ProfilesService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Follower)
    private readonly followerRepo: Repository<Follower>,
  ) {}

  async getProfile(username: string, currentUserId?: string): Promise<ProfileResponseDto> {
    const user = await this.userRepo.findOne({ where: { username } });
    if (!user) throw new NotFoundException('User not found');

    const [followersCount, followingCount] = await Promise.all([
      this.followerRepo.count({ where: { following: { id: user.id } } }),
      this.followerRepo.count({ where: { follower: { id: user.id } } }),
    ]);

    let isFollowing = false;
    if (currentUserId && currentUserId !== user.id) {
      const follow = await this.followerRepo.findOne({
        where: {
          follower: { id: currentUserId },
          following: { id: user.id },
        },
      });
      isFollowing = !!follow;
    }

    return {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      verifiedStatus: user.verifiedStatus,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      followersCount,
      followingCount,
      isFollowing,
      createdAt: user.createdAt,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<ProfileResponseDto> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    await this.userRepo.update(userId, dto);

    return this.getProfile(user.username, userId);
  }

  async getMe(userId: string): Promise<ProfileResponseDto> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    return this.getProfile(user.username, userId);
  }
}
