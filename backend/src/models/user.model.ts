import type { BaseDoc } from './common.model.js';

export type ThemePreference = 'system' | 'light' | 'dark';

export interface UserSettings {
  theme: ThemePreference;
  /** BCP-47 dil etiketi, örn. 'tr-TR' */
  locale: string;
}

/**
 * Firestore: users/{uid}
 * Doküman ID'si Firebase Auth `uid` ile aynıdır.
 */
export interface UserDoc extends BaseDoc {
  email: string;
  displayName: string | null;
  photoURL: string | null;
  settings: UserSettings;
}

/** API yanıtında dönen kullanıcı profili. */
export interface UserDto {
  id: string;
  email: string;
  displayName: string | null;
  photoURL: string | null;
  settings: UserSettings;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}
