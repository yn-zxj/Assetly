import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../services/ai_service.dart';
import '../widgets/common.dart';

Future<void> showAiSettingsSheet(
  BuildContext context, {
  required bool separate,
}) async {
  const secure = FlutterSecureStorage();
  final db = AppScope.of(context).database;
  final textEndpoint = TextEditingController(
    text: await db.getSetting('ai_api_url') ?? 'https://api.openai.com/v1',
  );
  final textModel = TextEditingController(
    text: await db.getSetting('ai_text_model') ?? 'gpt-4o-mini',
  );
  final textKey = TextEditingController(
    text: await secure.read(key: 'ai_api_key') ?? '',
  );
  final visionEndpoint = TextEditingController(
    text: await db.getSetting('ai_vision_api_url') ?? textEndpoint.text,
  );
  final visionModel = TextEditingController(
    text: await db.getSetting('ai_vision_model') ?? 'gpt-4o',
  );
  final visionKey = TextEditingController(
    text: await secure.read(key: 'ai_vision_api_key') ?? '',
  );
  if (!context.mounted) return;
  var testingText = false;
  var testingVision = false;
  String? textResult;
  String? visionResult;
  bool? textSuccess;
  bool? visionSuccess;
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
            SheetHeader(
              title: separate ? '文本与图文模型配置' : '大模型配置',
              subtitle: separate ? '两套模型的地址、名称和密钥需分别填写' : '文本与图片识别共用这一套配置',
            ),
            _ModelFields(
              title: separate ? '文本模型' : '通用模型',
              icon: separate ? LucideIcons.messageSquare : LucideIcons.sparkles,
              endpoint: textEndpoint,
              model: textModel,
              apiKey: textKey,
              testing: testingText,
              result: textResult,
              success: textSuccess,
              onTest: () async {
                setLocal(() {
                  testingText = true;
                  textResult = null;
                });
                final result = await _test(
                  endpoint: textEndpoint.text,
                  key: textKey.text,
                  model: textModel.text,
                );
                if (sheetContext.mounted) {
                  setLocal(() {
                    testingText = false;
                    textSuccess = result.ok;
                    textResult = result.message;
                  });
                }
              },
            ),
            if (separate) ...[
              const SizedBox(height: 10),
              _ModelFields(
                title: '图文模型',
                icon: LucideIcons.image,
                endpoint: visionEndpoint,
                model: visionModel,
                apiKey: visionKey,
                testing: testingVision,
                result: visionResult,
                success: visionSuccess,
                onTest: () async {
                  setLocal(() {
                    testingVision = true;
                    visionResult = null;
                  });
                  final result = await _test(
                    endpoint: visionEndpoint.text,
                    key: visionKey.text,
                    model: visionModel.text,
                  );
                  if (sheetContext.mounted) {
                    setLocal(() {
                      testingVision = false;
                      visionSuccess = result.ok;
                      visionResult = result.message;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                await db.setSetting('ai_api_url', textEndpoint.text.trim());
                await db.setSetting('ai_text_model', textModel.text.trim());
                await secure.write(
                  key: 'ai_api_key',
                  value: textKey.text.trim(),
                );
                await db.setSetting(
                  'ai_vision_api_url',
                  separate
                      ? visionEndpoint.text.trim()
                      : textEndpoint.text.trim(),
                );
                await db.setSetting(
                  'ai_vision_model',
                  separate ? visionModel.text.trim() : textModel.text.trim(),
                );
                await secure.write(
                  key: 'ai_vision_api_key',
                  value: separate ? visionKey.text.trim() : textKey.text.trim(),
                );
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text('保存模型配置'),
            ),
          ],
        ),
      ),
    ),
  );
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

class _ModelFields extends StatelessWidget {
  const _ModelFields({
    required this.title,
    required this.icon,
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.testing,
    required this.result,
    required this.success,
    required this.onTest,
  });
  final String title;
  final IconData icon;
  final TextEditingController endpoint, model, apiKey;
  final bool testing;
  final String? result;
  final bool? success;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) => ShadCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: endpoint,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'API Endpoint'),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: model,
          decoration: const InputDecoration(labelText: '模型名称'),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: apiKey,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'API Key'),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: testing ? null : onTest,
            icon: testing
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.plugZap, size: 17),
            label: Text(testing ? '正在测试…' : '测试连接'),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (success == true ? Colors.green : Colors.red).withValues(
                alpha: .08,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (success == true ? Colors.green : Colors.red).withValues(
                  alpha: .3,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  success == true
                      ? LucideIcons.checkCircle2
                      : LucideIcons.alertCircle,
                  size: 17,
                  color: success == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result!, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
