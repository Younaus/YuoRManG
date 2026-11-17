import 'package:dio/dio.dart';

import '../../../../core/network/api_guard.dart';
import '../models/task_dto.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TaskPageDto> list(Map<String, dynamic> params) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/tasks', queryParameters: params);
        return TaskPageDto.fromJson(res.data!);
      });

  Future<TaskDto> create(Map<String, dynamic> body) => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>('/tasks', data: body);
        return TaskDto.fromJson(res.data!);
      });

  Future<TaskDto> update(String id, Map<String, dynamic> body) => guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/tasks/$id', data: body);
        return TaskDto.fromJson(res.data!);
      });

  Future<void> delete(String id) => guardApi(() async {
        await _dio.delete<void>('/tasks/$id');
      });
}
