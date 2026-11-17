import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/network/api_exception.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/auth/presentation/providers/auth_providers.dart';
import 'package:yourmang/features/categories/presentation/providers/category_providers.dart';
import 'package:yourmang/features/tasks/domain/entities/task_draft.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/providers/task_providers.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  late FakeCategoryRepository categories;
  late FakeTaskRepository repo;
  late ProviderContainer c;

  setUp(() {
    categories = FakeCategoryRepository(sampleCategories());
    repo = FakeTaskRepository(tasks: sampleTasks(), categories: categories);
    c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        currentUidProvider.overrideWithValue('u1'),
        authStateProvider.overrideWithValue(const AsyncData(AppUser(uid: 'u1'))),
        categoryRepositoryProvider.overrideWithValue(categories),
        taskRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    // autoDispose olmayan sağlayıcılar için dinleyici tutmak gerekmez ama visible için tutalım.
    c.listen(visibleTasksProvider, (_, _) {});
  });

  List<String> ids() => c.read(taskListProvider).value!.items.map((t) => t.id).toList();

  test('varsayılan kapsam tüm görevleri en yeniden eskiye getirir', () async {
    await c.read(taskListProvider.future);
    expect(ids(), ['t1', 't2', 't3', 't4']);
  });

  test('kategori seçilince alt kategoriler dahil edilir', () async {
    c.read(selectedScopeProvider.notifier).select(const TaskScope.category('work'));
    await c.read(taskListProvider.future);
    expect(repo.queries.last.includeSubcategories, isTrue);
    expect(ids(), ['t1', 't2']);
  });

  test('alt kategorisi olmayan kategoride includeSubcategories gönderilmez', () async {
    c.read(selectedScopeProvider.notifier).select(const TaskScope.category('personal'));
    await c.read(taskListProvider.future);
    expect(repo.queries.last.includeSubcategories, isFalse);
    expect(ids(), ['t3']);
  });

  test('kategorisiz ve durum filtresi', () async {
    c.read(selectedScopeProvider.notifier).select(const TaskScope.uncategorized());
    await c.read(taskListProvider.future);
    expect(ids(), ['t4']);

    c.read(selectedScopeProvider.notifier).select(const TaskScope.all());
    c.read(taskFilterProvider.notifier).setStatus(TaskStatus.done);
    await c.read(taskListProvider.future);
    expect(ids(), ['t3']);
  });

  test('setStatus iyimser uygulanır ve sunucu sonucuyla güncellenir', () async {
    await c.read(taskListProvider.future);
    final t1 = c.read(taskListProvider).value!.items.first;

    final pending = c.read(taskListProvider.notifier).setStatus(t1, TaskStatus.done);
    expect(c.read(taskListProvider).value!.items.first.status, TaskStatus.done, reason: 'iyimser');
    await pending;
    expect(repo.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.done);
    expect(c.read(taskListProvider).value!.items.first.completedAt, isNotNull);
  });

  test('setStatus hata verirse eski haline döner ve hatayı iletir', () async {
    await c.read(taskListProvider.future);
    final t1 = c.read(taskListProvider).value!.items.first;
    repo.failNext = const ApiException(statusCode: 500, code: 'INTERNAL', message: 'boom');

    await expectLater(c.read(taskListProvider.notifier).setStatus(t1, TaskStatus.done), throwsA(isA<ApiException>()));
    expect(c.read(taskListProvider).value!.items.first.status, TaskStatus.todo);
  });

  test('durum filtresi aktifken filtreye uymayan görev listeden çıkar', () async {
    c.read(taskFilterProvider.notifier).setStatus(TaskStatus.todo);
    await c.read(taskListProvider.future);
    expect(ids(), ['t1', 't4']);

    final t1 = c.read(taskListProvider).value!.items.first;
    await c.read(taskListProvider.notifier).setStatus(t1, TaskStatus.done);
    expect(ids(), ['t4']);
  });

  test('removeLocal / restoreLocal aynı konuma geri koyar', () async {
    await c.read(taskListProvider.future);
    final ctrl = c.read(taskListProvider.notifier);
    final t2 = c.read(taskListProvider).value!.items[1];

    final index = ctrl.removeLocal('t2');
    expect(index, 1);
    expect(ids(), ['t1', 't3', 't4']);
    ctrl.restoreLocal(t2, index);
    expect(ids(), ['t1', 't2', 't3', 't4']);
    expect(repo.tasks.length, 4, reason: 'sunucuya dokunulmadı');
  });

  test('loadMore sonraki sayfayı ekler', () async {
    repo.tasks
      ..clear()
      ..addAll([for (var i = 0; i < 60; i++) task('p$i', ageMinutes: i)]);
    c.invalidate(taskListProvider);
    await c.read(taskListProvider.future);
    expect(ids().length, 50);
    expect(c.read(taskListProvider).value!.hasMore, isTrue);

    await c.read(taskListProvider.notifier).loadMore();
    expect(ids().length, 60);
    expect(ids().toSet().length, 60, reason: 'tekrar eden kayıt yok');
    expect(c.read(taskListProvider).value!.hasMore, isFalse);
  });

  test('arama yüklenmiş görevleri başlık ve açıklamada filtreler', () async {
    await c.read(taskListProvider.future);
    c.read(taskFilterProvider.notifier).setSearch('HEDEF');
    expect(c.read(visibleTasksProvider).value!.map((t) => t.id), ['t1']);
    c.read(taskFilterProvider.notifier).setSearch('api');
    expect(c.read(visibleTasksProvider).value!.map((t) => t.id), ['t2']);
  });

  test('create sonrası liste yenilenir ve yeni görev en üstte', () async {
    await c.read(taskListProvider.future);
    await c.read(taskListProvider.notifier).create(const TaskDraft(title: 'Yeni'));
    expect(ids().first, startsWith('new-'));
    expect(ids().length, 5);
  });
}
