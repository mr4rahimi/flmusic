import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { Track } from './track.entity';
import { TracksService } from './tracks.service';
import { TracksController } from './tracks.controller';
import { SearchModule } from '../search/search.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Track]),
    BullModule.registerQueue({ name: 'audio' }),
    SearchModule,
  ],
  controllers: [TracksController],
  providers: [TracksService],
  exports: [TracksService],
})
export class TracksModule {}
