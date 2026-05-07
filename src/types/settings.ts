// Settings types

export interface AppSettings {
  theme_color: string;
  currency_symbol: string;
}

export interface DashboardStats {
  total_items: number;
  total_value: number;
  medicine_count: number;
  expiring_count: number;
}

export interface CategoryDistribution {
  name: string;
  value: number;
  color: string;
}

export interface MonthlySpending {
  month: string;
  amount: number;
}

export interface WebDAVSettings {
  webdav_enabled: boolean;
  webdav_server_url: string;
  webdav_username: string;
  webdav_password: string;
  webdav_remote_path: string;
  webdav_last_sync_at: string;
}

export interface AISettings {
  ai_enabled: boolean;
  ai_model_mode: 'single' | 'separate';
  // Text model config
  ai_api_url: string;
  ai_api_key: string;
  ai_text_model: string;
  // Vision model config (used when ai_model_mode === 'separate')
  ai_vision_api_url: string;
  ai_vision_api_key: string;
  ai_vision_model: string;
}

export interface AIRecognitionResult {
  item_type: 'item' | 'medicine';
  name: string;
  description: string;
  category_id: string;
  location_id: string;
  purchase_date: string;
  purchase_price: number;
  quantity: number;
  // item fields
  warranty_expiry?: string;
  shelf_life_expiry?: string;
  // medicine fields
  medicine_type?: string;
  expiry_date?: string;
  dosage_instructions?: string;
  remaining_quantity?: number;
  unit?: string;
  manufacturer?: string;
  // meta
  confidence: number;
}
