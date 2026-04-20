import { useState, useRef, useEffect } from 'react';
import { Clock, X } from 'lucide-react';

interface TimePickerProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

const HOURS = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'));
const MINUTES = Array.from({ length: 60 }, (_, i) => String(i).padStart(2, '0'));

const ITEM_HEIGHT = 48;

export default function TimePicker({ value, onChange, placeholder = '选择时间' }: TimePickerProps) {
  const [open, setOpen] = useState(false);
  const [selectedHour, setSelectedHour] = useState(() => {
    if (value) return value.split(':')[0] || '08';
    return '08';
  });
  const [selectedMinute, setSelectedMinute] = useState(() => {
    if (value) return value.split(':')[1] || '00';
    return '00';
  });
  const containerRef = useRef<HTMLDivElement>(null);
  const hoursRef = useRef<HTMLDivElement>(null);
  const minutesRef = useRef<HTMLDivElement>(null);
  const scrollTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (value) {
      const [h, m] = value.split(':');
      setSelectedHour(h || '08');
      setSelectedMinute(m || '00');
    }
  }, [value]);

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handler, true);
    return () => document.removeEventListener('mousedown', handler, true);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const hourIndex = HOURS.indexOf(selectedHour);
    const minuteIndex = MINUTES.indexOf(selectedMinute);

    setTimeout(() => {
      if (hoursRef.current && hourIndex >= 0) {
        hoursRef.current.scrollTop = hourIndex * ITEM_HEIGHT;
      }
      if (minutesRef.current && minuteIndex >= 0) {
        minutesRef.current.scrollTop = minuteIndex * ITEM_HEIGHT;
      }
    }, 50);
  }, [open, selectedHour, selectedMinute]);

  const handleConfirm = () => {
    const time = `${selectedHour}:${selectedMinute}`;
    onChange(time);
    setOpen(false);
  };

  // 滚动停止后才更新选中状态，避免抖动
  const handleScrollEnd = (
    ref: React.RefObject<HTMLDivElement | null>,
    setter: (val: string) => void,
    items: string[]
  ) => {
    if (scrollTimeoutRef.current) {
      clearTimeout(scrollTimeoutRef.current);
    }
    scrollTimeoutRef.current = setTimeout(() => {
      if (!ref.current) return;
      const scrollTop = ref.current.scrollTop;
      const index = Math.round(scrollTop / ITEM_HEIGHT);
      const clampedIndex = Math.max(0, Math.min(items.length - 1, index));
      const targetScroll = clampedIndex * ITEM_HEIGHT;
      // 吸附到正确位置
      ref.current.scrollTo({ top: targetScroll, behavior: 'smooth' });
      setter(items[clampedIndex]);
      scrollTimeoutRef.current = null;
    }, 150);
  };

  const handleHoursScroll = () => {
    handleScrollEnd(hoursRef, setSelectedHour, HOURS);
  };

  const handleMinutesScroll = () => {
    handleScrollEnd(minutesRef, setSelectedMinute, MINUTES);
  };

  const displayValue = value || '';

  return (
    <div ref={containerRef} className="relative">
      <div
        onClick={() => setOpen(!open)}
        className={`flex items-center gap-1.5 px-2.5 py-1.5 bg-white border border-border rounded-lg text-sm cursor-pointer hover:border-gray-300 transition-colors min-w-[80px] justify-center ${
          open ? 'border-primary ring-1 ring-primary/20' : ''
        }`}
      >
        <Clock className="w-3.5 h-3.5 text-gray-400 shrink-0" />
        <span className={displayValue ? 'text-gray-800 font-mono' : 'text-gray-400'}>
          {displayValue || placeholder}
        </span>
      </div>

      {open && (
        <div className="fixed inset-0 z-[9999] flex items-end justify-center">
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-[2px]"
            onMouseDown={() => setOpen(false)}
          />
          <div
            className="relative bg-white rounded-t-3xl w-full max-w-md"
            onMouseDown={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between px-4 py-3 border-b border-border/50">
              <div className="w-8" />
              <h3 className="text-base font-semibold text-gray-800">用药时间</h3>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="p-1 rounded-lg hover:bg-gray-100"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <div className="flex items-center justify-center gap-12 py-4">
              <div className="relative">
                <div
                  ref={hoursRef}
                  className="w-16 h-[240px] overflow-y-auto"
                  style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' } as React.CSSProperties}
                  onScroll={handleHoursScroll}
                >
                  <div style={{ height: ITEM_HEIGHT * 2 }} />
                  {HOURS.map((hour) => (
                    <div
                      key={hour}
                      className={`w-16 h-12 flex items-center justify-center text-xl ${
                        selectedHour === hour
                          ? 'text-gray-900 font-semibold'
                          : 'text-gray-300'
                      }`}
                      style={{ scrollSnapAlign: 'center' } as React.CSSProperties}
                    >
                      {hour}
                    </div>
                  ))}
                  <div style={{ height: ITEM_HEIGHT * 2 }} />
                </div>
                <div 
                  className="absolute left-0 right-0 border-y-2 border-primary/30 pointer-events-none"
                  style={{ top: ITEM_HEIGHT * 2, height: ITEM_HEIGHT }}
                />
              </div>

              <div className="text-2xl font-bold text-gray-900 pb-1">:</div>

              <div className="relative">
                <div
                  ref={minutesRef}
                  className="w-16 h-[240px] overflow-y-auto"
                  style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' } as React.CSSProperties}
                  onScroll={handleMinutesScroll}
                >
                  <div style={{ height: ITEM_HEIGHT * 2 }} />
                  {MINUTES.map((minute) => (
                    <div
                      key={minute}
                      className={`w-16 h-12 flex items-center justify-center text-xl ${
                        selectedMinute === minute
                          ? 'text-gray-900 font-semibold'
                          : 'text-gray-300'
                      }`}
                      style={{ scrollSnapAlign: 'center' } as React.CSSProperties}
                    >
                      {minute}
                    </div>
                  ))}
                  <div style={{ height: ITEM_HEIGHT * 2 }} />
                </div>
                <div 
                  className="absolute left-0 right-0 border-y-2 border-primary/30 pointer-events-none"
                  style={{ top: ITEM_HEIGHT * 2, height: ITEM_HEIGHT }}
                />
              </div>
            </div>

            <div className="px-4 pb-6 pt-2">
              <button
                type="button"
                onClick={handleConfirm}
                className="w-full py-3.5 bg-primary text-white rounded-2xl text-base font-medium hover:opacity-90 active:opacity-80 transition-opacity"
              >
                确定
              </button>
            </div>
          </div>
        </div>
      )}

      <style>{`
        div::-webkit-scrollbar {
          display: none;
        }
      `}</style>
    </div>
  );
}
