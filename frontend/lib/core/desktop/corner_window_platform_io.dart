import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

  /// Runner'daki (windows/runner/flutter_window.cpp) kapsül bölgesi kanalı.
  static const _shape = MethodChannel('yourmang/window_shape');

  final _minimize = StreamController<void>.broadcast();
  final _restoreRequested = StreamController<void>.broadcast();

  /// Giriş/çıkış işlemlerini sıraya koyar: arka arkaya tıklama/küçültme pencereyi yarım bırakmaz.
  Future<void> _queue = Future.value();

  Rect? _restoreBounds;
  bool _wasMaximized = false;
  bool _inCorner = false;
  bool _transitioning = false;

  Future<void> _init() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
  }

  @override
  bool get isSupported => true;

  @override
  Stream<void> get onMinimize => _minimize.stream;

  @override
  Stream<void> get onRestoreRequested => _restoreRequested.stream;

  @override
  void onWindowMinimize() {
    if (!_inCorner && !_transitioning) _minimize.add(null);
  }

  @override
  void onWindowRestore() {
    // Kapsül görev çubuğundan küçültülüp geri açıldı → ana pencereyi geri ver (kullanıcı kapsülde kilitli kalmaz).
    if (_inCorner && !_transitioning) _restoreRequested.add(null);
  }

  @override
  Future<void> enterCornerMode({VoidCallback? onHidden}) => _serial(() async {
    if (_inCorner) return onHidden?.call();
    _inCorner = true;
    try {
      // Geçiş boyunca pencere görünmez: büyük pencerenin küçülüşü / yanıp sönme görülmez.
      await windowManager.setOpacity(0);
      // Sistem tepsisine gizlenmişse önce (görünmez hâlde) göster.
      if (!await windowManager.isVisible()) await windowManager.show();
      if (await windowManager.isMinimized()) await windowManager.restore();
      _wasMaximized = await windowManager.isMaximized();
      if (_wasMaximized) await windowManager.unmaximize();
      _restoreBounds = await windowManager.getBounds();
      onHidden?.call();

      await windowManager.setAsFrameless();
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(cornerWindowSize);
      await windowManager.setPosition(await _bottomRightOf(_restoreBounds!));
      await _setCapsule(true);
      await _settleFrame();
      await _fade(to: cornerIdleOpacity);
    } catch (_) {
      // Herhangi bir adım başarısız olursa pencereyi normal ve görünür hâle getir.
      await _restoreWindow();
      _inCorner = false;
      rethrow;
    }
  });

  @override
  Future<void> exitCornerMode({VoidCallback? onHidden}) => _serial(() async {
    if (!_inCorner) return onHidden?.call();
    await _quiet(() => windowManager.setOpacity(0));
    onHidden?.call();
    await _restoreWindow();
    _inCorner = false;
  });

  @override
  Future<void> setOpacity(double opacity) async {
    if (_inCorner && !_transitioning) await windowManager.setOpacity(opacity);
  }

  /// `DragToMoveArea` ile aynı mekanizma (`startDragging`), ancak çift tıklayınca
  /// pencereyi büyütmez — kapsülün tam ekran olmasını önler.
  @override
  Widget dragArea({required Widget child}) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onPanStart: (_) => windowManager.startDragging(),
    child: child,
  );

  /// Her adım ayrı ayrı denenir: biri başarısız olsa bile pencere tam boyutta ve görünür kalır.
  Future<void> _restoreWindow() async {
    await _quiet(() => windowManager.setOpacity(0));
    await _quiet(() => _setCapsule(false));
    await _quiet(() => windowManager.setAlwaysOnTop(false));
    await _quiet(() => windowManager.setTitleBarStyle(TitleBarStyle.normal)); // çerçeveyi geri getirir
    await _quiet(() => windowManager.setResizable(true));
    final bounds = _restoreBounds;
    if (bounds != null) await _quiet(() => windowManager.setBounds(bounds));
    if (_wasMaximized) await _quiet(windowManager.maximize);
    await _quiet(_settleFrame);
    await _quiet(() => _fade(to: 1));
    await _quiet(windowManager.focus);
  }

  Future<void> _serial(Future<void> Function() action) {
    final run = _queue.then((_) async {
      _transitioning = true;
      try {
        await action();
      } finally {
        _transitioning = false;
      }
    });
    _queue = run.catchError((Object _) {});
    return run;
  }

  Future<void> _setCapsule(bool enabled) async {
    try {
      await _shape.invokeMethod<void>('setCapsule', enabled);
    } on MissingPluginException {
      // Eski runner: kapsül kırpması yok, köşe modu dikdörtgen pencereyle çalışır.
    }
  }

  /// Yeni boyuttaki ilk karenin çizilmesini bekle (görünür olmadan önce).
  Future<void> _settleFrame() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    SchedulerBinding.instance.scheduleFrame();
    await SchedulerBinding.instance.endOfFrame;
  }

  /// 0'dan hedef opaklığa kısa ve yumuşak geçiş.
  Future<void> _fade({required double to}) async {
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      await windowManager.setOpacity(to * Curves.easeOut.transform(i / steps));
      if (i < steps) await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  static Future<void> _quiet(Future<void> Function() step) async {
    try {
      await step();
    } catch (_) {}
  }

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
