import {
  Timestamp,
  type DocumentSnapshot,
  type Query,
  type QueryDocumentSnapshot,
  type UpdateData,
} from 'firebase-admin/firestore';
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
import { buildSearchTokens, planSearch, titleMatches } from '../utils/search.js';
import { assertCategoryExists, getSubtreeIds } from './category.service.js';

/** Çok kelimeli aramada bir sayfayı doldurmak için en fazla kaç parti okunacağı (maliyet sınırı). */
const MAX_SEARCH_SCAN_ROUNDS = 5;

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

  // Başlık araması: en seçici kelime Firestore'da, diğerleri aşağıda bellekte elenir.
  const search = q.q ? planSearch(q.q) : null;
  if (search) query = query.where('searchTokens', 'array-contains', search.token);

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

  if (search) {
    const { docs, nextCursor } = await scanFiltered(query, q.limit, (t) => titleMatches(t.title, search.words));
    return { items: docs.map((d) => toTaskDto(d.id, d.data())), nextCursor };
  }

  // Bir fazla okuyarak sonraki sayfanın varlığını anlarız.
  const snap = await query.limit(q.limit + 1).get();
  const docs = snap.docs.slice(0, q.limit);
  return {
    items: docs.map((d) => toTaskDto(d.id, d.data())),
    nextCursor: snap.docs.length > q.limit ? docs[docs.length - 1].id : null,
  };
}

/**
 * Sorguyu partiler halinde okuyup `accept`'ten geçenleri `limit`e kadar toplar.
 * Cursor, *taranan* son belgedir (döndürülen son belge değil) — böylece elenen belgeler
 * sonraki sayfada yeniden taranmaz. Bu yüzden bir sayfa `limit`ten az, hatta boş olabilir
 * ama `nextCursor` doluysa devam vardır.
 */
async function scanFiltered(
  base: Query<TaskDoc>,
  limit: number,
  accept: (task: TaskDoc) => boolean,
): Promise<{ docs: QueryDocumentSnapshot<TaskDoc>[]; nextCursor: string | null }> {
  const matched: QueryDocumentSnapshot<TaskDoc>[] = [];
  let last: DocumentSnapshot<TaskDoc> | undefined;

  for (let round = 0; round < MAX_SEARCH_SCAN_ROUNDS; round++) {
    const snap = await (last ? base.startAfter(last) : base).limit(limit).get();
    for (const doc of snap.docs) {
      last = doc;
      if (!accept(doc.data())) continue;
      matched.push(doc);
      if (matched.length === limit) return { docs: matched, nextCursor: doc.id };
    }
    if (snap.size < limit) return { docs: matched, nextCursor: null }; // sonuçlar tükendi
  }
  return { docs: matched, nextCursor: last?.id ?? null };
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
    searchTokens: buildSearchTokens(input.title),
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
  // Başlık değişince token'lar yeniden üretilir; migration öncesinden kalan (token'sız) görevler
  // de ilk düzenlemede tamamlanır.
  if (input.title !== undefined || !Array.isArray(current.searchTokens)) {
    patch.searchTokens = buildSearchTokens(input.title ?? current.title);
  }

  await tasksCol.doc(id).update(patch as UpdateData<TaskDoc>);
  return toTaskDto(id, { ...current, ...patch });
}

export async function deleteTask(uid: string, id: string): Promise<void> {
  await getOwned(uid, id);
  await tasksCol.doc(id).delete();
}
