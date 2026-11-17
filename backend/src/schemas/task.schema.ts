import { z } from '../config/zod.js';
import { registry } from '../docs/registry.js';
import { TASK_STATUSES, type TaskDto } from '../models/index.js';
import type { Assert, Equals } from '../utils/type-assert.js';
import { docId, isoDateTime, NON_EMPTY_MESSAGE, nonEmpty } from './common.schema.js';

const taskStatus = () => z.enum(TASK_STATUSES).openapi({ example: 'todo' });
const title = () => z.string().trim().min(1).max(200).openapi({ example: 'Sprint planlamasını hazırla' });
const description = () => z.string().max(5000);
const dueDate = () => isoDateTime().nullable().openapi({ example: '2026-12-01T09:00:00+03:00' });

export const TaskSchema = registry.register(
  'Task',
  z.object({
    id: z.string(),
    categoryId: z.string().nullable(),
    title: z.string(),
    description: z.string(),
    status: z.enum(TASK_STATUSES),
    dueDate: z.iso.datetime().nullable(),
    completedAt: z.iso.datetime().nullable(),
    createdAt: z.iso.datetime(),
    updatedAt: z.iso.datetime(),
  }),
);
export type _TaskDtoMatches = Assert<Equals<z.infer<typeof TaskSchema>, TaskDto>>;

export const CreateTaskSchema = registry.register(
  'CreateTaskRequest',
  z.strictObject({
    title: title(),
    description: description().default(''),
    status: taskStatus().default('todo'),
    dueDate: dueDate().default(null),
    categoryId: docId().nullable().default(null),
  }),
);
export type CreateTaskInput = z.infer<typeof CreateTaskSchema>;

export const UpdateTaskSchema = registry.register(
  'UpdateTaskRequest',
  z
    .strictObject({
      title: title().optional(),
      description: description().optional(),
      status: taskStatus().optional(),
      dueDate: dueDate().optional(),
      categoryId: docId().nullable().optional(),
    })
    .refine(nonEmpty, NON_EMPTY_MESSAGE),
);
export type UpdateTaskInput = z.infer<typeof UpdateTaskSchema>;

/** `categoryId=none` → kategorisiz görevler. */
export const UNCATEGORIZED = 'none';

export const ListTasksQuerySchema = z
  .object({
    status: taskStatus().optional(),
    categoryId: docId().optional().openapi({ description: "Kategori ID'si veya kategorisizler için `none`" }),
    includeSubcategories: z
      .stringbool()
      .default(false)
      .openapi({ description: 'true ise alt kategorilerdeki görevler de dahil edilir' }),
    dueFrom: isoDateTime().optional(),
    dueTo: isoDateTime().optional(),
    sort: z
      .enum(['createdAt', 'dueDate'])
      .default('createdAt')
      .openapi({ description: '`createdAt`: yeniden eskiye. `dueDate`: yakından uzağa. dueFrom/dueTo verilirse dueDate kullanılır.' }),
    limit: z.coerce.number().int().min(1).max(100).default(50),
    cursor: docId().optional().openapi({ description: 'Önceki yanıttaki `nextCursor`' }),
  })
  .refine((q) => !(q.includeSubcategories && (!q.categoryId || q.categoryId === UNCATEGORIZED)), {
    message: 'includeSubcategories requires a concrete categoryId',
    path: ['includeSubcategories'],
  })
  .refine((q) => !(q.dueFrom && q.dueTo && Date.parse(q.dueFrom) > Date.parse(q.dueTo)), {
    message: 'dueFrom must be before dueTo',
    path: ['dueFrom'],
  });
export type ListTasksQuery = z.infer<typeof ListTasksQuerySchema>;

export const TaskListResponseSchema = registry.register(
  'TaskListResponse',
  z.object({
    items: z.array(TaskSchema),
    nextCursor: z.string().nullable(),
  }),
);
