import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/core/layout/app_sidebar.dart';
import 'package:yourmang/core/offline/connectivity_service.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/widgets/task_card.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_offline.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');
const _desktop = Size(1280, 800);
const _phone = Size(390, 844);

void main() {
  late FakeCategoryRepository categories;
  late FakeTaskRepository tasks;
  late FakeConnectivity connectivity;

  setUp(() {
    categories = FakeCategoryRepository(sampleCategories());
    tasks = FakeTaskRepository(tasks: sampleTasks(), categories: categories);
    connectivity = FakeConnectivity();
  });

  Future<SharedPreferences> pump(WidgetTester tester, {Size size = _desktop, Map<String, Object> prefs = const {}}) =>
      tester.pumpApp(
        auth: FakeAuthRepository(initialUser: _user),
        tasks: tasks,
        categories: categories,
        size: size,
        prefs: prefs,
        withOfflineLayer: true,
        overrides: [connectivityServiceProvider.overrideWithValue(connectivity)],
      );

  void disconnect() {
    tasks.offline = true;
    categories.offline = true;
    connectivity.set(online: false);
  }

  Future<void> reconnect(WidgetTester tester) async {
    tasks.offline = false;
    categories.offline = false;
    connectivity.set(online: true);
    await tester.pumpAndSettle();
  }

  Finder banner() => find.byKey(const Key('offline.banner'));
  Finder checkButtonOf(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(TaskCard)),
    matching: find.byTooltip('Tamamlandı olarak işaretle'),
  );
  Finder inSidebar(String text) => find.descendant(of: find.byType(AppSidebar), matching: find.text(text));

  Future<void> createTask(WidgetTester tester, String title) async {
    await tester.tap(find.byKey(const Key('tasks.newTask')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('taskForm.title')), title);
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('internet yokken açılış: önbellekteki görevler ve kategoriler + "Çevrimdışı mod" şeridi', (tester) async {
    tasks.offline = true;
    categories.offline = true;
    connectivity.online = false;
    await pump(
      tester,
      prefs: seededOfflineCache('u1', tasks: sampleTasks(), tree: categories.tree),
    );

    expect(find.byType(TaskCard), findsNWidgets(4));
    expect(inSidebar('Projeler'), findsOneWidget);
    expect(banner(), findsOneWidget);
    expect(find.textContaining('Çevrimdışı mod'), findsOneWidget);
  });

  testWidgets('başka kullanıcının önbelleği gösterilmez (uid bazlı)', (tester) async {
    tasks.offline = true;
    categories.offline = true;
    await pump(
      tester,
      prefs: seededOfflineCache('baska-kullanici', tasks: sampleTasks(), tree: categories.tree),
    );
    expect(find.byType(TaskCard), findsNothing);
    expect(find.text('Görevler yüklenemedi'), findsOneWidget);
  });

  testWidgets('çevrimdışı ekleme ve tamamlama anında görünür; bağlantı gelince sırayla gönderilir', (tester) async {
    await pump(tester);
    expect(banner(), findsNothing);
    disconnect();

    await createTask(tester, 'Uçakta yazıldı');
    expect(find.text('Uçakta yazıldı'), findsOneWidget, reason: 'optimistic');
    await tester.tap(checkButtonOf('Sprint planlaması'));
    await tester.pumpAndSettle();
    expect(banner(), findsOneWidget);
    expect(find.textContaining('2 değişiklik bekliyor'), findsOneWidget);
    expect(tasks.writes, isEmpty);

    await reconnect(tester);
    expect(tasks.writes, ['create:Uçakta yazıldı', 'status:t1:done'], reason: 'kullanıcının yaptığı sırayla');
    expect(tasks.tasks.firstWhere((t) => t.title == 'Uçakta yazıldı').status, TaskStatus.inProgress);
    expect(banner(), findsNothing, reason: 'kuyruk boşaldı, çevrimiçi');
    // Liste sunucudan yeniden çekildi: yerel geçici kimlik kalmadı.
    final card = tester.widget<TaskCard>(
      find.ancestor(of: find.text('Uçakta yazıldı'), matching: find.byType(TaskCard)),
    );
    expect(card.task.id, isNot(startsWith('local-')));
  });

  testWidgets('çevrimdışı silme kuyruğa yazılır, bağlantı gelince sunucudan silinir', (tester) async {
    await pump(tester, size: _phone);
    disconnect();
    await tester.drag(find.text('Sprint planlaması'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5)); // geri al süresi doldu
    await tester.pumpAndSettle();
    expect(find.text('Sprint planlaması'), findsNothing);
    expect(tasks.tasks.any((t) => t.id == 't1'), isTrue, reason: 'henüz gönderilmedi');

    await reconnect(tester);
    expect(tasks.writes, ['delete:t1']);
    expect(tasks.tasks.any((t) => t.id == 't1'), isFalse);
    expect(find.text('Sprint planlaması'), findsNothing);
  });

  testWidgets('sunucunun reddettiği işlem atlanır, kuyruk kilitlenmez', (tester) async {
    await pump(tester);
    disconnect();
    await tester.tap(checkButtonOf('Sprint planlaması')); // t1
    await tester.pumpAndSettle();
    await createTask(tester, 'Sonraki işlem');
    tasks.tasks.removeWhere((t) => t.id == 't1'); // diğer cihazda silindi → 404

    await reconnect(tester);
    expect(tasks.writes, ['create:Sonraki işlem']);
    expect(banner(), findsNothing);
  });

  testWidgets('"Tekrar dene" bağlantı olayı gelmeden de gönderir', (tester) async {
    await pump(tester);
    disconnect();
    await createTask(tester, 'Elle gönderilecek');
    tasks.offline = false;
    categories.offline = false;
    connectivity.online = true; // olay yayınlanmadı (ör. Wi-Fi vardı ama internet yoktu)

    await tester.tap(find.byKey(const Key('offline.retry')));
    await tester.pumpAndSettle();
    expect(tasks.writes, ['create:Elle gönderilecek']);
    expect(banner(), findsNothing);
  });

  testWidgets('çıkışta önbellek ve kuyruk silinir (bekleyen varsa önce onay)', (tester) async {
    final prefs = await pump(tester);
    disconnect();
    await createTask(tester, 'Kaybolacak');
    expect(prefs.getKeys().where((k) => k.startsWith('offline.v1.u1.')), isNotEmpty);

    await tester.tap(find.byKey(const Key('sidebar.settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.text('Gönderilmemiş değişiklikler var'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings.signOutConfirm')));
    await tester.pumpAndSettle();

    expect(prefs.getKeys().where((k) => k.startsWith('offline.v1.u1.')), isEmpty);
  });
}
