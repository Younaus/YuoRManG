import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'corner_window_service.dart';

/// Yalnızca Windows masaüstünde gerçek servis; Android/iOS/macOS/Linux ve `flutter test` no-op.
Future<CornerWindowService> createCornerWindowService() async {
  if (kIsWeb || !Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) {
    return const NoopCornerWindowService();
  }
  final service = WindowsCornerWindowService._();
  await service._init();
  return service;
}

class WindowsCornerWindowService with WindowListener implements CornerWindowService {
  WindowsCornerWindowService._();

  final _minimize = StreamController<void>.broadcast();
  Rect? _restoreBounds;
  bool _wasMaximized = false;
  bool _inCorner = false;

  Future<void> _init() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
  }

  @override
  bool get isSupported => true;

  @override
  Stream<void> get onMinimize => _minimize.stream;

  @override
  void onWindowMinimize() {
    if (!_inCorner) _minimize.add(null);
  }

  @override
  Future<void> enterCornerMode() async {
    if (_inCorner) return;
    _inCorner = true;

    // Küçültülmüş/tam ekran pencerenin gerçek sınırlarını alabilmek için önce normale döndür.
    if (await windowManager.isMinimized()) await windowManager.restore();
    _wasMaximized = await windowManager.isMaximized();
    if (_wasMaximized) await windowManager.unmaximize();
    _restoreBounds = await windowManager.getBounds();

    await windowManager.setOpacity(cornerIdleOpacity);
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(true); // DWM gölgesi (+ Windows 11'de yuvarlak köşe)
    await windowManager.setResizable(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSize(cornerWindowSize);
    await windowManager.setPosition(await _bottomRightOf(_restoreBounds!));
  }

  @override
  Future<void> exitCornerMode() async {
    if (!_inCorner) return;
    _inCorner = false;

    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal); // çerçeveyi geri getirir
    await windowManager.setResizable(true);
    final bounds = _restoreBounds;
    if (bounds != null) await windowManager.setBounds(bounds);
    if (_wasMaximized) await windowManager.maximize();
    await windowManager.setOpacity(1);
    await windowManager.focus();
  }

  @override
  Future<void> setOpacity(double opacity) async {
    if (_inCorner) await windowManager.setOpacity(opacity);
  }

  /// `DragToMoveArea` ile aynı mekanizma (`startDragging`), ancak çift tıklayınca
  /// pencereyi büyütmez — köşe hapının tam ekran olmasını önler.
  @override
  Widget dragArea({required Widget child}) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onPanStart: (_) => windowManager.startDragging(),
    child: child,
  );

  /// Pencerenin bulunduğu ekranın çalışma alanında (görev çubuğu hariç) sağ alt köşe.
  Future<Offset> _bottomRightOf(Rect window) async {
    final displays = await screenRetriever.getAllDisplays();
    Display display = await screenRetriever.getPrimaryDisplay();
    for (final d in displays) {
      final area = (d.visiblePosition ?? Offset.zero) & (d.visibleSize ?? d.size);
      if (area.contains(window.center)) {
        display = d;
        break;
      }
    }
    final origin = display.visiblePosition ?? Offset.zero;
    final area = display.visibleSize ?? display.size;
    return Offset(
      origin.dx + area.width - cornerWindowSize.width - cornerScreenMargin,
      origin.dy + area.height - cornerWindowSize.height - cornerScreenMargin,
    );
  }
}
