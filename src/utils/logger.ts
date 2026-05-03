import { info, error, warn, debug } from '@tauri-apps/plugin-log';

/**
 * Initialize logger.
 *
 * 注意：早期版本在这里 hook 了 console.*，将所有 console 输出转发到 Tauri log。
 * 但 tauri-plugin-log 默认的 Webview target 会将 Rust 侧日志反向打到 webview 的 console，
 * 造成每条 logInfo/logError 在终端和 webview console 重复打印一次。
 * 所以我们不再 hook console，统一通过 logInfo/logError 函数调用 Tauri log。
 */
export function initLogger() {
  // no-op：不再拦截 console，避免与 plugin-log 的 Webview target 形成回环重复。
}

/**
 * Log levels
 */
export type LogLevel = 'trace' | 'debug' | 'info' | 'warn' | 'error';

/**
 * Structured log entry
 */
export interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  source?: string;
}

const MAX_MEMORY_LOGS = 500;
const memoryLogs: LogEntry[] = [];

function addMemoryLog(level: LogLevel, message: string, source?: string) {
  memoryLogs.unshift({
    timestamp: new Date().toISOString(),
    level,
    message,
    source,
  });
  if (memoryLogs.length > MAX_MEMORY_LOGS) {
    memoryLogs.pop();
  }
}

export async function logInfo(message: string, source?: string) {
  addMemoryLog('info', message, source);
  await info(`[${source || 'app'}] ${message}`);
}

export async function logError(message: string, source?: string) {
  addMemoryLog('error', message, source);
  await error(`[${source || 'app'}] ${message}`);
}

export async function logWarn(message: string, source?: string) {
  addMemoryLog('warn', message, source);
  await warn(`[${source || 'app'}] ${message}`);
}

export async function logDebug(message: string, source?: string) {
  addMemoryLog('debug', message, source);
  await debug(`[${source || 'app'}] ${message}`);
}

export function getMemoryLogs(): LogEntry[] {
  return [...memoryLogs];
}

export function clearMemoryLogs() {
  memoryLogs.length = 0;
}
