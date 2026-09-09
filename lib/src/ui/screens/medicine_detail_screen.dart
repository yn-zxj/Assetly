import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'medicine_form.dart';

class MedicineDetailScreen extends StatelessWidget {
  const MedicineDetailScreen({super.key, required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final type = medicineTypeOptions
        .where((option) => option.value == medicine.medicineType)
        .firstOrNull;
    final days = medicine.daysUntilExpiry;
    final hasExpiry = days != 999999;
    final expiryText = !hasExpiry
        ? '未设置有效期'
        : days < 0
        ? '已过期 ${-days} 天'
        : days == 0
        ? '今天到期'
        : '$days 天后到期';

    return Scaffold(
      appBar: AppBar(title: const Text('药品完整详情')),
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
                  color: context.colors.accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  type?.icon ?? LucideIcons.pill,
                  size: 30,
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppBadge(type?.label ?? '其他'),
                        AppBadge(
                          medicine.isTaking ? '正在服用' : '常备药品',
                          color: medicine.isTaking
                              ? context.colors.accent
                              : context.colors.mutedForeground,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      expiryText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasExpiry && days <= 30
                            ? const Color(0xFFD97706)
                            : null,
                      ),
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
                Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: context.colors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '服用 / 使用说明',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  medicine.dosageInstructions.isEmpty
                      ? '未填写服用/使用说明'
                      : medicine.dosageInstructions,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShadCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MedicineDetailRow(
                  icon: LucideIcons.packageCheck,
                  label: '当前库存',
                  value:
                      '${medicine.remainingQuantity.toStringAsFixed(0)} ${medicine.unit}',
                ),
                const Hairline(),
                _MedicineDetailRow(
                  icon: LucideIcons.calendarClock,
                  label: '有效期',
                  value: medicine.expiryDate.isEmpty
                      ? '未设置'
                      : '${medicine.expiryDate} · $expiryText',
                ),
                const Hairline(),
                _MedicineDetailRow(
                  icon: LucideIcons.factory,
                  label: '生产厂商',
                  value: medicine.manufacturer.isEmpty
                      ? '未记录'
                      : medicine.manufacturer,
                ),
                const Hairline(),
                _MedicineDetailRow(
                  icon: LucideIcons.mapPin,
                  label: '存放位置',
                  value: medicine.locationPath.isEmpty
                      ? '未设置'
                      : medicine.locationPath,
                ),
                const Hairline(),
                _MedicineDetailRow(
                  icon: LucideIcons.shoppingBag,
                  label: '购买信息',
                  value: _purchaseText(medicine),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.bellRing,
                      size: 18,
                      color: medicine.isTaking
                          ? context.colors.accent
                          : context.colors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '用药计划',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    AppBadge(medicine.isTaking ? '已开启' : '未开启'),
                  ],
                ),
                const SizedBox(height: 12),
                _PlanLine(label: '频率', value: _frequencyText(medicine)),
                const SizedBox(height: 8),
                _PlanLine(
                  label: '时间',
                  value: medicine.slots.isEmpty
                      ? '未设置'
                      : medicine.slots.join('、'),
                ),
                const SizedBox(height: 8),
                _PlanLine(label: '周期', value: _durationText(medicine)),
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
                  label: const Text('编辑药品'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context),
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: const Text('删除药品'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _purchaseText(Medicine medicine) {
    final date = medicine.purchaseDate.isEmpty
        ? '日期未记录'
        : medicine.purchaseDate;
    final price = medicine.purchasePrice == 0
        ? '价格未记录'
        : '¥${NumberFormat('#,##0.00').format(medicine.purchasePrice)}';
    return '$date · $price';
  }

  String _frequencyText(Medicine medicine) => switch (medicine.frequencyType) {
    'daily' => '每天',
    'weekly' => '每周',
    'interval' => '每 ${medicine.frequencyDays} 天',
    'as_needed' => '按需服用',
    _ => '未设置',
  };

  String _durationText(Medicine medicine) {
    if (medicine.durationStart.isEmpty && medicine.durationEnd.isEmpty) {
      return '未设置';
    }
    return '${medicine.durationStart.isEmpty ? '未设置开始日期' : medicine.durationStart} 至 ${medicine.durationEnd.isEmpty ? '长期' : medicine.durationEnd}';
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await showMedicineForm(context, medicine: medicine);
    if (saved && context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('删除这项药品？'),
            content: Text('“${medicine.name}”及关联提醒和服药记录将从本机删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      await AppScope.of(context).deleteMedicine(medicine);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _MedicineDetailRow extends StatelessWidget {
  const _MedicineDetailRow({
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

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 48,
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        child: Text(value, style: Theme.of(context).textTheme.labelLarge),
      ),
    ],
  );
}
