import { create } from 'zustand';
import { getDb } from '../services/database';
import { getNow } from '../utils/dateHelper';
import type { AISettings, WebDAVSettings } from '../types/settings';

interface SettingsState extends AISettings, WebDAVSettings {
  themeColor: string;
  currencySymbol: string;
  loaded: boolean;
  loadSettings: () => Promise<void>;
  setThemeColor: (color: string) => Promise<void>;
  setCurrencySymbol: (symbol: string) => Promise<void>;
  setAIEnabled: (enabled: boolean) => Promise<void>;
  setAIModelMode: (mode: 'single' | 'separate') => Promise<void>;
  setAIApiUrl: (url: string) => Promise<void>;
  setAIApiKey: (key: string) => Promise<void>;
  setAITextModel: (model: string) => Promise<void>;
  setAIVisionApiUrl: (url: string) => Promise<void>;
  setAIVisionApiKey: (key: string) => Promise<void>;
  setAIVisionModel: (model: string) => Promise<void>;
  setWebDAVEnabled: (enabled: boolean) => Promise<void>;
  setWebDAVServerUrl: (url: string) => Promise<void>;
  setWebDAVUsername: (username: string) => Promise<void>;
  setWebDAVPassword: (password: string) => Promise<void>;
  setWebDAVRemotePath: (path: string) => Promise<void>;
  setWebDAVLastSyncAt: (time: string) => Promise<void>;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  themeColor: '#22C55E',
  currencySymbol: '¥',
  ai_enabled: false,
  ai_model_mode: 'single',
  ai_api_url: 'https://api.openai.com/v1',
  ai_api_key: '',
  ai_text_model: 'gpt-4o-mini',
  ai_vision_api_url: 'https://api.openai.com/v1',
  ai_vision_api_key: '',
  ai_vision_model: 'gpt-4o',
  webdav_enabled: false,
  webdav_server_url: '',
  webdav_username: '',
  webdav_password: '',
  webdav_remote_path: '/assetly-backup.json',
  webdav_last_sync_at: '',
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
      ai_model_mode: settings.ai_model_mode === 'separate' ? 'separate' : 'single',
      ai_api_url: settings.ai_api_url || 'https://api.openai.com/v1',
      ai_api_key: settings.ai_api_key || '',
      ai_text_model: settings.ai_text_model || 'gpt-4o-mini',
      ai_vision_api_url: settings.ai_vision_api_url || 'https://api.openai.com/v1',
      ai_vision_api_key: settings.ai_vision_api_key || '',
      ai_vision_model: settings.ai_vision_model || 'gpt-4o',
      webdav_enabled: String(settings.webdav_enabled) === 'true',
      webdav_server_url: settings.webdav_server_url || '',
      webdav_username: settings.webdav_username || '',
      webdav_password: settings.webdav_password || '',
      webdav_remote_path: settings.webdav_remote_path || '/assetly-backup.json',
      webdav_last_sync_at: settings.webdav_last_sync_at || '',
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

  setAIModelMode: async (mode: 'single' | 'separate') => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_model_mode', $1, $2)",
      [JSON.stringify(mode), getNow()]
    );
    set({ ai_model_mode: mode });
  },

  setAIVisionApiUrl: async (url: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_vision_api_url', $1, $2)",
      [JSON.stringify(url), getNow()]
    );
    set({ ai_vision_api_url: url });
  },

  setAIVisionApiKey: async (key: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_vision_api_key', $1, $2)",
      [JSON.stringify(key), getNow()]
    );
    set({ ai_vision_api_key: key });
  },

  setAIVisionModel: async (model: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('ai_vision_model', $1, $2)",
      [JSON.stringify(model), getNow()]
    );
    set({ ai_vision_model: model });
  },

  setWebDAVEnabled: async (enabled: boolean) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_enabled', $1, $2)",
      [JSON.stringify(enabled), getNow()]
    );
    set({ webdav_enabled: enabled });
  },

  setWebDAVServerUrl: async (url: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_server_url', $1, $2)",
      [JSON.stringify(url), getNow()]
    );
    set({ webdav_server_url: url });
  },

  setWebDAVUsername: async (username: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_username', $1, $2)",
      [JSON.stringify(username), getNow()]
    );
    set({ webdav_username: username });
  },

  setWebDAVPassword: async (password: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_password', $1, $2)",
      [JSON.stringify(password), getNow()]
    );
    set({ webdav_password: password });
  },

  setWebDAVRemotePath: async (path: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_remote_path', $1, $2)",
      [JSON.stringify(path), getNow()]
    );
    set({ webdav_remote_path: path });
  },

  setWebDAVLastSyncAt: async (time: string) => {
    const db = await getDb();
    await db.execute(
      "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_last_sync_at', $1, $2)",
      [JSON.stringify(time), getNow()]
    );
    set({ webdav_last_sync_at: time });
  },
}));
