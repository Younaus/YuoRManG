import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Her isteğe Firebase ID token ekler. 401 alınırsa token'ı zorla yenileyip isteği bir kez tekrarlar.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._auth, this._dio);

  final FirebaseAuth _auth;
  final Dio _dio;

  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = _auth.currentUser;
    if (user != null) {
      // getIdToken süresi dolmuşsa kendisi yeniler; aksi halde önbellekteki token'ı döner.
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final user = _auth.currentUser;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (err.response?.statusCode != 401 || user == null || alreadyRetried) {
      return handler.next(err);
    }

    try {
      final freshToken = await user.getIdToken(true);
      final retry = err.requestOptions
        ..headers['Authorization'] = 'Bearer $freshToken'
        ..extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      handler.next(e);
    } on FirebaseAuthException {
      handler.next(err);
    }
  }
}
