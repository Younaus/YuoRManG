import 'package:dio/dio.dart';

import '../../../../core/network/api_guard.dart';
import '../models/category_dto.dart';

class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CategoryDto>> getTree() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/categories/tree');
        final items = res.data!['items'] as List<dynamic>;
        return items.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<CategoryDto> create(Map<String, dynamic> body) => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>('/categories', data: body);
        return CategoryDto.fromJson(res.data!);
      });

  Future<CategoryDto> update(String id, Map<String, dynamic> body) => guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/categories/$id', data: body);
        return CategoryDto.fromJson(res.data!);
      });

  Future<void> delete(String id, String strategy) => guardApi(() async {
        await _dio.delete<void>('/categories/$id', queryParameters: {'strategy': strategy});
      });
}
