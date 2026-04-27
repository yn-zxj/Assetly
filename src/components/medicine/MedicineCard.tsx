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
      className="bg-white rounded-[20px] p-3 border border-border/50 cursor-pointer hover:shadow-md transition-shadow"
    >
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-green-50 rounded-full flex items-center justify-center shrink-0 relative">
          <Pill className="w-5 h-5 text-green-500" />
          {!!medicine.is_taking && (
            <div className="absolute -top-1 -right-1 w-4 h-4 bg-primary rounded-full flex items-center justify-center">
              <Bell className="w-2.5 h-2.5 text-white" />
            </div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          {/* Row 1: name + type tag + expiry badge */}
          <div className="flex items-center gap-2 mb-0.5">
            <h3 className="text-sm font-semibold text-gray-800 truncate">{medicine.name}</h3>
            {MEDICINE_TYPE_LABELS[medicine.medicine_type] && (
              <span className="shrink-0 text-[10px] px-1.5 py-0.5 bg-blue-50 text-blue-600 rounded-full">
                {MEDICINE_TYPE_LABELS[medicine.medicine_type]}
              </span>
            )}
            {!!medicine.is_taking && (
              <span className="shrink-0 text-[10px] px-1.5 py-0.5 bg-green-50 text-green-600 rounded-full">
                服用中
              </span>
            )}
            <div className="ml-auto shrink-0">
              <ExpiryBadge expiryDate={medicine.expiry_date} />
            </div>
          </div>

          {/* Row 2: frequency/time or dosage instructions */}
          {!!medicine.is_taking && (frequencyDisplay || timeSlotsDisplay) ? (
            <p className="text-xs text-gray-500 truncate">
              {frequencyDisplay}{frequencyDisplay && timeSlotsDisplay ? ' ' : ''}{timeSlotsDisplay}
              {durationDisplay && <span className="text-gray-400"> · {durationDisplay}</span>}
            </p>
          ) : medicine.dosage_instructions && medicine.dosage_instructions !== '0' ? (
            <p className="text-xs text-gray-500 truncate">{medicine.dosage_instructions}</p>
          ) : null}

          {/* Row 3: location + price + stock (all in one row) */}
          <div className="flex items-center justify-between gap-2 mt-1">
            <div className="flex items-center gap-3 min-w-0 flex-1">
              {medicine.location_full_path && (
                <div className="flex items-center gap-0.5 min-w-0">
                  <MapPin className="w-3 h-3 text-gray-300 shrink-0" />
                  <span className="text-xs text-gray-400 truncate">{medicine.location_full_path.replace(/\//g, ' > ')}</span>
                </div>
              )}
              <span className="text-xs text-muted shrink-0">
                库存 {medicine.remaining_quantity > 0 ? medicine.remaining_quantity : medicine.quantity} {medicine.unit || '片'}
              </span>
              {medicine.purchase_price > 0 && (
                <span className="text-xs font-semibold text-primary font-mono shrink-0">
                  {formatCurrency(medicine.purchase_price, currencySymbol)}
                </span>
              )}
            </div>
            {onUpdateQuantity && (
              <div className="flex items-center gap-1 shrink-0">
                <button
                  onClick={(e) => handleQuantityChange(e, -1)}
                  disabled={medicine.remaining_quantity <= 0}
                  className="w-6 h-6 rounded-md bg-gray-100 flex items-center justify-center hover:bg-gray-200 active:bg-gray-300 transition-colors disabled:opacity-30"
                >
                  <Minus className="w-3 h-3 text-gray-600" />
                </button>
                <button
                  onClick={(e) => handleQuantityChange(e, 1)}
                  className="w-6 h-6 rounded-md bg-primary/10 flex items-center justify-center hover:bg-primary/20 active:bg-primary/30 transition-colors"
                >
                  <Plus className="w-3 h-3 text-primary" />
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
