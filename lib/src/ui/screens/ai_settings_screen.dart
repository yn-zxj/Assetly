import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../services/ai_service.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

/// AI gateway configuration as a full page, matching the other settings
/// drill-downs instead of a bottom sheet.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key, required this.separate});

  final bool separate;

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  static const _secure = FlutterSecureStorage();
  final _textEndpoint = TextEditingController();
  final _textModel = TextEditingController();
  final _textKey = TextEditingController();
  final _visionEndpoint = TextEditingController();
  final _visionModel = TextEditingController();
  final _visionKey = TextEditingController();
  bool _loaded = false;
  bool _testingText = false;
  bool _testingVision = false;
  String? _textResult;
  String? _visionResult;
  bool? _textSuccess;
  bool? _visionSuccess;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  @override
  void dispose() {
    _textEndpoint.dispose();
    _textModel.dispose();
    _textKey.dispose();
    _visionEndpoint.dispose();
    _visionModel.dispose();
    _visionKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppScope.of(context).database;
    final endpoint =
        await db.getSetting('ai_api_url') ?? 'https://api.openai.com/v1';
    final model = await db.getSetting('ai_text_model') ?? 'gpt-4o-mini';
    final key = await _secure.read(key: 'ai_api_key') ?? '';
    final visionEndpoint = await db.getSetting('ai_vision_api_url') ?? endpoint;
    final visionModel = await db.getSetting('ai_vision_model') ?? 'gpt-4o';
    final visionKey = await _secure.read(key: 'ai_vision_api_key') ?? '';
    if (!mounted) return;
    setState(() {
      _textEndpoint.text = endpoint;
      _textModel.text = model;
      _textKey.text = key;
      _visionEndpoint.text = visionEndpoint;
      _visionModel.text = visionModel;
      _visionKey.text = visionKey;
    });
  }

  Future<void> _testText() async {
    setState(() {
      _testingText = true;
      _textResult = null;
    });
    final result = await _test(
      endpoint: _textEndpoint.text,
      key: _textKey.text,
      model: _textModel.text,
    );
    if (!mounted) return;
    setState(() {
      _testingText = false;
      _textSuccess = result.ok;
      _textResult = result.message;
    });
  }

  Future<void> _testVision() async {
    setState(() {
      _testingVision = true;
      _visionResult = null;
    });
    final result = await _test(
      endpoint: _visionEndpoint.text,
      key: _visionKey.text,
      model: _visionModel.text,
    );
    if (!mounted) return;
    setState(() {
      _testingVision = false;
      _visionSuccess = result.ok;
      _visionResult = result.message;
    });
  }

  Future<void> _save() async {
    final db = AppScope.of(context).database;
    await db.setSetting('ai_api_url', _textEndpoint.text.trim());
    await db.setSetting('ai_text_model', _textModel.text.trim());
    await _secure.write(key: 'ai_api_key', value: _textKey.text.trim());
    await db.setSetting(
      'ai_vision_api_url',
      widget.separate ? _visionEndpoint.text.trim() : _textEndpoint.text.trim(),
    );
    await db.setSetting(
      'ai_vision_model',
      widget.separate ? _visionModel.text.trim() : _textModel.text.trim(),
    );
    await _secure.write(
      key: 'ai_vision_api_key',
      value: widget.separate ? _visionKey.text.trim() : _textKey.text.trim(),
    );
    if (!mounted) return;
    showTopNotice(context, '模型配置已保存');
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final separate = widget.separate;
    return SubPage(
      title: separate ? '文本与图文模型' : '大模型配置',
      children: [
        SettingSection(
          icon: separate ? LucideIcons.messageSquare : LucideIcons.sparkles,
          label: separate ? '文本模型' : '通用模型',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: _ModelFields(
                endpoint: _textEndpoint,
                model: _textModel,
                apiKey: _textKey,
                testing: _testingText,
                result: _textResult,
                success: _textSuccess,
                onTest: _testText,
              ),
            ),
          ],
        ),
        if (separate)
          SettingSection(
            icon: LucideIcons.image,
            label: '图文模型',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: _ModelFields(
                  endpoint: _visionEndpoint,
                  model: _visionModel,
                  apiKey: _visionKey,
                  testing: _testingVision,
                  result: _visionResult,
                  success: _visionSuccess,
                  onTest: _testVision,
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 0),
          child: FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(LucideIcons.save, size: 18),
            label: const Text('保存模型配置'),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          separate ? '两套模型的地址、名称和密钥分别保存。' : '关闭双模型分离时，文本与图片识别共用这一套配置。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

Future<({bool ok, String message})> _test({
  required String endpoint,
  required String key,
  required String model,
}) async {
  try {
    final message = await AiService().testConnection(
      endpoint: endpoint,
      apiKey: key,
      model: model,
    );
    return (ok: true, message: message);
  } catch (error) {
    return (ok: false, message: '$error'.replaceFirst('Exception: ', ''));
  }
}

class _ModelFields extends StatefulWidget {
  const _ModelFields({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.testing,
    required this.result,
    required this.success,
    required this.onTest,
  });

  final TextEditingController endpoint, model, apiKey;
  final bool testing;
  final String? result;
  final bool? success;
  final VoidCallback onTest;

  @override
  State<_ModelFields> createState() => _ModelFieldsState();
}

class _ModelFieldsState extends State<_ModelFields> {
  bool _apiKeyVisible = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: widget.endpoint,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(labelText: 'API Endpoint'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: widget.model,
        decoration: const InputDecoration(labelText: '模型名称'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: widget.apiKey,
        obscureText: !_apiKeyVisible,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: 'API Key',
          suffixIcon: IconButton(
            tooltip: _apiKeyVisible ? '隐藏 API Key' : '显示 API Key',
            onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
            icon: Icon(
              _apiKeyVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 18,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.testing ? null : widget.onTest,
          icon: widget.testing
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.plugZap, size: 17),
          label: Text(widget.testing ? '正在测试…' : '测试连接'),
        ),
      ),
      if (widget.result != null) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: ShapeDecoration(
            color: (widget.success == true ? Colors.green : Colors.red)
                .withValues(alpha: .08),
            shape: AppShape.all(
              AppCorner.sm,
              border: (widget.success == true ? Colors.green : Colors.red)
                  .withValues(alpha: .3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.success == true
                    ? LucideIcons.checkCircle2
                    : LucideIcons.alertCircle,
                size: 17,
                color: widget.success == true ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.result!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
