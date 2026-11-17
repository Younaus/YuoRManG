import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/router/app_router.dart';
import 'package:yourmang/core/router/app_routes.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';

void main() {
  const user = AppUser(uid: 'u1', email: 'a@b.c');
  const loading = AsyncLoading<AppUser?>();
  const signedOut = AsyncData<AppUser?>(null);
  const signedIn = AsyncData<AppUser?>(user);
  Uri u(String s) => Uri.parse(s);

  group('resolveRedirect', () {
    test('auth yüklenirken splash\'e gider ve hedefi korur', () {
      expect(resolveRedirect(loading, u('/categories')), '/splash?from=%2Fcategories');
      expect(resolveRedirect(loading, u('/tasks')), AppRoutes.splash);
      expect(resolveRedirect(loading, u('/splash')), isNull);
    });

    test('oturum yokken korumalı sayfa → giriş', () {
      expect(resolveRedirect(signedOut, u('/settings')), '/sign-in?from=%2Fsettings');
      expect(resolveRedirect(signedOut, u('/tasks')), AppRoutes.signIn);
      expect(resolveRedirect(signedOut, u('/sign-in')), isNull);
    });

    test('splash → giriş geçişinde from korunur', () {
      expect(resolveRedirect(signedOut, u('/splash?from=%2Fsettings')), '/sign-in?from=%2Fsettings');
    });

    test('oturum açıkken giriş sayfası → from veya ana sayfa', () {
      expect(resolveRedirect(signedIn, u('/sign-in')), AppRoutes.home);
      expect(resolveRedirect(signedIn, u('/sign-in?from=%2Fcategories')), '/categories');
      expect(resolveRedirect(signedIn, u('/splash')), AppRoutes.home);
    });

    test('from ile dış adrese veya public sayfaya yönlendirme yapılmaz', () {
      expect(resolveRedirect(signedIn, u('/sign-in?from=https%3A%2F%2Fevil.com')), AppRoutes.home);
      expect(resolveRedirect(signedIn, u('/sign-in?from=%2F%2Fevil.com')), AppRoutes.home);
      expect(resolveRedirect(signedIn, u('/sign-in?from=%2Fsign-in')), AppRoutes.home);
    });

    test('oturum açıkken korumalı sayfada kalınır', () {
      expect(resolveRedirect(signedIn, u('/settings')), isNull);
    });

    test('auth akışı hata verirse oturumsuz sayılır → giriş', () {
      final failed = AsyncError<AppUser?>(Exception('stream failed'), StackTrace.empty);
      expect(resolveRedirect(failed, u('/tasks')), AppRoutes.signIn);
    });
  });
}
