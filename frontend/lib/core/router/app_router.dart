import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../layout/app_shell.dart';
import '../widgets/not_found_page.dart';
import 'app_routes.dart';

/// Oturum durumuna göre yönlendirme kararı (saf fonksiyon — test edilebilir).
///
/// - Oturum bilgisi henüz yüklenmediyse → splash
/// - Oturum yoksa ve korumalı sayfadaysa → giriş (`from` ile dönülecek yer korunur)
/// - Oturum varsa ve giriş/splash sayfasındaysa → `from` veya ana sayfa
@visibleForTesting
String? resolveRedirect(AsyncValue<AppUser?> auth, Uri uri) {
  final path = uri.path;
  final isPublic = AppRoutes.public.contains(path);
  final from = uri.queryParameters['from'];

  if (auth.isLoading && !auth.hasValue) {
    return path == AppRoutes.splash ? null : _withFrom(AppRoutes.splash, uri);
  }

  final loggedIn = auth.value != null;
  if (!loggedIn) {
    if (path == AppRoutes.signIn) return null;
    return path == AppRoutes.splash
        ? Uri(path: AppRoutes.signIn, queryParameters: from == null ? null : {'from': from}).toString()
        : _withFrom(AppRoutes.signIn, uri);
  }

  if (isPublic) return _safeReturnTarget(from) ?? AppRoutes.home;
  return null;
}

/// `from` yalnızca uygulama içi, korumalı bir yol ise kabul edilir (açık yönlendirme koruması).
/// `https://x` veya `//x` gibi şema/host içeren adresler reddedilir.
String? _safeReturnTarget(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
  final target = Uri.tryParse(from);
  if (target == null || target.hasScheme || target.hasAuthority) return null;
  if (AppRoutes.public.contains(target.path)) return null;
  return from;
}

String _withFrom(String target, Uri current) {
  final isHome = current.path == '/' || current.path == AppRoutes.home;
  return Uri(path: target, queryParameters: isHome ? null : {'from': current.toString()}).toString();
}

final routerProvider = Provider<GoRouter>((ref) {
  // Auth değişince GoRouter redirect'i yeniden değerlendirsin diye Listenable köprüsü.
  final authListenable = ValueNotifier<AsyncValue<AppUser?>>(const AsyncLoading());
  ref.listen(authStateProvider, (_, next) => authListenable.value = next, fireImmediately: true);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authListenable,
    redirect: (context, state) => resolveRedirect(authListenable.value, state.uri),
    errorBuilder: (context, state) => NotFoundPage(location: state.uri.toString()),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        // Sıra core/router/app_destinations.dart ile aynı olmalı.
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.tasks, builder: (_, _) => const TasksPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.calendar, builder: (_, _) => const CalendarPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.categories, builder: (_, _) => const CategoriesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage())],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authListenable.dispose();
  });
  return router;
});
