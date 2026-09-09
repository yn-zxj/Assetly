import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../state/app_controller.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

const medicineTypeOptions = <SelectOption<String>>[
  SelectOption('internal', '内服', icon: LucideIcons.pill),
  SelectOption('external', '外用', icon: LucideIcons.cross),
  SelectOption('emergency', '急救', icon: LucideIcons.heartPulse),
  SelectOption('injection', '注射', icon: LucideIcons.syringe),
  SelectOption('inhaled', '吸入', icon: LucideIcons.wind),
  SelectOption('ophthalmic', '眼用', icon: LucideIcons.eye),
];

Future<bool> showMedicineForm(
  BuildContext context, {
  Medicine? medicine,
  Map<String, String>? preset,
}) async {
  final controller = AppScope.of(context);
  final result = await showAssetlySheet<bool>(
    context,
    _MedicineForm(controller: controller, medicine: medicine, preset: preset),
  );
  return result ?? false;
}

class _MedicineForm extends StatefulWidget {
  const _MedicineForm({required this.controller, this.medicine, this.preset});
  final AppController controller;
  final Medicine? medicine;
  final Map<String, String>? preset;

  @override
  State<_MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends State<_MedicineForm> {
  late final name = TextEditingController(
    text: widget.preset?['name'] ?? widget.medicine?.name ?? '',
  );
  late final expiry = TextEditingController(
    text: widget.preset?['expiry'] ?? widget.medicine?.expiryDate ?? '',
  );
  late final instructions = TextEditingController(
    text:
        widget.preset?['instructions'] ??
        widget.medicine?.dosageInstructions ??
        '',
  );
  late final quantity = TextEditingController(
    text:
        widget.preset?['quantity'] ??
        (widget.medicine == null
            ? '1'
            : widget.medicine!.remainingQuantity.toStringAsFixed(0)),
  );
  late final manufacturer = TextEditingController(
    text: widget.preset?['manufacturer'] ?? widget.medicine?.manufacturer ?? '',
  );
  late final barcode = TextEditingController(
    text: widget.preset?['barcode'] ?? widget.medicine?.barcode ?? '',
  );
  late final purchaseDate = TextEditingController(
    text: widget.medicine?.purchaseDate ?? '',
  );
  late final price = TextEditingController(
    text: widget.medicine == null || widget.medicine!.purchasePrice == 0
        ? ''
        : widget.medicine!.purchasePrice.toString(),
  );
  late final startDate = TextEditingController(
    text: widget.medicine?.durationStart ?? '',
  );
  late final endDate = TextEditingController(
    text: widget.medicine?.durationEnd ?? '',
  );
  late String type =
      widget.preset?['medicineType'] ??
      widget.medicine?.medicineType ??
      'internal';
  late String unit = widget.preset?['unit'] ?? widget.medicine?.unit ?? '片';
  late bool taking = widget.medicine?.isTaking ?? false;
  late String frequency = widget.medicine?.frequencyType ?? 'daily';
  late final List<String> times = [...?widget.medicine?.slots];
  String locationId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (locationId.isEmpty) {
      final candidate = widget.medicine?.locationId ?? '';
      if (widget.controller.locations.any((x) => x.id == candidate)) {
        locationId = candidate;
      }
    }
    if (taking && times.isEmpty) times.add('08:00');
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      expiry,
      instructions,
      quantity,
      manufacturer,
      barcode,
      purchaseDate,
      price,
      startDate,
      endDate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: ListView(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SheetHeader(
            title: widget.medicine == null ? '添加药品' : '修改药品',
            subtitle: '药品信息和提醒计划只保存在本机',
          ),
          _group('基本信息', [
            TextField(
              controller: name,
              autofocus: widget.medicine == null,
              decoration: const InputDecoration(
                labelText: '药品名称 *',
                hintText: '如：布洛芬缓释胶囊',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppDateField(label: '有效期', controller: expiry),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppSelectField<String>(
                    label: '类型',
                    value: type,
                    options: medicineTypeOptions,
                    onChanged: (value) => setState(() => type = value),
                  ),
                ),
              ],
            ),
            TextField(
              controller: instructions,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '服用/使用说明',
                hintText: '如：每日2次，每次1粒，饭后服用',
                alignLabelWithHint: true,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: '剩余数量'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppSelectField<String>(
                    label: '单位',
                    value: unit,
                    options: const [
                      SelectOption('片', '片'),
                      SelectOption('粒', '粒'),
                      SelectOption('袋', '袋'),
                      SelectOption('支', '支'),
                      SelectOption('瓶', '瓶'),
                      SelectOption('盒', '盒'),
                      SelectOption('毫升', '毫升'),
                    ],
                    onChanged: (value) => setState(() => unit = value),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: manufacturer,
                    decoration: const InputDecoration(labelText: '生产厂商'),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          _group('购买信息', [
            TextField(
              controller: barcode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '药品条码',
                prefixIcon: Icon(LucideIcons.scanLine, size: 18),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppDateField(label: '购买日期', controller: purchaseDate),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '价格',
                      prefixText: '¥ ',
                    ),
                  ),
                ),
              ],
            ),
            AppSelectField<String>(
              label: '存放位置',
              value: locationId,
              options: [
                const SelectOption('', '暂不设置'),
                ...state.locations.map(
                  (location) => SelectOption(location.id, location.fullPath),
                ),
              ],
              onChanged: (value) => setState(() => locationId = value),
            ),
          ]),
          const SizedBox(height: 10),
          ShadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.bell,
                      size: 19,
                      color: context.colors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用药提醒',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '仅为当前正在服用的药品创建提醒',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: taking,
                      onChanged: (value) => setState(() {
                        taking = value;
                        if (taking && times.isEmpty) times.add('08:00');
                      }),
                    ),
                  ],
                ),
                if (taking) ...[
                  const SizedBox(height: 12),
                  AppSelectField<String>(
                    label: '用药频率',
                    value: frequency,
                    options: const [
                      SelectOption('daily', '每天'),
                      SelectOption('weekly', '每周'),
                      SelectOption('interval', '间隔天数'),
                      SelectOption('as_needed', '按需服用'),
                    ],
                    onChanged: (value) => setState(() => frequency = value),
                  ),
                  const SizedBox(height: 12),
                  Text('用药时间', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ...times.asMap().entries.map(
                        (entry) => InputChip(
                          avatar: const Icon(LucideIcons.clock3, size: 15),
                          label: Text(entry.value),
                          onPressed: () => _changeTime(entry.key),
                          onDeleted: () =>
                              setState(() => times.removeAt(entry.key)),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.plus, size: 15),
                        label: const Text('添加'),
                        onPressed: _addTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppDateField(
                          label: '开始日期',
                          controller: startDate,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: AppDateField(label: '结束日期', controller: endDate),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(LucideIcons.save, size: 18),
              label: Text(widget.medicine == null ? '添加药品' : '保存修改'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> children) => ShadCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          children[i],
        ],
      ],
    ),
  );

  Future<String?> _pickTime(String value) async {
    final parts = value.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.firstOrNull ?? '') ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      ),
    );
    if (selected == null) return null;
    return '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _changeTime(int index) async {
    final value = await _pickTime(times[index]);
    if (value != null) setState(() => times[index] = value);
  }

  Future<void> _addTime() async {
    final value = await _pickTime('08:00');
    if (value != null) setState(() => times.add(value));
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写药品名称')));
      return;
    }
    if (taking && times.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少添加一个用药时间')));
      return;
    }
    final state = widget.controller;
    await state.saveMedicine(
      {
        'name': name.text.trim(),
        'description': instructions.text.trim(),
        'location_id': locationId,
        'purchase_date': purchaseDate.text.trim(),
        'purchase_price': double.tryParse(price.text) ?? 0,
        'quantity': 1,
        'image_path': '',
        'icon': '💊',
        'barcode': barcode.text.trim(),
        'warranty_expiry': '',
        'shelf_life_expiry': expiry.text.trim(),
        'retired_date': '',
        'resale_amount': 0,
      },
      {
        'medicine_type': type,
        'expiry_date': expiry.text.trim(),
        'dosage_instructions': instructions.text.trim(),
        'remaining_quantity': double.tryParse(quantity.text) ?? 0,
        'unit': unit,
        'manufacturer': manufacturer.text.trim(),
        'is_taking': taking ? 1 : 0,
        'frequency_type': frequency,
        'frequency_days': 1,
        'week_days': '',
        'time_slots': taking ? times.join(',') : '',
        'duration_start': taking ? startDate.text.trim() : '',
        'duration_end': taking ? endDate.text.trim() : '',
        'last_reminded': '',
      },
      existing: widget.medicine,
    );
    if (mounted) Navigator.pop(context, true);
  }
}
