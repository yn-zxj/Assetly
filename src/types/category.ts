// Category types

export interface Category {
  id: string;
  name: string;
  icon: string;
  color: string;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface CategoryFormData {
  name: string;
  icon: string;
  color: string;
}
