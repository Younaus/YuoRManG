import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/theme/theme_mode_controller.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/auth/presentation/pages/sign_in_page.dart';
import 'package:yourmang/features/tasks/presentation/pages/tasks_page.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('oturum yoksa giriş sayfası açılır', (tester) async {
    await tester.pumpApp(auth: FakeAuthRepository());
    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('hatalı şifre hata mesajı gösterir, doğru şifre görevlere yönlendirir', (tester) async {
    await tester.pumpApp(auth: FakeAuthRepository());

    await tester.enterText(find.byKey(const Key('signIn.email')), 'ali@test.dev');
    await tester.enterText(find.byKey(const Key('signIn.password')), 'wrong');
    await tester.tap(find.byKey(const Key('signIn.submit')));
    await tester.pumpAndSettle();
    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signIn.password')), FakeAuthRepository.validPassword);
    await tester.tap(find.byKey(const Key('signIn.submit')));
    await tester.pumpAndSettle();
    expect(find.byType(TasksPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('sekmeler arası geçiş, tema değişimi ve çıkış', (tester) async {
    final prefs = await tester.pumpApp(
      auth: FakeAuthRepository(initialUser: const AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli')),
    );
    expect(find.byType(TasksPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Ali Veli'), findsOneWidget);
    expect(find.text('AV'), findsOneWidget);

    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(Scaffold).last)).brightness, Brightness.dark);
    expect(prefs.getString(ThemeModeController.storageKey), 'dark');

    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  });
}
