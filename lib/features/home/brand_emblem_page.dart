import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart' show SlmSfx, ZlMusic;

/// The Home shield opened big (owner, 2026-11-15): the emblem flies from the
/// Home card to the centre over a blurred emerald veil, then the name
/// «মৃত্যুহীন কর্মপথ» rises in word by word («কর্মপথ» in gold) and a thin gold
/// line with a star draws outward under it. A soft chime plays (unless the
/// app's sound is off). Tap anywhere, swipe down or back closes it and the
/// shield flies home. No tagline, no progress (owner's choices).
abstract final class BrandEmblem {
  /// Shared by the Home shield and this page, so the emblem flies between them.
  static const heroTag = 'brand-emblem';
  static const chimeAsset = 'sounds/brand_chime.ogg';
  static const word1 = 'মৃত্যুহীন';
  static const word2 = 'কর্মপথ';

  /// Plays the chime; tests swap it for a silent one.
  static Future<void> Function() chime = () => SlmSfx.play(chimeAsset, volume: 0.6);

  /// Opens the page over [context]'s navigator.
  static Future<void> open(BuildContext context) {
    final reduce = slmReduceMotion(context);
    HapticFeedback.lightImpact();
    if (!ZlMusic.muted) unawaited(chime());
    return Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: '$word1 $word2',
      transitionDuration: reduce ? const Duration(milliseconds: 150) : const Duration(milliseconds: 560),
      reverseTransitionDuration: reduce ? const Duration(milliseconds: 120) : const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => const BrandEmblemPage(),
      transitionsBuilder: (_, animation, _, child) => child,
    ));
  }
}

class BrandEmblemPage extends StatefulWidget {
  const BrandEmblemPage({super.key});

  @override
  State<BrandEmblemPage> createState() => _BrandEmblemPageState();
}

class _BrandEmblemPageState extends State<BrandEmblemPage> with SingleTickerProviderStateMixin {
  // The name and the line, after the shield has nearly landed.
  late final AnimationController _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250));
  bool _started = false;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (slmReduceMotion(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  Animation<double> _part(double begin, double end) =>
      CurvedAnimation(parent: _reveal, curve: Interval(begin, end, curve: Curves.easeOutCubic));

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final reduce = slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final shield = math.min(240.0, math.min(size.width, size.height) * 0.6);
    final fontSize = math.min(38.0, size.width / 9.5);
    final style = bangla(fontSize: fontSize, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.25);

    Widget word(String text, Color color, Animation<double> a) => AnimatedBuilder(
          animation: a,
          builder: (_, child) => Opacity(
            opacity: a.value,
            child: Transform.translate(offset: Offset(0, (1 - a.value) * 14), child: child),
          ),
          child: Text(text, style: style.copyWith(color: color)),
        );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSafetyShield(
          size: shield,
          entrance: false,
          animate: !reduce,
          intensity: 1.15,
          heroTag: BrandEmblem.heroTag,
        ),
        SizedBox(height: shield * 0.14),
        // The text fades with the route too, so on close it goes before the
        // shield flies back.
        FadeTransition(
          opacity: CurvedAnimation(parent: route, curve: const Interval(0.5, 1)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: fontSize * 0.3,
                children: [
                  word(BrandEmblem.word1, SlmColors.ivory, _part(0.30, 0.62)),
                  word(BrandEmblem.word2, SlmColors.gold300, _part(0.44, 0.76)),
                ],
              ),
              const SizedBox(height: 14),
              _GoldRule(progress: _part(0.68, 1.0), width: math.min(220.0, size.width * 0.55)),
            ],
          ),
        ),
      ],
    );

    return PopScope(
      onPopInvokedWithResult: (_, _) => _closing = true,
      child: Semantics(
        label: '${BrandEmblem.word1} ${BrandEmblem.word2}',
        hint: 'বন্ধ করতে যেকোনো জায়গায় ট্যাপ করুন',
        button: true,
        child: GestureDetector(
          key: const ValueKey('brand-emblem-page'),
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 250) _close();
          },
          child: AnimatedBuilder(
            animation: route,
            builder: (_, child) {
              final t = Curves.easeOut.transform(route.value.clamp(0.0, 1.0));
              final veil = DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.05,
                    colors: [
                      SlmColors.emerald900.withValues(alpha: 0.80 * t),
                      SlmColors.navy950.withValues(alpha: 0.92 * t),
                    ],
                  ),
                ),
                child: child,
              );
              if (reduce || t == 0) return veil;
              return BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t), child: veil);
            },
            child: SafeArea(child: Center(child: content)),
          ),
        ),
      ),
    );
  }
}

/// A thin gold line that draws outward from a small centre star.
class _GoldRule extends StatelessWidget {
  final Animation<double> progress;
  final double width;

  const _GoldRule({required this.progress, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 18,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, _) => CustomPaint(painter: _RulePainter(progress.value)),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  final double t;

  _RulePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final c = size.center(Offset.zero);
    final half = (size.width / 2 - 14) * t;
    for (final dir in [-1.0, 1.0]) {
      final a = Offset(c.dx + dir * 12, c.dy);
      final b = Offset(c.dx + dir * (12 + half), c.dy);
      final paint = Paint()
        ..strokeWidth = 1.4
        ..shader = ui.Gradient.linear(a, b, [SlmColors.gold300, SlmColors.gold300.withValues(alpha: 0)]);
      canvas.drawLine(a, b, paint);
    }
    // Four-point star, scaling in.
    final r = 7.0 * Curves.easeOutBack.transform(math.min(1, t * 2.5));
    final star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(star, Paint()..color = SlmColors.gold200);
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.t != t;
}
