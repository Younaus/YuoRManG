import '../../categories/domain/entities/category_tree.dart';
import 'entities/task.dart';
import 'entities/task_query.dart';
import 'entities/task_status.dart';

// Çevrimdışı modda `GET /tasks` sorgusunu önbellekteki görevlere yerelde uygular.
// Kurallar backend ile aynıdır (services/task.service.ts, utils/search.ts).

/// Görev [query]'nin kapsam / durum / arama filtresine uyuyor mu (sayfalama hariç).
bool taskMatchesQuery(Task task, TaskQuery query, {CategoryTree? tree}) {
  if (query.status != null && task.status != query.status) return false;
  if (query.dueFrom != null || query.dueTo != null) {
    final due = task.dueDate;
    if (due == null) return false;
    if (query.dueFrom != null && due.isBefore(query.dueFrom!)) return false;
    if (query.dueTo != null && due.isAfter(query.dueTo!)) return false;
  }
  final search = query.search?.trim();
  if (search != null && search.isNotEmpty && !titleMatchesSearch(task.title, search)) return false;
  return switch (query.scope) {
    AllTasksScope() => true,
    UncategorizedScope() => task.categoryId == null,
    CategoryScope(:final categoryId) =>
      query.includeSubcategories && tree != null
          ? tree.subtreeIds(categoryId).contains(task.categoryId)
          : task.categoryId == categoryId,
  };
}

/// Backend ile aynı sırada döner: en yeni önce, ya da bitiş tarihine göre (tarihsizler önce).
/// Tarih aralığı verilmişse her zaman bitiş tarihine göre.
List<Task> applyLocalQuery(Iterable<Task> tasks, TaskQuery query, {CategoryTree? tree}) {
  final result = tasks.where((t) => taskMatchesQuery(t, query, tree: tree)).toList();
  result.sort(
    (a, b) => sortsByDueDate(query)
        ? (a.dueDate ?? DateTime(0)).compareTo(b.dueDate ?? DateTime(0))
        : b.createdAt.compareTo(a.createdAt),
  );
  return result;
}

/// Backend: `sort=dueDate` ya da tarih aralığı verilmişse bitiş tarihine göre sıralanır.
bool sortsByDueDate(TaskQuery query) => query.sort == TaskSort.dueDate || query.dueFrom != null || query.dueTo != null;

// --- Başlık araması: kelime öneki; Türkçe büyük/küçük harf ve karakter duyarsız ------------------

const _fold = {'ı': 'i', 'ş': 's', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'ç': 'c'};

String _normalize(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase().split('').map((ch) => _fold[ch] ?? ch).join();

List<String> _words(String s) =>
    _normalize(s).split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((w) => w.isNotEmpty).toList();

/// Sorgudaki her kelime, başlıktaki bir kelimenin öneki mi ("BUTCE PLAN" → "Bütçe planlaması").
bool titleMatchesSearch(String title, String query) {
  final queryWords = _words(query);
  final titleWords = _words(title);
  return queryWords.every((q) => titleWords.any((t) => t.startsWith(q)));
}
