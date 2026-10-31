import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/slm_colors.dart';
import 'slm_motion_scope.dart';

/// A restrained burst of gold and emerald sparks with a thin shock ring.
/// Plays each time [trigger] changes (and on mount when [playOnMount]).
/// Draws outside its own box; give it room or wrap it in a [Stack].
class SlmSparkBurst extends StatefulWidget {
  final Object? trigger;
  final bool playOnMount;
  final double radius;
  final int count;
  final Duration duration;
  final List<Color> colors;

  const SlmSparkBurst({
    super.key,
    this.trigger,
    this.playOnMount = false,
    this.radius = 70,
    this.count = 16,
    this.duration = const Duration(milliseconds: 950),
    this.colors = const [SlmColors.gold300, SlmColors.emerald300, SlmColors.gold100, SlmColors.gold400],
  });

  @override
  State<SlmSparkBurst> createState() => _SlmSparkBurstState();
}

class _SlmSparkBurstState extends State<SlmSparkBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration, value: 1);
  late List<_Spark> _sparks = _make(0);
  var _seed = 0;

  List<_Spark> _make(int seed) {
    final r = math.Random(seed * 7919 + 13);
    return List.generate(widget.count, (i) {
      final angle = (i / widget.count) * 2 * math.pi + (r.nextDouble() - 0.5) * 0.5;
      return _Spark(
        dir: Offset(math.cos(angle), math.sin(angle)),
        reach: 0.55 + r.nextDouble() * 0.45,
        size: 2.2 + r.nextDouble() * 2.6,
        color: widget.colors[i % widget.colors.length],
        star: i.isEven,
        spin: (r.nextDouble() - 0.5) * 4,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.playOnMount && _c.value == 1 && _seed == 0) _play();
  }

  @override
  void didUpdateWidget(covariant SlmSparkBurst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _play();
  }

  void _play() {
    if (slmReduceMotion(context)) return;
    _seed++;
    _sparks = _make(_seed);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SparkPainter(_c, _sparks, widget.radius),
          size: Size.square(widget.radius * 2),
        ),
      ),
    );
  }
}

class _Spark {
  final Offset dir;
  final double reach;
  final double size;
  final Color color;
  final bool star;
  final double spin;

  const _Spark({
    required this.dir,
    required this.reach,
    required this.size,
    required this.color,
    required this.star,
    required this.spin,
  });
}

class _SparkPainter extends CustomPainter {
  final Animation<double> t;
  final List<_Spark> sparks;
  final double radius;

  _SparkPainter(this.t, this.sparks, this.radius) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    final c = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(v);
    final fade = 1 - Curves.easeIn.transform(v);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * fade
      ..color = SlmColors.gold300.withValues(alpha: 0.5 * fade);
    canvas.drawCircle(c, radius * 0.25 + radius * 0.75 * out, ring);

    final paint = Paint();
    for (final s in sparks) {
      final p = c + s.dir * (radius * s.reach * out) + Offset(0, 18 * v * v);
      final r = s.size * (1 - 0.5 * v);
      paint.color = s.color.withValues(alpha: fade);
      if (s.star) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(s.spin * v);
        final path = Path()
          ..moveTo(0, -r * 1.6)
          ..lineTo(r * 0.4, 0)
          ..lineTo(0, r * 1.6)
          ..lineTo(-r * 0.4, 0)
          ..close()
          ..moveTo(-r * 1.6, 0)
          ..lineTo(0, r * 0.4)
          ..lineTo(r * 1.6, 0)
          ..lineTo(0, -r * 0.4)
          ..close();
        canvas.drawPath(path, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(p, r * 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.sparks != sparks || old.radius != radius;
}
