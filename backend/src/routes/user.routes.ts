import { Router } from 'express';
import * as ctrl from '../controllers/user.controller.js';
import { validate } from '../middlewares/validate.middleware.js';
import { UpdateMeSchema } from '../schemas/user.schema.js';

export const userRouter = Router();

userRouter.get('/', ctrl.getMe);
userRouter.patch('/', validate({ body: UpdateMeSchema }), ctrl.updateMe);
