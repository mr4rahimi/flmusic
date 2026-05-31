import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProfilesService } from './profiles.service';
import { ProfilesController } from './profiles.controller';
import { User } from '../users/user.entity';
import { Follower } from '../followers/follower.entity';
import { Track } from '../tracks/track.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Follower, Track])],
  controllers: [ProfilesController],
  providers: [ProfilesService],
  exports: [ProfilesService],
})
export class ProfilesModule {}
