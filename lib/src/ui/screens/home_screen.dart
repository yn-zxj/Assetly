import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
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
              ShadCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TOTAL ASSETS VALUE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .5,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppBadge(
                          '在役中 ${state.activeCount} 件',
                          color: context.colors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥ ${NumberFormat('#,##0.00').format(state.totalValue)}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppBadge(
                          '日均消耗: ¥${state.totalDailyCost.toStringAsFixed(1)} / 天',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '数据仅保存在本机',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (state.items.isNotEmpty) ...[
                _AnalyticsCard(items: state.items),
                const SizedBox(height: 12),
              ],
              ShadCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.pill,
                          size: 18,
                          color: context.colors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '今日服药看板',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        AppBadge(
                          '待服 ${state.takingMedicines.where((m) => !state.wasTakenToday(m)).length} 项',
                          color: const Color(0xFFD97706),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                        ),
                                        Text(
                                          '${m.slots.isEmpty ? '--' : m.slots.first} · ${m.dosageInstructions}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 34,
                                    child: FilledButton(
                                      onPressed: state.wasTakenToday(m)
                                          ? null
                                          : () async {
                                              await state.takeDose(m);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${m.name} 已完成今日打卡，库存已同步更新',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      child: Text(
                                        state.wasTakenToday(m) ? '已打卡' : '快捷打卡',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SmartEntryScreen(initialMode: EntryMode.barcode),
                        ),
                      ),
                      icon: const Icon(LucideIcons.scanLine, size: 18),
                      label: const Text('扫条码 / 药监码'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SmartEntryScreen(initialMode: EntryMode.ai),
                        ),
                      ),
                      icon: const Icon(LucideIcons.sparkles, size: 18),
                      label: const Text('AI 拍照录入'),
                    ),
                  ),
                ],
              ),
              if (state.expiringMedicines.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ExpiryAlert(
                  name: state.expiringMedicines.first.name,
                  days: state.expiringMedicines.first.daysUntilExpiry,
                  location: state.expiringMedicines.first.locationPath,
                ),
              ],
              const SizedBox(height: 18),
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShadCard(
                          padding: const EdgeInsets.all(10),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: item),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.colors.muted,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  item.icon,
                                  style: const TextStyle(fontSize: 21),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '${item.locationPath} · 服役 ${item.daysInService} 天',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '原价 ¥${NumberFormat('#,##0').format(item.purchasePrice)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                leading: const Icon(
                  LucideIcons.alertTriangle,
                  color: Color(0xFFD97706),
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
    final maxAmount = months.fold<double>(0, (value, month) {
      return month.amount > value ? month.amount : value;
    });
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
              const Icon(LucideIcons.barChart3, size: 17),
              const SizedBox(width: 7),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('近 6 个月'),
                    SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('本月新增资产金额', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥ ${NumberFormat('#,##0.00').format(currentMonth?.amount ?? 0)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 6),
              Text(
                '${currentMonth?.itemCount ?? 0} 件',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: Row(
              children: [
                for (final month in months)
                  _MiniBar(
                    month: month.month,
                    value: maxAmount == 0 ? 0 : month.amount / maxAmount,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: leadingPercent,
              minHeight: 6,
              backgroundColor: context.colors.muted,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(height: 6),
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

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.month, required this.value});
  final DateTime month;
  final double value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: value == 0 ? 2 : 42 * value,
                decoration: BoxDecoration(
                  color:
                      month.year == DateTime.now().year &&
                          month.month == DateTime.now().month
                      ? Theme.of(context).colorScheme.onSurface
                      : context.colors.muted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text('${month.month}月', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
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
              padding: const EdgeInsets.only(bottom: 10),
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
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
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
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.muted,
                borderRadius: BorderRadius.circular(9),
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
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      border: Border.all(color: const Color(0xFFFDE68A)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(
          LucideIcons.alertTriangle,
          color: Color(0xFFD97706),
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '临期提醒：$name 剩余 $days 天到期',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
              Text(
                '存放空间：$location',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFA16207),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
