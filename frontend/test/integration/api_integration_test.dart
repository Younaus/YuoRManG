@Tags(['integration'])
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/config/app_config.dart';
import 'package:yourmang/core/network/api_exception.dart';
import 'package:yourmang/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:yourmang/features/categories/data/repositories/category_repository_impl.dart';
import 'package:yourmang/features/categories/domain/repositories/category_repository.dart';
import 'package:yourmang/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:yourmang/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:yourmang/features/tasks/domain/entities/task_draft.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

/// Gerçek backend'e (emülatör) karşı DTO/sorgu/hata eşleşmesini doğrular.
/// Önce: cd backend && npm run serve
void main() {
  late TaskRepositoryImpl tasks;
  late CategoryRepositoryImpl categories;

  setUpAll(() async {
    // flutter test varsayılan platformu Android kabul eder (→ 10.0.2.2). Testler host makinede koşar.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final authUrl = 'http://${AppConfig.emulatorHost}:${AppConfig.authEmulatorPort}'
        '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key';
    final signUp = await Dio().post<Map<String, dynamic>>(authUrl, data: {
      'email': 'flutter-it-${DateTime.now().microsecondsSinceEpoch}@test.dev',
      'password': 'secret123',
      'returnSecureToken': true,
    });
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: {'Authorization': 'Bearer ${signUp.data!['idToken']}'},
      contentType: Headers.jsonContentType,
    ));
    tasks = TaskRepositoryImpl(TaskRemoteDataSource(dio));
    categories = CategoryRepositoryImpl(CategoryRemoteDataSource(dio));
  });

  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  test('kategori ağacı + görev CRUD + filtreler gerçek API ile uyumlu', () async {
    final work = await categories.create(name: 'İş', color: '#4F46E5');
    final projects = await categories.create(name: 'Projeler', parentId: work.id);

    final tree = await categories.getTree();
    expect(tree.roots.single.name, 'İş');
    expect(tree.roots.single.children.single.id, projects.id);
    expect(tree.pathTo(projects.id).map((c) => c.name), ['İş', 'Projeler']);

    final due = DateTime(2026, 12, 1, 23, 59); // yerel saat
    final created = await tasks.create(TaskDraft(
      title: 'Entegrasyon',
      description: 'satır 1\nsatır 2',
      status: TaskStatus.inProgress,
      dueDate: due,
      categoryId: projects.id,
    ));
    expect(created.status, TaskStatus.inProgress);
    expect(created.dueDate, due, reason: 'UTC gidiş-dönüşte yerel saat korunur');
    expect(created.categoryId, projects.id);
    final loose = await tasks.create(const TaskDraft(title: 'Kategorisiz'));

    final inWork = await tasks.list(TaskQuery(scope: TaskScope.category(work.id), includeSubcategories: true));
    expect(inWork.items.map((t) => t.id), [created.id]);
    final onlyWork = await tasks.list(TaskQuery(scope: TaskScope.category(work.id)));
    expect(onlyWork.items, isEmpty);
    final uncategorized = await tasks.list(const TaskQuery(scope: TaskScope.uncategorized()));
    expect(uncategorized.items.map((t) => t.id), [loose.id]);

    final page1 = await tasks.list(const TaskQuery(limit: 1));
    expect(page1.items.single.id, loose.id);
    expect(page1.nextCursor, isNotNull);
    final page2 = await tasks.list(TaskQuery(limit: 1, cursor: page1.nextCursor));
    expect(page2.items.single.id, created.id);
    expect(page2.nextCursor, isNull);

    final done = await tasks.setStatus(created.id, TaskStatus.done);
    expect(done.completedAt, isNotNull);
    final byStatus = await tasks.list(const TaskQuery(status: TaskStatus.done, sort: TaskSort.dueDate));
    expect(byStatus.items.map((t) => t.id), [created.id]);

    final edited = await tasks.update(
      created.id,
      const TaskDraft(title: 'Düzenlendi', status: TaskStatus.todo, dueDate: null, categoryId: null),
    );
    expect((edited.title, edited.dueDate, edited.categoryId, edited.completedAt), ('Düzenlendi', null, null, null));

    await tasks.setStatus(created.id, TaskStatus.inProgress);
    await tasks.update(created.id, TaskDraft(title: 'Düzenlendi', categoryId: projects.id));
    await categories.delete(work.id, strategy: CategoryDeleteStrategy.cascade);
    expect((await categories.getTree()).isEmpty, isTrue);
    final afterDelete = await tasks.list(const TaskQuery(scope: TaskScope.uncategorized()));
    expect(afterDelete.items.length, 2, reason: 'silinen kategorideki görev kategorisiz kalır');

    await tasks.delete(created.id);
    await tasks.delete(loose.id);
    expect((await tasks.list(const TaskQuery())).items, isEmpty);
  });

  test('kategori yeniden adlandırma ve taşıma gerçek API ile uyumlu', () async {
    final a = await categories.create(name: 'Taşı-A', color: '#4F46E5');
    final b = await categories.create(name: 'Taşı-B', parentId: a.id);
    final c = await categories.create(name: 'Taşı-C');

    // Yalnızca ad: renk ve konum korunur.
    final renamed = await categories.update(a.id, name: 'Taşı-A2');
    expect((renamed.name, renamed.color, renamed.parentId), ('Taşı-A2', '#4F46E5', null));

    // B'yi C'nin altına, sonra köke taşı (parentId: null gönderilir).
    expect((await categories.update(b.id, parent: ParentChange(c.id))).parentId, c.id);
    var tree = await categories.getTree();
    expect(tree.pathTo(b.id).map((x) => x.name), ['Taşı-C', 'Taşı-B']);
    expect((await categories.update(b.id, parent: const ParentChange(null))).parentId, isNull);

    // Döngü: C'yi kendi alt kategorisinin altına taşımak reddedilir.
    await categories.update(b.id, parent: ParentChange(c.id));
    await expectLater(
      categories.update(c.id, parent: ParentChange(b.id)),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
    );
    tree = await categories.getTree();
    expect(tree[c.id]!.parentId, isNull, reason: 'reddedilen taşıma hiçbir şeyi değiştirmez');

    for (final id in [a.id, c.id]) {
      await categories.delete(id);
    }
  });

  test('başlık araması (q) gerçek API ile uyumlu', () async {
    final a = await tasks.create(const TaskDraft(title: 'Bütçe planlaması', status: TaskStatus.done));
    final b = await tasks.create(const TaskDraft(title: 'Şirket gezisi'));
    Future<List<String>> search(String q, {TaskStatus? status}) async =>
        (await tasks.list(TaskQuery(search: q, status: status))).items.map((t) => t.title).toList();

    expect(await search('plan'), ['Bütçe planlaması']);
    expect(await search('BUTCE PLAN'), ['Bütçe planlaması'], reason: 'Türkçe karakter + çok kelime');
    expect(await search('sirket'), ['Şirket gezisi']);
    expect(await search('lamasi'), isEmpty, reason: 'kelime ortası eşleşmez');
    expect(await search('plan', status: TaskStatus.todo), isEmpty, reason: 'durum filtresiyle birlikte');

    await tasks.delete(a.id);
    await tasks.delete(b.id);
  });

  test('backend hataları ApiException olarak eşlenir', () async {
    await expectLater(
      tasks.create(const TaskDraft(title: '   ')),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR').having((e) => e.statusCode, 'status', 400)),
    );
    await expectLater(
      tasks.delete('does-not-exist'),
      throwsA(isA<ApiException>().having((e) => e.isNotFound, 'isNotFound', isTrue)),
    );
    await categories.create(name: 'Tekil');
    await expectLater(
      categories.create(name: 'tekil'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
    );
  });
}
