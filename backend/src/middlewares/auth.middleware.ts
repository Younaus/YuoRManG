import type { Request, RequestHandler } from 'express';
import { logger } from 'firebase-functions';
import { auth } from '../config/firebase.js';
import type { AuthUser } from '../types/auth.js';
import { AppError } from '../utils/app-error.js';

const BEARER_PREFIX = /^Bearer\s+(.+)$/i;

/**
 * `Authorization: Bearer <Firebase ID token>` header'ını doğrular ve `req.user`'ı set eder.
 * Emülatörde FIREBASE_AUTH_EMULATOR_HOST otomatik set edildiği için emülatör token'ları kabul edilir.
 */
export const authenticate: RequestHandler = async (req, _res, next) => {
  const match = req.headers.authorization?.match(BEARER_PREFIX);
  if (!match) throw AppError.unauthorized('Missing or malformed Authorization header');

  try {
    const decoded = await auth.verifyIdToken(match[1].trim());
    req.user = {
      uid: decoded.uid,
      email: decoded.email ?? null,
      name: typeof decoded.name === 'string' ? decoded.name : null,
      picture: decoded.picture ?? null,
      emailVerified: decoded.email_verified ?? false,
    };
  } catch (err) {
    logger.debug('ID token verification failed', { error: (err as Error).message });
    throw AppError.unauthorized('Invalid or expired token');
  }

  next();
};

/** Controller'larda doğrulanmış kullanıcıyı tipli olarak almak için. */
export function requireUser(req: Pick<Request, 'user'>): AuthUser {
  if (!req.user) throw AppError.unauthorized();
  return req.user;
}
