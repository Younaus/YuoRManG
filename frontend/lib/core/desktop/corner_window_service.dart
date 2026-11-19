import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'corner_window_platform_stub.dart' if (dart.library.io) 'corner_window_platform_io.dart' as platform;

/// Köşe kapsülünün pencere boyutu (mantıksal piksel). Pencere bu boyutta kapsül biçimine kırpılır.
const cornerWindowSize = Size(280, 52);

/// Köşe modunda pencere opaklığı: fare uzaktayken çok soluk, üzerine gelince net.
const cornerIdleOpacity = 0.72;
const cornerHoverOpacity = 0.96;

/// Ekran kenarı / görev çubuğu ile köşe kapsülü arasındaki boşluk.
const cornerScreenMargin = 16.0;

/// "Mini Köşe Modu" için pencere işlemleri. Gerçek uygulama yalnızca Windows masaüstünde
/// çalışır; Web, Android ve testlerde [NoopCornerWindowService] kullanılır.
abstract interface class CornerWindowService {
  /// Bu platformda köşe modu kullanılabilir mi (yalnızca Windows).
  bool get isSupported;

  /// Kullanıcı tam pencereyi küçülttüğünde tetiklenir (köşe modundayken değil).
  Stream<void> get onMinimize;

  /// Köşe kapsülü küçültülüp görev çubuğundan geri açıldığında tetiklenir:
  /// kullanıcı ana pencereyi istiyor demektir.
  Stream<void> get onRestoreRequested;

  /// Pencereyi görünmez yapıp [onHidden]'ı çağırır (arayüz kapsüle geçer), ardından
  /// çerçevesiz, sabit boyutlu, her zaman üstte bir kapsül olarak sağ alt köşede yumuşakça gösterir.
  Future<void> enterCornerMode({VoidCallback? onHidden});

  /// Pencereyi görünmez yapıp [onHidden]'ı çağırır (arayüz tam ekrana döner), ardından
  /// önceki boyut, konum ve pencere stiliyle geri getirir. Hata olsa bile pencereyi görünür bırakır.
  Future<void> exitCornerMode({VoidCallback? onHidden});

  Future<void> setOpacity(double opacity);

  /// Basılı tutup sürükleyince pencereyi taşıyan alan.
  Widget dragArea({required Widget child});
}

/// Desteklenmeyen platformlar ve testler: pencereye dokunmaz, yalnızca geri çağrıları çalıştırır.
class NoopCornerWindowService implements CornerWindowService {
  const NoopCornerWindowService();

  @override
  bool get isSupported => false;

  @override
  Stream<void> get onMinimize => const Stream.empty();

  @override
  Stream<void> get onRestoreRequested => const Stream.empty();

  @override
  Future<void> enterCornerMode({VoidCallback? onHidden}) async => onHidden?.call();

  @override
  Future<void> exitCornerMode({VoidCallback? onHidden}) async => onHidden?.call();

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
