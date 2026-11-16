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
  Req,
  UseGuards,
} from '@nestjs/common';
import { CreateRatingDto } from '../dto/create-rating.dto.js';
import { UpdateRatingDto } from '../dto/update-rating.dto.js';
import { AuthGuard, type AuthenticatedRequest } from '../guard/auth.guard.js';
import { PositiveIdPipe } from '../positive-id.pipe.js';
import { RatingService } from '../service/rating.service.js';

@Controller()
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  @Get('members/:memberId/ratings')
  getMemberRatings(@Param('memberId', PositiveIdPipe) memberId: number) {
    return this.ratingService.getRatingsByMember(memberId);
  }

  @Post('ratings')
  @UseGuards(AuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateRatingDto,
  ) {
    const result = await this.ratingService.create(request.memberId, dto);
    return {
      isSuccess: true,
      code: 'COMMON201',
      message: '평점을 등록했습니다.',
      result,
    };
  }

  @Patch('ratings/:ratingId')
  @UseGuards(AuthGuard)
  @HttpCode(HttpStatus.OK)
  async update(
    @Req() request: AuthenticatedRequest,
    @Param('ratingId', PositiveIdPipe) ratingId: number,
    @Body() dto: UpdateRatingDto,
  ) {
    const result = await this.ratingService.update(request.memberId, ratingId, dto);
    return {
      isSuccess: true,
      code: 'COMMON200',
      message: '평점을 수정했습니다.',
      result,
    };
  }

  @Delete('ratings/:ratingId')
  @UseGuards(AuthGuard)
  @HttpCode(HttpStatus.OK)
  async delete(
    @Req() request: AuthenticatedRequest,
    @Param('ratingId', PositiveIdPipe) ratingId: number,
  ) {
    await this.ratingService.delete(request.memberId, ratingId);
    return {
      isSuccess: true,
      code: 'COMMON200',
      message: '평점을 삭제했습니다.',
      result: null,
    };
  }
}
