import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/domain/reminder_planner.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  final now = DateTime(2026, 11, 25, 10, 30);

  group('reminderTimeFor', () {
    test('saat yoksa (23:59) o gün 09:00; saat varsa tam bitiş zamanında', () {
      expect(reminderTimeFor(task('a', dueDate: DateTime(2026, 11, 26, 23, 59)), now), DateTime(2026, 11, 26, 9));
      expect(reminderTimeFor(task('b', dueDate: DateTime(2026, 11, 25, 14, 30)), now), DateTime(2026, 11, 25, 14, 30));
    });

    test('tamamlanmış, tarihsiz ya da zamanı geçmiş görevlere hatırlatma yok', () {
      expect(reminderTimeFor(task('a', status: TaskStatus.done, dueDate: DateTime(2026, 11, 26, 23, 59)), now), isNull);
      expect(reminderTimeFor(task('b'), now), isNull);
      expect(reminderTimeFor(task('c', dueDate: DateTime(2026, 11, 25, 9)), now), isNull, reason: 'saatli, geçmiş');
      expect(
        reminderTimeFor(task('d', dueDate: DateTime(2026, 11, 25, 23, 59)), now),
        isNull,
        reason: 'bugün, 09:00 geçti',
      );
    });
  });

  test('reminderIdFor: kararlı, pozitif 31 bit, görevler arasında farklı', () {
    expect(reminderIdFor('abc'), reminderIdFor('abc'));
    final ids = {for (var i = 0; i < 1000; i++) reminderIdFor('task-$i')};
    expect(ids.length, 1000);
    expect(ids.every((id) => id >= 0 && id <= 0x7fffffff), isTrue);
  });

  test('planReminders: en yakından uzağa, ufuk dışı hariç, en fazla üst sınır kadar', () {
    final tasks = [
      task('later', title: 'Sonra', dueDate: DateTime(2026, 11, 28, 16, 45)),
      task('soon', title: 'Yakında', dueDate: DateTime(2026, 11, 26, 23, 59)),
      task('far', title: 'Çok uzak', dueDate: DateTime(2027, 2, 1, 23, 59)),
      for (var i = 0; i < maxScheduledReminders + 5; i++) task('bulk$i', dueDate: DateTime(2026, 12, 10, 23, 59)),
    ];
    final plans = planReminders(tasks, now);
    expect(plans.length, maxScheduledReminders);
    expect(plans.first.taskId, 'soon');
    expect(plans.first.body, 'Bugün son gün');
    expect(plans[1].taskId, 'later');
    expect(plans[1].body, 'Bitiş saati: 16:45');
    expect(plans.any((p) => p.taskId == 'far'), isFalse, reason: '30 günlük ufuk dışında');
  });

  test('diffReminders: yalnızca değişenler yeniden kurulur, kalkanlar iptal edilir', () {
    ReminderPlan plan(String id, DateTime at, [String title = 'x']) =>
        ReminderPlan(id: reminderIdFor(id), taskId: id, at: at, title: title, body: 'b');
    final current = {
      for (final p in [
        plan('same', DateTime(2026, 11, 26, 9)),
        plan('moved', DateTime(2026, 11, 27, 9)),
        plan('gone', DateTime(2026, 11, 28, 9)),
      ])
        p.id: p,
    };
    final desired = [
      plan('same', DateTime(2026, 11, 26, 9)),
      plan('moved', DateTime(2026, 11, 29, 9)),
      plan('new', DateTime(2026, 11, 30, 9)),
    ];
    final diff = diffReminders(current, desired);
    expect(diff.cancel, [reminderIdFor('gone')]);
    expect(diff.schedule.map((p) => p.taskId), ['moved', 'new']);
  });

  test('ReminderPlan JSON gidiş-dönüş', () {
    final p = ReminderPlan(id: 7, taskId: 't', at: DateTime(2026, 11, 26, 9), title: 'Başlık', body: 'Gövde');
    expect(ReminderPlan.fromJson(p.toJson()).sameAs(p), isTrue);
  });
}
