import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/assetly_theme.dart';
import 'screens/home_screen.dart';
import 'screens/items_screen.dart';
import 'screens/pharmacy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spaces_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  late final pages = [
    HomeScreen(onNavigate: (i) => setState(() => index = i)),
    const ItemsScreen(),
    const PharmacyScreen(),
    const SpacesScreen(),
    const SettingsScreen(),
  ];
  static const destinations = [
    NavigationDestination(
      icon: Icon(LucideIcons.home),
      selectedIcon: Icon(LucideIcons.home),
      label: '首页',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.package),
      selectedIcon: Icon(LucideIcons.package),
      label: '物品',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.pill),
      selectedIcon: Icon(LucideIcons.pill),
      label: '药箱',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.layers),
      selectedIcon: Icon(LucideIcons.layers),
      label: '空间',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.settings),
      selectedIcon: Icon(LucideIcons.settings),
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) setState(() => index = 0);
      },
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => index = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: context.colors.card,
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(
                child: IndexedStack(index: index, children: pages),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => index = i),
                  destinations: destinations,
                ),
              ),
      ),
    );
  }
}
