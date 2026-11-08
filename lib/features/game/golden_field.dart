import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The place of ladder step 21 ("গোল্ডেন মিনিট", lesson 1.7): a village field
// by the line, late afternoon. Drawn in layers — sky and clouds, the far tree
// line and village, the line's poles and wires, the dirt road where the
// ambulance comes, the field — then the colleague lying on the grass off the
// wire (non-graphic: in his uniform, eyes closed, no wounds; only a small
// burn mark on his hand in the play where the coworker talks of it), the
// trainee kneeling beside him, a small crowd and a phone on the grass. The
// pole and its ladder are a near layer, over the ambulance on the road.
// Design: 360 wide × the scene's height; the ground rows follow the bottom
// of the screen (a tall phone gets more sky).

/// Where things are in the field (design px, 360 wide).
@immutable
class GoldenGeo {
  const GoldenGeo({required this.height, required this.base});

  /// The scene of design height [h] with [inset] (bottom system inset, design px).
  factory GoldenGeo.forScene(double h, double inset) => GoldenGeo(height: h, base: h - inset);

  final double height;

  /// The bottom of the visible scene.
  final double base;

  double get horizonY => base - 380;
  double get roadY => horizonY + 28;
  double get crowdY => base - 304;

  /// The line through the middle of the colleague's body, lying on his back.
  double get lieY => base - 250;

  // Along his body (head on the left).
  static const headX = 70.0;
  static const shoulderX = 122.0;
  static const chestX = 178.0;
  static const hipX = 232.0;
  static const footX = 322.0;

  Offset get face => Offset(headX, lieY - 2);
  Offset get shoulder => Offset(shoulderX, lieY + 12);
  Offset get chest => Offset(chestX, lieY - 2);

  /// The crowd: three places to stand (left of the trainee).
  List<Offset> get crowdFeet => [Offset(30, crowdY + 4), Offset(80, crowdY - 6), Offset(128, crowdY + 2)];

  /// Where the phone lies on the grass.
  Offset phone(bool left) => left ? Offset(34, lieY + 52) : Offset(96, lieY + 64);

  /// Where the ambulance stops on the road (its centre), and where it comes from.
  double get ambulanceStopX => 246;
  double get ambulanceFromX => 440;

  @override
  bool operator ==(Object other) => other is GoldenGeo && other.height == height && other.base == base;

  @override
  int get hashCode => Object.hash(height, base);
}

// ============================================================================
// The field (static)
// ============================================================================

class GoldenFieldPainter extends CustomPainter {
  const GoldenFieldPainter({required this.geo, this.near = false});
  final GoldenGeo geo;

  /// The near layer only (the pole, its ladder and wires, grass tufts, the
  /// hot stick): painted above the ambulance, which drives along the road
  /// behind the pole. Otherwise the far layer (sky to road and field).
  final bool near;

  @override
  void paint(Canvas c, Size s) {
    if (near) {
      _near(c, s);
    } else {
      _far(c, s);
    }
  }

  void _far(Canvas c, Size s) {
    final w = s.width;
    final hz = geo.horizonY;
    final road = geo.roadY;

    // Sky, late afternoon.
    final sky = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5B92C8), Color(0xFFA9CBE6), Color(0xFFF4DFB8)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.2, hz - 150);
    c.drawCircle(sun, 110, Paint()..shader = const RadialGradient(colors: [Color(0x99FFE7B0), Color(0x00FFE7B0)]).createShader(Rect.fromCircle(center: sun, radius: 110)));
    c.drawCircle(sun, 15, Paint()..color = const Color(0xFFFFF1D0));
    final cloud = Paint()..color = const Color(0xD9FFFFFF);
    for (final (x, y, r) in const [(70.0, 0.30, 20.0), (210.0, 0.16, 16.0), (300.0, 0.38, 24.0), (150.0, 0.50, 13.0)]) {
      final cy = hz * y + 30;
      c.drawOval(Rect.fromCenter(center: Offset(x, cy), width: r * 4.2, height: r * 1.3), cloud);
      c.drawCircle(Offset(x - r * 0.6, cy - r * 0.35), r * 0.8, cloud);
      c.drawCircle(Offset(x + r * 0.5, cy - r * 0.5), r, cloud);
    }

    // Far: the tree line with palms.
    final trees = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 13 + 8 * math.sin(x * 0.05) + 5 * math.sin(x * 0.15 + 1.1);
      trees.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    trees
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(trees, Paint()..color = const Color(0xFF6A8B5E));
    for (final x in const [40.0, 196.0, 250.0]) {
      final top = Offset(x + 4, hz - 52);
      c.drawLine(Offset(x, hz), top, Paint()
        ..color = const Color(0xFF5E5040)
        ..strokeWidth = 2.2);
      final leaf = Paint()
        ..color = const Color(0xFF4F7447)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final a in const [-2.6, -2.0, -1.2, -0.5, 0.1]) {
        c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(top.dx + 10 * math.cos(a), top.dy + 10 * math.sin(a) - 4, top.dx + 17 * math.cos(a), top.dy + 17 * math.sin(a) + 5),
          leaf,
        );
      }
    }
    // The village: tin roofs.
    for (final (x, wd, ht, wall, roof) in const [
      (92.0, 46.0, 22.0, Color(0xFFE6D6B1), Color(0xFF7F8E9A)),
      (146.0, 34.0, 18.0, Color(0xFFD7C19E), Color(0xFF9A5B3C)),
      (282.0, 50.0, 24.0, Color(0xFFE9E1CF), Color(0xFF6F7F8C)),
    ]) {
      final b = hz + 3;
      c.drawRect(Rect.fromLTWH(x, b - ht, wd, ht), Paint()..color = wall);
      c.drawPath(
        Path()
          ..moveTo(x - 4, b - ht)
          ..lineTo(x + wd / 2, b - ht - 11)
          ..lineTo(x + wd + 4, b - ht)
          ..close(),
        Paint()..color = roof,
      );
      c.drawRect(Rect.fromLTWH(x + wd * 0.4, b - ht * 0.6, wd * 0.18, ht * 0.6), Paint()..color = const Color(0xFF5A4636));
    }

    // The field.
    final field = Rect.fromLTWH(0, hz, w, s.height - hz);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DBE74), Color(0xFF7FA95A), Color(0xFF5F8C43)],
          stops: [0, 0.35, 1],
        ).createShader(field),
    );
    // Paddy rows between the road and the crowd.
    final row = Paint()
      ..color = const Color(0x3348702E)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 6; i++) {
      final y = road + 22 + i * 9.0;
      c.drawLine(Offset(0, y), Offset(w, y + 3), row);
    }
    // The dirt road the ambulance comes along.
    final roadPath = Path()
      ..moveTo(0, road - 9)
      ..quadraticBezierTo(w / 2, road - 13, w, road - 8)
      ..lineTo(w, road + 12)
      ..quadraticBezierTo(w / 2, road + 8, 0, road + 11)
      ..close();
    c.drawPath(roadPath, Paint()..color = const Color(0xFFCDB083));
    c.drawLine(Offset(0, road + 11), Offset(w, road + 12), Paint()
      ..color = const Color(0xFFA88B5E)
      ..strokeWidth = 1.5);

    // The line: a row of far poles and the near one, wires across the sky.
    final farPole = Paint()
      ..color = const Color(0xFF8D8A80)
      ..strokeWidth = 2;
    for (final x in const [20.0, 120.0, 220.0]) {
      c.drawLine(Offset(x, hz + 2), Offset(x, hz - 46), farPole);
      c.drawLine(Offset(x - 7, hz - 42), Offset(x + 7, hz - 42), farPole);
    }
  }

  void _near(Canvas c, Size s) {
    final w = s.width;
    final hz = geo.horizonY;
    final road = geo.roadY;
    const px = 326.0;
    final poleTop = math.max(geo.height * 0.04, hz - 330);
    final poleFoot = road + 30;
    final pole = Rect.fromLTRB(px - 7, poleTop, px + 7, poleFoot);
    c.drawRect(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFB9B5AA), Color(0xFFE2DED3), Color(0xFF9C978B)]).createShader(pole),
    );
    c.drawRect(Rect.fromLTWH(px - 40, poleTop + 22, 80, 6), Paint()..color = const Color(0xFF5E636B));
    final wire = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (final dx in const [-34.0, 0.0, 34.0]) {
      final top = Offset(px + dx, poleTop + 14);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: top, width: 7, height: 12), const Radius.circular(3)), Paint()..color = const Color(0xFF8A4B2E));
      c.drawPath(
        Path()
          ..moveTo(top.dx, top.dy - 4)
          ..quadraticBezierTo(px / 2 + dx, top.dy + 34, -10, top.dy + 12 + dx * 0.2),
        wire,
      );
    }
    // A ladder against the pole.
    final rail = Paint()
      ..color = const Color(0xFFB8C0C8)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final l1 = Offset(px - 30, poleFoot + 2), l2 = Offset(px - 8, poleFoot - 150);
    c.drawLine(l1, l2, rail);
    c.drawLine(l1 + const Offset(12, 2), l2 + const Offset(9, 0), rail);
    for (var i = 1; i < 9; i++) {
      final a = Offset.lerp(l1, l2, i / 9)!;
      c.drawLine(a, a + const Offset(11, 0.6), rail..strokeWidth = 1.8);
    }
    rail.strokeWidth = 2.6;

    // Foreground grass tufts.
    final tuft = Paint()
      ..color = const Color(0xFF4C7A35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 34; i++) {
      final x = (i * 53.7) % w;
      final y = geo.lieY - 60 + (i * 37.3) % (s.height - geo.lieY + 60);
      c.drawLine(Offset(x, y), Offset(x - 3, y - 7), tuft);
      c.drawLine(Offset(x, y), Offset(x + 2, y - 8), tuft);
      c.drawLine(Offset(x, y), Offset(x + 5, y - 5), tuft);
    }
    // The fibreglass hot stick he was freed with, lying in the grass.
    final stickA = Offset(18, geo.base - 150), stickB = Offset(214, geo.base - 172);
    c.drawLine(stickA + const Offset(0, 3), stickB + const Offset(0, 3), Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawLine(stickA, stickB, Paint()
      ..color = const Color(0xFFF2B51E)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    c.drawLine(stickB, stickB + const Offset(10, -6), Paint()
      ..color = const Color(0xFF6B7178)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(GoldenFieldPainter old) => old.geo != geo || old.near != near;
}

// ============================================================================
// The colleague and the trainee
// ============================================================================

/// What the trainee is doing.
enum RescuerPose { rest, shoulder, face, point, cpr }

/// The colleague lying on his back (head left) and the trainee kneeling by
/// him. [press] 0..1: a chest compression; [shake]: a shoulder shake (0..1);
/// [pointAt]: where the trainee points (design px); [awake]: he has come round.
class GoldenPatientPainter extends CustomPainter {
  const GoldenPatientPainter({
    required this.geo,
    required this.pose,
    this.press = 0,
    this.shake = 0,
    this.pointAt,
    this.awake = false,
    this.phoneLeft,
    this.burn = false,
  });

  final GoldenGeo geo;
  final RescuerPose pose;
  final double press;
  final double shake;
  final Offset? pointAt;
  final bool awake;

  /// The phone on the grass (null: picked up / not drawn).
  final bool? phoneLeft;

  /// A small burn mark on the back of his near hand (the play where the
  /// coworker talks about it); non-graphic, a darker patch only.
  final bool burn;

  static const _skin = Color(0xFFB07A52);
  static const _skinDark = Color(0xFF8E5E3D);
  static const _shirt = Color(0xFF6B8799);
  static const _shirtDark = Color(0xFF4F697A);
  static const _trousers = Color(0xFF2E3846);

  // The trainee (LinemanLook.trainee's colours).
  static const _tHelmet = Color(0xFFFFD34E);
  static const _tShirt = Color(0xFF1F5F8F);
  static const _tVest = Color(0xFFFF851B);
  static const _tPants = Color(0xFF26303D);
  static const _tSkin = Color(0xFFA86E48);
  static const _tGlove = Color(0xFF8B5A2B);

  @override
  void paint(Canvas c, Size s) {
    final y = geo.lieY;
    final phone = phoneLeft;
    if (phone != null) _phone(c, geo.phone(phone));
    _rescuerBody(c, y);
    _victim(c, y);
    _rescuerArms(c, y);
  }

  void _phone(Canvas c, Offset p) {
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(-0.5);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(1, 2), width: 15, height: 26), const Radius.circular(3)), Paint()..color = const Color(0x40000000));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 14, height: 25), const Radius.circular(3)), Paint()..color = const Color(0xFF22262B));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -1), width: 10, height: 18), const Radius.circular(1.5)), Paint()..color = const Color(0xFF3E5B78));
    c.restore();
  }

  void _victim(Canvas c, double y) {
    const hx = GoldenGeo.headX, sx = GoldenGeo.shoulderX, cx = GoldenGeo.chestX, hip = GoldenGeo.hipX, fx = GoldenGeo.footX;
    final sink = 3.0 * press;
    // Shadow.
    c.drawOval(Rect.fromLTRB(hx - 30, y + 10, fx + 22, y + 34), Paint()..color = const Color(0x2E000000));
    // His helmet, lying behind his head.
    final helm = Offset(hx - 26, y - 30);
    c.drawPath(
      Path()
        ..addArc(Rect.fromCenter(center: helm, width: 30, height: 26), math.pi * 0.9, math.pi * 1.25)
        ..close(),
      Paint()..color = const Color(0xFFF4F4F2),
    );
    c.drawLine(helm + const Offset(-16, 4), helm + const Offset(14, 9), Paint()
      ..color = const Color(0xFFC9CDD1)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    // Legs (far one a little up), boots toes up.
    for (final (dy, shade) in const [(-8.0, 0.82), (7.0, 1.0)]) {
      final r = RRect.fromRectAndRadius(Rect.fromLTRB(hip - 6, y + dy - 8, fx, y + dy + 8), const Radius.circular(8));
      c.drawRRect(r, Paint()..color = Color.lerp(Colors.black, _trousers, shade)!);
      final boot = RRect.fromRectAndRadius(Rect.fromLTWH(fx - 4, y + dy - 14, 16, 22), const Radius.circular(6));
      c.drawRRect(boot, Paint()..color = Color.lerp(Colors.black, const Color(0xFF4A3424), shade)!);
    }
    // Far arm (a sliver above the torso).
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(sx - 2, y - 30, hip - 16, y - 18), const Radius.circular(6)), Paint()..color = _shirtDark);
    // Torso (the chest gives under a compression).
    final torso = Path()
      ..moveTo(sx - 14, y - 20)
      ..quadraticBezierTo(cx, y - 27 + sink, hip + 6, y - 20)
      ..lineTo(hip + 6, y + 20)
      ..quadraticBezierTo(cx, y + 25, sx - 14, y + 20)
      ..quadraticBezierTo(sx - 22, y, sx - 14, y - 20)
      ..close();
    c.drawPath(
      torso,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_shirt, _shirtDark]).createShader(Rect.fromLTRB(sx - 22, y - 27, hip + 6, y + 25)),
    );
    // Buttons and a pocket; the belt.
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(sx + 12 + i * 26, y - 1 + sink * 0.5), 1.6, Paint()..color = const Color(0xFFDDE4EA));
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(sx + 8, y - 16 + sink * 0.6, 18, 12), const Radius.circular(2)), Paint()..color = const Color(0x22000000));
    c.drawRect(Rect.fromLTRB(hip - 2, y - 21, hip + 6, y + 21), Paint()..color = const Color(0xFF3A2E22));
    // Near arm along his side.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(sx - 6, y + 12, hip - 22, y + 26), const Radius.circular(7)), Paint()..color = _shirt);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(hip - 26, y + 14, hip + 2, y + 25), const Radius.circular(6)), Paint()..color = _skin);
    c.drawCircle(Offset(hip + 4, y + 20), 6, Paint()..color = _skin);
    if (burn) {
      c.drawOval(Rect.fromCenter(center: Offset(hip - 2, y + 19), width: 9, height: 6), Paint()..color = const Color(0xCC6E3326));
      c.drawOval(Rect.fromCenter(center: Offset(hip - 2, y + 19), width: 5, height: 3), Paint()..color = const Color(0xFF8C4A35));
    }
    // Neck, collar.
    c.drawRect(Rect.fromLTRB(hx + 10, y - 7, sx - 12, y + 7), Paint()..color = _skinDark);
    // Head: seen from the side, face up.
    final head = Offset(hx, y - 2);
    c.drawCircle(head, 17, Paint()..color = _skin);
    c.drawPath(
      Path()..addArc(Rect.fromCircle(center: head, radius: 17), math.pi * 0.55, math.pi * 1.05),
      Paint()..color = const Color(0xFF2A2018),
    );
    c.drawCircle(head + const Offset(-1, 4), 4, Paint()..color = _skinDark); // ear
    // Nose (up), brow, eye, mouth.
    c.drawPath(
      Path()
        ..moveTo(head.dx + 2, head.dy - 16)
        ..quadraticBezierTo(head.dx + 6, head.dy - 22, head.dx + 9, head.dy - 15),
      Paint()..color = _skin,
    );
    final ink = Paint()
      ..color = const Color(0xFF2A2018)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (awake) {
      c.drawCircle(head + const Offset(-4, -10), 1.8, Paint()..color = const Color(0xFF2A2018));
      c.drawOval(Rect.fromCenter(center: head + const Offset(11, -8), width: 4, height: 3), Paint()..color = const Color(0xFF5A2E22));
    } else {
      c.drawLine(head + const Offset(-7, -10), head + const Offset(-1, -10), ink);
      c.drawLine(head + const Offset(9, -9), head + const Offset(13, -6), ink);
    }
  }

  /// Arm from [shoulder] to [hand] (upper arm then forearm, elbow bent out).
  void _arm(Canvas c, Offset shoulder, Offset hand, {double bend = 1}) {
    final mid = Offset.lerp(shoulder, hand, 0.5)!;
    final d = hand - shoulder;
    final len = d.distance;
    final n = len == 0 ? Offset.zero : Offset(-d.dy / len, d.dx / len);
    const reach = 64.0 * _k;
    final out = len >= reach ? 0.0 : math.sqrt(reach * reach / 4 - len * len / 4) * bend;
    final elbow = mid + n * out;
    final sleeve = Paint()
      ..color = _tShirt
      ..strokeWidth = 9 * _k
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..lineTo(elbow.dx, elbow.dy)
        ..lineTo(hand.dx, hand.dy),
      sleeve,
    );
    c.drawCircle(hand, 5.5 * _k, Paint()..color = _tGlove);
  }

  /// The trainee's size against the colleague (he kneels in front of the
  /// crowd, so he is drawn larger than them).
  static const _k = 1.3;

  /// The trainee's knee (he kneels just behind the colleague).
  double _rx() => switch (pose) {
        RescuerPose.rest => 166.0,
        RescuerPose.shoulder => 150.0,
        RescuerPose.face => 140.0,
        RescuerPose.point => 160.0,
        RescuerPose.cpr => GoldenGeo.chestX - 10,
      };

  /// His shoulders and head now.
  (Offset, Offset) _upper(double y) {
    final rx = _rx();
    final knee = y - 30;
    const k = _k;
    return switch (pose) {
      RescuerPose.cpr => (Offset(GoldenGeo.chestX + 3, knee - 62 * k + 5 * press), Offset(GoldenGeo.chestX + 8, knee - 80 * k + 5 * press)),
      // A deep lean from the hips, his head low over the colleague's face
      // (checking his breathing).
      RescuerPose.face => (Offset(rx - 34, knee - 56), Offset(GoldenGeo.headX + 16, y - 66)),
      RescuerPose.shoulder => (Offset(rx + 2 * k, knee - 72 * k), Offset(rx + 1 * k, knee - 90 * k)),
      _ => (Offset(rx + 6 * k, knee - 74 * k), Offset(rx + 6 * k, knee - 92 * k)),
    };
  }

  /// Legs, torso, head (drawn before the colleague: his knees are behind him).
  void _rescuerBody(Canvas c, double y) {
    const k = _k;
    final rx = _rx();
    final knee = y - 30;
    final hip = Offset(rx + 8 * k, knee - 32 * k);
    final (sh, head) = _upper(y);
    // Shins on the grass behind him, boots; the thigh up to the hip.
    final leg = Paint()
      ..color = _tPants
      ..strokeWidth = 13 * k
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(rx, knee), Offset(rx + 36 * k, knee - 4 * k), leg);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rx + 34 * k, knee - 13 * k, 14 * k, 16 * k), Radius.circular(5 * k)), Paint()..color = const Color(0xFF3A2A1E));
    c.drawLine(Offset(rx, knee), hip, leg..strokeWidth = 15 * k);
    // Torso: shirt, then the vest with its reflective band.
    final dir = sh - hip;
    final len = dir.distance;
    final n = Offset(-dir.dy / len, dir.dx / len);
    Path quad(double wHip, double wSh) => Path()
      ..moveTo(hip.dx + n.dx * wHip, hip.dy + n.dy * wHip)
      ..lineTo(sh.dx + n.dx * wSh, sh.dy + n.dy * wSh)
      ..lineTo(sh.dx - n.dx * wSh, sh.dy - n.dy * wSh)
      ..lineTo(hip.dx - n.dx * wHip, hip.dy - n.dy * wHip)
      ..close();
    c.drawPath(quad(13 * k, 14 * k), Paint()..color = _tShirt);
    c.drawPath(quad(12 * k, 10 * k), Paint()..color = _tVest);
    final band = Offset.lerp(hip, sh, 0.42)!;
    c.drawLine(band + n * 12 * k, band - n * 12 * k, Paint()
      ..color = const Color(0xFFE8ECEF)
      ..strokeWidth = 3.4 * k);
    // Neck, head with a face, helmet.
    c.drawLine(sh, head, Paint()
      ..color = _tSkin
      ..strokeWidth = 8 * k);
    final r = 11 * k;
    c.drawCircle(head, r, Paint()..color = _tSkin);
    // Bent over his face the head tips forward (crown up-left) and he faces
    // down-left, at the colleague; otherwise the head sits on the neck.
    final bent = pose == RescuerPose.face;
    final hd = bent ? const Offset(-0.5, -0.866) : (head - sh) / (head - sh).distance;
    final hn = Offset(-hd.dy, hd.dx);
    final fn = bent ? -hn : hn;
    final eye = head + fn * 4 * k + hd * 1 * k;
    c.drawCircle(eye, 1.6 * k, Paint()..color = const Color(0xFF2A2018));
    c.drawLine(head + fn * 5 * k - hd * 5 * k, head + fn * 1 * k - hd * 6 * k, Paint()
      ..color = const Color(0xFF6E3F27)
      ..strokeWidth = 1.6 * k
      ..strokeCap = StrokeCap.round);
    final crown = head + hd * 3 * k;
    c.drawPath(
      Path()
        ..moveTo(crown.dx + hn.dx * 14 * k, crown.dy + hn.dy * 14 * k)
        ..quadraticBezierTo(crown.dx + hd.dx * 22 * k, crown.dy + hd.dy * 22 * k, crown.dx - hn.dx * 14 * k, crown.dy - hn.dy * 14 * k)
        ..close(),
      Paint()..color = _tHelmet,
    );
    c.drawLine(crown + hn * 17 * k, crown - hn * 15 * k, Paint()
      ..color = const Color(0xFFE0B22E)
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round);
  }

  /// Arms and hands (drawn over the colleague: they reach him).
  void _rescuerArms(Canvas c, double y) {
    const k = _k;
    final rx = _rx();
    final knee = y - 30;
    final hip = Offset(rx + 8 * k, knee - 32 * k);
    final (sh, _) = _upper(y);
    final far = sh + Offset(5 * k, -2 * k);
    final farHand = switch (pose) {
      RescuerPose.cpr => Offset(GoldenGeo.chestX + 2, y - 8 + 4 * press),
      // One hand on his forehead.
      RescuerPose.face => Offset(GoldenGeo.headX + 4, y - 18),
      _ => hip + Offset(12 * k, 4 * k),
    };
    _arm(c, far, farHand, bend: -1);
    final near = sh + Offset(-3 * k, 3 * k);
    final shakeX = math.sin(shake * math.pi * 6) * 3 * (1 - shake);
    final nearHand = switch (pose) {
      RescuerPose.cpr => Offset(GoldenGeo.chestX - 1, y - 7 + 4 * press),
      RescuerPose.shoulder => Offset(GoldenGeo.shoulderX + 2 + shakeX, y - 14),
      // The other on his chest.
      RescuerPose.face => Offset(GoldenGeo.shoulderX + 18, y - 12),
      RescuerPose.point => () {
          final t = pointAt ?? Offset(near.dx - 40, near.dy - 30);
          final d = t - near;
          return near + d / d.distance * 62 * k;
        }(),
      RescuerPose.rest => hip + Offset(16 * k, 2 * k),
    };
    _arm(c, near, nearHand, bend: pose == RescuerPose.point ? 0.1 : 1);
    if (pose == RescuerPose.cpr) {
      // Hands one over the other, heel of the hand on the middle of the chest.
      c.drawOval(Rect.fromCenter(center: Offset(GoldenGeo.chestX, y - 6 + 4 * press), width: 18, height: 9), Paint()..color = _tGlove);
    }
  }

  @override
  bool shouldRepaint(GoldenPatientPainter old) =>
      old.geo != geo ||
      old.pose != pose ||
      old.press != press ||
      old.shake != shake ||
      old.pointAt != pointAt ||
      old.awake != awake ||
      old.phoneLeft != phoneLeft ||
      old.burn != burn;
}

// ============================================================================
// The crowd
// ============================================================================

/// The people who gathered (looks dealt per play).
enum Bystander { sari, lungi, shirt, elder, youth }

class GoldenCrowdPainter extends CustomPainter {
  const GoldenCrowdPainter({required this.geo, required this.crowd, this.caller});
  final GoldenGeo geo;
  final List<Bystander> crowd;

  /// The one calling the ambulance (phone at the ear), or null.
  final int? caller;

  static const _skin = Color(0xFFAF7A54);

  @override
  void paint(Canvas c, Size s) {
    final feet = geo.crowdFeet;
    for (var i = 0; i < crowd.length && i < feet.length; i++) {
      _person(c, crowd[i], feet[i], calling: caller == i);
    }
  }

  void _person(Canvas c, Bystander b, Offset f, {required bool calling}) {
    final x = f.dx, y = f.dy;
    c.drawOval(Rect.fromCenter(center: Offset(x, y + 1), width: 30, height: 7), Paint()..color = const Color(0x30000000));
    final legs = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final (Color top, Color low, Color hair) = switch (b) {
      Bystander.sari => (const Color(0xFFC94F7C), const Color(0xFFD86A93), const Color(0xFF1E1712)),
      Bystander.lungi => (const Color(0xFFF2F0EA), const Color(0xFF2F7A5A), const Color(0xFF241A12)),
      Bystander.shirt => (const Color(0xFF8DB6DA), const Color(0xFF5B6068), const Color(0xFF241A12)),
      Bystander.elder => (const Color(0xFFF4F2EC), const Color(0xFFE4E1D8), const Color(0xFFDADADA)),
      Bystander.youth => (const Color(0xFFF2C230), const Color(0xFF3D5A80), const Color(0xFF1E1712)),
    };
    // Lower body.
    switch (b) {
      case Bystander.sari:
        c.drawPath(
          Path()
            ..moveTo(x - 9, y - 44)
            ..lineTo(x + 9, y - 44)
            ..lineTo(x + 13, y)
            ..lineTo(x - 13, y)
            ..close(),
          Paint()..color = low,
        );
      case Bystander.lungi:
        c.drawRect(Rect.fromLTRB(x - 10, y - 44, x + 10, y - 12), Paint()..color = low);
        for (var k = 0; k < 4; k++) {
          c.drawLine(Offset(x - 10, y - 40 + k * 8), Offset(x + 10, y - 40 + k * 8), Paint()
            ..color = const Color(0x55FFFFFF)
            ..strokeWidth = 1);
        }
        c.drawLine(Offset(x - 4, y - 12), Offset(x - 5, y), legs..color = _skin);
        c.drawLine(Offset(x + 4, y - 12), Offset(x + 5, y), legs);
        legs.color = const Color(0xFF3A3A3A);
      case Bystander.elder:
        c.drawLine(Offset(x - 4, y - 20), Offset(x - 5, y), legs..color = low);
        c.drawLine(Offset(x + 4, y - 20), Offset(x + 5, y), legs);
        legs.color = const Color(0xFF3A3A3A);
      case Bystander.shirt:
      case Bystander.youth:
        c.drawLine(Offset(x - 4, y - 44), Offset(x - 5, y), legs..color = low);
        c.drawLine(Offset(x + 4, y - 44), Offset(x + 5, y), legs);
        legs.color = const Color(0xFF3A3A3A);
    }
    // Torso (the elder's panjabi reaches the knees).
    final torso = RRect.fromRectAndRadius(Rect.fromLTRB(x - 10, y - 78, x + 10, b == Bystander.elder ? y - 18 : y - 42), const Radius.circular(7));
    c.drawRRect(torso, Paint()..color = top);
    if (b == Bystander.sari) {
      // The end of the sari over the shoulder.
      c.drawPath(
        Path()
          ..moveTo(x - 10, y - 76)
          ..lineTo(x + 4, y - 78)
          ..lineTo(x + 10, y - 46)
          ..lineTo(x + 2, y - 46)
          ..close(),
        Paint()..color = low,
      );
    }
    // Arms: one hangs; the caller holds a phone to his ear.
    final arm = Paint()
      ..color = b == Bystander.lungi ? _skin : top
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(x - 10, y - 74), Offset(x - 13, y - 48), arm);
    if (calling) {
      c.drawPath(
        Path()
          ..moveTo(x + 10, y - 74)
          ..lineTo(x + 15, y - 62)
          ..lineTo(x + 8, y - 86),
        arm,
      );
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + 8, y - 90), width: 6, height: 11), const Radius.circular(2)), Paint()..color = const Color(0xFF22262B));
      final wave = Paint()
        ..color = const Color(0xFF2E8B45)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final r in const [6.0, 11.0]) {
        c.drawArc(Rect.fromCircle(center: Offset(x + 12, y - 92), radius: r), -0.9, 1.3, false, wave);
      }
    } else {
      c.drawLine(Offset(x + 10, y - 74), Offset(x + 13, y - 48), arm);
    }
    // Head and hair.
    final head = Offset(x, y - 88);
    c.drawCircle(head, 8.5, Paint()..color = _skin);
    switch (b) {
      case Bystander.sari:
        c.drawPath(Path()..addArc(Rect.fromCircle(center: head, radius: 9), math.pi, math.pi), Paint()..color = hair);
        c.drawCircle(head + const Offset(-8, -2), 4, Paint()..color = hair);
      case Bystander.elder:
        c.drawPath(Path()..addArc(Rect.fromCircle(center: head + const Offset(0, -3), radius: 8), math.pi, math.pi), Paint()..color = const Color(0xFFFFFFFF));
        c.drawPath(Path()..addArc(Rect.fromCircle(center: head + const Offset(0, 3), radius: 7), 0.2, math.pi - 0.4), Paint()..color = hair);
      case Bystander.youth:
        for (var k = -2; k <= 2; k++) {
          c.drawLine(head + Offset(k * 3.0, -6), head + Offset(k * 3.5, -12), Paint()
            ..color = hair
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round);
        }
      default:
        c.drawPath(Path()..addArc(Rect.fromCircle(center: head + const Offset(0, -1), radius: 9), math.pi * 1.05, math.pi * 0.9), Paint()..color = hair);
    }
    c.drawCircle(head + const Offset(-3, 0), 1.1, Paint()..color = const Color(0xFF2A2018));
    c.drawCircle(head + const Offset(3, 0), 1.1, Paint()..color = const Color(0xFF2A2018));
  }

  @override
  bool shouldRepaint(GoldenCrowdPainter old) => old.geo != geo || old.caller != caller || !_same(old.crowd, crowd);

  static bool _same(List<Bystander> a, List<Bystander> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ============================================================================
// The ambulance
// ============================================================================

/// The ambulance on the road; [progress] 0 → 1 drives it in from the right.
class AmbulancePainter extends CustomPainter {
  AmbulancePainter({required this.geo, required this.progress, required this.label}) : super(repaint: progress);
  final GoldenGeo geo;
  final Animation<double> progress;
  final String label;

  @override
  void paint(Canvas c, Size s) {
    final t = progress.value;
    if (t <= 0) return;
    final k = Curves.easeOutCubic.transform(t);
    final x = geo.ambulanceFromX + (geo.ambulanceStopX - geo.ambulanceFromX) * k;
    final y = geo.roadY + 4;
    c.save();
    c.translate(x, y);
    // Driving left: the cab is on the left.
    c.drawOval(Rect.fromCenter(center: const Offset(0, 4), width: 104, height: 10), Paint()..color = const Color(0x40000000));
    final body = Rect.fromLTRB(-22, -46, 50, 0);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFDDE3EA)]).createShader(body),
    );
    final cab = Path()
      ..moveTo(-22, -34)
      ..lineTo(-38, -34)
      ..lineTo(-50, -16)
      ..lineTo(-50, 0)
      ..lineTo(-22, 0)
      ..close();
    c.drawPath(cab, Paint()..color = const Color(0xFFF2F4F7));
    c.drawPath(
      Path()
        ..moveTo(-25, -31)
        ..lineTo(-37, -31)
        ..lineTo(-46, -18)
        ..lineTo(-25, -18)
        ..close(),
      Paint()..color = const Color(0xFF8FB7DD),
    );
    c.drawRect(const Rect.fromLTRB(-50, -14, 50, -9), Paint()..color = const Color(0xFFD63A2F));
    // The light bar (flashes while it comes).
    final on = t >= 1 || ((t * 14).floor().isEven);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -52, 22, 6), const Radius.circular(2)), Paint()..color = on ? const Color(0xFF2F7DE1) : const Color(0xFF9DB4D1));
    if (on && t < 1) {
      c.drawCircle(const Offset(-3, -49), 14, Paint()..color = const Color(0x332F7DE1));
    }
    // The word on the side, as painted on the van.
    final tp = TextPainter(
      text: TextSpan(text: label, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFFC0392B))),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 70);
    tp.paint(c, Offset(14 - tp.width / 2, -36));
    // Wheels.
    for (final wx in const [-34.0, 32.0]) {
      c.drawCircle(Offset(wx, 0), 8, Paint()..color = const Color(0xFF22262B));
      c.drawCircle(Offset(wx, 0), 3.5, Paint()..color = const Color(0xFF9AA3AB));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(AmbulancePainter old) => old.geo != geo || old.progress != progress || old.label != label;
}
