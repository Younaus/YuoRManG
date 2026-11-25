import 'package:flutter/material.dart';

import 'app_routes.dart';

/// Ana navigasyon hedefleri. Sıra, router'daki StatefulShellBranch sırasıyla aynı olmalıdır.
/// Hem mobil alt menü hem masaüstü yan menü (Adım 4) bu listeden üretilir.
class AppDestination {
  const AppDestination({required this.path, required this.label, required this.icon, required this.selectedIcon});

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const appDestinations = <AppDestination>[
  AppDestination(
    path: AppRoutes.tasks,
    label: 'Görevler',
    icon: Icons.check_circle_outline,
    selectedIcon: Icons.check_circle,
  ),
  AppDestination(
    path: AppRoutes.calendar,
    label: 'Takvim',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  AppDestination(
    path: AppRoutes.categories,
    label: 'Kategoriler',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
  ),
  AppDestination(
    path: AppRoutes.settings,
    label: 'Ayarlar',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];
