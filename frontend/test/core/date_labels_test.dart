import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yourmang/core/utils/date_labels.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  final now = DateTime(2026, 11, 17, 15, 30);

  test('göreli gün etiketleri', () {
    expect(relativeDayLabel(DateTime(2026, 11, 17, 23, 59), now: now), 'Bugün');
    expect(relativeDayLabel(DateTime(2026, 11, 18), now: now), 'Yarın');
    expect(relativeDayLabel(DateTime(2026, 11, 16), now: now), 'Dün');
    expect(relativeDayLabel(DateTime(2026, 12, 3), now: now), '3 Ara');
    expect(relativeDayLabel(DateTime(2027, 1, 5), now: now), '5 Oca 2027');
  });

  test('takvim günü farkı yaz saati geçişinden etkilenmez', () {
    expect(calendarDaysBetween(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 29, 1)), 1);
    expect(calendarDaysBetween(DateTime(2026, 10, 24, 1), DateTime(2026, 10, 25, 23)), 1);
  });

  test('endOfDay', () => expect(endOfDay(DateTime(2026, 5, 1, 8)), DateTime(2026, 5, 1, 23, 59)));
}
