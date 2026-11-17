import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_surfaces.dart';
import 'status_colors.dart';

/// "Clarity Workspace" Material 3 teması (açık + koyu): indigo vurgular, ferah nötr
/// yüzeyler, yuvarlatılmış köşeler ve Inter tipografisi.
abstract final class AppTheme {
  static const String fontFamily = 'Inter';

  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;

  static ThemeData light() => _build(_lightScheme, AppSurfaces.light, StatusColors.light);
  static ThemeData dark() => _build(_darkScheme, AppSurfaces.dark, StatusColors.dark);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.indigo100,
    onPrimaryContainer: AppColors.indigo900,
    inversePrimary: AppColors.indigo300,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.slate200,
    onSecondaryContainer: AppColors.slate800,
    tertiary: AppColors.emerald600,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.emerald100,
    onTertiaryContainer: AppColors.emerald900,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.lightBackground,
    onSurface: AppColors.neutral,
    onSurfaceVariant: AppColors.slate500,
    surfaceContainerLowest: AppColors.lightCard,
    surfaceContainerLow: AppColors.lightContainerLow,
    surfaceContainer: AppColors.lightContainer,
    surfaceContainerHigh: AppColors.lightContainerHigh,
    surfaceContainerHighest: AppColors.lightContainerHighest,
    surfaceTint: Colors.transparent,
    outline: AppColors.slate400,
    outlineVariant: AppColors.lightBorder,
    inverseSurface: AppColors.slate800,
    onInverseSurface: AppColors.slate100,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.indigo400,
    onPrimary: AppColors.indigo950,
    primaryContainer: AppColors.indigo800,
    onPrimaryContainer: AppColors.indigo100,
    inversePrimary: AppColors.primary,
    secondary: AppColors.emerald400,
    onSecondary: AppColors.emerald950,
    secondaryContainer: AppColors.emerald900,
    onSecondaryContainer: AppColors.emerald100,
    tertiary: AppColors.amber400,
    onTertiary: AppColors.amber950,
    tertiaryContainer: AppColors.amber900,
    onTertiaryContainer: AppColors.amber100,
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppColors.darkBackground,
    onSurface: AppColors.slate200,
    onSurfaceVariant: AppColors.slate400,
    surfaceContainerLowest: AppColors.darkContainerLowest,
    surfaceContainerLow: AppColors.darkContainerLow,
    surfaceContainer: AppColors.darkContainer,
    surfaceContainerHigh: AppColors.darkContainerHigh,
    surfaceContainerHighest: AppColors.darkContainerHighest,
    surfaceTint: Colors.transparent,
    outline: AppColors.secondary,
    outlineVariant: AppColors.darkBorder,
    inverseSurface: AppColors.slate200,
    onInverseSurface: AppColors.neutral,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final t = base.apply(fontFamily: fontFamily, bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    TextStyle? tight(TextStyle? s, FontWeight w, double spacing) => s?.copyWith(fontWeight: w, letterSpacing: spacing);
    return t.copyWith(
      displaySmall: tight(t.displaySmall, FontWeight.w700, -1.0),
      headlineMedium: tight(t.headlineMedium, FontWeight.w700, -0.6),
      headlineSmall: tight(t.headlineSmall, FontWeight.w700, -0.5),
      titleLarge: tight(t.titleLarge, FontWeight.w700, -0.4),
      titleMedium: tight(t.titleMedium, FontWeight.w600, -0.2),
      titleSmall: tight(t.titleSmall, FontWeight.w600, -0.1),
      bodyLarge: tight(t.bodyLarge, FontWeight.w400, -0.1),
      bodyMedium: tight(t.bodyMedium, FontWeight.w400, 0),
      bodySmall: tight(t.bodySmall, FontWeight.w400, 0),
      labelLarge: tight(t.labelLarge, FontWeight.w600, 0),
      labelMedium: tight(t.labelMedium, FontWeight.w500, 0),
      labelSmall: tight(t.labelSmall, FontWeight.w600, 0.2),
    );
  }

  static ThemeData _build(ColorScheme scheme, AppSurfaces surfaces, StatusColors status) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: fontFamily);
    final text = _textTheme(base.textTheme, scheme);

    RoundedRectangleBorder rounded(double r, [BorderSide side = BorderSide.none]) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r), side: side);
    final border = BorderSide(color: surfaces.border);
    const buttonSize = Size(64, 44);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: text,
      primaryTextTheme: _textTheme(base.primaryTextTheme, scheme),
      extensions: [status, surfaces],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surfaces.card,
        surfaceTintColor: Colors.transparent,
        shape: rounded(radiusLg, border),
      ),
      dividerTheme: DividerThemeData(color: surfaces.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        shape: rounded(radiusSm),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.onSurfaceVariant,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.card,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder(surfaces.border),
        enabledBorder: inputBorder(surfaces.border),
        focusedBorder: inputBorder(scheme.primary, 1.6),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        // Koyu temada da canlı indigo (#6366F1) + beyaz metin.
        style: FilledButton.styleFrom(
          backgroundColor: surfaces.fab,
          foregroundColor: surfaces.onFab,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: rounded(radiusSm),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: rounded(radiusSm),
          side: BorderSide(color: isDark ? AppColors.slate700 : AppColors.slate300),
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 40),
          shape: rounded(radiusSm),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: rounded(radiusSm),
          side: border,
          backgroundColor: surfaces.card,
          foregroundColor: scheme.onSurface,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: border,
        backgroundColor: surfaces.card,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.14),
        circularTrackColor: scheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),

      // Navigasyon: alt menü ve ray, seçili öğeyi indigo ikon + kalın etiketle gösterir.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.sidebar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)
              : text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaces.sidebar,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        indicatorShape: rounded(radiusMd),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaces.sidebar,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(radiusXl))),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        shape: rounded(radiusXl),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaces.card,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: rounded(radiusMd, border),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        shape: rounded(radiusXl),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded(radiusMd),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: isDark ? AppColors.primary : AppColors.indigo300,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(radiusXs)),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      // Yuvarlak, belirgin FAB (gölgesi AppFab'da indigo tonunda verilir).
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surfaces.fab,
        foregroundColor: surfaces.onFab,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        iconSize: 28,
        sizeConstraints: const BoxConstraints.tightFor(width: 60, height: 60),
      ),
    );
  }
}
