import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_status.dart';
import '../../../../core/offline/offline_store.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/offline/pending_task_op.dart';
import '../../data/offline/task_offline_cache.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/repositories/task_repository.dart';
import 'sync_providers.dart';
import 'task_providers.dart';

/// Çevrimdışı mod durumu (bilgi şeridi için).
@immutable
class OfflineState {
  const OfflineState({this.offline = false, this.pending = 0, this.syncing = false});

  /// Son istek sunucuya ulaşamadı; önbellekteki veriler gösteriliyor.
  final bool offline;

  /// Kuyrukta gönderilmeyi bekleyen işlem sayısı.
  final int pending;

  /// Kuyruk şu an gönderiliyor.
  final bool syncing;

  OfflineState copyWith({bool? offline, int? pending, bool? syncing}) => OfflineState(
    offline: offline ?? this.offline,
    pending: pending ?? this.pending,
    syncing: syncing ?? this.syncing,
  );
}

/// Kuyruk gönderiminin sonucu.
@immutable
class FlushResult {
  const FlushResult({this.sent = 0, this.dropped = 0, this.remaining = 0});

  final int sent;

  /// Sunucunun kalıcı olarak reddettiği (ör. silinmiş görev) ve kuyruktan atılan işlemler.
  final int dropped;
  final int remaining;
}

/// Çevrimdışı işlem kuyruğunu canlı API'ye sırayla gönderir ve çevrimdışı durumunu tutar.
///
/// Gönderim: `syncProvider` her yenilemeden önce, bağlantı geri geldiğinde ve çevrimdışıyken
/// [retryInterval] aralıklarla (yenileme üzerinden) tetiklenir.
class OfflineSyncController extends Notifier<OfflineState> implements OfflineStatusSink {
  static const retryInterval = Duration(seconds: 30);

  Timer? _retry;
  Future<FlushResult>? _flushing;
  bool _flushRequested = false;

  TaskOfflineCache? get _cache {
    final uid = ref.read(currentUidProvider);
    return uid == null ? null : TaskOfflineCache(ref.read(offlineStoreProvider), uid);
  }

  @override
  OfflineState build() {
    final uid = ref.watch(currentUidProvider);
    final connectivity = ref.watch(connectivityServiceProvider);
    final changes = connectivity.onlineChanges.listen((online) {
      if (!online) return reportOffline();
      // Bağlantı geri geldi: kuyruğu gönder, listeleri yenile.
      if (state.offline || state.pending > 0) ref.read(syncProvider.notifier).refreshAll();
    });
    ref.onDispose(() {
      changes.cancel();
      _retry?.cancel();
      _retry = null;
    });
    final pending = uid == null ? 0 : TaskOfflineCache(ref.read(offlineStoreProvider), uid).readQueue().length;
    return OfflineState(pending: pending);
  }

  // --- OfflineStatusSink -----------------------------------------------------

  @override
  void reportOnline() {
    _retry?.cancel();
    _retry = null;
    if (state.offline) state = state.copyWith(offline: false);
  }

  @override
  void reportOffline() {
    _retry ??= Timer.periodic(retryInterval, (_) => ref.read(syncProvider.notifier).refreshAll());
    if (!state.offline) state = state.copyWith(offline: true);
  }

  @override
  void reportPending(int count) {
    if (state.pending != count) state = state.copyWith(pending: count);
  }

  @override
  void requestFlush() {
    if (_flushRequested) return;
    _flushRequested = true;
    // Gönder + listeleri yenile (yerel kimlikler sunucu kimlikleriyle değişsin).
    scheduleMicrotask(() {
      _flushRequested = false;
      if (ref.mounted && !state.offline) ref.read(syncProvider.notifier).refreshAll();
    });
  }

  // --- Gönderim --------------------------------------------------------------

  /// Kuyruktaki işlemleri sırayla gönderir. Ağ hatasında durur (kalanlar korunur); sunucu bir
  /// işlemi kalıcı olarak reddederse (ör. 404/400) o işlem atılır ve sıradakine geçilir.
  Future<FlushResult> flush() => _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<FlushResult> _flush() async {
    final cache = _cache;
    if (cache == null || cache.readQueue().isEmpty) return const FlushResult();
    if (!await ref.read(connectivityServiceProvider).isOnline()) {
      reportOffline();
      return FlushResult(remaining: cache.readQueue().length);
    }

    final remote = ref.read(taskRemoteRepositoryProvider);
    state = state.copyWith(syncing: true);
    var sent = 0;
    var dropped = 0;
    try {
      while (true) {
        final queue = cache.readQueue();
        if (queue.isEmpty) break;
        final op = queue.first;
        try {
          await _send(op, cache, remote);
          sent++;
          reportOnline();
        } on ApiException catch (e) {
          if (e.isNetworkError) {
            reportOffline();
            break;
          }
          final alreadyDeleted = op.kind == PendingTaskOpKind.delete && e.isNotFound;
          if (!alreadyDeleted) {
            dropped++;
            debugPrint('[offline] işlem sunucu tarafından reddedildi, atlanıyor: $op → $e');
          }
        }
        // Gönderim sürerken kuyruk değişmiş olabilir: işlenen kaydı kimliğiyle çıkar.
        final latest = cache.readQueue();
        final index = latest.indexWhere((q) => q.kind == op.kind && q.taskId == op.taskId);
        if (index >= 0) await cache.writeQueue([...latest]..removeAt(index));
      }
    } finally {
      final remaining = cache.readQueue().length;
      if (ref.mounted) state = state.copyWith(syncing: false, pending: remaining);
    }
    return FlushResult(sent: sent, dropped: dropped, remaining: cache.readQueue().length);
  }

  Future<void> _send(PendingTaskOp op, TaskOfflineCache cache, TaskRepository remote) async {
    switch (op.kind) {
      case PendingTaskOpKind.create:
        final local = op.task!;
        final created = await remote.create(
          TaskDraft(
            title: local.title,
            description: local.description,
            status: local.status,
            dueDate: local.dueDate,
            categoryId: local.categoryId,
          ),
        );
        await cache.rememberServerId(local.id, created.id);
        final snapshot = cache.readSnapshot()
          ..remove(local.id)
          ..[created.id] = created;
        await cache.writeSnapshot(snapshot);
      case PendingTaskOpKind.setStatus:
        final saved = await remote.setStatus(op.taskId, op.status!);
        final snapshot = cache.readSnapshot()..[saved.id] = saved;
        await cache.writeSnapshot(snapshot);
      case PendingTaskOpKind.delete:
        await remote.delete(op.taskId);
    }
  }
}

final offlineSyncProvider = NotifierProvider<OfflineSyncController, OfflineState>(OfflineSyncController.new);

/// Oturum kapatılınca (veya hesap değişince) önceki kullanıcının önbelleğini ve kuyruğunu siler.
final offlineSessionGuardProvider = Provider<void>((ref) {
  ref.listen(currentUidProvider, (previous, next) {
    if (previous != null && previous != next) ref.read(offlineStoreProvider).clearUser(previous);
  });
});
