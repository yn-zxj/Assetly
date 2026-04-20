import { create } from 'zustand';
import * as locationService from '../services/locationService';
import type { Location, LocationTreeNode, LocationFormData } from '../types/location';

interface LocationState {
  locations: Location[];
  locationTree: LocationTreeNode[];
  loading: boolean;
  fetchLocations: () => Promise<void>;
  addLocation: (data: LocationFormData) => Promise<Location>;
  updateLocation: (id: string, name: string) => Promise<void>;
  deleteLocation: (id: string) => Promise<void>;
}

export const useLocationStore = create<LocationState>((set, get) => ({
  locations: [],
  locationTree: [],
  loading: false,

  fetchLocations: async () => {
    set({ loading: true });
    const locations = await locationService.getAllLocations();
    const locationTree = locationService.buildLocationTree(locations);
    set({ locations, locationTree, loading: false });
  },

  addLocation: async (data: LocationFormData) => {
    const location = await locationService.createLocation(data);
    await get().fetchLocations(); // Re-fetch to get updated tree
    return location;
  },

  updateLocation: async (id: string, data: Partial<LocationFormData>) => {
    await locationService.updateLocation(id, data);
    await get().fetchLocations();
  },

  deleteLocation: async (id: string) => {
    await locationService.deleteLocation(id);
    await get().fetchLocations();
  },
}));
