import 'package:intl/intl.dart';

import 'entities/task.dart';

/// Saati belirtilmemiş (yalnızca tarih) görevlerin hatırlatma saati.
const reminderMorningHour = 9;

/// Bu kadar ileriye kadar hatırlatma kurulur (sonrakiler sonraki senkronizasyonlarda).
const reminderHorizon = Duration(days: 30);

/// Aynı anda en fazla bu kadar zamanlanmış bildirim (en yakın olanlar).
const maxScheduledReminders = 60;

/// Form yalnızca tarih seçildiğinde günü 23:59'a ayarlar → "saat yok" kabul edilir.
bool isDateOnlyDue(DateTime due) => due.hour == 23 && due.minute == 59;

/// Hatırlatma anı: saat belirtilmişse bitiş zamanında, yoksa o gün 09:00'da.
/// Tamamlanmış, tarihsiz ya da zamanı geçmiş görevler için `null`.
DateTime? reminderTimeFor(Task task, DateTime now) {
  final due = task.dueDate;
  if (task.isDone || due == null) return null;
  final at = isDateOnlyDue(due) ? DateTime(due.year, due.month, due.day, reminderMorningHour) : due;
  return at.isAfter(now) ? at : null;
}

/// Görev kimliğinden kararlı, pozitif 31 bit bildirim kimliği (FNV-1a).
int reminderIdFor(String taskId) {
  var hash = 0x811c9dc5;
  for (final unit in taskId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// Zamanlanması gereken tek bir hatırlatma.
class ReminderPlan {
  const ReminderPlan({
    required this.id,
    required this.taskId,
    required this.at,
    required this.title,
    required this.body,
  });

  factory ReminderPlan.fromJson(Map<String, dynamic> json) => ReminderPlan(
    id: json['id'] as int,
    taskId: json['taskId'] as String,
    at: DateTime.parse(json['at'] as String).toLocal(),
    title: json['title'] as String,
    body: json['body'] as String,
  );

  final int id;
  final String taskId;
  final DateTime at;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'at': at.toUtc().toIso8601String(),
    'title': title,
    'body': body,
  };

  /// Bildirimi yeniden kurmayı gerektiren bir fark var mı.
  bool sameAs(ReminderPlan other) =>
      id == other.id && at.isAtSameMomentAs(other.at) && title == other.title && body == other.body;
}

/// Görevlerden istenen hatırlatma listesi: en yakından uzağa, ufuk ve üst sınırla.
List<ReminderPlan> planReminders(Iterable<Task> tasks, DateTime now) {
  final plans = <ReminderPlan>[];
  for (final task in tasks) {
    final at = reminderTimeFor(task, now);
    if (at == null || at.isAfter(now.add(reminderHorizon))) continue;
    plans.add(
      ReminderPlan(
        id: reminderIdFor(task.id),
        taskId: task.id,
        at: at,
        title: task.title,
        body: isDateOnlyDue(task.dueDate!)
            ? 'Bugün son gün'
            : 'Bitiş saati: ${DateFormat('HH:mm', 'tr_TR').format(task.dueDate!)}',
      ),
    );
  }
  plans.sort((a, b) => a.at.compareTo(b.at));
  return plans.take(maxScheduledReminders).toList();
}

/// Mevcut zamanlanmış hatırlatmalardan istenene geçmek için yapılacaklar.
({List<int> cancel, List<ReminderPlan> schedule}) diffReminders(
  Map<int, ReminderPlan> current,
  List<ReminderPlan> desired,
) {
  final desiredById = {for (final p in desired) p.id: p};
  return (
    cancel: [
      for (final id in current.keys)
        if (!desiredById.containsKey(id)) id,
    ],
    schedule: [
      for (final p in desired)
        if (!(current[p.id]?.sameAs(p) ?? false)) p,
    ],
  );
}
