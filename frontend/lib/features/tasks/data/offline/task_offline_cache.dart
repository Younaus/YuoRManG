import '../../../../core/offline/offline_store.dart';
import '../../domain/entities/task.dart';
import '../models/task_dto.dart';
import 'pending_task_op.dart';

/// Kullanıcı bazlı yerel görev kümesi (sunucudan görülen + çevrimdışı değişiklikler) ve işlem kuyruğu.
class TaskOfflineCache {
  TaskOfflineCache(this._store, this.uid);

  final OfflineStore _store;
  final String uid;

  static const _tasks = 'tasks';
  static const _queue = 'queue';
  static const _idMap = 'idmap';

  bool get hasSnapshot => _store.has(uid, _tasks);

  Map<String, Task> readSnapshot() {
    final raw = _store.read(uid, _tasks);
    if (raw is! Map) return {};
    final result = <String, Task>{};
    for (final entry in raw.entries) {
      try {
        result[entry.key as String] = taskFromJson(entry.value as Map<String, dynamic>);
      } catch (_) {}
    }
    return result;
  }

  Future<void> writeSnapshot(Map<String, Task> tasks) =>
      _store.write(uid, _tasks, {for (final e in tasks.entries) e.key: taskToJson(e.value)});

  List<PendingTaskOp> readQueue() {
    final raw = _store.read(uid, _queue);
    if (raw is! List) return const [];
    final result = <PendingTaskOp>[];
    for (final item in raw) {
      try {
        result.add(PendingTaskOp.fromJson(item as Map<String, dynamic>));
      } catch (_) {}
    }
    return result;
  }

  Future<void> writeQueue(List<PendingTaskOp> queue) =>
      _store.write(uid, _queue, queue.map((op) => op.toJson()).toList());

  /// Gönderilmiş yerel görevin sunucudaki kimliği (arayüz henüz yenilenmemişken gelen işlemler için).
  String resolveId(String id) {
    if (!isLocalTaskId(id)) return id;
    final raw = _store.read(uid, _idMap);
    return raw is Map && raw[id] is String ? raw[id] as String : id;
  }

  Future<void> rememberServerId(String localId, String serverId) {
    final raw = _store.read(uid, _idMap);
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    map[localId] = serverId;
    return _store.write(uid, _idMap, map);
  }
}
