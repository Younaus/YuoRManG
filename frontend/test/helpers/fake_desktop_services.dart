import 'dart:async';

import 'package:yourmang/core/desktop/global_hotkey_service.dart';
import 'package:yourmang/core/desktop/tray_service.dart';

/// Windows sistem tepsisini taklit eder: eylemleri tetikler, pencere çağrılarını kaydeder.
class FakeDesktopTrayService implements DesktopTrayService {
  final calls = <String>[];
  final _actions = StreamController<TrayAction>.broadcast();

  bool visible = true;
  bool minimized = false;
  bool focused = true;

  void trigger(TrayAction action) => _actions.add(action);

  @override
  bool get isSupported => true;

  @override
  Stream<TrayAction> get actions => _actions.stream;

  @override
  Future<void> showWindow() async {
    calls.add('show');
    visible = true;
    minimized = false;
    focused = true;
  }

  @override
  Future<void> hideWindow() async {
    calls.add('hide');
    visible = false;
    focused = false;
  }

  @override
  Future<void> minimizeWindow() async {
    calls.add('minimize');
    minimized = true;
    focused = false;
  }

  @override
  Future<void> blurWindow() async {
    calls.add('blur');
    focused = false;
  }

  @override
  Future<bool> isWindowVisible() async => visible;

  @override
  Future<bool> isWindowMinimized() async => minimized;

  @override
  Future<bool> isWindowFocused() async => focused;

  @override
  Future<void> quit() async => calls.add('quit');
}

/// Sistem geneli Ctrl+Alt+N kısayolunu taklit eder.
class FakeGlobalHotkeyService implements GlobalHotkeyService {
  final _quickCapture = StreamController<void>.broadcast();
  bool disposed = false;

  void press() => _quickCapture.add(null);

  @override
  bool get isSupported => true;

  @override
  Stream<void> get quickCapture => _quickCapture.stream;

  @override
  Future<void> dispose() async => disposed = true;
}
