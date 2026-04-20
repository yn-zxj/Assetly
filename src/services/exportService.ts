import { getDb } from './database';
import { getNow } from '../utils/dateHelper';

export async function exportToJSON(): Promise<string> {
  const db = await getDb();

  const categories = await db.select('SELECT * FROM categories ORDER BY sort_order');
  const locations = await db.select('SELECT * FROM locations ORDER BY level, sort_order');
  const items = await db.select('SELECT * FROM items ORDER BY created_at DESC');
  const medicines = await db.select('SELECT * FROM medicines ORDER BY expiry_date');

  return JSON.stringify({ categories, locations, items, medicines }, null, 2);
}

export async function exportToCSV(): Promise<string> {
  const db = await getDb();

  const items = await db.select<Record<string, unknown>[]>(
    `SELECT i.name, i.description, c.name as category, l.full_path as location,
            i.purchase_date, i.purchase_price, i.quantity, i.status,
            CASE WHEN i.is_medicine = 1 THEN m.expiry_date ELSE '' END as expiry_date,
            CASE WHEN i.is_medicine = 1 THEN m.medicine_type ELSE '' END as medicine_type
     FROM items i
     LEFT JOIN categories c ON i.category_id = c.id
     LEFT JOIN locations l ON i.location_id = l.id
     ORDER BY i.created_at DESC`
  );

  if (items.length === 0) return '';

  const headers = ['名称', '描述', '分类', '位置', '购买日期', '价格', '数量', '状态', '有效期', '药品类型'];
  const keys = ['name', 'description', 'category', 'location', 'purchase_date', 'purchase_price', 'quantity', 'status', 'expiry_date', 'medicine_type'];

  const lines = [headers.join(',')];
  for (const item of items) {
    const values = keys.map((key) => {
      const val = String(item[key] ?? '');
      return val.includes(',') || val.includes('"') ? `"${val.replace(/"/g, '""')}"` : val;
    });
    lines.push(values.join(','));
  }

  return lines.join('\n');
}

interface ImportData {
  categories?: unknown[];
  locations?: unknown[];
  items?: unknown[];
  medicines?: unknown[];
}

export async function importFromJSON(jsonStr: string): Promise<{ success: number; failed: number; errors: string[] }> {
  const db = await getDb();
  const result = { success: 0, failed: 0, errors: [] as string[] };

  let data: ImportData;
  try {
    data = JSON.parse(jsonStr);
  } catch {
    result.errors.push('JSON 格式解析失败');
    return result;
  }

  const now = getNow();

  // Import categories
  if (data.categories && Array.isArray(data.categories)) {
    for (const cat of data.categories) {
      try {
        const c = cat as Record<string, unknown>;
        await db.execute(
          `INSERT OR REPLACE INTO categories (id, name, icon, color, sort_order, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [c.id, c.name, c.icon ?? '', c.color ?? '#6B7280', c.sort_order ?? 0, c.created_at ?? now, now]
        );
        result.success++;
      } catch (err) {
        result.failed++;
        result.errors.push(`分类导入失败: ${(err as Error).message}`);
      }
    }
  }

  // Import locations
  if (data.locations && Array.isArray(data.locations)) {
    for (const loc of data.locations) {
      try {
        const l = loc as Record<string, unknown>;
        await db.execute(
          `INSERT OR REPLACE INTO locations (id, name, parent_id, full_path, level, sort_order, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [l.id, l.name, l.parent_id ?? null, l.full_path ?? l.name, l.level ?? 0, l.sort_order ?? 0, l.created_at ?? now, now]
        );
        result.success++;
      } catch (err) {
        result.failed++;
        result.errors.push(`位置导入失败: ${(err as Error).message}`);
      }
    }
  }

  // Import items
  if (data.items && Array.isArray(data.items)) {
    for (const item of data.items) {
      try {
        const i = item as Record<string, unknown>;
        await db.execute(
          `INSERT OR REPLACE INTO items (id, name, description, category_id, location_id, purchase_date,
           purchase_price, quantity, image_path, icon, status, is_medicine, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
          [
            i.id, i.name, i.description ?? '', i.category_id ?? '', i.location_id ?? '',
            i.purchase_date ?? '', i.purchase_price ?? 0, i.quantity ?? 1, i.image_path ?? '',
            i.icon ?? '', i.status ?? 'active', i.is_medicine ?? 0, i.created_at ?? now, now,
          ]
        );
        result.success++;
      } catch (err) {
        result.failed++;
        result.errors.push(`物品导入失败: ${(err as Error).message}`);
      }
    }
  }

  // Import medicines
  if (data.medicines && Array.isArray(data.medicines)) {
    for (const med of data.medicines) {
      try {
        const m = med as Record<string, unknown>;
        await db.execute(
          `INSERT OR REPLACE INTO medicines (id, item_id, medicine_type, expiry_date, dosage_instructions,
           remaining_quantity, unit, manufacturer, is_taking, frequency_type, frequency_days,
           week_days, time_slots, duration_start, duration_end, last_reminded, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)`,
          [
            m.id, m.item_id, m.medicine_type ?? 'internal', m.expiry_date ?? '', m.dosage_instructions ?? '',
            m.remaining_quantity ?? 0, m.unit ?? '片', m.manufacturer ?? '',
            m.is_taking ?? 0, m.frequency_type ?? 'daily', m.frequency_days ?? 1,
            m.week_days ?? '', m.time_slots ?? '', m.duration_start ?? '',
            m.duration_end ?? '', m.last_reminded ?? '', m.created_at ?? now, now,
          ]
        );
        result.success++;
      } catch (err) {
        result.failed++;
        result.errors.push(`药品导入失败: ${(err as Error).message}`);
      }
    }
  }

  return result;
}
