import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Comment } from './comment.entity';
import { Track } from '../tracks/track.entity';
import { CommentsService } from './comments.service';
import { CommentsController } from './comments.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Comment, Track])],
  controllers: [CommentsController],
  providers: [CommentsService],
  exports: [CommentsService],
})
export class CommentsModule {}
