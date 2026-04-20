import { create } from 'zustand';
import { getDb } from '../services/database';
import { getNow } from '../utils/dateHelper';

interface SettingsState {
  themeColor: string;
  currencySymbol: string;
  loaded: boolean;
  loadSettings: () => Promise<void>;
  setThemeColor: (color: string) => Promise<void>;
  setCurrencySymbol: (symbol: string) => Promise<void>;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  themeColor: '#22C55E',
  currencySymbol: '¥',
  loaded: false,

  loadSettings: async () => {
    const db = await getDb();
    const rows = await db.select<{ key: string; value: string }[]>('SELECT * FROM settings');
    const settings: Record<string, string> = {};
    for (const row of rows) {
      try {
        settings[row.key] = JSON.parse(row.value);
      } catch {
        settings[row.key] = row.value;
      }
    }
    set({
      themeColor: settings.theme_color || '#22C55E',
      currencySymbol: settings.currency_symbol || '¥',
      loaded: true,
    });
  },

  setThemeColor: async (color: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('theme_color', $1, $2)",
      [JSON.stringify(color), getNow()]
    );
    set({ themeColor: color });
    document.documentElement.style.setProperty('--color-primary', color);
  },

  setCurrencySymbol: async (symbol: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('currency_symbol', $1, $2)",
      [JSON.stringify(symbol), getNow()]
    );
    set({ currencySymbol: symbol });
  },
}));
