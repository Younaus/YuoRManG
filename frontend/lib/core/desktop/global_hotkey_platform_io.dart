import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'global_hotkey_service.dart';

/// Yalnızca Windows masaüstünde gerçek servis; diğer platformlar ve `flutter test` no-op.
Future<GlobalHotkeyService> createGlobalHotkeyService() async {
  if (kIsWeb || !Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) {
    return const NoopGlobalHotkeyService();
  }
  final service = WindowsGlobalHotkeyService._();
  try {
    await service._register();
    return service;
  } catch (e) {
    // Ör. kısayol başka bir uygulamada kayıtlı: uygulama kısayolsuz çalışmaya devam eder.
    debugPrint('[hotkey] $quickCaptureShortcutLabel kaydedilemedi: $e');
    return const NoopGlobalHotkeyService();
  }
}

class WindowsGlobalHotkeyService implements GlobalHotkeyService {
  WindowsGlobalHotkeyService._();

  final _quickCapture = StreamController<void>.broadcast();

  final _hotKey = HotKey(
    identifier: 'yourmang.quickCapture',
    key: PhysicalKeyboardKey.keyN,
    modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );

  Future<void> _register() async {
    // Hot restart'tan kalan kayıtları temizle.
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(_hotKey, keyDownHandler: (_) => _quickCapture.add(null));
  }

  @override
  bool get isSupported => true;

  @override
  Stream<void> get quickCapture => _quickCapture.stream;

  @override
  Future<void> dispose() async {
    try {
      await hotKeyManager.unregister(_hotKey);
    } catch (_) {}
  }
}
