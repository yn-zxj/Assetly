import { useState, useRef } from 'react';
import { Download, Upload, Check, Palette, DollarSign, Info, FileJson, ScrollText, Share2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useSettingsStore } from '../stores/useSettingsStore';
import { exportToJSON, importFromJSON } from '../services/exportService';
import { THEME_PRESETS, CURRENCY_OPTIONS } from '../utils/constants';
import ConfirmDialog from '../components/shared/ConfirmDialog';

export default function Settings() {
  const navigate = useNavigate();
  const { themeColor, currencySymbol, setThemeColor, setCurrencySymbol } = useSettingsStore();
  const [exporting, setExporting] = useState(false);
  const [exportMsg, setExportMsg] = useState('');
  const [importing, setImporting] = useState(false);
  const [importMsg, setImportMsg] = useState('');
  const [showImportConfirm, setShowImportConfirm] = useState(false);
  const [pendingImportData, setPendingImportData] = useState('');
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

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <h1 className="text-xl font-bold text-gray-800 mb-5">设置</h1>

      {/* Theme Color */}
      <div className="bg-white rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <Palette className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700">主题色</h2>
        </div>
        <div className="flex flex-wrap gap-3">
          {THEME_PRESETS.map((preset) => (
            <button
              key={preset.color}
              onClick={() => setThemeColor(preset.color)}
              className={`flex flex-col items-center gap-1.5 p-2 rounded-[12px] transition-colors ${
                themeColor === preset.color ? 'bg-gray-100' : 'hover:bg-gray-50'
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
              <span className="text-xs text-gray-500">{preset.name}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Currency */}
      <div className="bg-white rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <DollarSign className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700">货币符号</h2>
        </div>
        <div className="flex gap-2">
          {CURRENCY_OPTIONS.map((symbol) => (
            <button
              key={symbol}
              onClick={() => setCurrencySymbol(symbol)}
              className={`w-12 h-12 rounded-[12px] text-lg font-mono font-bold transition-colors ${
                currencySymbol === symbol
                  ? 'bg-primary text-white'
                  : 'bg-gray-50 text-gray-600 hover:bg-gray-100'
              }`}
            >
              {symbol}
            </button>
          ))}
        </div>
      </div>

      {/* Data Export */}
      <div className="bg-white rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <Download className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700">数据导出</h2>
        </div>
        <p className="text-xs text-gray-400 mb-3">
          {isMobile ? '点击后会弹出分享面板，可以选择保存到文件或发送给他人' : '导出数据会保存到下载目录中'}
        </p>
        <button
          onClick={() => handleExport()}
          disabled={exporting}
          className="w-full py-3 border border-border rounded-[12px] text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 transition-colors flex items-center justify-center gap-2"
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
      <div className="bg-white rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <Upload className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700">数据导入</h2>
        </div>
        <p className="text-xs text-gray-400 mb-3">选择之前导出的 JSON 文件进行恢复，导入后会刷新页面</p>
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

      {/* Logs */}
      <div className="bg-white rounded-[20px] p-5 border border-border/50 mb-4">
        <div className="flex items-center gap-2 mb-4">
          <ScrollText className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700">运行日志</h2>
        </div>
        <p className="text-xs text-gray-400 mb-3">查看应用运行日志，便于排查问题</p>
        <button
          onClick={() => navigate('/logs')}
          className="w-full py-3 border border-border rounded-[12px] text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors flex items-center justify-center gap-2"
        >
          <ScrollText className="w-4 h-4" />
          查看日志
        </button>
      </div>

      {/* About */}
      <div className="bg-white rounded-[20px] p-5 border border-border/50">
        <div className="flex items-center gap-2 mb-3">
          <Info className="w-5 h-5 text-primary" />
          <h2 className="text-sm font-semibold text-gray-700">关于</h2>
        </div>
        <div className="text-sm text-gray-500 space-y-1">
          <p>Assetly - 家庭物品管家</p>
          <p>版本 {__APP_VERSION__}</p>
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
    </div>
  );
}
