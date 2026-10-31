import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/slm_text.dart';
import '../components/slm_tone.dart';
import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import '../tokens/slm_layout.dart';
import '../tokens/slm_motion.dart';
import '../tokens/slm_palette.dart';
import 'slm_motion_scope.dart';
import 'slm_motion_widgets.dart';
import 'slm_safety_shield.dart';

/// XP / level bar. When [value] rises, the fill glides forward, the newly
/// earned stretch glows gold and then settles to emerald. Reaching 1.0 adds
/// a short completion flash and calls [onFilled].
class SlmXpBar extends StatefulWidget {
  final double value;
  final double height;
  final SlmTone tone;
  final VoidCallback? onFilled;

  const SlmXpBar({
    super.key,
    required this.value,
    this.height = 12,
    this.tone = SlmTone.emerald,
    this.onFilled,
  });

  @override
  State<SlmXpBar> createState() => _SlmXpBarState();
}

class _SlmXpBarState extends State<SlmXpBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late double _from = widget.value.clamp(0.0, 1.0);
  late double _to = _from;
  bool _filling = false;

  @override
  void initState() {
    super.initState();
    _c.value = 1;
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && _filling) {
        _filling = false;
        widget.onFilled?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SlmXpBar old) {
    super.didUpdateWidget(old);
    final next = widget.value.clamp(0.0, 1.0);
    if (next == _to) return;
    _from = _shown;
    _to = next;
    _filling = _to >= 1 && _from < 1;
    if (slmReduceMotion(context)) {
      _c.value = 1;
      if (_filling) {
        _filling = false;
        widget.onFilled?.call();
      }
    } else {
      _c.forward(from: 0);
    }
  }

  double get _shown => _from + (_to - _from) * SlmMotion.emphasized.transform((_c.value / 0.6).clamp(0.0, 1.0));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    return Semantics(
      value: '${(_to * 100).round()}%',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _XpBarPainter(
            anim: _c,
            from: () => _from,
            to: () => _to,
            shown: () => _shown,
            palette: p,
            tone: widget.tone,
            filling: _to >= 1 && _from < 1,
          ),
        ),
      ),
    );
  }
}

class _XpBarPainter extends CustomPainter {
  final Animation<double> anim;
  final double Function() from;
  final double Function() to;
  final double Function() shown;
  final SlmPalette palette;
  final SlmTone tone;
  final bool filling;

  _XpBarPainter({
    required this.anim,
    required this.from,
    required this.to,
    required this.shown,
    required this.palette,
    required this.tone,
    required this.filling,
  }) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = Radius.circular(h / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(track, Paint()..color = palette.surfaceSunken);
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = palette.line.withValues(alpha: 0.6),
    );

    final v = anim.value;
    final cur = shown();
    if (cur <= 0) return;
    final w = math.max(h, size.width * cur);
    final fill = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), r);
    canvas.drawRRect(fill, Paint()..shader = tone.gradient(palette).createShader(fill.outerRect));

    // Fresh XP glows gold, then fades into the bar colour.
    final gained = cur - from();
    final settle = 1 - Curves.easeIn.transform(((v - 0.55) / 0.45).clamp(0.0, 1.0));
    if (gained > 0.001 && settle > 0) {
      final gx = size.width * from();
      final rect = Rect.fromLTWH(gx, 0, w - gx, h);
      canvas.save();
      canvas.clipRRect(fill);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(colors: [
            SlmColors.gold300.withValues(alpha: 0.55 * settle),
            SlmColors.gold100.withValues(alpha: 0.95 * settle),
          ]).createShader(rect),
      );
      canvas.restore();
    }

    // Glint at the head while moving.
    final moving = v < 0.62 && to() != from();
    if (moving) {
      final c = Offset(w - h / 2, h / 2);
      canvas.drawCircle(
        c,
        h * 1.1,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.9),
            SlmColors.gold200.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: c, radius: h * 1.1)),
      );
    }

    // Full bar: one soft white pass.
    if (filling && v > 0.55) {
      final f = math.sin(((v - 0.55) / 0.45).clamp(0.0, 1.0) * math.pi);
      canvas.drawRRect(fill, Paint()..color = Colors.white.withValues(alpha: 0.35 * f));
    }

    // Top gloss.
    final gloss = Rect.fromLTWH(0, 0, w, h / 2);
    canvas.save();
    canvas.clipRRect(fill);
    canvas.drawRect(
      gloss,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
        ).createShader(gloss),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _XpBarPainter old) => true;
}

/// Circular progress with an animated arc and a glowing head.
class SlmProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final SlmTone tone;
  final Widget? child;

  const SlmProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.stroke = 7,
    this.tone = SlmTone.emerald,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    final d = size * context.slm.layout.scale;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(v * 100).round()}%',
      child: SizedBox.square(
        dimension: d,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: slmReduceMotion(context) ? Duration.zero : SlmMotion.page * 2,
          curve: SlmMotion.emphasized,
          child: child == null ? null : Center(child: child),
          builder: (context, t, child) => CustomPaint(
            painter: _RingProgressPainter(t, stroke, tone.color(p), tone.gradient(p), p),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final double t;
  final double stroke;
  final Color color;
  final Gradient gradient;
  final SlmPalette p;

  _RingProgressPainter(this.t, this.stroke, this.color, this.gradient, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = p.surfaceSunken,
    );
    if (t <= 0) return;
    final sweep = 2 * math.pi * t;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withValues(alpha: 0.55), color, Colors.white.withValues(alpha: 0.9)],
          stops: [0, math.max(0.01, t * 0.85), math.max(0.02, t)],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
    final head = c + Offset(math.cos(-math.pi / 2 + sweep), math.sin(-math.pi / 2 + sweep)) * r;
    canvas.drawCircle(
      head,
      stroke * 1.3,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.75),
          color.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: head, radius: stroke * 1.3)),
    );
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter old) =>
      old.t != t || old.color != color || old.stroke != stroke;
}

/// Segmented lesson progress; segments fill one after another.
class SlmStepProgress extends StatelessWidget {
  final int total;
  final int done;
  final double height;
  final SlmTone tone;

  const SlmStepProgress({
    super.key,
    required this.total,
    required this.done,
    this.height = 8,
    this.tone = SlmTone.emerald,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    final n = math.max(1, total);
    return Semantics(
      value: '$done / $total',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: done.clamp(0, n).toDouble()),
        duration: slmReduceMotion(context) ? Duration.zero : SlmMotion.stagger * 4 * n,
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => Row(
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) SizedBox(width: n > 12 ? 2 : 4),
              Expanded(
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: SlmRadius.pillAll,
                    border: Border.all(color: p.line.withValues(alpha: 0.5)),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (t - i).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: tone.gradient(p),
                        borderRadius: SlmRadius.pillAll,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "3 / 10" style counter with a medal icon and label.
class SlmAchievementCounter extends StatelessWidget {
  final int value;
  final int total;
  final String label;
  final IconData icon;

  const SlmAchievementCounter({
    super.key,
    required this.value,
    required this.total,
    required this.label,
    this.icon = Icons.military_tech_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final big = s.type.number.copyWith(fontSize: 22 * s.layout.scale, color: s.palette.accent);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: s.palette.accent, size: 26 * s.layout.scale),
        const SizedBox(height: SlmSpace.xxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SlmCountUp(value: value, style: big),
            Text(' / $total', style: big.copyWith(fontSize: 14 * s.layout.scale, color: s.palette.inkMuted)),
          ],
        ),
        SlmText(label, role: SlmTextRole.caption, align: TextAlign.center, maxLines: 2),
      ],
    );
  }
}

/// Level row: small static shield emblem, level number + title, XP bar.
class SlmLevelMeter extends StatelessWidget {
  final int level;
  final String levelLabel;
  final String title;
  final double value;
  final String? caption;
  final VoidCallback? onFilled;

  const SlmLevelMeter({
    super.key,
    required this.level,
    required this.levelLabel,
    required this.title,
    required this.value,
    this.caption,
    this.onFilled,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final k = s.layout.scale;
    return Row(
      children: [
        SizedBox(
          width: 46 * k,
          height: 56 * k,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                SlmShieldAssets.body,
                height: 56 * k,
                cacheHeight: (56 * k * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, SlmShieldAssets.pixelHeight),
                filterQuality: FilterQuality.medium,
              ),
              AnimatedSwitcher(
                duration: SlmMotion.slow,
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
                child: Text(
                  '$level',
                  key: ValueKey(level),
                  style: s.type.number.copyWith(
                    fontSize: 18 * k,
                    color: Colors.white,
                    shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: SlmSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SlmText(levelLabel, role: SlmTextRole.overline),
                  const SizedBox(width: SlmSpace.xs),
                  Expanded(child: SlmText(title, role: SlmTextRole.titleSm, maxLines: 1)),
                ],
              ),
              const SizedBox(height: 6),
              SlmXpBar(value: value, onFilled: onFilled),
              if (caption != null) ...[
                const SizedBox(height: 4),
                SlmText(caption!, role: SlmTextRole.caption, maxLines: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
