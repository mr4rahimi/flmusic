import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFiles,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
} from '@nestjs/swagger';
import { TracksService } from './tracks.service';
import { CreateTrackDto } from './dto/create-track.dto';
import { UpdateTrackDto } from './dto/update-track.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { audioMulterConfig, imageMulterConfig } from '../../config/upload.config';
import { join } from 'path';

@ApiTags('Tracks')
@Controller('tracks')
export class TracksController {
  constructor(private readonly tracksService: TracksService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upload a new track' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'audio', maxCount: 1 },
        { name: 'cover', maxCount: 1 },
      ],
      {
        storage: audioMulterConfig.storage,
        limits: audioMulterConfig.limits,
      },
    ),
  )
  async create(
    @Request() req: any,
    @Body() dto: CreateTrackDto,
    @UploadedFiles()
    files: {
      audio?: Express.Multer.File[];
      cover?: Express.Multer.File[];
    },
  ) {
    const audioFile = files.audio?.[0];
    const coverFile = files.cover?.[0];

    return this.tracksService.create(
      req.user.id,
      dto,
      audioFile?.path || '',
      coverFile?.path,
    );
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get track by ID' })
  getTrack(@Param('id') id: string, @Request() req: any) {
    return this.tracksService.findById(id, req.user?.id);
  }

  @Get('user/:username')
  @ApiOperation({ summary: 'Get tracks by username' })
  getUserTracks(@Param('username') username: string, @Request() req: any) {
    return this.tracksService.findByUser(username, req.user?.id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update track info' })
  update(
    @Param('id') id: string,
    @Request() req: any,
    @Body() dto: UpdateTrackDto,
  ) {
    return this.tracksService.update(id, req.user.id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a track' })
  delete(@Param('id') id: string, @Request() req: any) {
    return this.tracksService.delete(id, req.user.id);
  }
}
