import 'corner_window_service.dart';

/// Web: `dart:io` ve `window_manager` yok — köşe modu devre dışı.
Future<CornerWindowService> createCornerWindowService() async => const NoopCornerWindowService();
