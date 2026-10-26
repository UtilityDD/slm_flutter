import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(tr(bn, 'লগইন', 'Log in')),
      ),
      body: SlmBackdrop(
        child: ListView(
          padding: shellScrollPadding(context, left: 20, top: 12, right: 20, extraBottom: 12),
          children: [
            Text(
              tr(bn, 'ফোন বা ইমেল দিয়ে ঢুকুন', 'Sign in with your account'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: tr(bn, 'ইমেল', 'Email'),
                filled: true,
                fillColor: const Color(0xE6FFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr(bn, 'পাসওয়ার্ড', 'Password'),
                filled: true,
                fillColor: const Color(0xE6FFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(auth.errorMessage!, style: const TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final ok = await ref.read(authProvider.notifier).login(_email.text, _password.text);
                      if (ok && context.mounted) Navigator.of(context).pop();
                    },
              child: auth.isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(tr(bn, 'ঢুকুন', 'Sign in')),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).continueAsGuest();
                Navigator.of(context).pop();
              },
              child: Text(tr(bn, 'অতিথি হিসেবে দেখুন', 'Continue as guest')),
            ),
          ],
        ),
      ),
    );
  }
}
