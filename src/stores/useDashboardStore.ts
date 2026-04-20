import { create } from 'zustand';
import * as statisticsService from '../services/statisticsService';
import * as medicineService from '../services/medicineService';
import type { DashboardStats, CategoryDistribution, MonthlySpending } from '../types/settings';
import type { MedicineWithItem } from '../types/medicine';

interface DashboardState {
  stats: DashboardStats;
  categoryDistribution: CategoryDistribution[];
  monthlySpending: MonthlySpending[];
  expiringMedicines: MedicineWithItem[];
  loading: boolean;
  fetchDashboardData: () => Promise<void>;
}

export const useDashboardStore = create<DashboardState>((set) => ({
  stats: { total_items: 0, total_value: 0, medicine_count: 0, expiring_count: 0 },
  categoryDistribution: [],
  monthlySpending: [],
  expiringMedicines: [],
  loading: false,

  fetchDashboardData: async () => {
    set({ loading: true });
    const [stats, categoryDistribution, monthlySpending, expiringMedicines] = await Promise.all([
      statisticsService.getDashboardStats(),
      statisticsService.getCategoryDistribution(),
      statisticsService.getMonthlySpending(6),
      medicineService.getExpiringMedicines(30),
    ]);
    set({ stats, categoryDistribution, monthlySpending, expiringMedicines, loading: false });
  },
}));
