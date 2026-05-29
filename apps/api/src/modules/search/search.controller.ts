import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { SearchService } from './search.service';

@ApiTags('Search')
@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  @ApiOperation({ summary: 'Search tracks and users' })
  @ApiQuery({ name: 'q', required: true, type: String })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: ['tracks', 'users', 'all'],
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  search(
    @Query('q') query: string,
    @Query('type') type: 'tracks' | 'users' | 'all' = 'all',
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.searchService.search(query, type, +page, +limit);
  }
}
