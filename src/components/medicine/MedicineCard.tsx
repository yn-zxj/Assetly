import { Pill, MapPin, Minus, Plus, Bell } from 'lucide-react';
import ExpiryBadge from './ExpiryBadge';
import { useSettingsStore } from '../../stores/useSettingsStore';
import { formatCurrency } from '../../utils/currencyHelper';
import { MEDICINE_TYPE_LABELS } from '../../utils/constants';
import type { MedicineWithItem } from '../../types/medicine';

interface MedicineCardProps {
  medicine: MedicineWithItem;
  onClick: () => void;
  onUpdateQuantity?: (itemId: string, delta: number) => void;
}

export default function MedicineCard({ medicine, onClick, onUpdateQuantity }: MedicineCardProps) {
  const { currencySymbol } = useSettingsStore();

  const handleQuantityChange = (e: React.MouseEvent, delta: number) => {
    e.stopPropagation();
    onUpdateQuantity?.(medicine.item_id, delta);
  };

  // Format time slots for display - only show if has valid time slots
  const timeSlotsDisplay = medicine.time_slots
    ? medicine.time_slots.split(',').filter(Boolean).join(', ')
    : '';

  // Format frequency for display - only show if has valid data
  const getFrequencyDisplay = (): string | null => {
    if (!medicine.is_taking) return null;
    switch (medicine.frequency_type) {
      case 'daily':
        return '每天';
      case 'every_n_days':
        return medicine.frequency_days > 0 ? `每${medicine.frequency_days}天` : null;
      case 'weekly': {
        const days = medicine.week_days
          .split(',')
          .filter(Boolean)
          .map((d) => '日一二三四五六'[parseInt(d)])
          .join('、');
        return days ? `每周${days}` : null;
      }
      default:
        return null;
    }
  };
  const frequencyDisplay = getFrequencyDisplay();

  // Format duration for display
  const durationDisplay =
    medicine.duration_start && medicine.duration_end
      ? `${medicine.duration_start} 至 ${medicine.duration_end}`
      : medicine.duration_start
        ? `${medicine.duration_start} 起`
        : medicine.duration_end
          ? `至 ${medicine.duration_end}`
          : '';

  return (
    <div
      onClick={onClick}
      className="bg-white rounded-[20px] p-4 border border-border/50 cursor-pointer hover:shadow-md transition-shadow"
    >
      <div className="flex items-start gap-3">
        <div className="w-12 h-12 bg-green-50 rounded-full flex items-center justify-center shrink-0 relative">
          <Pill className="w-6 h-6 text-green-500" />
          {medicine.is_taking && (
            <div className="absolute -top-1 -right-1 w-5 h-5 bg-primary rounded-full flex items-center justify-center">
              <Bell className="w-3 h-3 text-white" />
            </div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2 mb-1">
            <h3 className="text-sm font-semibold text-gray-800 truncate">{medicine.name}</h3>
            <ExpiryBadge expiryDate={medicine.expiry_date} />
          </div>

          <div className="flex flex-wrap gap-2 mb-2">
            <span className="text-xs px-2 py-0.5 bg-blue-50 text-blue-600 rounded-full">
              {MEDICINE_TYPE_LABELS[medicine.medicine_type]}
            </span>
            {medicine.is_taking && (
              <span className="text-xs px-2 py-0.5 bg-green-50 text-green-600 rounded-full">
                正在服用
              </span>
            )}
          </div>

          {medicine.is_taking && (frequencyDisplay || timeSlotsDisplay) && (
            <>
              <p className="text-xs text-gray-500 mb-1">
                {frequencyDisplay}{frequencyDisplay && timeSlotsDisplay ? ' ' : ''}{timeSlotsDisplay}
              </p>
              {durationDisplay && (
                <p className="text-xs text-gray-400">{durationDisplay}</p>
              )}
            </>
          )}

          {medicine.dosage_instructions && !medicine.is_taking && (
            <p className="text-xs text-gray-500 mb-1.5 line-clamp-1">{medicine.dosage_instructions}</p>
          )}

          <div className="flex items-center justify-between">
            {medicine.location_full_path && (
              <div className="flex items-center gap-1">
                <MapPin className="w-3 h-3 text-gray-300" />
                <span className="text-xs text-gray-400 truncate">{medicine.location_full_path.replace(/\//g, ' > ')}</span>
              </div>
            )}
            {medicine.purchase_price > 0 && (
              <span className="text-sm font-bold text-primary font-mono">
                {formatCurrency(medicine.purchase_price, currencySymbol)}
              </span>
            )}
          </div>

          {/* Quick quantity controls */}
          <div className="flex items-center justify-between mt-2.5 pt-2.5 border-t border-gray-50">
            <span className="text-xs text-muted">
              库存 {medicine.remaining_quantity} {medicine.unit}
            </span>
            {onUpdateQuantity && (
              <div className="flex items-center gap-1">
                <button
                  onClick={(e) => handleQuantityChange(e, -1)}
                  disabled={medicine.remaining_quantity <= 0}
                  className="w-7 h-7 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 active:bg-gray-300 transition-colors disabled:opacity-30"
                >
                  <Minus className="w-3.5 h-3.5 text-gray-600" />
                </button>
                <button
                  onClick={(e) => handleQuantityChange(e, 1)}
                  className="w-7 h-7 rounded-lg bg-primary/10 flex items-center justify-center hover:bg-primary/20 active:bg-primary/30 transition-colors"
                >
                  <Plus className="w-3.5 h-3.5 text-primary" />
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
