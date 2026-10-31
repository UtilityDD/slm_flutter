import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import '../training/training_provider.dart';
import '../duty_slip/duty_slip_page.dart';
import '../duty_slip/duty_slip_models.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'hero_card_carousel.dart';
import 'lesson_progress_store.dart';
import 'lineman_progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final localDone = ref.watch(allCompletedLessonsProvider);
    final ladder = ref.watch(trainingLadderProvider).value;
    var highestDone = 0;
    if (ladder != null) {
      for (final m in ladder) {
        if (!m.isCompleted) break;
        highestDone = m.moduleNumber;
      }
    }
    final path = linemanPath(
      profile,
      extraCompleted: localDone,
      highestCompletedModule: highestDone > 0 ? highestDone : null,
    );
    final guest = auth.isGuest || !auth.isAuthenticated;
    final verified = linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final fullName = profile?.fullName?.trim() ?? '';
    final slmId = profile?.slmId?.trim() ?? '';
    final guestLabel = tr(bn, 'অতিথি', 'Guest');
    final name = guest
        ? guestLabel
        : (fullName.isNotEmpty
              ? fullName
              : (slmId.isNotEmpty ? slmId : guestLabel));

    return SlmBackdrop(
      child: ShellSafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _Header(
                bn: bn,
                name: name,
                onName: () {
                  if (guest) {
                    Navigator.of(context).pushNamed(AppRoutes.login);
                    return;
                  }
                  Navigator.of(context).pushNamed(AppRoutes.more);
                },
                onTick: verified ? null : () => showVerifySheet(context),
                verified: verified,
                onLanguage: (value) =>
                    ref.read(languageProvider.notifier).setBengali(value),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: shellDockBottomInset(context) + 68,
                    ),
                    child: HeroCardCarousel(path: path, bn: bn),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: shellDockBottomOffset(context, 14),
                    child: Center(
                      child: _PathPlayChip(
                        label: tr(bn, 'মৃত্যুহীন পথ', 'Mrityuhin Path'),
                        onTap: (sourceRect) {
                          DutySlipPage.open(context, sourceRect: sourceRect);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathPlayChip extends StatefulWidget {
  final String label;
  final void Function(Rect? sourceRect) onTap;

  const _PathPlayChip({required this.label, required this.onTap});

  @override
  State<_PathPlayChip> createState() => _PathPlayChipState();
}

class _PathPlayChipState extends State<_PathPlayChip>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _charge;

  @override
  void initState() {
    super.initState();
    unawaited(DsPack.load());
    _charge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _charge.dispose();
    super.dispose();
  }

  void _trigger(BuildContext ctx) {
    if (_charge.isAnimating) return;
    HapticFeedback.heavyImpact();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.95));
    final box = ctx.findRenderObject() as RenderBox?;
    final rect = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;
    _charge.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _pressed = false);
      widget.onTap(rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (chipContext) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => _trigger(chipContext),
        child: AnimatedBuilder(
          animation: _charge,
          builder: (context, child) {
            final chargeVal = _charge.value;
            final chargeScale = 1.0 + (math.sin(chargeVal * math.pi) * 0.08);

            return Transform.translate(
              offset: Offset(0, _pressed ? 2 : 0),
              child: Transform.scale(
                scale: (_pressed ? 0.97 : 1) * chargeScale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (chargeVal > 0.01)
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 1.0 + (chargeVal * 0.45),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Color.fromRGBO(
                                  251,
                                  191,
                                  36,
                                  (1.0 - chargeVal).clamp(0.0, 1.0),
                                ),
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(
                                    251,
                                    191,
                                    36,
                                    0.4 * (1.0 - chargeVal),
                                  ),
                                  blurRadius: 18 * chargeVal,
                                  spreadRadius: 4 * chargeVal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    DecoratedBox(
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
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            );
          },
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: _LabelLight(widget.label),
          ),
        ),
      ),
    );
  }
}

class _LabelLight extends StatefulWidget {
  final String text;
  const _LabelLight(this.text);

  @override
  State<_LabelLight> createState() => _LabelLightState();
}

class _LabelLightState extends State<_LabelLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final slide = -bounds.width + (_sweep.value * bounds.width * 2.4);
            return const LinearGradient(
              colors: [
                Color(0xB8FFFFFF),
                Color(0xFFFFFFFF),
                Color(0xFFFFF6C8),
                Color(0xFFFFFFFF),
                Color(0xB8FFFFFF),
              ],
              stops: [0.30, 0.44, 0.50, 0.56, 0.70],
            ).createShader(Rect.fromLTWH(slide, 0, bounds.width, bounds.height));
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: banglaFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool bn;
  final String name;
  final bool verified;
  final VoidCallback onName;
  final VoidCallback? onTick;
  final ValueChanged<bool> onLanguage;

  const _Header({
    required this.bn,
    required this.name,
    required this.verified,
    required this.onName,
    required this.onTick,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onName,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTick,
                  child: VerifyTick(gold: verified, size: 22),
                ),
              ],
            ),
          ),
        ),
        _LangPill(bn: bn, onLanguage: onLanguage),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  final bool bn;
  final ValueChanged<bool> onLanguage;

  const _LangPill({required this.bn, required this.onLanguage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EA),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE7D5C6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangSeg(label: 'বাং', selected: bn, onTap: () => onLanguage(true)),
          _LangSeg(label: 'EN', selected: !bn, onTap: () => onLanguage(false)),
        ],
      ),
    );
  }
}

class _LangSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangSeg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
