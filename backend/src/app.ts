import cors from 'cors';
import express, { type Express, type Request, type RequestHandler } from 'express';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';
import { publicBasePath } from './config/env.js';
import { generateOpenApiDocument } from './docs/openapi.js';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware.js';
import { apiRouter } from './routes/index.js';

export function createApp(): Express {
  const app = express();

  app.disable('x-powered-by');
  // Swagger UI inline script/style kullandığı için CSP'yi /docs dışında uyguluyoruz.
  app.use(/^(?!\/docs).*/, helmet());
  app.use(cors({ origin: true }));
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // --- OpenAPI / Swagger UI ---------------------------------------------------
  const openApiDoc = generateOpenApiDocument();
  const docForRequest = (req: Request) => ({ ...openApiDoc, servers: [{ url: publicBasePath(req) || '/' }] });

  const attachSwaggerDoc: RequestHandler = (req, _res, next) => {
    (req as Request & { swaggerDoc?: object }).swaggerDoc = docForRequest(req);
    next();
  };

  app.get('/docs.json', (req, res) => {
    res.json(docForRequest(req));
  });
  // swagger-ui-express'in kendi /docs → /docs/ yönlendirmesi öneki kaybettiği için kendimiz yapıyoruz.
  app.get('/docs', (req, res, next) => {
    if (req.path.endsWith('/')) return next();
    res.redirect(301, `${publicBasePath(req)}/docs/`);
  });
  app.use(
    '/docs',
    attachSwaggerDoc,
    swaggerUi.serveFiles(undefined, { swaggerOptions: { persistAuthorization: true } }),
    swaggerUi.setup(undefined, { swaggerOptions: { persistAuthorization: true } }),
  );

  // --- API --------------------------------------------------------------------
  app.use('/v1', apiRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
