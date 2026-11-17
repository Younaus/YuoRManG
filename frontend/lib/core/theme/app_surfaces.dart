import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Clarity Workspace yüzey token'ları: kart, yan menü, kenarlık ve gölgeler.
/// M3 `ColorScheme` rolleri koyu temada "en alçak = en koyu" kuralını izlediği için
/// kart/yan menü renkleri ayrı tutulur. Kullanım: `context.surfaces`.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.card,
    required this.sidebar,
    required this.border,
    required this.shadow,
    required this.fab,
    required this.onFab,
  });

  static const light = AppSurfaces(
    card: AppColors.lightCard,
    sidebar: AppColors.lightCard,
    border: AppColors.lightBorder,
    shadow: Color(0x0A1E1B4B),
    fab: AppColors.primary,
    onFab: Colors.white,
  );

  static const dark = AppSurfaces(
    card: AppColors.darkCard,
    sidebar: AppColors.darkSidebar,
    border: AppColors.darkBorder,
    shadow: Color(0x66000000),
    fab: AppColors.primaryDark,
    onFab: Colors.white,
  );

  /// Kart / panel zemini.
  final Color card;

  /// Masaüstü yan menüsü, navigasyon rayı ve alt menü zemini.
  final Color sidebar;

  /// İnce (1 px) kenarlıklar.
  final Color border;

  /// Yumuşak, geniş yayılımlı kart gölgesi rengi.
  final Color shadow;

  /// Belirgin, yuvarlak FAB rengi.
  final Color fab;
  final Color onFab;

  /// Kartlar için iki katmanlı yumuşak gölge.
  List<BoxShadow> get cardShadow => [
    BoxShadow(color: shadow, blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 4)),
  ];

  @override
  AppSurfaces copyWith({Color? card, Color? sidebar, Color? border, Color? shadow, Color? fab, Color? onFab}) {
    return AppSurfaces(
      card: card ?? this.card,
      sidebar: sidebar ?? this.sidebar,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      fab: fab ?? this.fab,
      onFab: onFab ?? this.onFab,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      card: Color.lerp(card, other.card, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      fab: Color.lerp(fab, other.fab, t)!,
      onFab: Color.lerp(onFab, other.onFab, t)!,
    );
  }
}

extension AppSurfacesContext on BuildContext {
  AppSurfaces get surfaces => Theme.of(this).extension<AppSurfaces>()!;
}
