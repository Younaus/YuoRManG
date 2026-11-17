import { z } from '../config/zod.js';
import { registry } from '../docs/registry.js';

/** Firestore doküman ID'si (path parametresi). */
export const docId = () => z.string().trim().min(1).max(128).regex(/^[^/]+$/, 'Invalid id');

export const IdParamsSchema = z.object({
  id: docId().openapi({ param: { name: 'id', in: 'path' }, example: 'Xy12AbC34dEf' }),
});
export type IdParams = z.infer<typeof IdParamsSchema>;

/** Saat dilimi ofsetine izin veren ISO 8601 tarih-saat. */
export const isoDateTime = () => z.iso.datetime({ offset: true });

/** PATCH gövdeleri için: en az bir alan gönderilmeli. */
export const nonEmpty = (obj: object) => Object.values(obj).some((v) => v !== undefined);
export const NON_EMPTY_MESSAGE = 'At least one field must be provided';

export const ErrorResponseSchema = registry.register(
  'ErrorResponse',
  z.object({
    error: z.object({
      code: z.string().openapi({ example: 'VALIDATION_ERROR' }),
      message: z.string(),
      details: z.unknown().optional(),
    }),
  }),
);
