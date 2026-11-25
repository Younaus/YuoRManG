import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/config/app_config.dart';
import 'package:yourmang/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:yourmang/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:yourmang/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:yourmang/features/tasks/domain/entities/task_query.dart';

/// Android ve Windows aynı canlı API'ye, aynı yollarla gider; istemcide önbellek yoktur.
void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  /// Ağa çıkmadan istekleri kaydeden Dio (uygulamadaki dioProvider ile aynı baseUrl).
  (Dio, List<RequestOptions>) recordingDio() {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final path = options.uri.path;
          final Object data = switch ((options.method, path.endsWith('/tree'))) {
            ('GET', true) => {'items': <Object>[]},
            ('GET', false) => {'items': <Object>[], 'nextCursor': null},
            _ => {
              'id': 'c1',
              'name': 'Okul',
              'parentId': null,
              'color': null,
              'order': 0,
              'createdAt': '2026-11-25T09:00:00.000Z',
              'updatedAt': '2026-11-25T09:00:00.000Z',
            },
          };
          handler.resolve(Response(requestOptions: options, statusCode: 200, data: data));
        },
      ),
    );
    return (dio, requests);
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    test('${platform.name}: kategori listeleme/oluşturma ve görevler canlı /v1 uçlarına gider', () async {
      debugDefaultTargetPlatformOverride = platform;
      expect(AppConfig.apiBaseUrl, 'https://europe-west1-yourmang.cloudfunctions.net/api/v1');

      final (dio, requests) = recordingDio();
      final categories = CategoryRemoteDataSource(dio);
      await categories.getTree();
      await categories.getTree();
      await categories.create({'name': 'Okul', 'parentId': null, 'color': null});
      await TaskRepositoryImpl(TaskRemoteDataSource(dio)).list(const TaskQuery());

      expect(requests.map((r) => '${r.method} ${r.uri}'), [
        'GET https://europe-west1-yourmang.cloudfunctions.net/api/v1/categories/tree',
        'GET https://europe-west1-yourmang.cloudfunctions.net/api/v1/categories/tree',
        'POST https://europe-west1-yourmang.cloudfunctions.net/api/v1/categories',
        startsWith('GET https://europe-west1-yourmang.cloudfunctions.net/api/v1/tasks'),
      ], reason: 'her listeleme sunucuya gider (istemci önbelleği yok)');
    });
  }
}
