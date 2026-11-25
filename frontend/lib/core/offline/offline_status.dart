/// Çevrimdışı katmanın (repository'ler) durum bildirdiği arayüz; `OfflineSyncController` uygular.
abstract interface class OfflineStatusSink {
  /// Bir ağ isteği başarılı oldu.
  void reportOnline();

  /// Sunucuya ulaşılamadı; önbellekten gösteriliyor.
  void reportOffline();

  /// Bekleyen işlem sayısı değişti.
  void reportPending(int count);

  /// Kuyrukta işlem var ve bağlantı olabilir: kısa süre içinde göndermeyi dene.
  void requestFlush();
}

/// Bildirimleri yok sayar (oturum yokken / testlerde).
class NoopOfflineStatusSink implements OfflineStatusSink {
  const NoopOfflineStatusSink();

  @override
  void reportOnline() {}

  @override
  void reportOffline() {}

  @override
  void reportPending(int count) {}

  @override
  void requestFlush() {}
}
