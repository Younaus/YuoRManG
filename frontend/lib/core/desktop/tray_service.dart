import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tray_platform_stub.dart' if (dart.library.io) 'tray_platform_io.dart' as platform;

/// Sistem tepsisi menüsünden / ikonundan gelen istekler.
enum TrayAction {
  /// Sol tık veya "YouRManG'ı Aç".
  open,

  /// "Hızlı Görev Ekle (Ctrl+Alt+N)".
  quickAdd,

  /// "Köşe Kapsülünü Aç/Kapat".
  toggleCorner,

  /// "Çıkış": uygulamayı gerçekten sonlandırır.
  quit,
}

/// Windows sistem tepsisi + "kapatınca tepsiye gizle" davranışı. Gerçek uygulama yalnızca
/// Windows masaüstünde çalışır; Web, Android ve testlerde [NoopDesktopTrayService] kullanılır.
abstract interface class DesktopTrayService {
  bool get isSupported;

  /// Tepsi ikonu ve menü öğesi tıklamaları.
  Stream<TrayAction> get actions;

  /// Pencereyi (gizli/küçültülmüş olsa bile) gösterip öne getirir.
  Future<void> showWindow();

  /// Pencereyi sistem tepsisine gizler (uygulama çalışmaya devam eder).
  Future<void> hideWindow();

  Future<void> minimizeWindow();

  Future<bool> isWindowVisible();

  Future<bool> isWindowMinimized();

  /// Pencere şu an öne getirilmiş (odaklı) mı.
  Future<bool> isWindowFocused();

  /// Tepsi ikonunu kaldırır ve uygulamayı sonlandırır.
  Future<void> quit();
}

class NoopDesktopTrayService implements DesktopTrayService {
  const NoopDesktopTrayService();

  @override
  bool get isSupported => false;

  @override
  Stream<TrayAction> get actions => const Stream.empty();

  @override
  Future<void> showWindow() async {}

  @override
  Future<void> hideWindow() async {}

  @override
  Future<void> minimizeWindow() async {}

  @override
  Future<bool> isWindowVisible() async => true;

  @override
  Future<bool> isWindowMinimized() async => false;

  @override
  Future<bool> isWindowFocused() async => true;

  @override
  Future<void> quit() async {}
}

/// Platforma uygun servisi oluşturur (`main()` içinde, köşe kapsülü servisinden sonra).
Future<DesktopTrayService> createDesktopTrayService() => platform.createDesktopTrayService();

/// Varsayılan no-op; gerçek servis `main()` içinde verilir.
final desktopTrayServiceProvider = Provider<DesktopTrayService>((ref) => const NoopDesktopTrayService());
