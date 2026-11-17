import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_dto.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remote);

  final TaskRemoteDataSource _remote;

  @override
  Future<TaskPage> list(TaskQuery query) async => (await _remote.list(taskQueryToParams(query))).toEntity();

  @override
  Future<Task> create(TaskDraft draft) async => (await _remote.create(taskDraftToJson(draft))).toEntity();

  @override
  Future<Task> update(String id, TaskDraft draft) async =>
      (await _remote.update(id, taskDraftToJson(draft))).toEntity();

  @override
  Future<Task> setStatus(String id, TaskStatus status) async =>
      (await _remote.update(id, {'status': status.apiValue})).toEntity();

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
