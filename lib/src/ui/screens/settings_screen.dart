import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../data/app_database.dart';
import '../../state/app_controller.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import '../widgets/update_dialog.dart';
import 'about_screen.dart';
import 'ai_settings_screen.dart';
import 'theme_screen.dart';
import 'webdav_screen.dart';

/// Settings laid out like FlClash's 工具 page: quiet labels with thin line
/// icons above white cards, one 56dp row per entry, hairlines inset to the
/// text and a chevron on anything that opens another page.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      children: [
        BigPageHeader(
          title: '设置',
          caption:
              '物语 ${state.displayVersion} · 本地优先 · SQLite v${AppDatabase.schemaVersion}',
        ),
        StaggeredEntry(
          index: 0,
          child: SettingSection(
            icon: LucideIcons.settings,
            label: '设置',
            children: [
              SettingRow(
                icon: LucideIcons.palette,
                title: '主题与外观',
                subtitle: '深浅模式、主题色彩与图标风格',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemeScreen()),
                ),
                trailing: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: state.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                chevron: true,
              ),
              SettingRow(
                icon: LucideIcons.cloud,
                title: 'WebDAV 云同步',
                subtitle: '坚果云等兼容服务 · 账号存于系统安全区',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WebDavScreen()),
                ),
                chevron: true,
              ),
              SettingRow(
                icon: LucideIcons.archiveRestore,
                title: '备份与恢复',
                subtitle: '导入或导出 JSON 备份文件',
                onTap: () => _backupSheet(context),
                chevron: true,
              ),
            ],
          ),
        ),
        StaggeredEntry(
          index: 1,
          child: SettingSection(
            icon: LucideIcons.sparkles,
            label: 'AI 智能网关',
            children: [
              SettingRow(
                icon: LucideIcons.gitBranch,
                title: '双模型分离',
                subtitle: state.separateAiModels
                    ? '已开启：文本模型与图文模型分别配置'
                    : '关闭时文本与图片识别共用一套模型',
                trailing: Switch(
                  value: state.separateAiModels,
                  onChanged: state.setAiModelMode,
                ),
              ),
              SettingRow(
                icon: LucideIcons.bot,
                title: state.separateAiModels ? '配置文本与图文模型' : '配置大模型',
                subtitle: 'OpenAI 兼容协议 · 保存前可测试连接',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AiSettingsScreen(separate: state.separateAiModels),
                  ),
                ),
                chevron: true,
              ),
            ],
          ),
        ),
        StaggeredEntry(
          index: 2,
          child: SettingSection(
            icon: LucideIcons.bellRing,
            label: '服药提醒',
            children: [
              SettingRow(
                icon: LucideIcons.alarmClock,
                title: '精确闹钟与通知权限',
                subtitle: '后台与锁屏状态下准时唤醒',
                trailing: FilledButton(
                  onPressed: () async {
                    final ok = await state.enableReminders();
                    if (context.mounted) {
                      showTopNotice(
                        context,
                        ok ? '精准提醒已开启' : '未获得完整权限，请在系统设置中开启',
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(50, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('授权', style: TextStyle(fontSize: 11)),
                ),
              ),
              SettingRow(
                icon: LucideIcons.lock,
                title: '锁屏快捷打卡',
                subtitle: '通知中心直接完成服药记录',
                trailing: const AppBadge('支持', color: Color(0xFF10B981)),
              ),
            ],
          ),
        ),
        StaggeredEntry(
          index: 3,
          child: SettingSection(
            icon: LucideIcons.info,
            label: '关于',
            children: [
              SettingRow(
                icon: LucideIcons.refreshCw,
                title: '检查更新',
                subtitle: _updateSubtitle(state),
                onTap: state.checkingForUpdates
                    ? null
                    : () => _checkForUpdates(context, state),
                trailing: state.checkingForUpdates
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : state.availableUpdate != null
                    ? AppBadge(
                        state.availableUpdate!.tagName,
                        color: context.colors.accent,
                      )
                    : null,
              ),
              SettingRow(
                icon: LucideIcons.fileText,
                title: '关于、运行日志与开源许可',
                subtitle: '${state.displayVersion} Stable · Local-First 架构',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
                chevron: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _updateSubtitle(AppController state) {
    if (state.checkingForUpdates) return '正在查询 GitHub Releases…';
    if (state.availableUpdate != null) {
      return '发现 ${state.availableUpdate!.tagName}，点击查看更新';
    }
    if (state.updateError != null) return state.updateError!;
    if (state.checkedForUpdates) return '当前已是最新版本';
    return '自动检查 GitHub 发布的新版本';
  }

  Future<void> _checkForUpdates(
    BuildContext context,
    AppController state,
  ) async {
    final release = await state.checkForUpdates(force: true);
    if (!context.mounted) return;
    if (release != null) {
      await showAppUpdateDialog(
        context,
        release: release,
        currentVersion: state.appVersion,
      );
      return;
    }
    showTopNotice(context, state.updateError ?? '当前已是最新版本');
  }

  Future<void> _backupSheet(BuildContext context) async {
    await showAssetlySheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(
              title: '备份与恢复',
              subtitle: 'JSON 备份兼容旧版 /assetly-backup.json',
            ),
            SettingSection(
              icon: LucideIcons.hardDrive,
              label: '本地文件',
              children: [
                SettingRow(
                  icon: LucideIcons.fileDown,
                  title: '导入 JSON 备份',
                  subtitle: '按 ID 合并，相同记录以文件为准',
                  onTap: () {
                    Navigator.pop(context);
                    _import(context);
                  },
                ),
                SettingRow(
                  icon: LucideIcons.share2,
                  title: '导出备份文件',
                  subtitle: '生成并分享 assetly-backup.json',
                  onTap: () {
                    Navigator.pop(context);
                    _export(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      maxHeight: .62,
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final state = AppScope.of(context);
      final json = await state.database.exportJson(
        appVersion: state.appVersion,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/assetly-backup.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: '物语本地数据备份');
    } catch (e) {
      if (context.mounted) {
        showTopNotice(context, '导出失败：$e');
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final state = AppScope.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null) return;
      final selected = result.files.single;
      final bytes = selected.bytes ?? await File(selected.path!).readAsBytes();
      final counts = await state.database.importJson(utf8.decode(bytes));
      await state.refresh();
      if (context.mounted) {
        showTopNotice(context, '导入完成：成功 ${counts.$1}，失败 ${counts.$2}');
      }
    } catch (e) {
      if (context.mounted) {
        showTopNotice(context, '导入失败：$e');
      }
    }
  }
}
