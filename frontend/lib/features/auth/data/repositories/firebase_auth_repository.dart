import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signInWithEmail({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<void> registerWithEmail({required String email, required String password, String? displayName}) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        final name = displayName?.trim();
        if (name != null && name.isNotEmpty) await cred.user?.updateDisplayName(name);
      });

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  static AppUser? _map(User? u) => u == null
      ? null
      : AppUser(uid: u.uid, email: u.email, displayName: u.displayName, photoUrl: u.photoURL);

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code, _messageFor(e.code));
    }
  }

  static String _messageFor(String code) => switch (code) {
        'invalid-email' => 'Geçerli bir e-posta adresi girin.',
        'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'E-posta veya şifre hatalı.',
        'email-already-in-use' => 'Bu e-posta adresiyle zaten bir hesap var.',
        'weak-password' => 'Şifre en az 6 karakter olmalı.',
        'too-many-requests' => 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.',
        'network-request-failed' => 'Ağ bağlantısı kurulamadı.',
        _ => 'Kimlik doğrulama başarısız oldu ($code).',
      };
}
