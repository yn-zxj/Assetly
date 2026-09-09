import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'items_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});
  final AssetItem item;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('物品详情与价值透视')),
    body: ListView(
      padding: pagePadding,
      children: [
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.muted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(item.icon, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      AppBadge(item.categoryName),
                      AppBadge(
                        item.status == 'active' ? '● 服役中' : '● 闲置',
                        color: item.status == 'active'
                            ? context.colors.accent
                            : const Color(0xFFD97706),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VALUE & DEPRECIATION ANALYTICS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 14),
              Text('日均成本引擎', style: Theme.of(context).textTheme.bodySmall),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥ ${item.dailyCost.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(width: 7),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/ 天 (当前累计摊薄)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '购买价格 ¥${NumberFormat('#,##0.00').format(item.purchasePrice)} ÷ 实际使用 ${item.daysInService} 天',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (item.daysInService / 1095).clamp(0, 1),
                  minHeight: 7,
                  backgroundColor: context.colors.muted,
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '预期服役周期 36 个月 · 已完成 ${(item.daysInService / 1095 * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _DetailRow(
                icon: LucideIcons.calendar,
                label: '购买日期',
                value:
                    '${item.purchaseDate.isEmpty ? '未记录' : item.purchaseDate} · 已服役 ${item.daysInService} 天',
              ),
              const Hairline(),
              _DetailRow(
                icon: LucideIcons.walletCards,
                label: '购买价格',
                value:
                    '¥ ${NumberFormat('#,##0.00').format(item.purchasePrice)}',
              ),
              const Hairline(),
              _DetailRow(
                icon: LucideIcons.shieldCheck,
                label: '质保与延保',
                value: item.warrantyExpiry.isEmpty
                    ? '未记录'
                    : item.warrantyExpiry,
              ),
              const Hairline(),
              _DetailRow(
                icon: LucideIcons.mapPin,
                label: '存放空间位置',
                value: item.locationPath.isEmpty ? '未设置' : item.locationPath,
              ),
              const Hairline(),
              _DetailRow(
                icon: LucideIcons.scanLine,
                label: '商品条形码',
                value: item.barcode.isEmpty ? '未记录' : item.barcode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(LucideIcons.pencil, size: 18),
                label: const Text('编辑资产'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text('删除资产'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    ),
  );

  Future<void> _edit(BuildContext context) async {
    final saved = await showItemForm(context, item: item);
    // Return to the live list after saving so stale detail values are never
    // left on screen and the edit result is immediately visible.
    if (saved && context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除这件物品？'),
            content: Text('“${item.name}”及其关联记录将从本机删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && context.mounted) {
      await AppScope.of(context).deleteItem(item.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.colors.mutedForeground),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ],
    ),
  );
}
