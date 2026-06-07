import {
  Controller, Get, Post, Delete, Body, Param,
  UseGuards, Request,
} from '@nestjs/common';
import { PlaylistsService } from './playlists.service';
import { CreatePlaylistDto } from './dto/create-playlist.dto';
import { AddTrackDto } from './dto/add-track.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Controller('playlists')
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@Request() req, @Body() dto: CreatePlaylistDto) {
    return this.playlistsService.create(req.user.id, dto);
  }

  @Get('my')
  @UseGuards(JwtAuthGuard)
  getMyPlaylists(@Request() req) {
    return this.playlistsService.findUserPlaylists(req.user.id);
  }

  @Get('user/:userId')
  getUserPlaylists(@Param('userId') userId: string) {
    return this.playlistsService.findUserPlaylists(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.playlistsService.findOne(id);
  }

  @Post(':id/tracks')
  @UseGuards(JwtAuthGuard)
  addTrack(@Param('id') id: string, @Body() dto: AddTrackDto, @Request() req) {
    return this.playlistsService.addTrack(id, dto.trackId, req.user.id);
  }

  @Delete(':id/tracks/:trackId')
  @UseGuards(JwtAuthGuard)
  removeTrack(@Param('id') id: string, @Param('trackId') trackId: string, @Request() req) {
    return this.playlistsService.removeTrack(id, trackId, req.user.id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  delete(@Param('id') id: string, @Request() req) {
    return this.playlistsService.delete(id, req.user.id);
  }
}
