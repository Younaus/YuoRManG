import { z } from '../config/zod.js';
import { registry } from '../docs/registry.js';
import type { UserDto } from '../models/index.js';
import type { Assert, Equals } from '../utils/type-assert.js';
import { NON_EMPTY_MESSAGE, nonEmpty } from './common.schema.js';

export const UserSettingsSchema = z.object({
  theme: z.enum(['system', 'light', 'dark']),
  locale: z.string().min(2).max(20).openapi({ example: 'tr-TR' }),
});

export const UserSchema = registry.register(
  'User',
  z.object({
    id: z.string(),
    email: z.string(),
    displayName: z.string().nullable(),
    photoURL: z.string().nullable(),
    settings: UserSettingsSchema,
    createdAt: z.iso.datetime(),
    updatedAt: z.iso.datetime(),
  }),
);
export type _UserDtoMatches = Assert<Equals<z.infer<typeof UserSchema>, UserDto>>;

export const UpdateMeSchema = registry.register(
  'UpdateMeRequest',
  z
    .strictObject({
      displayName: z.string().trim().min(1).max(100).nullable().optional(),
      settings: UserSettingsSchema.partial().optional(),
    })
    .refine(nonEmpty, NON_EMPTY_MESSAGE),
);
export type UpdateMeInput = z.infer<typeof UpdateMeSchema>;
