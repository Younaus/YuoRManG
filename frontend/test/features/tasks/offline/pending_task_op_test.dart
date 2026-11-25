import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/features/tasks/data/offline/pending_task_op.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  final local = task('local-1', title: 'Yerel', status: TaskStatus.inProgress);

  List<String> describe(List<PendingTaskOp> q) => [
    for (final op in q)
      switch (op.kind) {
        PendingTaskOpKind.create => 'create:${op.taskId}:${op.task!.status.apiValue}:${op.task!.title}',
        PendingTaskOpKind.setStatus => 'status:${op.taskId}:${op.status!.apiValue}',
        PendingTaskOpKind.delete => 'delete:${op.taskId}',
      },
  ];

  group('enqueuePendingOp (birleştirme)', () {
    test('yerel görevde durum değişikliği create kaydına katlanır', () {
      var q = enqueuePendingOp(const [], PendingTaskOp.create(local));
      q = enqueuePendingOp(q, const PendingTaskOp.setStatus('local-1', TaskStatus.done));
      expect(describe(q), ['create:local-1:done:Yerel']);
      expect(q.single.task!.completedAt, isNotNull);
    });

    test('yerel görevin düzenlenmiş hâli kaydı yerinde günceller', () {
      var q = enqueuePendingOp(const [], PendingTaskOp.create(local));
      q = enqueuePendingOp(q, const PendingTaskOp.setStatus('t9', TaskStatus.done));
      q = enqueuePendingOp(q, PendingTaskOp.create(local.copyWith(title: 'Yerel v2')));
      expect(describe(q), ['create:local-1:in_progress:Yerel v2', 'status:t9:done']);
    });

    test('yerel görevi silmek: hiçbir şey gönderilmez', () {
      var q = enqueuePendingOp(const [], PendingTaskOp.create(local));
      q = enqueuePendingOp(q, const PendingTaskOp.setStatus('t1', TaskStatus.done));
      q = enqueuePendingOp(q, const PendingTaskOp.delete('local-1'));
      expect(describe(q), ['status:t1:done']);
    });

    test('art arda durum değişikliğinde yalnızca sonuncusu kalır', () {
      var q = enqueuePendingOp(const [], const PendingTaskOp.setStatus('t1', TaskStatus.done));
      q = enqueuePendingOp(q, const PendingTaskOp.setStatus('t2', TaskStatus.done));
      q = enqueuePendingOp(q, const PendingTaskOp.setStatus('t1', TaskStatus.todo));
      expect(describe(q), ['status:t2:done', 'status:t1:todo']);
    });

    test('sunucudaki görevi silmek bekleyen durum değişikliklerini düşürür', () {
      var q = enqueuePendingOp(const [], const PendingTaskOp.setStatus('t1', TaskStatus.done));
      q = enqueuePendingOp(q, const PendingTaskOp.delete('t1'));
      expect(describe(q), ['delete:t1']);
    });
  });

  test('applyPendingOps: ekler, durum değiştirir, siler', () {
    final server = [task('t1'), task('t2'), task('t3')];
    final result = applyPendingOps(server, [
      PendingTaskOp.create(local),
      const PendingTaskOp.setStatus('t1', TaskStatus.done),
      const PendingTaskOp.delete('t2'),
      const PendingTaskOp.setStatus('yok', TaskStatus.done),
    ]);
    expect(
      {for (final t in result) t.id: t.status},
      {'t1': TaskStatus.done, 't3': TaskStatus.todo, 'local-1': TaskStatus.inProgress},
    );
  });

  test('JSON gidiş-dönüş', () {
    final ops = [
      PendingTaskOp.create(local.copyWith(dueDate: DateTime(2026, 12, 1, 23, 59), categoryId: 'work')),
      const PendingTaskOp.setStatus('t1', TaskStatus.done),
      const PendingTaskOp.delete('t2'),
    ];
    final back = ops.map((o) => PendingTaskOp.fromJson(o.toJson())).toList();
    expect(describe(back), describe(ops));
    expect(back.first.task!.dueDate, DateTime(2026, 12, 1, 23, 59));
    expect(back.first.task!.categoryId, 'work');
    expect(isLocalTaskId('local-1'), isTrue);
    expect(isLocalTaskId('abc'), isFalse);
  });
}
