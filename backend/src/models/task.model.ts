import type { Timestamp } from 'firebase-admin/firestore';
import type { BaseDoc } from './common.model.js';

export const TASK_STATUSES = ['todo', 'in_progress', 'done'] as const;
export type TaskStatus = (typeof TASK_STATUSES)[number];

/** Firestore: tasks/{taskId} */
export interface TaskDoc extends BaseDoc {
  /** Sahip kullanıcının uid'i */
  userId: string;
  /** Bağlı kategori — `null` ise kategorisiz */
  categoryId: string | null;
  title: string;
  /** Boş olabilir; varsayılan '' */
  description: string;
  status: TaskStatus;
  dueDate: Timestamp | null;
  /** status 'done' olduğunda set edilir, geri alınınca null'lanır */
  completedAt: Timestamp | null;
  /**
   * Başlık araması için kelime önekleri (utils/search.ts → buildSearchTokens). API'de dönülmez.
   * Bu alan eklenmeden önce oluşturulmuş görevler için: npm run migrate:search-tokens
   */
  searchTokens: string[];
}

/** API yanıtında dönen görev. `userId` dönülmez — istek zaten token sahibine aittir. */
export interface TaskDto {
  id: string;
  categoryId: string | null;
  title: string;
  description: string;
  status: TaskStatus;
  dueDate: string | null; // ISO 8601
  completedAt: string | null; // ISO 8601
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}
