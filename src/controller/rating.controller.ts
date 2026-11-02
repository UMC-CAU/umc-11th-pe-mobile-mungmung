import { PositiveIdPipe } from '../positive-id.pipe.js';
// src/controller/rating.controller.ts
import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CreateRatingDto } from '../dto/create-rating.dto.js';
import { UpdateRatingDto } from '../dto/update-rating.dto.js';
import { RatingService } from '../service/rating.service.js';

@Controller('members')
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  @Get(':memberId/ratings')
  getMemberRatings(@Param('memberId', PositiveIdPipe) memberId: number) {
    return this.ratingService.getRatingsByMember(memberId);
  }

  @Post(':memberId/ratings')
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Param('memberId', PositiveIdPipe) memberId: number,
    @Body() dto: CreateRatingDto,
  ) {
    const ratingId = await this.ratingService.create(memberId, dto);
    return {
      isSuccess: true,
      code: 'COMMON201',
      message: '평점 등록에 성공했습니다.',
      result: ratingId,
    };
  }

  @Patch(':memberId/ratings/:ratingId')
  async update(
    @Param('memberId', PositiveIdPipe) memberId: number,
    @Param('ratingId', PositiveIdPipe) ratingId: number,
    @Body() dto: UpdateRatingDto,
  ) {
    await this.ratingService.update(ratingId, memberId, dto);
    return {
      isSuccess: true,
      code: 'COMMON200',
      message: '평점 수정에 성공했습니다.',
      result: null,
    };
  }

  @Delete(':memberId/ratings/:ratingId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(
    @Param('memberId', PositiveIdPipe) memberId: number,
    @Param('ratingId', PositiveIdPipe) ratingId: number,
  ) {
    await this.ratingService.delete(ratingId, memberId);
  }
}
