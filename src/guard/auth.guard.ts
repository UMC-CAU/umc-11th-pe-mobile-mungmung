import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { JwtService, TokenExpiredError } from '@nestjs/jwt';
import type { Request } from 'express';
import { ApiException } from '../exception/api.exception.js';

const BEARER_PREFIX = 'Bearer ';

export interface AuthenticatedRequest extends Request {
  memberId: number;
}

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const header = request.headers.authorization;
    const token = header?.startsWith(BEARER_PREFIX)
      ? header.slice(BEARER_PREFIX.length).trim()
      : '';

    if (!token) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'AUTH401_2',
        '로그인이 필요한 요청입니다.',
      );
    }

    try {
      const payload = await this.jwtService.verifyAsync<{ sub: string }>(token);
      const memberId = Number(payload.sub);
      if (!Number.isSafeInteger(memberId) || memberId <= 0) {
        throw new Error('Invalid member ID in token');
      }
      request.memberId = memberId;
    } catch (error) {
      if (error instanceof TokenExpiredError) {
        throw new ApiException(
          HttpStatus.UNAUTHORIZED,
          'AUTH401_4',
          '토큰이 만료되었습니다. 다시 로그인해주세요.',
        );
      }

      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'AUTH401_3',
        '유효하지 않은 토큰입니다.',
      );
    }

    return true;
  }
}
