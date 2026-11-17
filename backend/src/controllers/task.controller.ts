import type { Request, Response } from 'express';
import { requireUser } from '../middlewares/auth.middleware.js';
import type { PaginatedResult, TaskDto } from '../models/index.js';
import type { IdParams } from '../schemas/common.schema.js';
import type { CreateTaskInput, ListTasksQuery, UpdateTaskInput } from '../schemas/task.schema.js';
import * as taskService from '../services/task.service.js';

export async function list(
  req: Request<object, PaginatedResult<TaskDto>, unknown, ListTasksQuery>,
  res: Response<PaginatedResult<TaskDto>>,
) {
  const { uid } = requireUser(req);
  res.json(await taskService.listTasks(uid, req.query));
}

export async function getById(req: Request<IdParams>, res: Response<TaskDto>) {
  const { uid } = requireUser(req);
  res.json(await taskService.getTask(uid, req.params.id));
}

export async function create(req: Request<object, TaskDto, CreateTaskInput>, res: Response<TaskDto>) {
  const { uid } = requireUser(req);
  res.status(201).json(await taskService.createTask(uid, req.body));
}

export async function update(req: Request<IdParams, TaskDto, UpdateTaskInput>, res: Response<TaskDto>) {
  const { uid } = requireUser(req);
  res.json(await taskService.updateTask(uid, req.params.id, req.body));
}

export async function remove(req: Request<IdParams>, res: Response) {
  const { uid } = requireUser(req);
  await taskService.deleteTask(uid, req.params.id);
  res.status(204).end();
}
