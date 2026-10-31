import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
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

    // Only the backdrop takes the night theme: sheets opened from Home capture
    // the caller's theme and must keep their own look.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Theme(
              data: SlmTheme.night(),
              child: const SlmBackground(constrain: false, child: SizedBox.expand()),
            ),
          ),
          ShellSafeArea(
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
                      bottom: shellDockBottomInset(context) + 88,
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
        ],
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
    with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _charge;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    unawaited(DsPack.load());
    _charge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _charge.dispose();
    _shine.dispose();
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
                child: child,
              ),
            );
          },
          child: Semantics(
            button: true,
            label: widget.label,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = math.min(_PathBadge.width, box.maxWidth);
                return SizedBox(
                  width: w,
                  height: w * _PathBadge.aspect,
                  child: _PathBadge(
                    shine: _shine,
                    charge: _charge,
                    pressed: _pressed,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shield emblem riding on an emerald pill with the title and a gold arrow.
/// Keeps the footprint of the old 270 px artwork (560 × 174).
class _PathBadge extends StatelessWidget {
  static const width = 270.0;
  static const aspect = 174 / 560;

  final Animation<double> shine;
  final Animation<double> charge;
  final bool pressed;

  const _PathBadge({
    required this.shine,
    required this.charge,
    required this.pressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final inset = h * 0.13;
        final pillH = h - inset * 2;
        final shield = h * 1.32;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: h * 0.36,
              right: 0,
              top: inset,
              bottom: inset,
              child: AnimatedBuilder(
                animation: Listenable.merge([shine, charge]),
                builder: (context, _) => _pill(pillH, h * 0.6),
              ),
            ),
            Positioned(
              left: -h * 0.24,
              top: (h - shield) / 2 - h * 0.02,
              width: shield,
              height: shield,
              child: IgnorePointer(
                child: AnimatedSafetyShield(size: shield, intensity: 0.85),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pill(double pillH, double textStart) {
    // The band crosses in the first 45% of each loop, then rests.
    final run = (shine.value / 0.45).clamp(0.0, 1.0);
    final pass = Curves.easeInOutSine.transform(run);
    final boost = math.sin(charge.value * math.pi);
    final radius = BorderRadius.circular(pillH / 2);
    final title = TextStyle(
      fontFamily: banglaFont,
      fontSize: pillH * 0.42,
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: SlmColors.ivory,
      shadows: const [
        Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2)),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SlmColors.gold200,
            SlmColors.gold500,
            SlmColors.gold700,
            SlmColors.gold300,
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: SlmColors.emerald500.withValues(alpha: 0.28 + 0.32 * boost),
            blurRadius: 18 + 10 * boost,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: pressed ? 0.25 : 0.4),
            blurRadius: pressed ? 6 : 12,
            offset: Offset(0, pressed ? 2 : 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SlmSweepMask(
          t: pass,
          intensity: 0.9,
          color: const Color(0xFFFFF6D6),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E7A5E), SlmColors.emerald800, Color(0xFF04281F)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.48,
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(textStart, 0, pillH * 0.1, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'মৃত্যুহীন '),
                                TextSpan(
                                  text: 'পথ',
                                  style: title.copyWith(color: SlmColors.gold300),
                                ),
                              ],
                            ),
                            style: title,
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                          ),
                        ),
                      ),
                      SizedBox(width: pillH * 0.08),
                      _PathArrow(size: pillH * 0.74, phase: shine.value),
                    ],
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

class _PathArrow extends StatelessWidget {
  final double size;
  final double phase;

  const _PathArrow({required this.size, required this.phase});

  @override
  Widget build(BuildContext context) {
    final nudge = math.sin(phase * 2 * math.pi) * 1.6;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [SlmColors.gold100, SlmColors.gold300, SlmColors.gold600],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: SlmColors.gold700, width: 1),
        boxShadow: [
          BoxShadow(
            color: SlmColors.gold400.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
      child: Transform.translate(
        offset: Offset(1 + nudge, 0),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: size * 0.42,
          color: SlmColors.navy900,
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
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0.1,
                      color: SlmColors.ivory,
                      shadows: [
                        Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTick,
                  child: SlmShimmer(
                    enabled: verified,
                    period: const Duration(milliseconds: 4600),
                    intensity: 1.2,
                    child: VerifyTick(gold: verified, size: 22),
                  ),
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

  static const _seg = 38.0;
  static const _segH = 24.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SlmColors.navy950.withValues(alpha: 0.55),
        borderRadius: SlmRadius.pillAll,
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
      ),
      child: SizedBox(
        width: _seg * 2,
        height: _segH,
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: bn ? Alignment.centerLeft : Alignment.centerRight,
              duration: SlmMotion.base,
              curve: SlmMotion.emphasized,
              child: Container(
                width: _seg,
                height: _segH,
                decoration: BoxDecoration(
                  gradient: SlmGradients.gold,
                  borderRadius: SlmRadius.pillAll,
                  boxShadow: [
                    BoxShadow(
                      color: SlmColors.gold400.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _LangSeg(label: 'বাং', selected: bn, onTap: () => onLanguage(true)),
                _LangSeg(label: 'EN', selected: !bn, onTap: () => onLanguage(false)),
              ],
            ),
          ],
        ),
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
    return SlmPressable(
      onTap: onTap,
      pressedScale: 0.9,
      semanticLabel: label,
      child: SizedBox(
        width: _LangPill._seg,
        height: _LangPill._segH,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: SlmMotion.base,
            style: TextStyle(
              fontFamily: banglaFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: selected ? SlmColors.navy900 : SlmColors.mist,
            ),
            child: Text(label, textScaler: TextScaler.noScaling),
          ),
        ),
      ),
    );
  }
}
