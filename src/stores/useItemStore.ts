import { create } from 'zustand';
import * as itemService from '../services/itemService';
import type { ItemWithDetails, ItemFormData } from '../types/item';

interface ItemFilter {
  category_id?: string;
  location_id?: string;
  status?: string;
  search?: string;
}

interface ItemState {
  items: ItemWithDetails[];
  loading: boolean;
  filter: ItemFilter;
  fetchItems: () => Promise<void>;
  addItem: (data: ItemFormData) => Promise<void>;
  updateItem: (id: string, data: Partial<ItemFormData>) => Promise<void>;
  deleteItem: (id: string) => Promise<void>;
  setFilter: (filter: Partial<ItemFilter>) => void;
}

export const useItemStore = create<ItemState>((set, get) => ({
  items: [],
  loading: false,
  filter: {},

  fetchItems: async () => {
    set({ loading: true });
    const items = await itemService.getAllItems(get().filter);
    set({ items, loading: false });
  },

  addItem: async (data: ItemFormData) => {
    await itemService.createItem(data);
    await get().fetchItems();
  },

  updateItem: async (id: string, data: Partial<ItemFormData>) => {
    await itemService.updateItem(id, data);
    await get().fetchItems();
  },

  deleteItem: async (id: string) => {
    await itemService.deleteItem(id);
    await get().fetchItems();
  },

  setFilter: (filter: Partial<ItemFilter>) => {
    set({ filter: { ...get().filter, ...filter } });
  },
}));
