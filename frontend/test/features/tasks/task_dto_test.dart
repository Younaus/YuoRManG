import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/features/tasks/data/models/task_dto.dart';
import 'package:yourmang/features/tasks/domain/entities/task_draft.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';

void main() {
  test('backend görev JSON\'u entity\'ye çevrilir', () {
    final dto = TaskDto.fromJson({
      'id': 't1',
      'categoryId': null,
      'title': 'Başlık',
      'description': '',
      'status': 'in_progress',
      'dueDate': '2026-12-01T06:00:00.000Z',
      'completedAt': null,
      'createdAt': '2026-11-16T12:00:00.000Z',
      'updatedAt': '2026-11-16T12:00:00.000Z',
    });
    final task = dto.toEntity();
    expect(task.status, TaskStatus.inProgress);
    expect(task.dueDate!.toUtc(), DateTime.utc(2026, 12, 1, 6));
    expect(task.dueDate!.isUtc, isFalse, reason: 'yerel saate çevrilir');
    expect(task.categoryId, isNull);
  });

  test('taslak UTC ISO tarih ve API durum değeriyle gönderilir', () {
    final json = taskDraftToJson(
      TaskDraft(title: '  Başlık  ', status: TaskStatus.inProgress, dueDate: DateTime.utc(2026, 12, 1, 20, 59)),
    );
    expect(json['title'], 'Başlık');
    expect(json['status'], 'in_progress');
    expect(json['dueDate'], '2026-12-01T20:59:00.000Z');
    expect(json.containsKey('categoryId'), isTrue, reason: 'null da gönderilir (kategoriden çıkarma)');
  });

  group('taskQueryToParams', () {
    test('tüm görevler', () {
      expect(taskQueryToParams(const TaskQuery()), {'sort': 'createdAt', 'limit': 50});
    });
    test('kategorisiz + durum + cursor', () {
      expect(
        taskQueryToParams(
          const TaskQuery(scope: TaskScope.uncategorized(), status: TaskStatus.done, cursor: 'x', sort: TaskSort.dueDate),
        ),
        {'status': 'done', 'categoryId': 'none', 'sort': 'dueDate', 'limit': 50, 'cursor': 'x'},
      );
    });
    test('kategori + alt kategoriler', () {
      expect(
        taskQueryToParams(const TaskQuery(scope: TaskScope.category('c1'), includeSubcategories: true)),
        {'categoryId': 'c1', 'includeSubcategories': 'true', 'sort': 'createdAt', 'limit': 50},
      );
    });
    test('arama metni kırpılarak q olarak gönderilir; boşsa gönderilmez', () {
      expect(taskQueryToParams(const TaskQuery(search: '  plan  '))['q'], 'plan');
      expect(taskQueryToParams(const TaskQuery(search: '   ')).containsKey('q'), isFalse);
      expect(taskQueryToParams(const TaskQuery()).containsKey('q'), isFalse);
    });
  });
}
