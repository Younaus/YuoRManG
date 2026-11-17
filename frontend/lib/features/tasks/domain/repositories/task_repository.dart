import '../entities/task.dart';
import '../entities/task_draft.dart';
import '../entities/task_query.dart';
import '../entities/task_status.dart';

/// Hatalar `ApiException` olarak fırlatılır.
abstract interface class TaskRepository {
  Future<TaskPage> list(TaskQuery query);

  Future<Task> create(TaskDraft draft);

  Future<Task> update(String id, TaskDraft draft);

  Future<Task> setStatus(String id, TaskStatus status);

  Future<void> delete(String id);
}
