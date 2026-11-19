import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_draft.dart';
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

  test('yeni görev taslağı varsayılan olarak "Devam ediyor"', () {
    expect(TaskDraft.initialStatus, TaskStatus.inProgress);
    expect(const TaskDraft(title: 'x').status, TaskStatus.inProgress);
  });

  testWidgets('yeni görev formunda durum seçici yok; görev "Devam ediyor" olarak kaydedilir', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('tasks.newTask')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taskForm.status')), findsNothing);
    expect(find.text('Durum'), findsNothing);
    expect(find.text('Görev "Devam ediyor" olarak eklenecek'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('taskForm.title')), 'Rapor yaz');
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await tester.pumpAndSettle();
    final created = tasks.tasks.last;
    expect(created.title, 'Rapor yaz');
    expect(created.status, TaskStatus.inProgress);
  });

  testWidgets('düzenleme formunda tüm durumlar seçilebilir', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Sprint planlaması'));
    await tester.pumpAndSettle();

    expect(find.text('Görevi düzenle'), findsOneWidget);
    expect(find.byKey(const Key('taskForm.initialStatus')), findsNothing);
    for (final s in TaskStatus.values) {
      expect(segment(s.label), findsOneWidget);
    }
    await tester.tap(segment('Tamamlandı'));
    await tester.tap(find.byKey(const Key('taskForm.submit')));
    await tester.pumpAndSettle();
    expect(tasks.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.done);
  });

  testWidgets('seçili segmentteki durum noktası indigo zeminde yüksek kontrastlı', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Sprint planlaması')); // durum: Yapılacak
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('taskForm.status')));
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    expect(dotColor(tester, TaskStatus.todo), onPrimary);
    expect(dotColor(tester, TaskStatus.inProgress), isNot(onPrimary));

    await tester.tap(segment('Devam ediyor'));
    await tester.pumpAndSettle();
    expect(dotColor(tester, TaskStatus.inProgress), onPrimary);
    expect(dotColor(tester, TaskStatus.todo), isNot(onPrimary), reason: 'seçilmeyen segment kendi durum rengine döner');
  });
}
