import 'category.dart';

/// Ağaçta düz sırayla gezinirken her düğümün derinliğini taşır (dropdown, girintili liste için).
class FlatCategory {
  const FlatCategory(this.category, this.depth);

  final Category category;
  final int depth;
}

/// Kategori ağacı + sık kullanılan sorgular için önceden hesaplanmış indeksler.
class CategoryTree {
  CategoryTree(this.roots) {
    void visit(Category c, int depth) {
      _byId[c.id] = c;
      _flat.add(FlatCategory(c, depth));
      for (final child in c.children) {
        visit(child, depth + 1);
      }
    }

    for (final root in roots) {
      visit(root, 0);
    }
  }

  static final empty = CategoryTree(const []);

  final List<Category> roots;
  final Map<String, Category> _byId = {};
  final List<FlatCategory> _flat = [];

  bool get isEmpty => roots.isEmpty;
  int get length => _flat.length;

  Category? operator [](String? id) => id == null ? null : _byId[id];

  /// Ön-sıralı (pre-order) düz liste — ağaçtaki görsel sırayla aynı.
  List<FlatCategory> get flattened => List.unmodifiable(_flat);

  /// Kökten verilen kategoriye kadar olan yol (kendisi dahil).
  List<Category> pathTo(String id) {
    final path = <Category>[];
    final seen = <String>{};
    Category? cursor = _byId[id];
    while (cursor != null && seen.add(cursor.id)) {
      path.insert(0, cursor);
      cursor = _byId[cursor.parentId];
    }
    return path;
  }

  /// Kategori ve tüm alt kategorilerinin ID'leri.
  List<String> subtreeIds(String id) {
    final root = _byId[id];
    if (root == null) return const [];
    final ids = <String>[];
    void visit(Category c) {
      ids.add(c.id);
      c.children.forEach(visit);
    }

    visit(root);
    return ids;
  }

  /// `id` kategorisi `newParentId` altına taşınabilir mi? (kendisi veya kendi alt dalı olamaz)
  bool canMoveTo(String id, String? newParentId) {
    if (!_byId.containsKey(id)) return false;
    if (newParentId == null) return true;
    if (!_byId.containsKey(newParentId)) return false;
    return !subtreeIds(id).contains(newParentId);
  }

  /// Taşıma için geçerli üst kategori seçenekleri (kendisi ve alt dalı hariç).
  List<FlatCategory> moveTargetsFor(String id) {
    final excluded = subtreeIds(id).toSet();
    return _flat.where((f) => !excluded.contains(f.category.id)).toList(growable: false);
  }
}
