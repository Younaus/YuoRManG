import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/features/calendar/domain/calendar_grouping.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 12);

  test('calendarDay: yerel ve UTC gün aynı anahtara düşer', () {
    expect(calendarDay(DateTime(2026, 11, 25, 23, 59)), DateTime(2026, 11, 25));
    expect(calendarDay(DateTime.utc(2026, 11, 25)), DateTime(2026, 11, 25));
  });

  test('groupTasksByDueDay: tarihsizler atlanır, gün içinde saate sonra başlığa göre sıralanır', () {
    final grouped = groupTasksByDueDay([
      task('a', title: 'Öğleden sonra', dueDate: DateTime(2026, 11, 25, 15)),
      task('b', title: 'Sabah', dueDate: DateTime(2026, 11, 25, 9)),
      task('c', title: 'Akşam B', dueDate: DateTime(2026, 11, 25, 23, 59)),
      task('d', title: 'Akşam A', dueDate: DateTime(2026, 11, 25, 23, 59)),
      task('e', title: 'Ertesi gün', dueDate: DateTime(2026, 11, 26, 23, 59)),
      task('f', title: 'Tarihsiz'),
    ]);
    expect(grouped.keys, [DateTime(2026, 11, 25), DateTime(2026, 11, 26)]);
    expect(grouped[DateTime(2026, 11, 25)]!.map((t) => t.id), ['b', 'a', 'd', 'c']);
  });

  test('işaret türleri: gecikmiş > açık > tamamlanmış; en fazla 3', () {
    final day = [
      task('done', status: TaskStatus.done, dueDate: DateTime(2026, 11, 25, 9)),
      task('open', dueDate: DateTime(2026, 11, 25, 23, 59)),
      task('late', status: TaskStatus.inProgress, dueDate: DateTime(2026, 11, 25, 10)),
      task('open2', dueDate: DateTime(2026, 11, 25, 22)),
    ];
    expect(markerKindOf(day[0], now), CalendarMarkerKind.done);
    expect(markerKindOf(day[1], now), CalendarMarkerKind.open);
    expect(markerKindOf(day[2], now), CalendarMarkerKind.overdue);
    expect(dayMarkers(day, now), [CalendarMarkerKind.overdue, CalendarMarkerKind.open, CalendarMarkerKind.open]);
  });

  test('calendarFetchRange: ay ± 14 gün, yıl sınırında da doğru', () {
    final nov = calendarFetchRange(DateTime(2026, 11, 25));
    expect(nov.from, DateTime(2026, 10, 18));
    expect(nov.to, DateTime(2026, 12, 14, 23, 59, 59, 999));

    final jan = calendarFetchRange(DateTime(2027, 1, 3));
    expect(jan.from, DateTime(2026, 12, 18));
    expect(jan.to, DateTime(2027, 2, 14, 23, 59, 59, 999));
  });
}
