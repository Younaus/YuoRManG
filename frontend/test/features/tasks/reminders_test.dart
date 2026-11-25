import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/core/notifications/reminder_service.dart';
import 'package:yourmang/core/utils/date_labels.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/providers/reminder_providers.dart';
import 'package:yourmang/features/tasks/presentation/widgets/task_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_reminders.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');

void main() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final inTwoDays = DateTime(now.year, now.month, now.day + 2, 14, 30);

  late FakeCategoryRepository categories;
  late FakeTaskRepository tasks;
  late FakeReminderService reminders;

  setUp(() {
    categories = FakeCategoryRepository(sampleCategories());
    tasks = FakeTaskRepository(
      categories: categories,
      tasks: [
        task('r1', title: 'Yarınki rapor', dueDate: endOfDay(tomorrow)),
        task('r2', title: 'Saatli toplantı', status: TaskStatus.inProgress, dueDate: inTwoDays, ageMinutes: 1),
        task('r3', title: 'Bitmiş iş', status: TaskStatus.done, dueDate: endOfDay(tomorrow), ageMinutes: 2),
        task('r4', title: 'Tarihsiz', ageMinutes: 3),
      ],
    );
    reminders = FakeReminderService();
  });

  Future<SharedPreferences> pump(WidgetTester tester, {Map<String, Object> prefs = const {}}) => tester.pumpApp(
    auth: FakeAuthRepository(initialUser: _user),
    tasks: tasks,
    categories: categories,
    size: const Size(1280, 800),
    prefs: prefs,
    withOfflineLayer: true,
    overrides: [reminderServiceProvider.overrideWithValue(reminders)],
  );

  /// Eşitleme gecikmesini (debounce) geçir.
  Future<void> settleReminders(WidgetTester tester) async {
    await tester.pumpAndSettle(); // animasyonlar (ör. SnackBar kapanışı) → yazma isteği
    await tester.pump(ReminderController.debounce + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  Finder card(String title) => find.ancestor(of: find.text(title), matching: find.byType(TaskCard));

  test('flutter test ortamında platform servisi no-op', () async {
    expect((await createReminderService()).isSupported, isFalse);
  });

  testWidgets('açılışta tamamlanmamış tarihli görevlere hatırlatma kurulur', (tester) async {
    await pump(tester);
    await settleReminders(tester);
    expect(reminders.atFor('Yarınki rapor'), DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9));
    expect(reminders.atFor('Saatli toplantı'), inTwoDays);
    expect(reminders.atFor('Bitmiş iş'), isNull);
    expect(reminders.atFor('Tarihsiz'), isNull);
  });

  testWidgets('tamamlayınca iptal, geri alınca yeniden kurulur; silince iptal', (tester) async {
    await pump(tester);
    await settleReminders(tester);

    await tester.tap(
      find.descendant(of: card('Yarınki rapor'), matching: find.byTooltip('Tamamlandı olarak işaretle')),
    );
    await settleReminders(tester);
    expect(reminders.atFor('Yarınki rapor'), isNull);

    await tester.tap(
      find.descendant(of: card('Yarınki rapor'), matching: find.byTooltip('Tamamlanmadı olarak işaretle')),
    );
    await settleReminders(tester);
    expect(reminders.atFor('Yarınki rapor'), isNotNull);

    await tester.drag(find.text('Saatli toplantı'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5)); // "Geri al" süresi
    await settleReminders(tester);
    expect(reminders.atFor('Saatli toplantı'), isNull);
  });

  testWidgets('tarih değişince hatırlatma yeni zamana taşınır; yeni görev için kurulur', (tester) async {
    await pump(tester);
    await settleReminders(tester);

    // Düzenleme: tarihi kaldır → hatırlatma iptal.
    await tester.tap(find.text('Saatli toplantı'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tarihi kaldır'));
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await settleReminders(tester);
    expect(reminders.atFor('Saatli toplantı'), isNull);

    // Başka cihazda tarih eklendi; yenileme (F5 / syncProvider) sonrası kurulur.
    final i = tasks.tasks.indexWhere((t) => t.id == 'r2');
    tasks.tasks[i] = tasks.tasks[i].copyWith(dueDate: inTwoDays.add(const Duration(hours: 1)));
    tasks.tasks.add(task('remote', title: 'Diğer cihazdan', dueDate: endOfDay(tomorrow), ageMinutes: -5));
    await tester.tap(find.byKey(const Key('tasks.refresh')));
    await settleReminders(tester);
    expect(reminders.atFor('Saatli toplantı'), inTwoDays.add(const Duration(hours: 1)));
    expect(reminders.atFor('Diğer cihazdan'), isNotNull);
  });

  testWidgets('Ayarlar: kapatınca tüm hatırlatmalar silinir, açınca yeniden kurulur', (tester) async {
    await pump(tester);
    await settleReminders(tester);
    expect(reminders.scheduled, isNotEmpty);

    await tester.tap(find.byKey(const Key('sidebar.settings')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('settings.reminders'));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(reminders.scheduled, isEmpty);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await settleReminders(tester);
    expect(reminders.scheduled, hasLength(2));
  });

  testWidgets('izin reddedilirse anahtar kapalı kalır ve kullanıcı bilgilendirilir', (tester) async {
    reminders
      ..permission = false
      ..grantOnRequest = false;
    await pump(tester, prefs: {ReminderController.enabledKey: false, ReminderController.permissionAskedKey: true});
    await tester.tap(find.byKey(const Key('sidebar.settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings.reminders')));
    await tester.pumpAndSettle();
    expect(reminders.permissionRequests, 1);
    expect(find.textContaining('Bildirim izni verilmedi'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('settings.reminders'))).value, isFalse);
    expect(reminders.scheduled, isEmpty);
  });

  testWidgets('Android 13+: izin önce açıklanarak bir kez istenir', (tester) async {
    reminders.permission = false;
    final prefs = await pump(tester);
    expect(find.byKey(const Key('reminders.permissionDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reminders.allow')));
    await settleReminders(tester);
    expect(reminders.permissionRequests, 1);
    expect(prefs.getBool(ReminderController.permissionAskedKey), isTrue);
    expect(reminders.scheduled, hasLength(2), reason: 'izin verildi, kuruldu');
  });

  testWidgets('"Şimdi değil" denince tekrar sorulmaz ve bildirim kurulmaz', (tester) async {
    reminders.permission = false;
    await pump(tester);
    await tester.tap(find.text('Şimdi değil'));
    await settleReminders(tester);
    expect(reminders.permissionRequests, 0);
    expect(reminders.scheduled, isEmpty);
    expect(find.byKey(const Key('reminders.permissionDialog')), findsNothing);
  });

  testWidgets('çıkış yapılınca zamanlanmış tüm hatırlatmalar temizlenir', (tester) async {
    final prefs = await pump(tester);
    await settleReminders(tester);
    expect(reminders.scheduled, isNotEmpty);

    await tester.tap(find.byKey(const Key('sidebar.settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çıkış yap'));
    await settleReminders(tester);
    expect(reminders.scheduled, isEmpty);
    expect(prefs.getString(ReminderController.scheduledKey), '[]');
  });
}
