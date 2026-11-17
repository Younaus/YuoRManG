import { Timestamp, type UpdateData } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import type { UserDoc, UserDto } from '../models/index.js';
import type { UpdateMeInput } from '../schemas/user.schema.js';
import type { AuthUser } from '../types/auth.js';
import { usersCol } from '../utils/firestore.js';
import { toUserDto } from '../utils/mappers.js';

const DEFAULT_SETTINGS: UserDoc['settings'] = { theme: 'system', locale: 'tr-TR' };

/** Profil dokümanını döner; ilk istekte token bilgilerinden oluşturur (idempotent, transaction ile). */
export async function getOrCreateProfile(user: AuthUser): Promise<UserDto> {
  const ref = usersCol.doc(user.uid);
  const doc = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.data();
    if (existing) return existing;

    const now = Timestamp.now();
    const created: UserDoc = {
      email: user.email ?? '',
      displayName: user.name,
      photoURL: user.picture,
      settings: DEFAULT_SETTINGS,
      createdAt: now,
      updatedAt: now,
    };
    tx.set(ref, created);
    return created;
  });
  return toUserDto(user.uid, doc);
}

export async function updateProfile(user: AuthUser, input: UpdateMeInput): Promise<UserDto> {
  const current = await getOrCreateProfile(user);

  const now = Timestamp.now();
  // settings alanları dot-path ile güncellenir; gönderilmeyen ayarlar korunur.
  const patch: Record<string, unknown> = { updatedAt: now };
  if (input.displayName !== undefined) patch.displayName = input.displayName;
  for (const [key, value] of Object.entries(input.settings ?? {})) {
    if (value !== undefined) patch[`settings.${key}`] = value;
  }
  await usersCol.doc(user.uid).update(patch as UpdateData<UserDoc>);

  return {
    ...current,
    displayName: input.displayName !== undefined ? input.displayName : current.displayName,
    settings: { ...current.settings, ...stripUndefined(input.settings ?? {}) },
    updatedAt: now.toDate().toISOString(),
  };
}

function stripUndefined<T extends object>(obj: T): Partial<T> {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== undefined)) as Partial<T>;
}
