import {
  Controller,
  Post,
  Delete,
  Get,
  Param,
  Body,
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
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Comments')
@Controller('tracks/:trackId/comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Add comment to track' })
  create(
    @Param('trackId') trackId: string,
    @Request() req: any,
    @Body() dto: CreateCommentDto,
  ) {
    return this.commentsService.create(req.user.id, trackId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get track comments' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findByTrack(
    @Param('trackId') trackId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.commentsService.findByTrack(trackId, +page, +limit);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a comment' })
  delete(@Param('id') id: string, @Request() req: any) {
    return this.commentsService.delete(id, req.user.id);
  }
}
