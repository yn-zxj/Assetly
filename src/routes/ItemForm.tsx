import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Save, X } from 'lucide-react';
import { useItemStore } from '../stores/useItemStore';
import { useCategoryStore } from '../stores/useCategoryStore';
import { getItemById } from '../services/itemService';
import LocationPicker from '../components/items/LocationPicker';
import DatePicker from '../components/shared/DatePicker';
import CustomSelect from '../components/shared/CustomSelect';
import EmojiPicker from '../components/shared/EmojiPicker';
import type { ItemFormData } from '../types/item';

const defaultForm: ItemFormData = {
  name: '',
  description: '',
  category_id: '',
  location_id: '',
  purchase_date: '',
  purchase_price: 0,
  quantity: 1,
  image_path: '',
  icon: '',
  status: 'active',
  is_medicine: false,
  warranty_expiry: '',
  shelf_life_expiry: '',
};

export default function ItemForm() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = Boolean(id);
  const { addItem, updateItem } = useItemStore();
  const { categories, fetchCategories } = useCategoryStore();
  const [form, setForm] = useState<ItemFormData>(defaultForm);
  const [saving, setSaving] = useState(false);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);

  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  useEffect(() => {
    if (isEdit && id) {
      getItemById(id).then((item) => {
        if (item) {
          setForm({
            name: item.name,
            description: item.description,
            category_id: item.category_id,
            location_id: item.location_id,
            purchase_date: item.purchase_date,
            purchase_price: item.purchase_price,
            quantity: item.quantity,
            image_path: item.image_path,
            icon: item.icon || '',
            status: item.status,
            is_medicine: Boolean(item.is_medicine),
            warranty_expiry: item.warranty_expiry || '',
            shelf_life_expiry: item.shelf_life_expiry || '',
          });
        }
      });
    }
  }, [isEdit, id]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) return;
    setSaving(true);
    try {
      if (isEdit && id) {
        await updateItem(id, form);
      } else {
        await addItem(form);
      }
      navigate(-1);
    } finally {
      setSaving(false);
    }
  };

  const updateField = <K extends keyof ItemFormData>(key: K, value: ItemFormData[K]) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <button
          onClick={() => navigate(-1)}
          className="p-2 rounded-[10px] hover:bg-gray-100 transition-colors"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </button>
        <h1 className="text-xl font-bold text-gray-800">
          {isEdit ? '编辑物品' : '添加物品'}
        </h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Icon & Name */}
        <div className="flex gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">图标</label>
            <button
              type="button"
              onClick={() => setShowEmojiPicker(!showEmojiPicker)}
              className="w-12 h-12 bg-white border border-border rounded-[10px] flex items-center justify-center text-2xl hover:border-primary transition-colors"
            >
              {form.icon || '📦'}
            </button>
          </div>
          <div className="flex-1">
            <label className="block text-sm font-medium text-gray-700 mb-1.5">名称 *</label>
            <input
              type="text"
              value={form.name}
              onChange={(e) => updateField('name', e.target.value)}
              placeholder="请输入物品名称"
              className="w-full px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
              required
            />
          </div>
        </div>

        {/* Emoji Picker */}
        {showEmojiPicker && (
          <div className="bg-white border border-border rounded-[16px] p-3 shadow-sm">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs text-muted">选择图标</span>
              {form.icon && (
                <button
                  type="button"
                  onClick={() => { updateField('icon', ''); setShowEmojiPicker(false); }}
                  className="text-xs text-red-500 flex items-center gap-0.5"
                >
                  <X className="w-3 h-3" /> 清除
                </button>
              )}
            </div>
            <EmojiPicker onSelect={(emoji) => { updateField('icon', emoji); setShowEmojiPicker(false); }} />
          </div>
        )}

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">描述/备注</label>
          <textarea
            value={form.description}
            onChange={(e) => updateField('description', e.target.value)}
            placeholder="可选填写物品描述"
            rows={3}
            className="w-full px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 resize-none"
          />
        </div>

        {/* Category */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">分类</label>
          <CustomSelect
            value={form.category_id}
            onChange={(v) => updateField('category_id', v)}
            options={[
              { value: '', label: '选择分类' },
              ...categories.map((cat) => ({ value: cat.id, label: cat.name })),
            ]}
            placeholder="选择分类"
          />
        </div>

        {/* Location */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">存放位置</label>
          <LocationPicker value={form.location_id} onChange={(id) => updateField('location_id', id)} />
        </div>

        {/* Purchase Date & Price */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">购买日期</label>
            <DatePicker
              value={form.purchase_date}
              onChange={(v) => updateField('purchase_date', v)}
              placeholder="选择购买日期"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">购买价格</label>
            <input
              type="number"
              min="0"
              step="0.01"
              value={form.purchase_price || ''}
              onChange={(e) => updateField('purchase_price', Number(e.target.value))}
              placeholder="0.00"
              className="w-full px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 font-mono"
            />
          </div>
        </div>

        {/* Warranty & Shelf Life Expiry */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">保修期至</label>
            <DatePicker
              value={form.warranty_expiry}
              onChange={(v) => updateField('warranty_expiry', v)}
              placeholder="选择保修期截止日期"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">保质期至</label>
            <DatePicker
              value={form.shelf_life_expiry}
              onChange={(v) => updateField('shelf_life_expiry', v)}
              placeholder="选择保质期截止日期"
            />
          </div>
        </div>

        {/* Quantity & Status */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">数量</label>
            <input
              type="number"
              min="1"
              value={form.quantity}
              onChange={(e) => updateField('quantity', Number(e.target.value))}
              className="w-full px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary/20"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">状态</label>
            <CustomSelect
              value={form.status}
              onChange={(v) => updateField('status', v as ItemFormData['status'])}
              options={[
                { value: 'active', label: '服役中' },
                { value: 'archived', label: '已闲置' },
                { value: 'disposed', label: '已处置' },
              ]}
              placeholder="选择状态"
            />
          </div>
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={saving || !form.name.trim()}
          className="w-full flex items-center justify-center gap-2 py-3 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          {saving ? '保存中...' : isEdit ? '保存修改' : '添加物品'}
        </button>
      </form>
    </div>
  );
}
