import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, QueryFailedError, Repository } from 'typeorm';
import type { CreateFavoriteDto } from '../dto/create-favorite.dto.js';
import { FavoriteResponseDto } from '../dto/favorite-response.dto.js';
import { FavoriteStatusResponseDto } from '../dto/favorite-status-response.dto.js';
import { Favorite } from '../entity/favorite.entity.js';
import { Member } from '../entity/member.entity.js';
import { ApiException } from '../exception/api.exception.js';

@Injectable()
export class FavoriteService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async create(
    memberId: number,
    dto: CreateFavoriteDto,
    manager?: EntityManager,
  ): Promise<FavoriteResponseDto> {
    const members = manager?.getRepository(Member) ?? this.memberRepository;
    const favorites =
      manager?.getRepository(Favorite) ?? this.favoriteRepository;
    const member = await members.findOneBy({ memberId });
    if (!member) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'MEMBER404_1',
        '해당 회원을 찾을 수 없습니다.',
      );
    }

    try {
      const saved = await favorites.save(
        favorites.create({ member, movieId: dto.movieId }),
      );
      return FavoriteResponseDto.from(saved);
    } catch (error) {
      if (
        error instanceof QueryFailedError &&
        (error.driverError as { code?: string }).code === 'ER_DUP_ENTRY'
      ) {
        throw new ApiException(
          HttpStatus.CONFLICT,
          'FAVORITE409_1',
          '이미 이 영화를 즐겨찾기하셨습니다.',
        );
      }
      throw error;
    }
  }

  async getMyFavorites(memberId: number): Promise<FavoriteResponseDto[]> {
    const favorites = await this.favoriteRepository.find({
      where: { member: { memberId } },
      order: { favoriteId: 'DESC' },
    });
    return favorites.map(FavoriteResponseDto.from);
  }

  async getStatus(
    memberId: number,
    movieId: number,
  ): Promise<FavoriteStatusResponseDto> {
    const isFavorite = await this.favoriteRepository.exists({
      where: { member: { memberId }, movieId },
    });
    return FavoriteStatusResponseDto.from(isFavorite);
  }

  async delete(memberId: number, movieId: number): Promise<void> {
    const favorite = await this.favoriteRepository.findOne({
      where: { member: { memberId }, movieId },
    });
    if (favorite) {
      const deleted = await this.favoriteRepository.delete(favorite.favoriteId);
      if (deleted.affected) return;
    }

    throw new ApiException(
      HttpStatus.NOT_FOUND,
      'FAVORITE404_1',
      '즐겨찾기한 영화를 찾을 수 없습니다.',
    );
  }
}
