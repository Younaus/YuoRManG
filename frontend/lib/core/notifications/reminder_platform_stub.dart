import 'reminder_service.dart';

/// Web: cihaz içi hatırlatma yok.
Future<ReminderService> createReminderService() async => const NoopReminderService();
