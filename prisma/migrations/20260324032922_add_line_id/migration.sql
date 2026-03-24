-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MALE', 'FEMALE', 'OTHER', 'UNDISCLOSED');

-- CreateEnum
CREATE TYPE "SkillLevel" AS ENUM ('L1', 'L2', 'L3', 'L4', 'L5');

-- CreateEnum
CREATE TYPE "GameStatus" AS ENUM ('OPEN', 'FULL', 'CANCELLED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "ApprovalMode" AS ENUM ('AUTO', 'MANUAL');

-- CreateEnum
CREATE TYPE "JoinRequestStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ShuttleType" AS ENUM ('FEATHER', 'NYLON', 'MIXED');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "email" VARCHAR(255),
    "phoneNumber" VARCHAR(32),
    "passwordHash" VARCHAR(255),
    "nickname" VARCHAR(50) NOT NULL,
    "avatarUrl" VARCHAR(500),
    "gender" "Gender",
    "skillLevel" "SkillLevel" NOT NULL,
    "lineId" VARCHAR(50),
    "preferredCity" VARCHAR(50),
    "preferredDistrict" VARCHAR(50),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Game" (
    "id" UUID NOT NULL,
    "hostId" UUID NOT NULL,
    "title" VARCHAR(120) NOT NULL,
    "city" VARCHAR(50) NOT NULL,
    "district" VARCHAR(50) NOT NULL,
    "venueName" VARCHAR(120) NOT NULL,
    "venueAddress" VARCHAR(255) NOT NULL,
    "gameDate" DATE NOT NULL,
    "startAt" TIMESTAMP(3) NOT NULL,
    "endAt" TIMESTAMP(3) NOT NULL,
    "skillLevelMin" "SkillLevel" NOT NULL,
    "skillLevelMax" "SkillLevel",
    "fee" INTEGER NOT NULL,
    "capacity" INTEGER NOT NULL,
    "availableSpots" INTEGER NOT NULL,
    "courtCount" INTEGER NOT NULL,
    "shuttleType" "ShuttleType",
    "notes" TEXT,
    "approvalMode" "ApprovalMode" NOT NULL DEFAULT 'AUTO',
    "status" "GameStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Game_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JoinRequest" (
    "id" UUID NOT NULL,
    "gameId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "status" "JoinRequestStatus" NOT NULL DEFAULT 'PENDING',
    "message" VARCHAR(300),
    "respondedAt" TIMESTAMP(3),
    "approvedAt" TIMESTAMP(3),
    "rejectedReason" VARCHAR(300),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "JoinRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phoneNumber_key" ON "User"("phoneNumber");

-- CreateIndex
CREATE INDEX "idx_users_skill_level" ON "User"("skillLevel");

-- CreateIndex
CREATE INDEX "idx_users_preferred_area" ON "User"("preferredCity", "preferredDistrict");

-- CreateIndex
CREATE INDEX "idx_games_city_district_date_status" ON "Game"("city", "district", "gameDate", "status");

-- CreateIndex
CREATE INDEX "idx_games_district_date" ON "Game"("district", "gameDate");

-- CreateIndex
CREATE INDEX "idx_games_game_date" ON "Game"("gameDate");

-- CreateIndex
CREATE INDEX "idx_games_status_date" ON "Game"("status", "gameDate");

-- CreateIndex
CREATE INDEX "idx_games_host_date" ON "Game"("hostId", "gameDate");

-- CreateIndex
CREATE INDEX "idx_join_requests_game_status" ON "JoinRequest"("gameId", "status");

-- CreateIndex
CREATE INDEX "idx_join_requests_user_status" ON "JoinRequest"("userId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "uniq_join_requests_game_user" ON "JoinRequest"("gameId", "userId");

-- AddForeignKey
ALTER TABLE "Game" ADD CONSTRAINT "Game_hostId_fkey" FOREIGN KEY ("hostId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JoinRequest" ADD CONSTRAINT "JoinRequest_gameId_fkey" FOREIGN KEY ("gameId") REFERENCES "Game"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JoinRequest" ADD CONSTRAINT "JoinRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
