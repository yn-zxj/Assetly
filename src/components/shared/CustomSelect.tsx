import { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { ChevronDown, Check } from 'lucide-react';

export interface SelectOption {
  value: string;
  label: string;
}

interface CustomSelectProps {
  value: string;
  onChange: (value: string) => void;
  options: SelectOption[];
  placeholder?: string;
}

export default function CustomSelect({ value, onChange, options, placeholder = '请选择' }: CustomSelectProps) {
  const [open, setOpen] = useState(false);
  const triggerRef = useRef<HTMLDivElement>(null);

  // Lock body scroll when open
  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [open]);

  const selectedLabel = options.find((o) => o.value === value)?.label || '';

  const handleSelect = (val: string) => {
    onChange(val);
    setOpen(false);
  };

  return (
    <div ref={triggerRef} className="relative">
      <div
        onClick={() => setOpen(!open)}
        className={`w-full flex items-center justify-between px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm cursor-pointer hover:border-gray-300 transition-colors ${
          open ? 'border-primary ring-1 ring-primary/20' : ''
        }`}
      >
        <span className={selectedLabel ? 'text-gray-800' : 'text-gray-400'}>
          {selectedLabel || placeholder}
        </span>
        <ChevronDown className={`w-4 h-4 text-gray-400 shrink-0 transition-transform duration-200 ${open ? 'rotate-180' : ''}`} />
      </div>

      {open && createPortal(
        <div
          className="fixed inset-0 z-[9999] flex items-end justify-center bg-black/40 backdrop-blur-[2px]"
          onClick={(e) => { if (e.target === e.currentTarget) setOpen(false); }}
        >
          <div className="w-full max-w-lg bg-white rounded-t-2xl overflow-hidden animate-in slide-in-from-bottom duration-200 pb-[env(safe-area-inset-bottom,0px)]">
            {/* Handle bar */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-10 h-1 bg-gray-300 rounded-full" />
            </div>

            {/* Title */}
            <div className="px-4 pb-2">
              <p className="text-sm font-medium text-gray-500">{placeholder}</p>
            </div>

            {/* Options */}
            <div className="max-h-[50vh] overflow-y-auto">
              {options.map((option) => {
                const isActive = option.value === value;
                return (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => handleSelect(option.value)}
                    className={`w-full flex items-center justify-between px-5 py-3.5 text-left transition-colors ${
                      isActive
                        ? 'bg-primary/5 text-primary'
                        : 'text-gray-700 active:bg-gray-50'
                    }`}
                  >
                    <span className={`text-[15px] ${isActive ? 'font-medium' : ''}`}>
                      {option.label}
                    </span>
                    {isActive && <Check className="w-5 h-5 text-primary shrink-0" />}
                  </button>
                );
              })}
            </div>

            {/* Cancel button */}
            <div className="p-4 border-t border-border/50">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="w-full py-3 text-sm font-medium text-gray-500 bg-gray-50 rounded-xl active:bg-gray-100 transition-colors"
              >
                取消
              </button>
            </div>
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
