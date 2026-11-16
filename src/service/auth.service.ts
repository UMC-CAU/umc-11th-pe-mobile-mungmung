import { HttpStatus, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Member } from '../entity/member.entity.js';
import type { LoginRequestDto } from '../dto/login-request.dto.js';
import type { LoginResponseDto } from '../dto/login-response.dto.js';
import { ApiException } from '../exception/api.exception.js';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
    private readonly jwtService: JwtService,
  ) {}

  async login(dto: LoginRequestDto): Promise<LoginResponseDto> {
    const member = await this.memberRepository.findOneBy({ email: dto.email });
    if (!member || !(await bcrypt.compare(dto.password, member.password))) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'AUTH401_1',
        '이메일 또는 비밀번호가 올바르지 않습니다.',
      );
    }

    const accessToken = await this.jwtService.signAsync({
      sub: String(member.memberId),
      email: member.email,
    });

    return { nickname: member.nickname, accessToken };
  }
}
