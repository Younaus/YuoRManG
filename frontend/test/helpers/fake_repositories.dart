import 'package:yourmang/core/network/api_exception.dart';
import 'package:yourmang/features/categories/domain/entities/category.dart';
import 'package:yourmang/features/categories/domain/entities/category_tree.dart';
import 'package:yourmang/features/categories/domain/repositories/category_repository.dart';
import 'package:yourmang/features/tasks/domain/entities/task.dart';
import 'package:yourmang/features/tasks/domain/entities/task_draft.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/domain/repositories/task_repository.dart';

/// Bellek içi kategori deposu (düz liste → ağaç).
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([List<Category> flat = const []]) : _flat = [...flat];

  final List<Category> _flat;
  int _seq = 0;

  /// `getTree` çağrı sayısı (yenileme testleri için).
  int treeRequests = 0;

  CategoryTree get tree {
    List<Category> childrenOf(String? parentId) => _flat
        .where((c) => c.parentId == parentId)
        .map((c) => c.copyWith(children: childrenOf(c.id)))
        .toList();
    return CategoryTree(childrenOf(null));
  }

  @override
  Future<CategoryTree> getTree() async {
    treeRequests++;
    return tree;
  }

  @override
  Future<Category> create({required String name, String? parentId, String? color}) async {
    if (_flat.any((c) => c.parentId == parentId && c.name.toLowerCase() == name.toLowerCase())) {
      throw const ApiException(statusCode: 409, code: 'CONFLICT', message: 'duplicate');
    }
    final c = Category(id: 'c${++_seq}-new', name: name, parentId: parentId, color: color, order: _flat.length);
    _flat.add(c);
    return c;
  }

  /// Backend gibi: döngü → 400, aynı seviyede aynı ad → 409, taşınınca yeni seviyenin sonuna eklenir.
  @override
  Future<Category> update(String id, {String? name, String? color, ParentChange? parent}) async {
    final i = _flat.indexWhere((c) => c.id == id);
    final current = _flat[i];
    final newParent = parent != null ? parent.parentId : current.parentId;
    if (parent != null && !tree.canMoveTo(id, newParent)) {
      throw const ApiException(statusCode: 400, code: 'BAD_REQUEST', message: 'cycle');
    }
    final newName = name ?? current.name;
    if (_flat.any((c) => c.id != id && c.parentId == newParent && c.name.toLowerCase() == newName.toLowerCase())) {
      throw const ApiException(statusCode: 409, code: 'CONFLICT', message: 'duplicate');
    }
    return _flat[i] = current.copyWith(
      name: newName,
      color: color ?? current.color,
      parentId: newParent,
      order: parent != null ? _flat.length + 100 : current.order,
    );
  }

  @override
  Future<void> delete(String id, {CategoryDeleteStrategy strategy = CategoryDeleteStrategy.cascade}) async {
    final ids = tree.subtreeIds(id);
    if (strategy == CategoryDeleteStrategy.cascade) {
      _flat.removeWhere((c) => ids.contains(c.id));
    } else {
      final removed = _flat.firstWhere((c) => c.id == id);
      for (var i = 0; i < _flat.length; i++) {
        if (_flat[i].parentId == id) _flat[i] = _flat[i].copyWith(parentId: removed.parentId);
      }
      _flat.removeWhere((c) => c.id == id);
    }
  }
}

/// Bellek içi görev deposu: kapsam/durum filtresi, sıralama ve cursor sayfalaması backend gibi davranır.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<Task> tasks = const [], this.categories}) : tasks = [...tasks];

  final List<Task> tasks;
  final FakeCategoryRepository? categories;
  final List<TaskQuery> queries = [];
  int _seq = 0;

  /// Bir sonraki çağrıda fırlatılacak hata (tek seferlik).
  Object? failNext;

  void _maybeFail() {
    final e = failNext;
    if (e != null) {
      failNext = null;
      throw e;
    }
  }

  @override
  Future<TaskPage> list(TaskQuery query) async {
    queries.add(query);
    _maybeFail();
    Iterable<Task> result = tasks;
    if (query.status != null) result = result.where((t) => t.status == query.status);
    final search = query.search;
    if (search != null && search.trim().isNotEmpty) result = result.where((t) => _titleMatches(t.title, search));
    result = switch (query.scope) {
      AllTasksScope() => result,
      UncategorizedScope() => result.where((t) => t.categoryId == null),
      CategoryScope(:final categoryId) => () {
          final ids = query.includeSubcategories
              ? (categories?.tree.subtreeIds(categoryId) ?? [categoryId])
              : [categoryId];
          return result.where((t) => ids.contains(t.categoryId));
        }(),
    };
    final sorted = result.toList()
      ..sort((a, b) => query.sort == TaskSort.dueDate
          ? (a.dueDate ?? DateTime(0)).compareTo(b.dueDate ?? DateTime(0))
          : b.createdAt.compareTo(a.createdAt));
    final start = query.cursor == null ? 0 : sorted.indexWhere((t) => t.id == query.cursor) + 1;
    final page = sorted.skip(start).take(query.limit).toList();
    final hasMore = start + page.length < sorted.length;
    return TaskPage(items: page, nextCursor: hasMore ? page.last.id : null);
  }

  @override
  Future<Task> create(TaskDraft d) async {
    _maybeFail();
    final now = DateTime.now();
    final t = Task(
      id: 'new-${++_seq}',
      title: d.title,
      description: d.description,
      status: d.status,
      dueDate: d.dueDate,
      categoryId: d.categoryId,
      createdAt: now,
      updatedAt: now,
    );
    tasks.add(t);
    return t;
  }

  @override
  Future<Task> update(String id, TaskDraft d) async {
    _maybeFail();
    final i = tasks.indexWhere((t) => t.id == id);
    return tasks[i] = tasks[i].copyWith(
      title: d.title,
      description: d.description,
      status: d.status,
      dueDate: d.dueDate,
      categoryId: d.categoryId,
    );
  }

  @override
  Future<Task> setStatus(String id, TaskStatus status) async {
    _maybeFail();
    final i = tasks.indexWhere((t) => t.id == id);
    return tasks[i] = tasks[i].copyWith(status: status, completedAt: status == TaskStatus.done ? DateTime.now() : null);
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    tasks.removeWhere((t) => t.id == id);
  }
}

// --- Backend araması (utils/search.ts) ile aynı kurallar ------------------------
// Kelime öneki, yalnızca başlıkta; Türkçe büyük/küçük harf ve karakter duyarsız.

const _fold = {'ı': 'i', 'ş': 's', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'ç': 'c'};

String _normalize(String s) => s
    .replaceAll('I', 'ı')
    .replaceAll('İ', 'i')
    .toLowerCase()
    .split('')
    .map((ch) => _fold[ch] ?? ch)
    .join();

List<String> _words(String s) =>
    _normalize(s).split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((w) => w.isNotEmpty).toList();

bool _titleMatches(String title, String query) {
  final queryWords = _words(query);
  final titleWords = _words(title);
  return queryWords.every((q) => titleWords.any((t) => t.startsWith(q)));
}

// --- Örnek veri ---------------------------------------------------------------

final _base = DateTime(2026, 11, 10, 9);

Task task(
  String id, {
  String? title,
  String description = '',
  TaskStatus status = TaskStatus.todo,
  String? categoryId,
  DateTime? dueDate,
  int ageMinutes = 0,
}) {
  final created = _base.subtract(Duration(minutes: ageMinutes));
  return Task(
    id: id,
    title: title ?? 'Görev $id',
    description: description,
    status: status,
    categoryId: categoryId,
    dueDate: dueDate,
    createdAt: created,
    updatedAt: created,
  );
}

/// İş > Projeler > Alpha, Kişisel
List<Category> sampleCategories() => const [
      Category(id: 'work', name: 'İş', color: '#4F46E5'),
      Category(id: 'projects', name: 'Projeler', parentId: 'work', color: '#0EA5E9'),
      Category(id: 'alpha', name: 'Alpha', parentId: 'projects', color: '#10B981'),
      Category(id: 'personal', name: 'Kişisel', color: '#F43F5E', order: 1),
    ];

List<Task> sampleTasks() => [
      task('t1', title: 'Sprint planlaması', description: 'Hedefleri belirle\nikinci satır', categoryId: 'work'),
      task('t2', title: 'API dokümantasyonu', status: TaskStatus.inProgress, categoryId: 'alpha', ageMinutes: 1),
      task('t3', title: 'Market alışverişi', status: TaskStatus.done, categoryId: 'personal', ageMinutes: 2),
      task('t4', title: 'Kategorisiz not', ageMinutes: 3),
    ];
