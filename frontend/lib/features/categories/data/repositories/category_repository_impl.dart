import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._remote);

  final CategoryRemoteDataSource _remote;

  @override
  Future<CategoryTree> getTree() async {
    final dtos = await _remote.getTree();
    return CategoryTree(dtos.map((d) => d.toEntity()).toList(growable: false));
  }

  @override
  Future<Category> create({required String name, String? parentId, String? color}) async {
    final dto = await _remote.create({'name': name.trim(), 'parentId': parentId, 'color': color});
    return dto.toEntity();
  }

  @override
  Future<void> delete(String id, {CategoryDeleteStrategy strategy = CategoryDeleteStrategy.cascade}) =>
      _remote.delete(id, strategy.name);
}
