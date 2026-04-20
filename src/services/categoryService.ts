import { getDb } from './database';
import { getNow } from '../utils/dateHelper';
import type { Category, CategoryFormData } from '../types/category';

function generateId(): string {
  return crypto.randomUUID();
}

export async function getAllCategories(): Promise<Category[]> {
  const db = await getDb();
  return db.select<Category[]>('SELECT * FROM categories ORDER BY sort_order ASC');
}

export async function getCategoryById(id: string): Promise<Category | null> {
  const db = await getDb();
  const rows = await db.select<Category[]>('SELECT * FROM categories WHERE id = $1', [id]);
  return rows[0] ?? null;
}

export async function createCategory(data: CategoryFormData): Promise<Category> {
  const db = await getDb();
  const now = getNow();
  const id = generateId();
  const maxOrder = await db.select<{ max_order: number }[]>(
    'SELECT COALESCE(MAX(sort_order), -1) as max_order FROM categories'
  );
  const sortOrder = (maxOrder[0]?.max_order ?? -1) + 1;

  await db.execute(
    'INSERT INTO categories (id, name, icon, color, sort_order, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
    [id, data.name, data.icon, data.color, sortOrder, now, now]
  );
  return { id, ...data, sort_order: sortOrder, created_at: now, updated_at: now };
}

export async function updateCategory(id: string, data: CategoryFormData): Promise<void> {
  const db = await getDb();
  await db.execute(
    'UPDATE categories SET name = $1, icon = $2, color = $3, updated_at = $4 WHERE id = $5',
    [data.name, data.icon, data.color, getNow(), id]
  );
}

export async function deleteCategory(id: string): Promise<void> {
  const db = await getDb();
  // Set items in this category to empty category
  await db.execute("UPDATE items SET category_id = '' WHERE category_id = $1", [id]);
  await db.execute('DELETE FROM categories WHERE id = $1', [id]);
}

export async function getCategoryItemCount(id: string): Promise<number> {
  const db = await getDb();
  const rows = await db.select<{ count: number }[]>(
    'SELECT COUNT(*) as count FROM items WHERE category_id = $1',
    [id]
  );
  return rows[0]?.count ?? 0;
}
