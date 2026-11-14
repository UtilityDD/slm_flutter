import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

// The brand splash on a cold start, drawn in code (vector): crisp on any
// screen and on exactly the app's navy, so the native launch screen (navy +
// logo, tool/brand_assets.py), this intro and the app join without a seam.
// It recreates the owner's intro video (blueprint dial → the gear's 12 teeth
// fly in → the ring → the bolt strikes → "SmartLineman" + "সুরক্ষা প্রশিক্ষণ
// সিরিজ") to its own soundtrack (assets/brand/intro.m4a, taken unchanged from
// that video). The logo geometry is measured from the app icon
// (assets/brand/source/app_icon_512.png, 512 px units, centre 256).
//
// Since the "home → one tap → ladder" redesign (Nov 2026) only the last
// beat plays: the logo settles into the lockup and the title and Bangla line
// are revealed ([IntroOverlay.from] → [IntroOverlay.until], 1.2 s, then a
// 0.3 s fade: at most 1.5 s), with the soundtrack from the same moment so
// its last hit lands as Home appears. A tap anywhere skips it. The app
// (Home) builds underneath meanwhile; [IntroGate.warmUp] loads what the
// first taps would wait for and runs on after the splash if it needs to.
// Reduced motion shows the still lockup briefly; never blocks the app.

/// The brand navy (the logo's own background, as the native launch screen).
const introNavy = Color(0xFF0E162B);
const brandYellow = Color(0xFFFAC70C);
const brandBlue = Color(0xFF142A4B);
const _cyan = Color(0xFF2CC5C9);
const _titleWhite = Color(0xFFF0F3FE);

/// The intro's sound; swapped for a silent one in tests.
abstract class IntroSound {
  /// Plays the soundtrack from [from] (the splash starts late in it).
  Future<void> play({Duration from = Duration.zero});
  Future<void> stop();
}

class AssetIntroSound implements IntroSound {
  AudioPlayer? _player;

  @override
  Future<void> play({Duration from = Duration.zero}) async {
    try {
      final p = _player = AudioPlayer()..positionUpdater = null;
      await p.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
      await p.setReleaseMode(ReleaseMode.release);
      await p.setVolume(0.8);
      await p.play(AssetSource(IntroGate.soundAsset), position: from);
      unawaited(p.onPlayerComplete.first.then((_) {
        if (identical(_player, p)) _player = null;
        return p.dispose();
      }).catchError((_) {}));
    } catch (_) {
      // No sound is fine; the intro plays on.
    }
  }

  @override
  Future<void> stop() async {
    final p = _player;
    _player = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }
}

/// Puts the intro over [child] (the app) until it is done.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.child, this.enabled = true, this.warmUp, this.sound});

  final Widget child;

  /// Background loading started with the intro (given this gate's context,
  /// which lives as long as the app).
  final Future<void> Function(BuildContext context)? warmUp;

  /// False: the app straight away (tests of the app shell).
  final bool enabled;

  /// Null: the soundtrack from [soundAsset].
  final IntroSound? sound;

  static const soundAsset = 'brand/intro.m4a';

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  late bool _showing = widget.enabled;
  // Owned here, not by the overlay: the last hit plays as the app appears.
  late final IntroSound _sound = widget.sound ?? AssetIntroSound();

  @override
  void initState() {
    super.initState();
    final warm = widget.warmUp;
    if (widget.enabled && warm != null) {
      // After the first frame, so the native splash hands over first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(warm(context));
      });
    }
  }

  @override
  void dispose() {
    unawaited(_sound.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showing)
          IntroOverlay(
            key: const ValueKey('intro'),
            sound: _sound,
            onDone: () {
              if (mounted) setState(() => _showing = false);
            },
          ),
      ],
    );
  }
}

/// The splash layer: the lockup beat with its sound → fade out → [onDone].
/// A tap anywhere ends it at once.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key, required this.sound, required this.onDone});
  final IntroSound sound;
  final VoidCallback onDone;

  /// The drawing's timeline is 0–6 s (the soundtrack's length); the splash
  /// plays [from] → [until] of it in real time, then fades for [fade].
  static const from = 3.85;
  static const until = 5.05;
  static const length = Duration(milliseconds: 1200);
  static const fade = Duration(milliseconds: 300);

  /// Splash start to the app fully shown, at most.
  static const total = Duration(milliseconds: 1500);

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: IntroOverlay.length);
  var _leaving = false;
  var _done = false;
  var _still = false;
  Timer? _stillTimer;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    // Reduced motion: the still lockup for a moment, no sound, a short fade.
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _still = true);
      _stillTimer = Timer(const Duration(milliseconds: 700), _leave);
      return;
    }
    unawaited(widget.sound.play(from: Duration(milliseconds: (IntroOverlay.from * 1000).round())));
    unawaited(_c.forward());
  }

  void _onTick() {
    if (_c.isCompleted) _leave();
  }

  void _skip() {
    unawaited(widget.sound.stop());
    _leave();
  }

  void _leave() {
    if (_leaving || !mounted) return;
    _stillTimer?.cancel();
    setState(() => _leaving = true);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _c.stop();
    widget.onDone();
  }

  @override
  void dispose() {
    _stillTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: introNavy),
      child: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: quiet ? const Duration(milliseconds: 150) : IntroOverlay.fade,
        curve: Curves.easeOut,
        onEnd: () {
          if (_leaving) _finish();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A tap anywhere skips; the app under it waits meanwhile.
          onTap: _leaving ? null : _skip,
          child: ColoredBox(
            color: introNavy,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => CustomPaint(
                      painter: BrandIntroPainter(
                        t: _still
                            ? IntroOverlay.until
                            : IntroOverlay.from + _c.value * (IntroOverlay.until - IntroOverlay.from),
                        title: _titleStyle,
                        subtitle: bangla(fontSize: 17, fontWeight: FontWeight.w600, color: _titleWhite),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _titleStyle = TextStyle(fontFamily: 'PoppinsBrand', fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.0);
}

// ---------------------------------------------------------------------------
// The logo, in icon units (512 px icon, centre at 0,0, y down).

abstract final class BrandLogo {
  /// Gear: 12 teeth, a tooth centred at 0° (top), every 30°; the yellow
  /// stroke's centre line; the outer edge is at 169 (tip) / 146 (root).
  static const teeth = 12;
  static const tipC = 162.0, rootC = 139.5, stroke = 14.0;
  static const tipO = 169.0, rootO = 146.0;
  static const tipHalf = 7.6, baseHalf = 10.8;

  /// Ring: centre radius and width; the blue disc inside.
  static const ringR = 107.5, ringW = 17.0;

  /// The bolt (measured from the icon).
  static const bolt = [
    Offset(-19, -170), Offset(20, -168), Offset(28, -122), Offset(0, -20), //
    Offset(60, -18), Offset(-42, 162), Offset(-3, 20), Offset(-62, 18),
  ];

  /// The logo's size for scaling (tooth tip to tooth tip).
  static const span = 2 * tipO;

  static double _r(double deg, double tip, double root) {
    final d = ((deg + 15) % 30 + 30) % 30 - 15;
    final a = d.abs();
    if (a <= tipHalf) return tip;
    if (a >= baseHalf) return root;
    return tip + (root - tip) * (a - tipHalf) / (baseHalf - tipHalf);
  }

  static Offset _p(double deg, double r) {
    final a = deg * math.pi / 180;
    return Offset(r * math.sin(a), -r * math.cos(a));
  }

  /// The gear outline from [from]° to [to]° (closed when the whole way round).
  static Path outline(double from, double to, {bool outer = false}) {
    final tip = outer ? tipO : tipC, root = outer ? rootO : rootC;
    final path = Path();
    var first = true;
    for (var d = from; d <= to + 1e-6; d += 0.25) {
      final p = _p(d, _r(d, tip, root));
      if (first) {
        path.moveTo(p.dx, p.dy);
        first = false;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }

  static final Path gearFill = outline(0, 360, outer: true)..close();
  static final Path gearStroke = outline(0, 360)..close();

  /// Tooth piece [i]: one pitch of the outline, centred on the tooth.
  static final List<Path> pieces = [for (var i = 0; i < teeth; i++) outline(i * 30.0 - 15, i * 30.0 + 15)];

  static final Path boltPath = Path()..addPolygon(bolt, true);
}

// ---------------------------------------------------------------------------

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _ease(double x) => Curves.easeOutCubic.transform(x);
double _inOut(double x) => Curves.easeInOutCubic.transform(x);

/// Paints the intro at time [t] seconds (0–6).
class BrandIntroPainter extends CustomPainter {
  BrandIntroPainter({required this.t, required this.title, required this.subtitle});
  final double t;
  final TextStyle title;
  final TextStyle subtitle;

  static const titleText = 'SmartLineman';
  static const subtitleBn = 'সুরক্ষা প্রশিক্ষণ সিরিজ';

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // The source video's frame was 464 x 832: one unit of it.
    final u = math.min(w / 464, h / 832);
    final centre = Offset(w / 2, h / 2);

    _background(canvas, size, u);
    _blueprint(canvas, size, centre, u);

    // The logo: assembled at the centre, then up and smaller for the lockup.
    final lift = _inOut(_seg(t, 3.45, 4.05));
    final logoAt = Offset(w / 2, h / 2 + (h * 0.40 - h / 2) * lift);
    final kA = 135 * u / BrandLogo.tipO, kL = 95 * u / BrandLogo.tipO;
    var k = kA + (kL - kA) * lift;
    // A small kick when the bolt lands.
    k *= 1 + 0.06 * math.sin(math.pi * _seg(t, 2.58, 2.85));

    _handover(canvas, centre, u);
    _gear(canvas, logoAt, k, u);
    _strike(canvas, logoAt, k, u, size);
    _glint(canvas, logoAt, k);
    _lockup(canvas, size, logoAt, u);
  }

  void _background(Canvas canvas, Size size, double u) {
    // Flat navy at the start and the end (the splash and the app); a soft
    // light behind the logo in between.
    final glow = _seg(t, 0.15, 0.8) * 0.55;
    if (glow <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.46);
    final r = math.max(size.width, size.height) * 0.7;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [const Color(0xFF22355F).withValues(alpha: glow), const Color(0x000E162B)]),
    );
  }

  /// The native splash's logo (144 dp, centred) fades as the grid comes.
  void _handover(Canvas canvas, Offset centre, double u) {
    final a = 1 - _seg(t, 0.08, 0.45);
    if (a <= 0) return;
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, a));
    _logo(canvas, centre, 144 / BrandLogo.span, ring: 1, bolt: 1, fill: 1);
    canvas.restore();
  }

  void _blueprint(Canvas canvas, Size size, Offset c, double u) {
    final fade = _seg(t, 0.0, 0.5) * (1 - _seg(t, 3.0, 3.5));
    if (fade <= 0) return;
    final w = size.width, h = size.height;
    final grid = Paint()..strokeWidth = 1;
    final cell = 24 * u;
    for (var i = 0; c.dx + i * cell < w + cell; i++) {
      for (final x in {c.dx + i * cell, c.dx - i * cell}) {
        grid.color = Colors.white.withValues(alpha: (i % 4 == 0 ? 0.06 : 0.03) * fade);
        canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
      }
    }
    for (var i = 0; c.dy + i * cell < h + cell; i++) {
      for (final y in {c.dy + i * cell, c.dy - i * cell}) {
        grid.color = Colors.white.withValues(alpha: (i % 4 == 0 ? 0.06 : 0.03) * fade);
        canvas.drawLine(Offset(0, y), Offset(w, y), grid);
      }
    }
    final line = Paint()
      ..color = const Color(0xFF8FB4E8).withValues(alpha: 0.35 * fade)
      ..strokeWidth = 1;
    // The crosshair draws out from the centre.
    final cross = _ease(_seg(t, 0.25, 0.75));
    canvas.drawLine(c - Offset(w / 2 * cross, 0), c + Offset(w / 2 * cross, 0), line);
    canvas.drawLine(c - Offset(0, h / 2 * cross), c + Offset(0, h / 2 * cross), line);

    // The dial: an arc sweeps round with a glowing dot, then ticks and labels.
    final dialR = 135 * u;
    final sweep = _ease(_seg(t, 0.45, 1.1));
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF9CC0F0).withValues(alpha: 0.55 * fade);
    final rect = Rect.fromCircle(center: c, radius: dialR);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * sweep, false, arc);
    canvas.drawArc(Rect.fromCircle(center: c, radius: dialR * 0.72), -math.pi / 2, 2 * math.pi * sweep, false,
        arc..color = const Color(0xFF9CC0F0).withValues(alpha: 0.25 * fade));
    canvas.drawArc(Rect.fromCircle(center: c, radius: dialR * 0.48), -math.pi / 2, 2 * math.pi * sweep, false, arc);
    if (sweep > 0 && sweep < 1) {
      final a = -math.pi / 2 + 2 * math.pi * sweep;
      final dot = c + Offset(math.cos(a), math.sin(a)) * dialR;
      canvas.drawCircle(dot, 7 * u, Paint()..color = const Color(0xFF5AA0FF).withValues(alpha: 0.5 * fade)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(dot, 2.2 * u, Paint()..color = Colors.white.withValues(alpha: fade));
    }
    final ticks = _seg(t, 0.8, 1.2) * fade;
    if (ticks > 0) {
      final tick = Paint()
        ..color = const Color(0xFF9CC0F0).withValues(alpha: 0.5 * ticks)
        ..strokeWidth = 1;
      for (var d = 0; d < 360; d += 5) {
        final a = d * math.pi / 180 - math.pi / 2;
        final dir = Offset(math.cos(a), math.sin(a));
        final r0 = dialR + 10 * u, r1 = dialR + (d % 30 == 0 ? 20 : 15) * u;
        canvas.drawLine(c + dir * r0, c + dir * r1, tick);
      }
    }
    final labels = _seg(t, 0.95, 1.35) * fade;
    if (labels > 0) {
      final col = const Color(0xFF9CC0F0).withValues(alpha: 0.75 * labels);
      for (var d = 0; d < 360; d += 30) {
        final a = d * math.pi / 180 - math.pi / 2;
        _mono(canvas, '$d°', c + Offset(math.cos(a), math.sin(a)) * (dialR + 36 * u), 9 * u, col);
      }
      // The drawing's notes (as the video's).
      final dimY = c.dy - dialR - 70 * u;
      canvas.drawLine(Offset(c.dx - dialR, dimY), Offset(c.dx + dialR, dimY), line);
      for (final s in [-1.0, 1.0]) {
        canvas.drawLine(Offset(c.dx + s * dialR, dimY - 4 * u), Offset(c.dx + s * dialR, dimY + 4 * u), line);
      }
      _mono(canvas, 'Ø 336', Offset(c.dx, dimY - 10 * u), 10 * u, col);
      _mono(canvas, 'R 116', Offset(c.dx - dialR - 40 * u, c.dy + 50 * u), 10 * u, col);
      _mono(canvas, 'Z = 12', Offset(c.dx + 80 * u, c.dy + dialR + 60 * u), 10 * u, col);
      _mono(canvas, 'MODULE 2.5', Offset(c.dx + 80 * u, c.dy + dialR + 75 * u), 10 * u, col.withValues(alpha: 0.55 * labels));
      final pad = 30 * u;
      _mono(canvas, 'SCALE 1:1', Offset(pad + 30 * u, pad), 8 * u, col, left: true);
      _mono(canvas, 'SMARTLINEMAN / SAFETY', Offset(pad, h - pad), 8 * u, col, left: true);
      _mono(canvas, 'SL-01 · REV A', Offset(w - pad - 70 * u, h - pad), 8 * u, col, left: true);
    }
  }

  void _mono(Canvas canvas, String s, Offset at, double size, Color color, {bool left = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'monospace', fontSize: size, color: color, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, left ? at - Offset(0, tp.height / 2) : at - Offset(tp.width / 2, tp.height / 2));
  }

  /// The gear: teeth fly in one by one and lock round the circle; then the
  /// blue body, the ring.
  void _gear(Canvas canvas, Offset at, double k, double u) {
    if (t < 0.95) return;
    final body = _seg(t, 2.1, 2.35);
    final ring = _ease(_seg(t, 1.95, 2.4));
    final bolt = t >= 2.6 ? 1.0 : 0.0;
    if (body > 0) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(k);
      canvas.drawPath(BrandLogo.gearFill, Paint()..color = brandBlue.withValues(alpha: body));
      canvas.restore();
    }
    // The teeth.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = BrandLogo.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = brandYellow;
    for (var i = 0; i < BrandLogo.teeth; i++) {
      // Starting at the upper right, round clockwise.
      final order = (i - 1 + BrandLogo.teeth) % BrandLogo.teeth;
      final start = 1.0 + order * 0.085;
      final f = _seg(t, start, start + 0.42);
      if (f <= 0) continue;
      final e = _ease(f);
      final ang = i * 30 * math.pi / 180;
      final out = Offset(math.sin(ang + 0.7), -math.cos(ang + 0.7)) * (420 * u * (1 - e));
      canvas.save();
      canvas.translate(at.dx + out.dx, at.dy + out.dy);
      canvas.rotate((1 - e) * 1.2);
      canvas.scale(k);
      if (f < 1) {
        canvas.drawPath(
          BrandLogo.pieces[i],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = BrandLogo.stroke * 2.2
            ..color = brandYellow.withValues(alpha: 0.35 * (1 - e))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
      }
      canvas.drawPath(BrandLogo.pieces[i], stroke..color = brandYellow.withValues(alpha: math.min(1, f * 3)));
      canvas.restore();
    }
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(k);
    if (ring > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: BrandLogo.ringR),
        -math.pi / 2,
        2 * math.pi * ring,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = BrandLogo.ringW
          ..color = brandYellow,
      );
    }
    if (bolt > 0) _boltAt(canvas, 0);
    canvas.restore();
  }

  void _boltAt(Canvas canvas, double dy) {
    canvas.save();
    canvas.translate(0, dy);
    canvas.drawPath(
      BrandLogo.boltPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeJoin = StrokeJoin.miter
        ..color = introNavy,
    );
    canvas.drawPath(BrandLogo.boltPath, Paint()..color = brandYellow);
    canvas.restore();
  }

  /// The whole logo still (the handover and reduced motion).
  void _logo(Canvas canvas, Offset at, double k, {required double ring, required double bolt, required double fill}) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(k);
    canvas.drawPath(BrandLogo.gearFill, Paint()..color = brandBlue.withValues(alpha: fill));
    canvas.drawPath(
      BrandLogo.gearStroke,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = BrandLogo.stroke
        ..strokeJoin = StrokeJoin.round
        ..color = brandYellow,
    );
    canvas.drawCircle(
      Offset.zero,
      BrandLogo.ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = BrandLogo.ringW
        ..color = brandYellow,
    );
    _boltAt(canvas, 0);
    canvas.restore();
  }

  /// The bolt comes down; a flash, lightning round the gear, two shock rings.
  void _strike(Canvas canvas, Offset at, double k, double u, Size size) {
    // A small charge at 2.3 s (the soundtrack's first hit).
    final charge = math.sin(math.pi * _seg(t, 2.22, 2.45));
    if (charge > 0) {
      canvas.drawCircle(
        at,
        185 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26 * k
          ..color = brandYellow.withValues(alpha: 0.22 * charge)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
    // The bolt falls in.
    final fall = _seg(t, 2.52, 2.6);
    if (fall > 0 && fall < 1) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(k);
      final dy = -(1 - Curves.easeInQuad.transform(fall)) * (at.dy / k + 200);
      canvas.drawRect(Rect.fromLTRB(-30, dy - 600, 30, dy - 100), Paint()..color = Colors.white.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
      _boltAt(canvas, dy);
      canvas.restore();
    }
    final hit = _seg(t, 2.6, 3.3);
    if (hit <= 0 || hit >= 1) return;
    // Flash.
    final flash = math.pow(1 - _seg(t, 2.6, 2.85), 2) * 0.5;
    if (flash > 0) {
      canvas.drawCircle(
        at,
        260 * k,
        Paint()..shader = ui.Gradient.radial(at, 260 * k, [Colors.white.withValues(alpha: flash.toDouble()), Colors.white.withValues(alpha: 0)]),
      );
    }
    // Shock rings.
    for (final (color, r0, r1, a, b) in [
      (const Color(0xFFBFD8FF), 175.0, 560.0, 2.6, 3.3),
      (brandYellow, 175.0, 440.0, 2.63, 3.25),
    ]) {
      final f = _seg(t, a, b);
      if (f <= 0 || f >= 1) continue;
      final e = _ease(f);
      canvas.drawCircle(
        at,
        (r0 + (r1 - r0) * e) * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * u * (1 - e) + 1
          ..color = color.withValues(alpha: 0.55 * (1 - e))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    // Lightning: branches crackle out from the gear, re-drawn every 50 ms.
    final crackle = 1 - _seg(t, 2.95, 3.2);
    if (crackle <= 0) return;
    final rng = math.Random((t * 20).floor());
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * u
      ..color = const Color(0xFF7FB2FF).withValues(alpha: 0.35 * crackle)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * u
      ..color = const Color(0xFFE6F0FF).withValues(alpha: 0.9 * crackle);
    for (var i = 0; i < 9; i++) {
      final a = rng.nextDouble() * 2 * math.pi;
      var p = at + Offset(math.cos(a), math.sin(a)) * (175 * k);
      final path = Path()..moveTo(p.dx, p.dy);
      final len = (90 + rng.nextDouble() * 160) * u;
      var dir = a;
      for (var s = 0; s < 8; s++) {
        dir += (rng.nextDouble() - 0.5) * 0.9;
        p += Offset(math.cos(dir), math.sin(dir)) * (len / 8);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
  }

  /// A light sweeps across the logo once it is in place.
  void _glint(Canvas canvas, Offset at, double k) {
    final f = _seg(t, 4.55, 5.05);
    if (f <= 0 || f >= 1) return;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(k);
    canvas.clipPath(BrandLogo.gearFill);
    final x = -260 + 520 * Curves.easeInOut.transform(f);
    canvas.drawRect(
      const Rect.fromLTRB(-200, -200, 200, 200),
      Paint()
        ..shader = ui.Gradient.linear(Offset(x - 60, -200), Offset(x + 60, 200), [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0),
        ], [0, 0.5, 1]),
    );
    canvas.restore();
  }

  /// "SmartLineman" and the Bangla line, each revealed by a colour bar.
  void _lockup(Canvas canvas, Size size, Offset logoAt, double u) {
    if (t < 3.55) return;
    final w = size.width;
    final cy = size.height * 0.40;
    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(text: 'Smart', style: title.copyWith(color: _titleWhite)),
        TextSpan(text: 'Lineman', style: title.copyWith(color: brandYellow)),
      ], style: title.copyWith(fontSize: 100)),
      textDirection: TextDirection.ltr,
    )..layout();
    final fs = 100 * math.min(w * 0.76, 352 * u) / tp.width;
    final tt = TextPainter(
      text: TextSpan(children: [
        TextSpan(text: 'Smart', style: title.copyWith(color: _titleWhite, fontSize: fs)),
        TextSpan(text: 'Lineman', style: title.copyWith(color: brandYellow, fontSize: fs)),
      ]),
      textDirection: TextDirection.ltr,
    )..layout();
    final titleBox = Rect.fromCenter(center: Offset(w / 2, cy + 150 * u), width: tt.width, height: tt.height);
    _reveal(canvas, titleBox, brandYellow, 3.6, (c) => tt.paint(c, titleBox.topLeft));

    // The underline: a short cyan lead, then gold.
    final ul = _ease(_seg(t, 4.0, 4.3));
    if (ul > 0) {
      final y = titleBox.bottom + 8 * u;
      final x0 = titleBox.left, x1 = titleBox.left + titleBox.width * ul;
      final split = titleBox.left + titleBox.width * 0.16;
      final p = Paint()..strokeWidth = 1.6 * u;
      canvas.drawLine(Offset(x0, y), Offset(math.min(x1, split), y), p..color = _cyan.withValues(alpha: 0.85));
      if (x1 > split) canvas.drawLine(Offset(split, y), Offset(x1, y), p..color = brandYellow.withValues(alpha: 0.8));
    }

    final sp = TextPainter(
      text: TextSpan(text: subtitleBn, style: subtitle.copyWith(fontSize: 17 * u)),
      textDirection: TextDirection.ltr,
    )..layout();
    final subBox = Rect.fromCenter(center: Offset(w / 2, titleBox.bottom + 32 * u), width: sp.width, height: sp.height);
    _reveal(canvas, subBox, _cyan, 3.95, (c) => sp.paint(c, subBox.topLeft));
  }

  /// A bar grows from the left over [box] (0.2 s), then slides off to the
  /// right uncovering what [draw] paints (0.2 s).
  void _reveal(Canvas canvas, Rect box, Color bar, double start, void Function(Canvas) draw) {
    final grow = _ease(_seg(t, start, start + 0.2));
    final open = _inOut(_seg(t, start + 0.2, start + 0.42));
    if (grow <= 0) return;
    final barH = box.height * 0.62;
    final top = box.center.dy - barH / 2;
    if (open > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(box.left - 4, box.top - 8, box.left + (box.width + 8) * open, box.bottom + 8));
      draw(canvas);
      canvas.restore();
    }
    final left = box.left + box.width * open;
    final right = box.left + box.width * grow;
    if (right > left) canvas.drawRect(Rect.fromLTRB(left, top, right, top + barH), Paint()..color = bar);
  }

  @override
  bool shouldRepaint(BrandIntroPainter old) => old.t != t || old.title != title || old.subtitle != subtitle;
}
