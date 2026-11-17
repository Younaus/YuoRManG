import 'package:flutter/widgets.dart';

/// Material 3 pencere sınıflarına yakın kırılım noktaları.
///  - compact  (< 600):  telefon → alt navigasyon + çekmece (drawer)
///  - medium   (< 1000): tablet / dar pencere → NavigationRail + çekmece
///  - expanded (≥ 1000): masaüstü → sabit yan menü (kategori ağacı ile)
enum WindowSize {
  compact,
  medium,
  expanded;

  static const compactMax = 600.0;
  static const mediumMax = 1000.0;

  static WindowSize fromWidth(double width) => width < compactMax
      ? WindowSize.compact
      : width < mediumMax
          ? WindowSize.medium
          : WindowSize.expanded;
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize => WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
