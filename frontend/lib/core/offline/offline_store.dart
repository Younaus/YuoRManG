import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

/// Kullanıcı bazlı (uid ile anahtarlanmış) yerel JSON deposu: çevrimdışı önbellek ve işlem kuyruğu.
class OfflineStore {
  OfflineStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'offline.v1';

  /// Bilinen tüm kayıt türleri (oturum kapatılınca hepsi silinir).
  static const keys = ['tasks', 'categories', 'queue', 'idmap'];

  String _key(String uid, String name) => '$_prefix.$uid.$name';

  Object? read(String uid, String name) {
    final raw = _prefs.getString(_key(uid, name));
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null; // bozuk kayıt: yok say
    }
  }

  bool has(String uid, String name) => _prefs.containsKey(_key(uid, name));

  Future<void> write(String uid, String name, Object? value) => _prefs.setString(_key(uid, name), jsonEncode(value));

  /// Oturum kapatılınca: kullanıcının önbelleği ve bekleyen işlemleri silinir.
  Future<void> clearUser(String uid) async {
    for (final name in keys) {
      await _prefs.remove(_key(uid, name));
    }
  }
}

final offlineStoreProvider = Provider<OfflineStore>((ref) => OfflineStore(ref.watch(sharedPreferencesProvider)));
