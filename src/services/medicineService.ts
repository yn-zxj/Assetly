import { getDb } from './database';
import { getNow } from '../utils/dateHelper';
import { logInfo } from '../utils/logger';
import type { MedicineWithItem, MedicineFormData } from '../types/medicine';

function generateId(): string {
  return crypto.randomUUID();
}

export async function getAllMedicines(
  filter?: { type?: string; search?: string }
): Promise<MedicineWithItem[]> {
  const db = await getDb();
  let sql = `
    SELECT m.*, i.name, i.description, i.category_id, i.location_id,
           i.purchase_date, i.purchase_price, i.quantity, i.image_path, i.status, i.icon,
           l.full_path as location_full_path
    FROM medicines m
    JOIN items i ON m.item_id = i.id
    LEFT JOIN locations l ON i.location_id = l.id
    WHERE 1=1
  `;
  const params: unknown[] = [];
  let paramIndex = 1;

  if (filter?.type) {
    sql += ` AND m.medicine_type = $${paramIndex++}`;
    params.push(filter.type);
  }
  if (filter?.search) {
    sql += ` AND i.name LIKE $${paramIndex++}`;
    params.push(`%${filter.search}%`);
  }

  sql += ' ORDER BY m.expiry_date ASC';
  return db.select<MedicineWithItem[]>(sql, params);
}

export async function getMedicineByItemId(itemId: string): Promise<MedicineWithItem | null> {
  const db = await getDb();
  const rows = await db.select<MedicineWithItem[]>(
    `SELECT m.*, i.name, i.description, i.category_id, i.location_id,
            i.purchase_date, i.purchase_price, i.quantity, i.image_path, i.status, i.icon,
            l.full_path as location_full_path
     FROM medicines m
     JOIN items i ON m.item_id = i.id
     LEFT JOIN locations l ON i.location_id = l.id
     WHERE m.item_id = $1`,
    [itemId]
  );
  return rows[0] ?? null;
}

export async function createMedicine(data: MedicineFormData): Promise<{ itemId: string; medicineId: string }> {
  const db = await getDb();
  const now = getNow();
  const itemId = generateId();
  const medicineId = generateId();

  // Find medicine category
  const cats = await db.select<{ id: string }[]>(
    "SELECT id FROM categories WHERE name = '药品保健' LIMIT 1"
  );
  const categoryId = data.category_id || (cats[0]?.id ?? '');

  // Create item first
  await db.execute(
    `INSERT INTO items (id, name, description, category_id, location_id, purchase_date,
     purchase_price, quantity, image_path, status, is_medicine, icon, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'active', 1, $10, $11, $12)`,
    [
      itemId, data.name, data.description, categoryId, data.location_id,
      data.purchase_date, data.purchase_price, data.quantity, data.image_path,
      data.icon, now, now,
    ]
  );

  // Create medicine extension
  await db.execute(
    `INSERT INTO medicines (id, item_id, medicine_type, expiry_date, dosage_instructions,
     remaining_quantity, unit, manufacturer, is_taking, frequency_type, frequency_days,
     week_days, time_slots, duration_start, duration_end, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
    [
      medicineId, itemId, data.medicine_type, data.expiry_date,
      data.dosage_instructions, data.remaining_quantity, data.unit,
      data.manufacturer, data.is_taking ? 1 : 0, data.frequency_type,
      data.frequency_days, data.week_days, data.time_slots,
      data.duration_start, data.duration_end, now, now,
    ]
  );

  logInfo(`创建药品: ${data.name} (itemId=${itemId}, medicineId=${medicineId})`, 'MedicineService');
  return { itemId, medicineId };
}

export async function updateMedicine(itemId: string, data: Partial<MedicineFormData>): Promise<void> {
  const db = await getDb();
  const now = getNow();

  // Update item fields
  const itemFields: string[] = [];
  const itemParams: unknown[] = [];
  let idx = 1;

  const itemFieldMap: Record<string, string> = {
    name: 'name', description: 'description', location_id: 'location_id',
    purchase_date: 'purchase_date', purchase_price: 'purchase_price',
    quantity: 'quantity', image_path: 'image_path', icon: 'icon',
  };

  for (const [key, col] of Object.entries(itemFieldMap)) {
    if (key in data) {
      itemFields.push(`${col} = $${idx++}`);
      itemParams.push((data as Record<string, unknown>)[key]);
    }
  }

  if (itemFields.length > 0) {
    itemFields.push(`updated_at = $${idx++}`);
    itemParams.push(now);
    itemParams.push(itemId);
    await db.execute(
      `UPDATE items SET ${itemFields.join(', ')} WHERE id = $${idx}`,
      itemParams
    );
  }

  // Update medicine fields
  const medFields: string[] = [];
  const medParams: unknown[] = [];
  idx = 1;

  const medFieldMap: Record<string, string> = {
    medicine_type: 'medicine_type', expiry_date: 'expiry_date',
    dosage_instructions: 'dosage_instructions', remaining_quantity: 'remaining_quantity',
    unit: 'unit', manufacturer: 'manufacturer',
    is_taking: 'is_taking', frequency_type: 'frequency_type',
    frequency_days: 'frequency_days', week_days: 'week_days',
    time_slots: 'time_slots', duration_start: 'duration_start',
    duration_end: 'duration_end',
  };

  for (const [key, col] of Object.entries(medFieldMap)) {
    if (key in data) {
      medFields.push(`${col} = $${idx++}`);
      const val = (data as Record<string, unknown>)[key];
      // Convert boolean to integer for SQLite
      medParams.push(key === 'is_taking' ? (val ? 1 : 0) : val);
    }
  }

  if (medFields.length > 0) {
    medFields.push(`updated_at = $${idx++}`);
    medParams.push(now);
    medParams.push(itemId);
    await db.execute(
      `UPDATE medicines SET ${medFields.join(', ')} WHERE item_id = $${idx}`,
      medParams
    );
  }
}

export async function getExpiringMedicines(withinDays: number): Promise<MedicineWithItem[]> {
  const db = await getDb();
  return db.select<MedicineWithItem[]>(
    `SELECT m.*, i.name, i.description, i.category_id, i.location_id,
            i.purchase_date, i.purchase_price, i.quantity, i.image_path, i.status, i.icon,
            l.full_path as location_full_path
     FROM medicines m
     JOIN items i ON m.item_id = i.id
     LEFT JOIN locations l ON i.location_id = l.id
     WHERE date(m.expiry_date) <= date('now', '+' || $1 || ' days')
       AND i.status = 'active'
     ORDER BY m.expiry_date ASC`,
    [withinDays]
  );
}

export async function getTakingMedicines(): Promise<MedicineWithItem[]> {
  const db = await getDb();
  return db.select<MedicineWithItem[]>(
    `SELECT m.*, i.name, i.description, i.category_id, i.location_id,
            i.purchase_date, i.purchase_price, i.quantity, i.image_path, i.status, i.icon,
            l.full_path as location_full_path
     FROM medicines m
     JOIN items i ON m.item_id = i.id
     LEFT JOIN locations l ON i.location_id = l.id
     WHERE m.is_taking = 1
       AND i.status = 'active'
     ORDER BY m.created_at DESC`
  );
}
