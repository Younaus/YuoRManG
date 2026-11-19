import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_status.dart';

part 'task_draft.freezed.dart';

/// Görev oluşturma / düzenleme formunun çıktısı. Yeni görevler varsayılan olarak "Devam ediyor".
@freezed
abstract class TaskDraft with _$TaskDraft {
  const factory TaskDraft({
    required String title,
    @Default('') String description,
    @Default(TaskDraft.initialStatus) TaskStatus status,
    DateTime? dueDate,
    String? categoryId,
  }) = _TaskDraft;

  /// Yeni oluşturulan görevlerin durumu.
  static const initialStatus = TaskStatus.inProgress;
}
