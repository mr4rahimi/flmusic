import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Track } from '../tracks/track.entity';
import { Follower } from '../followers/follower.entity';
import { FeedService } from './feed.service';
import { FeedController } from './feed.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Track, Follower])],
  controllers: [FeedController],
  providers: [FeedService],
})
export class FeedModule {}
