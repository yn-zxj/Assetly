import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../state/app_controller.dart';
import '../theme/assetly_theme.dart';
import 'screens/home_screen.dart';
import 'screens/items_screen.dart';
import 'screens/pharmacy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spaces_screen.dart';
import 'widgets/common.dart';
import 'widgets/update_dialog.dart';

class _DockItem {
  const _DockItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _dockItems = [
  _DockItem(LucideIcons.home, '首页'),
  _DockItem(LucideIcons.package, '物品'),
  _DockItem(LucideIcons.pill, '药箱'),
  _DockItem(LucideIcons.layers, '空间'),
  _DockItem(LucideIcons.settings, '设置'),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int index = 0;
  bool updateCheckStarted = false;
  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  late final Animation<double> _tabOpacity = CurvedAnimation(
    parent: _tabFade,
    curve: Curves.easeInOut,
  );
  late final pages = [
    HomeScreen(onNavigate: (i) => _select(i)),
    const ItemsScreen(),
    const PharmacyScreen(),
    const SpacesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
  }

  @override
  void dispose() {
    _tabFade.dispose();
    super.dispose();
  }

  void _select(int value) {
    if (value == index) return;
    setState(() => index = value);
    // Start most of the way in: a fade from zero leaves the new tab nearly
    // invisible for the first frames, which reads as a tap that did nothing.
    _tabFade.forward(from: .55);
  }

  Future<void> _checkForUpdates() async {
    if (updateCheckStarted) return;
    updateCheckStarted = true;
    final release = await widget.controller.checkForUpdates();
    if (!mounted || release == null) return;
    await showAppUpdateDialog(
      context,
      release: release,
      currentVersion: widget.controller.appVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) _select(0);
      },
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Row(
            children: [
              if (wide) _SideDock(index: index, onSelect: _select),
              Expanded(
                child: FadeTransition(
                  opacity: _tabOpacity,
                  child: IndexedStack(index: index, children: pages),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : _FloatingDock(index: index, onSelect: _select),
      ),
    );
  }
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppCorner.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? .45 : .1),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppCorner.full),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: context.colors.card.withValues(
                  alpha: context.isDark ? .82 : .84,
                ),
                borderRadius: BorderRadius.circular(AppCorner.full),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: .8),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slot = (constraints.maxWidth - 12) / _dockItems.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        left: 6 + index * slot + 2,
                        width: slot - 4,
                        top: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: context.colors.primary.withValues(
                              alpha: context.isDark ? .2 : .1,
                            ),
                            shape: AppShape.pill,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _dockItems.length; i++)
                            Expanded(
                              child: _DockButton(
                                item: _dockItems[i],
                                selected: i == index,
                                onTap: () => onSelect(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DockItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.primary
        : context.colors.mutedForeground;
    return ElasticPress(
      maxGrowth: 7,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(item.icon, size: 20, color: color),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideDock extends StatelessWidget {
  const _SideDock({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: context.colors.card,
        shape: AppShape.all(AppCorner.xl, border: context.colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: NavigationRail(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          labelType: NavigationRailLabelType.all,
          minWidth: 78,
          groupAlignment: -1,
          destinations: [
            for (final item in _dockItems)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon),
                label: Text(item.label),
              ),
          ],
        ),
      ),
    ),
  );
}
