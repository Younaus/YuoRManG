import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/reminder_service.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/reminder_planner.dart';
import 'task_providers.dart';

@immutable
class ReminderState {
  const ReminderState({this.enabled = true, this.scheduled = 0});

  /// Ayarlar: "Hatırlatmalar" açık mı (varsayılan açık; izin yoksa bildirim kurulmaz).
  final bool enabled;

  /// Şu an zamanlanmış hatırlatma sayısı.
  final int scheduled;
}

/// Cihaz içi görev hatırlatmalarını görev listesiyle eşitler (sunucuya ek istek yok — listeler
/// zaten çekiliyor; çevrimdışıyken önbellekten).
///
/// Tetikleyiciler: görev yazma işlemleri (ekle/düzenle/tamamla/sil — kısa gecikmeyle birleştirilir),
/// `syncProvider` yenilemesi (diğer cihazlardan gelen görevler) ve oturum açılışı.
class ReminderController extends Notifier<ReminderState> {
  static const enabledKey = 'reminders_enabled';
  static const permissionAskedKey = 'reminders_permission_asked';
  static const scheduledKey = 'reminders.v1.scheduled';

  /// Art arda değişiklikler tek eşitlemede birleşir.
  static const debounce = Duration(milliseconds: 700);

  Timer? _debounce;
  Future<void>? _running;
  bool _again = false;

  ReminderService get _service => ref.read(reminderServiceProvider);

  @override
  ReminderState build() {
    ref.watch(currentUidProvider);
    ref.onDispose(() => _debounce?.cancel());
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReminderState(enabled: prefs.getBool(enabledKey) ?? true, scheduled: _readScheduled().length);
  }

  Map<int, ReminderPlan> _readScheduled() {
    final raw = ref.read(sharedPreferencesProvider).getString(scheduledKey);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final plans = list.map((e) => ReminderPlan.fromJson(e as Map<String, dynamic>));
      return {for (final p in plans) p.id: p};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeScheduled(Map<int, ReminderPlan> plans) => ref
      .read(sharedPreferencesProvider)
      .setString(scheduledKey, jsonEncode(plans.values.map((p) => p.toJson()).toList()));

  /// Kısa gecikmeyle eşitle (art arda yazma işlemleri birleşir).
  void requestSync() {
    if (!_service.isSupported) return;
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      if (ref.mounted) sync();
    });
  }

  /// Zamanlanmış bildirimleri güncel görev listesine göre kurar / günceller / iptal eder.
  Future<void> sync() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _sync().whenComplete(() {
      _running = null;
      if (_again && ref.mounted) {
        _again = false;
        sync();
      }
    });
  }

  Future<void> _sync() async {
    final service = _service;
    if (!service.isSupported) return;
    final current = _readScheduled();

    var desired = const <ReminderPlan>[];
    if (ref.read(currentUidProvider) != null && state.enabled && await service.hasPermission()) {
      final now = DateTime.now();
      final tasks = <Task>[];
      try {
        final repo = ref.read(taskRepositoryProvider);
        String? cursor;
        for (var page = 0; page < 3; page++) {
          final result = await repo.list(
            TaskQuery(
              dueFrom: DateTime(now.year, now.month, now.day),
              dueTo: now.add(reminderHorizon),
              limit: 100,
              cursor: cursor,
            ),
          );
          tasks.addAll(result.items);
          cursor = result.nextCursor;
          if (cursor == null) break;
        }
      } catch (e) {
        debugPrint('[reminders] görevler alınamadı, mevcut hatırlatmalar korunuyor: $e');
        return;
      }
      if (!ref.mounted) return;
      desired = planReminders(tasks, now);
    }

    final diff = diffReminders(current, desired);
    final next = Map<int, ReminderPlan>.of(current);
    for (final id in diff.cancel) {
      await service.cancel(id);
      next.remove(id);
    }
    for (final plan in diff.schedule) {
      try {
        await service.schedule(plan.id, title: plan.title, body: plan.body, at: plan.at);
        next[plan.id] = plan;
      } catch (e) {
        debugPrint('[reminders] zamanlanamadı: ${plan.taskId} → $e');
        next.remove(plan.id);
      }
    }
    await _writeScheduled(next);
    if (ref.mounted) state = ReminderState(enabled: state.enabled, scheduled: next.length);
  }

  /// Ayarlar anahtarı. Açarken Android 13+ bildirim izni istenir; verilmezse `false` döner ve kapalı kalır.
  Future<bool> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (enabled) {
      final granted = await _service.hasPermission() || await _service.requestPermission();
      await prefs.setBool(permissionAskedKey, true);
      if (!granted) {
        await prefs.setBool(enabledKey, false);
        state = ReminderState(enabled: false, scheduled: state.scheduled);
        return false;
      }
    }
    await prefs.setBool(enabledKey, enabled);
    state = ReminderState(enabled: enabled, scheduled: state.scheduled);
    if (enabled) {
      await sync();
    } else {
      await clearAll();
    }
    return true;
  }

  /// Zamanlanmış tüm hatırlatmaları iptal eder (kapatınca, oturum kapanınca).
  Future<void> clearAll() async {
    await _service.cancelAll();
    await _writeScheduled({});
    if (ref.mounted) state = ReminderState(enabled: state.enabled, scheduled: 0);
  }
}

final reminderProvider = NotifierProvider<ReminderController, ReminderState>(ReminderController.new);

/// Bildirim izni var mı (Ayarlar'daki uyarı için; izin isteğinden sonra yenilenir).
final reminderPermissionProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderServiceProvider).hasPermission(),
);

/// Oturum kapanınca (veya hesap değişince) zamanlanmış hatırlatmaları temizler.
final reminderSessionGuardProvider = Provider<void>((ref) {
  ref.listen(currentUidProvider, (previous, next) {
    if (previous != null && previous != next) ref.read(reminderProvider.notifier).clearAll();
  });
});
