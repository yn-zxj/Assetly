import { useState, useRef } from 'react';
import dayjs from 'dayjs';
import { Download, Upload, Check, Palette, DollarSign, Info, FileJson, ScrollText, Share2, Sparkles, Eye, EyeOff, Loader2, Zap, Cloud, CloudUpload, CloudDownload, ChevronDown, ChevronRight, Sun, Moon, Monitor } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useSettingsStore } from '../stores/useSettingsStore';
import { exportToJSON, importFromJSON } from '../services/exportService';
import { THEME_PRESETS, CURRENCY_OPTIONS } from '../utils/constants';
import { ChatOpenAI } from '@langchain/openai';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import { getHttpFetch } from '../services/httpFetch';
import { testWebDAVConnection, uploadToWebDAV, downloadFromWebDAV, updateLastSyncTime, getRemoteBackupTime } from '../services/webdavService';
import { formatDateTime } from '../utils/dateHelper';

export default function Settings() {
  const navigate = useNavigate();
  const {
    themeColor, currencySymbol, colorMode, setThemeColor, setCurrencySymbol, setColorMode,
    ai_enabled, ai_api_url, ai_api_key, ai_model_mode, ai_text_model,
    ai_vision_api_url, ai_vision_api_key, ai_vision_model,
    setAIEnabled, setAIApiUrl, setAIApiKey, setAIModelMode, setAITextModel,
    setAIVisionApiUrl, setAIVisionApiKey, setAIVisionModel,
    webdav_enabled, webdav_server_url, webdav_username, webdav_password,
    webdav_remote_path, webdav_last_sync_at,
    setWebDAVEnabled, setWebDAVServerUrl, setWebDAVUsername,
    setWebDAVPassword, setWebDAVRemotePath,
  } = useSettingsStore();
  const [exporting, setExporting] = useState(false);
  const [exportMsg, setExportMsg] = useState('');
  const [importing, setImporting] = useState(false);
  const [importMsg, setImportMsg] = useState('');
  const [showImportConfirm, setShowImportConfirm] = useState(false);
  const [pendingImportData, setPendingImportData] = useState('');
  const [showApiKey, setShowApiKey] = useState(false);
  const [testLoading, setTestLoading] = useState(false);
  const [testMsg, setTestMsg] = useState('');
  const [showWebDAVPassword, setShowWebDAVPassword] = useState(false);
  const [webdavTestLoading, setWebdavTestLoading] = useState(false);
  const [webdavTestMsg, setWebdavTestMsg] = useState('');
  const [webdavSyncLoading, setWebdavSyncLoading] = useState(false);
  const [webdavSyncMsg, setWebdavSyncMsg] = useState('');
  const [showDownloadConfirm, setShowDownloadConfirm] = useState(false);
  const [aiExpanded, setAiExpanded] = useState(false);
  const [webdavExpanded, setWebdavExpanded] = useState(false);
  const [remoteBackupTime, setRemoteBackupTime] = useState<string | null>(null);
  const [showOldBackupWarning, setShowOldBackupWarning] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const isMobile = /android|iphone|ipad/i.test(navigator.userAgent);

  const handleExport = async () => {
    setExporting(true);
    setExportMsg('');
    try {
      const content = await exportToJSON();
      const fileName = `assetly-export-${new Date().toISOString().slice(0, 10)}.json`;

      if (isMobile) {
        // Method 1: Android native share (most reliable - native writes file + shares)
        if (typeof (window as any).Android?.shareTextAsFile === 'function') {
          try {
            const shared = (window as any).Android.shareTextAsFile(
              content,
              fileName,
              'application/json',
              'Assetly 数据导出'
            );
            if (shared) {
              setExportMsg('导出成功，请选择保存位置');
              return;
            }
          } catch (e) {
            console.warn('Android share failed:', e);
          }
        }

        // Method 2: Web Share API with file (fallback)
        try {
          const blob = new Blob([content], { type: 'application/json' });
          const file = new File([blob], fileName, { type: 'application/json' });
          if (navigator.canShare?.({ files: [file] })) {
            await navigator.share({ files: [file], title: 'Assetly 数据导出' });
            setExportMsg('导出成功');
            return;
          }
        } catch (shareErr) {
          if ((shareErr as Error).name === 'AbortError') {
            setExportMsg('导出已取消');
            return;
          }
          console.warn('Web Share failed:', shareErr);
        }

        // Method 3: Copy to clipboard as last resort
        try {
          await navigator.clipboard.writeText(content);
          setExportMsg('分享不可用，数据已复制到剪贴板');
        } catch {
          setExportMsg('导出失败：当前环境不支持分享功能');
        }
      } else {
        // Desktop: browser download
        fallbackDownload(content, fileName);
      }
    } catch (err) {
      setExportMsg('导出失败，请重试');
    } finally {
      setExporting(false);
    }
  };

  const fallbackDownload = (content: string, fileName: string) => {
    const blob = new Blob([content], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    setExportMsg(`导出成功，文件名为 ${fileName}，请在下载记录中查找`);
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setImporting(true);
    setImportMsg('');

    try {
      const text = await file.text();
      setPendingImportData(text);
      setShowImportConfirm(true);
    } catch {
      setImportMsg('读取文件失败');
    } finally {
      setImporting(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const testOneModel = async (
    label: string,
    modelName: string,
    apiKey: string,
    baseURL: string,
  ): Promise<string> => {
    if (!apiKey) return `${label}失败: 未填写 API Key`;
    if (!modelName) return `${label}失败: 未填写模型名称`;
    if (!baseURL) return `${label}失败: 未填写 Base URL`;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 20000);
    try {
      const model = new ChatOpenAI({
        model: modelName,
        apiKey,
        configuration: { baseURL, fetch: getHttpFetch() },
        temperature: 1,
        maxTokens: 10,
        timeout: 20000,
        maxRetries: 0,
      });
      await model.invoke('hi', { signal: controller.signal });
      return `${label}成功`;
    } catch (err) {
      const e = err as Error;
      const msg = e.name === 'AbortError' ? '请求超时' : e.message;
      return `${label}失败: ${msg}`;
    } finally {
      clearTimeout(timer);
    }
  };

  const handleTestConnection = async () => {
    setTestLoading(true);
    setTestMsg('');
    try {
      if (ai_model_mode === 'separate') {
        const [textResult, visionResult] = await Promise.all([
          testOneModel('文本模型', ai_text_model, ai_api_key, ai_api_url),
          testOneModel('图像模型', ai_vision_model, ai_vision_api_key, ai_vision_api_url),
        ]);
        setTestMsg(`${textResult}\n${visionResult}`);
      } else {
        const result = await testOneModel('连接', ai_text_model, ai_api_key, ai_api_url);
        setTestMsg(result);
      }
    } finally {
      setTestLoading(false);
    }
  };

  const handleImportConfirm = async () => {
    setShowImportConfirm(false);
    setImporting(true);
    setImportMsg('');

    try {
      const result = await importFromJSON(pendingImportData);
      if (result.errors.length > 0 && result.success === 0) {
        setImportMsg(`导入失败: ${result.errors[0]}`);
      } else {
        setImportMsg(`导入完成: 成功 ${result.success} 条${result.failed > 0 ? `，失败 ${result.failed} 条` : ''}`);
        window.location.reload();
      }
    } catch (err) {
      setImportMsg(`导入失败: ${(err as Error).message}`);
    } finally {
      setImporting(false);
      setPendingImportData('');
    }
  };

  const handleWebDAVTest = async () => {
    setWebdavTestLoading(true);
    setWebdavTestMsg('');
    try {
      const result = await testWebDAVConnection(
        webdav_server_url, webdav_username, webdav_password, webdav_remote_path,
      );
      setWebdavTestMsg(result);
    } finally {
      setWebdavTestLoading(false);
    }
  };

  const handleDownloadClick = async () => {
    setWebdavSyncLoading(true);
    setWebdavSyncMsg('');
    try {
      const remoteTime = await getRemoteBackupTime(
        webdav_server_url, webdav_username, webdav_password, webdav_remote_path,
      );
      setRemoteBackupTime(remoteTime);
      if (remoteTime && webdav_last_sync_at && dayjs(remoteTime).isBefore(dayjs(webdav_last_sync_at))) {
        setShowOldBackupWarning(true);
      } else {
        setShowDownloadConfirm(true);
      }
    } catch {
      setRemoteBackupTime(null);
      setShowDownloadConfirm(true);
    } finally {
      setWebdavSyncLoading(false);
    }
  };

  const handleWebDAVUpload = async () => {
    setWebdavSyncLoading(true);
    setWebdavSyncMsg('');
    try {
      await uploadToWebDAV(
        webdav_server_url, webdav_username, webdav_password, webdav_remote_path,
      );
      await updateLastSyncTime();
      await useSettingsStore.getState().loadSettings();
      setWebdavSyncMsg('备份上传成功');
    } catch (err) {
      setWebdavSyncMsg(`上传失败: ${(err as Error).message}`);
    } finally {
      setWebdavSyncLoading(false);
    }
  };

  const handleWebDAVDownloadConfirm = async () => {
    setShowDownloadConfirm(false);
    setShowOldBackupWarning(false);
    setWebdavSyncLoading(true);
    setWebdavSyncMsg('');
    try {
      const result = await downloadFromWebDAV(
        webdav_server_url, webdav_username, webdav_password, webdav_remote_path,
      );
      if (result.errors.length > 0 && result.success === 0) {
        setWebdavSyncMsg(`恢复失败: ${result.errors[0]}`);
      } else {
        await updateLastSyncTime();
        setWebdavSyncMsg(`恢复完成: 成功 ${result.success} 条${result.failed > 0 ? `，失败 ${result.failed} 条` : ''}`);
        window.location.reload();
      }
    } catch (err) {
      setWebdavSyncMsg(`下载失败: ${(err as Error).message}`);
    } finally {
      setWebdavSyncLoading(false);
    }
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <h1 className="text-xl font-bold text-gray-800 dark:text-gray-100 mb-5">设置</h1>

      {/* Appearance Mode */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Sun className="w-5 h-5 text-primary" />
            <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">外观</h2>
          </div>
          <div className="flex gap-1">
            {([
              { value: 'light' as const, Icon: Sun },
              { value: 'dark' as const, Icon: Moon },
              { value: 'system' as const, Icon: Monitor },
            ]).map(({ value, Icon }) => (
              <button
                key={value}
                onClick={() => setColorMode(value)}
                className={`p-2 rounded-[10px] transition-colors ${
                  colorMode === value
                    ? 'bg-primary text-white'
                    : 'text-gray-400 dark:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800'
                }`}
              >
                <Icon className="w-4 h-4" />
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Theme Color */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <Palette className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">主题色</h2>
        </div>
        <div className="flex flex-wrap gap-3">
          {THEME_PRESETS.map((preset) => (
            <button
              key={preset.color}
              onClick={() => setThemeColor(preset.color)}
              className={`flex-1 min-w-[3.5rem] max-w-[4.5rem] flex flex-col items-center gap-1.5 p-2 rounded-[12px] transition-colors ${
                themeColor === preset.color ? 'bg-gray-100 dark:bg-gray-800' : 'hover:bg-gray-50 dark:hover:bg-gray-800'
              }`}
            >
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center ${
                  themeColor === preset.color ? 'ring-2 ring-offset-2' : ''
                }`}
                style={{ backgroundColor: preset.color }}
              >
                {themeColor === preset.color && <Check className="w-5 h-5 text-white" />}
              </div>
              <span className="text-xs text-gray-500 dark:text-gray-400">{preset.name}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Currency */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <DollarSign className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">货币符号</h2>
        </div>
        <div className="flex gap-2">
          {CURRENCY_OPTIONS.map((symbol) => (
            <button
              key={symbol}
              onClick={() => setCurrencySymbol(symbol)}
              className={`w-12 h-12 rounded-[12px] text-lg font-mono font-bold transition-colors ${
                currencySymbol === symbol
                  ? 'bg-primary text-white'
                  : 'bg-gray-50 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
              }`}
            >
              {symbol}
            </button>
          ))}
        </div>
      </div>

      {/* Data Export */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <Download className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">数据导出</h2>
        </div>
        <p className="text-xs text-gray-400 dark:text-gray-500 mb-3">
          {isMobile ? '点击后会弹出分享面板，可以选择保存到文件或发送给他人' : '导出数据会保存到下载目录中'}
        </p>
        <button
          onClick={() => handleExport()}
          disabled={exporting}
          className="w-full py-3 border border-border rounded-[12px] text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50 transition-colors flex items-center justify-center gap-2"
        >
          {isMobile ? <Share2 className="w-4 h-4" /> : <FileJson className="w-4 h-4" />}
          {isMobile ? '分享导出' : '导出 JSON'}
        </button>
        {exportMsg && (
          <p className={`text-xs mt-2 ${exportMsg.includes('成功') ? 'text-green-600' : 'text-red-500'}`}>
            {exportMsg}
          </p>
        )}
      </div>

      {/* Data Import */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <Upload className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">数据导入</h2>
        </div>
        <p className="text-xs text-gray-400 dark:text-gray-500 mb-3">选择之前导出的 JSON 文件进行恢复，导入后会刷新页面</p>
        <input
          ref={fileInputRef}
          type="file"
          accept=".json,application/json"
          onChange={handleFileSelect}
          className="hidden"
        />
        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={importing}
          className="w-full py-3 border border-primary/30 bg-primary/5 rounded-[12px] text-sm font-medium text-primary hover:bg-primary/10 disabled:opacity-50 transition-colors flex items-center justify-center gap-2"
        >
          <Upload className="w-4 h-4" />
          {importing ? '导入中...' : '选择 JSON 文件导入'}
        </button>
        {importMsg && (
          <p className={`text-xs mt-2 ${importMsg.includes('成功') || importMsg.includes('完成') ? 'text-green-600' : 'text-red-500'}`}>
            {importMsg}
          </p>
        )}
      </div>

      {/* WebDAV Sync */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-4 border border-border/50 mb-4">
        <button
          type="button"
          onClick={() => setWebdavExpanded(!webdavExpanded)}
          className="w-full flex items-center justify-between"
        >
          <div className="flex items-center gap-2">
            <Cloud className="w-5 h-5 text-primary" />
            <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">WebDAV 同步</h2>
          </div>
          {webdavExpanded ? <ChevronDown className="w-4 h-4 text-gray-400" /> : <ChevronRight className="w-4 h-4 text-gray-400" />}
        </button>

        {webdavExpanded && (<>
        <div className="flex items-center justify-between mt-4 mb-4">
          <label className="text-sm text-gray-600 dark:text-gray-300">启用 WebDAV</label>
          <button
            type="button"
            onClick={() => setWebDAVEnabled(!webdav_enabled)}
            className={`relative w-11 h-6 rounded-full transition-colors ${webdav_enabled ? 'bg-primary' : 'bg-gray-300'}`}
          >
            <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${webdav_enabled ? 'translate-x-5' : ''}`} />
          </button>
        </div>

        {webdav_enabled && (
          <div className="space-y-3">
            <div className="p-3 bg-gray-50 dark:bg-gray-800/50 rounded-[12px] space-y-3">
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">服务器地址</label>
                <input
                  type="text"
                  value={webdav_server_url}
                  onChange={(e) => setWebDAVServerUrl(e.target.value)}
                  placeholder="https://dav.example.com"
                  className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">用户名</label>
                <input
                  type="text"
                  value={webdav_username}
                  onChange={(e) => setWebDAVUsername(e.target.value)}
                  placeholder="username"
                  className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">密码</label>
                <div className="relative">
                  <input
                    type={showWebDAVPassword ? 'text' : 'password'}
                    value={webdav_password}
                    onChange={(e) => setWebDAVPassword(e.target.value)}
                    placeholder="password"
                    className="w-full px-3 py-2.5 pr-10 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                  />
                  <button
                    type="button"
                    onClick={() => setShowWebDAVPassword(!showWebDAVPassword)}
                    className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-gray-400 hover:text-gray-600"
                  >
                    {showWebDAVPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">远程路径</label>
                <input
                  type="text"
                  value={webdav_remote_path}
                  onChange={(e) => setWebDAVRemotePath(e.target.value)}
                  placeholder="/assetly-backup.json"
                  className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                />
              </div>
            </div>

            <button
              onClick={handleWebDAVTest}
              disabled={webdavTestLoading || !webdav_server_url || !webdav_username || !webdav_password}
              className="w-full flex items-center justify-center gap-2 py-2.5 border border-primary/30 bg-primary/5 rounded-[12px] text-sm font-medium text-primary hover:bg-primary/10 disabled:opacity-50 transition-colors"
            >
              {webdavTestLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Zap className="w-4 h-4" />}
              {webdavTestLoading ? '测试中...' : '测试连接'}
            </button>
            {webdavTestMsg && (
              <p className={`text-xs ${webdavTestMsg.includes('成功') ? 'text-green-600' : 'text-red-500'}`}>
                {webdavTestMsg}
              </p>
            )}

            <div className="flex gap-2">
              <button
                onClick={handleWebDAVUpload}
                disabled={webdavSyncLoading || !webdav_server_url || !webdav_username || !webdav_password}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 border border-border rounded-[12px] text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50 transition-colors"
              >
                <CloudUpload className="w-4 h-4" />
                {webdavSyncLoading ? '同步中...' : '上传备份'}
              </button>
              <button
                onClick={handleDownloadClick}
                disabled={webdavSyncLoading || !webdav_server_url || !webdav_username || !webdav_password}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 border border-primary/30 bg-primary/5 rounded-[12px] text-sm font-medium text-primary hover:bg-primary/10 disabled:opacity-50 transition-colors"
              >
                <CloudDownload className="w-4 h-4" />
                {webdavSyncLoading ? '同步中...' : '下载恢复'}
              </button>
            </div>

            {webdavSyncMsg && (
              <p className={`text-xs ${webdavSyncMsg.includes('成功') || webdavSyncMsg.includes('完成') ? 'text-green-600' : 'text-red-500'}`}>
                {webdavSyncMsg}
              </p>
            )}

            {webdav_last_sync_at && (
              <p className="text-xs text-gray-400 dark:text-gray-500">
                上次同步: {formatDateTime(webdav_last_sync_at)}
              </p>
            )}

            <p className="text-xs text-gray-400 dark:text-gray-500">
              密码仅存储在本地，不会上传到任何服务器
            </p>
          </div>
        )}
        </>)}
      </div>

      {/* Logs */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <ScrollText className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">运行日志</h2>
        </div>
        <p className="text-xs text-gray-400 dark:text-gray-500 mb-3">查看应用运行日志，便于排查问题</p>
        <button
          onClick={() => navigate('/logs')}
          className="w-full py-3 border border-border rounded-[12px] text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors flex items-center justify-center gap-2"
        >
          <ScrollText className="w-4 h-4" />
          查看日志
        </button>
      </div>

      {/* AI Config */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-4 border border-border/50 mb-4">
        <button
          type="button"
          onClick={() => setAiExpanded(!aiExpanded)}
          className="w-full flex items-center justify-between"
        >
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-primary" />
            <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">AI 配置</h2>
          </div>
          {aiExpanded ? <ChevronDown className="w-4 h-4 text-gray-400" /> : <ChevronRight className="w-4 h-4 text-gray-400" />}
        </button>

        {aiExpanded && (<>
        {/* AI Enabled Toggle */}
        <div className="flex items-center justify-between mt-4 mb-4">
          <label className="text-sm text-gray-600 dark:text-gray-300">启用 AI 识别</label>
          <button
            type="button"
            onClick={() => setAIEnabled(!ai_enabled)}
            className={`relative w-11 h-6 rounded-full transition-colors ${ai_enabled ? 'bg-primary' : 'bg-gray-300'}`}
          >
            <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${ai_enabled ? 'translate-x-5' : ''}`} />
          </button>
        </div>

        {ai_enabled && (
          <div className="space-y-3">
            {/* Model Mode */}
            <div>
              <label className="block text-xs text-gray-500 mb-2">模型配置模式</label>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setAIModelMode('single')}
                  className={`flex-1 py-2 rounded-[10px] text-xs font-medium transition-colors ${
                    ai_model_mode === 'single'
                      ? 'bg-primary text-white'
                      : 'bg-gray-50 dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-border hover:bg-gray-100 dark:hover:bg-gray-700'
                  }`}
                >
                  多模态
                </button>
                <button
                  type="button"
                  onClick={() => setAIModelMode('separate')}
                  className={`flex-1 py-2 rounded-[10px] text-xs font-medium transition-colors ${
                    ai_model_mode === 'separate'
                      ? 'bg-primary text-white'
                      : 'bg-gray-50 dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-border hover:bg-gray-100 dark:hover:bg-gray-700'
                  }`}
                >
                  单模型
                </button>
              </div>
              <p className="text-xs text-gray-400 mt-1">
                {ai_model_mode === 'single'
                  ? '文字和图片使用同一个模型（如 gpt-4o）'
                  : '文字和图片可使用不同厂商的模型和密钥'}
              </p>
            </div>

            {/* Text Model Config */}
            <div className="p-3 bg-gray-50 dark:bg-gray-800/50 rounded-[12px] space-y-3">
              <p className="text-xs font-medium text-gray-700 dark:text-gray-200">文本模型配置</p>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">API Base URL</label>
                <input
                  type="text"
                  value={ai_api_url}
                  onChange={(e) => setAIApiUrl(e.target.value)}
                  placeholder="https://api.openai.com/v1"
                  className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">API Key</label>
                <div className="relative">
                  <input
                    type={showApiKey ? 'text' : 'password'}
                    value={ai_api_key}
                    onChange={(e) => setAIApiKey(e.target.value)}
                    placeholder="sk-..."
                    className="w-full px-3 py-2.5 pr-10 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                  />
                  <button
                    type="button"
                    onClick={() => setShowApiKey(!showApiKey)}
                    className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-gray-400 hover:text-gray-600"
                  >
                    {showApiKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">模型名称</label>
                <input
                  type="text"
                  value={ai_text_model}
                  onChange={(e) => setAITextModel(e.target.value)}
                  placeholder="gpt-4o-mini"
                  className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                />
              </div>
            </div>

            {/* Vision Model Config (separate mode) */}
            {ai_model_mode === 'separate' && (
              <div className="p-3 bg-gray-50 dark:bg-gray-800/50 rounded-[12px] space-y-3">
                <p className="text-xs font-medium text-gray-700 dark:text-gray-200">图像识别模型配置</p>
                <div>
                  <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">API Base URL</label>
                  <input
                    type="text"
                    value={ai_vision_api_url}
                    onChange={(e) => setAIVisionApiUrl(e.target.value)}
                    placeholder="https://api.openai.com/v1"
                    className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                  />
                </div>
                <div>
                  <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">API Key</label>
                  <div className="relative">
                    <input
                      type={showApiKey ? 'text' : 'password'}
                      value={ai_vision_api_key}
                      onChange={(e) => setAIVisionApiKey(e.target.value)}
                      placeholder="sk-..."
                      className="w-full px-3 py-2.5 pr-10 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                    />
                    <button
                      type="button"
                      onClick={() => setShowApiKey(!showApiKey)}
                      className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-gray-400 hover:text-gray-600"
                    >
                      {showApiKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                <div>
                  <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">模型名称</label>
                  <input
                    type="text"
                    value={ai_vision_model}
                    onChange={(e) => setAIVisionModel(e.target.value)}
                    placeholder="gpt-4o"
                    className="w-full px-3 py-2.5 bg-white dark:bg-gray-800 dark:text-gray-100 border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
                  />
                </div>
              </div>
            )}

            {/* Test Connection */}
            <button
              onClick={handleTestConnection}
              disabled={
                testLoading ||
                !ai_api_key ||
                (ai_model_mode === 'separate' && !ai_vision_api_key)
              }
              className="w-full flex items-center justify-center gap-2 py-2.5 border border-primary/30 bg-primary/5 rounded-[12px] text-sm font-medium text-primary hover:bg-primary/10 disabled:opacity-50 transition-colors"
            >
              {testLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Zap className="w-4 h-4" />}
              {testLoading ? '测试中...' : ai_model_mode === 'separate' ? '测试连接（文本 + 图像）' : '测试连接'}
            </button>
            {testMsg && (
              <div className="space-y-1">
                {testMsg.split('\n').map((line, idx) => (
                  <p
                    key={idx}
                    className={`text-xs ${line.includes('成功') ? 'text-green-600' : 'text-red-500'}`}
                  >
                    {line}
                  </p>
                ))}
              </div>
            )}

            <p className="text-xs text-gray-400 dark:text-gray-500">
              API Key 仅存储在本地，不会上传到任何服务器
            </p>
          </div>
        )}
        </>)}
      </div>

      {/* About */}
      <div className="bg-white dark:bg-[#1E1E1E] rounded-[20px] p-5 border border-border/50">
        <div className="flex items-center gap-2 mb-3">
          <Info className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-200">关于</h2>
        </div>
        <div className="text-sm text-gray-500 dark:text-gray-400 space-y-1">
          <p>Assetly - 家庭物品管家</p>
          <p>版本 <a href="https://github.com/yn-zxj/Assetly/releases" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">{__APP_VERSION__}</a></p>
          <p className="text-xs text-muted mt-2">基于 Tauri 2.0 构建，数据本地存储，隐私安全</p>
        </div>
      </div>

      <ConfirmDialog
        open={showImportConfirm}
        title="确认导入"
        message="导入数据会覆盖现有数据（相同 ID 的记录将被替换）。确定要继续吗？"
        confirmLabel="确认导入"
        danger
        onConfirm={handleImportConfirm}
        onCancel={() => { setShowImportConfirm(false); setPendingImportData(''); }}
      />

      <ConfirmDialog
        open={showDownloadConfirm}
        title="确认恢复"
        message="从 WebDAV 下载数据会覆盖现有数据（相同 ID 的记录将被替换）。确定要继续吗？"
        confirmLabel="确认恢复"
        danger
        onConfirm={handleWebDAVDownloadConfirm}
        onCancel={() => setShowDownloadConfirm(false)}
      />

      <ConfirmDialog
        open={showOldBackupWarning}
        title="远端数据可能较旧"
        message={`远端备份时间: ${remoteBackupTime ? formatDateTime(remoteBackupTime) : '未知'}\n本地上次同步: ${webdav_last_sync_at ? formatDateTime(webdav_last_sync_at) : '未知'}\n\n远端备份数据可能比本地旧，恢复后可能导致新数据丢失。确定要继续吗？`}
        confirmLabel="仍然恢复"
        danger
        onConfirm={handleWebDAVDownloadConfirm}
        onCancel={() => setShowOldBackupWarning(false)}
      />
    </div>
  );
}
