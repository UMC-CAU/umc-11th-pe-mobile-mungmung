// src/service/rating.service.ts
import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { type EntityManager, QueryFailedError, Repository } from 'typeorm';
import { Rating } from '../entity/rating.entity.js';
import { Member } from '../entity/member.entity.js';
import { RatingResponseDto } from '../dto/rating-response.dto.js';
import { ApiException } from '../exception/api.exception.js';
import { CreateRatingDto } from '../dto/create-rating.dto.js';
import { UpdateRatingDto } from '../dto/update-rating.dto.js';

@Injectable()
export class RatingService {
  constructor(
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async getRatingsByMember(memberId: number): Promise<RatingResponseDto[]> {
    await this.findMember(memberId);

    const ratings = await this.ratingRepository.find({
      where: { member: { memberId } },
      order: { ratingId: 'DESC' },
    });

    return ratings.map(RatingResponseDto.from);
  }
  async create(
    memberId: number,
    dto: CreateRatingDto,
    manager?: EntityManager,
  ): Promise<RatingResponseDto> {
    const members = manager?.getRepository(Member) ?? this.memberRepository;
    const ratings = manager?.getRepository(Rating) ?? this.ratingRepository;
    const member = await this.findMember(memberId, members);
    const duplicate = () =>
      new ApiException(
        HttpStatus.CONFLICT,
        'RATING409_1',
        '이미 이 영화에 평점을 남기셨습니다.',
      );

    const existing = await ratings.findOne({
      where: { member: { memberId }, movieId: dto.movieId },
    });
    if (existing) throw duplicate();

    try {
      const saved = await ratings.save(
        ratings.create({
          member,
          movieId: dto.movieId,
          score: dto.score,
          comment: dto.comment ?? null,
        }),
      );
      return RatingResponseDto.from(saved);
    } catch (error) {
      if (
        error instanceof QueryFailedError &&
        (error.driverError as { code?: string }).code === 'ER_DUP_ENTRY'
      ) {
        throw duplicate();
      }
      throw error;
    }
  }

  async update(
    memberId: number,
    ratingId: number,
    dto: UpdateRatingDto,
  ): Promise<RatingResponseDto> {
    const rating = await this.findOwnedRating(memberId, ratingId);

    rating.score = dto.score;
    rating.comment = dto.comment ?? null;

    const saved = await this.ratingRepository.save(rating);
    return RatingResponseDto.from(saved);
  }

  async delete(memberId: number, ratingId: number): Promise<void> {
    const rating = await this.findOwnedRating(memberId, ratingId);

    await this.ratingRepository.remove(rating);
  }

  /**
   * 평점을 찾고, 그 평점이 요청자의 것인지까지 확인합니다.
   * 먼저 찾아보고(없으면 404), 찾았으면 주인을 봅니다(내 것이 아니면 403).
   */
  private async findOwnedRating(
    memberId: number,
    ratingId: number,
  ): Promise<Rating> {
    const rating = await this.ratingRepository.findOne({
      where: { ratingId },
      relations: { member: true }, // 작성자를 함께 불러와야 소유권을 비교할 수 있습니다
    });

    if (!rating) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'RATING404_1',
        '해당 평점을 찾을 수 없습니다.',
      );
    }

    if (rating.member.memberId !== memberId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'RATING403_1',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
    }

    return rating;
  }

  private async findMember(
    memberId: number,
    members = this.memberRepository,
  ): Promise<Member> {
    const member = await members.findOneBy({ memberId });
    if (!member) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'MEMBER404_1',
        '해당 회원을 찾을 수 없습니다.',
      );
    }
    return member;
  }
}
