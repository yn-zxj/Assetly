import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Save, Trash2, Bell, Plus, X } from 'lucide-react';
import { useMedicineStore } from '../stores/useMedicineStore';
import { useItemStore } from '../stores/useItemStore';
import { getMedicineByItemId } from '../services/medicineService';
import LocationPicker from '../components/items/LocationPicker';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import DatePicker from '../components/shared/DatePicker';
import TimePicker from '../components/shared/TimePicker';
import CustomSelect from '../components/shared/CustomSelect';
import type { MedicineFormData, MedicineType, FrequencyType } from '../types/medicine';

const defaultForm: MedicineFormData = {
  name: '', description: '', category_id: '', location_id: '',
  purchase_date: '', purchase_price: 0, quantity: 1, image_path: '', icon: '',
  medicine_type: 'internal', expiry_date: '', dosage_instructions: '',
  remaining_quantity: 1, unit: '片', manufacturer: '',
  is_taking: false, frequency_type: 'daily', frequency_days: 1,
  week_days: '', time_slots: '', duration_start: '', duration_end: '',
};

const WEEK_DAYS = [
  { value: '1', label: '一' },
  { value: '2', label: '二' },
  { value: '3', label: '三' },
  { value: '4', label: '四' },
  { value: '5', label: '五' },
  { value: '6', label: '六' },
  { value: '0', label: '日' },
];

export default function MedicineForm() {
  const navigate = useNavigate();
  const { id: itemId } = useParams();
  const isEdit = Boolean(itemId);
  const { addMedicine, updateMedicine } = useMedicineStore();
  const { deleteItem } = useItemStore();
  const [form, setForm] = useState<MedicineFormData>(defaultForm);
  const [saving, setSaving] = useState(false);
  const [showDelete, setShowDelete] = useState(false);

  useEffect(() => {
    if (isEdit && itemId) {
      getMedicineByItemId(itemId).then((med) => {
        if (med) {
          setForm({
            name: med.name, description: med.description,
            category_id: med.category_id, location_id: med.location_id,
            purchase_date: med.purchase_date, purchase_price: med.purchase_price,
            quantity: med.quantity, image_path: med.image_path, icon: med.icon || '',
            medicine_type: med.medicine_type, expiry_date: med.expiry_date,
            dosage_instructions: med.dosage_instructions,
            remaining_quantity: med.remaining_quantity,
            unit: med.unit, manufacturer: med.manufacturer,
            is_taking: med.is_taking, frequency_type: med.frequency_type,
            frequency_days: med.frequency_days, week_days: med.week_days,
            time_slots: med.time_slots, duration_start: med.duration_start,
            duration_end: med.duration_end,
          });
        }
      });
    }
  }, [isEdit, itemId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.expiry_date) return;
    setSaving(true);
    try {
      if (isEdit && itemId) {
        await updateMedicine(itemId, form);
      } else {
        await addMedicine(form);
      }
      navigate('/medicine');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (itemId) {
      await deleteItem(itemId);
      navigate('/medicine', { replace: true });
    }
  };

  const updateField = <K extends keyof MedicineFormData>(key: K, value: MedicineFormData[K]) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const addTimeSlot = () => {
    const slots = form.time_slots ? form.time_slots.split(',') : [];
    slots.push('08:00');
    updateField('time_slots', slots.join(','));
  };

  const removeTimeSlot = (index: number) => {
    const slots = form.time_slots.split(',');
    slots.splice(index, 1);
    updateField('time_slots', slots.join(','));
  };

  const updateTimeSlot = (index: number, value: string) => {
    const slots = form.time_slots.split(',');
    slots[index] = value;
    updateField('time_slots', slots.join(','));
  };

  const toggleWeekDay = (day: string) => {
    const days = form.week_days ? form.week_days.split(',').filter(Boolean) : [];
    const idx = days.indexOf(day);
    if (idx >= 0) {
      days.splice(idx, 1);
    } else {
      days.push(day);
    }
    updateField('week_days', days.sort().join(','));
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(-1)} className="p-2 rounded-[10px] hover:bg-gray-100">
            <ArrowLeft className="w-5 h-5 text-gray-600" />
          </button>
          <h1 className="text-xl font-bold text-gray-800">{isEdit ? '编辑药品' : '添加药品'}</h1>
        </div>
        {isEdit && (
          <button onClick={() => setShowDelete(true)} className="p-2 rounded-[10px] hover:bg-red-50">
            <Trash2 className="w-5 h-5 text-danger" />
          </button>
        )}
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Basic Info */}
        <div className="bg-white rounded-[20px] p-4 border border-border/50 space-y-4">
          <h2 className="text-sm font-semibold text-gray-700">基本信息</h2>
          <div>
            <label className="block text-sm text-gray-600 mb-1">药品名称 *</label>
            <input
              type="text" value={form.name}
              onChange={(e) => updateField('name', e.target.value)}
              placeholder="如: 布洛芬缓释胶囊"
              className="w-full px-3 py-2.5 border border-border rounded-[10px] text-sm outline-none focus:border-primary"
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm text-gray-600 mb-1">有效期 *</label>
              <DatePicker
                value={form.expiry_date}
                onChange={(v) => updateField('expiry_date', v)}
                placeholder="选择有效期"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-gray-600 mb-1">类型</label>
              <CustomSelect
                value={form.medicine_type}
                onChange={(v) => updateField('medicine_type', v as MedicineType)}
                options={[
                  { value: 'internal', label: '内服' },
                  { value: 'external', label: '外用' },
                  { value: 'emergency', label: '急救' },
                  { value: 'injection', label: '注射' },
                  { value: 'inhalation', label: '吸入' },
                  { value: 'ophthalmic', label: '眼用' },
                  { value: 'topical', label: '外用膏贴' },
                ]}
                placeholder="选择类型"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm text-gray-600 mb-1">服用/使用说明</label>
            <textarea
              value={form.dosage_instructions}
              onChange={(e) => updateField('dosage_instructions', e.target.value)}
              placeholder="如: 每日2次，每次1粒，饭后服用"
              rows={2}
              className="w-full px-3 py-2.5 border border-border rounded-[10px] text-sm outline-none focus:border-primary resize-none"
            />
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-sm text-gray-600 mb-1">剩余数量</label>
              <input
                type="number" min="0" value={form.remaining_quantity || ''}
                onChange={(e) => updateField('remaining_quantity', Number(e.target.value))}
                className="w-full px-3 py-2.5 border border-border rounded-[10px] text-sm outline-none focus:border-primary"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-600 mb-1">单位</label>
              <CustomSelect
                value={form.unit}
                onChange={(v) => updateField('unit', v)}
                options={[
                  { value: '片', label: '片' },
                  { value: '粒', label: '粒' },
                  { value: '支', label: '支' },
                  { value: '瓶', label: '瓶' },
                  { value: '盒', label: '盒' },
                  { value: '袋', label: '袋' },
                  { value: '包', label: '包' },
                  { value: '条', label: '条' },
                  { value: '贴', label: '贴' },
                  { value: '枚', label: '枚' },
                  { value: '滴', label: '滴' },
                  { value: '喷', label: '喷' },
                  { value: 'g', label: '克(g)' },
                  { value: 'mg', label: '毫克(mg)' },
                  { value: 'ml', label: '毫升(ml)' },
                ]}
                placeholder="选择单位"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-600 mb-1">生产厂商</label>
              <input
                type="text" value={form.manufacturer}
                onChange={(e) => updateField('manufacturer', e.target.value)}
                placeholder="厂商名称"
                className="w-full px-3 py-2.5 border border-border rounded-[10px] text-sm outline-none focus:border-primary"
              />
            </div>
          </div>
        </div>

        {/* Purchase Info */}
        <div className="bg-white rounded-[20px] p-4 border border-border/50 space-y-4">
          <h2 className="text-sm font-semibold text-gray-700">购买信息</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm text-gray-600 mb-1">购买日期</label>
              <DatePicker
                value={form.purchase_date}
                onChange={(v) => updateField('purchase_date', v)}
                placeholder="选择购买日期"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-600 mb-1">价格</label>
              <input
                type="number" min="0" step="0.01" value={form.purchase_price || ''}
                onChange={(e) => updateField('purchase_price', Number(e.target.value))}
                className="w-full px-3 py-2.5 border border-border rounded-[10px] text-sm outline-none focus:border-primary font-mono"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm text-gray-600 mb-1">存放位置</label>
            <LocationPicker value={form.location_id} onChange={(id) => updateField('location_id', id)} />
          </div>
        </div>

        {/* Medication Reminder */}
        <div className="bg-white rounded-[20px] p-4 border border-border/50 space-y-4">
          <div className="flex items-center gap-2">
            <Bell className="w-4 h-4 text-primary" />
            <h2 className="text-sm font-semibold text-gray-700">用药提醒</h2>
          </div>

          {/* Is Taking Toggle */}
          <div className="flex items-center justify-between">
            <label className="text-sm text-gray-600">是否正在服用</label>
            <button
              type="button"
              onClick={() => updateField('is_taking', !form.is_taking)}
              className={`relative w-11 h-6 rounded-full transition-colors ${form.is_taking ? 'bg-primary' : 'bg-gray-300'}`}
            >
              <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${form.is_taking ? 'translate-x-5' : ''}`} />
            </button>
          </div>

          {form.is_taking && (
            <>
              {/* Frequency Type */}
              <div>
                <label className="block text-sm text-gray-600 mb-1">用药频率</label>
                <CustomSelect
                  value={form.frequency_type}
                  onChange={(v) => updateField('frequency_type', v as FrequencyType)}
                  options={[
                    { value: 'daily', label: '每天' },
                    { value: 'every_n_days', label: '每几天' },
                    { value: 'weekly', label: '每周指定星期几' },
                  ]}
                  placeholder="选择频率"
                />
              </div>

              {/* Every N Days */}
              {form.frequency_type === 'every_n_days' && (
                <div>
                  <label className="block text-sm text-gray-600 mb-1">每隔几天服用</label>
                  <input
                    type="number" min="2" value={form.frequency_days || ''}
                    onChange={(e) => updateField('frequency_days', Number(e.target.value))}
                    className="w-full px-3 py-2.5 border border-border rounded-[10px] text-sm outline-none focus:border-primary"
                  />
                </div>
              )}

              {/* Week Days */}
              {form.frequency_type === 'weekly' && (
                <div>
                  <label className="block text-sm text-gray-600 mb-2">选择星期几服用</label>
                  <div className="flex gap-2">
                    {WEEK_DAYS.map((day) => {
                      const isSelected = form.week_days.split(',').includes(day.value);
                      return (
                        <button
                          key={day.value}
                          type="button"
                          onClick={() => toggleWeekDay(day.value)}
                          className={`flex-1 py-2 rounded-[10px] text-xs font-medium transition-colors ${
                            isSelected
                              ? 'bg-primary text-white'
                              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                          }`}
                        >
                          {day.label}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Time Slots */}
              <div>
                <label className="block text-sm text-gray-600 mb-2">用药时间</label>
                <div className="flex flex-wrap gap-2">
                  {form.time_slots.split(',').filter(Boolean).map((slot, index) => (
                    <div key={index} className="flex items-center gap-1 bg-gray-50 rounded-xl px-2 py-1">
                      <TimePicker
                        value={slot}
                        onChange={(v) => updateTimeSlot(index, v)}
                        placeholder="时间"
                      />
                      <button
                        type="button"
                        onClick={() => removeTimeSlot(index)}
                        className="p-1 rounded-lg hover:bg-red-100 text-gray-400 hover:text-danger"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))}
                  <button
                    type="button"
                    onClick={addTimeSlot}
                    className="flex items-center gap-1 px-3 py-2 border border-dashed border-gray-300 rounded-xl text-sm text-gray-500 hover:border-primary hover:text-primary transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    添加
                  </button>
                </div>
              </div>

              {/* Duration - Date Range */}
              <div>
                <label className="block text-sm text-gray-600 mb-2">服用周期</label>
                <div className="flex items-center gap-2">
                  <DatePicker
                    value={form.duration_start || ''}
                    onChange={(v) => updateField('duration_start', v)}
                    placeholder="开始日期"
                  />
                  <span className="text-gray-400 text-sm shrink-0">至</span>
                  <DatePicker
                    value={form.duration_end || ''}
                    onChange={(v) => updateField('duration_end', v)}
                    placeholder="结束日期"
                  />
                </div>
              </div>
            </>
          )}
        </div>

        <button
          type="submit"
          disabled={saving || !form.name.trim() || !form.expiry_date}
          className="w-full flex items-center justify-center gap-2 py-3 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90 disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          {saving ? '保存中...' : isEdit ? '保存修改' : '添加药品'}
        </button>
      </form>

      <ConfirmDialog
        open={showDelete}
        title="删除药品"
        message={`确定要删除"${form.name}"吗？此操作无法撤销。`}
        confirmLabel="删除"
        danger
        onConfirm={handleDelete}
        onCancel={() => setShowDelete(false)}
      />
    </div>
  );
}
