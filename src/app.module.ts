// src/app.module.ts
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Member } from './entity/member.entity.js';
import { Rating } from './entity/rating.entity.js';
import { MemberController } from './controller/member.controller.js';
import { RatingController } from './controller/rating.controller.js';
import { MemberService } from './service/member.service.js';
import { RatingService } from './service/rating.service.js';
import { AuthController } from './controller/auth.controller.js';
import { AuthService } from './service/auth.service.js';
import { AuthGuard } from './guard/auth.guard.js';
import { FavoriteController } from './controller/favorite.controller.js';
import { MovieRecordController } from './controller/movie-record.controller.js';
import { Favorite } from './entity/favorite.entity.js';
import { FavoriteService } from './service/favorite.service.js';
import { MovieRecordService } from './service/movie-record.service.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const expiresIn = Number(
          config.getOrThrow<string>('JWT_ACCESS_EXPIRATION'),
        );
        if (!Number.isSafeInteger(expiresIn) || expiresIn <= 0) {
          throw new Error(
            'JWT_ACCESS_EXPIRATION must be a positive number of seconds',
          );
        }
        return {
          secret: config.getOrThrow<string>('JWT_SECRET'),
          signOptions: { expiresIn },
        };
      },
    }),
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: process.env.DB_HOST,
      port: 3306,
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      autoLoadEntities: true,
      synchronize: false,
    }),
    TypeOrmModule.forFeature([Member, Rating, Favorite]),
  ],
  controllers: [
    MemberController,
    RatingController,
    AuthController,
    FavoriteController,
    MovieRecordController,
  ],
  providers: [
    MemberService,
    RatingService,
    AuthService,
    AuthGuard,
    FavoriteService,
    MovieRecordService,
  ],
})
export class AppModule {}
