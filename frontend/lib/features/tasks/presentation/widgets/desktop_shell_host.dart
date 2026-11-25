import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/global_hotkey_service.dart';
import '../../../../core/desktop/tray_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/desktop_shell_providers.dart';
import 'quick_capture_dialog.dart';

/// Uygulamanın kökünde: Windows sistem tepsisi eylemlerini ve global `Ctrl+Alt+N` kısayolunu dinler.
/// Diğer platformlarda servisler no-op olduğu için hiçbir şey yapmaz.
class DesktopShellHost extends ConsumerStatefulWidget {
  const DesktopShellHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DesktopShellHost> createState() => _DesktopShellHostState();
}

class _DesktopShellHostState extends ConsumerState<DesktopShellHost> {
  StreamSubscription<TrayAction>? _trayActions;
  StreamSubscription<void>? _hotkey;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _trayActions = ref.read(desktopTrayServiceProvider).actions.listen(_onTrayAction);
    _hotkey = ref.read(globalHotkeyServiceProvider).quickCapture.listen((_) => _quickCapture());
  }

  @override
  void dispose() {
    _trayActions?.cancel();
    _hotkey?.cancel();
    super.dispose();
  }

  /// Router'ın kök Navigator'ı (diyaloglar MaterialApp.builder seviyesinin altında açılmalı).
  BuildContext? get _navigatorContext => ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;

  Future<void> _onTrayAction(TrayAction action) async {
    final shell = ref.read(desktopShellProvider.notifier);
    switch (action) {
      case TrayAction.open:
        await shell.openMainWindow();
      case TrayAction.quickAdd:
        await _quickCapture();
      case TrayAction.toggleCorner:
        await shell.toggleCorner();
      case TrayAction.quit:
        await shell.quit();
    }
  }

  /// `Ctrl+Alt+N` / tepsi menüsü: pencereyi öne getirip hızlı görev diyaloğunu açar; kaydedince
  /// veya `Esc` ile iptal edince pencereyi önceki yerine (tepsi, küçültülmüş, arka plan, kapsül) döndürür.
  Future<void> _quickCapture() async {
    final shell = ref.read(desktopShellProvider.notifier);
    if (_capturing) {
      // Diyalog zaten açık: yalnızca öne getir.
      await ref.read(desktopTrayServiceProvider).showWindow();
      return;
    }
    _capturing = true;
    try {
      final previous = await shell.currentPresence();
      await shell.openMainWindow();
      final context = _navigatorContext;
      // Oturum yoksa giriş ekranı açık kalır.
      if (context == null || !context.mounted || ref.read(currentUidProvider) == null) return;
      await showQuickCaptureDialog(context);
      await shell.restorePresence(previous);
    } finally {
      _capturing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
