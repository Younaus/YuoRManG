import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../calendar/domain/calendar_grouping.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_query.dart';
import '../../domain/entities/task_status.dart';
import 'task_providers.dart';

/// Takvimde odaktaki gün (sayfa değişince güncellenir).
class CalendarFocusController extends Notifier<DateTime> {
  @override
  DateTime build() {
    ref.watch(currentUidProvider);
    return calendarDay(DateTime.now());
  }

  void focus(DateTime day) => state = calendarDay(day);
}

final calendarFocusedDayProvider = NotifierProvider<CalendarFocusController, DateTime>(CalendarFocusController.new);

/// Takvimde seçili gün (altındaki / sağ paneldeki görev listesi).
class CalendarSelectionController extends Notifier<DateTime> {
  @override
  DateTime build() {
    ref.watch(currentUidProvider);
    return calendarDay(DateTime.now());
  }

  void select(DateTime day) => state = calendarDay(day);
}

final calendarSelectedDayProvider = NotifierProvider<CalendarSelectionController, DateTime>(
  CalendarSelectionController.new,
);

class CalendarFormatController extends Notifier<CalendarFormat> {
  @override
  CalendarFormat build() => CalendarFormat.month;

  void set(CalendarFormat format) => state = format;
}

final calendarFormatProvider = NotifierProvider<CalendarFormatController, CalendarFormat>(CalendarFormatController.new);

/// Odaktaki ay: yalnızca ay değişince sunucudan yeniden çekilir.
final calendarMonthProvider = Provider<DateTime>((ref) {
  final focused = ref.watch(calendarFocusedDayProvider);
  return DateTime(focused.year, focused.month);
});

/// Odaktaki ayın (±14 gün) bitiş tarihli görevleri — kapsam ve filtrelerden bağımsız.
/// Depo çevrimdışı katmanlı olduğu için internet yokken önbellekten gelir.
class CalendarTasksController extends AsyncNotifier<List<Task>> {
  /// Bir ayda en fazla bu kadar sayfa (100'er) çekilir.
  static const maxPages = 10;

  @override
  Future<List<Task>> build() async {
    if (ref.watch(currentUidProvider) == null) return const [];
    final range = calendarFetchRange(ref.watch(calendarMonthProvider));
    final repo = ref.watch(taskRepositoryProvider);
    final items = <Task>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final result = await repo.list(TaskQuery(dueFrom: range.from, dueTo: range.to, limit: 100, cursor: cursor));
      items.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return items;
  }

  /// İyimser durum değişikliği; görev listesi ve aktif görevler de güncellenir. Hata olursa geri alınır.
  Future<void> setStatus(Task task, TaskStatus status) async {
    final before = state.value;
    if (before == null || task.status == status) return;
    final optimistic = task.copyWith(status: status, completedAt: status == TaskStatus.done ? DateTime.now() : null);
    state = AsyncData([for (final t in before) t.id == task.id ? optimistic : t]);
    try {
      final saved = await ref.read(taskRepositoryProvider).setStatus(task.id, status);
      if (!ref.mounted) return;
      state = AsyncData([for (final t in state.value ?? before) t.id == saved.id ? saved : t]);
      if (ref.exists(taskListProvider)) ref.read(taskListProvider.notifier).syncLocal(saved);
      ref.invalidate(activeTasksProvider);
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }

  /// Görevi siler (çevrimdışıyken kuyruğa yazılır); görev listesi yenilenir.
  Future<void> delete(Task task) async {
    final before = state.value ?? const <Task>[];
    state = AsyncData([
      for (final t in before)
        if (t.id != task.id) t,
    ]);
    try {
      await ref.read(taskRepositoryProvider).delete(task.id);
      if (!ref.mounted) return;
      if (ref.exists(taskListProvider)) ref.read(taskListProvider.notifier).removeLocal(task.id);
      ref.invalidate(activeTasksProvider);
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}

final calendarTasksProvider = AsyncNotifierProvider<CalendarTasksController, List<Task>>(CalendarTasksController.new);

/// Güne göre gruplanmış takvim görevleri.
final calendarTasksByDayProvider = Provider<Map<DateTime, List<Task>>>(
  (ref) => groupTasksByDueDay(ref.watch(calendarTasksProvider).value ?? const []),
);
