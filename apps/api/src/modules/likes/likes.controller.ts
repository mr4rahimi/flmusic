import {
  Controller,
  Post,
  Delete,
  Get,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { LikesService } from './likes.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Likes')
@Controller()
export class LikesController {
  constructor(private readonly likesService: LikesService) {}

  @Post('tracks/:trackId/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Like a track' })
  like(@Param('trackId') trackId: string, @Request() req: any) {
    return this.likesService.like(req.user.id, trackId);
  }

  @Delete('tracks/:trackId/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Unlike a track' })
  unlike(@Param('trackId') trackId: string, @Request() req: any) {
    return this.likesService.unlike(req.user.id, trackId);
  }

  @Get('tracks/:trackId/liked')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if track is liked' })
  isLiked(@Param('trackId') trackId: string, @Request() req: any) {
    return this.likesService.isLiked(req.user.id, trackId);
  }

  @Get('users/me/likes')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get my liked tracks' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getLikedTracks(
    @Request() req: any,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.likesService.getLikedTracks(req.user.id, +page, +limit);
  }
}
