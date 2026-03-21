# Taiwan Badminton Match Backend MVP

## Chosen Persistence

This MVP uses PostgreSQL with Prisma ORM.

Reason:
- the product already has strongly related entities (`users`, `games`, `join_requests`)
- query filters on city, district, date, and status map well to relational indexes
- preventing overbooking is simpler and safer with transactional writes and atomic decrements

## Data Model Summary

### `User`
- stores login identity and player profile
- `email` and `phoneNumber` are both optional in schema, but application validation should require at least one of them
- one user can host many games and create many join requests

### `Game`
- owned by one host (`hostId`)
- `gameDate` is stored separately from `startAt`/`endAt` to keep date filtering index-friendly
- `availableSpots` is persisted so availability queries do not require counting approved rows on every request
- `approvalMode` supports both one-tap auto-join and manual host approval

### `JoinRequest`
- represents the player-to-game relationship
- `APPROVED` means the player has a reserved slot
- `PENDING` is used only for manual approval mode and does not consume a spot until approval
- one user can only have one request per game in the MVP via `@@unique([gameId, userId])`

## MVP REST API

### Authentication

| Method | URL | Request Body | Response |
| --- | --- | --- | --- |
| `POST` | `/api/v1/auth/register` | `{ "email?": "a@b.com", "phoneNumber?": "0912345678", "password": "Secret123!", "nickname": "Kevin", "skillLevel": "L3" }` | `201 Created` with `{ "user": {...}, "token": "jwt" }` |
| `POST` | `/api/v1/auth/login` | `{ "emailOrPhone": "a@b.com", "password": "Secret123!" }` | `200 OK` with `{ "user": {...}, "token": "jwt" }` |
| `GET` | `/api/v1/auth/me` | none | `200 OK` with current user profile |

### Profile

| Method | URL | Request Body | Response |
| --- | --- | --- | --- |
| `PATCH` | `/api/v1/users/me` | `{ "nickname?": "Kevin", "avatarUrl?": "https://...", "gender?": "MALE", "skillLevel?": "L4", "preferredCity?": "Taipei City", "preferredDistrict?": "Da'an" }` | `200 OK` with updated user |

### Games

| Method | URL | Request Body | Response |
| --- | --- | --- | --- |
| `GET` | `/api/v1/games?city=Taipei%20City&district=Da'an&date=2026-03-25&status=OPEN&skillLevel=L3&feeMin=0&feeMax=300&vacancyOnly=true` | none | `200 OK` with paginated game summaries |
| `GET` | `/api/v1/games/:gameId` | none | `200 OK` with full game detail, host summary, join summary |
| `POST` | `/api/v1/games` | `{ "title": "Wednesday Doubles", "city": "Taipei City", "district": "Da'an", "venueName": "NTU Sports Center", "venueAddress": "No. 1, Sec. 4, Roosevelt Rd.", "gameDate": "2026-03-25", "startAt": "2026-03-25T19:00:00+08:00", "endAt": "2026-03-25T21:00:00+08:00", "skillLevelMin": "L2", "skillLevelMax": "L4", "fee": 200, "capacity": 8, "courtCount": 2, "shuttleType": "FEATHER", "approvalMode": "AUTO", "notes": "Bring indoor shoes." }` | `201 Created` with created game; server sets `availableSpots = capacity` |
| `PATCH` | `/api/v1/games/:gameId` | editable game fields before start | `200 OK` with updated game |
| `PATCH` | `/api/v1/games/:gameId/status` | `{ "status": "CANCELLED" }` | `200 OK` with updated game status |

### Join / Request-to-Join

| Method | URL | Request Body | Response |
| --- | --- | --- | --- |
| `POST` | `/api/v1/games/:gameId/join` | `{ "message?": "I am L3 and can bring shuttles." }` | `201 Created` with `{ "joinRequest": {...}, "game": { "id": "...", "availableSpots": 3, "status": "OPEN" } }`; for `AUTO` mode request becomes `APPROVED`, for `MANUAL` mode request becomes `PENDING` |
| `GET` | `/api/v1/games/:gameId/join-requests` | none | `200 OK` with host-facing request list |
| `PATCH` | `/api/v1/join-requests/:joinRequestId/approve` | none | `200 OK` with approved request and updated `availableSpots`; must use the same atomic decrement pattern as auto-join |
| `PATCH` | `/api/v1/join-requests/:joinRequestId/reject` | `{ "reason?": "Skill level mismatch" }` | `200 OK` with rejected request |
| `PATCH` | `/api/v1/join-requests/:joinRequestId/withdraw` | none | `200 OK` with withdrawn request; if current status is `APPROVED`, increment `availableSpots` inside a transaction |

### My Games

| Method | URL | Request Body | Response |
| --- | --- | --- | --- |
| `GET` | `/api/v1/me/games/joined` | none | `200 OK` with current user's approved/upcoming games |
| `GET` | `/api/v1/me/games/created` | none | `200 OK` with games hosted by current user |

## Validation Approach

Recommended stack: `zod` or `express-validator` at the request boundary, plus Prisma/database constraints for data integrity.

Key rules:
- `endAt` must be strictly later than `startAt`
- `gameDate` must match the local calendar date of `startAt`
- `fee`, `capacity`, `courtCount`, and `availableSpots` must be positive integers; `availableSpots` should only be set by server logic
- `skillLevelMax`, when provided, must not be lower than `skillLevelMin`
- `city`, `district`, `venueName`, and `nickname` should be trimmed and length-limited
- at least one of `email` or `phoneNumber` must be present for registration
- `message` on join requests should have a safe max length, such as 300 characters

Database-side guardrails:
- unique constraints on `email`, `phoneNumber`, and `(gameId, userId)`
- join flow decrements capacity only through transactional code
- status transitions should be whitelisted in service/controller logic
