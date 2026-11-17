import '../entities/category.dart';
import '../entities/category_tree.dart';

enum CategoryDeleteStrategy {
  /// Kategori ve tüm alt kategorileri silinir.
  cascade,

  /// Yalnızca kategori silinir; alt kategoriler bir üst seviyeye taşınır.
  lift,
}

/// Hatalar `ApiException` olarak fırlatılır.
abstract interface class CategoryRepository {
  Future<CategoryTree> getTree();

  Future<Category> create({required String name, String? parentId, String? color});

  Future<void> delete(String id, {CategoryDeleteStrategy strategy = CategoryDeleteStrategy.cascade});
}
