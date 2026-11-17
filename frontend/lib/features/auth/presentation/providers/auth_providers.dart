import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
);

/// Oturum durumu — router yönlendirmeleri ve kullanıcı bilgisi bunu dinler.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Oturumdaki kullanıcının uid'i. Veri sağlayıcıları bunu izler; kullanıcı değişince
/// (çıkış / başka hesapla giriş) önceki kullanıcının verisi otomatik temizlenir.
final currentUidProvider = Provider<String?>((ref) => ref.watch(authStateProvider.select((s) => s.value?.uid)));
