import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import 'pole_yard.dart';

// The roadside work site of lesson 1.6 কাজ 1 ("কাগজ মেলাও"), drawn in code:
// the village roadside of the pole levels (PoleYardPainter: sky, clouds, far
// village, verge, road) with the job in front — the 11 kV pole with its
// feeder tag and number plate, the conductors on the cross-arm, the crew's
// van with the ladder on its rack, traffic cones and a phone on the van's
// bonnet. Labels only where a worker reads them (the tag, the plate, the
// phone's clock). The site slides in from the right when the crew drives to
// the next job ([PtwSitePainter.dx]).
//
// Also here: the pieces the lens shows big (the tag, the plate, the phone,
// the worker's ID card) and the deadly consequence (the line is live: an arc
// at the cross-arm, drawn in colour over the frozen grey site).

/// Where things stand at the site (design px, 360 wide).
@immutable
class PtwGeo {
  const PtwGeo(this.pole);

  factory PtwGeo.forScene(double h, double inset) => PtwGeo(PoleGeo.forScene(h, inset));

  /// The ground row and the scale (shared with the pole levels).
  final PoleGeo pole;

  /// The pole's axis (left: the permit is held up on its right).
  static const poleX = 60.0;

  double get groundY => pole.groundY;
  double get topY => pole.topY + 40;
  double get armY => topY + 20;
  double get ppm => pole.ppm;

  /// The feeder tag and the number plate, at eye height on the pole.
  Rect get tagRect => Rect.fromCenter(center: Offset(poleX, pole.y(3.2)), width: 70, height: 34);
  Rect get plateRect => Rect.fromLTWH(poleX - 21, tagRect.bottom + 6, 42, 30);

  /// The van on the road, facing left.
  Rect get vanRect => Rect.fromLTWH(150, groundY - 30, 160, 76);

  /// The phone, standing on the van's bonnet (the tap zone round it is bigger).
  Rect get phoneRect => Rect.fromLTWH(vanRect.left + 7, vanRect.top + 20, 15, 25);

  /// The trainee beside the pole; the crewmate in front of the van.
  Rect get traineeRect {
    final h = 1.8 * ppm;
    return Rect.fromLTWH(poleX + 8, groundY + 8 - h, h / 2, h);
  }

  Rect get crewRect {
    final h = 1.9 * ppm;
    return Rect.fromLTWH(222, groundY + 46 - h, h / 2, h);
  }

  @override
  bool operator ==(Object other) => other is PtwGeo && other.pole == pole;

  @override
  int get hashCode => pole.hashCode;
}

/// The pole with its conductors (shifted by [dx]; the last job's pole at
/// [prevDx] while driving on), and the crew's van and cones, which come along.
class PtwSitePainter extends CustomPainter {
  const PtwSitePainter({required this.geo, this.dx = 0, this.prevDx});
  final PtwGeo geo;
  final double dx;
  final double? prevDx;

  @override
  void paint(Canvas c, Size s) {
    for (final x in [?prevDx, dx]) {
      c.save();
      c.translate(x, 0);
      _wires(c, s, x);
      _pole(c);
      c.restore();
    }
    _van(c);
    for (final x in const [24.0, 128.0]) {
      _cone(c, Offset(x, geo.groundY + 30));
    }
  }

  void _wires(Canvas c, Size s, double dx) {
    final x = PtwGeo.poleX;
    final w = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final (ix, lift) in const [(-36.0, 0.0), (0.0, 16.0), (36.0, 0.0)]) {
      final y = geo.armY - 12 - lift;
      final p = Path()
        ..moveTo(-dx - 40, y + 14)
        ..quadraticBezierTo((x + ix - 40 - dx) / 2, y + 22, x + ix, y)
        ..quadraticBezierTo(x + ix + 160, y + 26, s.width - dx + 60, y + 10);
      c.drawPath(p, w);
    }
  }

  void _pole(Canvas c) {
    final x = PtwGeo.poleX;
    final g = geo.groundY;
    final top = geo.topY;
    // The concrete pole, tapered, lit from the left.
    final body = Path()
      ..moveTo(x - 8, g + 4)
      ..lineTo(x - 4.5, top)
      ..lineTo(x + 4.5, top)
      ..lineTo(x + 8, g + 4)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFD9D6CE), Color(0xFFB4B0A6), Color(0xFF8E8A82)], stops: [0, 0.55, 1])
            .createShader(Rect.fromLTRB(x - 8, top, x + 8, g)),
    );
    // Its shadow and the soil round the foot.
    c.drawOval(Rect.fromCenter(center: Offset(x + 6, g + 5), width: 34, height: 7), Paint()..color = const Color(0x55392A18));
    // The cross-arm (steel channel) and its brace.
    final arm = Rect.fromLTRB(x - 44, geo.armY - 3, x + 44, geo.armY + 3);
    c.drawRRect(RRect.fromRectAndRadius(arm, const Radius.circular(1.5)), Paint()..color = const Color(0xFF5F676F));
    final brace = Paint()
      ..color = const Color(0xFF5F676F)
      ..strokeWidth = 2;
    c.drawLine(Offset(x - 26, geo.armY + 2), Offset(x, geo.armY + 22), brace);
    c.drawLine(Offset(x + 26, geo.armY + 2), Offset(x, geo.armY + 22), brace);
    // Brown-glazed pin insulators (and the top one on the pole cap).
    for (final (ix, base) in [(-36.0, geo.armY - 3), (36.0, geo.armY - 3), (0.0, top)]) {
      _insulator(c, Offset(x + ix, base));
    }
    // The steel bands that hold the tag and the plate.
    final band = Paint()..color = const Color(0xFF6E757C);
    for (final r in [geo.tagRect, geo.plateRect]) {
      c.drawRect(Rect.fromLTRB(x - 7.5, r.center.dy - 1.5, x + 7.5, r.center.dy + 1.5), band);
    }
  }

  static void _insulator(Canvas c, Offset base) {
    final p = Paint()..color = const Color(0xFF7A3E1E);
    c.drawRect(Rect.fromCenter(center: base.translate(0, -3), width: 2.4, height: 6), Paint()..color = const Color(0xFF8A8F94));
    for (var i = 0; i < 2; i++) {
      c.drawOval(Rect.fromCenter(center: base.translate(0, -7 - i * 4.5), width: 10 - i * 2.5, height: 4), p);
    }
    c.drawCircle(base.translate(0, -15), 2, p);
  }

  void _van(Canvas c) {
    final r = geo.vanRect;
    final l = r.left, t = r.top, h = r.height;
    final bodyTop = t + 6;
    final wheelY = r.bottom - 9;
    // Shadow.
    c.drawOval(Rect.fromLTRB(l + 4, r.bottom - 6, r.right + 2, r.bottom + 4), Paint()..color = const Color(0x55000000));
    // The box body (white), the cab in front (left) with the bonnet.
    final box = RRect.fromLTRBR(l + 36, bodyTop, r.right, wheelY + 2, const Radius.circular(5));
    c.drawRRect(box, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7F6F1), Color(0xFFD8D6CE)]).createShader(box.outerRect));
    final cab = Path()
      ..moveTo(l + 40, bodyTop + 4)
      ..lineTo(l + 22, bodyTop + 6)
      ..lineTo(l + 12, t + h * 0.45)
      ..lineTo(l + 2, t + h * 0.5)
      ..lineTo(l, wheelY + 2)
      ..lineTo(l + 40, wheelY + 2)
      ..close();
    c.drawPath(cab, Paint()..color = const Color(0xFFF2F0E8));
    // Windscreen and side window.
    c.drawPath(
      Path()
        ..moveTo(l + 23, bodyTop + 10)
        ..lineTo(l + 14, t + h * 0.44)
        ..lineTo(l + 34, t + h * 0.44)
        ..lineTo(l + 36, bodyTop + 10)
        ..close(),
      Paint()..color = const Color(0xFF6E92AE),
    );
    // The orange safety stripe and a reflector.
    c.drawRect(Rect.fromLTRB(l + 1, t + h * 0.62, r.right, t + h * 0.62 + 5), Paint()..color = const Color(0xFFF08A1C));
    c.drawRect(Rect.fromLTRB(r.right - 6, t + h * 0.4, r.right - 1, t + h * 0.5), Paint()..color = const Color(0xFFD23A2A));
    // The rear door line and handle.
    final line = Paint()
      ..color = const Color(0x55333A40)
      ..strokeWidth = 1;
    c.drawLine(Offset(l + 104, bodyTop + 4), Offset(l + 104, wheelY - 2), line);
    c.drawRect(Rect.fromLTWH(l + 108, t + h * 0.5, 8, 2.5), Paint()..color = const Color(0xFF6E757C));
    // The ladder on the roof rack.
    final rack = Paint()
      ..color = const Color(0xFFB8BDC2)
      ..strokeWidth = 2;
    c.drawLine(Offset(l + 30, bodyTop - 3), Offset(r.right - 4, bodyTop - 3), rack);
    c.drawLine(Offset(l + 30, bodyTop - 8), Offset(r.right - 4, bodyTop - 8), rack);
    for (var x = l + 36; x < r.right - 4; x += 10) {
      c.drawLine(Offset(x, bodyTop - 8), Offset(x, bodyTop - 3), rack..strokeWidth = 1.4);
    }
    // Wheels.
    for (final wx in [l + 24, r.right - 30]) {
      c.drawCircle(Offset(wx, wheelY), 9, Paint()..color = const Color(0xFF23262B));
      c.drawCircle(Offset(wx, wheelY), 4, Paint()..color = const Color(0xFF9AA0A6));
    }
    // An amber beacon on the cab.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + 24, bodyTop, 9, 5), const Radius.circular(2)), Paint()..color = const Color(0xFFF2A51A));
  }

  static void _cone(Canvas c, Offset foot) {
    c.drawRect(Rect.fromCenter(center: foot, width: 18, height: 3.5), Paint()..color = const Color(0xFF2B2F35));
    final body = Path()
      ..moveTo(foot.dx - 7, foot.dy - 1)
      ..lineTo(foot.dx - 1.8, foot.dy - 24)
      ..lineTo(foot.dx + 1.8, foot.dy - 24)
      ..lineTo(foot.dx + 7, foot.dy - 1)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFFF26A1B));
    c.drawRect(Rect.fromLTRB(foot.dx - 4.6, foot.dy - 14, foot.dx + 4.6, foot.dy - 10), Paint()..color = const Color(0xFFF4F4F0));
  }

  @override
  bool shouldRepaint(PtwSitePainter old) => old.geo != geo || old.dx != dx || old.prevDx != prevDx;
}

/// The feeder tag on the pole: the feeder's name, as written on it.
class PtwTag extends StatelessWidget {
  const PtwTag({super.key, required this.feederBn, this.big = false});
  final String feederBn;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final k = big ? 2.6 : 1.0;
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 3 * k, vertical: 1.5 * k),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(3 * k),
        border: Border.all(color: const Color(0xFFC0392B), width: 1.6 * k),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      // The name on one line, the voltage under it ("নদীপাড়" / "11 কেভি").
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          enDigits(feederBn).replaceFirst(RegExp(r' (?=\d)'), '\n'),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: bangla(fontSize: 8.2 * k, fontWeight: FontWeight.w900, color: const Color(0xFF1F2430), height: 1.15),
        ),
      ),
    );
  }
}

/// The pole's number plate.
class PtwPlate extends StatelessWidget {
  const PtwPlate({super.key, required this.pole, this.big = false});
  final int pole;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final k = big ? 2.6 : 1.0;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF6C836),
        borderRadius: BorderRadius.circular(3 * k),
        border: Border.all(color: const Color(0xFF2B2F35), width: 1.2 * k),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('পোল', style: bangla(fontSize: 6.2 * k, fontWeight: FontWeight.w800, color: const Color(0xFF2B2F35), height: 1.0)),
          Text(enDigits('$pole'), style: bangla(fontSize: 12 * k, fontWeight: FontWeight.w900, color: const Color(0xFF1F2430), height: 1.05)),
        ],
      ),
    );
  }
}

/// A phone with its clock on the lock screen.
class PtwPhone extends StatelessWidget {
  const PtwPhone({super.key, required this.timeBn, required this.dateBn, this.big = false, this.calling = false});
  final String timeBn;
  final String dateBn;
  final bool big;

  /// The screen shows an incoming call instead of the clock.
  final bool calling;

  @override
  Widget build(BuildContext context) {
    final k = big ? 7.0 : 1.0;
    return Container(
      padding: EdgeInsets.all(1.2 * k),
      decoration: BoxDecoration(color: const Color(0xFF1B1E23), borderRadius: BorderRadius.circular(2.6 * k)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: calling ? const [Color(0xFF1E7A4A), Color(0xFF0F3F28)] : const [Color(0xFF3D6A9A), Color(0xFF1E3550)],
          ),
          borderRadius: BorderRadius.circular(1.8 * k),
        ),
        alignment: Alignment.center,
        child: big
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(enDigits(timeBn), style: bangla(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                  Text(enDigits(dateBn), style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFFDDE7F2), height: 1.2)),
                ],
              )
            : (calling ? Icon(Icons.call_rounded, size: 9 * k, color: Colors.white) : const SizedBox.expand()),
      ),
    );
  }
}

/// The worker's ID card: his own name and, under it, his team.
class PtwIdCard extends StatelessWidget {
  const PtwIdCard({super.key, required this.titleBn, required this.nameLabelBn, required this.nameBn, this.teamLabelBn, this.teamBn});
  final String titleBn;
  final String nameLabelBn;
  final String nameBn;
  final String? teamLabelBn;
  final String? teamBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F5F8F), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFF1F5F8F), borderRadius: BorderRadius.circular(4)),
            child: Text(titleBn, textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 30,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFCFD8E3), borderRadius: BorderRadius.circular(3)),
                child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFF6B7A8C)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nameLabelBn, style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.1)),
                    Text(nameBn, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1F2430), height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
          if (teamBn != null) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(6, 3, 6, 4),
              decoration: BoxDecoration(color: const Color(0xFFE3ECF6), borderRadius: BorderRadius.circular(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (teamLabelBn != null)
                    Text(teamLabelBn!, style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.1)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(teamBn!, maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF1F2430), height: 1.2)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The phone on the bonnet. When [ringing] it buzzes and glows for a few
/// seconds (then holds a still "ringing" frame: an idle screen draws nothing).
class PtwScenePhone extends StatefulWidget {
  const PtwScenePhone({super.key, required this.ringing, required this.calling, required this.quiet, required this.wake, required this.onTap});
  final bool ringing;
  final bool calling;
  final bool quiet;
  final int wake;
  final VoidCallback? onTap;

  @override
  State<PtwScenePhone> createState() => _PtwScenePhoneState();
}

class _PtwScenePhoneState extends State<PtwScenePhone> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    _buzz();
  }

  @override
  void didUpdateWidget(PtwScenePhone old) {
    super.didUpdateWidget(old);
    if (widget.ringing != old.ringing || widget.wake != old.wake) _buzz();
  }

  void _buzz() {
    if (widget.ringing && !widget.quiet) {
      unawaited(_c.forward(from: 0));
    } else {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final live = widget.ringing && _c.isAnimating;
          final wob = live ? math.sin(_c.value * math.pi * 60) * 0.18 * (1 - _c.value * 0.5) : 0.0;
          return CustomPaint(
            painter: _RingPainter(on: widget.ringing, t: live ? (_c.value * 4) % 1 : 0.55),
            child: Center(child: Transform.rotate(angle: wob, child: child)),
          );
        },
        child: SizedBox(width: 15, height: 25, child: PtwPhone(timeBn: '', dateBn: '', calling: widget.ringing || widget.calling)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.on, required this.t});
  final bool on;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    if (!on) return;
    final centre = s.center(Offset.zero);
    for (var i = 0; i < 2; i++) {
      final k = (t + i * 0.5) % 1;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF3DDC84).withValues(alpha: (1 - k) * 0.9);
      c.drawArc(Rect.fromCircle(center: centre, radius: 12 + 12 * k), -0.9, 1.8, false, p);
      c.drawArc(Rect.fromCircle(center: centre, radius: 12 + 12 * k), math.pi - 0.9, 1.8, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.on != on || old.t != t;
}

/// The deadly consequence, in colour over the frozen grey site: the line was
/// live — an arc flashes from the conductor to the cross-arm and down the pole.
/// Plays once (about two seconds), then holds still. Never graphic.
class PtwLiveFlash extends StatelessWidget {
  const PtwLiveFlash({super.key, required this.geo, required this.quiet});
  final PtwGeo geo;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: quiet ? 1 : 2200),
      builder: (_, t, _) => CustomPaint(painter: _FlashPainter(geo: geo, t: t), size: Size.infinite),
    );
  }
}

class _FlashPainter extends CustomPainter {
  const _FlashPainter({required this.geo, required this.t});
  final PtwGeo geo;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final x = PtwGeo.poleX;
    final hot = Offset(x + 36, geo.armY - 12);
    // A flicker that settles into a steady glow.
    final flick = t >= 1 ? 0.75 : (0.55 + 0.45 * math.sin(t * math.pi * 26).abs());
    c.drawCircle(hot, 70, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 244, 196, 0.85 * flick), const Color(0x00FFC83D)]).createShader(Rect.fromCircle(center: hot, radius: 70)));
    final rnd = math.Random(7 + (t * 12).floor());
    Path bolt(Offset a, Offset b, int n) {
      final p = Path()..moveTo(a.dx, a.dy);
      for (var i = 1; i < n; i++) {
        final k = i / n;
        final m = Offset.lerp(a, b, k)!;
        p.lineTo(m.dx + (rnd.nextDouble() - 0.5) * 9, m.dy + (rnd.nextDouble() - 0.5) * 5);
      }
      p.lineTo(b.dx, b.dy);
      return p;
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Color.fromRGBO(120, 190, 255, 0.45 * flick)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFF4FBFF);
    final arm = Offset(x + 6, geo.armY);
    final foot = Offset(x, geo.groundY);
    for (final p in [bolt(hot, arm, 6), bolt(arm, Offset(x, geo.tagRect.top), 9), bolt(Offset(x, geo.plateRect.bottom), foot, 7)]) {
      c.drawPath(p, glow);
      c.drawPath(p, core);
    }
    // Sparks out of the arc, and the ground glow at the foot.
    final spark = Paint()
      ..color = const Color(0xFFFFD34E)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d = 8 + rnd.nextDouble() * 26 * (0.4 + 0.6 * t);
      final from = hot + Offset(math.cos(a), math.sin(a)) * d;
      c.drawLine(from, from + Offset(math.cos(a), math.sin(a)) * 5, spark);
    }
    c.drawOval(Rect.fromCenter(center: foot, width: 70, height: 16), Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 210, 90, 0.7 * flick), const Color(0x00FFC83D)]).createShader(Rect.fromCenter(center: foot, width: 70, height: 16)));
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.t != t || old.geo != geo;
}
