import { getDb } from './database';
import { getNow } from '../utils/dateHelper';
import type { Location, LocationTreeNode, LocationFormData } from '../types/location';

function generateId(): string {
  return crypto.randomUUID();
}

export async function getAllLocations(): Promise<Location[]> {
  const db = await getDb();
  return db.select<Location[]>('SELECT * FROM locations ORDER BY level ASC, sort_order ASC');
}

export async function getLocationById(id: string): Promise<Location | null> {
  const db = await getDb();
  const rows = await db.select<Location[]>('SELECT * FROM locations WHERE id = $1', [id]);
  return rows[0] ?? null;
}

export async function createLocation(data: LocationFormData): Promise<Location> {
  const db = await getDb();
  const now = getNow();
  const id = generateId();

  let fullPath = data.name;
  let level = 0;

  if (data.parent_id) {
    const parent = await getLocationById(data.parent_id);
    if (parent) {
      fullPath = `${parent.full_path}/${data.name}`;
      level = parent.level + 1;
    }
  }

  const maxOrder = await db.select<{ max_order: number }[]>(
    'SELECT COALESCE(MAX(sort_order), -1) as max_order FROM locations WHERE parent_id IS $1',
    [data.parent_id]
  );
  const sortOrder = (maxOrder[0]?.max_order ?? -1) + 1;

  await db.execute(
    'INSERT INTO locations (id, name, parent_id, full_path, level, sort_order, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
    [id, data.name, data.parent_id, fullPath, level, sortOrder, now, now]
  );

  return {
    id, name: data.name, parent_id: data.parent_id,
    full_path: fullPath, level, sort_order: sortOrder,
    image_path: '',
    created_at: now, updated_at: now,
  };
}

export async function updateLocation(id: string, data: Partial<LocationFormData>): Promise<void> {
  const db = await getDb();
  const loc = await getLocationById(id);
  if (!loc) return;

  const now = getNow();
  const name = data.name ?? loc.name;
  let newFullPath: string;
  if (loc.parent_id) {
    const parent = await getLocationById(loc.parent_id);
    newFullPath = parent ? `${parent.full_path}/${name}` : name;
  } else {
    newFullPath = name;
  }

  await db.execute(
    'UPDATE locations SET name = $1, full_path = $2, image_path = COALESCE($3, image_path), updated_at = $4 WHERE id = $5',
    [name, newFullPath, data.image_path, now, id]
  );

  // Update children's full_path
  await updateChildrenPaths(db, id, newFullPath);
}

async function updateChildrenPaths(db: Awaited<ReturnType<typeof getDb>>, parentId: string, parentPath: string): Promise<void> {
  const children = await db.select<Location[]>(
    'SELECT * FROM locations WHERE parent_id = $1',
    [parentId]
  );
  for (const child of children) {
    const newPath = `${parentPath}/${child.name}`;
    await db.execute(
      'UPDATE locations SET full_path = $1, updated_at = $2 WHERE id = $3',
      [newPath, getNow(), child.id]
    );
    await updateChildrenPaths(db, child.id, newPath);
  }
}

export async function deleteLocation(id: string): Promise<void> {
  const db = await getDb();
  // Move children to parent's parent
  const loc = await getLocationById(id);
  if (!loc) return;

  // Delete all descendant locations
  const descendants = await getDescendants(db, id);
  for (const desc of descendants) {
    await db.execute("UPDATE items SET location_id = '' WHERE location_id = $1", [desc.id]);
    await db.execute('DELETE FROM locations WHERE id = $1', [desc.id]);
  }

  await db.execute("UPDATE items SET location_id = '' WHERE location_id = $1", [id]);
  await db.execute('DELETE FROM locations WHERE id = $1', [id]);
}

async function getDescendants(db: Awaited<ReturnType<typeof getDb>>, parentId: string): Promise<Location[]> {
  const children = await db.select<Location[]>(
    'SELECT * FROM locations WHERE parent_id = $1',
    [parentId]
  );
  let all: Location[] = [...children];
  for (const child of children) {
    const grandChildren = await getDescendants(db, child.id);
    all = all.concat(grandChildren);
  }
  return all;
}

export function buildLocationTree(locations: Location[]): LocationTreeNode[] {
  const map = new Map<string, LocationTreeNode>();
  const roots: LocationTreeNode[] = [];

  for (const loc of locations) {
    map.set(loc.id, { ...loc, children: [] });
  }

  for (const loc of locations) {
    const node = map.get(loc.id)!;
    if (loc.parent_id && map.has(loc.parent_id)) {
      map.get(loc.parent_id)!.children.push(node);
    } else {
      roots.push(node);
    }
  }

  return roots;
}
