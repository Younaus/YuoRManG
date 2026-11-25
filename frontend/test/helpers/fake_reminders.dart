import 'package:yourmang/core/notifications/reminder_service.dart';

/// Yerel bildirimleri taklit eder: zamanlanmış olanları id → (başlık, an) olarak tutar.
class FakeReminderService implements ReminderService {
  FakeReminderService({this.permission = true, this.grantOnRequest = true});

  bool permission;
  bool grantOnRequest;
  int permissionRequests = 0;
  final Map<int, ({String title, String body, DateTime at})> scheduled = {};

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    permission = grantOnRequest;
    return permission;
  }

  @override
  Future<void> schedule(int id, {required String title, required String body, required DateTime at}) async =>
      scheduled[id] = (title: title, body: body, at: at);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> cancelAll() async => scheduled.clear();

  /// Başlığa göre zamanlanmış an (yoksa null).
  DateTime? atFor(String title) => scheduled.values.where((s) => s.title == title).firstOrNull?.at;
}
