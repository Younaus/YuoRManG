import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Dio hatalarını `ApiException`'a çevirir; data source'lar tüm istekleri bununla sarar.
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
