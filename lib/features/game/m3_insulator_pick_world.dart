import 'dart:math' as math;

import 'package:flutter/material.dart';

// The field for lesson 3.2, কাজ 1 "কোথায় কোন ইনসুলেটর": a drawn scene — sky,
// a far tree line with a small line of poles, a field, one new pole close up
// (seen from the side: the line runs left–right across the screen), its
// danger board, and a tarp of insulators from the store at its foot (the
// insulators, the board's text and the trainee are widgets on it). No text in
// the art. Design: 360 wide × any height; the pole stands on the ground row,
// so a tall phone gets more sky, never a stretched pole.
//
// The pole is one of three spots: an HT pole where the line runs straight
// (the wires pass on both sides), an LT pole where the line ends (dead end:
// the wires come from the right only, a stay wire pulls back to the left), or
// an HT pole where the line ends. Before the insulator is chosen the
// conductors' route is drawn dashed and faint; once the right insulator is
// fitted, it shows at every phase and the wires are drawn solid.
//
// Also here: the insulators themselves (pin, shackle, a string of discs),
// lying lengthwise for the close look; the rack stands them upright.

/// Where the line's spot is.
enum M3InsulatorPickSite { straightHt, endLt, endHt }

/// Which insulator.
enum M3InsulatorPickKind { pin, shackle, disc }

/// Where things are, in design pixels (360 × [h]).
@immutable
class M3InsulatorPickGeo {
  const M3InsulatorPickGeo(this.h);
  final double h;

  /// Where the pole stands.
  double get groundY => h - 262;
  double get horizon => groundY - 46;
  static const poleX = 214.0;
  double get poleTop => math.max(150.0, h - 690);

  /// The crossarm (seen a little from the side: the near end lower left).
  double get armY => poleTop + 34;

  /// The phases' fixing points on an HT pole: the pole-top, the crossarm's
  /// near end, its far end.
  List<Offset> get htPoints => [Offset(poleX, poleTop + 2), Offset(poleX - 44, armY + 12), Offset(poleX + 44, armY - 10)];

  /// The four LT wires' points, down the pole.
  List<Offset> get ltPoints => [for (var i = 0; i < 4; i++) Offset(poleX + 7, poleTop + 34 + i * 28.0)];

  /// The danger board on the pole.
  Rect get plate => Rect.fromCenter(center: Offset(poleX, math.min(poleTop + 176, groundY - 50)), width: 40, height: 30);

  /// The tarp of insulators on the ground in front.
  Rect get rack => Rect.fromLTRB(84, h - 254, 354, h - 194);

  /// Place [i] of [n] on the tarp: an insulator stands in it.
  Rect slot(int i, int n) {
    final t = rack.deflate(4);
    final w = t.width / n;
    return Rect.fromLTWH(t.left + w * i, t.top, w, t.height);
  }

  /// Insulators set aside, by the trainee's feet.
  Rect aside(int i) => Rect.fromLTWH(4 + i * 26.0, h - 190, 24, 34);

  /// The trainee, on the ground at the left.
  Rect get trainee => Rect.fromLTWH(2, h - 402, 78, 156);
}

/// The sky, the far fields and line, the ground and the tarp (all static).
class M3InsulatorPickFieldPainter extends CustomPainter {
  const M3InsulatorPickFieldPainter(this.geo);
  final M3InsulatorPickGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final sky = Rect.fromLTWH(0, 0, w, geo.horizon + 2);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E9BD1), Color(0xFF9CC8E8), Color(0xFFDDEDF2)],
        ).createShader(sky),
    );
    // Sun and clouds.
    c.drawCircle(Offset(62, geo.poleTop - 40), 22, Paint()..color = const Color(0x55FFF4C8));
    c.drawCircle(Offset(62, geo.poleTop - 40), 14, Paint()..color = const Color(0xFFFFF1B8));
    final cloud = Paint()..color = const Color(0xD9FFFFFF);
    for (final o in [Offset(118, geo.poleTop - 12), Offset(300, geo.poleTop + 70), Offset(40, geo.poleTop + 120)]) {
      c.drawOval(Rect.fromCenter(center: o, width: 70, height: 18), cloud);
      c.drawOval(Rect.fromCenter(center: o + const Offset(-12, -8), width: 34, height: 18), cloud);
      c.drawOval(Rect.fromCenter(center: o + const Offset(12, -7), width: 30, height: 16), cloud);
    }
    // The far tree line.
    final trees = Path()..moveTo(0, geo.horizon);
    for (var x = 0.0; x <= w; x += 18) {
      trees.quadraticBezierTo(x + 9, geo.horizon - 16 - 6 * math.sin(x * 0.7), x + 18, geo.horizon);
    }
    trees
      ..lineTo(w, geo.horizon + 4)
      ..lineTo(0, geo.horizon + 4)
      ..close();
    c.drawPath(trees, Paint()..color = const Color(0xFF6E9A6A));
    // A small far line of poles.
    final far = Paint()..color = const Color(0xFF8299A6);
    for (var i = 0; i < 6; i++) {
      final x = 20.0 + i * 64;
      c.drawRect(Rect.fromLTWH(x, geo.horizon - 34, 2, 34), far);
      c.drawRect(Rect.fromLTWH(x - 6, geo.horizon - 32, 14, 1.6), far);
    }
    c.drawLine(Offset(0, geo.horizon - 30), Offset(w, geo.horizon - 31), Paint()
      ..color = const Color(0xFF7C909C)
      ..strokeWidth = 0.7);
    // The field.
    final field = Rect.fromLTRB(0, geo.horizon, w, s.height);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DB872), Color(0xFF7FA05A), Color(0xFF5E7C42)],
        ).createShader(field),
    );
    // A dirt path along the line.
    final path = Path()
      ..moveTo(0, geo.groundY + 4)
      ..lineTo(w, geo.groundY - 6)
      ..lineTo(w, geo.groundY + 22)
      ..lineTo(0, geo.groundY + 36)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFFB79D72));
    // Tufts of grass.
    final tuft = Paint()
      ..color = const Color(0xFF4F6E36)
      ..strokeWidth = 1.2;
    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * w;
      final y = geo.groundY + 40 + rnd.nextDouble() * (s.height - geo.groundY - 50);
      c.drawLine(Offset(x, y), Offset(x - 2, y - 5), tuft);
      c.drawLine(Offset(x, y), Offset(x + 2, y - 6), tuft);
    }

    // The tarp the store's insulators stand on.
    final t = geo.rack.inflate(6);
    c.drawRRect(RRect.fromRectAndRadius(t.shift(const Offset(2, 4)), const Radius.circular(6)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F6FA8), Color(0xFF225886)],
        ).createShader(t),
    );
    final seam = Paint()
      ..color = const Color(0x553F86C4)
      ..strokeWidth = 1;
    for (var x = t.left + 30; x < t.right; x += 30) {
      c.drawLine(Offset(x, t.top + 3), Offset(x, t.bottom - 3), seam);
    }
    for (final o in [t.topLeft + const Offset(5, 5), t.topRight + const Offset(-5, 5), t.bottomLeft + const Offset(5, -5), t.bottomRight + const Offset(-5, -5)]) {
      c.drawCircle(o, 2.2, Paint()..color = const Color(0xFFD7DDE2));
    }
  }

  @override
  bool shouldRepaint(M3InsulatorPickFieldPainter old) => old.geo.h != geo.h;
}

/// The pole close up, its crossarm (HT), the stay wire (dead end), the
/// conductors' route, the danger board, and the fitted insulators.
class M3InsulatorPickPolePainter extends CustomPainter {
  const M3InsulatorPickPolePainter(this.geo, {required this.site, this.fitted, this.discs = 0});
  final M3InsulatorPickGeo geo;
  final M3InsulatorPickSite site;

  /// The insulator fitted at every phase (null: not chosen yet).
  final M3InsulatorPickKind? fitted;
  final int discs;

  bool get _ht => site != M3InsulatorPickSite.endLt;
  bool get _end => site != M3InsulatorPickSite.straightHt;

  @override
  void paint(Canvas c, Size s) {
    final x = M3InsulatorPickGeo.poleX;
    final top = geo.poleTop;
    final base = geo.groundY + 12;
    // The stay wire (a dead end is pulled back the other way).
    if (_end) {
      final from = Offset(x - 3, top + (_ht ? 44 : 30));
      final to = Offset(x - 118, base + 16);
      c.drawLine(from, to, Paint()
        ..color = const Color(0xFF4B5056)
        ..strokeWidth = 1.6);
      c.drawRect(Rect.fromCenter(center: to, width: 10, height: 5), Paint()..color = const Color(0xFF6B5A44));
      // The stay insulator (egg) on the stay wire.
      final eg = Offset.lerp(from, to, 0.36)!;
      c.drawOval(Rect.fromCenter(center: eg, width: 9, height: 12), Paint()..color = const Color(0xFF7A4326));
    }
    // The pole: a tapered concrete pole.
    final pole = Path()
      ..moveTo(x - 4, top - 4)
      ..lineTo(x + 4, top - 4)
      ..lineTo(x + 8, base)
      ..lineTo(x - 8, base)
      ..close();
    c.drawPath(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8E959B), Color(0xFFCDD2D6), Color(0xFF7A8086)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(x - 8, top, x + 8, base)),
    );
    c.drawOval(Rect.fromCenter(center: Offset(x, base + 1), width: 30, height: 7), Paint()..color = const Color(0x55000000));
    // Anti-climbing barbed wire band.
    final band = Paint()
      ..color = const Color(0xFF5B6066)
      ..strokeWidth = 0.9;
    for (var i = 0; i < 5; i++) {
      final y = geo.plate.bottom + 14 + i * 3.0;
      c.drawLine(Offset(x - 8, y), Offset(x + 8, y + 2), band);
    }

    // The HT crossarm (a channel seen a little from the side).
    if (_ht) {
      final p = geo.htPoints;
      final arm = Path()
        ..moveTo(p[1].dx - 6, p[1].dy + 2)
        ..lineTo(p[2].dx + 6, p[2].dy + 2)
        ..lineTo(p[2].dx + 6, p[2].dy + 7)
        ..lineTo(p[1].dx - 6, p[1].dy + 7)
        ..close();
      c.drawPath(arm, Paint()..color = const Color(0xFF4E5A63));
      c.drawLine(Offset(p[1].dx - 6, p[1].dy + 2), Offset(p[2].dx + 6, p[2].dy + 2), Paint()
        ..color = const Color(0xFF8A98A3)
        ..strokeWidth = 1);
      // The clamp holding it to the pole.
      c.drawRect(Rect.fromCenter(center: Offset(x, geo.armY + 3), width: 14, height: 9), Paint()..color = const Color(0xFF3E474F));
    }

    // The conductors' route, and the insulators once fitted.
    final solid = fitted != null;
    final wire = Paint()
      ..color = solid ? const Color(0xFF2B3036) : const Color(0x88FFFFFF)
      ..strokeWidth = solid ? 1.5 : 1.2
      ..style = PaintingStyle.stroke;
    final points = _ht ? geo.htPoints : geo.ltPoints;
    for (final p in points) {
      // Where the conductor leaves the insulator.
      final Offset at;
      if (!_end) {
        at = p + const Offset(0, -17);
      } else if (_ht) {
        at = p + Offset(22 + 11.0 * math.max(1, discs), 0);
      } else {
        at = p + const Offset(14, 0);
      }
      final right = Path()
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo((at.dx + s.width) / 2, at.dy + 16, s.width + 4, at.dy - 2);
      _route(c, right, wire, solid);
      if (!_end) {
        final left = Path()
          ..moveTo(at.dx, at.dy)
          ..quadraticBezierTo(at.dx / 2, at.dy + 14, -4, at.dy - 3);
        _route(c, left, wire, solid);
      }
      final f = fitted;
      if (f != null) _fit(c, p, f);
    }
    // The danger board.
    final b = geo.plate;
    c.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(1, 2)), const Radius.circular(2)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2)), Paint()..color = const Color(0xFFF4F1E8));
    c.drawRRect(
      RRect.fromRectAndRadius(b.deflate(1.5), const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFFC62828)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // A small skull mark at the top.
    c.drawCircle(Offset(b.center.dx, b.top + 7), 3.2, Paint()..color = const Color(0xFFC62828));
  }

  void _route(Canvas c, Path p, Paint paint, bool solid) {
    if (solid) {
      c.drawPath(p, paint);
      return;
    }
    for (final m in p.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        c.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
      }
    }
  }

  /// The insulator fitted at [p].
  void _fit(Canvas c, Offset p, M3InsulatorPickKind k) {
    switch (k) {
      case M3InsulatorPickKind.pin:
        // Upright on its pin: the head (groove) at the top.
        c.save();
        c.translate(p.dx, p.dy);
        _upright(c, const Size(20, 20));
        c.restore();
      case M3InsulatorPickKind.shackle:
        // On a D-iron at the pole's side.
        c.drawRect(Rect.fromLTWH(p.dx - 3, p.dy - 7, 10, 2), Paint()..color = const Color(0xFF3E474F));
        c.drawRect(Rect.fromLTWH(p.dx - 3, p.dy + 5, 10, 2), Paint()..color = const Color(0xFF3E474F));
        c.drawRect(Rect.fromLTWH(p.dx + 5, p.dy - 7, 2, 14), Paint()..color = const Color(0xFF3E474F));
        final sp = Rect.fromCenter(center: p + const Offset(2, 0), width: 10, height: 11);
        c.drawRRect(RRect.fromRectAndRadius(sp, const Radius.circular(3)), Paint()..color = _glazeMid);
        c.drawRect(Rect.fromCenter(center: sp.center, width: 5, height: 4), Paint()..color = _glazeLight);
      case M3InsulatorPickKind.disc:
        // A string, lengthwise from the fixing point toward the pull.
        final n = math.max(1, discs);
        final hook = Paint()
          ..color = const Color(0xFF59626A)
          ..strokeWidth = 1.6;
        c.drawLine(p, p + const Offset(8, 0), hook);
        for (var i = 0; i < n; i++) {
          final cx = p.dx + 13 + i * 11.0;
          c.drawOval(Rect.fromCenter(center: Offset(cx, p.dy), width: 7, height: 20), Paint()..color = _discMid);
          c.drawOval(Rect.fromCenter(center: Offset(cx - 1, p.dy - 1), width: 3, height: 13), Paint()..color = _discLight);
        }
        c.drawLine(p + Offset(10 + 11.0 * n, 0), p + Offset(22 + 11.0 * n, 0), hook);
    }
  }

  @override
  bool shouldRepaint(M3InsulatorPickPolePainter old) => old.geo.h != geo.h || old.site != site || old.fitted != fitted || old.discs != discs;
}

const _glazeLight = Color(0xFFC98A5E);
const _glazeMid = Color(0xFF8A4B2A);
const _glazeDark = Color(0xFF5A2E18);
const _discLight = Color(0xFFF1F3F4);
const _discMid = Color(0xFFB9C1C7);
const _discDark = Color(0xFF7D868D);
const _biscuit = Color(0xFFF2EBDD);

/// A small upright pin insulator for the pole (centred on x = 0, the pin's
/// foot at y = 0, growing upward by [s].height).
void _upright(Canvas c, Size s) {
  final h = s.height;
  final w = s.width;
  c.drawRect(Rect.fromLTWH(-1, -3, 2, 3), Paint()..color = const Color(0xFF59626A));
  final body = Path()
    ..moveTo(-w * 0.5, -h * 0.25)
    ..lineTo(w * 0.5, -h * 0.25)
    ..lineTo(w * 0.24, -h * 0.55)
    ..lineTo(w * 0.42, -h * 0.6)
    ..lineTo(w * 0.2, -h * 0.85)
    ..lineTo(w * 0.24, -h)
    ..lineTo(-w * 0.24, -h)
    ..lineTo(-w * 0.2, -h * 0.85)
    ..lineTo(-w * 0.42, -h * 0.6)
    ..lineTo(-w * 0.24, -h * 0.55)
    ..close();
  c.drawPath(body, Paint()..color = _glazeMid);
  c.drawLine(Offset(-w * 0.2, -h * 0.9), Offset(w * 0.2, -h * 0.9), Paint()
    ..color = _glazeDark
    ..strokeWidth = 1);
}

/// How many stretches an insulator is looked over in.
const kM3InsulatorPickBins = 16;
int m3InsulatorPickBin(double u) => (u * kM3InsulatorPickBins).floor().clamp(0, kM3InsulatorPickBins - 1);

/// An insulator lying lengthwise (the pin's iron foot / the string's hook at
/// the left). A hairline crack shows only where the hand has been ([seen]:
/// stretches of [kM3InsulatorPickBins] across the width; null = all seen);
/// unseen stretches are washed with [veil] when it is set. A chipped shed
/// shows once the back has been looked at ([backSeen]).
class M3InsulatorPickItemPainter extends CustomPainter {
  M3InsulatorPickItemPainter({
    required this.kind,
    this.discs = 0,
    this.crack = false,
    this.chip = false,
    this.seen,
    this.backSeen = false,
    this.veil,
  });
  final M3InsulatorPickKind kind;
  final int discs;
  final bool crack;
  final bool chip;
  final Set<int>? seen;
  final bool backSeen;
  final Color? veil;

  /// Where the crack is, across the width.
  static double crackU(M3InsulatorPickKind k, int discs) => switch (k) {
        M3InsulatorPickKind.pin => 0.58,
        M3InsulatorPickKind.shackle => 0.46,
        M3InsulatorPickKind.disc => _discX(discs, (discs - 1) ~/ 2),
      };

  static double _discX(int n, int i) {
    if (n <= 1) return 0.5;
    return 0.3 + 0.4 * i / (n - 1);
  }

  static bool crackSeen(M3InsulatorPickKind k, int discs, Set<int>? seen) {
    if (seen == null) return true;
    final u = crackU(k, discs);
    for (var i = m3InsulatorPickBin(u - 0.04); i <= m3InsulatorPickBin(u + 0.04); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  @override
  void paint(Canvas c, Size s) {
    switch (kind) {
      case M3InsulatorPickKind.pin:
        _pin(c, s);
      case M3InsulatorPickKind.shackle:
        _shackle(c, s);
      case M3InsulatorPickKind.disc:
        _string(c, s);
    }
    if (crack && crackSeen(kind, discs, seen)) _crack(c, s);
    final v = veil;
    final sn = seen;
    if (v != null && sn != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.6);
      final bw = s.width / kM3InsulatorPickBins;
      for (var i = 0; i < kM3InsulatorPickBins; i++) {
        if (!sn.contains(i)) c.drawRect(Rect.fromLTWH(bw * i - 0.5, 0, bw + 1, s.height), wash);
      }
    }
  }

  Paint _glaze(Rect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_glazeLight, _glazeMid, _glazeDark],
      stops: [0.05, 0.55, 1],
    ).createShader(r);

  void _pin(Canvas c, Size s) {
    final h = s.height;
    final w = s.width;
    final cy = h / 2;
    // The iron pin (foot) at the left.
    c.drawRect(Rect.fromLTRB(w * 0.02, cy - h * 0.06, w * 0.26, cy + h * 0.06), Paint()..color = const Color(0xFF6E777F));
    c.drawRect(Rect.fromLTRB(w * 0.02, cy - h * 0.1, w * 0.07, cy + h * 0.1), Paint()..color = const Color(0xFF59626A));
    // The body: two sheds (petticoats) and the head with its groove.
    final r = Rect.fromLTRB(w * 0.24, h * 0.04, w * 0.98, h * 0.96);
    final body = Path()
      ..moveTo(w * 0.24, h * 0.04)
      ..lineTo(w * 0.3, h * 0.04)
      ..lineTo(w * 0.5, h * 0.24)
      ..lineTo(w * 0.54, h * 0.1)
      ..lineTo(w * 0.58, h * 0.1)
      ..lineTo(w * 0.74, h * 0.3)
      ..lineTo(w * 0.8, h * 0.3)
      ..lineTo(w * 0.86, h * 0.3)
      ..lineTo(w * 0.86, h * 0.38)
      ..lineTo(w * 0.98, h * 0.38)
      ..lineTo(w * 0.98, h * 0.62)
      ..lineTo(w * 0.86, h * 0.62)
      ..lineTo(w * 0.86, h * 0.7)
      ..lineTo(w * 0.74, h * 0.7)
      ..lineTo(w * 0.58, h * 0.9)
      ..lineTo(w * 0.54, h * 0.9)
      ..lineTo(w * 0.5, h * 0.76)
      ..lineTo(w * 0.3, h * 0.96)
      ..lineTo(w * 0.24, h * 0.96)
      ..close();
    c.drawPath(body, _glaze(r));
    // The groove at the head.
    c.drawRect(Rect.fromLTRB(w * 0.9, h * 0.38, w * 0.93, h * 0.62), Paint()..color = _glazeDark);
    // Highlight.
    c.drawLine(Offset(w * 0.33, h * 0.12), Offset(w * 0.48, h * 0.27), Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = math.max(1, h * 0.03)
      ..strokeCap = StrokeCap.round);
    if (chip && backSeen) _chipAt(c, Offset(w * 0.3, h * 0.96), h);
  }

  void _shackle(Canvas c, Size s) {
    final h = s.height;
    final w = s.width;
    // A spool (reel) on its side: two flanges and the waist with the bore.
    final r = Rect.fromLTRB(w * 0.14, h * 0.06, w * 0.86, h * 0.94);
    final body = Path()
      ..moveTo(w * 0.14, h * 0.06)
      ..lineTo(w * 0.3, h * 0.06)
      ..lineTo(w * 0.36, h * 0.24)
      ..lineTo(w * 0.64, h * 0.24)
      ..lineTo(w * 0.7, h * 0.06)
      ..lineTo(w * 0.86, h * 0.06)
      ..lineTo(w * 0.86, h * 0.94)
      ..lineTo(w * 0.7, h * 0.94)
      ..lineTo(w * 0.64, h * 0.76)
      ..lineTo(w * 0.36, h * 0.76)
      ..lineTo(w * 0.3, h * 0.94)
      ..lineTo(w * 0.14, h * 0.94)
      ..close();
    c.drawPath(body, _glaze(r));
    // The bore, seen end-on through the flange (a dark slot along the axis).
    c.drawRect(Rect.fromLTRB(w * 0.1, h * 0.45, w * 0.9, h * 0.55), Paint()..color = const Color(0x55200F06));
    c.drawLine(Offset(w * 0.18, h * 0.12), Offset(w * 0.27, h * 0.12), Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = math.max(1, h * 0.03)
      ..strokeCap = StrokeCap.round);
    if (chip && backSeen) _chipAt(c, Offset(w * 0.86, h * 0.94), h);
  }

  void _string(Canvas c, Size s) {
    final h = s.height;
    final w = s.width;
    final cy = h / 2;
    final n = math.max(1, discs);
    final steel = Paint()
      ..color = const Color(0xFF6E777F)
      ..strokeWidth = math.max(1.5, h * 0.06)
      ..strokeCap = StrokeCap.round;
    // Hook at the left, the discs' caps and pins in a chain, the clamp at the right.
    c.drawLine(Offset(w * 0.04, cy), Offset(w * 0.94, cy), steel);
    c.drawCircle(Offset(w * 0.05, cy), h * 0.08, Paint()
      ..color = const Color(0xFF59626A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, h * 0.04));
    c.drawRect(Rect.fromLTRB(w * 0.86, cy - h * 0.1, w * 0.96, cy + h * 0.1), Paint()..color = const Color(0xFF59626A));
    final dw = math.min(w * 0.4 / n + w * 0.03, w * 0.12);
    for (var i = 0; i < n; i++) {
      final cx = w * _discX(n, i);
      final disc = Rect.fromCenter(center: Offset(cx, cy), width: dw, height: h * 0.9);
      c.drawOval(
        disc,
        Paint()
          ..shader = const LinearGradient(
            colors: [_discDark, _discLight, _discMid],
            stops: [0, 0.4, 1],
          ).createShader(disc),
      );
      c.drawOval(disc, Paint()
        ..color = _discDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, h * 0.015));
      // The cap.
      c.drawRect(Rect.fromCenter(center: Offset(cx - dw * 0.55, cy), width: dw * 0.4, height: h * 0.2), Paint()..color = const Color(0xFF8B949B));
      if (chip && backSeen && i == n - 1) _chipAt(c, Offset(cx + dw * 0.1, disc.bottom - h * 0.02), h, biscuit: Colors.white);
    }
  }

  /// A wedge missing from a shed's edge: the unglazed body shows.
  void _chipAt(Canvas c, Offset at, double h, {Color biscuit = _biscuit}) {
    final r = h * 0.16;
    final p = Path()
      ..moveTo(at.dx - r, at.dy)
      ..lineTo(at.dx - r * 0.2, at.dy - r * 0.9)
      ..lineTo(at.dx + r * 0.5, at.dy - r * 0.5)
      ..lineTo(at.dx + r, at.dy)
      ..close();
    c.drawPath(p, Paint()..color = biscuit);
    c.drawPath(p, Paint()
      ..color = const Color(0xFF6B5A44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, h * 0.015));
  }

  void _crack(Canvas c, Size s) {
    final h = s.height;
    final cx = s.width * crackU(kind, discs);
    final p = Path()
      ..moveTo(cx - h * 0.02, h * 0.18)
      ..lineTo(cx + h * 0.05, h * 0.34)
      ..lineTo(cx - h * 0.03, h * 0.48)
      ..lineTo(cx + h * 0.06, h * 0.64)
      ..lineTo(cx, h * 0.8);
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF1E1A16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, h * 0.018)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(M3InsulatorPickItemPainter old) =>
      old.kind != kind ||
      old.discs != discs ||
      old.crack != crack ||
      old.chip != chip ||
      old.backSeen != backSeen ||
      old.veil != veil ||
      !_same(old.seen, seen);
}

bool _same(Set<int>? a, Set<int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a.length == b.length && a.containsAll(b);
}

/// The insulator seen end-on, from the back: its sheds' rims as rings, a
/// chipped rim where it is chipped. Before it is looked at, it is shaded.
class M3InsulatorPickBackPainter extends CustomPainter {
  const M3InsulatorPickBackPainter({required this.kind, required this.chip, required this.seen});
  final M3InsulatorPickKind kind;
  final bool chip;
  final bool seen;

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = s.shortestSide * 0.42;
    final disc = kind == M3InsulatorPickKind.disc;
    final rim = Paint()
      ..shader = RadialGradient(
        colors: disc ? const [_discLight, _discMid, _discDark] : const [_glazeLight, _glazeMid, _glazeDark],
        stops: const [0.2, 0.7, 1],
      ).createShader(Rect.fromCircle(center: o, radius: r));
    c.drawCircle(o, r, rim);
    c.drawCircle(o, r * 0.72, Paint()
      ..color = (disc ? _discDark : _glazeDark).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    c.drawCircle(o, r * (kind == M3InsulatorPickKind.shackle ? 0.24 : 0.3), Paint()..color = const Color(0xFF2A2F35));
    if (chip && seen) {
      final a = -0.7;
      final p = Path()
        ..moveTo(o.dx + r * math.cos(a - 0.32), o.dy + r * math.sin(a - 0.32))
        ..lineTo(o.dx + r * 0.7 * math.cos(a), o.dy + r * 0.7 * math.sin(a))
        ..lineTo(o.dx + r * math.cos(a + 0.36), o.dy + r * math.sin(a + 0.36))
        ..arcTo(Rect.fromCircle(center: o, radius: r + 2), a + 0.36, -0.68, false)
        ..close();
      c.drawPath(p, Paint()..color = disc ? Colors.white : _biscuit);
      c.drawPath(p, Paint()
        ..color = const Color(0xFF6B5A44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
    if (!seen) c.drawCircle(o, r + 1, Paint()..color = const Color(0x99263040));
  }

  @override
  bool shouldRepaint(M3InsulatorPickBackPainter old) => old.kind != kind || old.chip != chip || old.seen != seen;
}
