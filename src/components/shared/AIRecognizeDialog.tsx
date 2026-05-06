import { useState, useRef, useCallback, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { X, Type, Image, Loader2, Sparkles, AlertCircle } from 'lucide-react';
import { useSettingsStore } from '../../stores/useSettingsStore';
import { recognizeByText, recognizeByImage, fileToBase64 } from '../../services/aiService';
import type { AIRecognitionResult } from '../../types/settings';

interface AIRecognizeDialogProps {
  open: boolean;
  onClose: () => void;
}

type Mode = 'select' | 'text' | 'image';

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

export default function AIRecognizeDialog({ open, onClose }: AIRecognizeDialogProps) {
  const navigate = useNavigate();
  const settings = useSettingsStore();
  const [mode, setMode] = useState<Mode>('select');
  const [text, setText] = useState('');
  const [imagePreview, setImagePreview] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [streamText, setStreamText] = useState('');
  const [elapsed, setElapsed] = useState(0);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const streamBoxRef = useRef<HTMLDivElement>(null);
  const startAtRef = useRef<number>(0);

  // loading 时每 100ms 刷新耗时
  useEffect(() => {
    if (!loading) return;
    startAtRef.current = Date.now();
    setElapsed(0);
    const timer = setInterval(() => {
      setElapsed(Date.now() - startAtRef.current);
    }, 100);
    return () => clearInterval(timer);
  }, [loading]);

  // 流内容更新时自动滚到底
  useEffect(() => {
    if (streamBoxRef.current) {
      streamBoxRef.current.scrollTop = streamBoxRef.current.scrollHeight;
    }
  }, [streamText]);

  const reset = useCallback(() => {
    setMode('select');
    setText('');
    setImagePreview('');
    setLoading(false);
    setError('');
    setStreamText('');
    setElapsed(0);
  }, []);

  const handleClose = useCallback(() => {
    reset();
    onClose();
  }, [reset, onClose]);

  const handleRecognizeText = async () => {
    if (!text.trim()) return;
    setLoading(true);
    setError('');
    setStreamText('');
    try {
      const result = await recognizeByText(text.trim(), settings, (partial) => {
        setStreamText(partial);
      });
      handleResult(result);
    } catch (err) {
      setError((err as Error).message || '识别失败，请重试');
    } finally {
      setLoading(false);
    }
  };

  const handleRecognizeImage = async () => {
    if (!imagePreview) return;
    setLoading(true);
    setError('');
    setStreamText('');
    try {
      const result = await recognizeByImage(imagePreview, settings, (partial) => {
        setStreamText(partial);
      });
      handleResult(result);
    } catch (err) {
      setError((err as Error).message || '识别失败，请重试');
    } finally {
      setLoading(false);
    }
  };

  const handleResult = (result: AIRecognitionResult) => {
    const encoded = btoa(encodeURIComponent(JSON.stringify(result)));
    if (result.item_type === 'medicine') {
      navigate(`/medicine/new?ai=1&data=${encoded}`);
    } else {
      navigate(`/items/new?ai=1&data=${encoded}`);
    }
    handleClose();
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > MAX_FILE_SIZE) {
      setError('图片大小不能超过 5MB');
      return;
    }

    if (!file.type.startsWith('image/')) {
      setError('请选择图片文件');
      return;
    }

    setError('');
    try {
      const base64 = await fileToBase64(file);
      setImagePreview(base64);
    } catch {
      setError('图片读取失败');
    }
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={handleClose} />

      {/* Dialog */}
      <div className="relative bg-white rounded-[24px] w-full max-w-md max-h-[85vh] overflow-hidden shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-border/50">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-primary" />
            <h2 className="text-base font-semibold text-gray-800">AI 智能识别</h2>
          </div>
          <button
            onClick={handleClose}
            className="p-2 rounded-full hover:bg-gray-100 transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Content */}
        <div className="p-5 overflow-y-auto">
          {mode === 'select' && (
            <div className="space-y-3">
              <p className="text-sm text-gray-500 mb-4">选择识别方式，AI 将自动判断是普通物品还是药品</p>
              <button
                onClick={() => setMode('text')}
                className="w-full flex items-center gap-4 p-4 rounded-[16px] border border-border hover:border-primary/50 hover:bg-primary/5 transition-colors text-left"
              >
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                  <Type className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-800">文字描述</p>
                  <p className="text-xs text-gray-400 mt-0.5">输入物品或药品的文字描述</p>
                </div>
              </button>
              <button
                onClick={() => setMode('image')}
                className="w-full flex items-center gap-4 p-4 rounded-[16px] border border-border hover:border-primary/50 hover:bg-primary/5 transition-colors text-left"
              >
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                  <Image className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-800">图片识别</p>
                  <p className="text-xs text-gray-400 mt-0.5">拍照或上传物品/药品图片</p>
                </div>
              </button>
            </div>
          )}

          {mode === 'text' && (
            <div className="space-y-4">
              <button
                onClick={() => setMode('select')}
                className="text-xs text-primary flex items-center gap-1"
              >
                ← 返回选择
              </button>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  描述你要添加的物品或药品
                </label>
                <textarea
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  placeholder="例如：一盒布洛芬缓释胶囊，24粒装，有效期到2026年8月，用于缓解头痛..."
                  rows={5}
                  className="w-full px-3 py-2.5 bg-white border border-border rounded-[12px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 resize-none"
                />
              </div>
              <button
                onClick={handleRecognizeText}
                disabled={loading || !text.trim()}
                className="w-full flex items-center justify-center gap-2 py-3 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
              >
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />}
                {loading ? '识别中...' : '开始识别'}
              </button>
            </div>
          )}

          {mode === 'image' && (
            <div className="space-y-4">
              <button
                onClick={() => setMode('select')}
                className="text-xs text-primary flex items-center gap-1"
              >
                ← 返回选择
              </button>

              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileSelect}
                className="hidden"
              />

              {!imagePreview ? (
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full aspect-[4/3] rounded-[16px] border-2 border-dashed border-gray-300 flex flex-col items-center justify-center gap-3 hover:border-primary hover:bg-primary/5 transition-colors"
                >
                  <Image className="w-10 h-10 text-gray-400" />
                  <div className="text-center">
                    <p className="text-sm text-gray-600">点击选择图片</p>
                    <p className="text-xs text-gray-400 mt-1">支持 JPG、PNG，最大 5MB</p>
                  </div>
                </button>
              ) : (
                <div className="relative">
                  <img
                    src={imagePreview}
                    alt="Preview"
                    className="w-full rounded-[16px] object-cover max-h-64"
                  />
                  <button
                    onClick={() => { setImagePreview(''); setError(''); }}
                    className="absolute top-2 right-2 p-1.5 bg-black/50 rounded-full text-white hover:bg-black/70 transition-colors"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              )}

              {imagePreview && (
                <button
                  onClick={handleRecognizeImage}
                  disabled={loading}
                  className="w-full flex items-center justify-center gap-2 py-3 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
                >
                  {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />}
                  {loading ? '识别中...' : '开始识别'}
                </button>
              )}
            </div>
          )}

          {error && (
            <div className="flex items-center gap-2 mt-4 p-3 bg-red-50 rounded-[12px] text-red-600 text-sm">
              <AlertCircle className="w-4 h-4 shrink-0" />
              {error}
            </div>
          )}

          {loading && (mode === 'text' || mode === 'image') && (
            <div className="mt-4 rounded-[12px] border border-border bg-gray-50 overflow-hidden">
              <div className="flex items-center justify-between px-3 py-2 text-xs text-gray-500 border-b border-border/60 bg-white">
                <div className="flex items-center gap-1.5">
                  <Loader2 className="w-3.5 h-3.5 animate-spin text-primary" />
                  <span>AI 正在输出</span>
                  <span className="text-gray-400">· {(elapsed / 1000).toFixed(1)}s</span>
                  {streamText && (
                    <span className="text-gray-400">· {streamText.length} 字符</span>
                  )}
                </div>
              </div>
              <div
                ref={streamBoxRef}
                className="px-3 py-2 text-xs text-gray-700 font-mono whitespace-pre-wrap break-words max-h-40 overflow-y-auto"
              >
                {streamText || <span className="text-gray-400">等待模型响应…</span>}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
