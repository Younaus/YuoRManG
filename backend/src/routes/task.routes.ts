import { Router } from 'express';
import * as ctrl from '../controllers/task.controller.js';
import { validate } from '../middlewares/validate.middleware.js';
import { IdParamsSchema } from '../schemas/common.schema.js';
import { CreateTaskSchema, ListTasksQuerySchema, UpdateTaskSchema } from '../schemas/task.schema.js';

export const taskRouter = Router();

taskRouter.get('/', validate({ query: ListTasksQuerySchema }), ctrl.list);
taskRouter.post('/', validate({ body: CreateTaskSchema }), ctrl.create);
taskRouter.get('/:id', validate({ params: IdParamsSchema }), ctrl.getById);
taskRouter.patch('/:id', validate({ params: IdParamsSchema, body: UpdateTaskSchema }), ctrl.update);
taskRouter.delete('/:id', validate({ params: IdParamsSchema }), ctrl.remove);
