import type { RequestHandler } from 'express';
import type { ZodType } from 'zod';

interface ValidationSchemas {
  params?: ZodType;
  query?: ZodType;
  body?: ZodType;
}

/**
 * İsteğin params/query/body kısımlarını Zod ile doğrular ve parse edilmiş (default'ları uygulanmış,
 * dönüştürülmüş) değerlerle değiştirir. Hata durumunda ZodError fırlatılır; errorHandler 400'e çevirir.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function validate(schemas: ValidationSchemas): RequestHandler<any, any, any, any> {
  return (req, _res, next) => {
    if (schemas.params) {
      req.params = schemas.params.parse(req.params);
    }
    if (schemas.query) {
      // Express 5'te req.query bir getter; parse edilmiş değeri own property olarak tanımlıyoruz.
      Object.defineProperty(req, 'query', {
        value: schemas.query.parse(req.query),
        writable: true,
        configurable: true,
        enumerable: true,
      });
    }
    if (schemas.body) {
      req.body = schemas.body.parse(req.body ?? {});
    }
    next();
  };
}
