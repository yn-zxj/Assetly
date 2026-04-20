import { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Search } from 'lucide-react';
import { useItemStore } from '../stores/useItemStore';
import { useCategoryStore } from '../stores/useCategoryStore';
import { useSettingsStore } from '../stores/useSettingsStore';
import { formatCurrencyFull, calculateDailyCost } from '../utils/currencyHelper';
import ItemCard from '../components/items/ItemCard';
import EmptyState from '../components/shared/EmptyState';
import CustomSelect from '../components/shared/CustomSelect';

const STATUS_OPTIONS = [
  { value: 'all', label: '全部' },
  { value: 'active', label: '服役中' },
  { value: 'archived', label: '已闲置' },
  { value: 'disposed', label: '已处置' },
];

export default function ItemList() {
  const navigate = useNavigate();
  const { items, loading, fetchItems, filter, setFilter } = useItemStore();
  const { categories, fetchCategories } = useCategoryStore();
  const { currencySymbol } = useSettingsStore();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    fetchItems();
    fetchCategories();
  }, [fetchItems, fetchCategories]);

  useEffect(() => {
    const timer = setTimeout(() => {
      setFilter({ search: search || undefined });
      fetchItems();
    }, 300);
    return () => clearTimeout(timer);
  }, [search, setFilter, fetchItems]);

  const handleStatusChange = (val: string) => {
    setStatusFilter(val);
    setFilter({ status: val === 'all' ? undefined : val });
    fetchItems();
  };

  const handleCategoryFilter = (categoryId: string) => {
    setFilter({ category_id: categoryId || undefined });
    fetchItems();
  };

  const stats = useMemo(() => {
    const active = items.filter((i) => i.status === 'active').length;
    const archived = items.filter((i) => i.status === 'archived').length;
    const disposed = items.filter((i) => i.status === 'disposed').length;
    const totalValue = items
      .filter((i) => i.status === 'active')
      .reduce((sum, i) => sum + i.purchase_price * i.quantity, 0);
    // Calculate total daily cost for all active items
    let totalDailyCost = 0;
    items.filter((i) => i.status === 'active').forEach((item) => {
      const effectiveDate = item.purchase_date || item.created_at?.slice(0, 10) || new Date().toISOString().slice(0, 10);
      const days = Math.max(1, Math.floor((Date.now() - new Date(effectiveDate).getTime()) / (1000 * 60 * 60 * 24)));
      if (item.purchase_price > 0) {
        totalDailyCost += calculateDailyCost(item.purchase_price * item.quantity, days);
      }
    });
    return { active, archived, disposed, totalValue, totalDailyCost };
  }, [items]);

  return (
    <div className="p-4 md:p-6 max-w-6xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <h1 className="text-xl font-bold text-gray-800">我的物品</h1>
        <button
          onClick={() => navigate('/items/new')}
          className="flex items-center gap-1.5 px-4 py-2.5 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90 transition-opacity"
        >
          <Plus className="w-4 h-4" />
          添加
        </button>
      </div>

      {/* Stats Overview */}
      <div className="bg-white rounded-[20px] p-4 border border-border/50 mb-4">
        <div className="flex items-baseline gap-2 mb-2">
          <span className="text-2xl font-bold text-gray-800 font-mono">
            {formatCurrencyFull(stats.totalValue, currencySymbol)}
          </span>
          <span className="text-xs text-muted">总资产</span>
        </div>
        {stats.totalDailyCost > 0 && (
          <p className="text-xs text-gray-500 mb-3">
            日均成本 <span className="font-mono font-medium text-primary">{formatCurrencyFull(stats.totalDailyCost, currencySymbol)}</span>
          </p>
        )}
        <div className="flex gap-4 text-xs text-gray-500">
          <span>服役中 <strong className="text-gray-800">{stats.active}</strong></span>
          <span>已闲置 <strong className="text-gray-800">{stats.archived}</strong></span>
          <span>已处置 <strong className="text-gray-800">{stats.disposed}</strong></span>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="flex gap-2 mb-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="搜索物品名称..."
            className="w-full pl-9 pr-3 py-2.5 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
          />
        </div>
        <div className="w-28">
          <CustomSelect
            value={statusFilter}
            onChange={handleStatusChange}
            options={STATUS_OPTIONS}
            placeholder="状态"
          />
        </div>
      </div>

      {/* Category Chips */}
      <div className="flex gap-2 overflow-x-auto pb-2 mb-4 scrollbar-hide">
        <button
          onClick={() => handleCategoryFilter('')}
          className={`shrink-0 px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
            !filter.category_id
              ? 'bg-gray-800 text-white'
              : 'bg-white text-gray-600 border border-border'
          }`}
        >
          全部
        </button>
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => handleCategoryFilter(cat.id)}
            className={`shrink-0 px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
              filter.category_id === cat.id
                ? 'bg-gray-800 text-white'
                : 'bg-white text-gray-600 border border-border'
            }`}
          >
            {cat.name}
          </button>
        ))}
      </div>

      {/* Item Grid */}
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      ) : items.length === 0 ? (
        <EmptyState
          title="暂无物品"
          description="点击右上角按钮添加你的第一件物品"
          action={
            <button
              onClick={() => navigate('/items/new')}
              className="px-4 py-2 bg-primary text-white rounded-[12px] text-sm font-medium"
            >
              添加物品
            </button>
          }
        />
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 md:gap-4">
          {items.map((item) => (
            <ItemCard
              key={item.id}
              item={item}
              onClick={() => navigate(`/items/${item.id}`)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
