import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/desktop/corner_window_service.dart';
import 'package:yourmang/core/layout/app_sidebar.dart';
import 'package:yourmang/core/network/api_exception.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/providers/sync_providers.dart';
import 'package:yourmang/features/tasks/presentation/widgets/task_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';
import 'corner_mode_test.dart' show FakeCornerWindowService;

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');
const _desktop = Size(1280, 800);
const _phone = Size(390, 844);

void main() {
  late FakeCategoryRepository categories;
  late FakeTaskRepository tasks;
  late DateTime now;

  setUp(() {
    categories = FakeCategoryRepository(sampleCategories());
    tasks = FakeTaskRepository(tasks: sampleTasks(), categories: categories);
    now = DateTime(2026, 11, 25, 9);
  });

  Future<void> pump(WidgetTester tester, Size size, {CornerWindowService? window}) => tester.pumpApp(
    auth: FakeAuthRepository(initialUser: _user),
    tasks: tasks,
    categories: categories,
    size: size,
    overrides: [
      syncClockProvider.overrideWithValue(() => now),
      if (window != null) cornerWindowServiceProvider.overrideWithValue(window),
    ],
  );

  /// Başka bir cihaz (ör. Android) aynı hesaba kategori + görev ekler.
  Future<void> changeOnOtherDevice() async {
    final c = await categories.create(name: 'Okul', color: '#F59E0B');
    tasks.tasks.add(task('remote', title: 'Mobilden eklendi', categoryId: c.id, ageMinutes: -10));
  }

  Finder inSidebar(String text) => find.descendant(of: find.byType(AppSidebar), matching: find.text(text));

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  group('masaüstü', () {
    testWidgets('yenile düğmesi diğer cihazdaki kategori ve görevi birlikte getirir', (tester) async {
      await pump(tester, _desktop);
      await changeOnOtherDevice();
      expect(inSidebar('Okul'), findsNothing, reason: 'henüz yenilenmedi');

      await tester.tap(find.byKey(const Key('tasks.refresh')));
      await tester.pumpAndSettle();
      expect(inSidebar('Okul'), findsOneWidget);
      expect(find.text('Mobilden eklendi'), findsOneWidget);
    });

    testWidgets('F5 kısayolu da ikisini yeniler', (tester) async {
      await pump(tester, _desktop);
      await changeOnOtherDevice();
      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pumpAndSettle();
      expect(inSidebar('Okul'), findsOneWidget);
      expect(find.text('Mobilden eklendi'), findsOneWidget);
    });

    testWidgets('yenileme başarısız olursa uyarı gösterilir, liste ekranda kalır', (tester) async {
      await pump(tester, _desktop);
      tasks.failNext = const ApiException(statusCode: 503, code: 'UNAVAILABLE', message: 'yok');
      await tester.tap(find.byKey(const Key('tasks.refresh')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Yenilenemedi'), findsOneWidget);
      expect(find.byType(TaskCard), findsNWidgets(4));
      expect(inSidebar('Kişisel'), findsOneWidget);
    });
  });

  group('mobil: aşağı çekip yenileme', () {
    testWidgets('görev listesi hem görevleri hem kategorileri yeniler', (tester) async {
      await pump(tester, _phone);
      await changeOnOtherDevice();
      final before = categories.treeRequests;

      await tester.fling(find.byType(TaskCard).first, const Offset(0, 500), 1200);
      await tester.pumpAndSettle();
      expect(find.text('Mobilden eklendi'), findsOneWidget);
      expect(categories.treeRequests, before + 1);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Drawer), matching: find.text('Okul')), findsOneWidget);
    });

    testWidgets('görev yokken de aşağı çekilebilir', (tester) async {
      tasks = FakeTaskRepository(categories: categories);
      await pump(tester, _phone);
      expect(find.text('Burada henüz görev yok'), findsOneWidget);
      tasks.tasks.add(task('remote', title: 'İlk uzak görev', status: TaskStatus.inProgress));

      await tester.fling(find.text('Burada henüz görev yok'), const Offset(0, 500), 1200);
      await tester.pumpAndSettle();
      expect(find.text('İlk uzak görev'), findsOneWidget);
    });

    testWidgets('Kategoriler sekmesi aşağı çekilince yenilenir', (tester) async {
      await pump(tester, _phone);
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Kategoriler')));
      await tester.pumpAndSettle();
      await changeOnOtherDevice();
      expect(find.text('Okul'), findsNothing);

      await tester.fling(find.text('İş'), const Offset(0, 500), 1200);
      await tester.pumpAndSettle();
      expect(find.text('Okul'), findsOneWidget);
    });
  });

  group('uygulama öne gelince', () {
    testWidgets('5 sn bekleme süresinden sonra kategoriler ve görevler yenilenir', (tester) async {
      await pump(tester, _desktop);
      await changeOnOtherDevice();
      final treeBefore = categories.treeRequests;
      final listBefore = tasks.queries.length;

      now = now.add(const Duration(seconds: 2));
      await resume(tester);
      expect(categories.treeRequests, treeBefore, reason: 'açılıştan hemen sonra tekrar istenmez');
      expect(inSidebar('Okul'), findsNothing);

      now = now.add(const Duration(seconds: 4));
      await resume(tester);
      expect(categories.treeRequests, treeBefore + 1);
      expect(tasks.queries.length, greaterThan(listBefore));
      expect(inSidebar('Okul'), findsOneWidget);
      expect(find.text('Mobilden eklendi'), findsOneWidget);

      now = now.add(const Duration(seconds: 3));
      await resume(tester);
      expect(categories.treeRequests, treeBefore + 1, reason: 'son yenilemeden 5 sn geçmedi');
    });

    testWidgets('elle yenileme de bekleme süresini başlatır', (tester) async {
      await pump(tester, _desktop);
      now = now.add(const Duration(minutes: 1));
      await tester.tap(find.byKey(const Key('tasks.refresh')));
      await tester.pumpAndSettle();
      final after = categories.treeRequests;

      now = now.add(const Duration(seconds: 1));
      await resume(tester);
      expect(categories.treeRequests, after);
    });

    testWidgets('köşe modundayken öne gelme yenilemesi yapılmaz', (tester) async {
      await pump(tester, _desktop, window: FakeCornerWindowService());
      await tester.tap(find.byKey(const Key('tasks.cornerMode')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final before = categories.treeRequests;

      now = now.add(const Duration(minutes: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(categories.treeRequests, before);

      await tester.tap(find.byKey(const Key('corner.open')));
      await tester.pumpAndSettle();
    });
  });
}
