import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import 'calendar_providers.dart';
import 'corner_mode_providers.dart';
import 'offline_sync_providers.dart';
import 'reminder_providers.dart';
import 'task_providers.dart';

/// Yenileme durumu (masaüstü yenile düğmesindeki gösterge için).
@immutable
class SyncState {
  const SyncState({this.refreshing = false, this.lastRefreshAt});

  final bool refreshing;

  /// Son yenilemenin (veya oturumdaki ilk yüklemenin) başladığı an.
  final DateTime? lastRefreshAt;
}

/// Test için değiştirilebilir saat.
final syncClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Kategorileri ve görevleri **birlikte** sunucudan yeniden çeker.
///
/// Veriler canlı dinlenmez (her şey REST API'den gelir); başka bir cihazda yapılan
/// değişiklikler aşağı çekip yenileme, yenile düğmesi / F5 ya da uygulama öne geldiğinde görünür.
class SyncController extends Notifier<SyncState> {
  /// Öne gelme kaynaklı yenilemeler arasında en az bu kadar süre olur.
  static const resumeCooldown = Duration(seconds: 5);

  Future<bool>? _inFlight;

  DateTime _now() => ref.read(syncClockProvider)();

  @override
  SyncState build() {
    // Oturum açılınca veriler zaten yeni yüklenir: hemen ardından gelen "öne gelme" yenilemesi gereksiz.
    ref.watch(currentUidProvider);
    return SyncState(lastRefreshAt: _now());
  }

  /// Kullanıcı tetiklemeli (aşağı çek, yenile düğmesi, F5): her zaman yeniler.
  /// Süren bir yenileme varsa onu bekler. Hepsi başarılıysa `true`.
  Future<bool> refreshAll() => _inFlight ?? _run();

  /// Uygulama öne geldiğinde: son yenilemeden bu yana [resumeCooldown] geçmediyse veya köşe
  /// modundaysa (kapsüldeki tamamlama ile yarışmasın) atlanır.
  Future<bool> refreshOnResume() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (ref.read(cornerModeProvider).active) return Future.value(true);
    final last = state.lastRefreshAt;
    if (last != null && _now().difference(last) < resumeCooldown) return Future.value(true);
    return _run();
  }

  Future<bool> _run() {
    if (ref.read(currentUidProvider) == null) return Future.value(true);
    state = SyncState(refreshing: true, lastRefreshAt: _now());
    Future<bool> ok(Future<Object?> f) => f.then((_) => true, onError: (Object _) => false);

    final run = () async {
      try {
        // Önce çevrimdışı yapılan değişiklikleri sırayla gönder, sonra güncel listeyi çek.
        try {
          await ref.read(offlineSyncProvider.notifier).flush();
        } catch (_) {}
        ref.invalidate(categoryTreeProvider);
        ref.invalidate(activeTasksProvider);
        ref.invalidate(calendarTasksProvider);
        final results = await Future.wait([
          ok(ref.read(categoryTreeProvider.future)),
          ok(ref.read(taskListProvider.notifier).refresh()),
        ]);
        // Diğer cihazlardan gelen görevler için hatırlatmaları güncelle.
        ref.read(reminderProvider.notifier).requestSync();
        return results.every((r) => r);
      } finally {
        _inFlight = null;
        if (ref.mounted) state = SyncState(lastRefreshAt: state.lastRefreshAt);
      }
    }();
    return _inFlight = run;
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
