import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Follower } from './follower.entity';
import { User } from '../users/user.entity';
import { FollowersService } from './followers.service';
import { FollowersController } from './followers.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Follower, User])],
  controllers: [FollowersController],
  providers: [FollowersService],
  exports: [FollowersService, TypeOrmModule],
})
export class FollowersModule {}
