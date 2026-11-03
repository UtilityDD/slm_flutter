import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'auth_provider.dart';
import 'google_mark.dart';
import 'verify_gate.dart';
import 'verify_hold.dart';
import 'verify_tick.dart';

Future<void> showVerifySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VerifyInfo(),
  );
}

double _sheetBottom(BuildContext context) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboard > 0) return keyboard;
  final scoped = context.dependOnInheritedWidgetOfExactType<ShellDockScope>();
  return scoped?.bottomInset ?? MediaQuery.paddingOf(context).bottom;
}

class _VerifyInfo extends ConsumerWidget {
  const _VerifyInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final guest = !auth.isAuthenticated || auth.isGuest;
    final verified = linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final bottom = _sheetBottom(context);

    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && !next.isGuest && context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });

    final title = verified
        ? tr(bn, 'যাচাই হয়েছে', 'Verified')
        : tr(bn, 'যাচাই হয়নি', 'Not verified');
    final detail = verified
        ? tr(bn, 'আপনার অ্যাকাউন্ট যাচাই সম্পন্ন।', 'Your account is verified.')
        : guest
            ? tr(bn, 'লগইন করলে যাচাই স্থিতি দেখা যাবে।', 'Sign in to see your verification status.')
            : tr(bn, 'যাচাই অপেক্ষমাণ।', 'Verification pending.');

    return Theme(
      data: SlmTheme.night(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SlmColors.navy800, SlmColors.navy950],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SlmColors.gold400.withValues(alpha: 0.7),
                      borderRadius: SlmRadius.pillAll,
                    ),
                  ),
                  const SizedBox(height: 16),
                  VerifyTick(gold: verified, size: 40),
                  const SizedBox(height: 12),
                  SlmText(title, role: SlmTextRole.title, color: SlmColors.ivory, align: TextAlign.center),
                  const SizedBox(height: 6),
                  SlmText(
                    detail,
                    role: SlmTextRole.bodySm,
                    color: SlmColors.mist,
                    align: TextAlign.center,
                    maxLines: 2,
                  ),
                  if (guest) ...[
                    const SizedBox(height: 18),
                    GoogleSignInButton(
                      bn: bn,
                      loading: auth.isLoading,
                      error: auth.errorMessage,
                      onPressed: auth.isLoading
                          ? null
                          : () => ref.read(authProvider.notifier).signInWithGoogle(),
                    ),
                  ] else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

