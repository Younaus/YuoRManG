import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../firebase/firebase_providers.dart';
import 'auth_interceptor.dart';

/// Backend API'ye istek atan, kimlik doğrulamalı Dio örneği.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref.watch(firebaseAuthProvider), dio));
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestHeader: false, responseHeader: false, logPrint: (o) => debugPrint(o.toString())));
  }

  ref.onDispose(dio.close);
  return dio;
});
