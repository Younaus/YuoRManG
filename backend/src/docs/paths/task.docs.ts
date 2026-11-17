import { IdParamsSchema } from '../../schemas/common.schema.js';
import {
  CreateTaskSchema,
  ListTasksQuerySchema,
  TaskListResponseSchema,
  TaskSchema,
  UpdateTaskSchema,
} from '../../schemas/task.schema.js';
import { registry } from '../registry.js';
import { API_PREFIX, errors, json, ok } from './helpers.js';

const tags = ['Tasks'];
const base = `${API_PREFIX}/tasks`;

registry.registerPath({
  method: 'get',
  path: base,
  tags,
  summary: 'Görevleri listele (filtre + sayfalama)',
  description: 'Cursor tabanlı sayfalama: yanıttaki `nextCursor` değerini sonraki istekte `cursor` olarak gönderin.',
  request: { query: ListTasksQuerySchema },
  responses: { 200: ok(TaskListResponseSchema), ...errors(400, 404) },
});

registry.registerPath({
  method: 'post',
  path: base,
  tags,
  summary: 'Görev oluştur',
  request: { body: { required: true, content: json(CreateTaskSchema) } },
  responses: { 201: ok(TaskSchema, 'Oluşturuldu'), ...errors(400) },
});

registry.registerPath({
  method: 'get',
  path: `${base}/{id}`,
  tags,
  summary: 'Görev detayı',
  request: { params: IdParamsSchema },
  responses: { 200: ok(TaskSchema), ...errors(404) },
});

registry.registerPath({
  method: 'patch',
  path: `${base}/{id}`,
  tags,
  summary: 'Görev güncelle',
  description: "`status` 'done' olduğunda `completedAt` otomatik set edilir, 'done'dan çıkınca temizlenir.",
  request: { params: IdParamsSchema, body: { required: true, content: json(UpdateTaskSchema) } },
  responses: { 200: ok(TaskSchema), ...errors(400, 404) },
});

registry.registerPath({
  method: 'delete',
  path: `${base}/{id}`,
  tags,
  summary: 'Görev sil',
  request: { params: IdParamsSchema },
  responses: { 204: { description: 'Silindi' }, ...errors(404) },
});
