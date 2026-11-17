import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/brand.dart';
import '../../domain/entities/auth_failure.dart';
import '../controllers/sign_in_controller.dart';

/// E-posta/şifre ile giriş ve kayıt. Başarılı girişte yönlendirmeyi router yapar.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(signInControllerProvider.notifier);
    if (_isRegister) {
      await controller.register(email: _email.text, password: _password.text, displayName: _name.text);
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final isLoading = state.isLoading;
    final error = state.error;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogoMark(size: 52)),
                        const SizedBox(height: 16),
                        Text(
                          _isRegister ? 'Hesap oluştur' : 'Tekrar hoş geldiniz',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRegister ? 'Görevlerinizi düzenlemeye başlayın.' : 'Devam etmek için giriş yapın.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        if (_isRegister) ...[
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(labelText: 'Ad Soyad'),
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          key: const Key('signIn.email'),
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'E-posta'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'E-posta gerekli';
                            if (!value.contains('@')) return 'Geçerli bir e-posta girin';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('signIn.password'),
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          autofillHints: [_isRegister ? AutofillHints.newPassword : AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Şifre gerekli';
                            if (_isRegister && v!.length < 6) return 'En az 6 karakter';
                            return null;
                          },
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: error is AuthFailure ? error.message : 'Beklenmeyen bir hata oluştu.'),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('signIn.submit'),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(_isRegister ? 'Kayıt ol' : 'Giriş yap'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  ref.invalidate(signInControllerProvider);
                                  setState(() => _isRegister = !_isRegister);
                                },
                          child: Text(_isRegister ? 'Zaten hesabınız var mı? Giriş yapın' : 'Hesabınız yok mu? Kayıt olun'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
        ],
      ),
    );
  }
}
