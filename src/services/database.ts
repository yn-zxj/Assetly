import Database from '@tauri-apps/plugin-sql';
import { getNow } from '../utils/dateHelper';
import { DEFAULT_CATEGORIES } from '../utils/constants';
import { logInfo, logError, logDebug } from '../utils/logger';

let db: Database | null = null;

export async function getDb(): Promise<Database> {
  if (!db) {
    logInfo('正在连接数据库...', 'Database');
    db = await Database.load('sqlite:assetly.db');
    logInfo('数据库连接成功', 'Database');
    await runMigrations(db);
  }
  return db;
}

async function runMigrations(database: Database): Promise<void> {
  // Create migrations table
  await database.execute(`
    CREATE TABLE IF NOT EXISTS _migrations (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL
    )
  `);

  // Get current version
  const rows = await database.select<{ version: number }[]>(
    'SELECT MAX(version) as version FROM _migrations'
  );
  const currentVersion = rows[0]?.version ?? 0;
  logDebug(`当前数据库版本: ${currentVersion}`, 'Database');

  const migrations = getMigrations();
  for (const migration of migrations) {
    if (migration.version > currentVersion) {
      logInfo(`执行数据库迁移: v${migration.version}`, 'Database');
      for (const sql of migration.statements) {
        try {
          await database.execute(sql);
        } catch (err) {
          logError(`迁移 SQL 执行失败: ${sql.slice(0, 80)}... 错误: ${(err as Error).message}`, 'Database');
          throw err;
        }
      }
      await database.execute(
        'INSERT INTO _migrations (version, applied_at) VALUES ($1, $2)',
        [migration.version, getNow()]
      );
      logInfo(`数据库迁移完成: v${migration.version}`, 'Database');
    }
  }
}

interface Migration {
  version: number;
  statements: string[];
}

function getMigrations(): Migration[] {
  const now = getNow();
  return [
    {
      version: 1,
      statements: [
        // Categories table
        `CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT DEFAULT '',
          color TEXT DEFAULT '#6B7280',
          sort_order INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )`,
        // Locations table (self-referencing tree)
        `CREATE TABLE IF NOT EXISTS locations (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          parent_id TEXT,
          full_path TEXT NOT NULL DEFAULT '',
          level INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (parent_id) REFERENCES locations(id) ON DELETE SET NULL
        )`,
        // Items table
        `CREATE TABLE IF NOT EXISTS items (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT DEFAULT '',
          category_id TEXT DEFAULT '',
          location_id TEXT DEFAULT '',
          purchase_date TEXT DEFAULT '',
          purchase_price REAL DEFAULT 0,
          quantity INTEGER DEFAULT 1,
          image_path TEXT DEFAULT '',
          status TEXT DEFAULT 'active',
          is_medicine INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )`,
        // Medicines table (1:1 extension of items)
        `CREATE TABLE IF NOT EXISTS medicines (
          id TEXT PRIMARY KEY,
          item_id TEXT NOT NULL UNIQUE,
          medicine_type TEXT NOT NULL DEFAULT 'internal',
          expiry_date TEXT NOT NULL,
          dosage_instructions TEXT DEFAULT '',
          remaining_quantity INTEGER DEFAULT 0,
          unit TEXT DEFAULT '片',
          manufacturer TEXT DEFAULT '',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
        )`,
        // Settings table
        `CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )`,
        // Indexes
        `CREATE INDEX IF NOT EXISTS idx_items_category ON items(category_id)`,
        `CREATE INDEX IF NOT EXISTS idx_items_location ON items(location_id)`,
        `CREATE INDEX IF NOT EXISTS idx_items_status ON items(status)`,
        `CREATE INDEX IF NOT EXISTS idx_medicines_item ON medicines(item_id)`,
        `CREATE INDEX IF NOT EXISTS idx_medicines_expiry ON medicines(expiry_date)`,
        `CREATE INDEX IF NOT EXISTS idx_medicines_type ON medicines(medicine_type)`,
        `CREATE INDEX IF NOT EXISTS idx_locations_parent ON locations(parent_id)`,
        // Seed default categories
        ...DEFAULT_CATEGORIES.map(
          (cat, i) =>
            `INSERT OR IGNORE INTO categories (id, name, icon, color, sort_order, created_at, updated_at) VALUES ('cat-${i + 1}', '${cat.name}', '${cat.icon}', '${cat.color}', ${cat.sort_order}, '${now}', '${now}')`
        ),
        // Seed default settings
        `INSERT OR IGNORE INTO settings (key, value, updated_at) VALUES ('theme_color', '"#22C55E"', '${now}')`,
        `INSERT OR IGNORE INTO settings (key, value, updated_at) VALUES ('currency_symbol', '"¥"', '${now}')`,
      ],
    },
    {
      version: 2,
      statements: [
        `ALTER TABLE items ADD COLUMN icon TEXT DEFAULT ''`,
      ],
    },
    {
      version: 3,
      statements: [
        `ALTER TABLE medicines ADD COLUMN is_taking INTEGER DEFAULT 0`,
        `ALTER TABLE medicines ADD COLUMN frequency_type TEXT DEFAULT 'daily'`,
        `ALTER TABLE medicines ADD COLUMN frequency_days INTEGER DEFAULT 1`,
        `ALTER TABLE medicines ADD COLUMN week_days TEXT DEFAULT ''`,
        `ALTER TABLE medicines ADD COLUMN time_slots TEXT DEFAULT ''`,
        `ALTER TABLE medicines ADD COLUMN duration_start TEXT DEFAULT ''`,
        `ALTER TABLE medicines ADD COLUMN duration_end TEXT DEFAULT ''`,
        `ALTER TABLE medicines ADD COLUMN last_reminded TEXT DEFAULT ''`,
      ],
    },
    {
      version: 4,
      statements: [
        `ALTER TABLE items ADD COLUMN warranty_expiry TEXT DEFAULT ''`,
        `ALTER TABLE items ADD COLUMN shelf_life_expiry TEXT DEFAULT ''`,
        `ALTER TABLE locations ADD COLUMN image_path TEXT DEFAULT ''`,
      ],
    },
  ];
}
