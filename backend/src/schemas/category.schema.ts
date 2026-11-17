import { z } from '../config/zod.js';
import { registry } from '../docs/registry.js';
import type { CategoryDto } from '../models/index.js';
import type { Assert, Equals } from '../utils/type-assert.js';
import { docId, NON_EMPTY_MESSAGE, nonEmpty } from './common.schema.js';

const hexColor = () =>
  z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Color must be in #RRGGBB format').openapi({ example: '#4F46E5' });
const categoryName = () => z.string().trim().min(1).max(100).openapi({ example: 'İş' });
const iconKey = () => z.string().trim().min(1).max(50).openapi({ example: 'work' });

export const CategorySchema = registry.register(
  'Category',
  z.object({
    id: z.string(),
    name: z.string(),
    parentId: z.string().nullable().openapi({ description: 'Ebeveyn kategori; null ise kök' }),
    color: z.string().nullable(),
    icon: z.string().nullable(),
    order: z.number().int(),
    createdAt: z.iso.datetime(),
    updatedAt: z.iso.datetime(),
  }),
);
export type _CategoryDtoMatches = Assert<Equals<z.infer<typeof CategorySchema>, CategoryDto>>;

// Özyinelemeli ağaç düğümü — OpenAPI'de $ref ile kendine referans veren component olarak tanımlanır.
export const categoryTreeNodeRef = registry.registerComponent('schemas', 'CategoryTreeNode', {
  allOf: [
    { $ref: '#/components/schemas/Category' },
    {
      type: 'object',
      required: ['children'],
      properties: {
        children: { type: 'array', items: { $ref: '#/components/schemas/CategoryTreeNode' } },
      },
    },
  ],
}).ref;

export const CreateCategorySchema = registry.register(
  'CreateCategoryRequest',
  z.strictObject({
    name: categoryName(),
    parentId: docId().nullable().default(null),
    color: hexColor().nullable().default(null),
    icon: iconKey().nullable().default(null),
    order: z.number().int().min(0).optional().openapi({ description: 'Verilmezse kardeşlerin sonuna eklenir' }),
  }),
);
export type CreateCategoryInput = z.infer<typeof CreateCategorySchema>;

export const UpdateCategorySchema = registry.register(
  'UpdateCategoryRequest',
  z
    .strictObject({
      name: categoryName().optional(),
      parentId: docId().nullable().optional().openapi({ description: 'Taşımak için yeni ebeveyn; null = köke taşı' }),
      color: hexColor().nullable().optional(),
      icon: iconKey().nullable().optional(),
      order: z.number().int().min(0).optional(),
    })
    .refine(nonEmpty, NON_EMPTY_MESSAGE),
);
export type UpdateCategoryInput = z.infer<typeof UpdateCategorySchema>;

export const CategoryTreeQuerySchema = z.object({
  rootId: docId().optional().openapi({ description: 'Verilirse yalnızca bu kategorinin alt ağacı döner' }),
});
export type CategoryTreeQuery = z.infer<typeof CategoryTreeQuerySchema>;

export const DELETE_STRATEGIES = ['cascade', 'lift'] as const;
export type DeleteStrategy = (typeof DELETE_STRATEGIES)[number];

export const DeleteCategoryQuerySchema = z.object({
  strategy: z.enum(DELETE_STRATEGIES).default('cascade').openapi({
    description:
      '`cascade`: kategori ve tüm alt kategorileri silinir. `lift`: yalnızca kategori silinir, alt kategoriler bir üst seviyeye taşınır. Her iki durumda da etkilenen görevler silinmez, `categoryId` alanı null yapılır.',
  }),
});
export type DeleteCategoryQuery = z.infer<typeof DeleteCategoryQuerySchema>;

export const DeleteCategoryResultSchema = registry.register(
  'DeleteCategoryResult',
  z.object({
    deletedCategoryIds: z.array(z.string()),
    movedCategoryIds: z.array(z.string()).openapi({ description: '`lift` ile üst seviyeye taşınan alt kategoriler' }),
    detachedTaskCount: z.number().int().openapi({ description: 'categoryId alanı null yapılan görev sayısı' }),
  }),
);
export type DeleteCategoryResult = z.infer<typeof DeleteCategoryResultSchema>;
