import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../state/app_controller.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'item_detail_screen.dart';
import 'smart_entry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: '物语',
            subtitle: '${_formatChineseDate(DateTime.now())} · 家庭资产全景',
            actions: [
              IconAction(
                icon: LucideIcons.search,
                onPressed: () => onNavigate(1),
                tooltip: '搜索',
              ),
              const SizedBox(width: 8),
              IconAction(
                icon: LucideIcons.bell,
                onPressed: () => _alerts(context),
                badge: state.expiringMedicines.isNotEmpty,
                tooltip: '提醒',
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: pagePadding,
          sliver: SliverList.list(
            children: [
              _AssetHero(
                totalValue: state.totalValue,
                activeCount: state.activeCount,
                dailyCost: state.totalDailyCost,
                onScan: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SmartEntryScreen(initialMode: EntryMode.barcode),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SmartEntryScreen(initialMode: EntryMode.ai),
                  ),
                ),
                child: Row(
                  children: [
                    const TintedIcon(icon: LucideIcons.sparkles),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI 拍照录入',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '多模态识别物品与药品，自动填充表单',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: context.colors.mutedForeground,
                    ),
                  ],
                ),
              ),
              if (state.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                _AnalyticsCard(items: state.items),
              ],
              const SizedBox(height: 12),
              _MedicationBoard(state: state),
              if (state.expiringMedicines.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ExpiryAlert(
                  name: state.expiringMedicines.first.name,
                  days: state.expiringMedicines.first.daysUntilExpiry,
                  location: state.expiringMedicines.first.locationPath,
                ),
              ],
              const SizedBox(height: 12),
              SectionTitle(
                '在役资产精选',
                trailing: TextButton(
                  onPressed: () => onNavigate(1),
                  child: Text('查看全部 ${state.items.length} >'),
                ),
              ),
              if (state.items.isEmpty)
                EmptyState(
                  title: '资产库还是空的',
                  description: '从第一件物品开始建立你的本地资产档案',
                  action: FilledButton.icon(
                    onPressed: () => onNavigate(1),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('添加第一件物品'),
                  ),
                )
              else
                ...state.items
                    .take(4)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _HomeItemTile(item: item),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _alerts(BuildContext context) {
    final state = AppScope.of(context);
    showAssetlySheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(title: '提醒与预警', subtitle: '临期、库存与质保提醒集中在这里'),
            if (state.expiringMedicines.isEmpty)
              const EmptyState(
                icon: LucideIcons.bellOff,
                title: '目前没有提醒',
                description: '临期药品、低库存和质保提醒会显示在这里',
              ),
            ...state.expiringMedicines.map(
              (m) => ListTile(
                leading: const TintedIcon(
                  icon: LucideIcons.alertTriangle,
                  color: Color(0xFFD97706),
                  size: 38,
                  iconSize: 18,
                  radius: AppCorner.sm,
                ),
                title: Text(m.name),
                subtitle: Text(
                  '${m.daysUntilExpiry} 天后到期 · 剩余 ${m.remainingQuantity.toStringAsFixed(0)} ${m.unit}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetHero extends StatelessWidget {
  const _AssetHero({
    required this.totalValue,
    required this.activeCount,
    required this.dailyCost,
    required this.onScan,
  });

  final double totalValue;
  final int activeCount;
  final double dailyCost;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    return ShadCard(
      padding: EdgeInsets.zero,
      clip: true,
      elevated: true,
      borderColor: accent.withValues(alpha: context.isDark ? .3 : .2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: context.isDark ? .26 : .14),
          context.colors.card,
        ],
        stops: const [0, .82],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            top: -64,
            child: Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: context.isDark ? .2 : .12),
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '家庭资产总值',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                      ),
                    ),
                    const Spacer(),
                    AppBadge('在役中 $activeCount 件', color: accent),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnimatedMoney(
                        value: totalValue,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ScanOrb(onTap: onScan),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroStat(
                      label: '日均消耗',
                      value: '¥${dailyCost.toStringAsFixed(1)} / 天',
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: context.colors.border,
                    ),
                    _HeroStat(label: '数据存储', value: '仅保存在本机'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      Text(value, style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}

class _ScanOrb extends StatelessWidget {
  const _ScanOrb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ElasticPress(
        maxGrowth: 6,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colors.primary,
                  Color.lerp(context.colors.primary, Colors.black, .18)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.scanLine,
              size: 25,
              color: context.colors.onPrimary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '扫码录入',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _HomeItemTile extends StatelessWidget {
  const _HomeItemTile({required this.item});
  final AssetItem item;

  @override
  Widget build(BuildContext context) => ShadCard(
    padding: const EdgeInsets.all(12),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: context.colors.muted,
            shape: AppShape.all(AppCorner.md),
          ),
          child: ItemIconArt(item.icon, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 3),
              Text(
                [
                  if (item.locationPath.isNotEmpty) item.locationPath,
                  '服役 ${item.daysInService} 天',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppBadge(
              '¥ ${item.dailyCost.toStringAsFixed(1)} / 天',
              color: item.status == 'idle'
                  ? const Color(0xFFD97706)
                  : context.colors.accent,
            ),
            const SizedBox(height: 5),
            Text(
              '原价 ¥${NumberFormat('#,##0').format(item.purchasePrice)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MedicationBoard extends StatelessWidget {
  const _MedicationBoard({required this.state});
  final AppController state;

  @override
  Widget build(BuildContext context) {
    final pending = state.takingMedicines
        .where((m) => !state.wasTakenToday(m))
        .length;
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TintedIcon(
                icon: LucideIcons.pill,
                size: 36,
                iconSize: 18,
                radius: AppCorner.sm,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '今日服药看板',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppBadge(
                '待服 $pending 项',
                color: pending == 0
                    ? context.colors.accent
                    : const Color(0xFFD97706),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (state.takingMedicines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '暂无进行中的用药计划，可前往药箱添加。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            ...state.takingMedicines
                .take(2)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        AppBadge(
                          m.slots.isEmpty ? '--:--' : m.slots.first,
                          icon: LucideIcons.clock3,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                m.dosageInstructions.isEmpty
                                    ? '未填写服用说明'
                                    : m.dosageInstructions,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CheckButton(
                          done: state.wasTakenToday(m),
                          onPressed: () async {
                            await state.takeDose(m);
                            if (context.mounted) {
                              showTopNotice(
                                context,
                                '${m.name} 已完成今日打卡，库存已同步更新',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onPressed});
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElasticPress(
    maxGrowth: 5,
    enabled: !done,
    child: GestureDetector(
      onTap: done ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: ShapeDecoration(
          color: done ? context.colors.muted : context.colors.primary,
          shape: AppShape.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done) ...[
              Icon(
                LucideIcons.check,
                size: 13,
                color: context.colors.mutedForeground,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              done ? '已打卡' : '打卡',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: done
                    ? context.colors.mutedForeground
                    : context.colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.items});
  final List<AssetItem> items;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = _monthlyPurchases(
      items,
      from: DateTime(now.year, now.month - 5),
    );
    final currentMonth = months.lastOrNull;
    final activeItems = items
        .where((item) => item.status != 'disposed')
        .toList();
    final total = activeItems.fold<double>(
      0,
      (sum, item) => sum + item.purchasePrice,
    );
    final categories = _categoryValues(activeItems);
    final leadingCategory = categories.entries.firstOrNull;
    final leadingPercent = total <= 0 || leadingCategory == null
        ? 0.0
        : leadingCategory.value / total;
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TintedIcon(
                icon: LucideIcons.areaChart,
                size: 36,
                iconSize: 18,
                radius: AppCorner.sm,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '数据统计与趋势',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => _showFullAnalytics(context, items),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('近 6 个月'),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('本月新增资产金额', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥ ${NumberFormat('#,##0.00').format(currentMonth?.amount ?? 0)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${currentMonth?.itemCount ?? 0} 件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 118, child: _PurchaseTrendChart(months: months)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppCorner.full),
            child: LinearProgressIndicator(
              value: leadingPercent,
              minHeight: 7,
              backgroundColor: context.colors.muted,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leadingCategory == null
                    ? '暂无分类数据'
                    : '${leadingCategory.key} ${(leadingPercent * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '总资产 ¥${NumberFormat.compact().format(total)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseTrendChart extends StatelessWidget {
  const _PurchaseTrendChart({required this.months});
  final List<_MonthlyPurchase> months;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    final maxAmount = months.fold<double>(0, (value, month) {
      return month.amount > value ? month.amount : value;
    });
    final chartMax = maxAmount <= 0 ? 1.0 : maxAmount * 1.18;
    final spots = [
      for (var index = 0; index < months.length; index++)
        FlSpot(index.toDouble(), months[index].amount),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).clamp(1, double.infinity).toDouble(),
        minY: 0,
        maxY: chartMax,
        clipData: const FlClipData.all(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.colors.border.withValues(alpha: .55),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (value != index || index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    '${months[index].month.month}月',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchSpotThreshold: 22,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(AppCorner.md),
            getTooltipColor: (_) => Theme.of(context).colorScheme.onSurface,
            getTooltipItems: (spots) => spots.map((spot) {
              final month = months[spot.x.round()];
              return LineTooltipItem(
                '${month.month.year}年${month.month.month}月\n¥${NumberFormat('#,##0.00').format(month.amount)} · ${month.itemCount} 件',
                TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: .32,
            preventCurveOverShooting: true,
            barWidth: 2.6,
            color: accent,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: spot.x == months.length - 1 ? 3.4 : 2.2,
                color: accent,
                strokeWidth: 2,
                strokeColor: context.colors.card,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: .3),
                  accent.withValues(alpha: .01),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }
}

class _MonthlyPurchase {
  const _MonthlyPurchase({
    required this.month,
    required this.amount,
    required this.itemCount,
  });

  final DateTime month;
  final double amount;
  final int itemCount;
}

String _formatChineseDate(DateTime date) {
  const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  return '${date.year}年${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
}

List<_MonthlyPurchase> _monthlyPurchases(
  List<AssetItem> items, {
  DateTime? from,
}) {
  final now = DateTime.now();
  final datedItems = items
      .map((item) => DateTime.tryParse(item.purchaseDate))
      .whereType<DateTime>()
      .where((date) => !date.isAfter(now))
      .toList();
  final earliest =
      from ??
      (datedItems.isEmpty
          ? now
          : datedItems.reduce((a, b) => a.isBefore(b) ? a : b));
  var cursor = DateTime(earliest.year, earliest.month);
  final lastMonth = DateTime(now.year, now.month);
  final result = <_MonthlyPurchase>[];

  while (!cursor.isAfter(lastMonth)) {
    final nextMonth = DateTime(cursor.year, cursor.month + 1);
    var amount = 0.0;
    var itemCount = 0;

    for (final item in items) {
      final purchaseDate = DateTime.tryParse(item.purchaseDate);
      if (purchaseDate != null &&
          purchaseDate.year == cursor.year &&
          purchaseDate.month == cursor.month) {
        itemCount++;
        amount += item.purchasePrice;
      }
    }

    result.add(
      _MonthlyPurchase(month: cursor, amount: amount, itemCount: itemCount),
    );
    cursor = nextMonth;
  }
  return result;
}

Map<String, double> _categoryValues(List<AssetItem> items) {
  final values = <String, double>{};
  for (final item in items) {
    final category = item.categoryName.trim().isEmpty
        ? '未分类'
        : item.categoryName;
    values.update(
      category,
      (value) => value + item.purchasePrice,
      ifAbsent: () => item.purchasePrice,
    );
  }
  final entries = values.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

Future<void> _showFullAnalytics(
  BuildContext context,
  List<AssetItem> items,
) async {
  final months = _monthlyPurchases(items);
  final activeItems = items.where((item) => item.status != 'disposed').toList();
  final total = activeItems.fold<double>(
    0,
    (sum, item) => sum + item.purchasePrice,
  );
  final currentMonth = months.lastOrNull;
  final categories = _categoryValues(activeItems);
  final range = months.isEmpty
      ? '暂无月份记录'
      : '${months.first.month.year}年${months.first.month.month}月至今';

  await showAssetlySheet<void>(
    context,
    ListView(
      key: UniqueKey(),
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        SheetHeader(title: '完整数据统计', subtitle: '$range · 数据来自本机物品记录'),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: '在役资产',
                value: '${activeItems.length} 件',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: '资产原值',
                value: '¥${NumberFormat.compact().format(total)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: '本月新增',
                value:
                    '¥${NumberFormat.compact().format(currentMonth?.amount ?? 0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionTitle('分类占比', subtitle: '按当前在役资产原值计算'),
        if (categories.isEmpty)
          Text('暂无分类数据', style: Theme.of(context).textTheme.bodySmall)
        else
          ...categories.entries.map((entry) {
            final percent = total <= 0 ? 0.0 : entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text(
                        '¥${NumberFormat('#,##0').format(entry.value)} · ${(percent * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppCorner.full),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 7,
                      backgroundColor: context.colors.muted,
                      color: context.colors.accent,
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        const SectionTitle('全部月份', subtitle: '按购买日期归属月份，每件物品只统计一次'),
        ...months.reversed.map(
          (month) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: context.colors.muted,
                shape: AppShape.all(AppCorner.sm),
              ),
              child: Text(
                '${month.month.month}月',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            title: Text('${month.month.year}年${month.month.month}月'),
            subtitle: Text('${month.itemCount} 件新增物品'),
            trailing: Text(
              '¥${NumberFormat('#,##0.00').format(month.amount)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExpiryAlert extends StatelessWidget {
  const _ExpiryAlert({
    required this.name,
    required this.days,
    required this.location,
  });
  final String name, location;
  final int days;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: ShapeDecoration(
      color: const Color(
        0xFFD97706,
      ).withValues(alpha: context.isDark ? .16 : .08),
      shape: AppShape.all(
        AppCorner.md,
        border: const Color(0xFFD97706).withValues(alpha: .28),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          LucideIcons.alertTriangle,
          color: Color(0xFFD97706),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '临期提醒：$name 剩余 $days 天到期',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '存放空间：$location',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
