import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { FeedService } from './feed.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Feed')
@Controller('feed')
export class FeedController {
  constructor(private readonly feedService: FeedService) {}

  @Get('following')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get following feed' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getFollowingFeed(
    @Request() req: any,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.feedService.getFollowingFeed(req.user.id, +page, +limit);
  }

  @Get('trending')
  @ApiOperation({ summary: 'Get trending feed' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getTrendingFeed(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.feedService.getTrendingFeed(+page, +limit);
  }

  @Get('new')
  @ApiOperation({ summary: 'Get newest tracks feed' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getNewFeed(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.feedService.getNewFeed(+page, +limit);
  }
}
