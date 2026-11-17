import { Router } from 'express';
import { authenticate } from '../middlewares/auth.middleware.js';
import { categoryRouter } from './category.routes.js';
import { taskRouter } from './task.routes.js';
import { userRouter } from './user.routes.js';

/** `/v1` altındaki tüm endpoint'ler kimlik doğrulama gerektirir. */
export const apiRouter = Router();

apiRouter.use(authenticate);
apiRouter.use('/me', userRouter);
apiRouter.use('/categories', categoryRouter);
apiRouter.use('/tasks', taskRouter);
