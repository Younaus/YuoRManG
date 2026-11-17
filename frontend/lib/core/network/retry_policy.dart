import 'api_exception.dart';

/// Riverpod 3 başarısız sağlayıcıları otomatik tekrar dener. 4xx hataları tekrar denemenin
/// anlamı yok (doğrulama, yetki, bulunamadı); ağ/sunucu hatalarında 2 kez kısa beklemeyle dener.
Duration? appProviderRetry(int retryCount, Object error) {
  if (error is ApiException) {
    final status = error.statusCode;
    if (status != null && status < 500) return null;
  }
  if (retryCount >= 2) return null;
  return Duration(milliseconds: 500 * (retryCount + 1));
}
