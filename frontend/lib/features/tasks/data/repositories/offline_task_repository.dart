import '../../../../core/network/api_exception.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_status.dart';
import '../../../categories/data/offline/category_offline_cache.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/local_task_query.dart';
import '../../domain/repositories/task_repository.dart';
import '../offline/pending_task_op.dart';
import '../offline/task_offline_cache.dart';

/// Çevrimdışı mod: canlı API'nin önüne yerel önbellek ve işlem kuyruğu koyar.
///
///  - Okuma: başarılı yanıtlar önbelleğe yazılır; ağa ulaşılamazsa sorgu önbellekte yerel olarak çalışır.
///  - Yazma (ekle, durum değiştir, sil): ağa ulaşılamazsa kuyruğa yazılır ve hemen yerel sonuç döner
///    (optimistic). Kuyruk boşalana kadar yeni işlemler de sıraya girer — böylece sunucuya
///    kullanıcının yaptığı sırayla gider.
///  - Düzenleme: yalnızca çevrimdışı oluşturulmuş (henüz gönderilmemiş) görevlerde çevrimdışı yapılabilir.
class OfflineTaskRepository implements TaskRepository {
  OfflineTaskRepository({
    required this.remote,
    required this.cache,
    required this.categories,
    required this.connectivity,
    required this.status,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final TaskRepository remote;
  final TaskOfflineCache cache;
  final CategoryOfflineCache categories;
  final ConnectivityService connectivity;
  final OfflineStatusSink status;
  final DateTime Function() _now;

  static const _offlineEdit = ApiException(
    code: 'OFFLINE',
    message: 'Çevrimdışıyken mevcut görevler düzenlenemez. Bağlantı gelince tekrar deneyin.',
  );

  // --- Okuma -----------------------------------------------------------------

  @override
  Future<TaskPage> list(TaskQuery query) async {
    if (await connectivity.isOnline()) {
      try {
        final page = await remote.list(query);
        status.reportOnline();
        return await _reconcile(query, page);
      } on ApiException catch (e) {
        if (!e.isNetworkError) rethrow;
      }
    }
    status.reportOffline();
    if (!cache.hasSnapshot) {
      throw const ApiException(
        code: ApiException.networkErrorCode,
        message: 'Çevrimdışısınız ve bu cihazda kayıtlı görev yok.',
      );
    }
    // Çevrimdışı sonuçların tamamı ilk sayfada döner.
    if (query.cursor != null) return const TaskPage(items: []);
    return TaskPage(items: applyLocalQuery(cache.readSnapshot().values, query, tree: categories.readTree()));
  }

  /// Sunucu yanıtını önbelleğe işler; henüz gönderilmemiş işlemleri yanıtın üzerine uygular.
  Future<TaskPage> _reconcile(TaskQuery query, TaskPage page) async {
    final tree = categories.readTree();
    final queue = cache.readQueue();
    final snapshot = cache.readSnapshot();
    for (final t in page.items) {
      snapshot[t.id] = t;
    }
    // Filtrenin tam sonucu geldiyse (tek sayfa, aramasız), filtreye uyup yanıtta olmayan görevler
    // başka bir cihazda silinmiştir.
    final complete = query.cursor == null && page.nextCursor == null && (query.search?.trim().isEmpty ?? true);
    if (complete) {
      final ids = {for (final t in page.items) t.id};
      snapshot.removeWhere(
        (id, t) => !isLocalTaskId(id) && !ids.contains(id) && taskMatchesQuery(t, query, tree: tree),
      );
    }
    await cache.writeSnapshot({for (final t in applyPendingOps(snapshot.values.toList(), queue)) t.id: t});

    if (queue.isEmpty) return page;
    final firstPage = query.cursor == null;
    final pending = firstPage ? queue : queue.where((op) => op.kind != PendingTaskOpKind.create).toList();
    final items = applyLocalQuery(applyPendingOps(page.items, pending), query, tree: tree);
    return TaskPage(items: items, nextCursor: page.nextCursor);
  }

  // --- Yazma -----------------------------------------------------------------

  /// Kuyrukta bekleyen işlem varsa yeni işlem de sıraya girer (sunucuya doğru sırayla gitsin).
  bool get _hasPending => cache.readQueue().isNotEmpty;

  @override
  Future<Task> create(TaskDraft draft) async {
    if (!_hasPending && await connectivity.isOnline()) {
      try {
        final task = await remote.create(draft);
        status.reportOnline();
        await _upsert(task);
        return task;
      } on ApiException catch (e) {
        if (!e.isNetworkError) rethrow;
        status.reportOffline();
      }
    }
    final now = _now();
    final local = Task(
      id: '$localTaskIdPrefix${now.microsecondsSinceEpoch}',
      title: draft.title.trim(),
      description: draft.description.trim(),
      status: draft.status,
      dueDate: draft.dueDate,
      categoryId: draft.categoryId,
      completedAt: draft.status == TaskStatus.done ? now : null,
      createdAt: now,
      updatedAt: now,
    );
    await _enqueue(PendingTaskOp.create(local));
    return local;
  }

  @override
  Future<Task> update(String id, TaskDraft draft) async {
    final pendingCreate = cache
        .readQueue()
        .where((op) => op.kind == PendingTaskOpKind.create && op.taskId == id)
        .firstOrNull;
    if (pendingCreate != null) {
      final now = _now();
      final edited = pendingCreate.task!.copyWith(
        title: draft.title.trim(),
        description: draft.description.trim(),
        status: draft.status,
        dueDate: draft.dueDate,
        categoryId: draft.categoryId,
        completedAt: draft.status == TaskStatus.done ? now : null,
        updatedAt: now,
      );
      await _enqueue(PendingTaskOp.create(edited));
      return edited;
    }
    if (_hasPending) throw _offlineEdit; // önce bekleyen işlemler gönderilmeli
    try {
      final task = await remote.update(cache.resolveId(id), draft);
      status.reportOnline();
      await _upsert(task);
      return task;
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      status.reportOffline();
      throw _offlineEdit;
    }
  }

  @override
  Future<Task> setStatus(String id, TaskStatus newStatus) async {
    final resolved = cache.resolveId(id);
    if (!isLocalTaskId(resolved) && !_hasPending && await connectivity.isOnline()) {
      try {
        final task = await remote.setStatus(resolved, newStatus);
        status.reportOnline();
        await _upsert(task);
        return task;
      } on ApiException catch (e) {
        if (!e.isNetworkError) rethrow;
        status.reportOffline();
      }
    }
    final current = cache.readSnapshot()[resolved];
    if (current == null) throw _offlineEdit;
    final now = _now();
    final updated = current.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.done ? now : null,
      updatedAt: now,
    );
    await _enqueue(PendingTaskOp.setStatus(resolved, newStatus));
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final resolved = cache.resolveId(id);
    if (!isLocalTaskId(resolved) && !_hasPending && await connectivity.isOnline()) {
      try {
        await remote.delete(resolved);
        status.reportOnline();
        final snapshot = cache.readSnapshot()..remove(resolved);
        await cache.writeSnapshot(snapshot);
        return;
      } on ApiException catch (e) {
        if (!e.isNetworkError) rethrow;
        status.reportOffline();
      }
    }
    await _enqueue(PendingTaskOp.delete(resolved));
  }

  Future<void> _upsert(Task task) async {
    final snapshot = cache.readSnapshot();
    snapshot[task.id] = task;
    await cache.writeSnapshot(snapshot);
  }

  /// Kuyruğa yazar (birleştirerek), yerel kümeye hemen uygular ve göndermeyi tetikler.
  Future<void> _enqueue(PendingTaskOp op) async {
    final queue = enqueuePendingOp(cache.readQueue(), op);
    await cache.writeQueue(queue);
    final snapshot = applyPendingOps(cache.readSnapshot().values.toList(), [op]);
    await cache.writeSnapshot({for (final t in snapshot) t.id: t});
    status.reportPending(queue.length);
    status.requestFlush();
  }
}
