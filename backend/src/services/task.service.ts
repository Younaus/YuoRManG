import { Timestamp, type Query, type UpdateData } from 'firebase-admin/firestore';
import type { PaginatedResult, TaskDoc, TaskDto } from '../models/index.js';
import {
  UNCATEGORIZED,
  type CreateTaskInput,
  type ListTasksQuery,
  type UpdateTaskInput,
} from '../schemas/task.schema.js';
import { AppError } from '../utils/app-error.js';
import { FIRESTORE_IN_LIMIT, fromIso, tasksCol } from '../utils/firestore.js';
import { toTaskDto } from '../utils/mappers.js';
import { assertCategoryExists, getSubtreeIds } from './category.service.js';

async function getOwned(uid: string, id: string): Promise<TaskDoc> {
  const snap = await tasksCol.doc(id).get();
  const data = snap.data();
  if (!data || data.userId !== uid) throw AppError.notFound('Task not found');
  return data;
}

/**
 * Filtrelenmiş, cursor ile sayfalı görev listesi.
 * Gerekli composite index'ler firestore.indexes.json'da tanımlıdır.
 */
export async function listTasks(uid: string, q: ListTasksQuery): Promise<PaginatedResult<TaskDto>> {
  let query: Query<TaskDoc> = tasksCol.where('userId', '==', uid);

  if (q.status) query = query.where('status', '==', q.status);

  if (q.categoryId === UNCATEGORIZED) {
    query = query.where('categoryId', '==', null);
  } else if (q.categoryId && q.includeSubcategories) {
    const ids = await getSubtreeIds(uid, q.categoryId);
    if (ids.length > FIRESTORE_IN_LIMIT) {
      throw AppError.badRequest(
        `includeSubcategories supports at most ${FIRESTORE_IN_LIMIT} categories in a subtree (found ${ids.length})`,
      );
    }
    query = ids.length === 1 ? query.where('categoryId', '==', ids[0]) : query.where('categoryId', 'in', ids);
  } else if (q.categoryId) {
    query = query.where('categoryId', '==', q.categoryId);
  }

  if (q.dueFrom) query = query.where('dueDate', '>=', fromIso(q.dueFrom));
  if (q.dueTo) query = query.where('dueDate', '<=', fromIso(q.dueTo));

  // Not: dueDate sıralamasında tarihsiz (null) görevler en başta gelir; tarih aralığı verilirse hariç kalırlar.
  const sortByDue = q.sort === 'dueDate' || Boolean(q.dueFrom || q.dueTo);
  query = sortByDue ? query.orderBy('dueDate', 'asc') : query.orderBy('createdAt', 'desc');

  if (q.cursor) {
    const cursorSnap = await tasksCol.doc(q.cursor).get();
    if (cursorSnap.data()?.userId !== uid) throw AppError.badRequest('Invalid cursor');
    query = query.startAfter(cursorSnap);
  }

  // Bir fazla okuyarak sonraki sayfanın varlığını anlarız.
  const snap = await query.limit(q.limit + 1).get();
  const docs = snap.docs.slice(0, q.limit);
  return {
    items: docs.map((d) => toTaskDto(d.id, d.data())),
    nextCursor: snap.docs.length > q.limit ? docs[docs.length - 1].id : null,
  };
}

export async function getTask(uid: string, id: string): Promise<TaskDto> {
  return toTaskDto(id, await getOwned(uid, id));
}

export async function createTask(uid: string, input: CreateTaskInput): Promise<TaskDto> {
  if (input.categoryId) await assertCategoryExists(uid, input.categoryId);

  const now = Timestamp.now();
  const doc: TaskDoc = {
    userId: uid,
    categoryId: input.categoryId,
    title: input.title,
    description: input.description,
    status: input.status,
    dueDate: fromIso(input.dueDate),
    completedAt: input.status === 'done' ? now : null,
    createdAt: now,
    updatedAt: now,
  };
  const ref = tasksCol.doc();
  await ref.set(doc);
  return toTaskDto(ref.id, doc);
}

export async function updateTask(uid: string, id: string, input: UpdateTaskInput): Promise<TaskDto> {
  const current = await getOwned(uid, id);
  if (input.categoryId && input.categoryId !== current.categoryId) {
    await assertCategoryExists(uid, input.categoryId);
  }

  const now = Timestamp.now();
  const patch: Partial<TaskDoc> = { updatedAt: now };
  if (input.title !== undefined) patch.title = input.title;
  if (input.description !== undefined) patch.description = input.description;
  if (input.categoryId !== undefined) patch.categoryId = input.categoryId;
  if (input.dueDate !== undefined) patch.dueDate = fromIso(input.dueDate);
  if (input.status !== undefined && input.status !== current.status) {
    patch.status = input.status;
    // 'done'a geçişte tamamlanma zamanı set edilir, 'done'dan çıkışta temizlenir.
    patch.completedAt = input.status === 'done' ? now : null;
  }

  await tasksCol.doc(id).update(patch as UpdateData<TaskDoc>);
  return toTaskDto(id, { ...current, ...patch });
}

export async function deleteTask(uid: string, id: string): Promise<void> {
  await getOwned(uid, id);
  await tasksCol.doc(id).delete();
}
