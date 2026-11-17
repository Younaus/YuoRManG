import 'package:flutter/material.dart';

/// Marka ve nötr renk paleti.
abstract final class AppColors {
  /// Marka rengi (indigo) — ColorScheme bu renkten türetilir.
  static const Color seed = Color(0xFF4F46E5);

  // Koyu tema yüzeyleri: saf siyah yerine hafif mavimsi nötr tonlar.
  static const Color darkSurface = Color(0xFF0F1117);
  static const Color darkSurfaceContainerLowest = Color(0xFF0B0D12);
  static const Color darkSurfaceContainerLow = Color(0xFF151821);
  static const Color darkSurfaceContainer = Color(0xFF1A1E28);
  static const Color darkSurfaceContainerHigh = Color(0xFF212532);
  static const Color darkSurfaceContainerHighest = Color(0xFF292E3C);

  // Açık tema yüzeyleri.
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF8F9FB);
  static const Color lightSurfaceContainer = Color(0xFFF3F4F7);
  static const Color lightSurfaceContainerHigh = Color(0xFFECEEF2);
  static const Color lightSurfaceContainerHighest = Color(0xFFE4E7EC);
}
