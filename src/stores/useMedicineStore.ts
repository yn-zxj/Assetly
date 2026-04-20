import { create } from 'zustand';
import * as medicineService from '../services/medicineService';
import type { MedicineWithItem, MedicineFormData, MedicineType } from '../types/medicine';

interface MedicineState {
  medicines: MedicineWithItem[];
  loading: boolean;
  activeTab: MedicineType | 'all';
  fetchMedicines: () => Promise<void>;
  addMedicine: (data: MedicineFormData) => Promise<void>;
  updateMedicine: (itemId: string, data: Partial<MedicineFormData>) => Promise<void>;
  setActiveTab: (tab: MedicineType | 'all') => void;
}

export const useMedicineStore = create<MedicineState>((set, get) => ({
  medicines: [],
  loading: false,
  activeTab: 'all',

  fetchMedicines: async () => {
    set({ loading: true });
    const tab = get().activeTab;
    const filter = tab !== 'all' ? { type: tab } : undefined;
    const medicines = await medicineService.getAllMedicines(filter);
    set({ medicines, loading: false });
  },

  addMedicine: async (data: MedicineFormData) => {
    await medicineService.createMedicine(data);
    await get().fetchMedicines();
  },

  updateMedicine: async (itemId: string, data: Partial<MedicineFormData>) => {
    await medicineService.updateMedicine(itemId, data);
    await get().fetchMedicines();
  },

  setActiveTab: (tab: MedicineType | 'all') => {
    set({ activeTab: tab });
  },
}));
