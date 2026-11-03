import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'auth_provider.dart';
import 'google_mark.dart';

/// Kept for deep links / old routes. Prefer signing in from Settings.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && context.mounted) {
        Navigator.of(context).pop();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
              ShellSafeArea(
                child: Padding(
                  padding: shellScrollPadding(context, left: 24, top: 4, right: 24, extraBottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: SlmColors.ivory),
                          tooltip: tr(bn, 'ফিরে যান', 'Back'),
                        ),
                      ),
                      const Spacer(),
                      SlmText(
                        tr(bn, 'স্মার্টলাইনম্যান', 'SmartLineman'),
                        role: SlmTextRole.headline,
                        color: SlmColors.ivory,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      GoogleSignInButton(
                        bn: bn,
                        loading: auth.isLoading,
                        error: auth.errorMessage,
                        onPressed: auth.isLoading
                            ? null
                            : () => ref.read(authProvider.notifier).signInWithGoogle(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
