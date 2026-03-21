import {
  ApprovalMode,
  GameStatus,
  JoinRequestStatus,
  PrismaClient,
  ShuttleType,
  SkillLevel,
} from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  const users = await seedUsers();
  await clearSeedGames();
  await seedGames(users);
}

async function seedUsers(): Promise<{
  hostKevin: { id: string };
  playerMina: { id: string };
  playerSean: { id: string };
}> {
  const hostKevin = await prisma.user.upsert({
    where: { email: 'kevin.seed@example.com' },
    update: {
      nickname: 'Kevin Seed',
      skillLevel: SkillLevel.L3,
      preferredCity: 'Taipei City',
      preferredDistrict: "Da'an",
    },
    create: {
      email: 'kevin.seed@example.com',
      passwordHash: 'seed-password-hash',
      nickname: 'Kevin Seed',
      skillLevel: SkillLevel.L3,
      preferredCity: 'Taipei City',
      preferredDistrict: "Da'an",
    },
    select: { id: true },
  });

  const playerMina = await prisma.user.upsert({
    where: { email: 'mina.seed@example.com' },
    update: {
      nickname: 'Mina Seed',
      skillLevel: SkillLevel.L2,
      preferredCity: 'Taipei City',
      preferredDistrict: 'Xinyi',
    },
    create: {
      email: 'mina.seed@example.com',
      passwordHash: 'seed-password-hash',
      nickname: 'Mina Seed',
      skillLevel: SkillLevel.L2,
      preferredCity: 'Taipei City',
      preferredDistrict: 'Xinyi',
    },
    select: { id: true },
  });

  const playerSean = await prisma.user.upsert({
    where: { email: 'sean.seed@example.com' },
    update: {
      nickname: 'Sean Seed',
      skillLevel: SkillLevel.L4,
      preferredCity: 'New Taipei City',
      preferredDistrict: 'Banqiao',
    },
    create: {
      email: 'sean.seed@example.com',
      passwordHash: 'seed-password-hash',
      nickname: 'Sean Seed',
      skillLevel: SkillLevel.L4,
      preferredCity: 'New Taipei City',
      preferredDistrict: 'Banqiao',
    },
    select: { id: true },
  });

  return {
    hostKevin,
    playerMina,
    playerSean,
  };
}

async function clearSeedGames(): Promise<void> {
  await prisma.game.deleteMany({
    where: {
      title: {
        startsWith: 'Seed:',
      },
    },
  });
}

async function seedGames(users: {
  hostKevin: { id: string };
  playerMina: { id: string };
  playerSean: { id: string };
}): Promise<void> {
  const taipeiDoubles = await prisma.game.create({
    data: {
      hostId: users.hostKevin.id,
      title: 'Seed: Taipei Wednesday Doubles',
      city: 'Taipei City',
      district: "Da'an",
      venueName: 'NTU Sports Center',
      venueAddress: 'No. 1, Sec. 4, Roosevelt Rd.',
      gameDate: new Date('2026-03-25T00:00:00.000Z'),
      startAt: new Date('2026-03-25T11:00:00.000Z'),
      endAt: new Date('2026-03-25T13:00:00.000Z'),
      skillLevelMin: SkillLevel.L2,
      skillLevelMax: SkillLevel.L4,
      fee: 200,
      capacity: 8,
      availableSpots: 5,
      courtCount: 2,
      shuttleType: ShuttleType.FEATHER,
      approvalMode: ApprovalMode.AUTO,
      status: GameStatus.OPEN,
      notes: 'Bring indoor shoes. Seed data for discovery/detail.',
      joinRequests: {
        create: [
          {
            userId: users.playerMina.id,
            status: JoinRequestStatus.APPROVED,
            message: 'Can bring shuttles.',
            approvedAt: new Date('2026-03-20T12:00:00.000Z'),
            respondedAt: new Date('2026-03-20T12:00:00.000Z'),
          },
          {
            userId: users.playerSean.id,
            status: JoinRequestStatus.APPROVED,
            message: 'L4 doubles player.',
            approvedAt: new Date('2026-03-20T13:00:00.000Z'),
            respondedAt: new Date('2026-03-20T13:00:00.000Z'),
          },
        ],
      },
    },
    select: { id: true },
  });

  await prisma.game.create({
    data: {
      hostId: users.playerSean.id,
      title: 'Seed: Xinyi Friday Intermediate',
      city: 'Taipei City',
      district: 'Xinyi',
      venueName: 'Taipei Xinyi Sports Center',
      venueAddress: 'Songqin St. 100',
      gameDate: new Date('2026-03-27T00:00:00.000Z'),
      startAt: new Date('2026-03-27T11:30:00.000Z'),
      endAt: new Date('2026-03-27T13:30:00.000Z'),
      skillLevelMin: SkillLevel.L3,
      skillLevelMax: SkillLevel.L4,
      fee: 250,
      capacity: 10,
      availableSpots: 7,
      courtCount: 2,
      shuttleType: ShuttleType.MIXED,
      approvalMode: ApprovalMode.MANUAL,
      status: GameStatus.OPEN,
      notes: 'Manual approval example with one pending request.',
      joinRequests: {
        create: [
          {
            userId: users.hostKevin.id,
            status: JoinRequestStatus.PENDING,
            message: 'Can fill in as needed.',
          },
        ],
      },
    },
  });

  await prisma.game.create({
    data: {
      hostId: users.playerMina.id,
      title: 'Seed: Banqiao Morning Rally',
      city: 'New Taipei City',
      district: 'Banqiao',
      venueName: 'Banqiao Civil Sports Center',
      venueAddress: 'Zhongshan Rd. 1',
      gameDate: new Date('2026-03-29T00:00:00.000Z'),
      startAt: new Date('2026-03-29T02:00:00.000Z'),
      endAt: new Date('2026-03-29T04:00:00.000Z'),
      skillLevelMin: SkillLevel.L1,
      skillLevelMax: SkillLevel.L3,
      fee: 150,
      capacity: 6,
      availableSpots: 0,
      courtCount: 1,
      shuttleType: ShuttleType.NYLON,
      approvalMode: ApprovalMode.AUTO,
      status: GameStatus.FULL,
      notes: 'Full game example for status and vacancy filters.',
    },
  });

  console.log(`Seeded games including ${taipeiDoubles.id}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
