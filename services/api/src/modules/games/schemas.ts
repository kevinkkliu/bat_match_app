import { z } from 'zod';

const skillLevelSchema = z.enum(['L1', 'L2', 'L3', 'L4', 'L5']);

const queryBooleanSchema = z.union([
  z.boolean(),
  z.literal('true'),
  z.literal('false'),
  z.literal('1'),
  z.literal('0'),
]).transform((value) => value === true || value === 'true' || value === '1');

export const gamesQuerySchema = z
  .object({
    city: z.string().trim().max(50).optional(),
    district: z.string().trim().max(50).optional(),
    date: z.string().date().optional(),
    startAtFrom: z.string().datetime({ offset: true }).optional(),
    startAtTo: z.string().datetime({ offset: true }).optional(),
    status: z.enum(['OPEN', 'FULL', 'CANCELLED', 'COMPLETED']).optional(),
    skillLevel: skillLevelSchema.optional(),
    feeMin: z.coerce.number().int().min(0).optional(),
    feeMax: z.coerce.number().int().min(0).optional(),
    vacancyOnly: queryBooleanSchema.optional(),
    page: z.coerce.number().int().min(1).default(1),
    pageSize: z.coerce.number().int().min(1).max(50).default(20),
  })
  .superRefine((data, ctx) => {
    if (typeof data.feeMin === 'number' && typeof data.feeMax === 'number' && data.feeMax < data.feeMin) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['feeMax'],
        message: 'feeMax must be greater than or equal to feeMin.',
      });
    }

    if (data.startAtFrom && data.startAtTo && new Date(data.startAtTo) < new Date(data.startAtFrom)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['startAtTo'],
        message: 'startAtTo must be later than or equal to startAtFrom.',
      });
    }
  });

export const gameIdParamsSchema = z.object({
  gameId: z.string().uuid(),
});

export const createGameBodySchema = z
  .object({
    title: z.string().trim().min(1).max(120),
    city: z.string().trim().min(1).max(50),
    district: z.string().trim().min(1).max(50),
    venueName: z.string().trim().min(1).max(120),
    venueAddress: z.string().trim().min(1).max(255),
    gameDate: z.string().date(),
    startAt: z.string().datetime({ offset: true }),
    endAt: z.string().datetime({ offset: true }),
    skillLevelMin: skillLevelSchema,
    skillLevelMax: skillLevelSchema.optional(),
    fee: z.number().int().min(0),
    capacity: z.number().int().positive(),
    courtCount: z.number().int().positive(),
    shuttleType: z.enum(['FEATHER', 'NYLON', 'MIXED']).optional(),
    approvalMode: z.enum(['AUTO', 'MANUAL']),
    notes: z.string().trim().max(2000).optional(),
  })
  .superRefine((data, ctx) => {
    if (new Date(data.endAt) <= new Date(data.startAt)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['endAt'],
        message: 'endAt must be later than startAt.',
      });
    }

    if (data.skillLevelMax && data.skillLevelMax < data.skillLevelMin) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['skillLevelMax'],
        message: 'skillLevelMax must be greater than or equal to skillLevelMin.',
      });
    }
  });

export const patchGameBodySchema = z
  .object({
    title: z.string().trim().min(1).max(120).optional(),
    city: z.string().trim().min(1).max(50).optional(),
    district: z.string().trim().min(1).max(50).optional(),
    venueName: z.string().trim().min(1).max(120).optional(),
    venueAddress: z.string().trim().min(1).max(255).optional(),
    gameDate: z.string().date().optional(),
    startAt: z.string().datetime({ offset: true }).optional(),
    endAt: z.string().datetime({ offset: true }).optional(),
    skillLevelMin: skillLevelSchema.optional(),
    skillLevelMax: skillLevelSchema.optional(),
    fee: z.number().int().min(0).optional(),
    capacity: z.number().int().positive().optional(),
    courtCount: z.number().int().positive().optional(),
    shuttleType: z.enum(['FEATHER', 'NYLON', 'MIXED']).optional(),
    approvalMode: z.enum(['AUTO', 'MANUAL']).optional(),
    notes: z.string().trim().max(2000).optional(),
  })
  .superRefine((data, ctx) => {
    if (data.startAt && data.endAt && new Date(data.endAt) <= new Date(data.startAt)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['endAt'],
        message: 'endAt must be later than startAt.',
      });
    }

    if (data.skillLevelMin && data.skillLevelMax && data.skillLevelMax < data.skillLevelMin) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['skillLevelMax'],
        message: 'skillLevelMax must be greater than or equal to skillLevelMin.',
      });
    }
  });

export const patchGameStatusBodySchema = z.object({
  status: z.enum(['OPEN', 'FULL', 'CANCELLED', 'COMPLETED']),
});

export type GamesQuery = z.infer<typeof gamesQuerySchema>;
export type CreateGameBody = z.infer<typeof createGameBodySchema>;
export type PatchGameBody = z.infer<typeof patchGameBodySchema>;
export type PatchGameStatusBody = z.infer<typeof patchGameStatusBodySchema>;
