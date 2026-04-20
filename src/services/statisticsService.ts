import { getDb } from './database';
import type { CategoryDistribution, MonthlySpending, DashboardStats } from '../types/settings';

export async function getDashboardStats(): Promise<DashboardStats> {
  const db = await getDb();

  const items = await db.select<{ count: number; total: number }[]>(
    "SELECT COUNT(*) as count, COALESCE(SUM(purchase_price * quantity), 0) as total FROM items WHERE status = 'active' AND is_medicine = 0"
  );

  const medicines = await db.select<{ count: number }[]>(
    "SELECT COUNT(*) as count FROM medicines m JOIN items i ON m.item_id = i.id WHERE i.status = 'active'"
  );

  const expiring = await db.select<{ count: number }[]>(
    `SELECT COUNT(*) as count FROM medicines m JOIN items i ON m.item_id = i.id
     WHERE i.status = 'active' AND date(m.expiry_date) <= date('now', '+30 days')`
  );

  return {
    total_items: items[0]?.count ?? 0,
    total_value: items[0]?.total ?? 0,
    medicine_count: medicines[0]?.count ?? 0,
    expiring_count: expiring[0]?.count ?? 0,
  };
}

export async function getCategoryDistribution(): Promise<CategoryDistribution[]> {
  const db = await getDb();
  return db.select<CategoryDistribution[]>(
    `SELECT c.name, c.color, COALESCE(SUM(i.purchase_price * i.quantity), 0) as value
     FROM categories c
     LEFT JOIN items i ON c.id = i.category_id AND i.status = 'active'
     GROUP BY c.id
     HAVING value > 0
     ORDER BY value DESC`
  );
}

export async function getMonthlySpending(months: number = 6): Promise<MonthlySpending[]> {
  const db = await getDb();
  return db.select<MonthlySpending[]>(
    `SELECT strftime('%Y-%m', purchase_date) as month,
            COALESCE(SUM(purchase_price * quantity), 0) as amount
     FROM items
     WHERE purchase_date != '' AND purchase_date >= date('now', '-' || $1 || ' months')
     GROUP BY month
     ORDER BY month ASC`,
    [months]
  );
}
