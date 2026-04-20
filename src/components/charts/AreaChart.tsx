import * as React from 'react';
import { Area, AreaChart as ReAreaChart, CartesianGrid, XAxis, YAxis } from 'recharts';
import {
  ChartConfig,
  ChartContainer,
} from './Chart';
import { cn } from '../../lib/utils';

export interface AreaChartData {
  label: string;
  value: number;
}

interface AreaChartProps extends React.HTMLAttributes<HTMLDivElement> {
  data: AreaChartData[];
  height?: number;
  config?: ChartConfig;
  showGrid?: boolean;
  showDots?: boolean;
  currencySymbol?: string;
}

export function AreaChartComponent({
  data,
  height = 350,
  config,
  showGrid = true,
  showDots = false,
  currencySymbol = '¥',
  className,
  ...props
}: AreaChartProps) {
  const chartConfig = config || {
    value: {
      label: '金额',
      color: 'hsl(var(--chart-1))',
    },
  };

  if (data.length === 0) {
    return (
      <div className="flex items-center justify-center" style={{ height }}>
        <p className="text-sm text-muted">暂无数据</p>
      </div>
    );
  }

  return (
    <div className={cn('w-full', className)} {...props}>
      <ChartContainer config={chartConfig} className="aspect-auto h-[200px] w-full">
        <ReAreaChart
          data={data}
          margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
        >
          <defs>
            <linearGradient id="fillAmount" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="var(--color-value)" stopOpacity={0.3} />
              <stop offset="95%" stopColor="var(--color-value)" stopOpacity={0} />
            </linearGradient>
          </defs>
          {showGrid && (
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--muted)/0.2)" vertical={false} />
          )}
          <XAxis
            dataKey="label"
            tickLine={false}
            axisLine={false}
            tickMargin={8}
            tick={{ fontSize: 12, fill: 'hsl(var(--muted))' }}
          />
          <YAxis
            tickLine={false}
            axisLine={false}
            tickMargin={8}
            tick={{ fontSize: 12, fill: 'hsl(var(--muted))' }}
            tickFormatter={(value) => `${currencySymbol}${value}`}
          />

          <Area
            dataKey="value"
            type="monotone"
            stroke="var(--color-value)"
            strokeWidth={2}
            fill="url(#fillAmount)"
            dot={showDots ? { r: 4 } : false}
            activeDot={false}
            isAnimationActive={false}
          />
        </ReAreaChart>
      </ChartContainer>
    </div>
  );
}
