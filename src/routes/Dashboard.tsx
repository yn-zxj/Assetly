import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Package, Plus, Pill, BarChart3, AlertTriangle, TrendingUp, ArrowRight, Clock } from 'lucide-react';
import { useDashboardStore } from '../stores/useDashboardStore';
import { useSettingsStore } from '../stores/useSettingsStore';
import { formatCurrency } from '../utils/currencyHelper';
import { getExpiryStatus } from '../utils/dateHelper';
import ExpiryBadge from '../components/medicine/ExpiryBadge';
import { getTakingMedicines } from '../services/medicineService';
import { PieChartComponent as PieChart } from '../components/charts/PieChart';
import type { MedicineWithItem } from '../types/medicine';

export default function Dashboard() {
  const navigate = useNavigate();
  const { stats, categoryDistribution, expiringMedicines, loading, fetchDashboardData } = useDashboardStore();
  const { currencySymbol } = useSettingsStore();
  const [takingMedicines, setTakingMedicines] = useState<MedicineWithItem[]>([]);

  useEffect(() => {
    fetchDashboardData();
    loadTakingMedicines();
  }, [fetchDashboardData]);

  const loadTakingMedicines = async () => {
    try {
      const medicines = await getTakingMedicines();
      setTakingMedicines(medicines);
    } catch (error) {
      console.error('Failed to load taking medicines:', error);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="p-4 md:p-6 max-w-5xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      {/* Greeting */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800">家庭物品管家</h1>
        <p className="text-sm text-muted mt-1">掌控你的家庭资产</p>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        <StatCard
          label="总资产"
          value={formatCurrency(stats.total_value, currencySymbol)}
          color="bg-primary/10 text-primary"
          icon={<TrendingUp className="w-5 h-5" />}
        />
        <StatCard
          label="物品总数"
          value={`${stats.total_items}`}
          suffix="件"
          color="bg-blue-50 text-blue-500"
          icon={<Package className="w-5 h-5" />}
        />
        <StatCard
          label="药品数量"
          value={`${stats.medicine_count}`}
          suffix="种"
          color="bg-green-50 text-green-500"
          icon={<Pill className="w-5 h-5" />}
        />
        <StatCard
          label="过期预警"
          value={`${stats.expiring_count}`}
          suffix="项"
          color={stats.expiring_count > 0 ? 'bg-red-50 text-red-500' : 'bg-gray-50 text-gray-400'}
          icon={<AlertTriangle className="w-5 h-5" />}
        />
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <button
          onClick={() => navigate('/items/new')}
          className="flex flex-col items-center gap-2 p-4 bg-white rounded-[20px] border border-border/50 hover:shadow-md transition-shadow"
        >
          <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Plus className="w-5 h-5 text-primary" />
          </div>
          <span className="text-xs font-medium text-gray-600">添加物品</span>
        </button>
        <button
          onClick={() => navigate('/medicine/new')}
          className="flex flex-col items-center gap-2 p-4 bg-white rounded-[20px] border border-border/50 hover:shadow-md transition-shadow"
        >
          <div className="w-10 h-10 bg-green-50 rounded-full flex items-center justify-center">
            <Pill className="w-5 h-5 text-green-500" />
          </div>
          <span className="text-xs font-medium text-gray-600">添加药品</span>
        </button>
        <button
          onClick={() => navigate('/statistics')}
          className="flex flex-col items-center gap-2 p-4 bg-white rounded-[20px] border border-border/50 hover:shadow-md transition-shadow"
        >
          <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center">
            <BarChart3 className="w-5 h-5 text-blue-500" />
          </div>
          <span className="text-xs font-medium text-gray-600">查看统计</span>
        </button>
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        {/* Expiring Medicines */}
        <div className="bg-white rounded-[20px] p-4 border border-border/50">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-semibold text-gray-700">药品预警</h2>
            <button onClick={() => navigate('/medicine')} className="text-xs text-primary flex items-center gap-0.5">
              查看全部 <ArrowRight className="w-3 h-3" />
            </button>
          </div>
          {expiringMedicines.length === 0 ? (
            <p className="text-sm text-gray-400 py-6 text-center">暂无过期预警</p>
          ) : (
            <div className="space-y-2.5">
              {expiringMedicines.slice(0, 5).map((med) => (
                <div
                  key={med.id}
                  onClick={() => navigate(`/medicine/${med.item_id}/edit`)}
                  className="flex items-center justify-between cursor-pointer hover:bg-gray-50 rounded-[12px] p-2 -mx-2 transition-colors"
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <Pill className={`w-4 h-4 shrink-0 ${
                      getExpiryStatus(med.expiry_date) === 'expired' ? 'text-red-400' : 'text-amber-400'
                    }`} />
                    <span className="text-sm text-gray-700 truncate">{med.name}</span>
                  </div>
                  <ExpiryBadge expiryDate={med.expiry_date} />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Currently Taking Medicines */}
        {takingMedicines.length > 0 && (
          <div className="bg-white rounded-[20px] p-4 border border-border/50">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-sm font-semibold text-gray-700">正在服用</h2>
              <button onClick={() => navigate('/medicine')} className="text-xs text-primary flex items-center gap-0.5">
                查看全部 <ArrowRight className="w-3 h-3" />
              </button>
            </div>
            <div className="space-y-2.5">
              {takingMedicines.slice(0, 5).map((med) => (
                <div
                  key={med.id}
                  onClick={() => navigate(`/medicine/${med.item_id}/edit`)}
                  className="cursor-pointer hover:bg-gray-50 rounded-[12px] p-2 -mx-2 transition-colors"
                >
                  <div className="flex items-center gap-2.5 mb-1.5">
                    <Clock className="w-4 h-4 shrink-0 text-green-500" />
                    <span className="text-sm font-medium text-gray-800 truncate">{med.name}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-gray-500 ml-6">
                    {med.frequency_type === 'daily' && <span>每天</span>}
                    {med.frequency_type === 'every_n_days' && med.frequency_days > 0 && (
                      <span>每{med.frequency_days}天</span>
                    )}
                    {med.frequency_type === 'weekly' && med.week_days && (
                      <span>
                        每周
                        {med.week_days.split(',').filter(Boolean).map((d) => '日一二三四五六'[parseInt(d)]).join('、')}
                      </span>
                    )}
                    {med.time_slots && (
                      <span className="flex items-center gap-1">
                        <span className="text-gray-300">|</span>
                        {med.time_slots.split(',').filter(Boolean).slice(0, 3).join('、')}
                        {med.time_slots.split(',').filter(Boolean).length > 3 && '...'}
                      </span>
                    )}
                  </div>
                  {med.duration_start && med.duration_end && (
                    <div className="text-xs text-gray-400 ml-6 mt-0.5">
                      {med.duration_start} 至 {med.duration_end}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Category Distribution */}
        <div className="bg-white rounded-[20px] p-4 border border-border/50">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-semibold text-gray-700">资产分布</h2>
            <button onClick={() => navigate('/statistics')} className="text-xs text-primary flex items-center gap-0.5">
              详细报表 <ArrowRight className="w-3 h-3" />
            </button>
          </div>
          {categoryDistribution.length === 0 ? (
            <p className="text-sm text-gray-400 py-6 text-center">暂无数据</p>
          ) : (
            <PieChart
              data={categoryDistribution.slice(0, 5)}
              height={160}
              innerRadius={30}
              outerRadius={55}
              currencySymbol={currencySymbol}
              showLegend
            />
          )}
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, suffix, color, icon }: {
  label: string; value: string; suffix?: string; color: string; icon: React.ReactNode;
}) {
  return (
    <div className="bg-white rounded-[20px] p-4 border border-border/50">
      <div className={`w-9 h-9 rounded-full flex items-center justify-center mb-2.5 ${color}`}>
        {icon}
      </div>
      <div className="flex items-baseline gap-1">
        <span className="text-xl font-bold text-gray-800 font-mono">{value}</span>
        {suffix && <span className="text-xs text-muted">{suffix}</span>}
      </div>
      <p className="text-xs text-muted mt-0.5">{label}</p>
    </div>
  );
}
