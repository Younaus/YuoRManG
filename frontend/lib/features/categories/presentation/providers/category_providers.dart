import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/category_remote_data_source.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(CategoryRemoteDataSource(ref.watch(dioProvider))),
);

class CategoryTreeController extends AsyncNotifier<CategoryTree> {
  @override
  Future<CategoryTree> build() async {
    if (ref.watch(currentUidProvider) == null) return CategoryTree.empty;
    return ref.watch(categoryRepositoryProvider).getTree();
  }

  Future<Category> create({required String name, String? parentId, String? color}) async {
    final created = await ref.read(categoryRepositoryProvider).create(name: name, parentId: parentId, color: color);
    ref.invalidateSelf();
    await future;
    return created;
  }

  /// Silinen kategorilerdeki görevler backend'de kategorisiz hale gelir.
  Future<void> delete(String id, {CategoryDeleteStrategy strategy = CategoryDeleteStrategy.cascade}) async {
    await ref.read(categoryRepositoryProvider).delete(id, strategy: strategy);
    ref.invalidateSelf();
    await future;
  }
}

final categoryTreeProvider = AsyncNotifierProvider<CategoryTreeController, CategoryTree>(CategoryTreeController.new);

/// Ağaçta daraltılmış (kapalı) düğümler. Varsayılan: hepsi açık.
class CollapsedCategoriesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}

final collapsedCategoriesProvider =
    NotifierProvider<CollapsedCategoriesController, Set<String>>(CollapsedCategoriesController.new);
