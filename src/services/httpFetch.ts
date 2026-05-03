import { fetch as tauriFetch } from '@tauri-apps/plugin-http';
import { logInfo, logWarn } from '../utils/logger';

/**
 * 返回可用于 LangChain/OpenAI SDK 的 fetch 实现。
 *
 * 在 Tauri WebView 中运行时返回原生 HTTP 客户端的 fetch，
 * 避免浏览器 CORS 预检（dev 模式下 http://localhost:1420 会被
 * 外部 API 的 CORS 策略拒绝）。
 *
 * 非 Tauri 环境（例如浏览器直接打开 vite 页面）回退到全局 fetch。
 *
 * 说明：tauri-plugin-http 的请求走 Rust 侧 reqwest，**不经过 WebView 网络栈**，
 * 所以 DevTools Network 面板抓不到。为了调试方便，这里统一包一层日志，
 * 将 method/url/status/耗时打印到 app 日志里（app 内"日志"页面即可查看）。
 */
export function getHttpFetch(): typeof fetch {
  const isTauri =
    typeof window !== 'undefined' &&
    (Boolean((window as any).__TAURI_INTERNALS__) || Boolean((window as any).__TAURI__));
  const raw = isTauri ? (tauriFetch as unknown as typeof fetch) : fetch.bind(globalThis);
  return withLogging(raw, isTauri ? 'tauri-http' : 'browser-fetch');
}

function withLogging(fetchImpl: typeof fetch, tag: string): typeof fetch {
  return async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const t0 = Date.now();
    const method = (init?.method || 'GET').toUpperCase();
    const url = typeof input === 'string' ? input : input instanceof URL ? input.toString() : (input as Request).url;
    const bodySize = estimateBodySize(init?.body);
    logInfo(`[HTTP] → ${method} ${url} (body ${bodySize})`, tag);
    try {
      const resp = await fetchImpl(input, init);
      const cost = Date.now() - t0;
      const contentType = resp.headers.get('content-type') || '';
      const contentLen = resp.headers.get('content-length') || '-';
      logInfo(`[HTTP] ← ${resp.status} ${method} ${url} (${cost}ms, ${contentType}, len=${contentLen})`, tag);
      return resp;
    } catch (err) {
      const cost = Date.now() - t0;
      logWarn(`[HTTP] ✗ ${method} ${url} (${cost}ms): ${(err as Error)?.message || String(err)}`, tag);
      throw err;
    }
  };
}

function estimateBodySize(body: unknown): string {
  if (!body) return '0';
  if (typeof body === 'string') return `${body.length}ch`;
  if (body instanceof ArrayBuffer) return `${body.byteLength}B`;
  if (body instanceof Blob) return `${body.size}B`;
  if (body instanceof FormData) return 'FormData';
  if (body instanceof URLSearchParams) return `${body.toString().length}ch`;
  return 'unknown';
}
