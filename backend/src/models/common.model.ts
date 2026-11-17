import type { Timestamp } from 'firebase-admin/firestore';

/** Firestore koleksiyon adları — tek kaynak. */
export const COLLECTIONS = {
  users: 'users',
  categories: 'categories',
  tasks: 'tasks',
} as const;

export type CollectionName = (typeof COLLECTIONS)[keyof typeof COLLECTIONS];

/** Her Firestore dokümanında bulunan zaman damgaları. */
export interface BaseDoc {
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/** Doküman verisi + Firestore doküman ID'si. */
export type WithId<T> = T & { id: string };

/** Düz liste yanıtı. */
export interface ListResult<T> {
  items: T[];
}

/** Cursor tabanlı sayfalı liste yanıtı. */
export interface PaginatedResult<T> extends ListResult<T> {
  /** Sonraki sayfa için `cursor` değeri; son sayfada `null`. */
  nextCursor: string | null;
}
