import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';

part 'task_dto.g.dart';

@JsonSerializable(createToJson: false)
class TaskDto {
  const TaskDto({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.dueDate,
    this.completedAt,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) => _$TaskDtoFromJson(json);

  final String id;
  final String title;
  final String description;
  final String status;
  final String? categoryId;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task toEntity() => Task(
        id: id,
        title: title,
        description: description,
        status: TaskStatus.fromApi(status),
        categoryId: categoryId,
        dueDate: dueDate?.toLocal(),
        completedAt: completedAt?.toLocal(),
        createdAt: createdAt.toLocal(),
        updatedAt: updatedAt.toLocal(),
      );
}

@JsonSerializable(createToJson: false)
class TaskPageDto {
  const TaskPageDto({required this.items, this.nextCursor});

  factory TaskPageDto.fromJson(Map<String, dynamic> json) => _$TaskPageDtoFromJson(json);

  final List<TaskDto> items;
  final String? nextCursor;

  TaskPage toEntity() => TaskPage(items: items.map((t) => t.toEntity()).toList(), nextCursor: nextCursor);
}

/// Form verisini API gövdesine çevirir (tarih UTC ISO 8601).
Map<String, dynamic> taskDraftToJson(TaskDraft d) => {
      'title': d.title.trim(),
      'description': d.description.trim(),
      'status': d.status.apiValue,
      'dueDate': d.dueDate?.toUtc().toIso8601String(),
      'categoryId': d.categoryId,
    };

String? _nonBlank(String? s) {
  final trimmed = s?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Sorgu nesnesini `GET /tasks` parametrelerine çevirir.
Map<String, dynamic> taskQueryToParams(TaskQuery q) => {
      if (q.status != null) 'status': q.status!.apiValue,
      ...switch (q.scope) {
        AllTasksScope() => const <String, dynamic>{},
        UncategorizedScope() => const {'categoryId': 'none'},
        CategoryScope(:final categoryId) => {
            'categoryId': categoryId,
            if (q.includeSubcategories) 'includeSubcategories': 'true',
          },
      },
      'q': ?_nonBlank(q.search),
      'sort': q.sort.apiValue,
      'limit': q.limit,
      'cursor': ?q.cursor,
    };

/// Görevi API yanıtıyla aynı biçimde JSON'a çevirir (çevrimdışı önbellek; [TaskDto.fromJson] ile okunur).
Map<String, dynamic> taskToJson(Task t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'status': t.status.apiValue,
      'categoryId': t.categoryId,
      'dueDate': t.dueDate?.toUtc().toIso8601String(),
      'completedAt': t.completedAt?.toUtc().toIso8601String(),
      'createdAt': t.createdAt.toUtc().toIso8601String(),
      'updatedAt': t.updatedAt.toUtc().toIso8601String(),
    };

Task taskFromJson(Map<String, dynamic> json) => TaskDto.fromJson(json).toEntity();
