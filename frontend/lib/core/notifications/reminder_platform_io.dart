import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// Android ve Windows'ta flutter_local_notifications; diğer platformlar ve `flutter test` no-op.
Future<ReminderService> createReminderService() async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isWindows) || Platform.environment.containsKey('FLUTTER_TEST')) {
    return const NoopReminderService();
  }
  final service = LocalNotificationReminderService._();
  try {
    await service._init();
    return service;
  } catch (e) {
    debugPrint('[reminders] bildirimler başlatılamadı: $e');
    return const NoopReminderService();
  }
}

class LocalNotificationReminderService implements ReminderService {
  LocalNotificationReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'task_reminders';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Görev hatırlatmaları',
      channelDescription: 'Bitiş tarihi gelen görevler için cihaz içi hatırlatmalar',
      importance: Importance.high,
      priority: Priority.high,
    ),
    windows: WindowsNotificationDetails(),
  );

  Future<void> _init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        windows: WindowsInitializationSettings(
          appName: 'YouRManG',
          appUserModelId: 'YouRManG.TaskManager.Desktop',
          guid: '6f0b5f0e-3c1d-4b8a-9e57-2a4c8d1f7b31',
        ),
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(int id, {required String title, required String body, required DateTime at}) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // Mutlak an (UTC): yerel saat dilimi veritabanı gerekmez.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details,
      // Kesin alarm izni (SCHEDULE_EXACT_ALARM) istemeden; Android birkaç dakika kaydırabilir.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
