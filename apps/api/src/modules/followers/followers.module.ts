import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Follower } from './follower.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Follower])],
  exports: [TypeOrmModule],
})
export class FollowersModule {}
