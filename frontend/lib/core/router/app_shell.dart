import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_destinations.dart';

/// Oturum açıkken tüm sekmeleri saran iskelet.
///
/// Adım 3: basit alt navigasyon. Adım 4'te ekran genişliğine göre
/// (mobil: alt menü, masaüstü: sabit yan menü) şekil değiştiren responsive layout ile değiştirilecek.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    // Aktif sekmeye tekrar basılırsa o sekmenin kök sayfasına dönülür.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in appDestinations)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}
