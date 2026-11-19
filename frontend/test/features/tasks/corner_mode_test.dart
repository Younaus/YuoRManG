import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/core/desktop/corner_window_service.dart';
import 'package:yourmang/core/layout/app_sidebar.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/providers/corner_mode_providers.dart';
import 'package:yourmang/features/tasks/presentation/widgets/task_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');
const _desktop = Size(1280, 800);

/// Windows pencere işlemlerini kaydeden sahte servis.
class FakeCornerWindowService implements CornerWindowService {
  final calls = <String>[];
  final opacities = <double>[];
  final _minimize = StreamController<void>.broadcast();

  void minimize() => _minimize.add(null);

  @override
  bool get isSupported => true;

  @override
  Stream<void> get onMinimize => _minimize.stream;

  @override
  Future<void> enterCornerMode() async => calls.add('enter');

  @override
  Future<void> exitCornerMode() async => calls.add('exit');

  @override
  Future<void> setOpacity(double opacity) async => opacities.add(opacity);

  @override
  Widget dragArea({required Widget child}) => KeyedSubtree(key: const Key('corner.dragArea'), child: child);
}

void main() {
  late FakeTaskRepository tasks;
  late FakeCornerWindowService window;

  setUp(() {
    window = FakeCornerWindowService();
    tasks = FakeTaskRepository(
      tasks: [
        ...sampleTasks(), // t2 "API dokümantasyonu" devam ediyor
        task('t5', title: 'Sunum hazırlığı', status: TaskStatus.inProgress, ageMinutes: 4),
      ],
    );
  });

  Future<SharedPreferences> pump(
    WidgetTester tester, {
    CornerWindowService? service,
    Map<String, Object> prefs = const {},
  }) => tester.pumpApp(
    auth: FakeAuthRepository(initialUser: _user),
    tasks: tasks,
    size: _desktop,
    prefs: prefs,
    overrides: [cornerWindowServiceProvider.overrideWithValue(service ?? window)],
  );

  /// Nabız animasyonu sürekli döndüğü için pumpAndSettle yerine sabit süre ilerletilir.
  Future<void> advance(WidgetTester tester, [Duration by = const Duration(milliseconds: 300)]) async {
    for (var elapsed = Duration.zero; elapsed < by; elapsed += const Duration(milliseconds: 50)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> enterCornerMode(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tasks.cornerMode')));
    await advance(tester);
  }

  String pillTitle(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('corner.title'))).data!;

  test('flutter test ortamında platform servisi no-op', () async {
    expect((await createCornerWindowService()).isSupported, isFalse);
  });

  testWidgets('desteklenmeyen platformda köşe modu düğmesi ve ayarı görünmez', (tester) async {
    await pump(tester, service: const NoopCornerWindowService());
    expect(find.byKey(const Key('tasks.cornerMode')), findsNothing);

    await tester.tap(find.byKey(const Key('sidebar.settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings.cornerOnMinimize')), findsNothing);
  });

  testWidgets('devam eden görev yoksa düğme pasif', (tester) async {
    tasks = FakeTaskRepository(tasks: [task('t1')]);
    await pump(tester);
    final button = tester.widget<IconButton>(find.byKey(const Key('tasks.cornerMode')));
    expect(button.onPressed, isNull);
  });

  testWidgets('köşe moduna geçince hap görünür, ana arayüz gizlenir; geri dönülür', (tester) async {
    await pump(tester);
    await enterCornerMode(tester);

    expect(window.calls, ['enter']);
    expect(find.byKey(const Key('corner.pill')), findsOneWidget);
    expect(find.byType(AppSidebar), findsNothing, reason: 'ana arayüz offstage');
    expect(pillTitle(tester), 'API dokümantasyonu');
    expect(find.text('DEVAM EDİYOR · 1/2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('corner.restore')));
    await tester.pumpAndSettle();
    expect(window.calls, ['enter', 'exit']);
    expect(find.byKey(const Key('corner.pill')), findsNothing);
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(TaskCard), findsNWidgets(5), reason: 'liste durumu korunur');
  });

  testWidgets('geçiş oku aktif görevler arasında döner', (tester) async {
    await pump(tester);
    await enterCornerMode(tester);

    await tester.tap(find.byKey(const Key('corner.next')));
    await advance(tester);
    expect(pillTitle(tester), 'Sunum hazırlığı');
    expect(find.text('DEVAM EDİYOR · 2/2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('corner.next')));
    await advance(tester);
    expect(pillTitle(tester), 'API dokümantasyonu');
  });

  testWidgets('tek aktif görevde geçiş oku yok', (tester) async {
    tasks = FakeTaskRepository(tasks: sampleTasks());
    await pump(tester);
    await enterCornerMode(tester);
    expect(find.byKey(const Key('corner.next')), findsNothing);
    expect(find.text('DEVAM EDİYOR'), findsOneWidget);
  });

  testWidgets('tamamlayınca kısa geri bildirim, sonra sıradaki aktif göreve geçer', (tester) async {
    await pump(tester);
    await enterCornerMode(tester);

    await tester.tap(find.byKey(const Key('corner.done')));
    await tester.pump();
    expect(tasks.tasks.firstWhere((t) => t.id == 't2').status, TaskStatus.done);
    expect(find.byKey(const Key('corner.completed')), findsOneWidget);
    expect(find.text('TAMAMLANDI'), findsOneWidget);
    expect(pillTitle(tester), 'API dokümantasyonu');

    await advance(tester, CornerModeController.nextDelay + const Duration(milliseconds: 100));
    expect(pillTitle(tester), 'Sunum hazırlığı');
    expect(find.byKey(const Key('corner.next')), findsNothing, reason: 'tek aktif görev kaldı');
    expect(window.calls, ['enter'], reason: 'köşe modunda kalır');
  });

  testWidgets('son aktif görev tamamlanınca tam pencereye döner ve liste güncellenir', (tester) async {
    tasks = FakeTaskRepository(tasks: sampleTasks());
    await pump(tester);
    await enterCornerMode(tester);

    await tester.tap(find.byKey(const Key('corner.done')));
    await tester.pump();
    expect(find.byKey(const Key('corner.completed')), findsOneWidget);

    await advance(tester, CornerModeController.exitDelay + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(window.calls, ['enter', 'exit']);
    expect(find.byKey(const Key('corner.pill')), findsNothing);
    final card = tester.widget<TaskCard>(
      find.ancestor(of: find.text('API dokümantasyonu'), matching: find.byType(TaskCard)),
    );
    expect(card.task.status, TaskStatus.done, reason: 'ana liste de güncellenir');
    expect(find.byKey(const Key('tasks.cornerMode')), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const Key('tasks.cornerMode'))).onPressed, isNull);
  });

  testWidgets('kaydetme hatasında görev geri gelir ve hata gösterilir', (tester) async {
    await pump(tester);
    await enterCornerMode(tester);

    tasks.failNext = Exception('ağ');
    await tester.tap(find.byKey(const Key('corner.done')));
    await advance(tester);
    expect(find.text('KAYDEDİLEMEDİ · TEKRAR DENE'), findsOneWidget);
    expect(pillTitle(tester), 'API dokümantasyonu');
    expect(window.calls, ['enter']);
  });

  testWidgets('fare üzerine gelince opaklık artar, çıkınca azalır', (tester) async {
    await pump(tester);
    await enterCornerMode(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('corner.title'))));
    await advance(tester);
    expect(window.opacities.last, cornerHoverOpacity);

    await mouse.moveTo(const Offset(-10, -10));
    await advance(tester);
    expect(window.opacities.last, cornerIdleOpacity);
  });

  group('küçültünce otomatik köşe modu', () {
    testWidgets('ayar açıkken ve aktif görev varken köşe moduna geçer', (tester) async {
      await pump(tester, prefs: {CornerModeOnMinimizeController.storageKey: true});
      window.minimize();
      await advance(tester);
      expect(window.calls, ['enter']);
      expect(find.byKey(const Key('corner.pill')), findsOneWidget);
    });

    testWidgets('ayar kapalıyken bir şey yapmaz', (tester) async {
      await pump(tester);
      window.minimize();
      await advance(tester);
      expect(window.calls, isEmpty);
    });

    testWidgets('aktif görev yoksa bir şey yapmaz', (tester) async {
      tasks = FakeTaskRepository(tasks: [task('t1')]);
      await pump(tester, prefs: {CornerModeOnMinimizeController.storageKey: true});
      window.minimize();
      await advance(tester);
      expect(window.calls, isEmpty);
    });

    testWidgets('Ayarlar sayfasındaki anahtar tercihi kaydeder', (tester) async {
      final prefs = await pump(tester);
      await tester.tap(find.byKey(const Key('sidebar.settings')));
      await tester.pumpAndSettle();

      final toggle = find.byKey(const Key('settings.cornerOnMinimize'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(prefs.getBool(CornerModeOnMinimizeController.storageKey), isTrue);

      window.minimize();
      await advance(tester);
      expect(window.calls, ['enter']);
    });
  });
}
