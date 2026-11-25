import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/tray_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/task.dart';
import 'corner_mode_providers.dart';
import 'task_providers.dart';

/// Sistem tepsisi eylemlerinin pencere tarafı: ana pencereyi açma, köşe kapsülünü aç/kapat, çıkış.
/// (Görev formu gibi arayüz gerektiren eylemler `DesktopShellHost` içinde açılır.)
class DesktopShellController extends Notifier<void> {
  DesktopTrayService get _tray => ref.read(desktopTrayServiceProvider);

  @override
  void build() {}

  /// Köşe kapsülündeyse önce ondan çıkar, sonra pencereyi (tepside/küçültülmüş olsa bile) öne getirir.
  Future<void> openMainWindow() async {
    if (ref.read(cornerModeProvider).active) await ref.read(cornerModeProvider.notifier).exit();
    await _tray.showWindow();
  }

  /// Kapsül açıksa ana pencereye döner; kapalıysa devam eden görev varsa kapsüle geçer,
  /// yoksa ana pencereyi açar.
  Future<void> toggleCorner() async {
    if (ref.read(cornerModeProvider).active) return openMainWindow();
    var active = const <Task>[];
    if (ref.read(currentUidProvider) != null) {
      try {
        active = await ref.read(activeTasksProvider.future);
      } catch (_) {}
    }
    if (active.isEmpty) return openMainWindow();
    await ref.read(cornerModeProvider.notifier).enter();
  }

  Future<void> quit() => _tray.quit();
}

final desktopShellProvider = NotifierProvider<DesktopShellController, void>(DesktopShellController.new);
