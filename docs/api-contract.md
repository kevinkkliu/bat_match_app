# API Contract

This document is the stable contract target for the new stack:

- Flutter client: `/mnt/d/Project/bat_dating_app/apps/mobile_flutter`
- API service: `/mnt/d/Project/bat_dating_app/services/api`
- Data schema source: `/mnt/d/Project/bat_dating_app/prisma/schema.prisma`

## Contract Rules

- API base path: `/api/v1`
- Dates exposed as ISO 8601 strings with timezone offsets
- `gameDate` uses `YYYY-MM-DD`
- IDs are UUID strings
- Frontend must use backend field names directly; do not keep a second legacy shape
- `availableSpots` is server-owned and may be `0`
- `status` and join-request state transitions are whitelisted in service logic

## Enums

### `SkillLevel`

- `L1`
- `L2`
- `L3`
- `L4`
- `L5`

### `GameStatus`

- `OPEN`
- `FULL`
- `CANCELLED`
- `COMPLETED`

### `ApprovalMode`

- `AUTO`
- `MANUAL`

### `JoinRequestStatus`

- `PENDING`
- `APPROVED`
- `REJECTED`
- `WITHDRAWN`
- `CANCELLED`

### `ShuttleType`

- `FEATHER`
- `NYLON`
- `MIXED`

## Shared DTOs

### `UserSummary`

```json
{
  "id": "uuid",
  "nickname": "Kevin",
  "avatarUrl": "https://cdn.example.com/avatar.jpg",
  "gender": "MALE",
  "skillLevel": "L3",
  "preferredCity": "Taipei City",
  "preferredDistrict": "Da'an"
}
```

### `GameSummary`

```json
{
  "id": "uuid",
  "title": "Wednesday Doubles",
  "city": "Taipei City",
  "district": "Da'an",
  "venueName": "NTU Sports Center",
  "venueAddress": "No. 1, Sec. 4, Roosevelt Rd.",
  "gameDate": "2026-03-25",
  "startAt": "2026-03-25T19:00:00+08:00",
  "endAt": "2026-03-25T21:00:00+08:00",
  "skillLevelMin": "L2",
  "skillLevelMax": "L4",
  "fee": 200,
  "capacity": 8,
  "availableSpots": 3,
  "courtCount": 2,
  "shuttleType": "FEATHER",
  "approvalMode": "AUTO",
  "status": "OPEN",
  "host": {
    "id": "uuid",
    "nickname": "Kevin",
    "avatarUrl": "https://cdn.example.com/avatar.jpg",
    "gender": "MALE",
    "skillLevel": "L3",
    "preferredCity": "Taipei City",
    "preferredDistrict": "Da'an"
  }
}
```

### `GameDetail`

```json
{
  "id": "uuid",
  "title": "Wednesday Doubles",
  "city": "Taipei City",
  "district": "Da'an",
  "venueName": "NTU Sports Center",
  "venueAddress": "No. 1, Sec. 4, Roosevelt Rd.",
  "gameDate": "2026-03-25",
  "startAt": "2026-03-25T19:00:00+08:00",
  "endAt": "2026-03-25T21:00:00+08:00",
  "skillLevelMin": "L2",
  "skillLevelMax": "L4",
  "fee": 200,
  "capacity": 8,
  "availableSpots": 3,
  "courtCount": 2,
  "shuttleType": "FEATHER",
  "approvalMode": "AUTO",
  "status": "OPEN",
  "notes": "Bring indoor shoes.",
  "host": {
    "id": "uuid",
    "nickname": "Kevin",
    "avatarUrl": "https://cdn.example.com/avatar.jpg",
    "gender": "MALE",
    "skillLevel": "L3",
    "preferredCity": "Taipei City",
    "preferredDistrict": "Da'an"
  },
  "joinSummary": {
    "currentUserStatus": "APPROVED",
    "currentUserRequestId": "uuid",
    "currentUserRequestedAt": "2026-03-21T12:00:00+08:00",
    "pendingCount": 0,
    "approvedCount": 5
  }
}
```

### `JoinRequestDto`

```json
{
  "id": "uuid",
  "gameId": "uuid",
  "userId": "uuid",
  "status": "PENDING",
  "message": "I am L3 and can bring shuttles.",
  "respondedAt": null,
  "approvedAt": null,
  "rejectedReason": null,
  "createdAt": "2026-03-21T12:00:00+08:00",
  "updatedAt": "2026-03-21T12:00:00+08:00",
  "applicant": {
    "id": "uuid",
    "nickname": "Mia",
    "avatarUrl": "https://cdn.example.com/avatar.jpg",
    "gender": "FEMALE",
    "skillLevel": "L3",
    "preferredCity": "Taipei City",
    "preferredDistrict": "Xinyi"
  }
}
```

### `PaginatedGamesResponse`

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

## Authentication

### `POST /api/v1/auth/register`

Request:

```json
{
  "email": "a@b.com",
  "phoneNumber": "0912345678",
  "password": "Secret123!",
  "nickname": "Kevin",
  "skillLevel": "L3"
}
```

Response `201`:

```json
{
  "user": {
    "id": "uuid",
    "nickname": "Kevin",
    "avatarUrl": null,
    "gender": null,
    "skillLevel": "L3",
    "preferredCity": null,
    "preferredDistrict": null
  },
  "token": "jwt"
}
```

### `POST /api/v1/auth/login`

Request:

```json
{
  "emailOrPhone": "a@b.com",
  "password": "Secret123!"
}
```

Response `200`: same shape as register.

### `GET /api/v1/auth/me`

Response `200`:

```json
{
  "user": {
    "id": "uuid",
    "nickname": "Kevin",
    "avatarUrl": null,
    "gender": null,
    "skillLevel": "L3",
    "preferredCity": "Taipei City",
    "preferredDistrict": "Da'an"
  }
}
```

## Profile

### `PATCH /api/v1/users/me`

Request:

```json
{
  "nickname": "Kevin",
  "avatarUrl": "https://cdn.example.com/avatar.jpg",
  "gender": "MALE",
  "skillLevel": "L4",
  "preferredCity": "Taipei City",
  "preferredDistrict": "Da'an"
}
```

Response `200`: same `user` shape as `auth/me`.

## Games

### `GET /api/v1/games`

Query:

- `city`
- `district`
- `date`
- `status`
- `skillLevel`
- `feeMin`
- `feeMax`
- `vacancyOnly`
- `page`
- `pageSize`

Notes:

- `vacancyOnly=true` returns only games with `status=OPEN` and `availableSpots > 0`
- `feeMin` and `feeMax` filter by the numeric `fee` field

Response `200`:

```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Wednesday Doubles",
      "city": "Taipei City",
      "district": "Da'an",
      "venueName": "NTU Sports Center",
      "venueAddress": "No. 1, Sec. 4, Roosevelt Rd.",
      "gameDate": "2026-03-25",
      "startAt": "2026-03-25T19:00:00+08:00",
      "endAt": "2026-03-25T21:00:00+08:00",
      "skillLevelMin": "L2",
      "skillLevelMax": "L4",
      "fee": 200,
      "capacity": 8,
      "availableSpots": 3,
      "courtCount": 2,
      "shuttleType": "FEATHER",
      "approvalMode": "AUTO",
      "status": "OPEN",
      "host": {
        "id": "uuid",
        "nickname": "Kevin",
        "avatarUrl": null,
        "gender": null,
        "skillLevel": "L3",
        "preferredCity": null,
        "preferredDistrict": null
      }
    }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 1
}
```

### `GET /api/v1/games/:gameId`

Response `200`: `GameDetail`.

### `POST /api/v1/games`

Request:

```json
{
  "title": "Wednesday Doubles",
  "city": "Taipei City",
  "district": "Da'an",
  "venueName": "NTU Sports Center",
  "venueAddress": "No. 1, Sec. 4, Roosevelt Rd.",
  "gameDate": "2026-03-25",
  "startAt": "2026-03-25T19:00:00+08:00",
  "endAt": "2026-03-25T21:00:00+08:00",
  "skillLevelMin": "L2",
  "skillLevelMax": "L4",
  "fee": 200,
  "capacity": 8,
  "courtCount": 2,
  "shuttleType": "FEATHER",
  "approvalMode": "AUTO",
  "notes": "Bring indoor shoes."
}
```

Response `201`: `GameDetail`

Notes:

- `hostId` is derived from the authenticated user and must not be sent by the client
- `availableSpots` is initialized by the server as `capacity`

### `PATCH /api/v1/games/:gameId`

Request: same fields as create, all optional.  
Response `200`: `GameDetail`

### `PATCH /api/v1/games/:gameId/status`

Request:

```json
{
  "status": "CANCELLED"
}
```

Response `200`: `GameDetail`

## Join / Request to Join

### `POST /api/v1/games/:gameId/join`

Request:

```json
{
  "message": "I am L3 and can bring shuttles."
}
```

Response `201`:

```json
{
  "joinRequest": {
    "id": "uuid",
    "gameId": "uuid",
    "userId": "uuid",
    "status": "APPROVED",
    "message": "I am L3 and can bring shuttles.",
    "respondedAt": "2026-03-21T12:00:00+08:00",
    "approvedAt": "2026-03-21T12:00:00+08:00",
    "rejectedReason": null,
    "createdAt": "2026-03-21T12:00:00+08:00",
    "updatedAt": "2026-03-21T12:00:00+08:00"
  },
  "game": {
    "id": "uuid",
    "availableSpots": 3,
    "status": "OPEN"
  }
}
```

### `GET /api/v1/games/:gameId/join-requests`

Host-only, authenticated endpoint.

Response `200`:

```json
{
  "items": [
    {
      "id": "uuid",
      "gameId": "uuid",
      "userId": "uuid",
      "status": "PENDING",
      "message": "I am L3 and can bring shuttles.",
      "respondedAt": null,
      "approvedAt": null,
      "rejectedReason": null,
      "createdAt": "2026-03-21T12:00:00+08:00",
      "updatedAt": "2026-03-21T12:00:00+08:00",
      "applicant": {
        "id": "uuid",
        "nickname": "Mia",
        "avatarUrl": null,
        "gender": "FEMALE",
        "skillLevel": "L3",
        "preferredCity": "Taipei City",
        "preferredDistrict": "Xinyi"
      }
    }
  ]
}
```

### `PATCH /api/v1/join-requests/:joinRequestId/approve`

Host-only, authenticated endpoint.

Response `200`: `JoinRequestDto` + updated game slot summary.

### `PATCH /api/v1/join-requests/:joinRequestId/reject`

Request:

```json
{
  "reason": "Skill level mismatch"
}
```

Response `200`: `JoinRequestDto`

### `PATCH /api/v1/join-requests/:joinRequestId/withdraw`

Response `200`: `JoinRequestDto`

## My Games

### `GET /api/v1/me/games/joined`

Authenticated endpoint for the current user.

Response `200`:

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

### `GET /api/v1/me/games/created`

Authenticated endpoint for the current user.

Response `200`:

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

## Validation Notes

- `endAt` must be strictly later than `startAt`
- `gameDate` must match the local calendar date of `startAt`
- `fee`, `capacity`, and `courtCount` must be positive integers
- `availableSpots` must be a non-negative integer and should only be set by server logic
- `skillLevelMax`, when provided, must not be lower than `skillLevelMin`
- `city`, `district`, `venueName`, and `nickname` should be trimmed and length-limited
- at least one of `email` or `phoneNumber` must be present for registration
- `message` on join requests should have a safe max length, such as 300 characters

## Guardrails

- unique constraints on `email`, `phoneNumber`, and `(gameId, userId)`
- join flow decrements capacity only through transactional code
- manual approval keeps the request `PENDING` until the host approves or rejects it
- status transitions should be whitelisted in service/controller logic
