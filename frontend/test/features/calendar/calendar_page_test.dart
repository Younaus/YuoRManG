import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:yourmang/core/layout/app_sidebar.dart';
import 'package:yourmang/core/offline/connectivity_service.dart';
import 'package:yourmang/core/utils/date_labels.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/widgets/task_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_offline.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');
const _phone = Size(390, 900);
const _desktop = Size(1280, 860);

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Ay görünümünde tek görünen bir gün (komşu ay günleriyle karışmasın): ayın 15–21'i.
  final other = DateTime(now.year, now.month, now.day == 18 ? 17 : 18);
  String id(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  // "Diğer gün" bugünden önceyse açık görevi gecikmiş sayılır.
  final otherOpen = other.isBefore(today) ? 'overdue' : 'open';

  late FakeCategoryRepository categories;
  late FakeTaskRepository tasks;

  List<Task> calendarTasks() => [
    task('late', title: 'Gecikmiş rapor', status: TaskStatus.inProgress, dueDate: today, ageMinutes: 1),
    task('open', title: 'Akşam toplantısı', dueDate: endOfDay(today), ageMinutes: 2),
    task('done', title: 'Biten iş', status: TaskStatus.done, dueDate: endOfDay(other), ageMinutes: 3),
    task('o2', title: 'Diğer gün görevi', dueDate: endOfDay(other), ageMinutes: 4),
    task('nodue', title: 'Tarihsiz not', ageMinutes: 5),
  ];

  setUp(() {
    categories = FakeCategoryRepository(sampleCategories());
    tasks = FakeTaskRepository(tasks: calendarTasks(), categories: categories);
  });

  Future<void> openCalendarOnPhone(WidgetTester tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(initialUser: _user),
      tasks: tasks,
      categories: categories,
      size: _phone,
    );
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Takvim')));
    await tester.pumpAndSettle();
  }

  Finder dayCell(DateTime d) =>
      find.descendant(of: find.byKey(const Key('calendar.table')), matching: find.text('${d.day}'));
  Finder inPanel(String text) =>
      find.descendant(of: find.byKey(const Key('calendar.dayTasks')), matching: find.text(text));

  testWidgets('mobil: alt çubukta Takvim; görevli günlerde durumlarına göre işaretler', (tester) async {
    await openCalendarOnPhone(tester);
    expect(find.byKey(const Key('calendar.table')), findsOneWidget);

    // Bugün: gün başında biten (gecikmiş) + gün sonunda biten (açık).
    expect(find.byKey(Key('calendar.marker.${id(today)}.0.overdue')), findsOneWidget);
    expect(find.byKey(Key('calendar.marker.${id(today)}.1.open')), findsOneWidget);
    // Diğer gün: açık önce, tamamlanmış sonra.
    expect(find.byKey(Key('calendar.marker.${id(other)}.0.$otherOpen')), findsOneWidget);
    expect(find.byKey(Key('calendar.marker.${id(other)}.1.done')), findsOneWidget);

    // Varsayılan seçili gün: bugün. Tarihsiz görev takvimde yok.
    expect(inPanel('Gecikmiş rapor'), findsOneWidget);
    expect(inPanel('Akşam toplantısı'), findsOneWidget);
    expect(find.text('Tarihsiz not'), findsNothing);
  });

  testWidgets('güne dokununca o günün görevleri listelenir; listeden tamamlanabilir', (tester) async {
    await openCalendarOnPhone(tester);
    await tester.tap(dayCell(other));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar.dayTitle')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('calendar.dayTitle'))).data,
      DateFormat('d MMMM, EEEE', 'tr_TR').format(other),
    );
    expect(inPanel('Diğer gün görevi'), findsOneWidget);
    expect(inPanel('Biten iş'), findsOneWidget);
    expect(inPanel('Gecikmiş rapor'), findsNothing);

    final card = find.ancestor(of: inPanel('Diğer gün görevi'), matching: find.byType(TaskCard));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: card, matching: find.byTooltip('Tamamlandı olarak işaretle')));
    await tester.pumpAndSettle();
    expect(tasks.tasks.firstWhere((t) => t.id == 'o2').status, TaskStatus.done);
    expect(find.byKey(Key('calendar.marker.${id(other)}.0.done')), findsOneWidget);
    expect(find.byKey(Key('calendar.marker.${id(other)}.1.done')), findsOneWidget);
  });

  testWidgets('aylık / 2 haftalık / haftalık görünüm geçişi', (tester) async {
    await openCalendarOnPhone(tester);
    CalendarFormat format() =>
        tester.widget<TableCalendar<Task>>(find.byKey(const Key('calendar.table'))).calendarFormat;
    expect(format(), CalendarFormat.month);

    await tester.tap(find.descendant(of: find.byKey(const Key('calendar.format')), matching: find.text('2 Hafta')));
    await tester.pumpAndSettle();
    expect(format(), CalendarFormat.twoWeeks);

    await tester.tap(find.descendant(of: find.byKey(const Key('calendar.format')), matching: find.text('Hafta')));
    await tester.pumpAndSettle();
    expect(format(), CalendarFormat.week);
    expect(find.byKey(Key('calendar.markers.${id(today)}')), findsOneWidget, reason: 'bugünün haftası görünür');
  });

  testWidgets('"Bu güne görev ekle" formu seçili tarihle açar ve görevi o güne ekler', (tester) async {
    await openCalendarOnPhone(tester);
    await tester.tap(dayCell(other));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('calendar.addForDay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar.addForDay')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byKey(const Key('taskForm.dueDate')), matching: find.text('Tarih yok')),
      findsNothing,
    );
    await tester.enterText(find.byKey(const Key('taskForm.title')), 'Takvimden eklendi');
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await tester.pumpAndSettle();

    final created = tasks.tasks.last;
    expect(created.title, 'Takvimden eklendi');
    expect(created.dueDate, endOfDay(other));
    await tester.ensureVisible(find.byKey(const Key('calendar.dayTasks')));
    expect(inPanel('Takvimden eklendi'), findsOneWidget, reason: 'takvim yenilendi');
  });

  testWidgets('listeden düzenleme formu açılır ve tarih değişince görev başka güne geçer', (tester) async {
    await openCalendarOnPhone(tester);
    await tester.ensureVisible(inPanel('Akşam toplantısı'));
    await tester.pumpAndSettle();
    await tester.tap(inPanel('Akşam toplantısı'));
    await tester.pumpAndSettle();
    expect(find.text('Görevi düzenle'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('taskForm.title')), 'Akşam toplantısı (güncel)');
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await tester.pumpAndSettle();
    expect(inPanel('Akşam toplantısı (güncel)'), findsOneWidget);
  });

  testWidgets('masaüstü: yan menüden Takvim; gün görevleri sağ panelde', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(initialUser: _user),
      tasks: tasks,
      categories: categories,
      size: _desktop,
    );
    await tester.tap(find.byKey(const Key('sidebar.calendar')));
    await tester.pumpAndSettle();
    expect(find.byType(AppSidebar), findsOneWidget);
    final table = tester.getRect(find.byKey(const Key('calendar.table')));
    final panel = tester.getRect(find.byKey(const Key('calendar.dayTasks')));
    expect(panel.left, greaterThan(table.right), reason: 'sağ panel');

    // Kategoriye tıklayınca görevler sekmesine dönülür.
    await tester.tap(find.descendant(of: find.byType(AppSidebar), matching: find.text('Kişisel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar.table')), findsNothing);
  });

  testWidgets('çevrimdışı: önbellekteki görevlerle takvim çalışır', (tester) async {
    final connectivity = FakeConnectivity(online: false);
    tasks.offline = true;
    categories.offline = true;
    await tester.pumpApp(
      auth: FakeAuthRepository(initialUser: _user),
      tasks: tasks,
      categories: categories,
      size: _phone,
      withOfflineLayer: true,
      prefs: seededOfflineCache('u1', tasks: calendarTasks(), tree: categories.tree),
      overrides: [connectivityServiceProvider.overrideWithValue(connectivity)],
    );
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Takvim')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline.banner')), findsOneWidget);
    expect(find.byKey(Key('calendar.marker.${id(other)}.0.$otherOpen')), findsOneWidget);
    expect(inPanel('Gecikmiş rapor'), findsOneWidget);
  });
}
