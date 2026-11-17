import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Giriş / kayıt formunun gönderim durumu (loading / error).
class SignInController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signIn({required String email, required String password}) => _run(
        () => ref.read(authRepositoryProvider).signInWithEmail(email: email, password: password),
      );

  Future<void> register({required String email, required String password, String? displayName}) => _run(
        () => ref
            .read(authRepositoryProvider)
            .registerWithEmail(email: email, password: password, displayName: displayName),
      );

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

final signInControllerProvider = AsyncNotifierProvider.autoDispose<SignInController, void>(SignInController.new);
