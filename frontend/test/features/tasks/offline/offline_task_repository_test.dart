import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourmang/core/network/api_exception.dart';
import 'package:yourmang/core/offline/offline_store.dart';
import 'package:yourmang/features/categories/data/offline/category_offline_cache.dart';
import 'package:yourmang/features/categories/data/repositories/offline_category_repository.dart';
import 'package:yourmang/features/tasks/data/offline/pending_task_op.dart';
import 'package:yourmang/features/tasks/data/offline/task_offline_cache.dart';
import 'package:yourmang/features/tasks/data/repositories/offline_task_repository.dart';
import 'package:yourmang/features/tasks/domain/entities/task_draft.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

import '../../../helpers/fake_offline.dart';
import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeCategoryRepository categoryRemote;
  late FakeTaskRepository remote;
  late OfflineStore store;
  late FakeConnectivity connectivity;
  late RecordingStatusSink sink;
  late TaskOfflineCache cache;
  late OfflineTaskRepository repo;
  late OfflineCategoryRepository categoryRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = OfflineStore(await SharedPreferences.getInstance());
    categoryRemote = FakeCategoryRepository(sampleCategories());
    remote = FakeTaskRepository(tasks: sampleTasks(), categories: categoryRemote);
    connectivity = FakeConnectivity();
    sink = RecordingStatusSink();
    cache = TaskOfflineCache(store, 'u1');
    repo = OfflineTaskRepository(
      remote: remote,
      cache: cache,
      categories: CategoryOfflineCache(store, 'u1'),
      connectivity: connectivity,
      status: sink,
      clock: () => DateTime(2026, 11, 25, 10),
    );
    categoryRepo = OfflineCategoryRepository(
      remote: categoryRemote,
      cache: CategoryOfflineCache(store, 'u1'),
      connectivity: connectivity,
      status: sink,
    );
  });

  void goOffline() {
    remote.offline = true;
    categoryRemote.offline = true;
  }

  List<String> ids(TaskPage page) => page.items.map((t) => t.id).toList();

  group('okuma', () {
    test('çevrimiçi yanıt önbelleğe yazılır; sunucuya ulaşılamayınca önbellekten sorgulanır', () async {
      final online = await repo.list(const TaskQuery());
      expect(sink.offline, isFalse);
      goOffline();

      final offline = await repo.list(const TaskQuery());
      expect(ids(offline), ids(online));
      expect(sink.offline, isTrue);
      expect(ids(await repo.list(const TaskQuery(status: TaskStatus.done))), ['t3'], reason: 'filtre yerelde');
      expect(ids(await repo.list(const TaskQuery(search: 'sprint'))), ['t1'], reason: 'arama yerelde');
    });

    test('bağlantı yokken ağ denenmez (zaman aşımı beklenmez)', () async {
      await repo.list(const TaskQuery());
      connectivity.online = false;
      remote.queries.clear();
      await repo.list(const TaskQuery());
      expect(remote.queries, isEmpty);
      expect(sink.offline, isTrue);
    });

    test('hiç önbellek yokken çevrimdışı: ağ hatası (boş liste değil)', () async {
      goOffline();
      await expectLater(
        repo.list(const TaskQuery()),
        throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
      );
    });

    test('ağ dışı hatalar önbelleğe düşmez', () async {
      await repo.list(const TaskQuery());
      remote.failNext = const ApiException(statusCode: 500, code: 'INTERNAL', message: 'boom');
      await expectLater(repo.list(const TaskQuery()), throwsA(isA<ApiException>()));
    });

    test('tam sonuç gelince başka cihazda silinen görev önbellekten çıkar; aramada çıkarılmaz', () async {
      await repo.list(const TaskQuery());
      remote.tasks.removeWhere((t) => t.id == 't1'); // diğer cihaz sildi

      await repo.list(const TaskQuery(search: 'market'));
      expect(cache.readSnapshot().containsKey('t1'), isTrue, reason: 'aramalı sonuç tam liste değildir');

      await repo.list(const TaskQuery());
      expect(cache.readSnapshot().containsKey('t1'), isFalse);
    });

    test('kategori ağacı önbelleklenir; çevrimdışıyken son ağaç döner', () async {
      final online = await categoryRepo.getTree();
      goOffline();
      final offline = await categoryRepo.getTree();
      expect(offline.flattened.map((f) => f.category.id), online.flattened.map((f) => f.category.id));
      expect(sink.offline, isTrue);
    });
  });

  group('yazma (çevrimdışı kuyruk)', () {
    setUp(() async {
      await repo.list(const TaskQuery()); // önbellek dolu
      goOffline();
    });

    test('yeni görev: geçici kimlikle hemen döner, kuyruğa yazılır, listede görünür', () async {
      final created = await repo.create(const TaskDraft(title: '  Çevrimdışı görev '));
      expect(isLocalTaskId(created.id), isTrue);
      expect(created.title, 'Çevrimdışı görev');
      expect(created.status, TaskStatus.inProgress);
      expect(cache.readQueue().single.kind, PendingTaskOpKind.create);
      expect(sink.pending, 1);
      expect(sink.flushRequests, 1);
      expect(ids(await repo.list(const TaskQuery())).first, created.id, reason: 'en yeni önce');
      expect(remote.writes, isEmpty);
    });

    test('tamamla / geri al ve sil kuyruğa yazılır, yerelde hemen uygulanır', () async {
      final done = await repo.setStatus('t1', TaskStatus.done);
      expect(done.status, TaskStatus.done);
      expect(done.completedAt, isNotNull);
      await repo.setStatus('t1', TaskStatus.todo); // geri al → tek işlem kalır
      await repo.delete('t4');

      expect(cache.readQueue().map((o) => o.toString()), [
        'PendingTaskOp(setStatus t1 → todo)',
        'PendingTaskOp(delete t4)',
      ]);
      final offlineList = ids(await repo.list(const TaskQuery()));
      expect(offlineList, isNot(contains('t4')));
    });

    test('çevrimdışı oluşturulan görev düzenlenebilir; sunucudaki görev düzenlenemez', () async {
      final created = await repo.create(const TaskDraft(title: 'Taslak'));
      final edited = await repo.update(created.id, const TaskDraft(title: 'Taslak v2', status: TaskStatus.todo));
      expect(edited.title, 'Taslak v2');
      expect(cache.readQueue().single.task!.title, 'Taslak v2');

      await expectLater(
        repo.update('t1', const TaskDraft(title: 'x')),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'OFFLINE')),
      );
    });

    test('kuyruk doluyken çevrimiçi olunsa da yeni işlem sıraya girer (sıra korunur)', () async {
      await repo.setStatus('t1', TaskStatus.done);
      remote.offline = false;
      await repo.setStatus('t2', TaskStatus.done);
      expect(remote.writes, isEmpty, reason: 'önce bekleyen işlemler gönderilmeli');
      expect(cache.readQueue().length, 2);
    });

    test('kuyruk varken gelen çevrimiçi liste bekleyen işlemleri yansıtır', () async {
      final created = await repo.create(const TaskDraft(title: 'Bekleyen'));
      await repo.setStatus('t1', TaskStatus.done);
      remote.offline = false;

      final page = await repo.list(const TaskQuery());
      expect(page.items.map((t) => t.id), contains(created.id));
      expect(page.items.firstWhere((t) => t.id == 't1').status, TaskStatus.done);
      expect(remote.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.todo, reason: 'henüz gönderilmedi');
    });
  });
}
