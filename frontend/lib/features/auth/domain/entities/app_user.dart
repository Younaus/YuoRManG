import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Oturum açmış kullanıcı (Firebase'den bağımsız domain modeli).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) = _AppUser;

  const AppUser._();

  /// Görünen ad yoksa e-postanın @ öncesi kullanılır.
  String get label => displayName?.trim().isNotEmpty == true ? displayName! : (email?.split('@').first ?? 'Kullanıcı');

  String get initials {
    final parts = label.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCode(parts.first.runes.first);
    final last = parts.length > 1 ? String.fromCharCode(parts.last.runes.first) : '';
    return (first + last).toUpperCase();
  }
}
