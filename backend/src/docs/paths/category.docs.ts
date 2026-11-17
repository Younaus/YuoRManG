import { z } from '../../config/zod.js';
import {
  CategorySchema,
  categoryTreeNodeRef,
  CategoryTreeQuerySchema,
  CreateCategorySchema,
  DeleteCategoryQuerySchema,
  DeleteCategoryResultSchema,
  UpdateCategorySchema,
} from '../../schemas/category.schema.js';
import { IdParamsSchema } from '../../schemas/common.schema.js';
import { registry } from '../registry.js';
import { API_PREFIX, errors, json, ok } from './helpers.js';

const tags = ['Categories'];
const base = `${API_PREFIX}/categories`;

registry.registerPath({
  method: 'get',
  path: base,
  tags,
  summary: 'Kategorileri düz liste olarak getir',
  description: 'Sıralama: `order`, ardından `name`. Her kayıt `parentId` içerir (Adjacency List).',
  responses: { 200: ok(z.object({ items: z.array(CategorySchema) })), ...errors() },
});

registry.registerPath({
  method: 'get',
  path: `${base}/tree`,
  tags,
  summary: 'Kategorileri hiyerarşik ağaç olarak getir',
  description: 'Sınırsız derinlik. `rootId` verilirse yalnızca o kategorinin alt ağacı döner.',
  request: { query: CategoryTreeQuerySchema },
  responses: {
    200: ok({ type: 'object', required: ['items'], properties: { items: { type: 'array', items: categoryTreeNodeRef } } } as never),
    ...errors(404),
  },
});

registry.registerPath({
  method: 'post',
  path: base,
  tags,
  summary: 'Kategori oluştur',
  description: '`parentId` verilirse alt kategori olarak oluşturulur. Aynı seviyede isim benzersiz olmalıdır.',
  request: { body: { required: true, content: json(CreateCategorySchema) } },
  responses: { 201: ok(CategorySchema, 'Oluşturuldu'), ...errors(400, 409) },
});

registry.registerPath({
  method: 'get',
  path: `${base}/{id}`,
  tags,
  summary: 'Kategori detayı',
  request: { params: IdParamsSchema },
  responses: { 200: ok(CategorySchema), ...errors(404) },
});

registry.registerPath({
  method: 'patch',
  path: `${base}/{id}`,
  tags,
  summary: 'Kategori güncelle / taşı',
  description: '`parentId` değiştirilerek kategori taşınır. Kendi alt kategorisinin altına taşıma (döngü) reddedilir.',
  request: { params: IdParamsSchema, body: { required: true, content: json(UpdateCategorySchema) } },
  responses: { 200: ok(CategorySchema), ...errors(400, 404, 409) },
});

registry.registerPath({
  method: 'delete',
  path: `${base}/{id}`,
  tags,
  summary: 'Kategori sil',
  request: { params: IdParamsSchema, query: DeleteCategoryQuerySchema },
  responses: { 200: ok(DeleteCategoryResultSchema), ...errors(404) },
});
