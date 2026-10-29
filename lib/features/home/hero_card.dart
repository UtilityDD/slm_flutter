import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/verify_tick.dart';
import 'lineman_figure.dart';

/// Frame metal per rank: the card frame *is* the badge.
class CardMetal {
  final Color light;
  final Color mid;
  final Color dark;
  final Color glow;

  const CardMetal(this.light, this.mid, this.dark, this.glow);
}

const _metals = <CardMetal>[
  CardMetal(
    Color(0xFFC5CAD3),
    Color(0xFF7A808A),
    Color(0xFF3A3F48),
    Color(0xFF94A3B8),
  ), // 0 iron
  CardMetal(
    Color(0xFFF0C495),
    Color(0xFFB87333),
    Color(0xFF5C2E12),
    Color(0xFFD97706),
  ), // 1 copper
  CardMetal(
    Color(0xFFE2E5EA),
    Color(0xFF6B7280),
    Color(0xFF1F2937),
    Color(0xFF67E8F9),
  ), // 2 gunmetal
  CardMetal(
    Color(0xFF99F6E4),
    Color(0xFF2A7A72),
    Color(0xFF0A2926),
    Color(0xFF2DD4BF),
  ), // 3 teal steel
  CardMetal(
    Color(0xFFF5E6A3),
    Color(0xFFC9A227),
    Color(0xFF4A3508),
    Color(0xFFEAB308),
  ), // 4 brass
  CardMetal(
    Color(0xFFBFDBFE),
    Color(0xFF2B5FBF),
    Color(0xFF0B1A3D),
    Color(0xFF60A5FA),
  ), // 5 cobalt
  CardMetal(
    Color(0xFFFFFFFF),
    Color(0xFFA8B0BC),
    Color(0xFF2D3642),
    Color(0xFFE2E8F0),
  ), // 6 silver
  CardMetal(
    Color(0xFFFFF1B8),
    Color(0xFFD4A017),
    Color(0xFF5C3D06),
    Color(0xFFF59E0B),
  ), // 7 gold
  CardMetal(
    Color(0xFFE9D5FF),
    Color(0xFF6D4AB8),
    Color(0xFF1E0A4A),
    Color(0xFFC084FC),
  ), // 8 violet
  CardMetal(
    Color(0xFFFFFFFF),
    Color(0xFFB8C0CC),
    Color(0xFF3A4450),
    Color(0xFF7DD3FC),
  ), // 9 platinum
  CardMetal(
    Color(0xFFF5D76E),
    Color(0xFF8A6A1C),
    Color(0xFF0A0908),
    Color(0xFFFBBF24),
  ), // 10 obsidian-gold
];

CardMetal cardMetalFor(int step) => _metals[step.clamp(0, 10)];

const _lockedMetal = CardMetal(
  Color(0xFF9AA0A8),
  Color(0xFF4B5058),
  Color(0xFF1C1F24),
  Color(0xFF475569),
);

/// One level as a collectible character card.
class HeroCard extends StatelessWidget {
  final int step;
  final String title;
  final bool locked;

  /// Pointer tilt, each axis -1..1.
  final Offset tilt;

  /// Sheen sweep position 0..1 (outside 0..1 = hidden).
  final double sheen;

  /// Glow strength 0..1 for the frame light-up.
  final double glow;

  /// Launch progress 0..1 — drives parallax pop of the figure vs scene.
  final double launch;

  final bool enableHero;

  /// Level numeral. Off for the login title card.
  final bool showGem;

  /// Grey check on levels that stay closed until an admin verifies the member.
  final bool verifyTick;

  const HeroCard({
    super.key,
    required this.step,
    required this.title,
    required this.locked,
    this.tilt = Offset.zero,
    this.sheen = -1,
    this.glow = 1,
    this.launch = 0,
    this.enableHero = false,
    this.showGem = true,
    this.verifyTick = false,
  });

  @override
  Widget build(BuildContext context) {
    final metal = locked ? _lockedMetal : cardMetalFor(step);
    const radius = 26.0;
    const frame = 7.0;

    return AspectRatio(
      aspectRatio: 0.66,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final plateH = h * 0.13;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Frame glow.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                      if (!locked)
                        BoxShadow(
                          color: metal.glow.withValues(alpha: 0.38 * glow),
                          blurRadius: 30,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
              ),
              // Metal frame.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      begin: Alignment(-1 + tilt.dx * 0.6, -1 + tilt.dy * 0.6),
                      end: Alignment(1 + tilt.dx * 0.6, 1 + tilt.dy * 0.6),
                      colors: [
                        metal.light,
                        metal.mid,
                        metal.dark,
                        metal.mid,
                        metal.light,
                      ],
                      stops: const [0.0, 0.28, 0.55, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              // Inner scene window.
              Positioned(
                left: frame,
                top: frame,
                right: frame,
                bottom: frame,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius - frame + 2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Scene background — recedes slightly on launch (parallax back layer).
                      Transform.translate(
                        offset: Offset(-tilt.dx * 8, -tilt.dy * 6 + launch * 8),
                        child: Transform.scale(
                          scale: 1.08 - launch * 0.05,
                          child: CustomPaint(
                            painter: _ScenePainter(step: step, locked: locked),
                          ),
                        ),
                      ),
                      // Figure — pops forward faster than scene (parallax front layer).
                      Positioned(
                        left: w * 0.04 + tilt.dx * 6,
                        right: w * 0.04 - tilt.dx * 6,
                        top: h * 0.05,
                        bottom: plateH * 0.62,
                        child: Transform.translate(
                          offset: Offset(0, -launch * 14),
                          child: Transform.scale(
                            scale: 1 + launch * 0.16,
                            child: _figure(),
                          ),
                        ),
                      ),
                      // Sheen.
                      if (sheen > -0.2 && sheen < 1.2)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.6 + sheen * 3.2, -1),
                                end: Alignment(-0.9 + sheen * 3.2, 1),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(
                                    alpha: locked ? 0.06 : 0.22,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Inner bevel.
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              radius - frame + 2,
                            ),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.35),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showGem && !verifyTick)
                Positioned(
                  left: frame + 8,
                  top: frame + 8,
                  child: _LevelGem(step: step, metal: metal, locked: locked),
                ),
              if (verifyTick)
                const Positioned(
                  left: 14,
                  top: 14,
                  child: VerifyTick(size: 28),
                ),
              // Nameplate.
              Positioned(
                left: w * 0.1,
                right: w * 0.1,
                bottom: -plateH * 0.18,
                height: plateH,
                child: _Nameplate(title: title, metal: metal, locked: locked),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _figure() {
    final figure = LinemanFigure(step: step, enableHero: enableHero && !locked);
    if (!locked) return figure;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0, 0, 0, 0, 14, //
        0, 0, 0, 0, 22,
        0, 0, 0, 0, 30,
        0, 0, 0, 0.92, 0,
      ]),
      child: figure,
    );
  }
}

class _LevelGem extends StatelessWidget {
  final int step;
  final CardMetal metal;
  final bool locked;

  const _LevelGem({
    required this.step,
    required this.metal,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [metal.light, metal.mid, metal.dark],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: metal.dark.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: locked
          ? Icon(Icons.lock_rounded, size: 16, color: metal.light)
          : Text(
              step == 10 ? '★' : '$step',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1,
                color: Colors.white,
                shadows: [Shadow(color: metal.dark, blurRadius: 3)],
              ),
            ),
    );
  }
}

class _Nameplate extends StatelessWidget {
  final String title;
  final CardMetal metal;
  final bool locked;

  const _Nameplate({
    required this.title,
    required this.metal,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [metal.light, metal.mid, metal.dark],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: Border.all(color: metal.dark, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: metal.dark.withValues(alpha: 0.85),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dusk sky + pole/line silhouettes behind the lineman.
class _ScenePainter extends CustomPainter {
  final int step;
  final bool locked;

  _ScenePainter({required this.step, required this.locked});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    final sky = locked
        ? const [Color(0xFF1F2933), Color(0xFF2B3440), Color(0xFF3A4350)]
        : const [Color(0xFF0B3B37), Color(0xFF1F6B63), Color(0xFFF2B36B)];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Sun glow on the horizon.
    if (!locked) {
      final sun = Offset(w * 0.72, h * 0.7);
      canvas.drawCircle(
        sun,
        w * 0.5,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE2A8).withValues(alpha: 0.75),
              const Color(0xFFFFE2A8).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: w * 0.5)),
      );
    }

    final ink = Paint()
      ..color = (locked ? const Color(0xFF151A20) : const Color(0xFF0A2E2B))
          .withValues(alpha: 0.55);
    final faint = Paint()..color = ink.color.withValues(alpha: 0.28);

    // Far hills.
    final hills = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.78, h * 0.78, w, h * 0.69)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hills, faint);

    // Poles and sagging wires, placement varies by level.
    final seed = step * 37;
    final poleXs = [w * 0.1, w * 0.5 + ((seed % 20) - 10), w * 0.92];
    final poleTop = h * 0.36;
    final base = h * 0.8;
    final wire = Paint()
      ..color = ink.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (final x in poleXs) {
      final top = poleTop + (x - w / 2).abs() * 0.12;
      canvas.drawRect(Rect.fromLTWH(x - 2.2, top, 4.4, base - top), ink);
      canvas.drawRect(Rect.fromLTWH(x - 16, top + 10, 32, 3), ink);
    }
    for (var line = 0; line < 3; line++) {
      for (var i = 0; i < poleXs.length - 1; i++) {
        final a = poleXs[i];
        final b = poleXs[i + 1];
        final ya = poleTop + (a - w / 2).abs() * 0.12 + 11;
        final yb = poleTop + (b - w / 2).abs() * 0.12 + 11;
        final offset = (line - 1) * 12.0;
        final p = Path()
          ..moveTo(a + offset, ya)
          ..quadraticBezierTo(
            (a + b) / 2,
            math.max(ya, yb) + 22,
            b + offset,
            yb,
          );
        canvas.drawPath(p, wire);
      }
    }

    // Ground.
    final ground = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.79, w, h * 0.83)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      ground,
      Paint()
        ..color = (locked ? const Color(0xFF12161B) : const Color(0xFF082522)),
    );

    // Ground light pool under the figure.
    final pool = Offset(w * 0.5, h * 0.86);
    canvas.drawOval(
      Rect.fromCenter(center: pool, width: w * 0.8, height: h * 0.08),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                (locked ? const Color(0xFF64748B) : const Color(0xFF5EEAD4))
                    .withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(center: pool, width: w * 0.8, height: h * 0.08),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.step != step || old.locked != locked;
}

/// Back face shown during the flip-in.
class HeroCardBack extends StatelessWidget {
  final int step;

  const HeroCardBack({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final metal = cardMetalFor(step);
    return AspectRatio(
      aspectRatio: 0.66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [metal.light, metal.mid, metal.dark],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: const RadialGradient(
              colors: [Color(0xFF1F6B63), Color(0xFF0B3B37)],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.bolt_rounded,
            size: 96,
            color: metal.light.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
