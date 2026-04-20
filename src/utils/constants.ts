import { type Category } from '../types/category';

// Default categories with icons and colors
export const DEFAULT_CATEGORIES: Omit<Category, 'id' | 'created_at' | 'updated_at'>[] = [
  { name: '电子产品', icon: 'Smartphone', color: '#3B82F6', sort_order: 0 },
  { name: '家具家电', icon: 'Sofa', color: '#8B5CF6', sort_order: 1 },
  { name: '厨房用品', icon: 'CookingPot', color: '#F97316', sort_order: 2 },
  { name: '衣物鞋包', icon: 'Shirt', color: '#EC4899', sort_order: 3 },
  { name: '书籍文具', icon: 'BookOpen', color: '#06B6D4', sort_order: 4 },
  { name: '药品保健', icon: 'Pill', color: '#22C55E', sort_order: 5 },
  { name: '工具耗材', icon: 'Wrench', color: '#78716C', sort_order: 6 },
  { name: '其他', icon: 'Package', color: '#6B7280', sort_order: 7 },
];

// Medicine type labels
export const MEDICINE_TYPE_LABELS: Record<string, string> = {
  internal: '内服',
  external: '外用',
  emergency: '急救',
};

// Item status labels
export const ITEM_STATUS_LABELS: Record<string, string> = {
  active: '服役中',
  archived: '已闲置',
  disposed: '已处置',
};

// Theme color presets
export const THEME_PRESETS = [
  { name: '活力绿', color: '#22C55E' },
  { name: '天蓝', color: '#3B82F6' },
  { name: '珊瑚橙', color: '#F97316' },
  { name: '薰衣紫', color: '#A855F7' },
  { name: '玫瑰粉', color: '#EC4899' },
];

// Currency symbols
export const CURRENCY_OPTIONS = ['¥', '$', '€', '£', '₩'];
