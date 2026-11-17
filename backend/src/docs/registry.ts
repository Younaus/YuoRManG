import { OpenAPIRegistry } from '@asteasolutions/zod-to-openapi';

/** Tüm şema ve endpoint tanımları bu registry'ye kaydedilir. */
export const registry = new OpenAPIRegistry();

export const bearerAuth = registry.registerComponent('securitySchemes', 'bearerAuth', {
  type: 'http',
  scheme: 'bearer',
  bearerFormat: 'JWT',
  description: 'Firebase Auth ID token',
});
