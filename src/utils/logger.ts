import { info, error, warn, debug, trace } from '@tauri-apps/plugin-log';

/**
 * Forward console logs to Tauri log plugin.
 * Call this once at app startup.
 */
export function initLogger() {
  const forwardConsole = (
    fnName: 'log' | 'debug' | 'info' | 'warn' | 'error',
    logger: (message: string) => Promise<void>
  ) => {
    const original = console[fnName];
    console[fnName] = (...args: unknown[]) => {
      original(...args);
      const message = args.map((a) => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' ');
      logger(message).catch(() => {});
    };
  };

  forwardConsole('log', trace);
  forwardConsole('debug', debug);
  forwardConsole('info', info);
  forwardConsole('warn', warn);
  forwardConsole('error', error);
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
