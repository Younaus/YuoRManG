import {
  Timestamp,
  type DocumentData,
  type FirestoreDataConverter,
  type QueryDocumentSnapshot,
  type WriteBatch,
} from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { COLLECTIONS, type CategoryDoc, type TaskDoc, type UserDoc } from '../models/index.js';

function converter<T extends DocumentData>(): FirestoreDataConverter<T> {
  return {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    toFirestore: (data: any) => data as DocumentData,
    fromFirestore: (snap: QueryDocumentSnapshot) => snap.data() as T,
  };
}

/** Tipli koleksiyon referansları. */
export const usersCol = db.collection(COLLECTIONS.users).withConverter(converter<UserDoc>());
export const categoriesCol = db.collection(COLLECTIONS.categories).withConverter(converter<CategoryDoc>());
export const tasksCol = db.collection(COLLECTIONS.tasks).withConverter(converter<TaskDoc>());

export function toIso(ts: Timestamp): string;
export function toIso(ts: Timestamp | null): string | null;
export function toIso(ts: Timestamp | null): string | null {
  return ts ? ts.toDate().toISOString() : null;
}

export function fromIso(iso: string): Timestamp;
export function fromIso(iso: string | null): Timestamp | null;
export function fromIso(iso: string | null): Timestamp | null {
  return iso ? Timestamp.fromDate(new Date(iso)) : null;
}

export function chunk<T>(items: readonly T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

/** Firestore batch'leri 500 işlem limitiyle sınırlı; işlemleri parçalara bölüp sırayla commit eder. */
export async function commitInChunks(ops: ReadonlyArray<(batch: WriteBatch) => void>, size = 450): Promise<void> {
  for (const group of chunk(ops, size)) {
    const batch = db.batch();
    group.forEach((op) => op(batch));
    await batch.commit();
  }
}

/** Firestore `in` sorgusu tek seferde en fazla 30 değer kabul eder. */
export const FIRESTORE_IN_LIMIT = 30;
