import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Track, TrackStatus, TrackVisibility } from '../tracks/track.entity';
import { User } from '../users/user.entity';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { Meilisearch } = require('meilisearch');

@Injectable()
export class SearchService implements OnModuleInit {
  private readonly logger = new Logger(SearchService.name);
  private client: any;

  constructor(private readonly configService: ConfigService) {
    this.client = new Meilisearch({
      host: this.configService.get<string>('meilisearch.host')!,
      apiKey: this.configService.get<string>('meilisearch.masterKey'),
    });
  }

  async onModuleInit() {
    await this.setupIndexes();
  }

  private async setupIndexes() {
    try {
      await this.client.createIndex('tracks', { primaryKey: 'id' });
      await this.client.index('tracks').updateSettings({
        searchableAttributes: ['title', 'description', 'genre', 'tags', 'username'],
        filterableAttributes: ['genre', 'visibility', 'status', 'userId'],
        sortableAttributes: ['createdAt', 'playCount', 'likesCount'],
        rankingRules: [
          'words', 'typo', 'proximity', 'attribute',
          'sort', 'exactness', 'playCount:desc',
        ],
      });

      await this.client.createIndex('users', { primaryKey: 'id' });
      await this.client.index('users').updateSettings({
        searchableAttributes: ['username', 'bio'],
        filterableAttributes: ['role', 'verifiedStatus'],
        sortableAttributes: ['createdAt'],
      });

      this.logger.log('Meilisearch indexes configured');
    } catch {
      this.logger.warn('Meilisearch indexes may already exist');
    }
  }

  async indexTrack(track: Track & { username?: string }) {
    try {
      await this.client.index('tracks').addDocuments([{
        id: track.id,
        title: track.title,
        description: track.description,
        genre: track.genre,
        tags: track.tags,
        coverUrl: track.coverUrl,
        audioUrl: track.audioUrl,
        duration: track.duration,
        playCount: track.playCount,
        likesCount: track.likesCount,
        visibility: track.visibility,
        status: track.status,
        userId: track.userId,
        username: track.username || track.user?.username,
        createdAt: track.createdAt,
      }]);
    } catch (error) {
      this.logger.error('Failed to index track', error);
    }
  }

  async removeTrack(trackId: string) {
    try {
      await this.client.index('tracks').deleteDocument(trackId);
    } catch (error) {
      this.logger.error('Failed to remove track from index', error);
    }
  }

  async indexUser(user: User) {
    try {
      await this.client.index('users').addDocuments([{
        id: user.id,
        username: user.username,
        bio: user.bio,
        avatarUrl: user.avatarUrl,
        role: user.role,
        verifiedStatus: user.verifiedStatus,
        createdAt: user.createdAt,
      }]);
    } catch (error) {
      this.logger.error('Failed to index user', error);
    }
  }

  async search(query: string, type?: 'tracks' | 'users' | 'all', page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    if (type === 'tracks') return this.searchTracks(query, offset, limit);
    if (type === 'users') return this.searchUsers(query, offset, limit);

    const [tracks, users] = await Promise.all([
      this.searchTracks(query, 0, 5),
      this.searchUsers(query, 0, 5),
    ]);
    return { tracks, users };
  }

  private async searchTracks(query: string, offset: number, limit: number) {
    const result = await this.client.index('tracks').search(query, {
      offset,
      limit,
      filter: [
        `visibility = ${TrackVisibility.PUBLIC}`,
        `status = ${TrackStatus.READY}`,
      ],
      sort: ['playCount:desc'],
    });
    return { data: result.hits, total: result.estimatedTotalHits, page: Math.floor(offset / limit) + 1, limit };
  }

  private async searchUsers(query: string, offset: number, limit: number) {
    const result = await this.client.index('users').search(query, {
      offset,
      limit,
    });
    return { data: result.hits, total: result.estimatedTotalHits, page: Math.floor(offset / limit) + 1, limit };
  }
}
