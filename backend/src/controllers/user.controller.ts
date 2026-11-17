import type { Request, Response } from 'express';
import { requireUser } from '../middlewares/auth.middleware.js';
import type { UserDto } from '../models/index.js';
import type { UpdateMeInput } from '../schemas/user.schema.js';
import * as userService from '../services/user.service.js';

export async function getMe(req: Request, res: Response<UserDto>) {
  res.json(await userService.getOrCreateProfile(requireUser(req)));
}

export async function updateMe(req: Request<object, UserDto, UpdateMeInput>, res: Response<UserDto>) {
  res.json(await userService.updateProfile(requireUser(req), req.body));
}
