import { getDb } from './database';
import { getNow } from '../utils/dateHelper';
import { logInfo } from '../utils/logger';
import type { Item, ItemWithDetails, ItemFormData } from '../types/item';

function generateId(): string {
  return crypto.randomUUID();
}

export async function getAllItems(
  filter?: { category_id?: string; location_id?: string; status?: string; search?: string }
): Promise<ItemWithDetails[]> {
  const db = await getDb();
  let sql = `
    SELECT i.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
           l.full_path as location_full_path
    FROM items i
    LEFT JOIN categories c ON i.category_id = c.id
    LEFT JOIN locations l ON i.location_id = l.id
    WHERE i.is_medicine = 0
  `;
  const params: unknown[] = [];
  let paramIndex = 1;

  if (filter?.category_id) {
    sql += ` AND i.category_id = $${paramIndex++}`;
    params.push(filter.category_id);
  }
  if (filter?.location_id) {
    sql += ` AND i.location_id = $${paramIndex++}`;
    params.push(filter.location_id);
  }
  if (filter?.status) {
    sql += ` AND i.status = $${paramIndex++}`;
    params.push(filter.status);
  }
  if (filter?.search) {
    sql += ` AND i.name LIKE $${paramIndex++}`;
    params.push(`%${filter.search}%`);
  }

  sql += ' ORDER BY i.created_at DESC';
  return db.select<ItemWithDetails[]>(sql, params);
}

export async function getItemById(id: string): Promise<ItemWithDetails | null> {
  const db = await getDb();
  const rows = await db.select<ItemWithDetails[]>(
    `SELECT i.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
            l.full_path as location_full_path
     FROM items i
     LEFT JOIN categories c ON i.category_id = c.id
     LEFT JOIN locations l ON i.location_id = l.id
     WHERE i.id = $1`,
    [id]
  );
  return rows[0] ?? null;
}

export async function createItem(data: ItemFormData): Promise<Item> {
  const db = await getDb();
  const now = getNow();
  const id = generateId();

  await db.execute(
    `INSERT INTO items (id, name, description, category_id, location_id, purchase_date,
     purchase_price, quantity, image_path, icon, status, is_medicine, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
    [
      id, data.name, data.description, data.category_id, data.location_id,
      data.purchase_date, data.purchase_price, data.quantity, data.image_path,
      data.icon || '', data.status, data.is_medicine ? 1 : 0, now, now,
    ]
  );

  logInfo(`创建物品: ${data.name} (id=${id})`, 'ItemService');

  return {
    id, name: data.name, description: data.description, category_id: data.category_id,
    location_id: data.location_id, purchase_date: data.purchase_date,
    purchase_price: data.purchase_price, quantity: data.quantity, image_path: data.image_path,
    icon: data.icon || '', status: data.status, is_medicine: data.is_medicine ? 1 : 0,
    warranty_expiry: data.warranty_expiry || '',
    shelf_life_expiry: data.shelf_life_expiry || '',
    created_at: now, updated_at: now,
  };
}

export async function updateItem(id: string, data: Partial<ItemFormData>): Promise<void> {
  const db = await getDb();
  const fields: string[] = [];
  const params: unknown[] = [];
  let paramIndex = 1;

  const fieldMap: Record<string, string> = {
    name: 'name', description: 'description', category_id: 'category_id',
    location_id: 'location_id', purchase_date: 'purchase_date',
    purchase_price: 'purchase_price', quantity: 'quantity',
    image_path: 'image_path', icon: 'icon', status: 'status',
  };

  for (const [key, col] of Object.entries(fieldMap)) {
    if (key in data) {
      fields.push(`${col} = $${paramIndex++}`);
      params.push((data as Record<string, unknown>)[key]);
    }
  }

  if (fields.length === 0) return;

  fields.push(`updated_at = $${paramIndex++}`);
  params.push(getNow());
  params.push(id);

  await db.execute(
    `UPDATE items SET ${fields.join(', ')} WHERE id = $${paramIndex}`,
    params
  );
}

export async function deleteItem(id: string): Promise<void> {
  const db = await getDb();
  // Medicines will be cascade deleted
  await db.execute('DELETE FROM items WHERE id = $1', [id]);
  logInfo(`删除物品: id=${id}`, 'ItemService');
}
