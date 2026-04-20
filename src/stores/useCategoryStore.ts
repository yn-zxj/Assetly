import { create } from 'zustand';
import * as categoryService from '../services/categoryService';
import type { Category, CategoryFormData } from '../types/category';

interface CategoryState {
  categories: Category[];
  loading: boolean;
  fetchCategories: () => Promise<void>;
  addCategory: (data: CategoryFormData) => Promise<Category>;
  updateCategory: (id: string, data: CategoryFormData) => Promise<void>;
  deleteCategory: (id: string) => Promise<void>;
}

export const useCategoryStore = create<CategoryState>((set, get) => ({
  categories: [],
  loading: false,

  fetchCategories: async () => {
    set({ loading: true });
    const categories = await categoryService.getAllCategories();
    set({ categories, loading: false });
  },

  addCategory: async (data: CategoryFormData) => {
    const category = await categoryService.createCategory(data);
    set({ categories: [...get().categories, category] });
    return category;
  },

  updateCategory: async (id: string, data: CategoryFormData) => {
    await categoryService.updateCategory(id, data);
    set({
      categories: get().categories.map((c) =>
        c.id === id ? { ...c, ...data, updated_at: new Date().toISOString() } : c
      ),
    });
  },

  deleteCategory: async (id: string) => {
    await categoryService.deleteCategory(id);
    set({ categories: get().categories.filter((c) => c.id !== id) });
  },
}));
