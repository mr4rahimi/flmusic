import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Like } from './like.entity';
import { Track } from '../tracks/track.entity';
import { LikesService } from './likes.service';
import { LikesController } from './likes.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Like, Track])],
  controllers: [LikesController],
  providers: [LikesService],
  exports: [LikesService],
})
export class LikesModule {}
