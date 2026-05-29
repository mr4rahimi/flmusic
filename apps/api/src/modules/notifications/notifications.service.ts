import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notifRepo: Repository<Notification>,
  ) {}

  async create(
    userId: string,
    actorId: string,
    type: NotificationType,
    entityId?: string,
  ): Promise<void> {
    // به خودت notification نده
    if (userId === actorId) return;

    // duplicate check برای follow
    if (type === NotificationType.FOLLOW) {
      const existing = await this.notifRepo.findOne({
        where: { userId, actorId, type },
      });
      if (existing) return;
    }

    const notif = this.notifRepo.create({ userId, actorId, type, entityId });
    await this.notifRepo.save(notif);
  }

  async findByUser(userId: string, page = 1, limit = 20) {
    const [items, total] = await this.notifRepo
      .createQueryBuilder('notif')
      .innerJoinAndSelect('notif.actor', 'actor')
      .where('notif.userId = :userId', { userId })
      .orderBy('notif.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: items.map((n) => ({
        id: n.id,
        type: n.type,
        entityId: n.entityId,
        isRead: n.isRead,
        createdAt: n.createdAt,
        actor: {
          id: n.actor.id,
          username: n.actor.username,
          avatarUrl: n.actor.avatarUrl,
          verifiedStatus: n.actor.verifiedStatus,
        },
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      unreadCount: await this.getUnreadCount(userId),
    };
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notifRepo.count({ where: { userId, isRead: false } });
  }

  async markOneAsRead(id: string, userId: string): Promise<void> {
    await this.notifRepo.update({ id, userId }, { isRead: true });
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notifRepo.update({ userId, isRead: false }, { isRead: true });
  }
}
