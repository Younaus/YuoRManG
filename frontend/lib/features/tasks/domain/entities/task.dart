import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_status.dart';

part 'task.freezed.dart';

@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    @Default('') String description,
    required TaskStatus status,
    DateTime? dueDate,
    String? categoryId,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  const Task._();

  bool get isDone => status == TaskStatus.done;

  bool isOverdue(DateTime now) => !isDone && dueDate != null && dueDate!.isBefore(now);

  /// Açıklamanın boş olmayan ilk satırı (kart önizlemesi için).
  String? get descriptionPreview {
    for (final line in description.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
