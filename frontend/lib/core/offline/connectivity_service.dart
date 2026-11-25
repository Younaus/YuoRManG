import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ağ bağlantısı durumu (Wi-Fi / mobil / ethernet var mı). Bağlantı "var" görünse bile
/// internet olmayabilir; asıl çevrimdışı kararı ağ isteği hatalarıyla da verilir.
abstract interface class ConnectivityService {
  /// En az bir ağ arayüzü bağlı mı.
  Future<bool> isOnline();

  /// Bağlantı değiştikçe: `true` = bağlı, `false` = hiçbir ağ yok.
  Stream<bool> get onlineChanges;
}

/// Varsayılan (testler): her zaman bağlı, hiç olay yok.
class AlwaysOnlineConnectivity implements ConnectivityService {
  const AlwaysOnlineConnectivity();

  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onlineChanges => const Stream.empty();
}

/// connectivity_plus (Android, Windows, Web).
class PlusConnectivityService implements ConnectivityService {
  PlusConnectivityService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _anyNetwork(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    try {
      return _anyNetwork(await _connectivity.checkConnectivity());
    } catch (_) {
      return true; // eklenti yoksa/hata verirse ağ isteğini denemeye devam et
    }
  }

  @override
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(_anyNetwork).distinct();
}

/// `main()` içinde [PlusConnectivityService] ile override edilir.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => const AlwaysOnlineConnectivity());
