import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import configuration from './config/configuration';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { FollowersModule } from './modules/followers/followers.module';
import { TracksModule } from './modules/tracks/tracks.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { LikesModule } from './modules/likes/likes.module';
import { CommentsModule } from './modules/comments/comments.module';
import { FeedModule } from './modules/feed/feed.module';
import { SearchModule } from './modules/search/search.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { PlaylistsModule } from './modules/playlists/playlists.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('database.host'),
        port: config.get('database.port'),
        username: config.get('database.username'),
        password: config.get('database.password'),
        database: config.get('database.name'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: config.get('nodeEnv') === 'development',
        logging: config.get('nodeEnv') === 'development',
      }),
    }),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        redis: {
          host: config.get('redis.host'),
          port: config.get('redis.port'),
        },
      }),
    }),
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),
    AuthModule,
    UsersModule,
    ProfilesModule,
    FollowersModule,
    TracksModule,
    UploadsModule,
    LikesModule,
    CommentsModule,
    FeedModule,
    SearchModule,
    NotificationsModule,
    PlaylistsModule,
  ],
})
export class AppModule {}
