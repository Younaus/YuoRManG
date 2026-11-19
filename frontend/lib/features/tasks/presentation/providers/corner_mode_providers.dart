import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/desktop/corner_window_service.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/task.dart';
import 'task_providers.dart';

/// Mini Köşe Modu durumu.
@immutable
class CornerModeState {
  const CornerModeState({this.active = false, this.focusedTaskId, this.completedTitle, this.error});

  /// Pencere köşe hapı olarak mı gösteriliyor.
  final bool active;

  /// Hapın gösterdiği görev; `null` → listedeki ilk aktif görev.
  final String? focusedTaskId;

  /// Az önce tamamlanan görevin başlığı — kısa "tamamlandı" geri bildirimi süresince dolu.
  final String? completedTitle;

  /// Son işlem başarısızsa kısa hata metni.
  final String? error;
}

/// Köşe moduna giriş/çıkış, görevler arası geçiş ve tek tıkla tamamlama.
class CornerModeController extends Notifier<CornerModeState> {
  /// Tamamlandı geri bildiriminden sonra sıradaki aktif göreve geçme gecikmesi.
  static const nextDelay = Duration(milliseconds: 900);

  /// Başka aktif görev kalmadıysa tam pencereye dönmeden önceki gecikme.
  static const exitDelay = Duration(milliseconds: 1600);

  Timer? _timer;

  CornerWindowService get _window => ref.read(cornerWindowServiceProvider);

  @override
  CornerModeState build() {
    final window = ref.watch(cornerWindowServiceProvider);
    final minimized = window.onMinimize.listen((_) => _onMinimized());
    // Kapsül görev çubuğundan küçültülüp geri açılırsa ana pencereye dön.
    final restoreRequested = window.onRestoreRequested.listen((_) => exit());
    ref.onDispose(() {
      minimized.cancel();
      restoreRequested.cancel();
      _timer?.cancel();
    });
    // Oturum kapanırsa pencereyi normale döndür.
    ref.listen(currentUidProvider, (_, uid) {
      if (uid == null) exit();
    });
    return const CornerModeState();
  }

  /// Arayüz, pencere görünmez olduktan sonra kapsüle geçer; pencere işlemi başarısız olursa
  /// servis pencereyi normale döndürür ve durum sıfırlanır — kullanıcı yarım bir durumda kalmaz.
  Future<void> enter({bool refresh = true}) async {
    if (!_window.isSupported || state.active) return;
    if (refresh) ref.invalidate(activeTasksProvider);
    _timer?.cancel();
    try {
      await _window.enterCornerMode(
        onHidden: () {
          if (ref.mounted) state = const CornerModeState(active: true);
        },
      );
    } catch (_) {
      if (ref.mounted) state = const CornerModeState();
    }
  }

  Future<void> exit() async {
    _timer?.cancel();
    if (!state.active) return;
    try {
      await _window.exitCornerMode(
        onHidden: () {
          if (ref.mounted) state = const CornerModeState();
        },
      );
    } finally {
      if (ref.mounted && state.active) state = const CornerModeState();
    }
  }

  /// Birden fazla aktif görev varsa sıradakine geçer (sonda başa döner).
  void focusNext() {
    final tasks = ref.read(activeTasksProvider).value ?? const <Task>[];
    final current = focusedTaskOf(tasks, state.focusedTaskId);
    if (!state.active || tasks.length < 2 || current == null || state.completedTitle != null) return;
    final index = tasks.indexWhere((t) => t.id == current.id);
    state = CornerModeState(active: true, focusedTaskId: tasks[(index + 1) % tasks.length].id);
  }

  /// Gösterilen görevi "done" yapar. Kısa geri bildirimden sonra sıradaki aktif göreve geçer;
  /// başka aktif görev kalmadıysa tam pencereye döner.
  Future<void> completeFocused() async {
    final before = ref.read(activeTasksProvider).value ?? const <Task>[];
    final task = focusedTaskOf(before, state.focusedTaskId);
    if (!state.active || task == null || state.completedTitle != null) return;
    final index = before.indexWhere((t) => t.id == task.id);

    _timer?.cancel();
    state = CornerModeState(active: true, focusedTaskId: task.id, completedTitle: task.title);
    try {
      await ref.read(activeTasksProvider.notifier).complete(task);
    } catch (_) {
      if (ref.mounted && state.active) {
        state = CornerModeState(active: true, focusedTaskId: task.id, error: 'Kaydedilemedi');
      }
      return;
    }
    if (!ref.mounted || !state.active) return;

    final remaining = ref.read(activeTasksProvider).value ?? const <Task>[];
    if (remaining.isEmpty) {
      _timer = Timer(exitDelay, exit);
    } else {
      final next = remaining[index.clamp(0, remaining.length - 1)];
      _timer = Timer(nextDelay, () {
        if (state.active) state = CornerModeState(active: true, focusedTaskId: next.id);
      });
    }
  }

  /// Pencere küçültüldüğünde: tercih açıksa ve devam eden görev varsa köşe moduna geç.
  Future<void> _onMinimized() async {
    if (state.active || !ref.read(cornerModeOnMinimizeProvider)) return;
    try {
      final tasks = await ref.read(activeTasksProvider.future);
      if (ref.mounted && tasks.isNotEmpty) await enter(refresh: false);
    } catch (_) {
      // Görevler alınamadıysa pencere küçültülmüş kalır.
    }
  }
}

final cornerModeProvider = NotifierProvider<CornerModeController, CornerModeState>(CornerModeController.new);

/// [id]'li görev; yoksa (ör. az önce tamamlandıysa) listedeki ilk aktif görev.
Task? focusedTaskOf(List<Task> tasks, String? id) {
  if (tasks.isEmpty) return null;
  return tasks.firstWhere((t) => t.id == id, orElse: () => tasks.first);
}

/// Köşe hapında gösterilen aktif görev.
final cornerFocusedTaskProvider = Provider<Task?>(
  (ref) => focusedTaskOf(
    ref.watch(activeTasksProvider).value ?? const <Task>[],
    ref.watch(cornerModeProvider.select((s) => s.focusedTaskId)),
  ),
);

/// Ayarlar: "Aktif görev varken pencereyi küçültünce otomatik köşe moduna geç" (cihazda saklanır).
/// Varsayılan olarak açık.
class CornerModeOnMinimizeController extends Notifier<bool> {
  static const storageKey = 'corner_mode_on_minimize';
  static const defaultValue = true;

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(storageKey) ?? defaultValue;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(storageKey, value);
  }
}

final cornerModeOnMinimizeProvider = NotifierProvider<CornerModeOnMinimizeController, bool>(
  CornerModeOnMinimizeController.new,
);
