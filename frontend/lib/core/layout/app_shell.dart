import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_destinations.dart';
import '../theme/app_surfaces.dart';
import '../widgets/brand.dart';
import 'app_sidebar.dart';
import 'breakpoints.dart';

/// Ekran genişliğine göre şekil değiştiren ana iskelet:
///  - compact:  alt NavigationBar (ince üst kenarlık + yumuşak gölge)
///  - medium:   logolu NavigationRail
///  - expanded: sabit yan menü (kategori ağacıyla)
class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Pencere yeniden boyutlanıp düzen değiştiğinde sayfa durumunun (kaydırma, form) korunması için.
  final _contentKey = GlobalKey();

  void _goBranch(int index) {
    // Aktif sekmeye tekrar basılırsa o sekmenin kök sayfasına dönülür.
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final content = KeyedSubtree(key: _contentKey, child: shell);

    return switch (context.windowSize) {
      WindowSize.expanded => Scaffold(
          body: Row(
            children: [
              AppSidebar(navigationShell: shell),
              Expanded(child: content),
            ],
          ),
        ),
      WindowSize.medium => Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _goBranch,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.9,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 20),
                  child: AppLogoMark(size: 40),
                ),
                destinations: [
                  for (final d in appDestinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              VerticalDivider(width: 1, color: context.surfaces.border),
              Expanded(child: content),
            ],
          ),
        ),
      WindowSize.compact => Scaffold(
          body: content,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.surfaces.border)),
              boxShadow: [BoxShadow(color: context.surfaces.shadow, blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _goBranch,
              destinations: [
                for (final d in appDestinations)
                  NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
              ],
            ),
          ),
        ),
    };
  }
}
