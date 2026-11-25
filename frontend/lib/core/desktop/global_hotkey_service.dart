import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'global_hotkey_platform_stub.dart' if (dart.library.io) 'global_hotkey_platform_io.dart' as platform;

/// Sistem geneli hızlı görev kısayolu.
const quickCaptureShortcutLabel = 'Ctrl+Alt+N';

/// Windows'ta sistem geneli `Ctrl+Alt+N` (uygulama tepside / arka planda olsa bile).
/// Web, Android ve testlerde [NoopGlobalHotkeyService] kullanılır.
abstract interface class GlobalHotkeyService {
  bool get isSupported;

  /// Kısayola her basıldığında.
  Stream<void> get quickCapture;

  /// Kısayol kaydını işletim sisteminden kaldırır (çıkışta).
  Future<void> dispose();
}

class NoopGlobalHotkeyService implements GlobalHotkeyService {
  const NoopGlobalHotkeyService();

  @override
  bool get isSupported => false;

  @override
  Stream<void> get quickCapture => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

Future<GlobalHotkeyService> createGlobalHotkeyService() => platform.createGlobalHotkeyService();

/// Varsayılan no-op; gerçek servis `main()` içinde verilir.
final globalHotkeyServiceProvider = Provider<GlobalHotkeyService>((ref) => const NoopGlobalHotkeyService());
