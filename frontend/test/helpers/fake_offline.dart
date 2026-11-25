import 'dart:async';
import 'dart:convert';

import 'package:yourmang/core/offline/connectivity_service.dart';
import 'package:yourmang/core/offline/offline_status.dart';
import 'package:yourmang/features/categories/data/models/category_dto.dart';
import 'package:yourmang/features/categories/domain/entities/category_tree.dart';
import 'package:yourmang/features/tasks/data/models/task_dto.dart';
import 'package:yourmang/features/tasks/domain/entities/task.dart';

/// Kontrol edilebilir ağ bağlantısı (connectivity_plus yerine).
class FakeConnectivity implements ConnectivityService {
  FakeConnectivity({this.online = true});

  bool online;
  final _changes = StreamController<bool>.broadcast();

  /// Bağlantıyı değiştirir ve olayı yayınlar.
  void set({required bool online}) {
    this.online = online;
    _changes.add(online);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;
}

/// Repository birim testleri için durum bildirimlerini kaydeder.
class RecordingStatusSink implements OfflineStatusSink {
  bool? offline;
  int pending = 0;
  int flushRequests = 0;

  @override
  void reportOnline() => offline = false;

  @override
  void reportOffline() => offline = true;

  @override
  void reportPending(int count) => pending = count;

  @override
  void requestFlush() => flushRequests++;
}

/// "Uygulama daha önce çevrimiçi açılmıştı" — SharedPreferences'a hazır önbellek değerleri.
Map<String, Object> seededOfflineCache(String uid, {required List<Task> tasks, required CategoryTree tree}) => {
  'offline.v1.$uid.tasks': jsonEncode({for (final t in tasks) t.id: taskToJson(t)}),
  'offline.v1.$uid.categories': jsonEncode(tree.roots.map(categoryToJson).toList()),
};
