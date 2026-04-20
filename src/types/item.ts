// Item types

export type ItemStatus = 'active' | 'archived' | 'disposed';

export interface Item {
  id: string;
  name: string;
  description: string;
  category_id: string;
  location_id: string;
  purchase_date: string;
  purchase_price: number;
  quantity: number;
  image_path: string;
  icon: string;
  status: ItemStatus;
  is_medicine: number; // 0 or 1
  warranty_expiry: string; // warranty expiry date
  shelf_life_expiry: string; // shelf life expiry date
  created_at: string;
  updated_at: string;
}

export interface ItemWithDetails extends Item {
  category_name?: string;
  category_icon?: string;
  category_color?: string;
  location_full_path?: string;
}

export interface ItemFormData {
  name: string;
  description: string;
  category_id: string;
  location_id: string;
  purchase_date: string;
  purchase_price: number;
  quantity: number;
  image_path: string;
  icon: string;
  status: ItemStatus;
  is_medicine: boolean;
  warranty_expiry: string;
  shelf_life_expiry: string;
}
