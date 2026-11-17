import 'dart:async';

import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/auth/domain/entities/auth_failure.dart';
import 'package:yourmang/features/auth/domain/repositories/auth_repository.dart';

/// Bellek içi sahte kimlik doğrulama — Firebase gerektirmez.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _user = initialUser;

  static const validPassword = 'secret123';

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  AppUser? get currentUser => _user;

  void _emit(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    if (password != validPassword) throw const AuthFailure('invalid-credential', 'E-posta veya şifre hatalı.');
    _emit(AppUser(uid: 'u1', email: email));
  }

  @override
  Future<void> registerWithEmail({required String email, required String password, String? displayName}) async =>
      _emit(AppUser(uid: 'u1', email: email, displayName: displayName));

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async => _emit(null);
}
