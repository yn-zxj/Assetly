import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../services/webdav_service.dart';
import '../../state/app_controller.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'ai_settings_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const PageHeader(
          title: '设置与系统引擎',
          subtitle: '物语 Assetly v1.3.0 · Local-First 架构',
        ),
        Padding(
          padding: pagePadding,
          child: Column(
            children: [
              _appearance(context, state),
              const SizedBox(height: 12),
              _Group(
                title: '多模态 AI 智能网关',
                icon: LucideIcons.sparkles,
                children: [
                  _SettingTile(
                    title: '双模型分离',
                    subtitle: state.separateAiModels
                        ? '已开启：文本模型与图文模型需要分别配置'
                        : '关闭时文本与图片识别共用一套模型配置',
                    trailing: Switch(
                      value: state.separateAiModels,
                      onChanged: state.setAiModelMode,
                    ),
                  ),
                  _SettingTile(
                    title: state.separateAiModels ? '配置文本与图文模型' : '配置大模型',
                    subtitle: 'OpenAI 兼容协议 · 保存前可测试连接',
                    onTap: () => _aiSettings(context),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                  _InfoStrip(
                    icon: LucideIcons.zap,
                    text: '768px 智能压缩管道已启用 · JPEG 质量 80%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Group(
                title: 'Android 系统级服药提醒',
                icon: LucideIcons.bellRing,
                children: [
                  _SettingTile(
                    title: '精确闹钟与通知权限',
                    subtitle: '后台与锁屏状态下准时唤醒',
                    trailing: FilledButton(
                      onPressed: () async {
                        final ok = await state.enableReminders();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? '精准提醒已开启' : '未获得完整权限，请在系统设置中开启',
                              ),
                            ),
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
                  const _SettingTile(
                    title: '锁屏快捷打卡',
                    subtitle: '通知中心直接完成服药记录',
                    trailing: AppBadge('支持', color: Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Group(
                title: '本地优先与 WebDAV',
                icon: LucideIcons.cloud,
                children: [
                  _SettingTile(
                    title: 'WebDAV 云同步',
                    subtitle: '兼容旧版 /assetly-backup.json',
                    onTap: () => _webdavSettings(context),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _import(context),
                          icon: const Icon(LucideIcons.download, size: 17),
                          label: const Text('导入 JSON'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _export(context),
                          icon: const Icon(LucideIcons.share2, size: 17),
                          label: const Text('导出备份'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Group(
                title: '软件信息',
                icon: LucideIcons.info,
                children: [
                  _SettingTile(
                    title: '关于、运行日志与开源许可',
                    subtitle: 'v1.3.0 Stable · SQLite schema v8',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appearance(BuildContext context, AppController state) => _Group(
    title: '外观',
    icon: LucideIcons.palette,
    headerTrailing: SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
        ButtonSegment(value: ThemeMode.dark, label: Text('暗色')),
        ButtonSegment(value: ThemeMode.system, label: Text('系统')),
      ],
      selected: {state.themeMode},
      onSelectionChanged: (value) => state.setTheme(value.first),
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    ),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text('主题色', style: Theme.of(context).textTheme.bodySmall),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 11,
        runSpacing: 9,
        children:
            {
                  'zinc': const Color(0xFF52525B),
                  'slate': const Color(0xFF475569),
                  'blue': const Color(0xFF2563EB),
                  'emerald': const Color(0xFF10B981),
                  'violet': const Color(0xFF7C3AED),
                  'rose': const Color(0xFFE11D48),
                  'amber': const Color(0xFFD97706),
                }.entries
                .map(
                  (entry) => Tooltip(
                    message: entry.key,
                    child: InkWell(
                      onTap: () => state.setAccent(entry.key),
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: state.accent == entry.value ? 3 : 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    ],
  );

  Future<void> _export(BuildContext context) async {
    try {
      final json = await AppScope.of(context).database.exportJson();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/assetly-backup.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: '物语 Assetly 本地数据备份');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入完成：成功 ${counts.$1}，失败 ${counts.$2}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }

  Future<void> _aiSettings(BuildContext context) async {
    await showAiSettingsSheet(
      context,
      separate: AppScope.of(context).separateAiModels,
    );
  }

  Future<void> _webdavSettings(BuildContext context) async {
    final db = AppScope.of(context).database, dav = WebDavService();
    const secure = FlutterSecureStorage();
    final server = TextEditingController(
          text: await db.getSetting('webdav_server_url') ?? '',
        ),
        user = TextEditingController(
          text: await db.getSetting('webdav_username') ?? '',
        ),
        password = TextEditingController(
          text: await secure.read(key: 'webdav_password') ?? '',
        ),
        path = TextEditingController(
          text:
              await db.getSetting('webdav_remote_path') ??
              '/assetly-backup.json',
        );
    if (!context.mounted) return;
    var passwordVisible = false;
    var busy = false;
    String? result;
    bool? success;
    await showAssetlySheet(
      context,
      StatefulBuilder(
        builder: (sheetContext, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: ListView(
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const SheetHeader(title: 'WebDAV 同步', subtitle: '账号信息使用系统安全区保存'),
              TextField(
                controller: server,
                decoration: const InputDecoration(labelText: '服务器地址'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: user,
                decoration: const InputDecoration(labelText: '用户名'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: password,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: '密码',
                  suffixIcon: IconButton(
                    tooltip: passwordVisible ? '隐藏密码' : '显示密码',
                    onPressed: () =>
                        setLocal(() => passwordVisible = !passwordVisible),
                    icon: Icon(
                      passwordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: path,
                decoration: const InputDecoration(labelText: '远程路径'),
              ),
              if (result != null) ...[
                const SizedBox(height: 10),
                _ConnectionResult(message: result!, success: success == true),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy
                          ? null
                          : () async {
                              setLocal(() {
                                busy = true;
                                result = null;
                              });
                              try {
                                await dav.test(
                                  server.text.trim(),
                                  user.text.trim(),
                                  password.text,
                                  path.text.trim(),
                                );
                                success = true;
                                result = '连接成功，服务器可用';
                              } catch (error) {
                                success = false;
                                result = '$error'.replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                              }
                              if (sheetContext.mounted) {
                                setLocal(() => busy = false);
                              }
                            },
                      child: Text(busy ? '正在测试…' : '测试连接'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () async {
                              await db.setSetting(
                                'webdav_server_url',
                                server.text.trim(),
                              );
                              await db.setSetting(
                                'webdav_username',
                                user.text.trim(),
                              );
                              await db.setSetting(
                                'webdav_remote_path',
                                path.text.trim(),
                              );
                              await secure.write(
                                key: 'webdav_password',
                                value: password.text,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        setLocal(() {
                          busy = true;
                          result = null;
                        });
                        try {
                          await dav.upload(
                            server.text.trim(),
                            user.text.trim(),
                            password.text,
                            path.text.trim(),
                            await db.exportJson(),
                          );
                          success = true;
                          result = '备份已成功上传';
                        } catch (error) {
                          success = false;
                          result = '$error'.replaceFirst('Exception: ', '');
                        }
                        if (sheetContext.mounted) {
                          setLocal(() => busy = false);
                        }
                      },
                icon: const Icon(LucideIcons.uploadCloud, size: 18),
                label: const Text('立即上传备份'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionResult extends StatelessWidget {
  const _ConnectionResult({required this.message, required this.success});
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? Colors.green : Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.icon,
    required this.children,
    this.headerTrailing,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? headerTrailing;
  @override
  Widget build(BuildContext context) => ShadCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: context.colors.accent),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (headerTrailing != null) ...[const Spacer(), headerTrailing!],
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 7),
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: context.colors.muted,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
