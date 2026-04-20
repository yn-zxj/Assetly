// Location types

export interface Location {
  id: string;
  name: string;
  parent_id: string | null;
  full_path: string;
  level: number;
  sort_order: number;
  image_path: string;
  created_at: string;
  updated_at: string;
}

export interface LocationTreeNode extends Location {
  children: LocationTreeNode[];
}

export interface LocationFormData {
  name: string;
  parent_id: string | null;
  image_path: string;
}
