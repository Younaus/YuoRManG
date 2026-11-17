import type { AuthUser } from './auth.js';

declare global {
  namespace Express {
    interface Request {
      /** `authenticate` middleware'i tarafından set edilir. */
      user?: AuthUser;
    }
  }
}

export {};
