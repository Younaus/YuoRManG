import { Router } from 'express';
import * as ctrl from '../controllers/category.controller.js';
import { validate } from '../middlewares/validate.middleware.js';
import {
  CategoryTreeQuerySchema,
  CreateCategorySchema,
  DeleteCategoryQuerySchema,
  UpdateCategorySchema,
} from '../schemas/category.schema.js';
import { IdParamsSchema } from '../schemas/common.schema.js';

export const categoryRouter = Router();

categoryRouter.get('/', ctrl.list);
// '/tree', '/:id'den önce tanımlanmalı.
categoryRouter.get('/tree', validate({ query: CategoryTreeQuerySchema }), ctrl.tree);
categoryRouter.post('/', validate({ body: CreateCategorySchema }), ctrl.create);
categoryRouter.get('/:id', validate({ params: IdParamsSchema }), ctrl.getById);
categoryRouter.patch('/:id', validate({ params: IdParamsSchema, body: UpdateCategorySchema }), ctrl.update);
categoryRouter.delete('/:id', validate({ params: IdParamsSchema, query: DeleteCategoryQuerySchema }), ctrl.remove);
