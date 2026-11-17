import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

// Cloud Functions ortamında ve emülatörde kimlik bilgileri otomatik bulunur.
const app = getApps()[0] ?? initializeApp();

export const db = getFirestore(app);
db.settings({ ignoreUndefinedProperties: true });

export const auth = getAuth(app);
