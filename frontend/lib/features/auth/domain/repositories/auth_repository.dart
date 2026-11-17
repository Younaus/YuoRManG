import '../entities/app_user.dart';

/// Kimlik doğrulama sözleşmesi. Hatalar `AuthFailure` olarak fırlatılır.
abstract interface class AuthRepository {
  /// Oturum değişikliklerini yayınlar; çıkış yapılmışsa `null`.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<void> signInWithEmail({required String email, required String password});

  Future<void> registerWithEmail({required String email, required String password, String? displayName});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
