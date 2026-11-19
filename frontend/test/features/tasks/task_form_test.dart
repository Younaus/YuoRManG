import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');

void main() {
  late FakeTaskRepository tasks;

  setUp(() => tasks = FakeTaskRepository(tasks: sampleTasks()));

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    auth: FakeAuthRepository(initialUser: _user),
    tasks: tasks,
    size: const Size(1280, 800),
  );

  Finder segment(String label) =>
      find.descendant(of: find.byKey(const Key('taskForm.status')), matching: find.text(label));

  Color dotColor(WidgetTester tester, TaskStatus status) {
    final dot = tester.widget<Container>(find.byKey(Key('taskForm.status.dot.${status.apiValue}')));
    return (dot.decoration! as BoxDecoration).color!;
  }

  testWidgets('yeni görev formunda "Tamamlandı" seçeneği yok', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('tasks.newTask')));
    await tester.pumpAndSettle();

    expect(segment('Yapılacak'), findsOneWidget);
    expect(segment('Devam ediyor'), findsOneWidget);
    expect(segment('Tamamlandı'), findsNothing);
  });

  testWidgets('düzenleme formunda "Tamamlandı" seçilebilir', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Sprint planlaması'));
    await tester.pumpAndSettle();

    expect(find.text('Görevi düzenle'), findsOneWidget);
    expect(segment('Tamamlandı'), findsOneWidget);
    await tester.tap(segment('Tamamlandı'));
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await tester.pumpAndSettle();
    expect(tasks.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.done);
  });

  testWidgets('seçili segmentteki durum noktası indigo zeminde yüksek kontrastlı', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('tasks.newTask')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('taskForm.status')));
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    expect(dotColor(tester, TaskStatus.todo), onPrimary, reason: 'varsayılan seçim: Yapılacak');
    final inProgressColor = dotColor(tester, TaskStatus.inProgress);
    expect(inProgressColor, isNot(onPrimary));

    await tester.tap(segment('Devam ediyor'));
    await tester.pumpAndSettle();
    expect(dotColor(tester, TaskStatus.inProgress), onPrimary);
    expect(dotColor(tester, TaskStatus.todo), isNot(onPrimary), reason: 'seçilmeyen segment kendi durum rengine döner');
  });
}
