import type { BaseDoc } from './common.model.js';

/**
 * Firestore: categories/{categoryId}
 * Adjacency List pattern: her kategori yalnızca ebeveyninin ID'sini tutar,
 * böylece sınırsız derinlikte alt kategori oluşturulabilir.
 */
export interface CategoryDoc extends BaseDoc {
  /** Sahip kullanıcının uid'i */
  userId: string;
  name: string;
  /** Ebeveyn kategori ID'si — `null` ise kök kategoridir. */
  parentId: string | null;
  /** '#RRGGBB' formatında renk */
  color: string | null;
  /** İkon anahtarı (Flutter tarafında IconData'ya map'lenir) */
  icon: string | null;
  /** Aynı ebeveyn altındaki kardeşler arası sıralama */
  order: number;
}

/** API yanıtında dönen düz kategori. */
export interface CategoryDto {
  id: string;
  name: string;
  parentId: string | null;
  color: string | null;
  icon: string | null;
  order: number;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}

/** Hiyerarşik listeleme için ağaç düğümü. */
export interface CategoryTreeNode extends CategoryDto {
  children: CategoryTreeNode[];
}
