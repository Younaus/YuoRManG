import 'package:dio/dio.dart';

/// Backend'in `{ error: { code, message, details } }` hata formatının istemci karşılığı.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(code: timeoutCode, message: 'Sunucu yanıt vermedi. Lütfen tekrar deneyin.');
      case DioExceptionType.connectionError:
        return const ApiException(code: networkErrorCode, message: 'Sunucuya bağlanılamadı. Bağlantınızı kontrol edin.');
      case DioExceptionType.cancel:
        return const ApiException(code: 'CANCELLED', message: 'İstek iptal edildi.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final err = data['error'] as Map<String, dynamic>;
      return ApiException(
        statusCode: status,
        code: err['code'] as String? ?? 'UNKNOWN',
        message: err['message'] as String? ?? 'Beklenmeyen bir hata oluştu.',
        details: err['details'],
      );
    }
    return ApiException(statusCode: status, code: 'UNKNOWN', message: 'Beklenmeyen bir hata oluştu ($status).');
  }

  final String code;
  final String message;
  final int? statusCode;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => code == 'VALIDATION_ERROR';

  /// Sunucuya hiç ulaşılamadı (bağlantı yok / zaman aşımı) — çevrimdışı moda geçmek için.
  bool get isNetworkError => code == networkErrorCode || code == timeoutCode;

  static const networkErrorCode = 'NETWORK_ERROR';
  static const timeoutCode = 'TIMEOUT';

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}
