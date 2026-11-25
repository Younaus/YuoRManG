import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';
import 'task_status.dart';

part 'task_query.freezed.dart';

/// Hangi görevlerin listelendiği (kenar çubuğundaki seçim).
@freezed
sealed class TaskScope with _$TaskScope {
  const factory TaskScope.all() = AllTasksScope;
  const factory TaskScope.uncategorized() = UncategorizedScope;
  const factory TaskScope.category(String categoryId) = CategoryScope;
}

@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    @Default(TaskScope.all()) TaskScope scope,
    TaskStatus? status,
    @Default(TaskSort.createdAt) TaskSort sort,
    /// Kategori seçiliyken alt kategorilerin görevleri de dahil edilsin mi.
    @Default(false) bool includeSubcategories,
    /// Başlıkta kelime öneki araması (sunucuda; büyük/küçük harf ve Türkçe karakter duyarsız).
    String? search,
    /// Bitiş tarihi aralığı (iki uç dahil). Verilirse tarihsiz görevler hariç kalır ve
    /// sonuçlar bitiş tarihine göre (yakından uzağa) sıralanır — takvim görünümü.
    DateTime? dueFrom,
    DateTime? dueTo,
    @Default(50) int limit,
    String? cursor,
  }) = _TaskQuery;
}

class TaskPage {
  const TaskPage({required this.items, this.nextCursor});

  final List<Task> items;
  final String? nextCursor;
}
