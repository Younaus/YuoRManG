import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'corner_window_platform_stub.dart' if (dart.library.io) 'corner_window_platform_io.dart' as platform;

/// Köşe modunda pencere boyutu (mantıksal piksel).
const cornerWindowSize = Size(300, 68);

/// Köşe modunda pencere opaklığı: fare dışarıdayken soluk, üzerindeyken neredeyse opak.
const cornerIdleOpacity = 0.78;
const cornerHoverOpacity = 0.98;

/// Ekran kenarı / görev çubuğu ile köşe penceresi arasındaki boşluk.
const cornerScreenMargin = 16.0;

/// "Mini Köşe Modu" için pencere işlemleri. Gerçek uygulama yalnızca Windows masaüstünde
/// çalışır; Web, Android ve testlerde [NoopCornerWindowService] kullanılır.
abstract interface class CornerWindowService {
  /// Bu platformda köşe modu kullanılabilir mi (yalnızca Windows).
  bool get isSupported;

  /// Kullanıcı pencereyi küçülttüğünde (köşe modundayken değil) tetiklenir.
  Stream<void> get onMinimize;

  /// Pencereyi çerçevesiz, sabit boyutlu, her zaman üstte küçük bir hap olarak sağ alt köşeye alır.
  Future<void> enterCornerMode();

  /// Önceki boyut, konum ve pencere stiline döner.
  Future<void> exitCornerMode();

  Future<void> setOpacity(double opacity);

  /// Basılı tutup sürükleyince pencereyi taşıyan alan.
  Widget dragArea({required Widget child});
}

/// Desteklenmeyen platformlar ve testler: hiçbir şey yapmaz.
class NoopCornerWindowService implements CornerWindowService {
  const NoopCornerWindowService();

  @override
  bool get isSupported => false;

  @override
  Stream<void> get onMinimize => const Stream.empty();

  @override
  Future<void> enterCornerMode() async {}

  @override
  Future<void> exitCornerMode() async {}

  @override
  Future<void> setOpacity(double opacity) async {}

  @override
  Widget dragArea({required Widget child}) => child;
}

/// Platforma uygun servisi oluşturur (Windows'ta `window_manager` başlatılır).
/// `main()` içinde çağrılıp [cornerWindowServiceProvider] override edilir.
Future<CornerWindowService> createCornerWindowService() => platform.createCornerWindowService();

/// Varsayılan no-op; gerçek servis `main()` içinde verilir.
final cornerWindowServiceProvider = Provider<CornerWindowService>((ref) => const NoopCornerWindowService());
