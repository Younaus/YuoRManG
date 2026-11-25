import '../../../core/utils/date_labels.dart';
import 'entities/task_draft.dart';

/// Hızlı görev ekleme tarih çipleri.
enum QuickDue {
  today('Bugün'),
  tomorrow('Yarın'),
  none('Tarihsiz');

  const QuickDue(this.label);

  final String label;

  /// Seçime karşılık gelen bitiş tarihi (günün sonu) — tarihsizse `null`.
  DateTime? resolve(DateTime now) => switch (this) {
    QuickDue.today => endOfDay(now),
    QuickDue.tomorrow => endOfDay(DateTime(now.year, now.month, now.day + 1)),
    QuickDue.none => null,
  };
}

/// Hızlı görev taslağı; başlık boşsa `null` (kaydedilmez). Durum: [TaskDraft.initialStatus].
TaskDraft? quickCaptureDraft({
  required String title,
  required QuickDue due,
  String? categoryId,
  required DateTime now,
}) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return null;
  return TaskDraft(title: trimmed, dueDate: due.resolve(now), categoryId: categoryId);
}
