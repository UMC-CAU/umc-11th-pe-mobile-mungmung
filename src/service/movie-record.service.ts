import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import type { CreateMovieRecordDto } from '../dto/create-movie-record.dto.js';
import type { MovieRecordResponseDto } from '../dto/movie-record-response.dto.js';
import { FavoriteService } from './favorite.service.js';
import { RatingService } from './rating.service.js';

@Injectable()
export class MovieRecordService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly ratingService: RatingService,
    private readonly favoriteService: FavoriteService,
  ) {}

  async create(
    memberId: number,
    dto: CreateMovieRecordDto,
  ): Promise<MovieRecordResponseDto> {
    return this.dataSource.transaction(async (manager) => {
      const rating = await this.ratingService.create(memberId, dto, manager);
      const favorite = dto.addToFavorites
        ? await this.favoriteService.create(memberId, dto, manager)
        : null;
      return { rating, favorite };
    });
  }
}
