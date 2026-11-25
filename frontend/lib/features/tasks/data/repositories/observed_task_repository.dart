import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';

/// Her başarılı yazma işleminden (ekle, düzenle, durum, sil) sonra [onWrite] çağırır —
/// ör. cihaz içi hatırlatmaları görev listesiyle yeniden eşitlemek için.
class ObservedTaskRepository implements TaskRepository {
  ObservedTaskRepository(this._inner, {required this.onWrite});

  final TaskRepository _inner;
  final void Function() onWrite;

  Future<T> _write<T>(Future<T> Function() action) async {
    final result = await action();
    onWrite();
    return result;
  }

  @override
  Future<TaskPage> list(TaskQuery query) => _inner.list(query);

  @override
  Future<Task> create(TaskDraft draft) => _write(() => _inner.create(draft));

  @override
  Future<Task> update(String id, TaskDraft draft) => _write(() => _inner.update(id, draft));

  @override
  Future<Task> setStatus(String id, TaskStatus status) => _write(() => _inner.setStatus(id, status));

  @override
  Future<void> delete(String id) => _write(() => _inner.delete(id));
}
