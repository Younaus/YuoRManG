import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/desktop/corner_window_service.dart';
import 'package:yourmang/core/desktop/global_hotkey_service.dart';
import 'package:yourmang/core/desktop/tray_service.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/domain/quick_capture.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_desktop_services.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';
import 'corner_mode_test.dart' show FakeCornerWindowService;

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');

void main() {
  group('QuickDue / quickCaptureDraft', () {
    final now = DateTime(2026, 12, 31, 14, 30);

    test('Bugün / Yarın günün sonu; Tarihsiz null (yıl sonu geçişi dahil)', () {
      expect(QuickDue.today.resolve(now), DateTime(2026, 12, 31, 23, 59));
      expect(QuickDue.tomorrow.resolve(now), DateTime(2027, 1, 1, 23, 59));
      expect(QuickDue.none.resolve(now), isNull);
      expect(QuickDue.values.map((d) => d.label), ['Bugün', 'Yarın', 'Tarihsiz']);
    });

    test('başlık kırpılır; boş başlık taslak üretmez; durum "Devam ediyor"', () {
      expect(quickCaptureDraft(title: '   ', due: QuickDue.today, now: now), isNull);
      final draft = quickCaptureDraft(title: '  Rapor  ', due: QuickDue.tomorrow, categoryId: 'work', now: now)!;
      expect(draft.title, 'Rapor');
      expect(draft.dueDate, DateTime(2027, 1, 1, 23, 59));
      expect(draft.categoryId, 'work');
      expect(draft.status, TaskStatus.inProgress);
    });
  });

  group('Ctrl+Alt+N akışı', () {
    late FakeCategoryRepository categories;
    late FakeTaskRepository tasks;
    late FakeDesktopTrayService tray;
    late FakeGlobalHotkeyService hotkey;
    late FakeCornerWindowService corner;

    setUp(() {
      categories = FakeCategoryRepository(sampleCategories());
      tasks = FakeTaskRepository(tasks: sampleTasks(), categories: categories);
      tray = FakeDesktopTrayService();
      hotkey = FakeGlobalHotkeyService();
      corner = FakeCornerWindowService();
    });

    Future<void> pump(WidgetTester tester) => tester.pumpApp(
      auth: FakeAuthRepository(initialUser: _user),
      tasks: tasks,
      categories: categories,
      size: const Size(1280, 800),
      overrides: [
        desktopTrayServiceProvider.overrideWithValue(tray),
        globalHotkeyServiceProvider.overrideWithValue(hotkey),
        cornerWindowServiceProvider.overrideWithValue(corner),
      ],
    );

    Future<void> press(WidgetTester tester) async {
      hotkey.press();
      await tester.pumpAndSettle();
    }

    test('flutter test ortamında platform servisi no-op', () async {
      expect((await createGlobalHotkeyService()).isSupported, isFalse);
    });

    testWidgets('tepsideyken: pencere açılır, başlığa odaklanılır; Enter kaydeder ve tepsiye döner', (tester) async {
      await pump(tester);
      tray.visible = false;
      tray.focused = false;
      await press(tester);

      expect(tray.calls, ['show']);
      expect(find.byKey(const Key('quickCapture.dialog')), findsOneWidget);
      // Otomatik odak: dokunmadan doğrudan yazılabilir.
      tester.testTextInput.enterText('Faturayı öde');
      await tester.tap(find.byKey(const Key('quickCapture.due.tomorrow')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('quickCapture.title')));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quickCapture.dialog')), findsNothing);
      final created = tasks.tasks.last;
      expect(created.title, 'Faturayı öde');
      expect(created.status, TaskStatus.inProgress);
      expect(created.categoryId, isNull, reason: 'varsayılan: Kategorisiz');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect((created.dueDate!.day, created.dueDate!.hour), (tomorrow.day, 23));
      expect(tray.calls, ['show', 'hide'], reason: 'önceki durum: tepside');
      expect(find.text('Faturayı öde'), findsOneWidget, reason: 'listeye eklendi');
    });

    testWidgets('varsayılan tarih "Tarihsiz"; kategori seçilebilir', (tester) async {
      await pump(tester);
      await press(tester);
      final chip = tester.widget<ChoiceChip>(find.byKey(const Key('quickCapture.due.none')));
      expect(chip.selected, isTrue);

      await tester.enterText(find.byKey(const Key('quickCapture.title')), 'Okuma listesi');
      await tester.tap(find.byKey(const Key('quickCapture.category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kişisel').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quickCapture.save')));
      await tester.pumpAndSettle();

      final created = tasks.tasks.last;
      expect(created.dueDate, isNull);
      expect(created.categoryId, 'personal');
      expect(tray.calls, ['show'], reason: 'önceki durum: ön planda — dokunulmaz');
    });

    testWidgets('Esc iptal eder, görev eklenmez ve pencere arka plana döner', (tester) async {
      await pump(tester);
      tray.focused = false; // başka uygulama önde
      final before = tasks.tasks.length;
      await press(tester);
      await tester.enterText(find.byKey(const Key('quickCapture.title')), 'Vazgeçildi');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quickCapture.dialog')), findsNothing);
      expect(tasks.tasks.length, before);
      expect(tray.calls, ['show', 'blur']);
    });

    testWidgets('boş başlıkla Enter kaydetmez, uyarı gösterir', (tester) async {
      await pump(tester);
      final before = tasks.tasks.length;
      await press(tester);
      await tester.tap(find.byKey(const Key('quickCapture.title')));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Başlık gerekli'), findsOneWidget);
      expect(find.byKey(const Key('quickCapture.dialog')), findsOneWidget);
      expect(tasks.tasks.length, before);
    });

    testWidgets('küçültülmüşken: kayıttan sonra yeniden küçültülür', (tester) async {
      await pump(tester);
      tray.minimized = true;
      await press(tester);
      await tester.enterText(find.byKey(const Key('quickCapture.title')), 'Not al');
      await tester.tap(find.byKey(const Key('quickCapture.save')));
      await tester.pumpAndSettle();
      expect(tray.calls, ['show', 'minimize']);
    });

    testWidgets('köşe kapsülündeyken: kapsülden çıkılır, kayıttan sonra kapsüle dönülür', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('tasks.cornerMode')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      hotkey.press();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(corner.calls, ['enter', 'exit']);
      expect(find.byKey(const Key('quickCapture.dialog')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('quickCapture.title')), 'Kapsülden');
      await tester.tap(find.byKey(const Key('quickCapture.save')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(corner.calls, ['enter', 'exit', 'enter']);
      expect(find.byKey(const Key('corner.pill')), findsOneWidget);
      await tester.tap(find.byKey(const Key('corner.open')));
      await tester.pumpAndSettle();
    });

    testWidgets('diyalog açıkken tekrar basılırsa ikinci diyalog açılmaz', (tester) async {
      await pump(tester);
      await press(tester);
      await press(tester);
      expect(find.byKey(const Key('quickCapture.dialog')), findsOneWidget);
    });

    testWidgets('oturum yoksa yalnızca pencere açılır (giriş ekranı)', (tester) async {
      await tester.pumpApp(
        auth: FakeAuthRepository(),
        size: const Size(1280, 800),
        overrides: [
          desktopTrayServiceProvider.overrideWithValue(tray),
          globalHotkeyServiceProvider.overrideWithValue(hotkey),
        ],
      );
      await press(tester);
      expect(tray.calls, ['show']);
      expect(find.byKey(const Key('quickCapture.dialog')), findsNothing);
    });

    testWidgets('tepsiden "Çıkış" kısayol kaydını temizler', (tester) async {
      await pump(tester);
      tray.trigger(TrayAction.quit);
      await tester.pumpAndSettle();
      expect(hotkey.disposed, isTrue);
      expect(tray.calls, ['quit']);
    });
  });
}
