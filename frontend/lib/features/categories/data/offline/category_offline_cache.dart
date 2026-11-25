import '../../../../core/offline/offline_store.dart';
import '../../domain/entities/category_tree.dart';
import '../models/category_dto.dart';

/// Son başarılı `GET /categories/tree` yanıtı (kullanıcı bazlı).
class CategoryOfflineCache {
  CategoryOfflineCache(this._store, this.uid);

  final OfflineStore _store;
  final String uid;

  static const _name = 'categories';

  CategoryTree? readTree() {
    final raw = _store.read(uid, _name);
    if (raw is! List) return null;
    try {
      return CategoryTree(
        raw.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>).toEntity()).toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeTree(CategoryTree tree) => _store.write(uid, _name, tree.roots.map(categoryToJson).toList());
}
