import { useState, useRef, useEffect, useCallback } from 'react';
import { ChevronLeft, ChevronRight, Calendar } from 'lucide-react';
import dayjs from 'dayjs';

interface DatePickerProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
}

const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六'];
const MONTHS = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];

type ViewMode = 'days' | 'months' | 'years';

export default function DatePicker({ value, onChange, placeholder = '选择日期', required }: DatePickerProps) {
  const [open, setOpen] = useState(false);
  const [viewDate, setViewDate] = useState(() =>
    value ? dayjs(value) : dayjs()
  );
  const [mode, setMode] = useState<ViewMode>('days');
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (value) setViewDate(dayjs(value));
  }, [value]);

  useEffect(() => {
    if (open) setMode('days');
  }, [open]);

  // Close when clicking outside
  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      const target = e.target as Node;
      if (containerRef.current && !containerRef.current.contains(target)) {
        setOpen(false);
      }
    };
    // Use capture phase to catch clicks before they bubble
    document.addEventListener('mousedown', handler, true);
    return () => document.removeEventListener('mousedown', handler, true);
  }, [open]);

  const year = viewDate.year();
  const month = viewDate.month();
  const firstDay = dayjs(new Date(year, month, 1)).day();
  const daysInMonth = viewDate.daysInMonth();
  const today = dayjs().format('YYYY-MM-DD');
  const selectedDate = value || '';
  const currentYear = dayjs().year();

  const selectDate = useCallback((day: number) => {
    const date = dayjs(new Date(year, month, day)).format('YYYY-MM-DD');
    onChange(date);
    setOpen(false);
  }, [year, month, onChange]);

  const selectMonth = useCallback((m: number) => {
    setViewDate((prev) => prev.month(m));
    setMode('days');
  }, []);

  const selectYear = useCallback((y: number) => {
    setViewDate((prev) => prev.year(y));
    setMode('months');
  }, []);

  const handlePrev = useCallback(() => {
    setViewDate((prev) => {
      if (mode === 'days') return prev.subtract(1, 'month');
      if (mode === 'months') return prev.subtract(1, 'year');
      return prev.subtract(12, 'year');
    });
  }, [mode]);

  const handleNext = useCallback(() => {
    setViewDate((prev) => {
      if (mode === 'days') return prev.add(1, 'month');
      if (mode === 'months') return prev.add(1, 'year');
      return prev.add(12, 'year');
    });
  }, [mode]);

  const handleHeaderClick = useCallback(() => {
    if (mode === 'days') setMode('months');
    else if (mode === 'months') setMode('years');
  }, [mode]);

  const yearStart = year - 5;
  const years = Array.from({ length: 12 }, (_, i) => yearStart + i);

  const cells: (number | null)[] = [];
  for (let i = 0; i < firstDay; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);

  const displayValue = value ? dayjs(value).format('YYYY/MM/DD') : '';

  const headerTitle = mode === 'days'
    ? viewDate.format('YYYY年M月')
    : mode === 'months'
    ? `${year}年`
    : `${yearStart} - ${yearStart + 11}`;

  return (
    <div ref={containerRef} className="relative">
      {/* Trigger */}
      <div
        onClick={() => setOpen(!open)}
        className={`w-full flex items-center gap-2 px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm cursor-pointer hover:border-gray-300 transition-colors ${
          open ? 'border-primary ring-1 ring-primary/20' : ''
        }`}
      >
        <Calendar className="w-4 h-4 text-gray-400 shrink-0" />
        <span className={displayValue ? 'text-gray-800' : 'text-gray-400'}>
          {displayValue || placeholder}
        </span>
        {required && !value && <span className="text-red-400 ml-auto text-xs">*</span>}
      </div>

      {/* Dropdown - NOT using portal, rendered inline with fixed positioning */}
      {open && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center">
          {/* Backdrop */}
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-[2px]"
            onMouseDown={() => setOpen(false)}
          />
          {/* Calendar card */}
          <div
            className="relative bg-white rounded-2xl w-[min(320px,90vw)] p-4 shadow-2xl"
            onMouseDown={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="flex items-center justify-between mb-3">
              <button
                type="button"
                onClick={handlePrev}
                className="p-2 rounded-xl hover:bg-gray-100 active:bg-gray-200 transition-colors"
              >
                <ChevronLeft className="w-5 h-5 text-gray-500" />
              </button>
              <button
                type="button"
                onClick={handleHeaderClick}
                className={`text-base font-semibold px-3 py-1 rounded-xl transition-colors ${
                  mode === 'years'
                    ? 'text-gray-800'
                    : 'text-gray-800 hover:bg-gray-100 active:bg-gray-200'
                }`}
                disabled={mode === 'years'}
              >
                {headerTitle}
              </button>
              <button
                type="button"
                onClick={handleNext}
                className="p-2 rounded-xl hover:bg-gray-100 active:bg-gray-200 transition-colors"
              >
                <ChevronRight className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            {/* Days view */}
            {mode === 'days' && (
              <>
                <div className="grid grid-cols-7 mb-1">
                  {WEEKDAYS.map((d) => (
                    <div key={d} className="text-center text-xs text-gray-400 font-medium py-1.5">
                      {d}
                    </div>
                  ))}
                </div>
                <div className="grid grid-cols-7 gap-0.5">
                  {cells.map((day, i) => {
                    if (day === null) return <div key={`empty-${i}`} />;
                    const dateStr = dayjs(new Date(year, month, day)).format('YYYY-MM-DD');
                    const isToday = dateStr === today;
                    const isSelected = dateStr === selectedDate;
                    return (
                      <button
                        key={day}
                        type="button"
                        onClick={() => selectDate(day)}
                        className={`w-10 h-10 mx-auto rounded-full text-sm flex items-center justify-center transition-colors ${
                          isSelected
                            ? 'bg-primary text-white font-medium'
                            : isToday
                            ? 'bg-primary/10 text-primary font-medium'
                            : 'text-gray-700 hover:bg-gray-100 active:bg-gray-200'
                        }`}
                      >
                        {day}
                      </button>
                    );
                  })}
                </div>
              </>
            )}

            {/* Months view */}
            {mode === 'months' && (
              <div className="grid grid-cols-3 gap-2 py-1">
                {MONTHS.map((label, i) => {
                  const isCurrentMonth = i === dayjs().month() && year === currentYear;
                  const isSelected = i === month;
                  return (
                    <button
                      key={label}
                      type="button"
                      onClick={() => selectMonth(i)}
                      className={`py-3 rounded-xl text-sm font-medium transition-colors ${
                        isSelected
                          ? 'bg-primary text-white'
                          : isCurrentMonth
                          ? 'bg-primary/10 text-primary'
                          : 'text-gray-700 hover:bg-gray-100 active:bg-gray-200'
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            )}

            {/* Years view */}
            {mode === 'years' && (
              <div className="grid grid-cols-3 gap-2 py-1">
                {years.map((y) => {
                  const isCurrentYear = y === currentYear;
                  const isSelected = y === year;
                  return (
                    <button
                      key={y}
                      type="button"
                      onClick={() => selectYear(y)}
                      className={`py-3 rounded-xl text-sm font-medium transition-colors ${
                        isSelected
                          ? 'bg-primary text-white'
                          : isCurrentYear
                          ? 'bg-primary/10 text-primary'
                          : 'text-gray-700 hover:bg-gray-100 active:bg-gray-200'
                      }`}
                    >
                      {y}
                    </button>
                  );
                })}
              </div>
            )}

            {/* Quick actions */}
            <div className="flex gap-2 mt-3 pt-3 border-t border-border/50">
              <button
                type="button"
                onClick={() => { onChange(today); setOpen(false); }}
                className="flex-1 py-2 text-sm text-primary font-medium bg-primary/5 rounded-xl hover:bg-primary/10 active:bg-primary/15 transition-colors"
              >
                今天
              </button>
              <button
                type="button"
                onClick={() => { onChange(''); setOpen(false); }}
                className="flex-1 py-2 text-sm text-gray-500 bg-gray-50 rounded-xl hover:bg-gray-100 active:bg-gray-200 transition-colors"
              >
                清除
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
