import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { ScrollText, Trash2, ArrowLeft, AlertCircle, Info, AlertTriangle, Bug } from 'lucide-react';
import { getMemoryLogs, clearMemoryLogs, type LogEntry, type LogLevel } from '../utils/logger';

const LEVEL_CONFIG: Record<LogLevel, { icon: typeof Info; color: string; bg: string; label: string }> = {
  trace: { icon: Bug, color: 'text-gray-400', bg: 'bg-gray-50', label: 'TRACE' },
  debug: { icon: Bug, color: 'text-blue-500', bg: 'bg-blue-50', label: 'DEBUG' },
  info: { icon: Info, color: 'text-green-600', bg: 'bg-green-50', label: 'INFO' },
  warn: { icon: AlertTriangle, color: 'text-amber-600', bg: 'bg-amber-50', label: 'WARN' },
  error: { icon: AlertCircle, color: 'text-red-600', bg: 'bg-red-50', label: 'ERROR' },
};

export default function Logs() {
  const navigate = useNavigate();
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [filter, setFilter] = useState<LogLevel | 'all'>('all');
  const [autoScroll, setAutoScroll] = useState(true);
  const scrollRef = useRef<HTMLDivElement>(null);

  const refreshLogs = () => {
    setLogs(getMemoryLogs());
  };

  useEffect(() => {
    refreshLogs();
    const interval = setInterval(refreshLogs, 2000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (autoScroll && scrollRef.current) {
      scrollRef.current.scrollTop = 0;
    }
  }, [logs, autoScroll]);

  const filteredLogs = filter === 'all' ? logs : logs.filter((l) => l.level === filter);

  const handleClear = () => {
    clearMemoryLogs();
    refreshLogs();
  };

  const formatTime = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleTimeString('zh-CN', { hour12: false }) + '.' + String(d.getMilliseconds()).padStart(3, '0');
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <div className="flex items-center justify-between mb-5">
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate('/settings')}
            className="p-1.5 rounded-full hover:bg-gray-100 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-gray-600" />
          </button>
          <ScrollText className="w-5 h-5 text-primary" />
          <h1 className="text-xl font-bold text-gray-800">运行日志</h1>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setAutoScroll(!autoScroll)}
            className={`text-xs px-2 py-1 rounded-full transition-colors ${
              autoScroll ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500'
            }`}
          >
            自动刷新
          </button>
          <button
            onClick={handleClear}
            className="flex items-center gap-1 text-xs px-3 py-1.5 rounded-full bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
          >
            <Trash2 className="w-3.5 h-3.5" />
            清空
          </button>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1.5 mb-4 overflow-x-auto pb-1">
        {(['all', 'error', 'warn', 'info', 'debug', 'trace'] as const).map((level) => (
          <button
            key={level}
            onClick={() => setFilter(level)}
            className={`text-xs px-3 py-1.5 rounded-full whitespace-nowrap transition-colors ${
              filter === level
                ? 'bg-primary text-white'
                : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
            }`}
          >
            {level === 'all' ? '全部' : LEVEL_CONFIG[level].label}
            {level !== 'all' && (
              <span className="ml-1 opacity-70">
                {logs.filter((l) => l.level === level).length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Log list */}
      <div
        ref={scrollRef}
        className="bg-white rounded-[20px] border border-border/50 overflow-y-auto"
        style={{ maxHeight: 'calc(100vh - 220px)' }}
      >
        {filteredLogs.length === 0 ? (
          <div className="p-8 text-center text-gray-400 text-sm">
            <ScrollText className="w-10 h-10 mx-auto mb-3 opacity-30" />
            <p>暂无日志</p>
            <p className="text-xs mt-1 opacity-60">日志会在应用运行过程中自动记录</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {filteredLogs.map((log, idx) => {
              const config = LEVEL_CONFIG[log.level];
              const Icon = config.icon;
              return (
                <div key={idx} className={`p-3 ${config.bg} hover:opacity-80 transition-opacity`}>
                  <div className="flex items-start gap-2">
                    <Icon className={`w-3.5 h-3.5 mt-0.5 shrink-0 ${config.color}`} />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className={`text-[10px] font-bold ${config.color}`}>{config.label}</span>
                        <span className="text-[10px] text-gray-400">{formatTime(log.timestamp)}</span>
                        {log.source && (
                          <span className="text-[10px] text-gray-400 bg-gray-100 px-1.5 rounded">
                            {log.source}
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-gray-700 break-words">{log.message}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <p className="text-[10px] text-gray-400 mt-3 text-center">
        显示最近 {logs.length} 条内存日志 · 完整日志文件保存在应用日志目录
      </p>
    </div>
  );
}
