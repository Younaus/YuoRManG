/// Uygulama içi rota yolları — tek kaynak.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';

  // Ana kabuk (shell) içindeki sekmeler
  static const tasks = '/tasks';
  static const calendar = '/calendar';
  static const categories = '/categories';
  static const settings = '/settings';

  static const home = tasks;

  /// Oturum gerektirmeyen sayfalar.
  static const public = {splash, signIn};
}
