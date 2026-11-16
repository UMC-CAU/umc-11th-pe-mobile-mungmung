import type { FavoriteResponseDto } from './favorite-response.dto.js';
import type { RatingResponseDto } from './rating-response.dto.js';

export class MovieRecordResponseDto {
  rating: RatingResponseDto;
  favorite: FavoriteResponseDto | null;
}
