import 'package:intl/intl.dart';

int _dayIndex(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

/// İki tarih arasındaki takvim günü farkı (yaz saati geçişlerinden etkilenmez).
int calendarDaysBetween(DateTime from, DateTime to) => _dayIndex(to) - _dayIndex(from);

/// "Bugün", "Yarın", "Dün", "18 Kas", "3 Oca 2027"
String relativeDayLabel(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return switch (calendarDaysBetween(today, date)) {
    0 => 'Bugün',
    1 => 'Yarın',
    -1 => 'Dün',
    _ when date.year == today.year => DateFormat('d MMM', 'tr_TR').format(date),
    _ => DateFormat('d MMM y', 'tr_TR').format(date),
  };
}

String longDateLabel(DateTime date) => DateFormat('d MMMM y, EEEE', 'tr_TR').format(date);

/// Yalnızca tarih seçildiğinde son tarih o günün sonu kabul edilir.
DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59);
