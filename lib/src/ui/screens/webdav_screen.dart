import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../services/webdav_service.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

/// WebDAV credentials and remote backup actions, laid out as a full page so it
/// matches the rest of the settings drill-downs.
class WebDavScreen extends StatefulWidget {
  const WebDavScreen({super.key});

  @override
  State<WebDavScreen> createState() => _WebDavScreenState();
}

class _WebDavScreenState extends State<WebDavScreen> {
  static const _secure = FlutterSecureStorage();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _path = TextEditingController();
  final _dav = WebDavService();
  bool _loaded = false;
  bool _busy = false;
  bool _passwordVisible = false;
  String? _result;
  bool? _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  @override
  void dispose() {
    _server.dispose();
    _user.dispose();
    _password.dispose();
    _path.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppScope.of(context).database;
    final server = await db.getSetting('webdav_server_url') ?? '';
    final user = await db.getSetting('webdav_username') ?? '';
    final password = await _secure.read(key: 'webdav_password') ?? '';
    final path =
        await db.getSetting('webdav_remote_path') ?? '/assetly-backup.json';
    if (!mounted) return;
    setState(() {
      _server.text = server;
      _user.text = user;
      _password.text = password;
      _path.text = path;
    });
  }

  void _finish(bool ok, String message) => setState(() {
    _busy = false;
    _success = ok;
    _result = message;
  });

  Future<void> _test() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      await _dav.test(
        _server.text.trim(),
        _user.text.trim(),
        _password.text,
        _path.text.trim(),
      );
      _finish(true, '连接成功，服务器可用');
    } catch (error) {
      _finish(false, friendlyWebDavError(error));
    }
  }

  Future<void> _save() async {
    final db = AppScope.of(context).database;
    await db.setSetting('webdav_server_url', _server.text.trim());
    await db.setSetting('webdav_username', _user.text.trim());
    await db.setSetting('webdav_remote_path', _path.text.trim());
    await _secure.write(key: 'webdav_password', value: _password.text);
    if (!mounted) return;
    showTopNotice(context, '云同步配置已保存');
    Navigator.maybePop(context);
  }

  Future<void> _download() async {
    final state = AppScope.of(context);
    final db = state.database;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('下载并恢复备份？'),
        content: const Text('云端备份将导入当前应用，相同记录会被云端内容覆盖，本地其他记录会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('继续恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final content = await _dav.download(
        _server.text.trim(),
        _user.text.trim(),
        _password.text,
        _path.text.trim(),
      );
      final counts = await db.importJson(content);
      await state.refresh();
      _finish(true, '恢复完成：成功 ${counts.$1}，失败 ${counts.$2}');
    } catch (error) {
      _finish(false, friendlyWebDavError(error));
    }
  }

  Future<void> _upload() async {
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      await _dav.upload(
        _server.text.trim(),
        _user.text.trim(),
        _password.text,
        _path.text.trim(),
        await state.database.exportJson(appVersion: state.appVersion),
      );
      _finish(true, '备份已成功上传');
    } catch (error) {
      _finish(false, friendlyWebDavError(error));
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(
    title: 'WebDAV 同步',
    children: [
      SettingSection(
        icon: LucideIcons.cloud,
        label: '连接信息',
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _server,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'https://dav.jianguoyun.com/dav/',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _user,
                  decoration: const InputDecoration(labelText: '用户名'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: !_passwordVisible,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: '密码',
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible ? '隐藏密码' : '显示密码',
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      icon: Icon(
                        _passwordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _path,
                  decoration: const InputDecoration(
                    labelText: '远程路径',
                    hintText: '/assetly-backup.json',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '账号信息使用系统安全区保存，不会写入备份文件。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      if (_result != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
          child: _ConnectionResult(
            message: _result!,
            success: _success == true,
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _test,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(_busy ? '正在测试…' : '测试连接'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
      SettingSection(
        icon: LucideIcons.archiveRestore,
        label: '云端备份',
        children: [
          SettingRow(
            icon: LucideIcons.downloadCloud,
            title: '下载恢复',
            subtitle: '用云端备份覆盖同 ID 记录，其余本地记录保留',
            onTap: _busy ? null : _download,
          ),
          SettingRow(
            icon: LucideIcons.uploadCloud,
            title: '上传备份',
            subtitle: '把当前数据推送到上面的远程路径',
            onTap: _busy ? null : _upload,
          ),
        ],
      ),
    ],
  );
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
      padding: const EdgeInsets.all(11),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: .08),
        shape: AppShape.all(AppCorner.sm, border: color.withValues(alpha: .3)),
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
