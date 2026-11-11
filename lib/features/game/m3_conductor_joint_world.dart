import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart' show bangla;
import 'm3_conductor_joint.dart';

// The joint site (lesson 3.1, কাজ 2): an 11 kV span under shutdown, earthed
// at the near pole (earth leads from all three phases down to the spike);
// one phase has broken and both its ends are lowered onto a blue tarpaulin.
// On the tarp: the docket with the conductor's code name, the magnet and the
// wire brush, the sleeve kit, the hydraulic compressor and its pump. On the
// tray round, four finished joints laid out to judge. All drawn in code
// (design px, 360 wide).

/// Where things are (design px).
@immutable
class M3ConductorJointGeo {
  const M3ConductorJointGeo._(this.h);
  factory M3ConductorJointGeo.forScene(double h) => M3ConductorJointGeo._(h);
  final double h;

  double get horizonY => h * 0.25;
  double get groundY => h * 0.38;
  double get tarpTop => h * 0.41;
  double get tarpBottom => h * 0.75;
  double get cableY => h * 0.53;

  /// The joint's centre and the sleeve's half length.
  static const jointX = 182.0;
  static const half = 64.0;

  /// The conductor tips: outside the sleeve's mouths at 0, meeting at the
  /// centre stop at 1.
  static double tipL(double inserted) => jointX - half - 18 + (half + 16) * inserted;
  static double tipR(double inserted) => jointX + half + 18 - (half + 16) * inserted;

  static double condR(M3ConductorJointCode c) => switch (c) {
        M3ConductorJointCode.rabbit => 6.0,
        M3ConductorJointCode.dog => 7.5,
        M3ConductorJointCode.panther => 9.0,
      };
  static double sleeveR(M3ConductorJointCode c) => condR(c) + 4;

  /// The sleeve kit (three sleeves in a box at the top of the tarp, clear
  /// of the guide's corner).
  Rect get kit => Rect.fromLTRB(80, h * 0.422, 352, h * 0.505);
  Offset kitAt(int i) => Offset(kit.left + 47 + 89.0 * i, kit.center.dy);
  static const kitSize = Size(84, 52);

  /// The docket, the magnet and the brush at rest.
  Rect get docket => Rect.fromLTWH(14, h * 0.6, 78, 40);
  Offset get magnetRest => Offset(124, h * 0.612);
  Offset get brushRest => Offset(178, h * 0.605);

  /// The magnet on the left conductor (the test), and where it drops.
  Offset magnetOn(M3ConductorJointCode c) => Offset(tipL(0) - 34, cableY - condR(c) - 3);
  Offset magnetDrop(M3ConductorJointCode c) => Offset(tipL(0) - 30, cableY + condR(c) + 16);

  /// The pump at rest (bottom right of the tarp).
  Offset get pump => Offset(270, h * 0.62);

  /// The tray round: four joints, two rows.
  Offset trayAt(int i) => Offset(i.isEven ? 96 : 266, h * (i < 2 ? 0.52 : 0.63));
  static const traySize = Size(164, 62);

  /// The near pole and its cross-arm.
  static const poleX = 322.0;
  double get poleTop => h * 0.05;
  double get armY => h * 0.085;
  List<Offset> get pins => [Offset(256, armY - 6), Offset(292, armY - 6), Offset(350, armY - 6)];

  @override
  bool operator ==(Object other) => other is M3ConductorJointGeo && other.h == h;
  @override
  int get hashCode => h.hashCode;
}

/// What the ground shows now.
@immutable
class M3ConductorJointView {
  const M3ConductorJointView({
    this.job,
    this.samples = const [],
    this.magnet = 0,
    this.magnetDone = false,
    this.brush = 0,
    this.brushed = false,
    this.sleeve,
    this.inserted = 0,
    this.press = 0,
    this.pressed = false,
    this.toolOn = false,
    this.showKit = false,
    this.heat = 0,
    this.heatAt,
    this.bad,
  });
  final M3ConductorJointJob? job;
  final List<M3ConductorJointSample> samples;

  /// The magnet test's motion (0–1), and whether it was done.
  final double magnet;
  final bool magnetDone;

  /// The brush's sweep (0–1).
  final double brush;
  final bool brushed;

  /// The sleeve on the joint (null = still in the kit).
  final M3ConductorJointSleeve? sleeve;
  final double inserted;

  /// The compressor's jaws closing (0–1).
  final double press;
  final bool pressed;

  /// The compressor's head is on the sleeve.
  final bool toolOn;

  /// The kit is open (its sleeves lit to pick).
  final bool showKit;

  /// The joint glowing under load (0–1).
  final double heat;
  final Offset? heatAt;

  /// How the made joint went wrong (drawn on the sleeve), if it did.
  final M3ConductorJointKind? bad;
}

/// The sky, the span, the near pole with its earth set, the field and the
/// tarp (behind the trainee).
class M3ConductorJointWorldPainter extends CustomPainter {
  const M3ConductorJointWorldPainter({required this.geo});
  final M3ConductorJointGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final g = geo.groundY;

    // --- sky -------------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5C9BD1), Color(0xFF9FC7E6), Color(0xFFEFE6CC)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(80.0, hz * 0.42, 15.0), (210.0, hz * 0.2, 19.0), (150.0, hz * 0.68, 11.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }

    // --- far land and the field ---------------------------------------------------
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 12 + 7 * math.sin(x * 0.05) + 5 * math.sin(x * 0.17 + 1.1);
      tree.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = const Color(0xFF4F7A55));
    final field = Rect.fromLTRB(0, hz, w, size.height);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB860), Color(0xFF6E9E45), Color(0xFF5B8538)],
          stops: [0, 0.5, 1],
        ).createShader(field),
    );
    final row = Paint()
      ..color = const Color(0x335A7F2E)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 6; i++) {
      final y = hz + (g - hz) * (i / 6) * (i / 6);
      c.drawLine(Offset(0, y), Offset(w, y), row);
    }

    // --- the far pole (left) ------------------------------------------------------
    const fx = 30.0;
    final farTop = geo.h * 0.11;
    c.drawPath(
        Path()
          ..moveTo(fx - 3, hz + 8)
          ..lineTo(fx - 2, farTop)
          ..lineTo(fx + 2, farTop)
          ..lineTo(fx + 3, hz + 8)
          ..close(),
        Paint()..color = const Color(0xFF9B9890));
    c.drawRect(Rect.fromLTWH(fx - 18, farTop + 6, 36, 3), Paint()..color = const Color(0xFF70757A));
    final farPins = [Offset(fx - 14, farTop + 4), Offset(fx, farTop + 4), Offset(fx + 14, farTop + 4)];

    // --- the near pole ------------------------------------------------------------
    _pole(c);

    // --- the conductors: two whole phases; the broken one hangs down to the
    // tarp from both poles ---------------------------------------------------
    final wire = Paint()
      ..color = const Color(0xFF2E3338)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final pins = geo.pins;
    for (final i in const [0, 2]) {
      final a = farPins[i];
      final b = pins[i];
      c.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo((a.dx + b.dx) / 2, math.max(a.dy, b.dy) + 26, b.dx, b.dy),
          wire);
    }
    final hang = Paint()
      ..color = const Color(0xFF3A4046)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final p1 = pins[1];
    c.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(p1.dx + 70, geo.h * 0.30, w + 6, geo.cableY - 4),
        hang);
    final f1 = farPins[1];
    c.drawPath(
        Path()
          ..moveTo(f1.dx, f1.dy)
          ..quadraticBezierTo(f1.dx - 34, geo.h * 0.33, -6, geo.cableY - 4),
        hang);
    for (final p in [...farPins, ...pins]) {
      c.drawRect(Rect.fromCenter(center: p.translate(0, 2), width: 4, height: 7), Paint()..color = const Color(0xFF7A4A2A));
    }

    // --- the earth set (the line is dead and earthed) ---------------------------
    _earth(c);

    // --- the tarpaulin --------------------------------------------------------------
    final tarp = Path()
      ..moveTo(6, geo.tarpTop + 4)
      ..lineTo(w - 4, geo.tarpTop)
      ..lineTo(w + 2, geo.tarpBottom)
      ..lineTo(-2, geo.tarpBottom + 4)
      ..close();
    c.drawPath(
        tarp,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F6FB5), Color(0xFF225890)])
              .createShader(Rect.fromLTRB(0, geo.tarpTop, w, geo.tarpBottom)));
    final fold = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1.4;
    for (final y in [0.33, 0.66]) {
      final yy = geo.tarpTop + (geo.tarpBottom - geo.tarpTop) * y;
      c.drawLine(Offset(0, yy), Offset(w, yy + 2), fold);
    }
    for (final p in [Offset(10, geo.tarpTop + 8), Offset(w - 10, geo.tarpTop + 5)]) {
      c.drawCircle(p, 2.4, Paint()..color = const Color(0xFFD7DEE6));
    }
  }

  void _pole(Canvas c) {
    const px = M3ConductorJointGeo.poleX;
    final g = geo.groundY;
    final top = geo.poleTop;
    const half0 = 11.0;
    const half1 = 7.0;
    final body = Path()
      ..moveTo(px - half0, g + 4)
      ..lineTo(px - half1, top)
      ..lineTo(px + half1, top)
      ..lineTo(px + half0, g + 4)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9C988E), Color(0xFFCBC7BC), Color(0xFF8E8A80)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(px - half0, top, px + half0, g)),
    );
    final arm = Paint()..color = const Color(0xFF6E757B);
    c.drawRect(Rect.fromLTRB(244, geo.armY - 3, 358, geo.armY + 3), arm);
    c.drawLine(Offset(px - 50, geo.armY + 2), Offset(px - 6, geo.armY + 34), Paint()..color = arm.color..strokeWidth = 2.6);
    for (final p in geo.pins) {
      // Pin insulators.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 4), width: 8, height: 9), const Radius.circular(2)), Paint()..color = const Color(0xFFE9E4D6));
    }
  }

  void _earth(Canvas c) {
    final spike = Offset(M3ConductorJointGeo.poleX - 30, geo.groundY + 8);
    final lead = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final join = Offset(M3ConductorJointGeo.poleX - 16, geo.armY + 52);
    for (final p in geo.pins) {
      final at = p.translate(6, 8);
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..quadraticBezierTo((at.dx + join.dx) / 2, join.dy + 8, join.dx, join.dy),
          lead);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 7, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 1), width: 7, height: 2), Paint()..color = const Color(0xFFF4D03F));
    }
    c.drawPath(
        Path()
          ..moveTo(join.dx, join.dy)
          ..quadraticBezierTo(join.dx - 12, (join.dy + spike.dy) / 2, spike.dx, spike.dy - 8),
        lead..strokeWidth = 2.2);
    c.drawRect(Rect.fromLTWH(spike.dx - 1.5, spike.dy - 10, 3, 14), Paint()..color = const Color(0xFF6B7076));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: spike.translate(0, -8), width: 8, height: 5), const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
  }

  @override
  bool shouldRepaint(M3ConductorJointWorldPainter old) => old.geo != geo;
}

/// On the tarp, in front of the trainee: the conductor ends and the sleeve
/// (a make-round) or the four finished joints (the tray), the docket, the
/// tools, the kit, the glow.
class M3ConductorJointGroundPainter extends CustomPainter {
  const M3ConductorJointGroundPainter({required this.geo, required this.view});
  final M3ConductorJointGeo geo;
  final M3ConductorJointView view;

  @override
  void paint(Canvas c, Size size) {
    final job = view.job;
    if (job != null) {
      _make(c, job);
    } else {
      for (final (i, s) in view.samples.indexed) {
        m3ConductorJointPaintSample(c, geo.trayAt(i), s);
      }
      final at = view.heatAt;
      if (view.heat > 0 && at != null) m3ConductorJointPaintHeat(c, at, view.heat);
    }
  }

  void _make(Canvas c, M3ConductorJointJob job) {
    final y = geo.cableY;
    final r = M3ConductorJointGeo.condR(job.code);
    // The docket: the conductor's code name.
    final d = geo.docket;
    c.drawRRect(RRect.fromRectAndRadius(d.translate(2, 3), const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(4)), Paint()..color = const Color(0xFFFFF8E7));
    c.drawRect(Rect.fromLTWH(d.left, d.top, d.width, 13), Paint()..color = const Color(0xFFE7C066));
    _bn(c, M3ConductorJointLines.docketHead, Offset(d.center.dx, d.top + 6.5), 9, const Color(0xFF3A2C06));
    _text(c, M3ConductorJointLines.codeName(job.code), Offset(d.center.dx, d.top + 26), 13, const Color(0xFF1C2E4A));

    // The two conductor ends.
    final ins = view.inserted;
    final l = M3ConductorJointGeo.tipL(ins);
    final rr = M3ConductorJointGeo.tipR(ins);
    _conductor(c, -6, l, y, r, job.type, dirtFrom: view.brushed ? null : (view.brush > 0 ? -6 + (l + 6) * view.brush : -6), dirtSide: -1);
    _conductor(c, rr, 366, y, r, job.type, dirtFrom: view.brushed ? null : (view.brush > 0 ? 366 - (366 - rr) * view.brush : 366), dirtSide: 1);

    // The sleeve on the joint.
    final s = view.sleeve;
    if (s != null) {
      m3ConductorJointPaintSleeve(
        c,
        Offset(M3ConductorJointGeo.jointX, y),
        M3ConductorJointGeo.half * 2,
        M3ConductorJointGeo.sleeveR(job.code),
        s,
        see: !view.pressed && view.bad == null,
        pressed: view.pressed || view.bad != null,
        bad: view.bad,
      );
    }

    // The kit (the sleeves still in it).
    final k = geo.kit;
    c.drawRRect(RRect.fromRectAndRadius(k.translate(2, 4), const Radius.circular(6)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(k, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B4A2A), Color(0xFF4A3018)]).createShader(k));
    c.drawRRect(RRect.fromRectAndRadius(k.deflate(4), const Radius.circular(4)), Paint()..color = const Color(0xFF2B1C0E));
    for (final (i, ks) in job.sleeves.indexed) {
      final at = geo.kitAt(i);
      if (s == ks) continue;
      m3ConductorJointPaintSleeve(c, at, 70, M3ConductorJointGeo.sleeveR(ks.code), ks);
      if (view.showKit) {
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: M3ConductorJointGeo.kitSize.width - 4, height: M3ConductorJointGeo.kitSize.height - 8), const Radius.circular(8)),
            Paint()
              ..color = const Color(0xFFFFF3C4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }

    // The brush: at rest, or sweeping both ends.
    if (view.brush > 0 && view.brush < 1) {
      final b = view.brush;
      final x = b < 0.5 ? 10 + (l - 10) * (b * 2) : 354 - (354 - rr) * ((b - 0.5) * 2);
      _brushAt(c, Offset(x, y - r - 22), 1);
    } else {
      _brushAt(c, geo.brushRest, 0.9, lying: true);
    }

    // The magnet: at rest, in the test's motion, then stuck (ACSR: the steel
    // core) or dropped beside (AAAC).
    final on = geo.magnetOn(job.code);
    final acsr = job.type == M3ConductorJointType.acsr;
    if (view.magnet > 0 && view.magnet < 1) {
      final v = view.magnet;
      if (v < 0.5) {
        final t = Curves.easeInOut.transform(v * 2);
        _magnet(c, Offset.lerp(geo.magnetRest, on, t)!, 0);
      } else {
        final t = (v - 0.5) * 2;
        _magnet(c, acsr ? on : Offset.lerp(on, geo.magnetDrop(job.code), Curves.easeIn.transform(t))!, acsr ? 0 : 1.2 * t);
      }
    } else if (view.magnetDone) {
      _magnet(c, acsr ? on : geo.magnetDrop(job.code), acsr ? 0 : 1.2);
    } else {
      _magnet(c, geo.magnetRest, 0);
    }

    // The compressor: on the sleeve (jaws closing), or at rest by the pump.
    final pump = geo.pump;
    final head = view.toolOn ? Offset(M3ConductorJointGeo.jointX, y) : pump.translate(-46, -4);
    c.drawPath(
        Path()
          ..moveTo(head.dx + 18, head.dy + 6)
          ..quadraticBezierTo((head.dx + pump.dx) / 2 + 10, math.max(head.dy, pump.dy) + 30, pump.dx - 8, pump.dy + 2),
        Paint()
          ..color = const Color(0xFF15181B)
          ..strokeWidth = 3.4
          ..style = PaintingStyle.stroke);
    _pump(c, pump);
    _compressor(c, head, view.toolOn ? view.press : 0, scale: view.toolOn ? 1 : 0.7, r: M3ConductorJointGeo.sleeveR(job.code));

    if (view.heat > 0) m3ConductorJointPaintHeat(c, view.heatAt ?? Offset(M3ConductorJointGeo.jointX, y), view.heat);
  }

  /// A stranded conductor from [x0] to [x1]; [dirtFrom]: the oxide film still
  /// on it from there to its tip ([dirtSide] −1 = the tip is at x1).
  void _conductor(Canvas c, double x0, double x1, double y, double r, M3ConductorJointType type, {double? dirtFrom, required int dirtSide}) {
    final rect = Rect.fromLTRB(x0, y - r, x1, y + r);
    final acsr = type == M3ConductorJointType.acsr;
    final metal = acsr ? const [Color(0xFFE0E4E8), Color(0xFF8E98A1)] : const [Color(0xFFF2F5F8), Color(0xFFA9B3BC)];
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.4)), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: metal).createShader(rect));
    // The lay of the outer strands.
    final lay = Paint()
      ..color = Color(acsr ? 0x55404850 : 0x33404850)
      ..strokeWidth = 0.9;
    for (var x = x0 + 2; x < x1 - 2; x += r * 0.9) {
      c.drawLine(Offset(x, y - r + 0.8), Offset(math.min(x + r * 0.9, x1), y + r - 0.8), lay);
    }
    if (dirtFrom != null) {
      // Grey-brown oxide and grime on the last part near the tip.
      final film = dirtSide < 0 ? Rect.fromLTRB(math.max(x0, math.max(dirtFrom, x1 - 70)), y - r, x1, y + r) : Rect.fromLTRB(x0, y - r, math.min(x1, math.min(dirtFrom, x0 + 70)), y + r);
      if (film.width > 0) c.drawRect(film, Paint()..color = const Color(0x99544B3A));
    }
  }

  void _brushAt(Canvas c, Offset at, double s, {bool lying = false}) {
    c.save();
    c.translate(at.dx, at.dy);
    if (lying) c.rotate(math.pi / 2);
    c.scale(s);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -30, 8, 34), const Radius.circular(3)), Paint()..color = const Color(0xFF8A4B22));
    c.drawRect(const Rect.fromLTWH(-7, 4, 14, 14), Paint()..color = const Color(0xFF6E6E6E));
    final bristle = Paint()
      ..color = const Color(0xFFD9D2C3)
      ..strokeWidth = 1;
    for (var x = -6.0; x <= 6; x += 2) {
      c.drawLine(Offset(x, 18), Offset(x, 25), bristle);
    }
    c.restore();
  }

  /// A horseshoe magnet, poles down, at [at] (the poles' centre), turned [tilt].
  void _magnet(Canvas c, Offset at, double tilt) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    final red = Paint()
      ..color = const Color(0xFFC0392B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    c.drawArc(Rect.fromCenter(center: const Offset(0, -12), width: 22, height: 22), math.pi, math.pi, false, red);
    c.drawLine(const Offset(-11, -12), const Offset(-11, -2), red);
    c.drawLine(const Offset(11, -12), const Offset(11, -2), red);
    final tip = Paint()..color = const Color(0xFFDDE2E6);
    c.drawRect(const Rect.fromLTWH(-14, -3, 6, 6), tip);
    c.drawRect(const Rect.fromLTWH(8, -3, 6, 6), tip);
    c.restore();
  }

  void _pump(Canvas c, Offset at) {
    final body = Rect.fromCenter(center: at, width: 20, height: 44);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFE5B23A), Color(0xFFB27F12)]).createShader(body));
    c.drawLine(at.translate(0, -22), at.translate(-24, -44), Paint()..color = const Color(0xFF2E353C)..strokeWidth = 4..strokeCap = StrokeCap.round);
    c.drawRect(Rect.fromCenter(center: at.translate(0, 18), width: 30, height: 6), Paint()..color = const Color(0xFF2E353C));
  }

  /// The compressor's C-head round the sleeve at [at]; [press] closes the dies.
  void _compressor(Canvas c, Offset at, double press, {required double scale, required double r}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(scale);
    final steel = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE2A93A), Color(0xFFA0700E)]).createShader(const Rect.fromLTWH(-22, -40, 44, 80));
    final gap = r + 5 + 6 * (1 - press.clamp(0.0, 1.0));
    // The C-frame: top jaw, back, the ram below.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-16, -gap - 16, 16, -gap), const Radius.circular(4)), steel);
    c.drawRect(Rect.fromLTRB(12, -gap - 14, 22, 30), steel);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-16, gap, 16, gap + 14), const Radius.circular(3)), steel);
    c.drawRect(Rect.fromLTRB(-10, gap + 14, 14, 34), Paint()..color = const Color(0xFF4D5863));
    // The die halves (steel grey).
    final die = Paint()..color = const Color(0xFF6E7881);
    c.drawRect(Rect.fromLTRB(-12, -gap - 4, 12, -gap), die);
    c.drawRect(Rect.fromLTRB(-12, gap, 12, gap + 4), die);
    c.restore();
  }

  @override
  bool shouldRepaint(M3ConductorJointGroundPainter old) => old.geo != geo || old.view != view;
}

/// A compression sleeve centred at [at] ([len] long, [r] half thick) with its
/// printed code; [see]: drawn a little see-through so the conductor tips
/// show inside; [pressed]: the compressor's bites along it ([bad] = how).
void m3ConductorJointPaintSleeve(Canvas c, Offset at, double len, double r, M3ConductorJointSleeve s,
    {bool see = false, bool pressed = false, M3ConductorJointKind? bad, String? label}) {
  final rect = Rect.fromCenter(center: at, width: len, height: r * 2);
  final acsr = s.type == M3ConductorJointType.acsr;
  final metal = acsr ? const [Color(0xFFDCE1E5), Color(0xFF8C969E)] : const [Color(0xFFEDEFF1), Color(0xFFB3BAC0)];
  final layer = see;
  if (layer) c.saveLayer(rect.inflate(4), Paint()..color = const Color.fromRGBO(0, 0, 0, 0.8));
  c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: metal).createShader(rect));
  c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF4A535B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
  if (pressed) {
    final bite = Paint()..color = const Color(0x664A535B);
    final edge = Paint()
      ..color = const Color(0xFF59636C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final n = bad == M3ConductorJointKind.halfPress ? 1 : 4;
    for (var i = 0; i < n; i++) {
      final cx = rect.left + 14 + (rect.width - 28) * (n == 1 ? 0.35 : i / (n - 1));
      final bw = len * 0.09;
      final deep = bad == M3ConductorJointKind.halfPress ? 0.25 : 1.0;
      final b = Rect.fromCenter(center: Offset(cx, at.dy), width: bw, height: rect.height);
      c.drawRect(Rect.fromLTRB(b.left, b.top, b.right, b.top + b.height * 0.5 * deep), bite);
      c.drawRect(Rect.fromLTRB(b.left, b.bottom - b.height * 0.5 * deep, b.right, b.bottom), bite);
      if (deep == 1) c.drawRect(b, edge);
    }
  }
  if (layer) c.restore();
  _text(c, label ?? M3ConductorJointLines.sleevePrint(s), Offset(at.dx + 3, at.dy), math.min(9.5, r * 1.15), const Color(0xFF1E252B));
}

/// One finished joint on the tray: a piece of conductor with its tag, the
/// sleeve in the middle.
void m3ConductorJointPaintSample(Canvas c, Offset at, M3ConductorJointSample s) {
  const size = M3ConductorJointGeo.traySize;
  final card = Rect.fromCenter(center: at, width: size.width, height: size.height);
  c.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(6)), Paint()..color = const Color(0x22FFFFFF));
  const r = 6.0;
  final y = at.dy + 8;
  final cond = Rect.fromLTRB(card.left + 4, y - r, card.right - 4, y + r);
  final acsr = s.type == M3ConductorJointType.acsr;
  c.drawRRect(RRect.fromRectAndRadius(cond, const Radius.circular(2)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: acsr ? const [Color(0xFFE0E4E8), Color(0xFF8E98A1)] : const [Color(0xFFF2F5F8), Color(0xFFA9B3BC)]).createShader(cond));
  final lay = Paint()
    ..color = const Color(0x44404850)
    ..strokeWidth = 0.9;
  for (var x = cond.left + 2; x < cond.right - 4; x += 5.4) {
    c.drawLine(Offset(x, y - r + 0.8), Offset(x + 5.4, y + r - 0.8), lay);
  }
  // The conductor's tag (white flag on a tie) on the left piece.
  final tag = Rect.fromLTWH(card.left + 6, card.top + 3, 64, 17);
  c.drawLine(Offset(tag.left + 10, tag.bottom), Offset(tag.left + 14, y - r), Paint()..color = const Color(0xFFEEEEEE)..strokeWidth = 1);
  c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = const Color(0xFFFFFFFF));
  _text(c, M3ConductorJointLines.tagPrint(s.type, s.code), tag.center, 9, const Color(0xFF1C2E4A));
  // The sleeve (the wrong one: the other type's sleeve).
  final sleeve = M3ConductorJointSleeve(s.kind == M3ConductorJointKind.wrongSleeve ? s.type.other : s.type, s.code);
  m3ConductorJointPaintSleeve(c, Offset(at.dx + 22, y), 84, r + 3.5, sleeve, pressed: true, bad: s.kind == M3ConductorJointKind.halfPress ? M3ConductorJointKind.halfPress : null);
  if (s.kind == M3ConductorJointKind.cutStrand) {
    // A cut strand springing out at the sleeve's left mouth.
    final mouth = Offset(at.dx + 22 - 42, y);
    final p = Paint()
      ..color = const Color(0xFFC9D0D6)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(mouth.dx - 2, y - r + 1)
          ..quadraticBezierTo(mouth.dx - 10, y - r - 10, mouth.dx - 20, y - r - 13),
        p);
    c.drawPath(
        Path()
          ..moveTo(mouth.dx - 14, y - r + 1)
          ..lineTo(mouth.dx - 22, y - r - 4),
        p);
  }
}

/// The joint glowing hot under load: a red-orange core, a heat haze and a
/// thin curl of smoke.
void m3ConductorJointPaintHeat(Canvas c, Offset at, double v) {
  final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
  final r = 18 + 34 * k;
  c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 240, 170, 0.95 * k),
          Color.fromRGBO(255, 120, 30, 0.75 * k),
          const Color(0x00FF3B1F),
        ], stops: const [0.0, 0.45, 1.0])
            .createShader(Rect.fromCircle(center: at, radius: r)));
  final haze = Paint()
    ..color = Color.fromRGBO(255, 170, 90, 0.5 * k)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  for (var i = -1; i <= 1; i++) {
    final x = at.dx + i * 12;
    final p = Path()..moveTo(x, at.dy - 14);
    for (var j = 1; j <= 4; j++) {
      p.quadraticBezierTo(x + (j.isEven ? 5 : -5), at.dy - 14 - j * 7 + 3, x, at.dy - 14 - j * 7);
    }
    c.drawPath(p, haze);
  }
  final smoke = Paint()..color = Color.fromRGBO(120, 120, 120, 0.35 * k);
  for (var i = 0; i < 4; i++) {
    c.drawCircle(at + Offset(4.0 * math.sin(i + v * 4), -30 - i * 11 - 14 * k), 5 + i * 2.2, smoke);
  }
}

void _text(Canvas c, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

void _bn(Canvas c, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: bangla(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}
