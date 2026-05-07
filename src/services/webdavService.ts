import { fetch as tauriFetch } from '@tauri-apps/plugin-http';
import { exportToJSON, importFromJSON } from './exportService';
import { logInfo } from '../utils/logger';
import { getDb } from './database';
import { getNow } from '../utils/dateHelper';

function getFetch() {
  const isTauri =
    typeof window !== 'undefined' &&
    (Boolean((window as any).__TAURI_INTERNALS__) || Boolean((window as any).__TAURI__));
  return isTauri ? (tauriFetch as unknown as typeof fetch) : fetch.bind(globalThis);
}

function authHeader(username: string, password: string): string {
  return 'Basic ' + btoa(`${username}:${password}`);
}

function buildPropfindBody(): string {
  return `<?xml version="1.0" encoding="utf-8"?>
<D:propfind xmlns:D="DAV:">
  <D:allprop/>
</D:propfind>`;
}

async function webdavRequest(
  url: string,
  method: string,
  username: string,
  password: string,
  body?: string | Uint8Array,
  extraHeaders?: Record<string, string>,
): Promise<Response> {
  const f = getFetch();
  const headers: Record<string, string> = {
    Authorization: authHeader(username, password),
    ...extraHeaders,
  };
  if (body && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/xml; charset=utf-8';
  }
  return f(url, { method, headers, body: body as BodyInit | undefined });
}

export async function testWebDAVConnection(
  serverUrl: string,
  username: string,
  password: string,
  remotePath: string,
): Promise<string> {
  if (!serverUrl) return '测试失败: 未填写服务器地址';
  if (!username) return '测试失败: 未填写用户名';
  if (!password) return '测试失败: 未填写密码';

  try {
    const dirPath = remotePath.substring(0, remotePath.lastIndexOf('/')) || '/';
    const url = serverUrl.replace(/\/+$/, '') + dirPath;

    logInfo(`WebDAV 测试连接: PROPFIND ${url}`, 'WebDAV');

    const resp = await webdavRequest(url, 'PROPFIND', username, password, buildPropfindBody(), {
      Depth: '1',
    });

    if (resp.ok || resp.status === 207) {
      return '连接成功';
    }
    if (resp.status === 401) {
      return '连接失败: 认证失败，请检查用户名和密码';
    }
    return `连接失败: HTTP ${resp.status}`;
  } catch (err) {
    const e = err as Error;
    return `连接失败: ${e.message}`;
  }
}

export async function uploadToWebDAV(
  serverUrl: string,
  username: string,
  password: string,
  remotePath: string,
): Promise<void> {
  if (!serverUrl || !username || !password) {
    throw new Error('WebDAV 配置不完整');
  }

  const jsonData = await exportToJSON();
  const baseUrl = serverUrl.replace(/\/+$/, '');
  const normalizedPath = remotePath.startsWith('/') ? remotePath : `/${remotePath}`;
  const fileUrl = baseUrl + normalizedPath;

  logInfo(`WebDAV 上传开始: PUT ${fileUrl} (${jsonData.length} 字符)`, 'WebDAV');

  // Ensure parent directories exist (only for non-root paths)
  const dirPath = normalizedPath.substring(0, normalizedPath.lastIndexOf('/'));
  if (dirPath) {
    const segments = dirPath.split('/').filter(Boolean);
    let current = '';
    for (const seg of segments) {
      current += '/' + seg;
      const dirUrl = baseUrl + current;
      try {
        const r = await webdavRequest(dirUrl, 'MKCOL', username, password);
        logInfo(`MKCOL ${dirUrl} -> ${r.status}`, 'WebDAV');
      } catch (e) {
        logInfo(`MKCOL ${dirUrl} 异常 (忽略): ${(e as Error).message}`, 'WebDAV');
      }
    }
  }

  // Encode body as bytes so Content-Length is correct for non-ASCII content
  const bodyBytes = new TextEncoder().encode(jsonData);
  const resp = await webdavRequest(fileUrl, 'PUT', username, password, bodyBytes, {
    'Content-Type': 'application/json; charset=utf-8',
  });

  if (!resp.ok && resp.status !== 201 && resp.status !== 204) {
    let detail = '';
    try {
      detail = (await resp.text()).slice(0, 200);
    } catch {
      // ignore
    }
    throw new Error(`HTTP ${resp.status}${detail ? ` - ${detail}` : ''}`);
  }

  logInfo(`WebDAV 上传完成 (${resp.status})`, 'WebDAV');
}

export async function downloadFromWebDAV(
  serverUrl: string,
  username: string,
  password: string,
  remotePath: string,
): Promise<{ success: number; failed: number; errors: string[] }> {
  if (!serverUrl || !username || !password) {
    throw new Error('WebDAV 配置不完整');
  }

  logInfo(`WebDAV 下载开始: ${remotePath}`, 'WebDAV');

  const baseUrl = serverUrl.replace(/\/+$/, '');
  const fileUrl = baseUrl + remotePath;

  // Check if file exists via HEAD
  const headResp = await webdavRequest(fileUrl, 'HEAD', username, password);
  if (headResp.status === 404) {
    throw new Error('远程备份文件不存在，请先执行上传备份');
  }

  // Download content
  const resp = await webdavRequest(fileUrl, 'GET', username, password);
  if (!resp.ok) {
    throw new Error(`下载失败: HTTP ${resp.status}`);
  }

  const content = await resp.text();

  logInfo(`WebDAV 下载完成 (${content.length} 字符)`, 'WebDAV');

  return importFromJSON(content);
}

export async function getRemoteBackupTime(
  serverUrl: string,
  username: string,
  password: string,
  remotePath: string,
): Promise<string | null> {
  if (!serverUrl || !username || !password) return null;
  try {
    const baseUrl = serverUrl.replace(/\/+$/, '');
    const fileUrl = baseUrl + remotePath;
    const resp = await webdavRequest(fileUrl, 'GET', username, password);
    if (!resp.ok) return null;
    const content = await resp.text();
    const data = JSON.parse(content);
    return data?.__meta__?.exported_at ?? null;
  } catch {
    return null;
  }
}

export async function updateLastSyncTime(): Promise<void> {
  const db = await getDb();
  const now = getNow();
  await db.execute(
    "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES ('webdav_last_sync_at', $1, $2)",
    [JSON.stringify(now), now]
  );
}
