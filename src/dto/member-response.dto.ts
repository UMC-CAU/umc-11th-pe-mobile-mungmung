import { Member } from '../entity/member.entity.js';

export class MemberResponseDto {
  memberId: number;
  email: string;
  nickname: string;

  static from(member: Member): MemberResponseDto {
    return {
      memberId: member.memberId,
      email: member.email,
      nickname: member.nickname,
    };
  }
}
