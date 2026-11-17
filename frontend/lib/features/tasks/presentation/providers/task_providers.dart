import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/datasources/task_remote_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';

part 'task_providers.freezed.dart';

/// Backend'in `includeSubcategories` için kabul ettiği en büyük alt ağaç (Firestore `in` limiti).
const maxSubtreeForInclude = 30;

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(TaskRemoteDataSource(ref.watch(dioProvider))),
);

// ---------------------------------------------------------------------------
// Seçim ve filtreler
// ---------------------------------------------------------------------------

/// Kenar çubuğunda seçili kapsam (tüm görevler / kategorisiz / bir kategori).
class SelectedScopeController extends Notifier<TaskScope> {
  @override
  TaskScope build() {
    ref.watch(currentUidProvider); // kullanıcı değişince sıfırla
    return const TaskScope.all();
  }

  void select(TaskScope scope) => state = scope;
}

final selectedScopeProvider = NotifierProvider<SelectedScopeController, TaskScope>(SelectedScopeController.new);

@freezed
abstract class TaskFilter with _$TaskFilter {
  const factory TaskFilter({
    TaskStatus? status,
    @Default(TaskSort.createdAt) TaskSort sort,
    @Default('') String search,
  }) = _TaskFilter;
}

class TaskFilterController extends Notifier<TaskFilter> {
  @override
  TaskFilter build() {
    ref.watch(currentUidProvider);
    return const TaskFilter();
  }

  void setStatus(TaskStatus? status) => state = state.copyWith(status: status);
  void setSort(TaskSort sort) => state = state.copyWith(sort: sort);
  void setSearch(String search) => state = state.copyWith(search: search);
}

final taskFilterProvider = NotifierProvider<TaskFilterController, TaskFilter>(TaskFilterController.new);

// ---------------------------------------------------------------------------
// Görev listesi
// ---------------------------------------------------------------------------

@freezed
abstract class TaskListState with _$TaskListState {
  const factory TaskListState({
    @Default(<Task>[]) List<Task> items,
    String? nextCursor,
    @Default(false) bool isLoadingMore,
    Object? loadMoreError,
  }) = _TaskListState;

  const TaskListState._();

  bool get hasMore => nextCursor != null;
}

/// Seçili kapsam + durum/sıralama filtresine göre sayfalı görev listesi.
/// Durum değişikliği ve silme iyimser (optimistic) uygulanır, hata olursa geri alınır.
class TaskListController extends AsyncNotifier<TaskListState> {
  late TaskQuery _query;

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<TaskListState> build() async {
    if (ref.watch(currentUidProvider) == null) return const TaskListState();

    final scope = ref.watch(selectedScopeProvider);
    final (status, sort) = ref.watch(taskFilterProvider.select((f) => (f.status, f.sort)));

    var includeSub = false;
    if (scope case CategoryScope(:final categoryId)) {
      final subtree = (await ref.watch(categoryTreeProvider.future)).subtreeIds(categoryId);
      includeSub = subtree.length > 1 && subtree.length <= maxSubtreeForInclude;
    }

    _query = TaskQuery(scope: scope, status: status, sort: sort, includeSubcategories: includeSub);
    final page = await ref.watch(taskRepositoryProvider).list(_query);
    return TaskListState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore || state.isLoading) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, loadMoreError: null));
    try {
      final page = await _repo.list(_query.copyWith(cursor: current.nextCursor));
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      final known = latest.items.map((t) => t.id).toSet();
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...page.items.where((t) => !known.contains(t.id))],
          nextCursor: page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData((state.value ?? current).copyWith(isLoadingMore: false, loadMoreError: e));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Task> create(TaskDraft draft) async {
    final task = await _repo.create(draft);
    if (ref.mounted) await refresh();
    return task;
  }

  Future<Task> edit(Task task, TaskDraft draft) async {
    final updated = await _repo.update(task.id, draft);
    if (ref.mounted) await refresh();
    return updated;
  }

  /// Durumu iyimser şekilde değiştirir; aktif durum filtresine uymayan görev listeden çıkar.
  Future<void> setStatus(Task task, TaskStatus status) async {
    if (task.status == status) return;
    final before = state.value;
    if (before == null) return;

    final optimistic = task.copyWith(status: status, completedAt: status == TaskStatus.done ? DateTime.now() : null);
    _setItems(_applyFilter(before.items.map((t) => t.id == task.id ? optimistic : t)));

    try {
      final saved = await _repo.setStatus(task.id, status);
      if (!ref.mounted) return;
      final items = state.value?.items ?? const <Task>[];
      _setItems(items.map((t) => t.id == saved.id ? saved : t));
    } catch (_) {
      if (ref.mounted) _setItems(before.items);
      rethrow;
    }
  }

  /// "Geri al" akışı için: görevi yalnızca yerelde kaldırır, eski konumunu döner.
  int removeLocal(String id) {
    final items = state.value?.items ?? const <Task>[];
    final index = items.indexWhere((t) => t.id == id);
    if (index >= 0) _setItems([...items]..removeAt(index));
    return index;
  }

  void restoreLocal(Task task, int index) {
    final items = [...?state.value?.items];
    if (items.any((t) => t.id == task.id)) return;
    items.insert(index.clamp(0, items.length), task);
    _setItems(items);
  }

  Future<void> deleteRemote(Task task) => _repo.delete(task.id);

  Iterable<Task> _applyFilter(Iterable<Task> items) {
    final status = _query.status;
    return status == null ? items : items.where((t) => t.status == status);
  }

  void _setItems(Iterable<Task> items) {
    final current = state.value ?? const TaskListState();
    state = AsyncData(current.copyWith(items: items.toList(growable: false)));
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListController, TaskListState>(TaskListController.new);

/// Arama metnine göre (yüklenmiş görevler üzerinde) filtrelenmiş liste.
final visibleTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final query = ref.watch(taskFilterProvider.select((f) => f.search)).trim().toLowerCase();
  return ref.watch(taskListProvider).whenData((s) {
    if (query.isEmpty) return s.items;
    return s.items
        .where((t) => t.title.toLowerCase().contains(query) || t.description.toLowerCase().contains(query))
        .toList(growable: false);
  });
});
