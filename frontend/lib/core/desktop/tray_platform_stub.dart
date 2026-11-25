import 'tray_service.dart';

/// Web: sistem tepsisi yok.
Future<DesktopTrayService> createDesktopTrayService() async => const NoopDesktopTrayService();
