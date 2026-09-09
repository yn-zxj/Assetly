import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app.dart';
import '../../services/ai_service.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'items_screen.dart';
import 'medicine_form.dart';

enum EntryMode { barcode, ai }

class SmartEntryScreen extends StatefulWidget {
  const SmartEntryScreen({super.key, required this.initialMode});
  final EntryMode initialMode;
  @override
  State<SmartEntryScreen> createState() => _SmartEntryScreenState();
}

class _SmartEntryScreenState extends State<SmartEntryScreen> {
  late EntryMode mode = widget.initialMode;
  final scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final ai = AiService();
  String? barcode;
  bool busy = false;
  bool get cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('智能拍照录入')),
    body: ListView(
      padding: pagePadding,
      children: [
        SegmentedButton<EntryMode>(
          segments: const [
            ButtonSegment(
              value: EntryMode.barcode,
              icon: Icon(LucideIcons.scanLine),
              label: Text('条码 / 药监码速扫'),
            ),
            ButtonSegment(
              value: EntryMode.ai,
              icon: Icon(LucideIcons.sparkles),
              label: Text('多模态 AI 拍照'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) => setState(() => mode = s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 16),
        if (mode == EntryMode.barcode)
          _barcodePane(context)
        else
          _aiPane(context),
      ],
    ),
  );

  Widget _barcodePane(BuildContext context) => Column(
    children: [
      AspectRatio(
        aspectRatio: 1.15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: cameraSupported
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: scanner,
                      onDetect: (capture) {
                        final code = capture.barcodes.firstOrNull?.rawValue;
                        if (code != null && mounted) {
                          scanner.stop();
                          setState(() => barcode = code);
                        }
                      },
                    ),
                    Center(
                      child: Container(
                        width: 230,
                        height: 112,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Text(
                        '将条码对准取景框',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            const Shadow(blurRadius: 6, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  color: context.colors.muted,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.scanLine, size: 60),
                      const SizedBox(height: 12),
                      Text(
                        '当前平台不支持实时相机预览',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Android / iOS 设备将启用 MLKit 扫码',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.muted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.zap, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'MLKit 本机识别 · 支持 EAN-13、UPC、Code-128 及药监码',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (barcode != null)
        ShadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 18,
                    color: context.colors.accent,
                  ),
                  const SizedBox(width: 7),
                  Text('识别成功', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 7),
              Text('条码：$barcode'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      showItemForm(context, preset: {'barcode': barcode!}),
                  child: const Text('继续填写物品信息'),
                ),
              ),
            ],
          ),
        )
      else
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _manual(context),
            icon: const Icon(LucideIcons.keyboard, size: 18),
            label: const Text('手动输入条码'),
          ),
        ),
    ],
  );

  Widget _aiPane(BuildContext context) => Column(
    children: [
      ShadCard(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 30,
                color: context.colors.accent,
              ),
            ),
            const SizedBox(height: 14),
            Text('拍一张物品或包装照片', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '图片最长边压缩至 768px、JPEG 质量 80%，由你配置的视觉模型提取名称、分类、条码、有效期和厂商。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : _recognize,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.camera, size: 19),
                label: Text(busy ? '识别中…' : '拍照并智能识别'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ShadCard(
        color: context.colors.muted,
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.shieldCheck, size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'API Key 使用系统安全区加密保存；只有点击识别时，压缩后的照片才会发送到你配置的 AI 服务。',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _manual(BuildContext context) async {
    final c = TextEditingController();
    final value = await showAssetlySheet<String>(
      context,
      Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: '手动输入条码'),
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'EAN / UPC / 药监码'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text('确认'),
              ),
            ),
          ],
        ),
      ),
    );
    if (value != null && value.isNotEmpty) setState(() => barcode = value);
  }

  Future<void> _recognize() async {
    final db = AppScope.of(context).database;
    setState(() => busy = true);
    try {
      final file = await ai.pickCompressedImage();
      if (file == null) return;
      final separate = await db.getSetting('ai_model_mode') == 'separate';
      final endpoint = separate
          ? await db.getSetting('ai_vision_api_url') ??
                'https://api.openai.com/v1'
          : await db.getSetting('ai_api_url') ?? 'https://api.openai.com/v1';
      final model = separate
          ? await db.getSetting('ai_vision_model') ?? 'gpt-4o'
          : await db.getSetting('ai_text_model') ?? 'gpt-4o';
      final result = await ai.recognize(file, endpoint: endpoint, model: model);
      if (!mounted) return;
      final asMedicine = await _confirmEntryType(result);
      if (asMedicine == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      if (asMedicine) {
        final quantity =
            result.remainingQuantity == result.remainingQuantity.roundToDouble()
            ? result.remainingQuantity.toStringAsFixed(0)
            : result.remainingQuantity.toString();
        await showMedicineForm(
          context,
          preset: {
            'name': result.name,
            'expiry': result.expiry,
            'instructions': result.description,
            'manufacturer': result.manufacturer,
            'barcode': result.barcode,
            'medicineType': result.medicineType,
            'quantity': quantity,
            'unit': result.unit,
          },
        );
      } else {
        await showItemForm(
          context,
          preset: {
            'name': result.name,
            'description': result.description,
            'barcode': result.barcode,
            'category': result.category,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool?> _confirmEntryType(AiRecognizedItem result) {
    Widget destinationButton({required bool medicine}) {
      final recommended = medicine == result.isMedicine;
      final icon = medicine ? LucideIcons.pill : LucideIcons.package;
      final label = medicine ? '录入家庭药箱' : '录入物品库';
      void onPressed() => Navigator.pop(context, medicine);
      if (recommended) {
        return FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text('$label（AI 推荐）'),
        );
      }
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return showAssetlySheet<bool>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(title: 'AI 识别完成', subtitle: '请确认保存位置，识别有误时可手动切换'),
            ShadCard(
              color: context.colors.muted,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    result.isMedicine ? LucideIcons.pill : LucideIcons.package,
                    color: context.colors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          result.isMedicine ? '初步判断：药品' : '初步判断：普通物品',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            destinationButton(medicine: result.isMedicine),
            const SizedBox(height: 8),
            destinationButton(medicine: !result.isMedicine),
          ],
        ),
      ),
    );
  }
}
