export type UserSummaryDto = {
  id: string;
  nickname: string;
  avatarUrl: string | null;
  gender: 'MALE' | 'FEMALE' | 'OTHER' | 'UNDISCLOSED' | null;
  skillLevel: 'L1' | 'L2' | 'L3' | 'L4' | 'L5';
  preferredCity: string | null;
  preferredDistrict: string | null;
  phoneNumber?: string | null;
  lineId?: string | null;
};

export type AuthSessionDto = {
  user: UserSummaryDto;
  token: string;
};

export type GameSummaryDto = {
  id: string;
  title: string;
  city: string;
  district: string;
  venueName: string;
  venueAddress: string;
  gameDate: string;
  startAt: string;
  endAt: string;
  skillLevelMin: 'L1' | 'L2' | 'L3' | 'L4' | 'L5';
  skillLevelMax: 'L1' | 'L2' | 'L3' | 'L4' | 'L5' | null;
  fee: number;
  capacity: number;
  availableSpots: number;
  courtCount: number;
  shuttleType: 'FEATHER' | 'NYLON' | 'MIXED' | null;
  approvalMode: 'AUTO' | 'MANUAL';
  status: 'OPEN' | 'FULL' | 'CANCELLED' | 'COMPLETED';
  host: UserSummaryDto;
};

export type GameDetailDto = GameSummaryDto & {
  notes: string | null;
  canViewHostContact: boolean;
  joinSummary: {
    currentUserStatus: 'PENDING' | 'APPROVED' | 'REJECTED' | 'WITHDRAWN' | 'CANCELLED' | null;
    currentUserRequestId: string | null;
    currentUserRequestedAt: string | null;
    pendingCount: number;
    approvedCount: number;
  };
};

export type JoinRequestDto = {
  id: string;
  gameId: string;
  userId: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'WITHDRAWN' | 'CANCELLED';
  message: string | null;
  respondedAt: string | null;
  approvedAt: string | null;
  rejectedReason: string | null;
  createdAt: string;
  updatedAt: string;
  applicant: UserSummaryDto;
};

export type PaginatedResponse<T> = {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
};

export type GameMutationSummary = {
  id: string;
  availableSpots: number;
  status: 'OPEN' | 'FULL' | 'CANCELLED' | 'COMPLETED';
};
