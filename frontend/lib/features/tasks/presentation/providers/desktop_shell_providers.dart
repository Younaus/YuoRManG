import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/global_hotkey_service.dart';
import '../../../../core/desktop/tray_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/task.dart';
import 'corner_mode_providers.dart';
import 'task_providers.dart';

/// Hızlı görev öncesinde pencerenin nerede olduğu — kayıttan sonra oraya geri dönülür.
enum WindowPresence {
  /// Ön planda, odaklı: dokunulmaz.
  foreground,

  /// Görünür ama başka bir uygulama önde.
  background,
  minimized,

  /// Sistem tepsisinde gizli.
  hidden,

  /// Köşe kapsülü açık.
  corner,
}

/// Sistem tepsisi / global kısayol eylemlerinin pencere tarafı: ana pencereyi açma, köşe kapsülünü
/// aç/kapat, hızlı görev sonrası önceki duruma dönüş ve çıkış.
/// (Diyalog gibi arayüz gerektiren adımlar `DesktopShellHost` içinde açılır.)
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

  Future<WindowPresence> currentPresence() async {
    if (ref.read(cornerModeProvider).active) return WindowPresence.corner;
    if (!await _tray.isWindowVisible()) return WindowPresence.hidden;
    if (await _tray.isWindowMinimized()) return WindowPresence.minimized;
    return await _tray.isWindowFocused() ? WindowPresence.foreground : WindowPresence.background;
  }

  /// Pencereyi hızlı görev öncesindeki yerine geri gönderir.
  Future<void> restorePresence(WindowPresence presence) async {
    switch (presence) {
      case WindowPresence.foreground:
        return;
      case WindowPresence.background:
        await _tray.blurWindow();
      case WindowPresence.minimized:
        await _tray.minimizeWindow();
      case WindowPresence.hidden:
        await _tray.hideWindow();
      case WindowPresence.corner:
        await ref.read(cornerModeProvider.notifier).enter();
    }
  }

  /// Global kısayol kaydını temizleyip uygulamayı sonlandırır.
  Future<void> quit() async {
    await ref.read(globalHotkeyServiceProvider).dispose();
    await _tray.quit();
  }
}

final desktopShellProvider = NotifierProvider<DesktopShellController, void>(DesktopShellController.new);
