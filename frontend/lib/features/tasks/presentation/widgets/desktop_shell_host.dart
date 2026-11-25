import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/tray_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/desktop_shell_providers.dart';
import 'task_form.dart';

/// Uygulamanın kökünde: Windows sistem tepsisi eylemlerini dinler ve uygular.
/// Diğer platformlarda tepsi servisi no-op olduğu için hiçbir şey yapmaz.
class DesktopShellHost extends ConsumerStatefulWidget {
  const DesktopShellHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DesktopShellHost> createState() => _DesktopShellHostState();
}

class _DesktopShellHostState extends ConsumerState<DesktopShellHost> {
  StreamSubscription<TrayAction>? _trayActions;

  @override
  void initState() {
    super.initState();
    _trayActions = ref.read(desktopTrayServiceProvider).actions.listen(_onTrayAction);
  }

  @override
  void dispose() {
    _trayActions?.cancel();
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
        await shell.openMainWindow();
        final context = _navigatorContext;
        if (context != null && context.mounted && ref.read(currentUidProvider) != null) {
          await showNewTaskForm(context, ref);
        }
      case TrayAction.toggleCorner:
        await shell.toggleCorner();
      case TrayAction.quit:
        await shell.quit();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
