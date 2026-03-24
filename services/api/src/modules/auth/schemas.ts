import { z } from 'zod';

export const registerBodySchema = z
  .object({
    email: z.string().trim().email().optional(),
    phoneNumber: z.string().trim().min(8).max(32).optional(),
    password: z.string().min(8).max(72),
    nickname: z.string().trim().min(1).max(50),
    skillLevel: z.enum(['L1', 'L2', 'L3', 'L4', 'L5']),
  })
  .refine((data) => Boolean(data.email || data.phoneNumber), {
    message: 'Either email or phoneNumber is required.',
    path: [],
  });

export const loginBodySchema = z.object({
  emailOrPhone: z.string().trim().min(1).max(255),
  password: z.string().min(8).max(72),
});

export const patchMeBodySchema = z.object({
  nickname: z.string().trim().min(1).max(50).optional(),
  avatarUrl: z.string().url().max(500).optional(),
  gender: z.enum(['MALE', 'FEMALE', 'OTHER', 'UNDISCLOSED']).optional(),
  skillLevel: z.enum(['L1', 'L2', 'L3', 'L4', 'L5']).optional(),
  preferredCity: z.string().trim().min(1).max(50).optional(),
  preferredDistrict: z.string().trim().min(1).max(50).optional(),
  lineId: z.string().trim().max(50).nullable().optional(),
});

export type RegisterBody = z.infer<typeof registerBodySchema>;
export type LoginBody = z.infer<typeof loginBodySchema>;
export type PatchMeBody = z.infer<typeof patchMeBodySchema>;
