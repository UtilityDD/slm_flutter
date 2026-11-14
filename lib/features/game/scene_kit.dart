import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';

// Scene kit: the pieces a level needs to be a place you stand in rather than
// a page you read — reusable across levels:
//  * AwakeClock — seconds that only run for a while after something happens
//    (idle screens draw nothing);
//  * LinemanFigure — the trainee (the player's worker in the scene) with
//    poses: idle, talk, point, worried, cheer, walk, hold / spray an
//    extinguisher, throw a bucket. Poses blend smoothly;
//  * GuideIntro — the guide (the app's own mascot, AiLinemanGuide) first,
//    full screen over the dimmed scene, says the task in one line, then
//    steps aside so the scene can start.
// The guide is always the existing mascot — no other guide character.
//
// Characters are drawn in a 100 x 200 box, feet at the bottom, facing right.

/// Seconds that advance only while awake: for [awake] after [wake] changes.
class AwakeClock extends StatefulWidget {
  const AwakeClock({super.key, required this.wake, required this.builder, this.quiet = false, this.awake = const Duration(seconds: 5)});

  final int wake;
  final bool quiet;
  final Duration awake;
  final Widget Function(BuildContext context, ValueListenable<double> t) builder;

  @override
  State<AwakeClock> createState() => _AwakeClockState();
}

class _AwakeClockState extends State<AwakeClock> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _t = ValueNotifier<double>(0);
  Duration _last = Duration.zero;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(AwakeClock old) {
    super.didUpdateWidget(old);
    if (old.wake != widget.wake || old.quiet != widget.quiet) _arm();
  }

  void _arm() {
    if (widget.quiet) {
      _ticker.stop();
      return;
    }
    _left = widget.awake;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration e) {
    final dt = e - _last;
    _last = e;
    _t.value += dt.inMicroseconds / 1e6;
    _left -= dt;
    if (_left <= Duration.zero) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _t);
}

// ============================================================================
// Characters
// ============================================================================

enum LinemanMode { idle, talk, point, worried, cheer, walk, hold, spray, throwIt }

/// What is in the hands.
enum Carry { none, dcp, co2, water, sand }

@immutable
class LinemanLook {
  const LinemanLook({
    required this.helmet,
    required this.shirt,
    required this.vest,
    required this.pants,
    this.skin = const Color(0xFFB57A52),
    this.moustache = false,
    this.grey = false,
    this.gloves = false,
  });

  final Color helmet;
  final Color shirt;
  final Color vest;
  final Color pants;
  final Color skin;
  final bool moustache;
  final bool grey;
  final bool gloves;

  /// The trainee (the player): yellow helmet, leather gloves.
  static const trainee = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
    gloves: true,
  );
}

/// Joint angles (radians from straight down; + swings forward, to the right).
@immutable
class _Pose {
  const _Pose({
    this.bu = -0.1,
    this.bf = -0.05,
    this.fu = 0.1,
    this.ff = 0.05,
    this.bt = -0.05,
    this.bs = -0.05,
    this.ft = 0.05,
    this.fs = 0.05,
    this.bob = 0,
    this.tilt = 0,
  });

  final double bu, bf, fu, ff; // back / front arm: upper, fore
  final double bt, bs, ft, fs; // back / front leg: thigh, shin
  final double bob, tilt;

  _Pose lerp(_Pose o, double k) {
    double l(double a, double b) => a + (b - a) * k;
    return _Pose(
      bu: l(bu, o.bu),
      bf: l(bf, o.bf),
      fu: l(fu, o.fu),
      ff: l(ff, o.ff),
      bt: l(bt, o.bt),
      bs: l(bs, o.bs),
      ft: l(ft, o.ft),
      fs: l(fs, o.fs),
      bob: l(bob, o.bob),
      tilt: l(tilt, o.tilt),
    );
  }
}

_Pose _target(LinemanMode m, double t, double modeT, double point) {
  final breathe = math.sin(t * 2.2) * 0.7;
  switch (m) {
    case LinemanMode.idle:
      return _Pose(bob: breathe);
    case LinemanMode.talk:
      return _Pose(fu: 0.45 + 0.08 * math.sin(t * 3), ff: 1.5 + 0.25 * math.sin(t * 3.3), tilt: 0.03 * math.sin(t * 1.5), bob: breathe);
    case LinemanMode.point:
      return _Pose(fu: point, ff: point, tilt: 0.04, bob: breathe);
    case LinemanMode.worried:
      return _Pose(bu: -0.4, bf: -2.6, fu: 0.4, ff: 2.6, tilt: -0.06, bob: breathe);
    case LinemanMode.cheer:
      final hop = -2.5 * math.sin(t * 6).abs() * math.max(0, 1 - modeT / 1.6);
      return _Pose(bu: -0.25, bf: -0.45, fu: 2.6 + 0.1 * math.sin(t * 9), ff: 3.0, bob: hop);
    case LinemanMode.walk:
      final s = math.sin(t * 7.5);
      return _Pose(
        ft: 0.35 * s,
        fs: 0.35 * s - 0.35 * math.max(0, -s),
        bt: -0.35 * s,
        bs: -0.35 * s - 0.35 * math.max(0, s),
        fu: -0.3 * s + 0.1,
        ff: -0.3 * s + 0.3,
        bu: 0.3 * s - 0.1,
        bf: 0.3 * s + 0.1,
        bob: -1.4 * s.abs(),
      );
    case LinemanMode.hold:
      return _Pose(bu: 0.05, bf: 0.05, fu: 0.55, ff: 1.35, bt: -0.12, bs: -0.05, ft: 0.18, fs: 0.1, bob: breathe);
    case LinemanMode.spray:
      final sw = 0.05 * math.sin(t * 5); // the sweep
      return _Pose(bu: 0.15, bf: 0.2, fu: 1.0 + sw, ff: 1.45 + sw, bt: -0.25, bs: -0.1, ft: 0.3, fs: 0.15, tilt: 0.05);
    case LinemanMode.throwIt:
      if (modeT < 0.25) {
        return const _Pose(bu: 0.5, bf: 1.2, fu: 0.5, ff: 1.2, bt: -0.2, ft: 0.2, tilt: -0.05);
      }
      return const _Pose(bu: 1.5, bf: 1.75, fu: 1.5, ff: 1.75, bt: -0.25, bs: -0.1, ft: 0.32, fs: 0.15, tilt: 0.1);
  }
}

Offset _dir(double a) => Offset(math.sin(a), math.cos(a));

/// Joint positions in the 100 x 200 box (upper body before the tilt).
class _Geo {
  _Geo(_Pose p) {
    sY = 58 + p.bob;
    hY = 118 + p.bob;
    bS = Offset(35, sY + 3);
    fS = Offset(65, sY + 3);
    bE = bS + _dir(p.bu) * 25;
    fE = fS + _dir(p.fu) * 25;
    bH = bE + _dir(p.bf) * 23;
    fH = fE + _dir(p.ff) * 23;
    bHip = Offset(44, hY);
    fHip = Offset(56, hY);
    bK = bHip + _dir(p.bt) * 40;
    fK = fHip + _dir(p.ft) * 40;
    bA = bK + _dir(p.bs) * 38;
    fA = fK + _dir(p.fs) * 38;
  }

  late final double sY, hY;
  late final Offset bS, fS, bE, fE, bH, fH, bHip, fHip, bK, fK, bA, fA;

  /// [o] (upper body) after leaning by [tilt] around the hips.
  Offset tilted(Offset o, double tilt) {
    final c = Offset(50, hY);
    final d = o - c;
    final cs = math.cos(tilt), sn = math.sin(tilt);
    return c + Offset(d.dx * cs - d.dy * sn, d.dx * sn + d.dy * cs);
  }
}

/// A rigged field worker. Poses blend; the body moves only for a few
/// seconds after a change (walk and spray keep it moving while they last).
class LinemanFigure extends StatefulWidget {
  const LinemanFigure({
    super.key,
    required this.look,
    required this.mode,
    this.carry = Carry.none,
    this.point = 1.3,
    this.wake = 0,
    this.awakeMs = 3000,
    this.quiet = false,
    this.mood,
  });

  final LinemanLook look;
  final LinemanMode mode;
  final Carry carry;

  /// Arm angle for [LinemanMode.point].
  final double point;

  /// Change it to animate again (a new line, a new move).
  final int wake;
  final int awakeMs;
  final bool quiet;

  /// Face only (brows, mouth); defaults from [mode].
  final LinemanMode? mood;

  /// Where the nozzle (or the bucket's mouth) is, in this widget's pixels,
  /// for a figure of [size] in [mode] (the still pose).
  static Offset tipOf(LinemanMode mode, Carry carry, Size size) {
    final p = _target(mode, 0, 1, 1.3);
    final g = _Geo(p);
    final Offset local;
    if (carry == Carry.water || carry == Carry.sand) {
      local = g.tilted((g.bH + g.fH) / 2 + _dir(p.ff) * 12, p.tilt);
    } else {
      local = g.tilted(g.fH + _dir(p.ff) * (carry == Carry.co2 ? 14 : 11), p.tilt);
    }
    final s = size.height / 200;
    return Offset((size.width - 100 * s) / 2 + local.dx * s, local.dy * s);
  }

  @override
  State<LinemanFigure> createState() => _LinemanFigureState();
}

class _LinemanFigureState extends State<LinemanFigure> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late _Pose _pose = _target(widget.mode, 0, 1, widget.point);
  double _t = 0;
  double _modeT = 1;
  double _left = 0;
  Duration _last = Duration.zero;

  bool get _continuous => widget.mode == LinemanMode.walk || widget.mode == LinemanMode.spray;

  @override
  void initState() {
    super.initState();
    _wakeUp();
  }

  @override
  void didUpdateWidget(LinemanFigure old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) _modeT = 0;
    if (old.mode != widget.mode || old.carry != widget.carry || old.wake != widget.wake || old.point != widget.point || old.quiet != widget.quiet) {
      _wakeUp();
    }
  }

  void _wakeUp() {
    if (widget.quiet) {
      _ticker.stop();
      setState(() => _pose = _target(widget.mode, 0, 1, widget.point));
      return;
    }
    _left = widget.awakeMs / 1000;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration e) {
    final dt = (e - _last).inMicroseconds / 1e6;
    _last = e;
    _t += dt;
    _modeT += dt;
    if (!_continuous) _left -= dt;
    final k = 1 - math.exp(-dt * 11);
    setState(() => _pose = _pose.lerp(_target(widget.mode, _t, _modeT, widget.point), k));
    if (_left <= 0) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final talking = widget.mode == LinemanMode.talk && _ticker.isActive && _left > 0.4;
    return IgnorePointer(
      child: CustomPaint(
        painter: _LinemanPainter(
          look: widget.look,
          pose: _pose,
          mood: widget.mood ?? widget.mode,
          carry: widget.carry,
          throwOut: widget.mode == LinemanMode.throwIt && _modeT >= 0.25,
          blink: (_t % 3.4) < 0.12,
          mouth: talking ? 0.5 + 0.5 * math.sin(_t * 13) : 0,
        ),
      ),
    );
  }
}

class _LinemanPainter extends CustomPainter {
  _LinemanPainter({
    required this.look,
    required this.pose,
    required this.mood,
    required this.carry,
    required this.throwOut,
    required this.blink,
    required this.mouth,
  });

  final LinemanLook look;
  final _Pose pose;
  final LinemanMode mood;
  final Carry carry;
  final bool throwOut;
  final bool blink;
  final double mouth;

  static Color _shade(Color c, double k) => Color.lerp(c, const Color(0xFF000000), k)!;

  void _limb(Canvas c, Offset a, Offset b, double w, Color col) {
    c.drawLine(a, b, Paint()
      ..color = col
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);
  }

  void _leg(Canvas c, Offset hip, Offset knee, Offset ankle, Color col) {
    _limb(c, hip, knee, 11, col);
    _limb(c, knee, ankle, 9.5, col);
    final boot = RRect.fromRectAndCorners(
      Rect.fromLTWH(ankle.dx - 6, ankle.dy - 4, 16, 8),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(5),
      bottomLeft: const Radius.circular(1),
      bottomRight: const Radius.circular(3),
    );
    c.drawRRect(boot, Paint()..color = const Color(0xFF1C1F24));
  }

  void _arm(Canvas c, Offset s, Offset e, Offset h, Color sleeve) {
    _limb(c, s, e, 9, sleeve);
    _limb(c, e, h, 8, sleeve);
    c.drawCircle(h, 4.6, Paint()..color = look.gloves ? const Color(0xFF6B4A33) : look.skin);
  }

  void _cylinder(Canvas c, Offset hand) {
    final r = Rect.fromLTWH(hand.dx - 7.5, hand.dy + 1, 15, 38);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8E1F16), Color(0xFFE5483A), Color(0xFF9E2419)], stops: [0, 0.45, 1]).createShader(r),
    );
    c.drawRect(Rect.fromLTWH(r.left, r.top + 14, r.width, 7), Paint()..color = carry == Carry.co2 ? const Color(0xFF2B2F35) : const Color(0xFF2F6FD0));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hand.dx - 4, hand.dy - 5, 8, 7), const Radius.circular(2)), Paint()..color = const Color(0xFF4A4F55));
  }

  void _bucket(Canvas c, Offset at, double angle) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    final b = Path()
      ..moveTo(-11, -9)
      ..lineTo(11, -9)
      ..lineTo(7.5, 10)
      ..lineTo(-7.5, 10)
      ..close();
    c.drawPath(b, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E1F16), Color(0xFFE5483A), Color(0xFF9E2419)]).createShader(const Rect.fromLTWH(-11, -9, 22, 19)));
    if (!throwOut) {
      c.drawOval(const Rect.fromLTWH(-11, -11.5, 22, 5), Paint()..color = carry == Carry.water ? const Color(0xFF5AA0D8) : const Color(0xFFD8B26A));
    }
    c.drawArc(const Rect.fromLTWH(-12, -18, 24, 18), math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF2B2F35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    final s = size.height / 200;
    c.translate((size.width - 100 * s) / 2, 0);
    c.scale(s);
    final p = pose;
    final g = _Geo(p);
    final extinguisher = carry == Carry.dcp || carry == Carry.co2;
    final bucket = carry == Carry.water || carry == Carry.sand;

    c.drawOval(Rect.fromCenter(center: const Offset(52, 197), width: 60, height: 7), Paint()..color = const Color(0x40000000));
    _leg(c, g.bHip, g.bK, g.bA, _shade(look.pants, 0.25));
    _leg(c, g.fHip, g.fK, g.fA, look.pants);

    c.save();
    c.translate(50, g.hY);
    c.rotate(p.tilt);
    c.translate(-50, -g.hY);

    _arm(c, g.bS, g.bE, g.bH, _shade(look.shirt, 0.3));
    if (extinguisher) _cylinder(c, g.bH);

    // Torso: shirt, hi-vis vest with reflective bands, belt.
    final sY = g.sY, hY = g.hY;
    final torso = Path()
      ..moveTo(31, sY + 4)
      ..quadraticBezierTo(50, sY - 2, 69, sY + 4)
      ..lineTo(65, hY)
      ..lineTo(35, hY)
      ..close();
    c.drawPath(torso, Paint()..shader = LinearGradient(colors: [_shade(look.shirt, 0.2), look.shirt, _shade(look.shirt, 0.3)]).createShader(Rect.fromLTWH(31, sY, 38, hY - sY)));
    final vestL = Path()
      ..moveTo(33, sY + 5)
      ..lineTo(45, sY + 2)
      ..lineTo(49, sY + 24)
      ..lineTo(49, hY - 3)
      ..lineTo(36, hY - 3)
      ..close();
    final vestR = Path()
      ..moveTo(67, sY + 5)
      ..lineTo(55, sY + 2)
      ..lineTo(51, sY + 24)
      ..lineTo(51, hY - 3)
      ..lineTo(64, hY - 3)
      ..close();
    final vp = Paint()..color = look.vest;
    c.drawPath(vestL, vp);
    c.drawPath(vestR, Paint()..color = _shade(look.vest, 0.12));
    final band = Paint()..color = const Color(0xFFE3E8EC);
    for (final y in [sY + 32, sY + 46]) {
      c.drawRect(Rect.fromLTWH(34.5, y, 14.5, 3.2), band);
      c.drawRect(Rect.fromLTWH(51, y, 13.5, 3.2), band);
    }
    c.drawRect(Rect.fromLTWH(35, hY - 5, 30, 6), Paint()..color = const Color(0xFF5A3B22));
    c.drawRect(Rect.fromLTWH(47.5, hY - 4.5, 5, 5), Paint()..color = const Color(0xFFB9A26A));

    // Neck and head.
    c.drawRect(Rect.fromLTWH(46, sY - 9, 9, 12), Paint()..color = _shade(look.skin, 0.12));
    final face = Rect.fromCenter(center: Offset(51, sY - 20), width: 22, height: 26);
    c.drawOval(Rect.fromCenter(center: Offset(40.5, sY - 19), width: 5, height: 7), Paint()..color = _shade(look.skin, 0.08));
    c.drawOval(face, Paint()..color = look.skin);
    if (look.grey) {
      final hair = Paint()..color = const Color(0xFFB8BCC2);
      c.drawRect(Rect.fromLTWH(40.5, sY - 29, 3, 8), hair);
      c.drawRect(Rect.fromLTWH(59.5, sY - 29, 2.5, 7), hair);
    }
    // Eyes and brows.
    final worried = mood == LinemanMode.worried;
    final cheer = mood == LinemanMode.cheer;
    final eyeY = sY - 21;
    final ink = Paint()
      ..color = const Color(0xFF231A14)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final ex in [47.0, 56.0]) {
      if (blink) {
        c.drawLine(Offset(ex - 2, eyeY), Offset(ex + 2, eyeY), ink);
      } else {
        c.drawOval(Rect.fromCenter(center: Offset(ex, eyeY), width: 4.6, height: worried ? 4.2 : 3.4), Paint()..color = const Color(0xFFF7F3EE));
        c.drawCircle(Offset(ex + 0.7, eyeY + 0.2), 1.35, Paint()..color = const Color(0xFF231A14));
      }
      final inner = ex < 50 ? ex + 2.4 : ex - 2.4;
      final outer = ex < 50 ? ex - 2.6 : ex + 2.6;
      final lift = cheer ? -1.4 : 0.0;
      final browCol = Paint()
        ..color = look.grey ? const Color(0xFF7D8288) : const Color(0xFF2A1E16)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(outer, eyeY - 4 + lift), Offset(inner, eyeY - (worried ? 6 : 4.4) + lift), browCol);
    }
    // Nose, moustache, mouth.
    c.drawLine(Offset(52.5, sY - 19), Offset(53.5, sY - 15.5), Paint()
      ..color = _shade(look.skin, 0.3)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round);
    if (look.moustache) {
      final m = Path()
        ..moveTo(46.5, sY - 12.5)
        ..quadraticBezierTo(52, sY - 15.5, 57.5, sY - 12.5)
        ..quadraticBezierTo(52, sY - 13.4, 46.5, sY - 12.5);
      c.drawPath(m, Paint()..color = const Color(0xFF8E9298));
    }
    final my = sY - 10.5;
    if (mouth > 0.05) {
      c.drawOval(Rect.fromCenter(center: Offset(52, my), width: 5.5, height: 1 + 3.2 * mouth), Paint()..color = const Color(0xFF5A2620));
    } else if (cheer) {
      c.drawPath(
        Path()
          ..moveTo(48.5, my - 1)
          ..quadraticBezierTo(52, my + 4.5, 55.5, my - 1)
          ..close(),
        Paint()..color = const Color(0xFF5A2620),
      );
    } else if (worried) {
      c.drawOval(Rect.fromCenter(center: Offset(52, my), width: 3.2, height: 2.6), Paint()..color = const Color(0xFF5A2620));
    } else {
      c.drawArc(Rect.fromCenter(center: Offset(52, my - 1.5), width: 7, height: 3.5), 0.3, math.pi - 0.6, false, Paint()
        ..color = const Color(0xFF5A2620)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round);
    }
    // Helmet: dome, ridge, brim, shine.
    final dome = Rect.fromLTWH(38, sY - 47, 28, 34);
    c.drawArc(dome, math.pi, math.pi, true, Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.6), radius: 1.1, colors: [Color.lerp(look.helmet, Colors.white, 0.4)!, look.helmet, _shade(look.helmet, 0.25)]).createShader(dome));
    c.drawLine(Offset(52, sY - 46.5), Offset(52, sY - 31), Paint()
      ..color = _shade(look.helmet, 0.18)
      ..strokeWidth = 2.2);
    c.drawOval(Rect.fromCenter(center: Offset(53.5, sY - 30), width: 36, height: 6), Paint()..color = _shade(look.helmet, 0.12));

    // Front arm and what it holds.
    if (extinguisher) {
      final hose = Path()
        ..moveTo(g.bH.dx + 2, g.bH.dy - 3)
        ..cubicTo(g.bH.dx + 10, g.bH.dy + 26, g.fH.dx - 12, g.fH.dy + 22, g.fH.dx, g.fH.dy);
      c.drawPath(hose, Paint()
        ..color = const Color(0xFF1E2126)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round);
    }
    _arm(c, g.fS, g.fE, g.fH, look.shirt);
    if (extinguisher) {
      final d = _dir(p.ff);
      final n = Paint()..color = const Color(0xFF1E2126);
      if (carry == Carry.co2) {
        final tip = g.fH + d * 14;
        final side = Offset(d.dy, -d.dx) * 4.5;
        c.drawPath(
          Path()
            ..moveTo(g.fH.dx, g.fH.dy)
            ..lineTo(tip.dx + side.dx, tip.dy + side.dy)
            ..lineTo(tip.dx - side.dx, tip.dy - side.dy)
            ..close(),
          n,
        );
      } else {
        _limb(c, g.fH, g.fH + d * 11, 3.4, const Color(0xFF1E2126));
      }
    }
    if (bucket) {
      _bucket(c, (g.bH + g.fH) / 2 + const Offset(0, 6), throwOut ? 1.3 : 0.15);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_LinemanPainter old) =>
      old.pose != pose || old.mood != mood || old.carry != carry || old.blink != blink || old.mouth != mouth || old.throwOut != throwOut || old.look != look;
}

// ============================================================================
// The guide first, full screen
// ============================================================================

/// The guide (the app's mascot) fills the screen in front of the dimmed
/// scene and says the task in one line, with the alarm; when the voice and a
/// fair reading time are done he steps aside and [onDone] runs. No start
/// button and no skipping — as level 1.
class GuideIntro extends ConsumerStatefulWidget {
  const GuideIntro({super.key, required this.line, required this.muted, required this.onDone, this.alarm = 'sounds/learn/fire_alarm.ogg'});

  final String line;
  final bool muted;
  final VoidCallback onDone;
  final String? alarm;

  @override
  ConsumerState<GuideIntro> createState() => _GuideIntroState();
}

class _GuideIntroState extends ConsumerState<GuideIntro> {
  var _done = false;
  var _leaving = false;
  final _skip = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  void dispose() {
    _done = true;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _run() async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final alarm = widget.alarm;
    if (alarm != null && !widget.muted) unawaited(ZlFx.cue(alarm, volume: 0.55, muted: false));
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.warn, line: widget.line);
    final read = Duration(milliseconds: (widget.line.length * 90).clamp(2600, 9000));
    await Future.any([
      Future.wait([MascotSpeechLibrary.speak(widget.line, muted: widget.muted), Future<void>.delayed(read)]),
      _skip.future,
    ]);
    if (!mounted || _done) return;
    await _leave();
  }

  void _tap() => HapticFeedback.selectionClick();

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final quiet = MediaQuery.disableAnimationsOf(context);
    setState(() {});
    if (!quiet) await Future<void>.delayed(const Duration(milliseconds: 380));
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context);
    final size = MediaQuery.sizeOf(context);
    final sprite = math.min(220.0, size.width * 0.56);
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: quiet ? Duration.zero : const Duration(milliseconds: 360),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99070D1A), Color(0xE6070D1A), Color(0xF2070D1A)],
                stops: [0, 0.45, 1],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // The guide, big, with the line in his own bubble.
                  Align(
                    alignment: const Alignment(0, 0.55),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      builder: (_, t, child) => Transform.translate(offset: Offset(0, 50 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                      child: AiLinemanGuide(sprite: sprite, bubbleWidth: math.min(330.0, size.width - 36), showBubble: true, large: true, centered: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
