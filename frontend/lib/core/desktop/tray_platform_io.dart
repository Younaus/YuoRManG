import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'tray_service.dart';

/// Yalnızca Windows masaüstünde gerçek servis; diğer platformlar ve `flutter test` no-op.
Future<DesktopTrayService> createDesktopTrayService() async {
  if (kIsWeb || !Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) {
    return const NoopDesktopTrayService();
  }
  final service = WindowsTrayService._();
  try {
    await service._init();
    return service;
  } catch (e) {
    // Tepsi kurulamazsa X normal şekilde kapatmalı — aksi hâlde pencere geri getirilemez biçimde gizlenir.
    debugPrint('[tray] kurulamadı, tepsisiz devam: $e');
    await service._dispose();
    return const NoopDesktopTrayService();
  }
}

class WindowsTrayService with TrayListener, WindowListener implements DesktopTrayService {
  WindowsTrayService._();

  /// pubspec.yaml `assets:` altında; tray_manager `data/flutter_assets` köküne göre çözer.
  static const _iconAsset = 'assets/tray/tray_icon.ico';

  final _actions = StreamController<TrayAction>.broadcast();

  Future<void> _init() async {
    await windowManager.ensureInitialized();
    await trayManager.setIcon(_iconAsset);
    await trayManager.setToolTip('YouRManG');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: TrayAction.open.name, label: "YouRManG'ı Aç"),
          MenuItem(key: TrayAction.quickAdd.name, label: 'Hızlı Görev Ekle (Ctrl+Alt+N)'),
          MenuItem(key: TrayAction.toggleCorner.name, label: 'Köşe Kapsülünü Aç/Kapat'),
          MenuItem.separator(),
          MenuItem(key: TrayAction.quit.name, label: 'Çıkış'),
        ],
      ),
    );
    trayManager.addListener(this);

    // Tepsi hazır: artık X (ve Alt+F4) uygulamayı kapatmaz, tepsiye gizler; gerçek çıkış tepsi menüsünden.
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
  }

  Future<void> _dispose() async {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    try {
      await windowManager.setPreventClose(false);
      await trayManager.destroy();
    } catch (_) {}
  }

  @override
  bool get isSupported => true;

  @override
  Stream<TrayAction> get actions => _actions.stream;

  // --- Tepsi -----------------------------------------------------------------

  @override
  void onTrayIconMouseDown() => _actions.add(TrayAction.open);

  @override
  void onTrayIconRightMouseDown() {
    // Windows'ta menünün dışarı tıklayınca kapanabilmesi için uygulama öne alınmalı (SetForegroundWindow).
    // ignore: deprecated_member_use
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final action = TrayAction.values.where((a) => a.name == menuItem.key).firstOrNull;
    if (action != null) _actions.add(action);
  }

  // --- Pencere ---------------------------------------------------------------

  @override
  void onWindowClose() {
    // setPreventClose(true) iken X → tepsiye gizle.
    windowManager.isPreventClose().then((prevent) {
      if (prevent) hideWindow();
    });
  }

  @override
  Future<void> showWindow() async {
    if (await windowManager.isMinimized()) await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> hideWindow() => windowManager.hide();

  @override
  Future<void> minimizeWindow() => windowManager.minimize();

  @override
  Future<void> blurWindow() => windowManager.blur();

  @override
  Future<bool> isWindowVisible() => windowManager.isVisible();

  @override
  Future<bool> isWindowMinimized() => windowManager.isMinimized();

  @override
  Future<bool> isWindowFocused() => windowManager.isFocused();

  @override
  Future<void> quit() async {
    await _dispose();
    await windowManager.destroy();
  }
}
