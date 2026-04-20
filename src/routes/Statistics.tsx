import { useEffect } from 'react';
import { useDashboardStore } from '../stores/useDashboardStore';
import { useSettingsStore } from '../stores/useSettingsStore';
import { formatCurrency } from '../utils/currencyHelper';
import { getMonthLabel } from '../utils/dateHelper';
import { AreaChartComponent as AreaChart } from '../components/charts/AreaChart';
import { PieChartComponent as PieChart } from '../components/charts/PieChart';

export default function Statistics() {
  const { categoryDistribution, monthlySpending, stats, loading, fetchDashboardData } = useDashboardStore();
  const { currencySymbol } = useSettingsStore();

  useEffect(() => {
    fetchDashboardData();
  }, [fetchDashboardData]);

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const chartSpending = monthlySpending.map((item) => ({
    label: getMonthLabel(item.month),
    value: item.amount,
  }));

  return (
    <div className="p-4 md:p-6 max-w-5xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <h1 className="text-xl font-bold text-gray-800 mb-5">数据统计</h1>

      {/* Summary */}
      <div className="grid grid-cols-2 gap-3 mb-6">
        <div className="bg-white rounded-[20px] p-4 border border-border/50">
          <p className="text-xs text-muted mb-1">总资产价值</p>
          <p className="text-2xl font-bold text-primary font-mono">
            {formatCurrency(stats.total_value, currencySymbol)}
          </p>
        </div>
        <div className="bg-white rounded-[20px] p-4 border border-border/50">
          <p className="text-xs text-muted mb-1">物品总数</p>
          <p className="text-2xl font-bold text-gray-800 font-mono">
            {stats.total_items} <span className="text-sm font-normal text-muted">件</span>
          </p>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        {/* Pie Chart - Asset Distribution */}
        <div className="bg-white rounded-[20px] p-5 border border-border/50">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">资产分布</h2>
          {categoryDistribution.length === 0 ? (
            <p className="text-sm text-gray-400 py-12 text-center">暂无数据，添加物品后查看</p>
          ) : (
            <PieChart
              data={categoryDistribution}
              height={210}
              innerRadius={45}
              outerRadius={80}
              currencySymbol={currencySymbol}
            />
          )}
        </div>

        {/* Area Chart - Monthly Spending */}
        <div className="bg-white rounded-[20px] p-5 border border-border/50">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">消费趋势 (近6个月)</h2>
          {chartSpending.length === 0 ? (
            <p className="text-sm text-gray-400 py-12 text-center">暂无消费数据</p>
          ) : (
            <AreaChart
              data={chartSpending}
              height={210}
              currencySymbol={currencySymbol}
              showDots
            />
          )}
        </div>
      </div>
    </div>
  );
}
