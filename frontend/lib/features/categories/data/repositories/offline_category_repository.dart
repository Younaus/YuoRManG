import '../../../../core/network/api_exception.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_status.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';
import '../offline/category_offline_cache.dart';

/// Kategori ağacını önbellekler; sunucuya ulaşılamazsa son başarılı ağacı döner.
/// Kategori oluşturma/düzenleme/silme çevrimiçi gerektirir (hata mesajı gösterilir).
class OfflineCategoryRepository implements CategoryRepository {
  OfflineCategoryRepository({
    required this.remote,
    required this.cache,
    required this.connectivity,
    required this.status,
  });

  final CategoryRepository remote;
  final CategoryOfflineCache cache;
  final ConnectivityService connectivity;
  final OfflineStatusSink status;

  @override
  Future<CategoryTree> getTree() async {
    if (await connectivity.isOnline()) {
      try {
        final tree = await remote.getTree();
        status.reportOnline();
        await cache.writeTree(tree);
        return tree;
      } on ApiException catch (e) {
        if (!e.isNetworkError) rethrow;
      }
    }
    status.reportOffline();
    final cached = cache.readTree();
    if (cached == null) {
      throw const ApiException(
        code: ApiException.networkErrorCode,
        message: 'Çevrimdışısınız ve bu cihazda kayıtlı kategori yok.',
      );
    }
    return cached;
  }

  @override
  Future<Category> create({required String name, String? parentId, String? color}) =>
      remote.create(name: name, parentId: parentId, color: color);

  @override
  Future<Category> update(String id, {String? name, String? color, ParentChange? parent}) =>
      remote.update(id, name: name, color: color, parent: parent);

  @override
  Future<void> delete(String id, {CategoryDeleteStrategy strategy = CategoryDeleteStrategy.cascade}) =>
      remote.delete(id, strategy: strategy);
}
