import { useSettingsStore } from '../../stores/useSettingsStore';
import { formatCurrencyFull, calculateDailyCost } from '../../utils/currencyHelper';
import { daysSince } from '../../utils/dateHelper';
import { ITEM_STATUS_LABELS } from '../../utils/constants';
import type { ItemWithDetails } from '../../types/item';

interface ItemCardProps {
  item: ItemWithDetails;
  onClick: () => void;
}

const CATEGORY_EMOJI: Record<string, string> = {
  Smartphone: '💻',
  Sofa: '🛋️',
  CookingPot: '🍳',
  Shirt: '👔',
  BookOpen: '📚',
  Pill: '💊',
  Wrench: '🔧',
  Package: '📦',
  Camera: '📷',
  Headphones: '🎧',
  Watch: '⌚',
  Car: '🚗',
};

export default function ItemCard({ item, onClick }: ItemCardProps) {
  const { currencySymbol } = useSettingsStore();

  // Use purchase_date if available, otherwise fall back to created_at or today
  const effectiveDate = item.purchase_date || item.created_at?.slice(0, 10) || new Date().toISOString().slice(0, 10);
  const days = daysSince(effectiveDate);
  const dailyCost = item.purchase_price > 0 && days >= 0
    ? calculateDailyCost(item.purchase_price * item.quantity, Math.max(1, days))
    : null;

  // Priority: item.icon > category_icon mapping > default
  const emoji = item.icon
    ? item.icon
    : item.category_icon && CATEGORY_EMOJI[item.category_icon]
    ? CATEGORY_EMOJI[item.category_icon]
    : '📦';

  return (
    <div
      onClick={onClick}
      className="bg-white rounded-[20px] shadow-sm border border-border/50 overflow-hidden cursor-pointer active:scale-[0.98] transition-transform"
    >
      {/* Top section with icon and status */}
      <div className="p-4 pb-2">
        <div className="flex items-start justify-between mb-3">
          <div className="w-14 h-14 bg-gray-50 rounded-2xl flex items-center justify-center text-3xl">
            {emoji}
          </div>
          <span
            className={`text-xs px-2.5 py-1 rounded-full shrink-0 ${
              item.status === 'active'
                ? 'bg-green-50 text-green-600'
                : item.status === 'archived'
                ? 'bg-yellow-50 text-yellow-600'
                : 'bg-gray-100 text-gray-500'
            }`}
          >
            {ITEM_STATUS_LABELS[item.status]}
          </span>
        </div>

        {/* Name */}
        <h3 className="text-base font-semibold text-gray-800 truncate mb-1">{item.name}</h3>

        {/* Price + days */}
        <p className="text-xs text-gray-400 mb-3">
          {formatCurrencyFull(item.purchase_price * item.quantity, currencySymbol)}
          {days > 0 && (
            <span className="ml-1">· 已使用 {days} 天</span>
          )}
        </p>
      </div>

      {/* Daily cost bar */}
      {dailyCost !== null && (
        <div className="px-4 pb-4">
          <div className="bg-primary/5 rounded-xl px-3 py-2 flex items-center justify-between">
            <span className="text-xs text-gray-500">成本</span>
            <span className="text-sm font-bold text-primary font-mono">
              {formatCurrencyFull(dailyCost, currencySymbol)}/天
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
