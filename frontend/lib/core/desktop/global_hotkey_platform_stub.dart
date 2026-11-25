import 'global_hotkey_service.dart';

/// Web: sistem geneli kısayol yok.
Future<GlobalHotkeyService> createGlobalHotkeyService() async => const NoopGlobalHotkeyService();
