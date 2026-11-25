import '../../tasks/domain/entities/task.dart';

/// Takvim günü anahtarı (yerel saat, gün başı). table_calendar UTC gün de verebilir; yalnızca y/a/g kullanılır.
DateTime calendarDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Görev işaretinin türü — takvimde renkle ayrılır.
enum CalendarMarkerKind {
  /// Tamamlanmamış ve bitiş zamanı geçmiş.
  overdue,

  /// Tamamlanmamış, süresi var.
  open,

  /// Tamamlanmış.
  done,
}

CalendarMarkerKind markerKindOf(Task task, DateTime now) {
  if (task.isDone) return CalendarMarkerKind.done;
  return task.isOverdue(now) ? CalendarMarkerKind.overdue : CalendarMarkerKind.open;
}

/// Bitiş tarihi olan görevleri güne göre gruplar; her gün kendi içinde saate, sonra başlığa göre sıralı.
Map<DateTime, List<Task>> groupTasksByDueDay(Iterable<Task> tasks) {
  final result = <DateTime, List<Task>>{};
  for (final t in tasks) {
    final due = t.dueDate;
    if (due == null) continue;
    (result[calendarDay(due)] ??= []).add(t);
  }
  for (final list in result.values) {
    list.sort((a, b) {
      final byTime = a.dueDate!.compareTo(b.dueDate!);
      return byTime != 0 ? byTime : a.title.compareTo(b.title);
    });
  }
  return result;
}

/// Gün hücresinin altındaki noktalar: önce gecikmiş, sonra açık, sonra tamamlanmış; en fazla [max].
List<CalendarMarkerKind> dayMarkers(List<Task> dayTasks, DateTime now, {int max = 3}) {
  final kinds = dayTasks.map((t) => markerKindOf(t, now)).toList()..sort((a, b) => a.index.compareTo(b.index));
  return kinds.take(max).toList();
}

/// Odaktaki ay için sunucudan çekilecek bitiş tarihi aralığı: ayın 14 gün öncesi ile 14 gün sonrası
/// (aylık görünümdeki komşu ay günleri ve ay sınırını aşan 2 haftalık / haftalık görünümler dahil).
({DateTime from, DateTime to}) calendarFetchRange(DateTime focusedDay) {
  // Gün aritmetiği DateTime kurucusuyla: yaz saati geçişlerinde kayma olmaz.
  return (
    from: DateTime(focusedDay.year, focusedDay.month, 1 - 14),
    to: DateTime(focusedDay.year, focusedDay.month + 1, 1 + 14).subtract(const Duration(milliseconds: 1)),
  );
}
