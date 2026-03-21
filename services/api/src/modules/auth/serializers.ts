import type { UserSummaryDto } from '../../contracts/api';

export type UserSummaryRecord = {
  id: string;
  nickname: string;
  avatarUrl: string | null;
  gender: UserSummaryDto['gender'];
  skillLevel: UserSummaryDto['skillLevel'];
  preferredCity: string | null;
  preferredDistrict: string | null;
};

export function toUserSummary(user: UserSummaryRecord): UserSummaryDto {
  return {
    id: user.id,
    nickname: user.nickname,
    avatarUrl: user.avatarUrl,
    gender: user.gender,
    skillLevel: user.skillLevel,
    preferredCity: user.preferredCity,
    preferredDistrict: user.preferredDistrict,
  };
}
