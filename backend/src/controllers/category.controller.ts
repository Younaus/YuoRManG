import type { Request, Response } from 'express';
import { requireUser } from '../middlewares/auth.middleware.js';
import type { CategoryDto, CategoryTreeNode, ListResult } from '../models/index.js';
import type {
  CategoryTreeQuery,
  CreateCategoryInput,
  DeleteCategoryQuery,
  DeleteCategoryResult,
  UpdateCategoryInput,
} from '../schemas/category.schema.js';
import type { IdParams } from '../schemas/common.schema.js';
import * as categoryService from '../services/category.service.js';

export async function list(req: Request, res: Response<ListResult<CategoryDto>>) {
  const { uid } = requireUser(req);
  res.json({ items: await categoryService.listCategories(uid) });
}

export async function tree(
  req: Request<object, ListResult<CategoryTreeNode>, unknown, CategoryTreeQuery>,
  res: Response<ListResult<CategoryTreeNode>>,
) {
  const { uid } = requireUser(req);
  res.json({ items: await categoryService.getCategoryTree(uid, req.query.rootId) });
}

export async function getById(req: Request<IdParams>, res: Response<CategoryDto>) {
  const { uid } = requireUser(req);
  res.json(await categoryService.getCategory(uid, req.params.id));
}

export async function create(req: Request<object, CategoryDto, CreateCategoryInput>, res: Response<CategoryDto>) {
  const { uid } = requireUser(req);
  res.status(201).json(await categoryService.createCategory(uid, req.body));
}

export async function update(req: Request<IdParams, CategoryDto, UpdateCategoryInput>, res: Response<CategoryDto>) {
  const { uid } = requireUser(req);
  res.json(await categoryService.updateCategory(uid, req.params.id, req.body));
}

export async function remove(
  req: Request<IdParams, DeleteCategoryResult, unknown, DeleteCategoryQuery>,
  res: Response<DeleteCategoryResult>,
) {
  const { uid } = requireUser(req);
  res.json(await categoryService.deleteCategory(uid, req.params.id, req.query.strategy));
}
