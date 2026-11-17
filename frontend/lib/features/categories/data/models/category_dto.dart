import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/category.dart';

part 'category_dto.g.dart';

/// `GET /categories/tree` düğümü (children özyinelemeli).
@JsonSerializable(createToJson: false)
class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    this.parentId,
    this.color,
    this.icon,
    this.order = 0,
    this.children = const [],
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => _$CategoryDtoFromJson(json);

  final String id;
  final String name;
  final String? parentId;
  final String? color;
  final String? icon;
  final int order;
  final List<CategoryDto> children;

  Category toEntity() => Category(
        id: id,
        name: name,
        parentId: parentId,
        color: color,
        icon: icon,
        order: order,
        children: children.map((c) => c.toEntity()).toList(growable: false),
      );
}
