import type { ResponseConfig } from '@asteasolutions/zod-to-openapi';
import type { ZodType } from 'zod';
import { ErrorResponseSchema } from '../../schemas/common.schema.js';

type SchemaOrRef = ZodType | { $ref: string };

export const API_PREFIX = '/v1';

export const json = (schema: SchemaOrRef) => ({ 'application/json': { schema } });

export const ok = (schema: SchemaOrRef, description = 'Başarılı'): ResponseConfig => ({
  description,
  content: json(schema),
});

const ERROR_DESCRIPTIONS = {
  400: 'Geçersiz istek / doğrulama hatası',
  401: 'Token eksik veya geçersiz',
  404: 'Kaynak bulunamadı',
  409: 'Çakışma',
} as const;

/** Her korumalı endpoint 401 dönebilir; ek hata kodları parametre olarak verilir. */
export const errors = (...codes: Array<keyof typeof ERROR_DESCRIPTIONS>): Record<string, ResponseConfig> =>
  Object.fromEntries(
    [401 as const, ...codes].map((code) => [
      code,
      { description: ERROR_DESCRIPTIONS[code], content: json(ErrorResponseSchema) },
    ]),
  );
