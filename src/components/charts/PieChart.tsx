import * as React from 'react';
import { Pie, PieChart as RePieChart, Cell } from 'recharts';
import {
  ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from './Chart';
import { cn } from '../../lib/utils';
import { formatCurrency } from '../../utils/currencyHelper';

export interface PieChartData {
  name: string;
  value: number;
  color: string;
}

interface PieChartProps extends React.HTMLAttributes<HTMLDivElement> {
  data: PieChartData[];
  height?: number;
  innerRadius?: number;
  outerRadius?: number;
  config?: ChartConfig;
  currencySymbol?: string;
  showLegend?: boolean;
}

export function PieChartComponent({
  data,
  height = 350,
  innerRadius = 60,
  outerRadius = 90,
  config,
  currencySymbol = '¥',
  showLegend = true,
  className,
  ...props
}: PieChartProps) {
  const chartConfig = React.useMemo(() => {
    const cfg: ChartConfig = {};
    data.forEach((item, _index) => {
      cfg[item.name] = {
        label: item.name,
        color: item.color,
      };
    });
    return cfg;
  }, [data]);

  const total = React.useMemo(() => {
    return data.reduce((sum, item) => sum + item.value, 0);
  }, [data]);

  if (data.length === 0) {
    return (
      <div className="flex items-center justify-center" style={{ height }}>
        <p className="text-sm text-muted">暂无数据</p>
      </div>
    );
  }

  return (
    <div className={cn('w-full', className)} {...props}>
      <ChartContainer config={chartConfig} className="mx-auto aspect-square h-[200px] w-full">
        <RePieChart>
          <ChartTooltip
            cursor={false}
            content={
              <ChartTooltipContent
                hideLabel
                formatter={(value) => [formatCurrency(Number(value), currencySymbol), '']}
              />
            }
          />
          <Pie
            data={data}
            dataKey="value"
            nameKey="name"
            innerRadius={innerRadius}
            outerRadius={outerRadius}
            strokeWidth={0}
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
        </RePieChart>
      </ChartContainer>

      {showLegend && (
        <div className="mt-4 space-y-2">
          {data.map((item, index) => {
            const percentage = ((item.value / total) * 100).toFixed(1);
            return (
              <div key={index} className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
                  <span className="text-gray-600">{item.name}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-mono font-medium text-gray-800">
                    {formatCurrency(item.value, currencySymbol)}
                  </span>
                  <span className="text-xs text-gray-400 w-10 text-right">{percentage}%</span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
