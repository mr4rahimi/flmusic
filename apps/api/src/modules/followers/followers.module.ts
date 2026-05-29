import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Follower } from './follower.entity';
import { User } from '../users/user.entity';
import { FollowersService } from './followers.service';
import { FollowersController } from './followers.controller';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Follower, User]),
    NotificationsModule,
  ],
  controllers: [FollowersController],
  providers: [FollowersService],
  exports: [FollowersService, TypeOrmModule],
})
export class FollowersModule {}
