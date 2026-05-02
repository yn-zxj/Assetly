import { create } from 'zustand';
import { getDb } from '../services/database';
import { getNow } from '../utils/dateHelper';
import type { AISettings } from '../types/settings';

interface SettingsState extends AISettings {
  themeColor: string;
  currencySymbol: string;
  loaded: boolean;
  loadSettings: () => Promise<void>;
  setThemeColor: (color: string) => Promise<void>;
  setCurrencySymbol: (symbol: string) => Promise<void>;
  setAIEnabled: (enabled: boolean) => Promise<void>;
  setAIApiUrl: (url: string) => Promise<void>;
  setAIApiKey: (key: string) => Promise<void>;
  setAITextModel: (model: string) => Promise<void>;
  setAIVisionModel: (model: string) => Promise<void>;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  themeColor: '#22C55E',
  currencySymbol: '¥',
  ai_enabled: false,
  ai_api_url: 'https://api.openai.com/v1',
  ai_api_key: '',
  ai_text_model: 'gpt-4o-mini',
  ai_vision_model: 'gpt-4o',
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
      ai_enabled: String(settings.ai_enabled) === 'true',
      ai_api_url: settings.ai_api_url || 'https://api.openai.com/v1',
      ai_api_key: settings.ai_api_key || '',
      ai_text_model: settings.ai_text_model || 'gpt-4o-mini',
      ai_vision_model: settings.ai_vision_model || 'gpt-4o',
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

  setAIEnabled: async (enabled: boolean) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_enabled', $1, $2)",
      [JSON.stringify(enabled), getNow()]
    );
    set({ ai_enabled: enabled });
  },

  setAIApiUrl: async (url: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_api_url', $1, $2)",
      [JSON.stringify(url), getNow()]
    );
    set({ ai_api_url: url });
  },

  setAIApiKey: async (key: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_api_key', $1, $2)",
      [JSON.stringify(key), getNow()]
    );
    set({ ai_api_key: key });
  },

  setAITextModel: async (model: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_text_model', $1, $2)",
      [JSON.stringify(model), getNow()]
    );
    set({ ai_text_model: model });
  },

  setAIVisionModel: async (model: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_vision_model', $1, $2)",
      [JSON.stringify(model), getNow()]
    );
    set({ ai_vision_model: model });
  },
}));
