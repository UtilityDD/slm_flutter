import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/slm_colors.dart';
import 'slm_motion_scope.dart';
import 'slm_motion_widgets.dart';

/// Layers cut from `assets/brand/source/shield_reference.jpg`. All three share
/// one crop, so they stack pixel for pixel.
abstract final class SlmShieldAssets {
  static const body = 'assets/brand/shield_body.webp';
  static const rim = 'assets/brand/shield_rim.webp';
  static const glass = 'assets/brand/shield_glass.webp';

  /// Natural pixel size of the layers.
  static const pixelWidth = 295;
  static const pixelHeight = 381;
  static const aspect = pixelWidth / pixelHeight;
}

/// Ring geometry fitted to the ring in the reference art, in units of the
/// shield height, measured from the shield centre.
abstract final class _Ring {
  static const cx = 0.007;
  static const cy = -0.0775;
  static const major = 0.5374;
  static const minor = 0.1816;
  static const angle = -33.28 * math.pi / 180;
}

/// Replays the entrance of the [AnimatedSafetyShield] it is attached to.
class AnimatedSafetyShieldController extends ChangeNotifier {
  void replayEntrance() => notifyListeners();
}

/// The মৃত্যুহীন পথ emblem: the emerald-and-gold shield with a 3D orbital
/// ring, travelling rim light and a gentle float.
///
/// Background is transparent; the widget is a [size] × [size] square.
class AnimatedSafetyShield extends StatefulWidget {
  final double size;

  /// Continuous float, ring spin and lighting.
  final bool animate;

  /// Play the 900 ms entrance when first shown.
  final bool entrance;

  final AnimatedSafetyShieldController? controller;

  /// One ring revolution; float and lighting loop on the same clock.
  final Duration revolution;

  /// Scales glow and light strength (0 = none, 1 = default).
  final double intensity;

  /// Wraps the emblem in a [Hero] with this tag.
  final Object? heroTag;

  const AnimatedSafetyShield({
    super.key,
    this.size = 220,
    this.animate = true,
    this.entrance = true,
    this.controller,
    this.revolution = const Duration(seconds: 6),
    this.intensity = 1,
    this.heroTag,
  });

  @override
  State<AnimatedSafetyShield> createState() => _AnimatedSafetyShieldState();
}

class _AnimatedSafetyShieldState extends State<AnimatedSafetyShield> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.revolution);
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.entrance ? 0 : 1,
  );
  late final Listenable _tick = Listenable.merge([_loop, _enter]);
  int? _token;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_replay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = slmReplayToken(context);
    if (_token == null) {
      _token = token;
      if (slmReduceMotion(context)) {
        _enter.value = 1;
      } else if (widget.entrance) {
        _enter.forward();
      }
    } else if (token != _token) {
      _token = token;
      _replay();
    }
    _syncLoop();
  }

  @override
  void didUpdateWidget(covariant AnimatedSafetyShield old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_replay);
      widget.controller?.addListener(_replay);
    }
    if (old.revolution != widget.revolution) _loop.duration = widget.revolution;
    _syncLoop();
  }

  // Stops with remove-animations; covered routes mute the ticker (TickerMode).
  void _syncLoop() => slmSyncLoop(context, _loop, enabled: widget.animate);

  void _replay() {
    if (slmReduceMotion(context)) return;
    _enter.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_replay);
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  // Ring segment geometry depends only on the shield height, so it is built
  // once per size instead of once per frame.
  _RingCache? _ring;

  _RingCache _ringFor(Offset center, double shieldH) {
    final r = _ring;
    if (r != null && r.center == center && r.shieldH == shieldH) return r;
    return _ring = _RingCache(center, shieldH);
  }

  double get _pulse => 0.5 + 0.5 * math.sin(_loop.value * 4 * math.pi);
  double get _goldFlash => _enter.value < 1 ? math.sin(_enter.value * math.pi) : 0.0;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final shieldH = s * 0.78;
    final shieldW = shieldH * SlmShieldAssets.aspect;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final rawCache = (shieldW * dpr).round();
    final cacheW = rawCache <= 0 ? null : math.min(SlmShieldAssets.pixelWidth, rawCache);
    final k = widget.intensity;

    Image layer(String asset, {Color? tint, Animation<double>? opacity}) => Image.asset(
          asset,
          width: shieldW,
          height: shieldH,
          cacheWidth: cacheW,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcIn,
          opacity: opacity,
        );

    final shieldRect = Rect.fromCenter(center: Offset(s / 2, s / 2), width: shieldW, height: shieldH);
    final ring = _ringFor(shieldRect.center, shieldH);

    // Everything below is built once; the loop only repaints it. The painters
    // and masks read the controllers at paint time, and the emerald tint is
    // an image opacity (same pixels as a tint colour with that alpha).
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GlowPainter(
              repaint: _tick,
              center: shieldRect.center,
              radius: s * 0.5,
              emerald: () => (0.14 + 0.08 * _pulse) * k,
              gold: () => (0.08 + 0.32 * _goldFlash) * k,
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _RingPainter(ring, _loop, front: false))),
        Positioned.fromRect(rect: shieldRect, child: layer(SlmShieldAssets.body)),
        Positioned.fromRect(
          rect: shieldRect,
          child: layer(
            SlmShieldAssets.glass,
            tint: SlmColors.emerald400,
            opacity: _loop.drive(_GlassTint(k)),
          ),
        ),
        Positioned.fromRect(
          rect: shieldRect,
          child: SlmLiveShaderMask(
            blendMode: BlendMode.srcIn,
            repaint: _loop,
            hideWhenIdle: true,
            shader: (r) {
              final glass = Curves.easeInOutSine.transform(((_loop.value - 0.52) / 0.3).clamp(0.0, 1.0));
              return glass > 0 && glass < 1 ? _glassSheen(r, glass, 0.2 * k) : null;
            },
            child: layer(SlmShieldAssets.glass),
          ),
        ),
        Positioned.fromRect(
          rect: shieldRect,
          child: SlmLiveShaderMask(
            blendMode: BlendMode.srcIn,
            repaint: _tick,
            shader: (r) => _rimGlint(r, _loop.value, (0.7 + 0.3 * _goldFlash) * k),
            child: layer(SlmShieldAssets.rim),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _RingPainter(ring, _loop, front: true))),
      ],
    );

    Widget emblem = SizedBox.square(
      dimension: s,
      child: AnimatedBuilder(
        animation: _tick,
        child: stack,
        builder: (context, child) {
          final t = _loop.value;
          final e = _enter.value;
          final wave = math.sin(t * 2 * math.pi);

          final appear = Curves.easeOut.transform((e / 0.55).clamp(0.0, 1.0));
          final grow = 0.75 + 0.25 * Curves.easeOutBack.transform(e);
          final settle = -0.17 * (1 - Curves.easeOutCubic.transform(e));

          final bob = wave * s * 0.032;
          final tilt = math.cos(t * 2 * math.pi) * 0.022;

          return Opacity(
            opacity: appear,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(0, bob, 0, 1)
                ..rotateZ(settle + tilt)
                ..scaleByDouble(grow, grow, 1, 1),
              child: child,
            ),
          );
        },
      ),
    );

    emblem = RepaintBoundary(child: emblem);
    if (widget.heroTag != null) {
      final size = widget.size;
      final revolution = widget.revolution;
      emblem = Hero(
        tag: widget.heroTag!,
        flightShuttleBuilder: (_, _, _, _, _) => FittedBox(
          child: AnimatedSafetyShield(size: size, entrance: false, revolution: revolution),
        ),
        child: emblem,
      );
    }
    return Semantics(label: 'মৃত্যুহীন পথ শিল্ড', image: true, child: emblem);
  }

  /// Two arcs of light orbiting the gold border, one per revolution.
  static Shader _rimGlint(Rect r, double t, double a) {
    final hi = a.clamp(0.0, 1.0);
    return SweepGradient(
      center: const Alignment(0, -0.05),
      colors: [
        const Color(0x00FFF3D0),
        SlmColors.gold200.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.85 * hi),
        SlmColors.gold200.withValues(alpha: 0),
        const Color(0x00FFF3D0),
        SlmColors.gold200.withValues(alpha: 0),
        SlmColors.gold100.withValues(alpha: 0.35 * hi),
        SlmColors.gold200.withValues(alpha: 0),
        const Color(0x00FFF3D0),
      ],
      stops: const [0, 0.05, 0.09, 0.13, 0.5, 0.55, 0.585, 0.62, 1],
      transform: GradientRotation(t * 2 * math.pi),
    ).createShader(r);
  }

  /// One diagonal glint across the glass once per loop.
  static Shader _glassSheen(Rect r, double p, double a) {
    final x = -0.6 + p * 2.2;
    return LinearGradient(
      begin: Alignment(x - 0.5, -1),
      end: Alignment(x + 0.5, 1),
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: a),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.35, 0.5, 0.65],
    ).createShader(r);
  }
}

class _RingGeometry {
  final Offset center;
  final Offset u;
  final Offset w;
  final double a;
  final double b;
  final double tube;

  _RingGeometry({required Offset center, required double shieldH})
      : center = center + Offset(_Ring.cx * shieldH, _Ring.cy * shieldH),
        u = Offset(math.cos(_Ring.angle), math.sin(_Ring.angle)),
        w = Offset(-math.sin(_Ring.angle), math.cos(_Ring.angle)),
        a = _Ring.major * shieldH,
        b = _Ring.minor * shieldH,
        tube = shieldH * 0.02;

  Offset at(double phi) => center + u * (a * math.cos(phi)) + w * (b * math.sin(phi));

  /// +1 nearest the viewer, −1 farthest. The lower arc is the front.
  static double depth(double phi) => math.sin(phi);
}

/// Emerald tint strength over the glass, on the shield clock.
class _GlassTint extends Animatable<double> {
  final double k;

  const _GlassTint(this.k);

  @override
  double transform(double t) {
    final pulse = 0.5 + 0.5 * math.sin(t * 4 * math.pi);
    return ((0.05 + 0.07 * pulse) * k).clamp(0.0, 1.0);
  }
}

/// Per-size ring segments. Everything here is independent of the spin, so
/// it is computed once per shield size; only the gold band moves per frame.
class _RingCache {
  final Offset center;
  final double shieldH;
  final _RingGeometry g;
  final List<_Seg> front;
  final List<_Seg> back;
  final Path frontShadow;

  factory _RingCache(Offset center, double shieldH) {
    final g = _RingGeometry(center: center, shieldH: shieldH);
    return _RingCache._(center, shieldH, g, _segs(g, true), _segs(g, false));
  }

  _RingCache._(this.center, this.shieldH, this.g, this.front, this.back) : frontShadow = _shadow(g, front);

  static List<_Seg> _segs(_RingGeometry g, bool front) {
    final segs = <_Seg>[];
    for (var i = 0; i < _RingPainter._segments; i++) {
      final p0 = i / _RingPainter._segments * 2 * math.pi;
      final p1 = (i + 1) / _RingPainter._segments * 2 * math.pi;
      final mid = (p0 + p1) / 2;
      final z = _RingGeometry.depth(mid);
      if (front != (z > 0)) continue;

      final d = (z + 1) / 2;
      final n = g.at(mid) - g.center;
      final nl = n.distance == 0 ? Offset.zero : n / n.distance;
      final lambert = math.max(0.0, nl.dx * _RingPainter._light.dx + nl.dy * _RingPainter._light.dy);
      final lit = 0.35 + 0.65 * lambert;
      final width = g.tube * (0.7 + 0.5 * d);
      final spec = math.pow(lambert, 10).toDouble();
      final off = _RingPainter._light * (width * 0.16);
      final a = g.at(p0);
      final b = g.at(p1);

      segs.add(_Seg(
        mid: mid,
        a: a,
        b: b,
        shineA: a + off,
        shineB: b + off,
        width: width,
        silver: Color.lerp(_RingPainter._silverDark, _RingPainter._silverLit, lit)!,
        gold: Color.lerp(_RingPainter._goldDark, _RingPainter._goldLit, lit)!,
        shine: (0.25 + 0.75 * spec) * (front ? 1 : 0.5),
      ));
    }
    return segs;
  }

  static Path _shadow(_RingGeometry g, List<_Seg> segs) {
    final path = Path();
    if (segs.isEmpty) return path;
    final off = Offset(0, g.tube * 1.0);
    path.moveTo(segs.first.a.dx + off.dx, segs.first.a.dy + off.dy);
    for (final s in segs) {
      path.lineTo(s.b.dx + off.dx, s.b.dy + off.dy);
    }
    return path;
  }
}

/// Half of the orbital ring. The rear half paints under the shield and the
/// front half over it, which is what puts the shield inside the ring.
class _RingPainter extends CustomPainter {
  final _RingCache ring;
  final Animation<double> loop;
  final bool front;

  _RingPainter(this.ring, this.loop, {required this.front}) : super(repaint: loop);

  static const _segments = 120;
  static const _light = Offset(-0.6, -0.8);
  static const _silverDark = Color(0xFF6F7B92);
  static const _silverLit = Color(0xFFF2F5FA);
  static const _goldDark = Color(0xFF8A6526);
  static const _goldLit = Color(0xFFF6E2A6);

  static final _shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _core = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _shine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt;

  @override
  void paint(Canvas canvas, Size size) {
    final g = ring.g;
    final spin = loop.value * 2 * math.pi;
    final segs = front ? ring.front : ring.back;

    // Only the gold band depends on the spin.
    final metals = List<Color>.filled(segs.length, const Color(0x00000000));
    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      // Two gold bands ride the ring, so its spin is visible.
      final band = math.pow(0.5 + 0.5 * math.cos(2 * (s.mid - spin)), 4).toDouble();
      var metal = Color.lerp(s.silver, s.gold, band * 0.85)!;
      if (!front) metal = Color.lerp(metal, SlmColors.navy900, 0.45)!;
      metals[i] = metal;
    }

    // One pass per layer, so a segment never paints over its neighbour's core.
    if (front && segs.isNotEmpty) {
      _shadowPaint
        ..strokeWidth = g.tube * 2.4
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.16);
      canvas.drawPath(ring.frontShadow, _shadowPaint);
    }
    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      _edge
        ..strokeWidth = s.width
        ..color = Color.lerp(metals[i], Colors.black, 0.5)!;
      canvas.drawLine(s.a, s.b, _edge);
    }
    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      _core
        ..strokeWidth = s.width * 0.62
        ..color = metals[i];
      canvas.drawLine(s.a, s.b, _core);
    }
    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      _shine
        ..strokeWidth = s.width * 0.22
        ..color = Color.lerp(metals[i], Colors.white, s.shine)!;
      canvas.drawLine(s.shineA, s.shineB, _shine);
    }

    for (var k = 0; k < 3; k++) {
      final phi = spin + k * 2 * math.pi / 3;
      final z = _RingGeometry.depth(phi);
      if (front != (z > 0)) continue;
      _bead(canvas, g.at(phi), g.tube * (0.85 + 0.55 * (z + 1) / 2), back: !front);
    }
  }

  void _bead(Canvas canvas, Offset c, double r, {required bool back}) {
    final rect = Rect.fromCircle(center: c, radius: r);
    final dim = back ? 0.35 : 0.0;
    canvas.drawCircle(
      c,
      r * 2.1,
      Paint()
        ..shader = RadialGradient(colors: [
          SlmColors.gold300.withValues(alpha: back ? 0.12 : 0.32),
          SlmColors.gold300.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: c, radius: r * 2.1)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          colors: [
            Color.lerp(Colors.white, SlmColors.navy900, dim)!,
            Color.lerp(SlmColors.gold300, SlmColors.navy900, dim)!,
            Color.lerp(SlmColors.gold700, SlmColors.navy900, dim)!,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      !identical(old.ring, ring) || old.front != front || !identical(old.loop, loop);
}

class _Seg {
  final double mid;
  final Offset a;
  final Offset b;
  final Offset shineA;
  final Offset shineB;
  final double width;
  final Color silver;
  final Color gold;

  /// Highlight mix toward white (spec and front/back already applied).
  final double shine;

  const _Seg({
    required this.mid,
    required this.a,
    required this.b,
    required this.shineA,
    required this.shineB,
    required this.width,
    required this.silver,
    required this.gold,
    required this.shine,
  });
}

class _GlowPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double Function() emerald;
  final double Function() gold;

  _GlowPainter({
    required Listenable repaint,
    required this.center,
    required this.radius,
    required this.emerald,
    required this.gold,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final emerald = this.emerald();
    final gold = this.gold();
    if (emerald > 0) {
      final r = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            SlmColors.emerald500.withValues(alpha: emerald.clamp(0.0, 1.0)),
            SlmColors.emerald500.withValues(alpha: 0),
          ]).createShader(r),
      );
    }
    if (gold > 0) {
      final c = center + Offset(0, -radius * 0.12);
      final r = Rect.fromCircle(center: c, radius: radius * 0.8);
      canvas.drawCircle(
        c,
        radius * 0.8,
        Paint()
          ..shader = RadialGradient(colors: [
            SlmColors.gold300.withValues(alpha: gold.clamp(0.0, 1.0)),
            SlmColors.gold300.withValues(alpha: 0),
          ]).createShader(r),
      );
    }
  }

  // Values are read at paint time; the repaint listenable drives changes.
  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.radius != radius || old.center != center || old.emerald() != emerald() || old.gold() != gold();
}
