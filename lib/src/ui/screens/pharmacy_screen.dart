import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'medicine_detail_screen.dart';
import 'medicine_form.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final taking = state.takingMedicines;
    final completed = taking.where(state.wasTakenToday).length;
    final visible = state.medicines
        .where((medicine) => filter == 'all' || medicine.medicineType == filter)
        .toList();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: '家庭药箱',
              subtitle: '${state.medicines.length} 种药品 · 本地管理',
              actions: [
                IconAction(
                  icon: LucideIcons.plus,
                  tooltip: '添加药品',
                  onPressed: () => showMedicineForm(context),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: pagePadding,
            sliver: SliverList.list(
              children: [
                if (taking.isNotEmpty) ...[
                  _ProgressCard(completed: completed, total: taking.length),
                  const SizedBox(height: 18),
                  const SectionTitle('正在服药', subtitle: '当前启用的用药计划'),
                  ...taking.map(
                    (medicine) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ScheduleCard(medicine: medicine),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SectionTitle(
                  '常备家庭药箱',
                  subtitle: '${state.medicines.length} 种药品',
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                              const SelectOption('all', '全部'),
                              ...medicineTypeOptions,
                            ]
                            .map(
                              (option) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: ChoiceChip(
                                  label: Text(option.label),
                                  selected: filter == option.value,
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      setState(() => filter = option.value),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                if (visible.isEmpty)
                  EmptyState(
                    icon: LucideIcons.pill,
                    title: state.medicines.isEmpty ? '药箱还是空的' : '此分类暂无药品',
                    description: state.medicines.isEmpty
                        ? '添加药品、使用说明、库存和可选的用药提醒'
                        : '选择其他分类查看药品',
                    action: state.medicines.isEmpty
                        ? FilledButton.icon(
                            onPressed: () => showMedicineForm(context),
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('添加第一种药品'),
                          )
                        : null,
                  )
                else
                  ...visible.map(
                    (medicine) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MedicineTile(medicine: medicine),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total});
  final int completed, total;

  @override
  Widget build(BuildContext context) => ShadCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '今日服药进度',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$completed / $total 项',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 8,
            backgroundColor: context.colors.muted,
            color: context.colors.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          completed == total ? '今日计划已全部完成' : '打卡会同步扣减库存并写入服药记录',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.wasTakenToday(medicine);
    return ShadCard(
      onTap: () => _openMedicineDetail(context, medicine),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(
            medicine.slots.firstOrNull ?? '--:--',
            icon: LucideIcons.clock3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  medicine.dosageInstructions.isEmpty
                      ? '未填写服用/使用说明'
                      : medicine.dosageInstructions,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: done
                ? null
                : () async {
                    await state.takeDose(medicine);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${medicine.name} 已完成今日打卡')),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 35),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              done ? '已打卡' : '打卡',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final days = medicine.daysUntilExpiry;
    final hasExpiry = days != 999999;
    final danger = hasExpiry && days <= 30;
    final option = medicineTypeOptions
        .where((item) => item.value == medicine.medicineType)
        .firstOrNull;
    return ShadCard(
      padding: const EdgeInsets.all(11),
      onTap: () => _openMedicineDetail(context, medicine),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.accent.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              option?.icon ?? LucideIcons.pill,
              size: 22,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    AppBadge(option?.label ?? '其他'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  medicine.dosageInstructions.isEmpty
                      ? '未填写服用/使用说明'
                      : medicine.dosageInstructions,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${medicine.locationPath.isEmpty ? '未设置位置' : medicine.locationPath} · 库存 ${medicine.remainingQuantity.toStringAsFixed(0)} ${medicine.unit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  !hasExpiry
                      ? '未设置有效期'
                      : danger
                      ? '仅剩 $days 天到期'
                      : '$days 天后到期',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: danger
                        ? const Color(0xFFD97706)
                        : context.colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openMedicineDetail(
  BuildContext context,
  Medicine medicine,
) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: medicine)),
  );
}
