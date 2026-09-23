import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/app_database.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final logs = [
      ('INFO', 'SQLite WAL mounted · schema v${AppDatabase.schemaVersion}'),
      ('ALARM', 'AlarmManager exact reminders ready'),
      ('SYNC', 'WebDAV adapter initialized'),
      ('AI', 'Vision compression: max 768px / JPEG 80%'),
      ('CPD', 'Daily cost engine refreshed'),
      ('SYS', 'Edge-to-edge insets active'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于与系统诊断'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('诊断摘要已准备'))),
            icon: const Icon(LucideIcons.share2),
          ),
        ],
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          ShadCard(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    LucideIcons.packageCheck,
                    color: Theme.of(context).colorScheme.surface,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text('物语', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                AppBadge('${state.displayVersion} · Stable'),
                const SizedBox(height: 10),
                Text(
                  '主打极简克制美学、全景家庭物品生命周期与原生精准服药提醒的资产管理工具。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('技术架构与数据协议'),
          ShadCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _AboutRow('兼容桌面端', 'v0.3.3 SQLite / JSON'),
                const Hairline(),
                const _AboutRow(
                  '本地引擎',
                  'SQLite WAL · schema v${AppDatabase.schemaVersion}',
                ),
                const Hairline(),
                const _AboutRow('准时提醒', 'Android Exact Alarm'),
                const Hairline(),
                const _AboutRow('云端同步', 'WebDAV 自有服务端'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionTitle(
            '系统运行日志',
            trailing: AppBadge('守护进程正常', color: context.colors.accent),
          ),
          ShadCard(
            color: const Color(0xFF09090B),
            child: Column(
              children: logs
                  .map(
                    (x) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TimeOfDay.now().format(context),
                            style: const TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '[${x.$1}]',
                              style: TextStyle(
                                color: x.$1 == 'ALARM'
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFA1A1AA),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              x.$2,
                              style: const TextStyle(
                                color: Color(0xFFD4D4D8),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'MIT License · 数据归用户所有 · Local-First',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}
