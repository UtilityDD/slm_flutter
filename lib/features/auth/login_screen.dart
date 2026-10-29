import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../home/hero_card.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlmBackdrop(
        child: ShellSafeArea(
          child: Padding(
            padding: shellScrollPadding(
              context,
              left: 24,
              top: 4,
              right: 24,
              extraBottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.ink,
                    ),
                    tooltip: tr(bn, 'ফিরে যান', 'Back'),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final maxH = (box.maxHeight - 156).clamp(168.0, 430.0);
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
                                  title: tr(
                                    bn,
                                    'স্মার্টলাইনম্যান',
                                    'SmartLineman',
                                  ),
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
                          _EnterButton(
                            label: tr(
                              bn,
                              'গুগল দিয়ে ঢুকুন',
                              'Continue with Google',
                            ),
                            loading: auth.isLoading,
                            onPressed: auth.isLoading
                                ? null
                                : () => ref
                                      .read(authProvider.notifier)
                                      .signInWithGoogle(),
                          ),
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              auth.errorMessage!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: bangla(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.alertRed,
                                height: 1.35,
                              ),
                            ),
                          ],
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    ref
                                        .read(authProvider.notifier)
                                        .continueAsGuest();
                                    Navigator.of(context).pop();
                                  },
                            child: Text(
                              tr(bn, 'আগে ঘুরে দেখুন', 'Look around first'),
                              style: bangla(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
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
      ),
    );
  }
}

class _EnterButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _EnterButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton>
    with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _glow;
  late final AnimationController _charge;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _charge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _glow.dispose();
    _charge.dispose();
    super.dispose();
  }

  void _trigger() {
    if (widget.onPressed == null || _charge.isAnimating) return;
    HapticFeedback.heavyImpact();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.95));
    _charge.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _pressed = false);
      widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: widget.onPressed == null ? null : (_) => _trigger(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_glow, _charge]),
        builder: (context, child) {
          final lift = _pressed ? 0.0 : _glow.value;
          final chargeVal = _charge.value;
          final chargeScale = 1.0 + (math.sin(chargeVal * math.pi) * 0.06);
          return Transform.translate(
            offset: Offset(0, _pressed ? 2 : 0),
            child: Transform.scale(
              scale: (_pressed ? 0.97 : 1 + lift * 0.02) * chargeScale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFBBF24),
                      Color(0xFFF59E0B),
                      Color(0xFFEA580C),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFE08A1E,
                      ).withValues(alpha: 0.32 + lift * 0.25 + chargeVal * 0.3),
                      offset: Offset(0, _pressed ? 2 : 8),
                      blurRadius: _pressed ? 6 : 16 + lift * 8 + chargeVal * 12,
                      spreadRadius: chargeVal * 2,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 18, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: widget.loading ? 0.18 : 0.28,
                  ),
                  shape: BoxShape.circle,
                ),
                child: widget.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
