import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class AppDatabase {
  static const schemaVersion = 9;

  Database? _database;
  final _uuid = const Uuid();
  Database get db => _database!;

  Future<void> open() async {
    final path = p.join(await getDatabasesPath(), 'assetly.db');
    _database = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await _createSchema(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) => _upgrade(db),
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS categories (id TEXT PRIMARY KEY, name TEXT NOT NULL, icon TEXT DEFAULT \'\', color TEXT DEFAULT \'#71717A\', sort_order INTEGER DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS locations (id TEXT PRIMARY KEY, name TEXT NOT NULL, icon TEXT DEFAULT \'📍\', parent_id TEXT, full_path TEXT NOT NULL DEFAULT \'\', level INTEGER NOT NULL DEFAULT 0, sort_order INTEGER DEFAULT 0, image_path TEXT DEFAULT \'\', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(parent_id) REFERENCES locations(id) ON DELETE SET NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS items (id TEXT PRIMARY KEY, barcode TEXT DEFAULT \'\', name TEXT NOT NULL, description TEXT DEFAULT \'\', category_id TEXT DEFAULT \'\', location_id TEXT DEFAULT \'\', purchase_date TEXT DEFAULT \'\', purchase_price REAL DEFAULT 0, quantity INTEGER DEFAULT 1, image_path TEXT DEFAULT \'\', status TEXT DEFAULT \'active\', is_medicine INTEGER DEFAULT 0, icon TEXT DEFAULT \'\', warranty_expiry TEXT DEFAULT \'\', shelf_life_expiry TEXT DEFAULT \'\', retired_date TEXT DEFAULT \'\', resale_amount REAL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS medicines (id TEXT PRIMARY KEY, item_id TEXT NOT NULL UNIQUE, medicine_type TEXT NOT NULL DEFAULT \'internal\', expiry_date TEXT NOT NULL, dosage_instructions TEXT DEFAULT \'\', remaining_quantity REAL DEFAULT 0, unit TEXT DEFAULT \'片\', manufacturer TEXT DEFAULT \'\', is_taking INTEGER DEFAULT 0, frequency_type TEXT DEFAULT \'daily\', frequency_days INTEGER DEFAULT 1, week_days TEXT DEFAULT \'\', time_slots TEXT DEFAULT \'\', duration_start TEXT DEFAULT \'\', duration_end TEXT DEFAULT \'\', last_reminded TEXT DEFAULT \'\', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS medication_logs (id TEXT PRIMARY KEY, medicine_id TEXT NOT NULL, scheduled_at TEXT DEFAULT \'\', taken_at TEXT NOT NULL, quantity REAL DEFAULT 1, status TEXT DEFAULT \'taken\', created_at TEXT NOT NULL, FOREIGN KEY(medicine_id) REFERENCES medicines(id) ON DELETE CASCADE)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
    for (final sql in [
      'CREATE INDEX IF NOT EXISTS idx_items_category ON items(category_id)',
      'CREATE INDEX IF NOT EXISTS idx_items_location ON items(location_id)',
      'CREATE INDEX IF NOT EXISTS idx_items_status ON items(status)',
      'CREATE INDEX IF NOT EXISTS idx_medicines_item ON medicines(item_id)',
      'CREATE INDEX IF NOT EXISTS idx_locations_parent ON locations(parent_id)',
    ]) {
      await db.execute(sql);
    }
  }

  Future<void> _upgrade(Database db) async {
    await _createSchema(db);
    await _ensureColumn(db, 'items', 'barcode', 'TEXT DEFAULT \'\'');
    await _ensureColumn(db, 'items', 'icon', 'TEXT DEFAULT \'\'');
    await _ensureColumn(db, 'items', 'warranty_expiry', 'TEXT DEFAULT \'\'');
    await _ensureColumn(db, 'items', 'shelf_life_expiry', 'TEXT DEFAULT \'\'');
    await _ensureColumn(db, 'items', 'retired_date', 'TEXT DEFAULT \'\'');
    await _ensureColumn(db, 'items', 'resale_amount', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'locations', 'image_path', 'TEXT DEFAULT \'\'');
    await _ensureColumn(db, 'locations', 'icon', 'TEXT DEFAULT \'📍\'');
    for (final entry in <String, String>{
      'is_taking': 'INTEGER DEFAULT 0',
      'frequency_type': 'TEXT DEFAULT \'daily\'',
      'frequency_days': 'INTEGER DEFAULT 1',
      'week_days': 'TEXT DEFAULT \'\'',
      'time_slots': 'TEXT DEFAULT \'\'',
      'duration_start': 'TEXT DEFAULT \'\'',
      'duration_end': 'TEXT DEFAULT \'\'',
      'last_reminded': 'TEXT DEFAULT \'\'',
    }.entries) {
      await _ensureColumn(db, 'medicines', entry.key, entry.value);
    }
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (!columns.any((row) => row['name'] == column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();
    // Categories are part of the product vocabulary rather than example data.
    // Assets, medicines and spaces intentionally start empty on a fresh install.
    final categories = [
      ['cat-digital', '数码家电', '', '#18181B'],
      ['cat-daily', '生活日用', '', '#71717A'],
      ['cat-apparel', '服饰鞋包', '', '#52525B'],
      ['cat-home', '家具家居', '', '#78716C'],
      ['cat-medicine', '药品保健', '', '#10B981'],
    ];
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      await db.insert('categories', {
        'id': c[0],
        'name': c[1],
        'icon': c[2],
        'color': c[3],
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }
    for (final e in {
      'theme_mode': 'system',
      'accent': 'emerald',
      'ai_enabled': 'false',
      'ai_model_mode': 'shared',
      'ai_api_url': 'https://api.openai.com/v1',
      'ai_text_model': 'gpt-4o-mini',
      'ai_vision_api_url': 'https://api.openai.com/v1',
      'ai_vision_model': 'gpt-4o',
      'webdav_enabled': 'false',
      'webdav_server_url': '',
      'webdav_username': '',
      'webdav_remote_path': '/assetly-backup.json',
    }.entries) {
      await setSetting(e.key, e.value, database: db);
    }
  }

  Future<List<AssetItem>> getItems() async {
    final rows = await db.rawQuery(
      'SELECT i.*, c.name category_name, l.full_path location_full_path FROM items i LEFT JOIN categories c ON i.category_id=c.id LEFT JOIN locations l ON i.location_id=l.id WHERE i.is_medicine=0 ORDER BY i.updated_at DESC',
    );
    return rows.map(AssetItem.fromMap).toList();
  }

  Future<List<Medicine>> getMedicines() async {
    final rows = await db.rawQuery(
      'SELECT m.*, i.name, i.icon, i.barcode, i.location_id, i.purchase_date, i.purchase_price, l.full_path location_full_path FROM medicines m JOIN items i ON i.id=m.item_id LEFT JOIN locations l ON i.location_id=l.id ORDER BY m.is_taking DESC, m.expiry_date',
    );
    return rows.map(Medicine.fromMap).toList();
  }

  Future<Medicine?> getMedicine(String id) async {
    final rows = await db.rawQuery(
      'SELECT m.*, i.name, i.icon, i.barcode, i.location_id, i.purchase_date, i.purchase_price, l.full_path location_full_path FROM medicines m JOIN items i ON i.id=m.item_id LEFT JOIN locations l ON i.location_id=l.id WHERE m.id=? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : Medicine.fromMap(rows.first);
  }

  Future<List<StorageLocation>> getLocations() async {
    final rows = await db.rawQuery(
      'SELECT l.*, COUNT(i.id) item_count, COALESCE(SUM(i.purchase_price),0) total_value FROM locations l LEFT JOIN items i ON i.location_id=l.id GROUP BY l.id ORDER BY l.level,l.sort_order',
    );
    return rows.map(StorageLocation.fromMap).toList();
  }

  Future<List<Category>> getCategories() async {
    final rows = await db.rawQuery(
      'SELECT c.*, COUNT(i.id) item_count FROM categories c LEFT JOIN items i ON i.category_id=c.id AND i.is_medicine=0 GROUP BY c.id ORDER BY c.sort_order',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<void> saveItem(Map<String, Object?> data, {String? id}) async {
    final now = DateTime.now().toIso8601String();
    final values = {...data, 'updated_at': now};
    if (id == null) {
      values.addAll({'id': _uuid.v4(), 'created_at': now, 'is_medicine': 0});
      await db.insert('items', values);
    } else {
      await db.update('items', values, where: 'id=?', whereArgs: [id]);
    }
  }

  Future<void> deleteItem(String id) =>
      db.delete('items', where: 'id=?', whereArgs: [id]);

  Future<Medicine?> recordDose(Medicine medicine, {double quantity = 1}) async {
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('medication_logs', {
        'id': _uuid.v4(),
        'medicine_id': medicine.id,
        'scheduled_at': '',
        'taken_at': now,
        'quantity': quantity,
        'status': 'taken',
        'created_at': now,
      });
      await txn.rawUpdate(
        'UPDATE medicines SET remaining_quantity=MAX(0, remaining_quantity-?), updated_at=? WHERE id=?',
        [quantity, now, medicine.id],
      );
    });
    return getMedicine(medicine.id);
  }

  Future<Medicine?> recordDoseById(
    String medicineId, {
    double quantity = 1,
  }) async {
    final medicine = await getMedicine(medicineId);
    if (medicine == null) return null;
    return recordDose(medicine, quantity: quantity);
  }

  Future<void> saveMedicine(
    Map<String, Object?> itemData,
    Map<String, Object?> medicineData, {
    String? itemId,
    String? medicineId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final resolvedItemId = itemId ?? _uuid.v4();
    final resolvedMedicineId = medicineId ?? _uuid.v4();
    await db.transaction((txn) async {
      if (itemId == null) {
        await txn.insert('items', {
          ...itemData,
          'id': resolvedItemId,
          'category_id': 'cat-medicine',
          'is_medicine': 1,
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await txn.update(
          'items',
          {...itemData, 'updated_at': now},
          where: 'id=?',
          whereArgs: [resolvedItemId],
        );
      }
      if (medicineId == null) {
        await txn.insert('medicines', {
          ...medicineData,
          'id': resolvedMedicineId,
          'item_id': resolvedItemId,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await txn.update(
          'medicines',
          {...medicineData, 'updated_at': now},
          where: 'id=?',
          whereArgs: [resolvedMedicineId],
        );
      }
    });
  }

  Future<void> deleteMedicine(Medicine medicine) => deleteItem(medicine.itemId);

  Future<Set<String>> getTakenMedicineIdsToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final rows = await db.rawQuery(
      'SELECT DISTINCT medicine_id FROM medication_logs WHERE status=? AND taken_at>=? AND taken_at<?',
      ['taken', start, end],
    );
    return rows.map((row) => '${row['medicine_id']}').toSet();
  }

  Future<void> saveLocation(
    String name, {
    String icon = '📍',
    String? parentId,
  }) async {
    final now = DateTime.now().toIso8601String();
    var level = 0, fullPath = name;
    if (parentId != null) {
      final rows = await db.query(
        'locations',
        where: 'id=?',
        whereArgs: [parentId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        level = ((rows.first['level'] as num?)?.toInt() ?? 0) + 1;
        fullPath = '${rows.first['full_path']} > $name';
      }
    }
    await db.insert('locations', {
      'id': _uuid.v4(),
      'name': name,
      'icon': icon,
      'parent_id': parentId,
      'full_path': fullPath,
      'level': level,
      'sort_order': DateTime.now().millisecondsSinceEpoch,
      'image_path': '',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateLocation(
    String id, {
    required String name,
    required String icon,
    String? parentId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      var level = 0;
      var fullPath = name;
      if (parentId != null) {
        final parents = await txn.query(
          'locations',
          columns: ['full_path', 'level'],
          where: 'id=?',
          whereArgs: [parentId],
          limit: 1,
        );
        if (parents.isEmpty) throw StateError('上级空间不存在');
        level = ((parents.first['level'] as num?)?.toInt() ?? 0) + 1;
        fullPath = '${parents.first['full_path']} > $name';
      }
      await txn.update(
        'locations',
        {
          'name': name,
          'icon': icon,
          'parent_id': parentId,
          'full_path': fullPath,
          'level': level,
          'updated_at': now,
        },
        where: 'id=?',
        whereArgs: [id],
      );
      await _updateChildLocationPaths(txn, id, fullPath, level, now);
    });
  }

  Future<void> _updateChildLocationPaths(
    DatabaseExecutor executor,
    String parentId,
    String parentPath,
    int parentLevel,
    String updatedAt,
  ) async {
    final children = await executor.query(
      'locations',
      columns: ['id', 'name'],
      where: 'parent_id=?',
      whereArgs: [parentId],
    );
    for (final child in children) {
      final childId = '${child['id']}';
      final childPath = '$parentPath > ${child['name']}';
      final childLevel = parentLevel + 1;
      await executor.update(
        'locations',
        {'full_path': childPath, 'level': childLevel, 'updated_at': updatedAt},
        where: 'id=?',
        whereArgs: [childId],
      );
      await _updateChildLocationPaths(
        executor,
        childId,
        childPath,
        childLevel,
        updatedAt,
      );
    }
  }

  Future<void> deleteLocation(String id) =>
      db.delete('locations', where: 'id=?', whereArgs: [id]);

  Future<String?> getSetting(String key) async {
    final rows = await db.query(
      'settings',
      where: 'key=?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : '${rows.first['value']}';
  }

  Future<void> setSetting(
    String key,
    String value, {
    Database? database,
  }) async {
    final target = database ?? db;
    final now = DateTime.now().toIso8601String();
    await target.insert('settings', {
      'key': key,
      'value': value,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> exportJson({String appVersion = ''}) async {
    final result = <String, Object?>{
      '__meta__': {
        'exported_at': DateTime.now().toIso8601String(),
        'version': appVersion.isEmpty ? 'unknown' : appVersion,
        'schema_version': schemaVersion,
      },
    };
    for (final table in [
      'categories',
      'locations',
      'items',
      'medicines',
      'medication_logs',
    ]) {
      result[table] = await db.query(table);
    }
    return const JsonEncoder.withIndent('  ').convert(result);
  }

  Future<(int, int)> importJson(String source) async {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    var success = 0, failed = 0;
    await db.transaction((txn) async {
      for (final table in [
        'categories',
        'locations',
        'items',
        'medicines',
        'medication_logs',
      ]) {
        final rows = decoded[table];
        if (rows is! List) continue;
        for (final row in rows) {
          try {
            await txn.insert(
              table,
              Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            success++;
          } catch (_) {
            failed++;
          }
        }
      }
    });
    return (success, failed);
  }
}
