import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/domain/local_task_query.dart';

import '../../../helpers/fake_repositories.dart';

/// Çevrimdışı sorgular backend ile aynı sonucu vermeli: sahte depo (backend kurallarıyla) ile karşılaştır.
void main() {
  final categories = FakeCategoryRepository(sampleCategories());
  final tree = categories.tree;
  final tasks = [
    ...sampleTasks(),
    task('t5', title: 'Bütçe planlaması', categoryId: 'projects', dueDate: DateTime(2026, 12, 3), ageMinutes: 4),
    task('t6', title: 'Şirket gezisi', status: TaskStatus.inProgress, dueDate: DateTime(2026, 11, 30), ageMinutes: 5),
  ];
  final remote = FakeTaskRepository(tasks: tasks, categories: categories);

  final queries = <String, TaskQuery>{
    'tümü': const TaskQuery(),
    'durum': const TaskQuery(status: TaskStatus.inProgress),
    'kategorisiz': const TaskQuery(scope: TaskScope.uncategorized()),
    'kategori (yalnız kendisi)': const TaskQuery(scope: TaskScope.category('work')),
    'kategori + alt kategoriler': const TaskQuery(scope: TaskScope.category('work'), includeSubcategories: true),
    'bitiş tarihine göre': const TaskQuery(sort: TaskSort.dueDate),
    'arama (Türkçe, çok kelime)': const TaskQuery(search: 'BUTCE PLAN'),
    'arama (kelime öneki)': const TaskQuery(search: 'sirk'),
    'arama (kelime ortası eşleşmez)': const TaskQuery(search: 'lamasi'),
  };

  for (final MapEntry(key: name, value: query) in queries.entries) {
    test('yerel sorgu = sunucu: $name', () async {
      final server = (await remote.list(query)).items.map((t) => t.id).toList();
      final local = applyLocalQuery(tasks, query, tree: tree).map((t) => t.id).toList();
      expect(local, server);
    });
  }

  test('titleMatchesSearch: büyük/küçük harf ve Türkçe karakter duyarsız', () {
    expect(titleMatchesSearch('İstanbul toplantısı', 'istanbul TOPL'), isTrue);
    expect(titleMatchesSearch('Çiçek sula', 'cicek'), isTrue);
    expect(titleMatchesSearch('Çiçek sula', 'ula'), isFalse);
  });
}
