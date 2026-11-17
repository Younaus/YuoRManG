import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'status_colors.dart';

/// Minimalist, profesyonel Material 3 teması (açık + koyu).
abstract final class AppTheme {
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    ).copyWith(
      primary: isDark ? const Color(0xFF818CF8) : AppColors.seed,
      onPrimary: isDark ? const Color(0xFF1E1B4B) : Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceContainerLowest: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.lightSurfaceContainerLowest,
      surfaceContainerLow: isDark ? AppColors.darkSurfaceContainerLow : AppColors.lightSurfaceContainerLow,
      surfaceContainer: isDark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer,
      surfaceContainerHigh: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.lightSurfaceContainerHigh,
      surfaceContainerHighest: isDark ? AppColors.darkSurfaceContainerHighest : AppColors.lightSurfaceContainerHighest,
      outlineVariant: isDark ? const Color(0xFF2A2F3C) : const Color(0xFFE3E6EB),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final mdShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd));
    final smShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm));
    const buttonSize = Size(64, 44);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      extensions: [isDark ? StatusColors.dark : StatusColors.light],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(shape: smShape, contentPadding: const EdgeInsets.symmetric(horizontal: 16)),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: smShape, textStyle: text.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: smShape,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 40), shape: smShape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: smShape,
          side: BorderSide(color: scheme.outlineVariant),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: smShape,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelMedium,
      ),

      // Navigasyon (Adım 4'teki responsive iskelet bunları kullanır)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: smShape,
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: mdShape),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(6)),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 2,
        highlightElevation: 0,
        shape: mdShape,
      ),
    );
  }
}
