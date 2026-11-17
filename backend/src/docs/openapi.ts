import { OpenApiGeneratorV3 } from '@asteasolutions/zod-to-openapi';
import { bearerAuth, registry } from './registry.js';
import './paths/index.js';

export function generateOpenApiDocument() {
  const generator = new OpenApiGeneratorV3(registry.definitions);
  return generator.generateDocument({
    openapi: '3.0.3',
    info: {
      title: 'YouRManG Task Manager API',
      version: '0.2.0',
      description: "Görev ve hiyerarşik kategori yönetimi API'si. Tüm `/v1` endpoint'leri Firebase ID token ister.",
    },
    security: [{ [bearerAuth.name]: [] }],
  });
}
