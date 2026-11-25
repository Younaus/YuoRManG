import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_platform_stub.dart' if (dart.library.io) 'reminder_platform_io.dart' as platform;

/// Cihaz içi (sunucusuz) yerel bildirimler: görev hatırlatmaları.
/// Gerçek uygulama Android ve Windows'ta; Web ve testlerde [NoopReminderService].
abstract interface class ReminderService {
  bool get isSupported;

  /// Bildirim gösterme izni var mı (Android 13+ çalışma zamanı izni; Windows'ta her zaman).
  Future<bool> hasPermission();

  /// Sistem izin penceresini gösterir; verildiyse `true`.
  Future<bool> requestPermission();

  /// [at] anında bildirim zamanlar (aynı [id] varsa değiştirir).
  Future<void> schedule(int id, {required String title, required String body, required DateTime at});

  Future<void> cancel(int id);

  /// Bu uygulamanın zamanlanmış tüm bildirimlerini iptal eder.
  Future<void> cancelAll();
}

class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  bool get isSupported => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(int id, {required String title, required String body, required DateTime at}) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

/// `main()` içinde platform servisiyle override edilir.
Future<ReminderService> createReminderService() => platform.createReminderService();

final reminderServiceProvider = Provider<ReminderService>((ref) => const NoopReminderService());
