import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/item_icons.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

/// Full-screen icon library. Same chrome as the other detail pages so picking
/// an icon feels like a settings page rather than a cramped bottom sheet.
class IconPickerScreen extends StatefulWidget {
  const IconPickerScreen({
    super.key,
    required this.selected,
    this.title = '选择物品图标',
  });

  final String selected;
  final String title;

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _category = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSlug = itemIconSlug(widget.selected);
    final icons = searchItemIcons(_query, category: _category);
    return Scaffold(
      appBar: subPageAppBar(context, title: widget.title),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search, size: 19),
                  hintText: '搜索名称，如 相机、药品、沙发',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空搜索',
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(LucideIcons.x, size: 16),
                        ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: PillFilterBar<String>(
                value: _category,
                onChanged: (value) => setState(() => _category = value),
                options: [
                  const PillFilterOption('all', '全部'),
                  ...iconCategoryLabels.entries.map(
                    (e) => PillFilterOption(e.key, e.value),
                  ),
                ],
              ),
            ),
          ),
          if (icons.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: EmptyState(
                  icon: LucideIcons.search,
                  title: '没有匹配的图标',
                  description: '换个关键词，或选择其他分类',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 92,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: .98,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final spec = icons[index];
                  return _IconCell(
                    spec: spec,
                    selected: spec.slug == selectedSlug,
                    onTap: () =>
                        Navigator.pop(context, itemIconValue(spec.slug)),
                  );
                }, childCount: icons.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final IconSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return ElasticPress(
      maxGrowth: 5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: selected
                    ? accent.withValues(alpha: .14)
                    : context.colors.muted,
                shape: AppShape.all(
                  AppCorner.md,
                  border: selected ? accent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ItemIconArt(itemIconValue(spec.slug), size: 34),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? accent
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .72),
              ),
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
