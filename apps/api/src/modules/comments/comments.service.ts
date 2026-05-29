import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Comment } from './comment.entity';
import { Track } from '../tracks/track.entity';
import { CreateCommentDto } from './dto/create-comment.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/notification.entity';

@Injectable()
export class CommentsService {
  constructor(
    @InjectRepository(Comment)
    private readonly commentRepo: Repository<Comment>,
    @InjectRepository(Track)
    private readonly trackRepo: Repository<Track>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(userId: string, trackId: string, dto: CreateCommentDto): Promise<Comment> {
    const track = await this.trackRepo.findOne({ where: { id: trackId } });
    if (!track) throw new NotFoundException('Track not found');

    const comment = this.commentRepo.create({ userId, trackId, content: dto.content });
    const saved = await this.commentRepo.save(comment);
    await this.trackRepo.increment({ id: trackId }, 'commentsCount', 1);

    await this.notificationsService.create(
      track.userId,
      userId,
      NotificationType.COMMENT,
      saved.id,
    );

    return this.commentRepo.findOne({
      where: { id: saved.id },
      relations: { user: true },
    }) as Promise<Comment>;
  }

  async findByTrack(trackId: string, page = 1, limit = 20) {
    const track = await this.trackRepo.findOne({ where: { id: trackId } });
    if (!track) throw new NotFoundException('Track not found');

    const [items, total] = await this.commentRepo
      .createQueryBuilder('comment')
      .innerJoinAndSelect('comment.user', 'user')
      .where('comment.trackId = :trackId', { trackId })
      .orderBy('comment.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: items.map((c) => ({
        id: c.id,
        content: c.content,
        createdAt: c.createdAt,
        user: {
          id: c.user.id,
          username: c.user.username,
          avatarUrl: c.user.avatarUrl,
          verifiedStatus: c.user.verifiedStatus,
        },
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async delete(id: string, userId: string): Promise<void> {
    const comment = await this.commentRepo.findOne({ where: { id } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.userId !== userId) throw new ForbiddenException();

    await this.commentRepo.remove(comment);
    await this.trackRepo.decrement(
      { id: comment.trackId },
      'commentsCount',
      1,
    );
  }
}
