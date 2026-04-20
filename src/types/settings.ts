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
