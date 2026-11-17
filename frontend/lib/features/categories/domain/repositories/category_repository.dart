import '../entities/category.dart';
import '../entities/category_tree.dart';

enum CategoryDeleteStrategy {
  /// Kategori ve tüm alt kategorileri silinir.
  cascade,

  /// Yalnızca kategori silinir; alt kategoriler bir üst seviyeye taşınır.
  lift,
}

/// Üst kategori değişikliği. `parentId == null` → en üst seviyeye taşı.
/// (Alanın hiç gönderilmemesi ile "köke taşı" ayrımı için ayrı tip.)
class ParentChange {
  const ParentChange(this.parentId);

  final String? parentId;
}

/// Hatalar `ApiException` olarak fırlatılır.
abstract interface class CategoryRepository {
  Future<CategoryTree> getTree();

  Future<Category> create({required String name, String? parentId, String? color});

  /// Yalnızca verilen alanlar güncellenir. Döngü oluşturan taşıma backend'de 400 ile reddedilir.
  Future<Category> update(String id, {String? name, String? color, ParentChange? parent});

  Future<void> delete(String id, {CategoryDeleteStrategy strategy = CategoryDeleteStrategy.cascade});
}
