import { Timestamp, type UpdateData, type WriteBatch } from 'firebase-admin/firestore';
import type { CategoryDoc, CategoryDto, CategoryTreeNode, WithId } from '../models/index.js';
import type {
  CreateCategoryInput,
  DeleteCategoryResult,
  DeleteStrategy,
  UpdateCategoryInput,
} from '../schemas/category.schema.js';
import { AppError } from '../utils/app-error.js';
import { categoriesCol, chunk, commitInChunks, FIRESTORE_IN_LIMIT, tasksCol } from '../utils/firestore.js';
import { toCategoryDto } from '../utils/mappers.js';

type Category = WithId<CategoryDoc>;

// ---------------------------------------------------------------------------
// Yardımcılar (saf fonksiyonlar)
// ---------------------------------------------------------------------------

const bySiblingOrder = (a: Pick<Category, 'order' | 'name'>, b: Pick<Category, 'order' | 'name'>) =>
  a.order - b.order || a.name.localeCompare(b.name, 'tr');

/**
 * Düz listeyi ağaca çevirir — O(n). Ebeveyni bulunamayan (yetim) kategoriler kök kabul edilir.
 * Girdi sıralı olmalıdır; Map ekleme sırasını koruduğu için çocuklar da sıralı eklenir.
 */
export function buildTree(sorted: CategoryDto[]): { roots: CategoryTreeNode[]; nodes: Map<string, CategoryTreeNode> } {
  const nodes = new Map<string, CategoryTreeNode>(sorted.map((c) => [c.id, { ...c, children: [] }]));
  const roots: CategoryTreeNode[] = [];
  for (const node of nodes.values()) {
    const parent = node.parentId ? nodes.get(node.parentId) : undefined;
    if (parent) parent.children.push(node);
    else roots.push(node);
  }
  return { roots, nodes };
}

/** `rootId` ve tüm alt kategorilerinin ID'leri (BFS, kök dahil). */
function collectSubtreeIds(all: Category[], rootId: string): string[] {
  const childrenOf = new Map<string, string[]>();
  for (const c of all) {
    if (!c.parentId) continue;
    const list = childrenOf.get(c.parentId) ?? [];
    list.push(c.id);
    childrenOf.set(c.parentId, list);
  }
  const result: string[] = [];
  const seen = new Set<string>();
  const queue = [rootId];
  while (queue.length) {
    const id = queue.shift()!;
    if (seen.has(id)) continue; // bozuk veride sonsuz döngüye karşı koruma
    seen.add(id);
    result.push(id);
    queue.push(...(childrenOf.get(id) ?? []));
  }
  return result;
}

/** `candidateParentId`'den köke yürür; yolda `categoryId` varsa taşıma döngü oluşturur. */
function wouldCreateCycle(byId: Map<string, Category>, categoryId: string, candidateParentId: string): boolean {
  const seen = new Set<string>();
  let cursor: string | null = candidateParentId;
  while (cursor && !seen.has(cursor)) {
    if (cursor === categoryId) return true;
    seen.add(cursor);
    cursor = byId.get(cursor)?.parentId ?? null;
  }
  return false;
}

function assertUniqueSiblingName(all: Category[], parentId: string | null, name: string, excludeId?: string) {
  const normalized = name.toLocaleLowerCase('tr');
  const clash = all.find(
    (c) => c.parentId === parentId && c.id !== excludeId && c.name.toLocaleLowerCase('tr') === normalized,
  );
  if (clash) throw AppError.conflict(`A category named "${name}" already exists at this level`, { id: clash.id });
}

function nextSiblingOrder(all: Category[], parentId: string | null): number {
  const orders = all.filter((c) => c.parentId === parentId).map((c) => c.order);
  return orders.length ? Math.max(...orders) + 1 : 0;
}

// ---------------------------------------------------------------------------
// Veri erişimi
// ---------------------------------------------------------------------------

/** Kullanıcının tüm kategorileri — tek sorgu (yalnızca tek alanlı index gerekir). */
async function fetchAll(uid: string): Promise<Category[]> {
  const snap = await categoriesCol.where('userId', '==', uid).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() })).sort(bySiblingOrder);
}

function indexById(all: Category[]): Map<string, Category> {
  return new Map(all.map((c) => [c.id, c]));
}

/** Kategori yoksa veya başka kullanıcıya aitse 404 (varlık bilgisi sızdırılmaz). */
async function getOwned(uid: string, id: string): Promise<Category> {
  const snap = await categoriesCol.doc(id).get();
  const data = snap.data();
  if (!data || data.userId !== uid) throw AppError.notFound('Category not found');
  return { id: snap.id, ...data };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export async function listCategories(uid: string): Promise<CategoryDto[]> {
  return (await fetchAll(uid)).map((c) => toCategoryDto(c.id, c));
}

export async function getCategoryTree(uid: string, rootId?: string): Promise<CategoryTreeNode[]> {
  const { roots, nodes } = buildTree(await listCategories(uid));
  if (!rootId) return roots;
  const node = nodes.get(rootId);
  if (!node) throw AppError.notFound('Category not found');
  return [node];
}

export async function getCategory(uid: string, id: string): Promise<CategoryDto> {
  const c = await getOwned(uid, id);
  return toCategoryDto(c.id, c);
}

/** Görev servisi için: kategori kullanıcıya ait değilse 400 fırlatır. */
export async function assertCategoryExists(uid: string, id: string): Promise<void> {
  const snap = await categoriesCol.doc(id).get();
  if (snap.data()?.userId !== uid) throw AppError.badRequest('Category not found', { categoryId: id });
}

/** Görev filtrelemesi için: kategori + tüm alt kategorilerinin ID'leri. */
export async function getSubtreeIds(uid: string, rootId: string): Promise<string[]> {
  const all = await fetchAll(uid);
  if (!all.some((c) => c.id === rootId)) throw AppError.notFound('Category not found');
  return collectSubtreeIds(all, rootId);
}

export async function createCategory(uid: string, input: CreateCategoryInput): Promise<CategoryDto> {
  const all = await fetchAll(uid);
  if (input.parentId && !all.some((c) => c.id === input.parentId)) {
    throw AppError.badRequest('Parent category not found', { parentId: input.parentId });
  }
  assertUniqueSiblingName(all, input.parentId, input.name);

  const now = Timestamp.now();
  const doc: CategoryDoc = {
    userId: uid,
    name: input.name,
    parentId: input.parentId,
    color: input.color,
    icon: input.icon,
    order: input.order ?? nextSiblingOrder(all, input.parentId),
    createdAt: now,
    updatedAt: now,
  };
  const ref = categoriesCol.doc();
  await ref.set(doc);
  return toCategoryDto(ref.id, doc);
}

export async function updateCategory(uid: string, id: string, input: UpdateCategoryInput): Promise<CategoryDto> {
  const all = await fetchAll(uid);
  const byId = indexById(all);
  const current = byId.get(id);
  if (!current) throw AppError.notFound('Category not found');

  const parentChanged = input.parentId !== undefined && input.parentId !== current.parentId;
  const targetParentId = input.parentId !== undefined ? input.parentId : current.parentId;

  if (parentChanged && targetParentId !== null) {
    if (targetParentId === id) throw AppError.badRequest('A category cannot be its own parent');
    if (!byId.has(targetParentId)) throw AppError.badRequest('Parent category not found', { parentId: targetParentId });
    if (wouldCreateCycle(byId, id, targetParentId)) {
      throw AppError.badRequest('A category cannot be moved under one of its own descendants');
    }
  }

  const targetName = input.name ?? current.name;
  if (parentChanged || input.name !== undefined) assertUniqueSiblingName(all, targetParentId, targetName, id);

  const patch: Partial<CategoryDoc> = { updatedAt: Timestamp.now() };
  if (input.name !== undefined) patch.name = input.name;
  if (input.color !== undefined) patch.color = input.color;
  if (input.icon !== undefined) patch.icon = input.icon;
  if (parentChanged) patch.parentId = targetParentId;
  if (input.order !== undefined) patch.order = input.order;
  else if (parentChanged) patch.order = nextSiblingOrder(all, targetParentId);

  await categoriesCol.doc(id).update(patch as UpdateData<CategoryDoc>);
  return toCategoryDto(id, { ...current, ...patch });
}

/**
 * Kategori silme. Görevler asla silinmez; silinen kategorilere bağlı görevlerin `categoryId`'si null yapılır.
 * Yazma sırası (görevler → taşınan çocuklar → silinen kategoriler), kısmi hata durumunda
 * var olmayan kategoriye referans veren görev kalmamasını sağlar.
 */
export async function deleteCategory(uid: string, id: string, strategy: DeleteStrategy): Promise<DeleteCategoryResult> {
  const all = await fetchAll(uid);
  const current = all.find((c) => c.id === id);
  if (!current) throw AppError.notFound('Category not found');

  const deletedIds = strategy === 'cascade' ? collectSubtreeIds(all, id) : [id];
  const movedChildren = strategy === 'lift' ? all.filter((c) => c.parentId === id) : [];

  const taskSnaps = await Promise.all(
    chunk(deletedIds, FIRESTORE_IN_LIMIT).map((ids) =>
      tasksCol.where('userId', '==', uid).where('categoryId', 'in', ids).get(),
    ),
  );
  const taskRefs = taskSnaps.flatMap((s) => s.docs.map((d) => d.ref));

  const now = Timestamp.now();
  let order = nextSiblingOrder(all, current.parentId);
  await commitInChunks([
    ...taskRefs.map((ref) => (b: WriteBatch) => b.update(ref, { categoryId: null, updatedAt: now })),
    ...movedChildren.map((child) => {
      const childOrder = order++;
      return (b: WriteBatch) =>
        b.update(categoriesCol.doc(child.id), { parentId: current.parentId, order: childOrder, updatedAt: now });
    }),
    ...deletedIds.map((cid) => (b: WriteBatch) => b.delete(categoriesCol.doc(cid))),
  ]);

  return {
    deletedCategoryIds: deletedIds,
    movedCategoryIds: movedChildren.map((c) => c.id),
    detachedTaskCount: taskRefs.length,
  };
}
