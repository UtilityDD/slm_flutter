import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/slm_colors.dart';
import 'slm_motion_scope.dart';

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

  void _syncLoop() {
    final run = widget.animate && slmLoopsOn(context);
    if (run && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!run && _loop.isAnimating) {
      _loop.stop();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final shieldH = s * 0.78;
    final shieldW = shieldH * SlmShieldAssets.aspect;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = math.min(SlmShieldAssets.pixelWidth, (shieldW * dpr).round());
    final k = widget.intensity;

    Image layer(String asset, {Color? tint}) => Image.asset(
          asset,
          width: shieldW,
          height: shieldH,
          cacheWidth: cacheW,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcIn,
        );

    final body = layer(SlmShieldAssets.body);
    final shieldRect = Rect.fromCenter(center: Offset(s / 2, s / 2), width: shieldW, height: shieldH);
    final geo = _RingGeometry(center: shieldRect.center, shieldH: shieldH);

    Widget emblem = SizedBox.square(
      dimension: s,
      child: AnimatedBuilder(
        animation: _tick,
        builder: (context, _) {
          final t = _loop.value;
          final e = _enter.value;
          final wave = math.sin(t * 2 * math.pi);
          final pulse = 0.5 + 0.5 * math.sin(t * 4 * math.pi);

          final appear = Curves.easeOut.transform((e / 0.55).clamp(0.0, 1.0));
          final grow = 0.75 + 0.25 * Curves.easeOutBack.transform(e);
          final settle = -0.17 * (1 - Curves.easeOutCubic.transform(e));
          final goldFlash = e < 1 ? math.sin(e * math.pi) : 0.0;

          final bob = wave * s * 0.032;
          final tilt = math.cos(t * 2 * math.pi) * 0.022;

          final glass = Curves.easeInOutSine.transform(((t - 0.52) / 0.3).clamp(0.0, 1.0));

          return Opacity(
            opacity: appear,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(0, bob, 0, 1)
                ..rotateZ(settle + tilt)
                ..scaleByDouble(grow, grow, 1, 1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GlowPainter(
                        center: shieldRect.center,
                        radius: s * 0.5,
                        emerald: (0.14 + 0.08 * pulse) * k,
                        gold: (0.08 + 0.32 * goldFlash) * k,
                      ),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _RingPainter(geo, t, front: false))),
                  Positioned.fromRect(rect: shieldRect, child: body),
                  Positioned.fromRect(
                    rect: shieldRect,
                    child: layer(
                      SlmShieldAssets.glass,
                      tint: SlmColors.emerald400.withValues(alpha: (0.05 + 0.07 * pulse) * k),
                    ),
                  ),
                  if (glass > 0 && glass < 1)
                    Positioned.fromRect(
                      rect: shieldRect,
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (r) => _glassSheen(r, glass, 0.2 * k),
                        child: layer(SlmShieldAssets.glass),
                      ),
                    ),
                  Positioned.fromRect(
                    rect: shieldRect,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => _rimGlint(r, t, (0.7 + 0.3 * goldFlash) * k),
                      child: layer(SlmShieldAssets.rim),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _RingPainter(geo, t, front: true))),
                ],
              ),
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

/// Half of the orbital ring. The rear half paints under the shield and the
/// front half over it, which is what puts the shield inside the ring.
class _RingPainter extends CustomPainter {
  final _RingGeometry g;
  final double t;
  final bool front;

  _RingPainter(this.g, this.t, {required this.front});

  static const _segments = 120;
  static const _light = Offset(-0.6, -0.8);
  static const _silverDark = Color(0xFF6F7B92);
  static const _silverLit = Color(0xFFF2F5FA);
  static const _goldDark = Color(0xFF8A6526);
  static const _goldLit = Color(0xFFF6E2A6);

  @override
  void paint(Canvas canvas, Size size) {
    final spin = t * 2 * math.pi;
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final segs = <_Seg>[];
    for (var i = 0; i < _segments; i++) {
      final p0 = i / _segments * 2 * math.pi;
      final p1 = (i + 1) / _segments * 2 * math.pi;
      final mid = (p0 + p1) / 2;
      final z = _RingGeometry.depth(mid);
      if (front != (z > 0)) continue;

      final d = (z + 1) / 2;
      final n = g.at(mid) - g.center;
      final nl = n.distance == 0 ? Offset.zero : n / n.distance;
      final lambert = math.max(0.0, nl.dx * _light.dx + nl.dy * _light.dy);
      final lit = 0.35 + 0.65 * lambert;

      // Two gold bands ride the ring, so its spin is visible.
      final band = math.pow(0.5 + 0.5 * math.cos(2 * (mid - spin)), 4).toDouble();
      var metal = Color.lerp(
        Color.lerp(_silverDark, _silverLit, lit)!,
        Color.lerp(_goldDark, _goldLit, lit)!,
        band * 0.85,
      )!;
      if (!front) metal = Color.lerp(metal, SlmColors.navy900, 0.45)!;

      segs.add(_Seg(
        a: g.at(p0),
        b: g.at(p1),
        d: d,
        width: g.tube * (0.7 + 0.5 * d),
        metal: metal,
        spec: math.pow(lambert, 10).toDouble(),
      ));
    }

    // One pass per layer, so a segment never paints over its neighbour's core.
    if (front && segs.isNotEmpty) {
      final off = Offset(0, g.tube * 1.0);
      final path = Path()..moveTo(segs.first.a.dx + off.dx, segs.first.a.dy + off.dy);
      for (final s in segs) {
        path.lineTo(s.b.dx + off.dx, s.b.dy + off.dy);
      }
      shadow
        ..strokeWidth = g.tube * 2.4
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.16);
      canvas.drawPath(path, shadow);
    }
    for (final s in segs) {
      edge
        ..strokeWidth = s.width
        ..color = Color.lerp(s.metal, Colors.black, 0.5)!;
      canvas.drawLine(s.a, s.b, edge);
    }
    for (final s in segs) {
      core
        ..strokeWidth = s.width * 0.62
        ..color = s.metal;
      canvas.drawLine(s.a, s.b, core);
    }
    for (final s in segs) {
      final off = _light * (s.width * 0.16);
      shine
        ..strokeWidth = s.width * 0.22
        ..color = Color.lerp(s.metal, Colors.white, (0.25 + 0.75 * s.spec) * (front ? 1 : 0.5))!;
      canvas.drawLine(s.a + off, s.b + off, shine);
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
  bool shouldRepaint(covariant _RingPainter old) => old.t != t || old.front != front || old.g.a != g.a;
}

class _Seg {
  final Offset a;
  final Offset b;
  final double d;
  final double width;
  final Color metal;
  final double spec;

  const _Seg({
    required this.a,
    required this.b,
    required this.d,
    required this.width,
    required this.metal,
    required this.spec,
  });
}

class _GlowPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double emerald;
  final double gold;

  _GlowPainter({required this.center, required this.radius, required this.emerald, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.emerald != emerald || old.gold != gold || old.radius != radius || old.center != center;
}
