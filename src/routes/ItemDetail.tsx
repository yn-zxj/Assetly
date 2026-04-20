import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Edit2, Trash2, MapPin, Tag, Calendar, DollarSign } from 'lucide-react';
import { getItemById } from '../services/itemService';
import { useItemStore } from '../stores/useItemStore';
import { useSettingsStore } from '../stores/useSettingsStore';
import { formatCurrencyFull, calculateDailyCost } from '../utils/currencyHelper';
import { formatDate, daysSince } from '../utils/dateHelper';
import { ITEM_STATUS_LABELS } from '../utils/constants';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import type { ItemWithDetails } from '../types/item';

export default function ItemDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { deleteItem } = useItemStore();
  const { currencySymbol } = useSettingsStore();
  const [item, setItem] = useState<ItemWithDetails | null>(null);
  const [showDelete, setShowDelete] = useState(false);

  useEffect(() => {
    if (id) getItemById(id).then(setItem);
  }, [id]);

  const handleDelete = async () => {
    if (id) {
      await deleteItem(id);
      navigate('/items', { replace: true });
    }
  };

  if (!item) {
    return (
      <div className="flex justify-center py-16">
        <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Use purchase_date if available, otherwise fall back to created_at or today
  const effectiveDate = item.purchase_date || item.created_at?.slice(0, 10) || new Date().toISOString().slice(0, 10);
  const days = daysSince(effectiveDate);
  const dailyCost = item.purchase_price > 0 && days >= 0
    ? calculateDailyCost(item.purchase_price * item.quantity, Math.max(1, days))
    : null;

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <button onClick={() => navigate(-1)} className="p-2 rounded-[10px] hover:bg-gray-100">
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </button>
        <div className="flex gap-2">
          <button
            onClick={() => navigate(`/items/${id}/edit`)}
            className="p-2 rounded-[10px] hover:bg-gray-100"
          >
            <Edit2 className="w-5 h-5 text-gray-600" />
          </button>
          <button
            onClick={() => setShowDelete(true)}
            className="p-2 rounded-[10px] hover:bg-red-50"
          >
            <Trash2 className="w-5 h-5 text-danger" />
          </button>
        </div>
      </div>

      {/* Icon */}
      <div className="h-48 bg-gray-100 rounded-[20px] flex items-center justify-center mb-5">
        <span className="text-7xl">{item.icon || '📦'}</span>
      </div>

      {/* Name & Status */}
      <div className="flex items-start justify-between mb-4">
        <h1 className="text-2xl font-bold text-gray-800">{item.name}</h1>
        <span className={`text-xs px-3 py-1 rounded-full ${
          item.status === 'active' ? 'bg-green-50 text-green-600' :
          item.status === 'archived' ? 'bg-yellow-50 text-yellow-600' :
          'bg-gray-100 text-gray-500'
        }`}>
          {ITEM_STATUS_LABELS[item.status]}
        </span>
      </div>

      {/* Price */}
      <div className="bg-white rounded-[20px] p-4 border border-border/50 mb-4">
        <p className="text-3xl font-bold text-primary font-mono">
          {formatCurrencyFull(item.purchase_price * item.quantity, currencySymbol)}
        </p>
        {dailyCost !== null && (
          <p className="text-sm text-muted mt-1">
            日均成本 <span className="font-mono font-medium text-gray-700">{formatCurrencyFull(dailyCost, currencySymbol)}</span>
            <span className="text-gray-400"> ({days} 天)</span>
          </p>
        )}
      </div>

      {/* Info Cards */}
      <div className="space-y-3">
        {item.category_name && (
          <div className="flex items-center gap-3 bg-white rounded-[16px] p-3.5 border border-border/50">
            <div className="w-9 h-9 rounded-full flex items-center justify-center" style={{ backgroundColor: item.category_color + '20' }}>
              <Tag className="w-4 h-4" style={{ color: item.category_color }} />
            </div>
            <div>
              <p className="text-xs text-muted">分类</p>
              <p className="text-sm font-medium text-gray-800">{item.category_name}</p>
            </div>
          </div>
        )}

        {item.location_full_path && (
          <div className="flex items-center gap-3 bg-white rounded-[16px] p-3.5 border border-border/50">
            <div className="w-9 h-9 bg-blue-50 rounded-full flex items-center justify-center">
              <MapPin className="w-4 h-4 text-blue-500" />
            </div>
            <div>
              <p className="text-xs text-muted">位置</p>
              <p className="text-sm font-medium text-gray-800">{item.location_full_path.replace(/\//g, ' > ')}</p>
            </div>
          </div>
        )}

        {item.purchase_date && (
          <div className="flex items-center gap-3 bg-white rounded-[16px] p-3.5 border border-border/50">
            <div className="w-9 h-9 bg-orange-50 rounded-full flex items-center justify-center">
              <Calendar className="w-4 h-4 text-orange-500" />
            </div>
            <div>
              <p className="text-xs text-muted">购买日期</p>
              <p className="text-sm font-medium text-gray-800">{formatDate(item.purchase_date)}</p>
            </div>
          </div>
        )}

        <div className="flex items-center gap-3 bg-white rounded-[16px] p-3.5 border border-border/50">
          <div className="w-9 h-9 bg-purple-50 rounded-full flex items-center justify-center">
            <DollarSign className="w-4 h-4 text-purple-500" />
          </div>
          <div>
            <p className="text-xs text-muted">数量</p>
            <p className="text-sm font-medium text-gray-800">{item.quantity} 件</p>
          </div>
        </div>

        {item.description && (
          <div className="bg-white rounded-[16px] p-3.5 border border-border/50">
            <p className="text-xs text-muted mb-1">备注</p>
            <p className="text-sm text-gray-700">{item.description}</p>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={showDelete}
        title="删除物品"
        message={`确定要删除"${item.name}"吗？此操作无法撤销。`}
        confirmLabel="删除"
        danger
        onConfirm={handleDelete}
        onCancel={() => setShowDelete(false)}
      />
    </div>
  );
}
