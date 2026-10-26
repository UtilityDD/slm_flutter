import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'hero_card.dart';
import 'level_lessons_sheet.dart';
import 'lineman_figure.dart';

/// Home carousel listens and scrolls to this step after a level celebration.
class PendingHomeRevealNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setStep(int? step) => state = step;
}

final pendingHomeRevealStepProvider =
    NotifierProvider<PendingHomeRevealNotifier, int?>(PendingHomeRevealNotifier.new);

Future<void> _playCelebrationCue() async {
  final player = AudioPlayer();
  try {
    await player.setReleaseMode(ReleaseMode.release);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/quiz_right.wav'));
    player.onPlayerComplete.first.then((_) => player.dispose()).ignore();
  } catch (_) {
    await player.dispose();
  }
}

/// Premium level-clear celebration + automatic color reveal of the next lineman.
class LevelCelebrationPage extends ConsumerStatefulWidget {
  final int completedStep;
  final String completedTitle;
  final int? nextStep;
  final String? nextTitle;
  final bool bn;

  const LevelCelebrationPage({
    super.key,
    required this.completedStep,
    required this.completedTitle,
    required this.nextStep,
    required this.nextTitle,
    required this.bn,
  });

  @override
  ConsumerState<LevelCelebrationPage> createState() => _LevelCelebrationPageState();
}

class _LevelCelebrationPageState extends ConsumerState<LevelCelebrationPage>
    with TickerProviderStateMixin {
  late final AnimationController _burst;
  late final AnimationController _reveal;
  late final AnimationController _sheen;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _playCelebrationCue();
    HapticFeedback.mediumImpact();

    // Auto color reveal — no tap required.
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _reveal.forward();
      _sheen.repeat();
    });

    // Lightning strike beat — big hit + sound as color surges up the card.
    Future.delayed(const Duration(milliseconds: 550 + 840), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _playCelebrationCue();
    });

    // After reveal finishes, return home so carousel shows the new colors.
    _reveal.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted && !_finishing) _finish();
        });
      }
    });
  }

  @override
  void dispose() {
    _burst.dispose();
    _reveal.dispose();
    _sheen.dispose();
    super.dispose();
  }

  Future<void> _finish({bool openNext = false}) async {
    if (_finishing) return;
    _finishing = true;
    final next = widget.nextStep;
    if (next != null) {
      ref.read(pendingHomeRevealStepProvider.notifier).setStep(next);
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (openNext && next != null && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      await openLevelLessons(context, ref, step: next, bn: widget.bn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bn = widget.bn;
    final next = widget.nextStep;
    final hasNext = next != null && widget.nextTitle != null;
    final doneMetal = cardMetalFor(widget.completedStep);
    final nextMetal = hasNext ? cardMetalFor(next) : doneMetal;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1214),
      body: AnimatedBuilder(
        animation: Listenable.merge([_burst, _reveal, _sheen]),
        builder: (context, _) {
          final burstT = Curves.easeOut.transform(_burst.value.clamp(0.0, 1.0));
          final revealT = Curves.easeOutCubic.transform(_reveal.value.clamp(0.0, 1.0));
          final showContinue = revealT > 0.85;

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _CelebrationFieldPainter(
                  burst: burstT,
                  reveal: revealT,
                  metal: nextMetal,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: Curves.easeOut.transform((_burst.value / 0.45).clamp(0.0, 1.0)),
                        child: Text(
                          bn ? 'লেভেল সম্পন্ন!' : 'Level complete!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: banglaFont,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: doneMetal.light,
                            shadows: [
                              Shadow(color: doneMetal.glow.withValues(alpha: 0.7), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: Curves.easeOut.transform(((_burst.value - 0.12) / 0.4).clamp(0.0, 1.0)),
                        child: Text(
                          widget.completedTitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: banglaFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      Expanded(
                        child: hasNext
                            ? _AutoRevealStage(
                                nextStep: next!,
                                nextTitle: widget.nextTitle!,
                                nextMetal: nextMetal,
                                reveal: revealT,
                                sheen: _sheen.value,
                                bn: bn,
                              )
                            : _FinalStage(
                                step: widget.completedStep,
                                title: widget.completedTitle,
                                metal: doneMetal,
                                bn: bn,
                              ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 280),
                        opacity: showContinue ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !showContinue,
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _finish(openNext: hasNext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: nextMetal.mid,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                hasNext
                                    ? (bn ? 'এগিয়ে যান' : 'Continue')
                                    : (bn ? 'হোমে ফিরে যান' : 'Back to home'),
                                style: const TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AutoRevealStage extends StatelessWidget {
  final int nextStep;
  final String nextTitle;
  final CardMetal nextMetal;
  final double reveal;
  final double sheen;
  final bool bn;

  const _AutoRevealStage({
    required this.nextStep,
    required this.nextTitle,
    required this.nextMetal,
    required this.reveal,
    required this.sheen,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    // Phase breakdown of the reveal timeline (0..1):
    final chargeT = (reveal / 0.3).clamp(0.0, 1.0);
    final wipe = ((reveal - 0.3) / 0.4).clamp(0.0, 1.0);
    final settleT = Curves.easeOutBack.transform(((reveal - 0.7) / 0.3).clamp(0.0, 1.0));
    final ringT = ((reveal - 0.3) / 0.38).clamp(0.0, 1.0);
    final sparksT = ((reveal - 0.3) / 0.55).clamp(0.0, 1.0);
    // Sharp white flash at the strike instant.
    final flashUp = ((reveal - 0.28) / 0.07).clamp(0.0, 1.0);
    final flashDown = 1 - ((reveal - 0.34) / 0.12).clamp(0.0, 1.0);
    final flash = (flashUp * flashDown).clamp(0.0, 1.0);
    final titleOpacity = Curves.easeOut.transform(((reveal - 0.72) / 0.28).clamp(0.0, 1.0));

    final phaseLabel = reveal < 0.3
        ? (bn ? 'চার্জ হচ্ছে…' : 'Charging…')
        : reveal < 0.72
            ? (bn ? 'রং জাগছে…' : 'Energizing…')
            : (bn ? 'নতুন রূপ!' : 'New look!');

    return LayoutBuilder(
      builder: (context, constraints) {
        final figW = math.min(constraints.maxWidth * 0.62, constraints.maxHeight * 0.5);
        final cardH = figW / 0.66;
        final fieldW = math.min(constraints.maxWidth, figW * 1.9);
        final fieldH = math.min(constraints.maxHeight - 80, cardH * 1.42);

        // Dark silhouette card revealed bottom-to-top by the energy wipe.
        final wipeGradient = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: const [Colors.white, Colors.white, Colors.transparent, Colors.transparent],
          stops: [
            0.0,
            (wipe - 0.06).clamp(0.0, 1.0),
            (wipe + 0.02).clamp(0.0, 1.0),
            1.0,
          ],
        );

        final tremor = chargeT * (1 - wipe) * 2.2;
        final tremorDx = math.sin(sheen * 48) * tremor;
        final cardTurn = (1 - wipe) * -0.16;
        final cardScale = 1 + 0.06 * settleT * (1 - settleT) * 4;

        final card = SizedBox(
          width: figW,
          height: cardH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-colour collectible card (brightens as it energizes).
              HeroCard(
                step: nextStep,
                title: nextTitle,
                locked: false,
                glow: 0.25 + 0.75 * wipe,
                enableHero: false,
              ),
              // Dark, un-energized silhouette erased from the bottom up.
              ShaderMask(
                blendMode: BlendMode.dstOut,
                shaderCallback: (rect) => wipeGradient.createShader(rect),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0xF2070B0F), BlendMode.srcATop),
                  child: HeroCard(
                    step: nextStep,
                    title: nextTitle,
                    locked: false,
                    glow: 0,
                    enableHero: false,
                  ),
                ),
              ),
              // Bright energy edge riding the wipe line.
              if (wipe > 0.01 && wipe < 0.99)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment(0, 1 - 2 * wipe),
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(color: nextMetal.glow, blurRadius: 18, spreadRadius: 2),
                          BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

        return Column(
          children: [
            const Spacer(flex: 1),
            Text(
              phaseLabel,
              style: TextStyle(
                fontFamily: banglaFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color.lerp(const Color(0xFF94A3B8), nextMetal.light, wipe),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: fieldW,
              height: fieldH,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Electric effects behind + around the card.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ForgeFxPainter(
                          charge: chargeT,
                          wipe: wipe,
                          ring: ringT,
                          sparks: sparksT,
                          flicker: sheen,
                          metal: nextMetal,
                          cardW: figW,
                          cardH: cardH,
                        ),
                      ),
                    ),
                  ),
                  // The card itself: trembles while charging, turns to face front,
                  // then pops on settle.
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..translateByDouble(tremorDx, 0.0, 0.0, 1.0)
                      ..rotateY(cardTurn)
                      ..scaleByDouble(cardScale, cardScale, 1, 1),
                    child: card,
                  ),
                  // Strike flash.
                  if (flash > 0.01)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.85 * flash),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Nameplate stamps in on settle.
            Opacity(
              opacity: titleOpacity,
              child: Transform.scale(
                scale: 0.7 + 0.3 * titleOpacity,
                child: Text(
                  nextTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: nextMetal.light,
                    shadows: [
                      Shadow(color: nextMetal.glow.withValues(alpha: 0.6), blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: titleOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in [nextMetal.light, nextMetal.mid, nextMetal.dark, nextMetal.glow])
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(color: c.withValues(alpha: 0.5 * titleOpacity), blurRadius: 8),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        );
      },
    );
  }
}

class _FinalStage extends StatelessWidget {
  final int step;
  final String title;
  final CardMetal metal;
  final bool bn;

  const _FinalStage({
    required this.step,
    required this.title,
    required this.metal,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Text(
          bn ? 'সব লেভেল জয়!' : 'All levels conquered!',
          style: TextStyle(
            fontFamily: banglaFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: metal.light,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 200,
          child: LinemanFigure(step: step, enableHero: false),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: banglaFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

/// Electric "forge" effects: lightning bolts, strike shockwave and sparks.
class _ForgeFxPainter extends CustomPainter {
  final double charge;
  final double wipe;
  final double ring;
  final double sparks;
  final double flicker;
  final CardMetal metal;
  final double cardW;
  final double cardH;

  _ForgeFxPainter({
    required this.charge,
    required this.wipe,
    required this.ring,
    required this.sparks,
    required this.flicker,
    required this.metal,
    required this.cardW,
    required this.cardH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cardLeft = center.dx - cardW / 2;
    final cardRight = center.dx + cardW / 2;
    final cardTop = center.dy - cardH / 2;
    final cardBottom = center.dy + cardH / 2;

    // --- Lightning bolts crackle while charging, fade once wipe advances. ---
    final boltAlpha = (charge * (1 - (wipe / 0.35).clamp(0.0, 1.0))).clamp(0.0, 1.0);
    if (boltAlpha > 0.02) {
      final rnd = math.Random((flicker * 20).floor() * 7 + 3);
      final flick = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(flicker * 60));
      final boltPaint = Paint()
        ..color = Colors.white.withValues(alpha: boltAlpha * flick)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      final glowPaint = Paint()
        ..color = metal.glow.withValues(alpha: boltAlpha * flick * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      for (var side = 0; side < 2; side++) {
        final startX = side == 0 ? cardLeft - 6 : cardRight + 6;
        final dir = side == 0 ? -1 : 1;
        final path = Path()..moveTo(startX, cardTop + cardH * 0.12);
        final segs = 6;
        for (var i = 1; i <= segs; i++) {
          final t = i / segs;
          final x = startX + dir * (10 + rnd.nextDouble() * 22) * t;
          final y = cardTop + cardH * (0.12 + t * 0.62);
          path.lineTo(x, y);
        }
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, boltPaint);
      }
    }

    // --- Shockwave ring at the strike. ---
    if (ring > 0.01 && ring < 1.0) {
      final maxR = size.width * 0.62;
      final r = maxR * Curves.easeOut.transform(ring);
      final a = (1 - ring) * 0.8;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = metal.glow.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * (1 - ring) + 1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        center,
        r * 0.82,
        Paint()
          ..color = Colors.white.withValues(alpha: a * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // --- Sparks burst from the card, arc out with gravity. ---
    if (sparks > 0.01 && sparks < 1.0) {
      final rnd = math.Random(99);
      const n = 26;
      final life = sparks;
      for (var i = 0; i < n; i++) {
        final ang = (i / n) * math.pi * 2 + rnd.nextDouble() * 0.5;
        final speed = (0.55 + rnd.nextDouble() * 0.6) * size.width * 0.75;
        final t = life;
        final dx = math.cos(ang) * speed * t;
        final dy = math.sin(ang) * speed * t + 0.5 * size.height * 1.1 * t * t;
        final p = center + Offset(dx, dy);
        final a = (1 - t).clamp(0.0, 1.0);
        final rad = 2.6 * (1 - t) + 0.6;
        final col = i % 3 == 0 ? Colors.white : metal.glow;
        canvas.drawCircle(
          p,
          rad,
          Paint()
            ..color = col.withValues(alpha: a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
    }

    // --- Rising metal glow pool under the card as it energizes. ---
    if (wipe > 0.0) {
      final pool = Offset(center.dx, cardBottom - 6);
      canvas.drawOval(
        Rect.fromCenter(center: pool, width: cardW * 1.1, height: cardH * 0.16),
        Paint()
          ..shader = RadialGradient(
            colors: [
              metal.glow.withValues(alpha: 0.5 * wipe),
              metal.glow.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCenter(center: pool, width: cardW * 1.1, height: cardH * 0.16)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ForgeFxPainter old) => true;
}

class _CelebrationFieldPainter extends CustomPainter {
  final double burst;
  final double reveal;
  final CardMetal metal;

  _CelebrationFieldPainter({
    required this.burst,
    required this.reveal,
    required this.metal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.4);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.2,
          colors: [
            Color.lerp(const Color(0xFF134E4A), metal.dark, reveal)!,
            const Color(0xFF0C1214),
          ],
        ).createShader(Offset.zero & size),
    );

    for (var i = 0; i < 22; i++) {
      final ang = (i / 22) * math.pi * 2 + burst * 1.6;
      final dist = size.shortestSide * (0.16 + burst * 0.48 + (i % 3) * 0.035);
      final p = c + Offset(math.cos(ang) * dist, math.sin(ang) * dist * 0.75);
      final alpha = ((1 - burst) * 0.9).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;
      canvas.drawCircle(
        p,
        2.2 + (i % 4) * 0.9,
        Paint()
          ..color = Color.lerp(const Color(0xFFFBBF24), metal.glow, reveal)!
              .withValues(alpha: alpha),
      );
    }

    canvas.drawCircle(
      c,
      size.shortestSide * (0.2 + reveal * 0.14),
      Paint()
        ..shader = RadialGradient(
          colors: [
            metal.glow.withValues(alpha: 0.2 + 0.28 * reveal),
            metal.glow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: size.shortestSide * 0.42)),
    );
  }

  @override
  bool shouldRepaint(covariant _CelebrationFieldPainter old) =>
      old.burst != burst || old.reveal != reveal || old.metal != metal;
}
