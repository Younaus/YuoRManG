import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// Hiyerarşik kategori düğümü (Adjacency List'ten kurulmuş ağaç).
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    String? parentId,
    /// '#RRGGBB'
    String? color,
    String? icon,
    @Default(0) int order,
    @Default(<Category>[]) List<Category> children,
  }) = _Category;
}
