import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/desktop/corner_window_service.dart';
import 'package:yourmang/core/desktop/tray_service.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_desktop_services.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';
import 'corner_mode_test.dart' show FakeCornerWindowService;

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');

void main() {
  late FakeTaskRepository tasks;
  late FakeDesktopTrayService tray;
  late FakeCornerWindowService corner;

  setUp(() {
    tasks = FakeTaskRepository(tasks: sampleTasks()); // t2 devam ediyor
    tray = FakeDesktopTrayService();
    corner = FakeCornerWindowService();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    auth: FakeAuthRepository(initialUser: _user),
    tasks: tasks,
    size: const Size(1280, 800),
    overrides: [
      desktopTrayServiceProvider.overrideWithValue(tray),
      cornerWindowServiceProvider.overrideWithValue(corner),
    ],
  );

  /// Kapsülün nabız animasyonu sürekli döndüğü için sabit süre ilerletilir.
  Future<void> advance(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  test('flutter test ortamında platform servisi no-op', () async {
    expect((await createDesktopTrayService()).isSupported, isFalse);
  });

  testWidgets('sol tık / "YouRManG\'ı Aç" pencereyi öne getirir', (tester) async {
    await pump(tester);
    tray.visible = false;
    tray.trigger(TrayAction.open);
    await tester.pumpAndSettle();
    expect(tray.calls, ['show']);
    expect(tray.visible, isTrue);
  });

  testWidgets('köşe kapsülündeyken "Aç" önce kapsülden çıkar', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('tasks.cornerMode')));
    await advance(tester);
    expect(find.byKey(const Key('corner.pill')), findsOneWidget);

    tray.trigger(TrayAction.open);
    await tester.pumpAndSettle();
    expect(corner.calls, ['enter', 'exit']);
    expect(tray.calls, ['show']);
    expect(find.byKey(const Key('corner.pill')), findsNothing);
  });

  testWidgets('"Hızlı Görev Ekle" pencereyi açıp hızlı görev diyaloğunu gösterir', (tester) async {
    await pump(tester);
    tray.trigger(TrayAction.quickAdd);
    await tester.pumpAndSettle();
    expect(tray.calls, contains('show'));
    expect(find.byKey(const Key('quickCapture.dialog')), findsOneWidget);
    expect(find.byKey(const Key('quickCapture.title')), findsOneWidget);
  });

  group('"Köşe Kapsülünü Aç/Kapat"', () {
    testWidgets('devam eden görev varken kapsüle geçer, tekrar seçilince ana pencereye döner', (tester) async {
      await pump(tester);
      tray.trigger(TrayAction.toggleCorner);
      await advance(tester);
      expect(corner.calls, ['enter']);
      expect(find.byKey(const Key('corner.pill')), findsOneWidget);

      tray.trigger(TrayAction.toggleCorner);
      await tester.pumpAndSettle();
      expect(corner.calls, ['enter', 'exit']);
      expect(tray.calls, ['show']);
    });

    testWidgets('devam eden görev yoksa yalnızca ana pencereyi açar', (tester) async {
      tasks = FakeTaskRepository(tasks: [task('t1', status: TaskStatus.todo)]);
      await pump(tester);
      tray.trigger(TrayAction.toggleCorner);
      await tester.pumpAndSettle();
      expect(corner.calls, isEmpty);
      expect(tray.calls, ['show']);
    });
  });

  testWidgets('"Çıkış" uygulamayı gerçekten sonlandırır', (tester) async {
    await pump(tester);
    tray.trigger(TrayAction.quit);
    await tester.pumpAndSettle();
    expect(tray.calls, ['quit']);
  });
}
