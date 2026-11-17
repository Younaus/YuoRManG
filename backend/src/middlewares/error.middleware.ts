import type { ErrorRequestHandler, RequestHandler } from 'express';
import { logger } from 'firebase-functions';
import { ZodError } from 'zod';
import { AppError, type ErrorCode } from '../utils/app-error.js';

interface ErrorBody {
  error: { code: ErrorCode; message: string; details?: unknown };
}

export const notFoundHandler: RequestHandler = (req, _res, next) => {
  next(AppError.notFound(`Route ${req.method} ${req.path} not found`));
};

export const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  const send = (status: number, body: ErrorBody) => res.status(status).json(body);

  if (err instanceof AppError) {
    return void send(err.statusCode, {
      error: { code: err.code, message: err.message, ...(err.details !== undefined && { details: err.details }) },
    });
  }

  if (err instanceof ZodError) {
    return void send(400, {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: err.issues.map((i) => ({ path: i.path.join('.'), message: i.message, code: i.code })),
      },
    });
  }

  // body-parser (express.json) hataları
  if (err?.type === 'entity.parse.failed') {
    return void send(400, { error: { code: 'INVALID_JSON', message: 'Malformed JSON body' } });
  }
  if (err?.type === 'entity.too.large') {
    return void send(413, { error: { code: 'PAYLOAD_TOO_LARGE', message: 'Request body too large' } });
  }

  logger.error('Unhandled error', { method: req.method, path: req.path, error: err?.stack ?? String(err) });
  send(500, { error: { code: 'INTERNAL', message: 'Internal server error' } });
};
