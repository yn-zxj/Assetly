import { useEffect, useState } from 'react';
import { Plus, Edit2, Trash2, X } from 'lucide-react';
import { useCategoryStore } from '../stores/useCategoryStore';
import { getCategoryItemCount } from '../services/categoryService';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import type { CategoryFormData } from '../types/category';

const ICON_OPTIONS = ['Smartphone', 'Sofa', 'CookingPot', 'Shirt', 'BookOpen', 'Pill', 'Wrench', 'Package', 'Camera', 'Headphones', 'Watch', 'Car'];
const COLOR_OPTIONS = ['#3B82F6', '#8B5CF6', '#F97316', '#EC4899', '#06B6D4', '#22C55E', '#78716C', '#6B7280', '#EF4444', '#F59E0B'];

export default function Categories() {
  const { categories, fetchCategories, addCategory, updateCategory, deleteCategory } = useCategoryStore();
  const [editId, setEditId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [deleteCount, setDeleteCount] = useState(0);
  const [form, setForm] = useState<CategoryFormData>({ name: '', icon: 'Package', color: '#6B7280' });

  useEffect(() => { fetchCategories(); }, [fetchCategories]);

  const openAdd = () => {
    setEditId(null);
    setForm({ name: '', icon: 'Package', color: '#6B7280' });
    setShowForm(true);
  };

  const openEdit = (id: string) => {
    const cat = categories.find((c) => c.id === id);
    if (cat) {
      setEditId(id);
      setForm({ name: cat.name, icon: cat.icon, color: cat.color });
      setShowForm(true);
    }
  };

  const handleDelete = async (id: string) => {
    const count = await getCategoryItemCount(id);
    setDeleteCount(count);
    setDeleteId(id);
  };

  const confirmDelete = async () => {
    if (deleteId) {
      await deleteCategory(deleteId);
      setDeleteId(null);
    }
  };

  const handleSave = async () => {
    if (!form.name.trim()) return;
    if (editId) {
      await updateCategory(editId, form);
    } else {
      await addCategory(form);
    }
    setShowForm(false);
  };

  const iconEmoji = (icon: string) => {
    const map: Record<string, string> = {
      Smartphone: '📱', Sofa: '🛋️', CookingPot: '🍳', Shirt: '👔',
      BookOpen: '📚', Pill: '💊', Wrench: '🔧', Package: '📦',
      Camera: '📷', Headphones: '🎧', Watch: '⌚', Car: '🚗',
    };
    return map[icon] || '📦';
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <div className="flex items-center justify-between mb-5">
        <h1 className="text-xl font-bold text-gray-800">分类管理</h1>
        <button
          onClick={openAdd}
          className="flex items-center gap-1.5 px-4 py-2.5 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90"
        >
          <Plus className="w-4 h-4" /> 添加分类
        </button>
      </div>

      <div className="space-y-2">
        {categories.map((cat) => (
          <div key={cat.id} className="flex items-center gap-3 bg-white rounded-[16px] p-3.5 border border-border/50">
            <div
              className="w-10 h-10 rounded-full flex items-center justify-center text-lg"
              style={{ backgroundColor: cat.color + '20' }}
            >
              {iconEmoji(cat.icon)}
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium text-gray-800">{cat.name}</p>
            </div>
            <div className="flex gap-1">
              <button onClick={() => openEdit(cat.id)} className="p-2 rounded-lg hover:bg-gray-100">
                <Edit2 className="w-4 h-4 text-gray-400" />
              </button>
              <button onClick={() => handleDelete(cat.id)} className="p-2 rounded-lg hover:bg-red-50">
                <Trash2 className="w-4 h-4 text-gray-400" />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Add/Edit Modal */}
      {showForm && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/40" onClick={() => setShowForm(false)} />
          <div className="relative bg-white rounded-[20px] p-6 w-full max-w-sm shadow-xl">
            <button onClick={() => setShowForm(false)} className="absolute top-4 right-4 p-1 rounded-full hover:bg-gray-100">
              <X className="w-4 h-4 text-gray-400" />
            </button>
            <h3 className="text-lg font-semibold text-gray-800 mb-4">{editId ? '编辑分类' : '添加分类'}</h3>

            <div className="space-y-4">
              <input
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="分类名称"
                className="w-full px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary"
              />

              <div>
                <p className="text-xs text-muted mb-2">图标</p>
                <div className="flex flex-wrap gap-2">
                  {ICON_OPTIONS.map((icon) => (
                    <button
                      key={icon}
                      type="button"
                      onClick={() => setForm({ ...form, icon })}
                      className={`w-9 h-9 rounded-lg flex items-center justify-center text-lg ${
                        form.icon === icon ? 'ring-2 ring-primary bg-primary/5' : 'bg-gray-50'
                      }`}
                    >
                      {iconEmoji(icon)}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <p className="text-xs text-muted mb-2">颜色</p>
                <div className="flex flex-wrap gap-2">
                  {COLOR_OPTIONS.map((color) => (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setForm({ ...form, color })}
                      className={`w-8 h-8 rounded-full ${
                        form.color === color ? 'ring-2 ring-offset-2 ring-primary' : ''
                      }`}
                      style={{ backgroundColor: color }}
                    />
                  ))}
                </div>
              </div>

              <button
                onClick={handleSave}
                disabled={!form.name.trim()}
                className="w-full py-2.5 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90 disabled:opacity-50"
              >
                {editId ? '保存修改' : '添加'}
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={Boolean(deleteId)}
        title="删除分类"
        message={deleteCount > 0
          ? `该分类下有 ${deleteCount} 件物品，删除后这些物品将变为"未分类"。确定要删除吗？`
          : '确定要删除该分类吗？'}
        confirmLabel="删除"
        danger
        onConfirm={confirmDelete}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
}
