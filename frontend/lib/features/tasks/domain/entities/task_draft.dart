import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_status.dart';

part 'task_draft.freezed.dart';

/// Görev oluşturma / düzenleme formunun çıktısı.
@freezed
abstract class TaskDraft with _$TaskDraft {
  const factory TaskDraft({
    required String title,
    @Default('') String description,
    @Default(TaskStatus.todo) TaskStatus status,
    DateTime? dueDate,
    String? categoryId,
  }) = _TaskDraft;
}
