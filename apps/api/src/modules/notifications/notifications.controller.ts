import {
  Controller,
  Get,
  Patch,
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
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Get my notifications' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getNotifications(
    @Request() req: any,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.notificationsService.findByUser(req.user.id, +page, +limit);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notifications count' })
  getUnreadCount(@Request() req: any) {
    return this.notificationsService.getUnreadCount(req.user.id);
  }

  @Patch('read-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Mark all notifications as read' })
  markAllAsRead(@Request() req: any) {
    return this.notificationsService.markAllAsRead(req.user.id);
  }

  @Patch(':id/read')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Mark one notification as read' })
  markOneAsRead(@Param('id') id: string, @Request() req: any) {
    return this.notificationsService.markOneAsRead(id, req.user.id);
  }
}
