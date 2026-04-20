// Medicine types

export type MedicineType = 'internal' | 'external' | 'emergency';
export type ExpiryStatus = 'safe' | 'warning' | 'expired';
export type FrequencyType = 'daily' | 'every_n_days' | 'weekly';

export interface Medicine {
  id: string;
  item_id: string;
  medicine_type: MedicineType;
  expiry_date: string;
  dosage_instructions: string;
  remaining_quantity: number;
  unit: string;
  manufacturer: string;
  // Medication reminder fields
  is_taking: boolean;
  frequency_type: FrequencyType;
  frequency_days: number;
  week_days: string; // comma-separated days, e.g., "1,3,5"
  time_slots: string; // comma-separated times, e.g., "08:00,20:00"
  duration_start: string; // start date of medication period
  duration_end: string; // end date of medication period
  last_reminded: string;
  created_at: string;
  updated_at: string;
}

export interface MedicineWithItem extends Medicine {
  name: string;
  description: string;
  category_id: string;
  location_id: string;
  purchase_date: string;
  purchase_price: number;
  quantity: number;
  image_path: string;
  status: string;
  icon: string;
  location_full_path?: string;
}

export interface MedicineFormData {
  // Item fields
  name: string;
  description: string;
  category_id: string;
  location_id: string;
  purchase_date: string;
  purchase_price: number;
  quantity: number;
  image_path: string;
  icon: string;
  // Medicine fields
  medicine_type: MedicineType;
  expiry_date: string;
  dosage_instructions: string;
  remaining_quantity: number;
  unit: string;
  manufacturer: string;
  // Medication reminder fields
  is_taking: boolean;
  frequency_type: FrequencyType;
  frequency_days: number;
  week_days: string;
  time_slots: string;
  duration_start: string;
  duration_end: string;
}
