import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../home/hero_card.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final maxH = (box.maxHeight - 180).clamp(168.0, 430.0);
                            final cardW = math.min(268.0, maxH * 0.66);
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: cardW,
                                  child: AnimatedBuilder(
                                    animation: _sheen,
                                    builder: (context, _) {
                                      final t = _sheen.value;
                                      return HeroCard(
                                        step: 10,
                                        title: tr(bn, 'স্মার্টলাইনম্যান', 'SmartLineman'),
                                        locked: false,
                                        showGem: false,
                                        enableHero: false,
                                        sheen: -0.35 + t * 1.7,
                                        glow: 0.82 + 0.18 * math.sin(t * math.pi),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SlmButton.gold(
                                  label: tr(bn, 'গুগল দিয়ে ঢুকুন', 'Continue with Google'),
                                  icon: Icons.login_rounded,
                                  size: SlmButtonSize.large,
                                  expand: true,
                                  loading: auth.isLoading,
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => ref.read(authProvider.notifier).signInWithGoogle(),
                                ),
                                if (auth.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  SlmText(
                                    auth.errorMessage!,
                                    role: SlmTextRole.bodySm,
                                    color: SlmColors.danger,
                                    align: TextAlign.center,
                                    maxLines: 3,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                SlmButton.ghost(
                                  label: tr(bn, 'আগে ঘুরে দেখুন', 'Look around first'),
                                  expand: true,
                                  onPressed: auth.isLoading
                                      ? null
                                      : () {
                                          ref.read(authProvider.notifier).continueAsGuest();
                                          Navigator.of(context).pop();
                                        },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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
