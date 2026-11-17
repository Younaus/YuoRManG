import type { CategoryDoc, CategoryDto, TaskDoc, TaskDto, UserDoc, UserDto } from '../models/index.js';
import { toIso } from './firestore.js';

export function toUserDto(id: string, d: UserDoc): UserDto {
  return {
    id,
    email: d.email,
    displayName: d.displayName,
    photoURL: d.photoURL,
    settings: d.settings,
    createdAt: toIso(d.createdAt),
    updatedAt: toIso(d.updatedAt),
  };
}

export function toCategoryDto(id: string, d: CategoryDoc): CategoryDto {
  return {
    id,
    name: d.name,
    parentId: d.parentId,
    color: d.color,
    icon: d.icon,
    order: d.order,
    createdAt: toIso(d.createdAt),
    updatedAt: toIso(d.updatedAt),
  };
}

export function toTaskDto(id: string, d: TaskDoc): TaskDto {
  return {
    id,
    categoryId: d.categoryId,
    title: d.title,
    description: d.description,
    status: d.status,
    dueDate: toIso(d.dueDate),
    completedAt: toIso(d.completedAt),
    createdAt: toIso(d.createdAt),
    updatedAt: toIso(d.updatedAt),
  };
}
