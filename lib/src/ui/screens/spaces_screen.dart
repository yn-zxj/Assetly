import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../state/app_controller.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final roots = state.locations.where((x) => x.parentId == null).toList();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: '空间与收纳透视',
              subtitle:
                  '全屋空间树状多级索引 · ${roots.length} 个主区域 · ${state.items.length + state.medicines.length} 件资产',
              actions: [
                IconAction(
                  icon: LucideIcons.plus,
                  onPressed: () => _add(context),
                  tooltip: '添加空间',
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: pagePadding,
            sliver: SliverList.list(
              children: [
                ShadCard(
                  color: context.colors.muted,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.map, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '当前聚焦：家庭全景',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...roots.map(
                  (root) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _SpaceCard(
                      root: root,
                      locations: state.locations,
                      items: [
                        ...state.items.where(
                          (x) => x.locationPath.startsWith(root.name),
                        ),
                        ...state.medicines.where(
                          (x) => x.locationPath.startsWith(root.name),
                        ),
                      ],
                      onManage: (location) => _manage(context, location),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.muted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.qrCode,
                            size: 20,
                            color: context.colors.accent,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              '物理空间收纳贴纸',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '一键生成二维码标签，手机扫码即可查看收纳盒内的全部物品。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: state.locations.isEmpty
                            ? null
                            : () => showAssetlySheet(
                                context,
                                _StorageStickerSheet(controller: state),
                              ),
                        icon: const Icon(LucideIcons.printer, size: 17),
                        label: const Text('生成贴纸'),
                      ),
                    ],
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

  Future<void> _add(
    BuildContext context, {
    String? parentId,
    StorageLocation? editing,
  }) async {
    final state = AppScope.of(context);
    final name = TextEditingController(text: editing?.name ?? '');
    var parent = editing?.parentId ?? parentId ?? '';
    var icon = editing?.icon ?? '📍';
    String? error;
    final blockedParents = <String>{};
    if (editing != null) {
      blockedParents.add(editing.id);
      var changed = true;
      while (changed) {
        changed = false;
        for (final location in state.locations) {
          if (location.parentId != null &&
              blockedParents.contains(location.parentId) &&
              blockedParents.add(location.id)) {
            changed = true;
          }
        }
      }
    }
    await showAssetlySheet(
      context,
      StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeader(
                  title: editing != null
                      ? '修改收纳空间'
                      : parentId == null
                      ? '添加收纳空间'
                      : '添加子空间',
                  subtitle: editing != null
                      ? '可修改空间名称、图标与所在层级'
                      : parentId == null
                      ? '可创建主区域，或选择一个上级空间'
                      : '将在所选空间下创建新的收纳层级',
                ),
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '空间名称',
                    errorText: error,
                  ),
                  onChanged: (_) {
                    if (error != null) setLocal(() => error = null);
                  },
                ),
                const SizedBox(height: 9),
                AssetIconPicker(
                  value: icon,
                  title: '空间图标',
                  subtitle: '选择便于识别房间、柜子或收纳盒的图标',
                  sheetTitle: '选择空间图标',
                  sheetSubtitle: '图标会显示在空间列表和收纳贴纸中',
                  choices: spaceIconChoices,
                  onChanged: (value) => setLocal(() => icon = value),
                ),
                const SizedBox(height: 9),
                AppSelectField<String>(
                  label: '上级空间',
                  value: parent,
                  options: [
                    const SelectOption('', '家庭全景（根空间）'),
                    ...state.locations
                        .where(
                          (location) => !blockedParents.contains(location.id),
                        )
                        .map((x) => SelectOption(x.id, x.fullPath)),
                  ],
                  onChanged: (value) => setLocal(() => parent = value),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final value = name.text.trim();
                      if (value.isEmpty) {
                        setLocal(() => error = '请输入空间名称');
                        return;
                      }
                      final resolvedParent = parent.isEmpty ? null : parent;
                      final duplicate = state.locations.any(
                        (location) =>
                            location.id != editing?.id &&
                            location.parentId == resolvedParent &&
                            location.name == value,
                      );
                      if (duplicate) {
                        setLocal(() => error = '同一层级已存在同名空间');
                        return;
                      }
                      if (editing == null) {
                        await state.addLocation(
                          value,
                          icon: icon,
                          parentId: resolvedParent,
                        );
                      } else {
                        await state.updateLocation(
                          editing.id,
                          name: value,
                          icon: icon,
                          parentId: resolvedParent,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(editing == null ? '保存空间' : '保存修改'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _manage(BuildContext context, StorageLocation location) async {
    final action = await showAssetlySheet<String>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: location.name, subtitle: location.fullPath),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('修改空间'),
              subtitle: const Text('修改名称、图标或上级空间'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.folderPlus),
              title: const Text('添加子空间'),
              subtitle: const Text('例如柜子、抽屉或收纳盒'),
              onTap: () => Navigator.pop(context, 'add'),
            ),
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除空间',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    // Wait for the action sheet route to finish its reverse animation before
    // presenting the edit/add sheet. Opening both routes in the same frame can
    // make the second sheet disappear with the first one on physical devices.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!context.mounted) return;
    if (action == 'edit') {
      await _add(context, editing: location);
    } else if (action == 'add') {
      await _add(context, parentId: location.id);
    } else if (action == 'delete') {
      await _delete(context, location);
    }
  }

  Future<void> _delete(BuildContext context, StorageLocation location) async {
    final state = AppScope.of(context);
    final childCount = state.locations
        .where((item) => item.parentId == location.id)
        .length;
    final itemCount = [
      ...state.items.where((item) => item.locationId == location.id),
      ...state.medicines.where((item) => item.locationId == location.id),
    ].length;
    if (childCount > 0 || itemCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('暂时无法删除'),
          content: Text(
            '“${location.name}”中还有$itemCount 件物品、$childCount 个下级空间。请先移动物品并删除下级空间，避免丢失收纳关系。',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('删除这个空间？'),
            content: Text('将删除“${location.fullPath}”，此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      await state.deleteLocation(location.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除空间“${location.name}”')));
      }
    }
  }
}

class _StorageStickerSheet extends StatefulWidget {
  const _StorageStickerSheet({required this.controller});
  final AppController controller;

  @override
  State<_StorageStickerSheet> createState() => _StorageStickerSheetState();
}

class _StorageStickerSheetState extends State<_StorageStickerSheet> {
  final boundaryKey = GlobalKey();
  String locationId = '';
  bool exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locations = widget.controller.locations;
    if (locationId.isEmpty && locations.isNotEmpty) {
      locationId = locations.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    final location = state.locations.firstWhere(
      (item) => item.id == locationId,
      orElse: () => state.locations.first,
    );
    final assets = state.items
        .where(
          (item) =>
              item.locationPath == location.fullPath ||
              item.locationPath.startsWith('${location.fullPath} >'),
        )
        .map((item) => '${item.icon} ${item.name}')
        .toList();
    final medicines = state.medicines
        .where(
          (item) =>
              item.locationPath == location.fullPath ||
              item.locationPath.startsWith('${location.fullPath} >'),
        )
        .map((item) => '💊 ${item.name}')
        .toList();
    final contents = [...assets, ...medicines];
    final qrData = [
      'Assetly 收纳清单',
      '空间：${location.fullPath}',
      '共 ${contents.length} 件',
      ...contents,
    ].join('\n');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SheetHeader(title: '生成收纳贴纸', subtitle: '扫码可直接读取空间名称和当前物品清单'),
          AppSelectField<String>(
            label: '选择空间',
            value: locationId,
            options: state.locations
                .map((item) => SelectOption(item.id, item.fullPath))
                .toList(),
            onChanged: (value) => setState(() => locationId = value),
          ),
          const SizedBox(height: 14),
          Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                width: 300,
                color: Colors.white,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSETLY · STORAGE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${location.icon} ${location.name}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      location.fullPath,
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QrImageView(
                          data: qrData,
                          size: 118,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${contents.length} 件物品',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...contents
                                  .take(5)
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF3F3F46),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              if (contents.length > 5)
                                Text(
                                  '另有 ${contents.length - 5} 件…',
                                  style: const TextStyle(
                                    color: Color(0xFF71717A),
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '扫码查看标签生成时的收纳清单 · 数据由 Assetly 本地生成',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: exporting ? null : () => _share(location.name),
            icon: exporting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.share2, size: 18),
            label: Text(exporting ? '正在生成…' : '分享 / 打印贴纸'),
          ),
        ],
      ),
    );
  }

  Future<void> _share(String name) async {
    setState(() => exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/assetly-storage-label.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: 'Assetly 收纳贴纸 · $name');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.root,
    required this.locations,
    required this.items,
    required this.onManage,
  });
  final StorageLocation root;
  final List<StorageLocation> locations;
  final List<dynamic> items;
  final ValueChanged<StorageLocation> onManage;
  @override
  Widget build(BuildContext context) {
    final legacyIcons = {
      '主卧': '🛏️',
      '客厅与玄关': '🛋️',
      '厨房与水吧': '☕',
      '储藏间与阳台': '🧳',
    };
    final rootIcon = root.icon == '📍'
        ? legacyIcons[root.name] ?? root.icon
        : root.icon;
    final value = items.fold<double>(
      0,
      (a, b) => a + (b.purchasePrice as double),
    );
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.muted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(rootIcon, style: const TextStyle(fontSize: 21)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      root.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${items.length} 件在役物品 · 资产总值 ¥ ${NumberFormat('#,##0').format(value)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '管理${root.name}',
                onPressed: () => onManage(root),
                icon: const Icon(LucideIcons.settings2, size: 19),
              ),
            ],
          ),
          if (locations.any((item) => item.parentId == root.id)) ...[
            const SizedBox(height: 12),
            Text('子空间（点击可管理）：', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            ..._childTiles(context, root.id, 0),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '代表资产：${items.take(4).map((x) => x.name).join('、')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _childTiles(BuildContext context, String parentId, int depth) =>
      locations
          .where((item) => item.parentId == parentId)
          .expand(
            (location) => [
              Padding(
                padding: EdgeInsets.only(left: depth * 14.0),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    location.icon,
                    style: const TextStyle(fontSize: 19),
                  ),
                  title: Text(location.name),
                  subtitle: Text('${location.itemCount} 件物品'),
                  trailing: const Icon(LucideIcons.settings2, size: 17),
                  onTap: () => onManage(location),
                ),
              ),
              ..._childTiles(context, location.id, depth + 1),
            ],
          )
          .toList();
}
