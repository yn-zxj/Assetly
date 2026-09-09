import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  String search = '', category = '全部';
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = state.items
        .where(
          (x) =>
              (category == '全部' || x.categoryName == category) &&
              (search.isEmpty ||
                  '${x.name}${x.barcode}${x.locationPath}${x.description}'
                      .toLowerCase()
                      .contains(search.toLowerCase())),
        )
        .toList();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: '物品资产库',
              actions: [
                IconAction(
                  icon: LucideIcons.slidersHorizontal,
                  onPressed: () => _filterSheet(context),
                ),
                const SizedBox(width: 8),
                IconAction(
                  icon: LucideIcons.plus,
                  onPressed: () => showItemForm(context),
                  tooltip: '添加物品',
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.search, size: 19),
                    hintText: '搜索物品、条码、型号、空间备注...',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['全部', ...state.categories.map((c) => c.name)]
                        .map(
                          (x) => Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ChoiceChip(
                              label: Text(
                                '$x${x == '全部' ? ' (${state.items.length})' : ''}',
                              ),
                              selected: category == x,
                              onSelected: (_) => setState(() => category = x),
                              showCheckmark: false,
                              labelStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: '在役资产估值',
                        value:
                            '¥ ${NumberFormat.compact().format(state.totalValue)}',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: MetricCard(
                        label: '闲置物品',
                        value:
                            '${state.items.where((e) => e.status == 'idle').length} 件',
                        valueColor: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: MetricCard(
                        label: '日均综合消耗',
                        value:
                            '¥ ${state.totalDailyCost.toStringAsFixed(1)} / 天',
                        valueColor: context.colors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (visible.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                title: '没有找到物品',
                description: '尝试更换关键词或添加一件新物品',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ItemTile(item: visible[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _filterSheet(BuildContext context) => showAssetlySheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: '筛选与排序'),
          ListTile(
            leading: const Icon(LucideIcons.activity),
            title: const Text('仅显示服役中'),
            trailing: Switch(
              value: false,
              onChanged: (_) {
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.arrowDownUp),
            title: const Text('按日均成本排序'),
            trailing: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    ),
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final AssetItem item;
  @override
  Widget build(BuildContext context) => ShadCard(
    padding: const EdgeInsets.all(10),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.muted,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(item.icon, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.locationPath} · ${item.barcode.isEmpty ? '无条码' : item.barcode}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '¥ ${NumberFormat('#,##0.00').format(item.purchasePrice)} · 在役 ${item.daysInService} 天',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppBadge(
              '¥ ${item.dailyCost.toStringAsFixed(1)} / 天',
              color: item.status == 'idle' ? const Color(0xFFD97706) : null,
            ),
            const SizedBox(height: 6),
            Text(
              item.status == 'active' ? '● 服役中' : '● 闲置待售',
              style: TextStyle(
                fontSize: 10.5,
                color: item.status == 'active'
                    ? context.colors.accent
                    : const Color(0xFFD97706),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool> showItemForm(
  BuildContext context, {
  AssetItem? item,
  Map<String, String>? preset,
}) async {
  final state = AppScope.of(context);
  final name = TextEditingController(text: preset?['name'] ?? item?.name ?? '');
  final description = TextEditingController(
    text: preset?['description'] ?? item?.description ?? '',
  );
  final price = TextEditingController(
    text: item?.purchasePrice.toString() ?? '',
  );
  final date = TextEditingController(
    text: item?.purchaseDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final barcode = TextEditingController(
    text: preset?['barcode'] ?? item?.barcode ?? '',
  );
  final warranty = TextEditingController(text: item?.warrantyExpiry ?? '');
  final retiredDate = TextEditingController(text: item?.retiredDate ?? '');
  final resaleAmount = TextEditingController(
    text: item == null || item.resaleAmount == 0
        ? ''
        : item.resaleAmount.toString(),
  );
  var icon = item?.icon ?? '📦';
  final presetCategory = state.categories
      .where((x) => x.name == preset?['category'])
      .firstOrNull;
  var categoryId = state.categories.any((x) => x.id == item?.categoryId)
      ? item!.categoryId
      : presetCategory?.id ?? state.categories.firstOrNull?.id ?? '';
  var locationId = state.locations.any((x) => x.id == item?.locationId)
      ? item!.locationId
      : '';
  var status = item?.status ?? 'active';
  final saved = await showAssetlySheet<bool>(
    context,
    StatefulBuilder(
      builder: (context, setLocal) => Padding(
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
              title: item == null ? '添加新物品' : '编辑资产属性',
              subtitle: '数据将保存在本机 SQLite 数据库',
            ),
            TextField(
              controller: name,
              autofocus: item == null,
              decoration: const InputDecoration(labelText: '物品名称 *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '描述 / 规格'),
            ),
            const SizedBox(height: 10),
            AssetIconPicker(
              value: icon,
              onChanged: (value) => setLocal(() => icon = value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppSelectField<String>(
                    label: '资产分类',
                    value: categoryId,
                    options: state.categories
                        .map((x) => SelectOption(x.id, x.name))
                        .toList(),
                    onChanged: (v) => setLocal(() => categoryId = v),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppSelectField<String>(
                    label: '存放空间',
                    value: locationId,
                    options: [
                      const SelectOption('', '暂不设置'),
                      ...state.locations.map(
                        (x) => SelectOption(x.id, x.fullPath),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => locationId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '购买价格',
                      prefixText: '¥ ',
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppDateField(label: '购买日期', controller: date),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: barcode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '商品条码',
                prefixIcon: Icon(LucideIcons.scanLine, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppDateField(label: '质保到期', controller: warranty),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppSelectField<String>(
                    label: '状态',
                    value: status,
                    options: const [
                      SelectOption('active', '服役中'),
                      SelectOption('idle', '闲置待售'),
                      SelectOption('disposed', '已处置'),
                    ],
                    onChanged: (v) => setLocal(() => status = v),
                  ),
                ),
              ],
            ),
            if (status == 'disposed') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppDateField(label: '退役日期', controller: retiredDate),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: resaleAmount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '转售金额',
                        prefixText: '¥ ',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await state.saveItem({
                  'name': name.text.trim(),
                  'description': description.text.trim(),
                  'category_id': categoryId,
                  'location_id': locationId,
                  'purchase_date': date.text.trim(),
                  'purchase_price': double.tryParse(price.text) ?? 0,
                  'quantity': 1,
                  'image_path': '',
                  'icon': icon,
                  'status': status,
                  'barcode': barcode.text.trim(),
                  'warranty_expiry': warranty.text.trim(),
                  'shelf_life_expiry': '',
                  'retired_date': status == 'disposed'
                      ? retiredDate.text.trim()
                      : '',
                  'resale_amount': status == 'disposed'
                      ? double.tryParse(resaleAmount.text) ?? 0
                      : 0,
                }, id: item?.id);
                if (context.mounted) Navigator.pop(context, true);
              },
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(item == null ? '保存到资产库' : '保存更改'),
            ),
          ],
        ),
      ),
    ),
  );
  return saved ?? false;
}
