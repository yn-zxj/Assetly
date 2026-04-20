import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Pill, AlertTriangle } from 'lucide-react';
import { useMedicineStore } from '../stores/useMedicineStore';
import MedicineCard from '../components/medicine/MedicineCard';
import EmptyState from '../components/shared/EmptyState';
import { MEDICINE_TYPE_LABELS } from '../utils/constants';
import { getExpiryStatus } from '../utils/dateHelper';
import type { MedicineType } from '../types/medicine';

const tabs: { key: MedicineType | 'all'; label: string }[] = [
  { key: 'all', label: '全部' },
  { key: 'internal', label: '内服' },
  { key: 'external', label: '外用' },
  { key: 'emergency', label: '急救' },
];

export default function MedicineBox() {
  const navigate = useNavigate();
  const { medicines, loading, activeTab, fetchMedicines, setActiveTab, updateMedicine } = useMedicineStore();
  const [initialized, setInitialized] = useState(false);

  useEffect(() => {
    fetchMedicines().then(() => setInitialized(true));
  }, [fetchMedicines]);

  useEffect(() => {
    if (initialized) fetchMedicines();
  }, [activeTab, initialized, fetchMedicines]);

  const handleUpdateQuantity = async (itemId: string, delta: number) => {
    const medicine = medicines.find((m) => m.item_id === itemId);
    if (!medicine) return;
    const newQuantity = Math.max(0, medicine.remaining_quantity + delta);
    await updateMedicine(itemId, { remaining_quantity: newQuantity });
  };

  const expiredCount = medicines.filter((m) => getExpiryStatus(m.expiry_date) === 'expired').length;
  const warningCount = medicines.filter((m) => getExpiryStatus(m.expiry_date) === 'warning').length;

  return (
    <div className="p-4 md:p-6 max-w-4xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <div>
          <h1 className="text-xl font-bold text-gray-800">家庭药箱</h1>
          <p className="text-sm text-muted mt-0.5">{medicines.length} 种药品</p>
        </div>
        <button
          onClick={() => navigate('/medicine/new')}
          className="flex items-center gap-1.5 px-4 py-2.5 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90"
        >
          <Plus className="w-4 h-4" /> 添加药品
        </button>
      </div>

      {/* Alert Banner */}
      {(expiredCount > 0 || warningCount > 0) && (
        <div className="bg-amber-50 border border-amber-200 rounded-[16px] p-3.5 mb-4 flex items-center gap-3">
          <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0" />
          <div className="text-sm">
            {expiredCount > 0 && <span className="text-red-600 font-medium">{expiredCount} 种已过期</span>}
            {expiredCount > 0 && warningCount > 0 && <span className="text-gray-400"> / </span>}
            {warningCount > 0 && <span className="text-amber-600 font-medium">{warningCount} 种即将过期</span>}
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 mb-4 bg-gray-100 rounded-[12px] p-1">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex-1 py-2 rounded-[10px] text-sm font-medium transition-colors ${
              activeTab === tab.key
                ? 'bg-white text-primary shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* List */}
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      ) : medicines.length === 0 ? (
        <EmptyState
          icon={<Pill className="w-8 h-8 text-gray-300" />}
          title={activeTab === 'all' ? '药箱是空的' : `暂无${MEDICINE_TYPE_LABELS[activeTab]}药品`}
          description="点击上方按钮添加药品"
        />
      ) : (
        <div className="space-y-3">
          {medicines.map((med) => (
            <MedicineCard
              key={med.id}
              medicine={med}
              onClick={() => navigate(`/medicine/${med.item_id}/edit`)}
              onUpdateQuantity={handleUpdateQuantity}
            />
          ))}
        </div>
      )}
    </div>
  );
}
