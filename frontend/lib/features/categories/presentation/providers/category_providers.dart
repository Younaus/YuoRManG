import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_store.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/presentation/providers/offline_sync_providers.dart';
import '../../data/datasources/category_remote_data_source.dart';
import '../../data/offline/category_offline_cache.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/offline_category_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';

/// Doğrudan canlı API.
final categoryRemoteRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(CategoryRemoteDataSource(ref.watch(dioProvider))),
);

/// Uygulamanın kullandığı depo: oturum açıkken ağaç çevrimdışı için önbelleklenir.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final remote = ref.watch(categoryRemoteRepositoryProvider);
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return remote;
  return OfflineCategoryRepository(
    remote: remote,
    cache: CategoryOfflineCache(ref.watch(offlineStoreProvider), uid),
    connectivity: ref.watch(connectivityServiceProvider),
    status: ref.read(offlineSyncProvider.notifier),
  );
});

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

  /// Ad / renk / konum günceller. Yeni üst kategori daraltılmışsa taşınan kategori görünsün diye açılır.
  Future<Category> updateCategory(String id, {String? name, String? color, ParentChange? parent}) async {
    final updated =
        await ref.read(categoryRepositoryProvider).update(id, name: name, color: color, parent: parent);
    final newParent = parent?.parentId;
    if (newParent != null) ref.read(collapsedCategoriesProvider.notifier).expand(newParent);
    ref.invalidateSelf();
    await future;
    return updated;
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

  void expand(String id) {
    if (state.contains(id)) state = {...state}..remove(id);
  }

  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}

final collapsedCategoriesProvider =
    NotifierProvider<CollapsedCategoriesController, Set<String>>(CollapsedCategoriesController.new);
