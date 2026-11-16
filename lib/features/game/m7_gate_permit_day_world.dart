import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn places of the Module 7 rank gate (m7_gate_permit_day.dart): one
// continuous world for one shutdown job, three spots side by side that the
// camera pans between — (A) the issuing counter of a 33/11 kV substation
// control room, (B) a para lane fed by a lane DTR whose AB switch is opened
// (all three blades seen, handle locked and tagged, HG fuses beside it) with
// the main-road line fed from a different DTR whose AB switch is closed, and
// (C) back at the counter in the late afternoon, its window on the lane at
// dusk. All in design pixels (360 wide, [M7GGeo.h] high). Nothing here names
// a breach: the same drawing is used for a lawful and an unlawful version
// wherever the difference is only a marking; only worker-read words are
// drawn (permit boxes, copy names, glove cuff, helmet print, the notice
// line, the agency truck's signboard, ID card fields).

/// What a drawn thing is.
enum M7GKind {
  none,
  person,
  idCard,
  copy,
  book,
  chit,
  logbook,
  glove,
  helmet,
  bag,
  gate,
  wall,
  door,
  curtain,
  conduit,
  meter,
  hook,
  tester,
  earth,
  paper,
  roof,
  clothes,
  pads,
  hose,
  drum,
  drain,
  bucket,
  truck,
  bin,
  ladder,
  tool,
  sheet,
  pole,
  tree,
  van,
  cart,
  dtrAb,
}

/// One thing on the stage: where, how it is drawn and what its close-up says.
@immutable
class M7GObj {
  const M7GObj({
    required this.id,
    required this.kind,
    required this.r,
    this.title = '',
    this.lines = const [],
    this.a = 0,
    this.col = const Color(0xFF8A6A4A),
    this.col2 = const Color(0xFFF2B632),
    this.txt = '',
    this.hit = true,
  });

  final String id;
  final M7GKind kind;

  /// The rect as fractions of the stage (0–1).
  final Rect r;

  /// The close-up's title and rows (raw markings only).
  final String title;
  final List<String> lines;

  /// Drawing variant (kind-specific flags / pose).
  final int a;
  final Color col;
  final Color col2;

  /// A worker-read word drawn on it (cuff, print, signboard, notice line).
  final String txt;

  /// Takes a tap (close-up / breach judgement).
  final bool hit;
}

/// Layout of the gate's scene (design px).
@immutable
class M7GGeo {
  const M7GGeo(this.h, this.inset);
  final double h;
  final double inset;

  /// The stage the props sit on (under the header and the crew's words, above
  /// the clipboard).
  Rect get stage => Rect.fromLTRB(0, 118, 360, math.max(300, h - inset - 128));

  /// The clipboard docked at the bottom edge: the one decision control.
  Rect get clip => Rect.fromLTWH(12, h - inset - 118, 336, 110);

  /// The crew's words (a bubble at the top of the stage).
  Rect get bubble => const Rect.fromLTWH(10, 70, 340, 44);

  Rect fr(Rect f) => Rect.fromLTWH(stage.left + f.left * stage.width, stage.top + f.top * stage.height, f.width * stage.width, f.height * stage.height);

  @override
  bool operator ==(Object other) => other is M7GGeo && other.h == h && other.inset == inset;
  @override
  int get hashCode => Object.hash(h, inset);
}

/// What the world draws now.
@immutable
class M7GView {
  const M7GView({
    required this.pan,
    required this.light,
    required this.props,
    required this.laneLeft,
    required this.crewCols,
    required this.key,
    this.fixed = false,
    this.propSpot = 0,
    this.vista = false,
  });

  /// The camera in spots (0 = A, 1 = B, 2 = C), animated while it pans.
  final double pan;

  /// Light per spot (0 – 2): a small tint change, dealt.
  final List<int> light;
  final List<M7GObj> props;
  final bool laneLeft;

  /// Each crew man's shirt colour (the morning line-up).
  final List<Color> crewCols;

  /// Changes whenever the props change (the painter repaints on it).
  final Object key;
  final bool fixed;

  /// The spot the props belong to.
  final int propSpot;

  /// The late counter's window is the whole lane at dusk (the line return).
  final bool vista;
}

const _ink = Color(0xFF1C2126);

class M7GWorldPainter extends CustomPainter {
  const M7GWorldPainter({required this.geo, required this.view});
  final M7GGeo geo;
  final M7GView view;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, 360, g.h));
    for (var s = 0; s < 3; s++) {
      final dx = (s - view.pan) * 360;
      if (dx <= -360 || dx >= 360) continue;
      c.save();
      c.translate(dx, 0);
      c.clipRect(Rect.fromLTWH(0, 0, 360, g.h));
      switch (s) {
        case 0:
          _counterSpot(c, late: false, light: view.light[0]);
        case 1:
          _laneSpot(c, light: view.light[1]);
        default:
          _counterSpot(c, late: true, light: view.light[2]);
      }
      // The props belong to the spot they were dealt for (the page keeps
      // the right ones in [M7GView.props]; they show once the camera is there).
      if (s == view.propSpot && (view.pan - s).abs() < 0.02) {
        for (final o in view.props) {
          _prop(c, o, g.fr(o.r));
        }
      }
      c.restore();
    }
    c.restore();
  }

  // --- helpers ---------------------------------------------------------------
  static final _tp = TextPainter(textDirection: TextDirection.ltr);

  static void _text(Canvas c, String t, Offset at, {double size = 8.5, Color color = _ink, double maxW = 120, FontWeight w = FontWeight.w800, TextAlign align = TextAlign.left}) {
    if (t.isEmpty) return;
    _tp
      ..text = TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: w, color: color, height: 1.15))
      ..textAlign = align
      ..maxLines = 2
      ..ellipsis = '…'
      ..layout(maxWidth: maxW);
    _tp.paint(c, at);
  }

  static void _textIn(Canvas c, String t, Rect r, {double size = 8.5, Color color = _ink}) {
    if (t.isEmpty) return;
    _tp
      ..text = TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.15))
      ..textAlign = TextAlign.center
      ..maxLines = 2
      ..ellipsis = '…'
      ..layout(maxWidth: r.width);
    _tp.paint(c, Offset(r.left, r.center.dy - _tp.height / 2));
  }

  static Paint _p(Color col, {double w = 0, bool stroke = false}) => Paint()
    ..color = col
    ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = w;

  static RRect _rr(Rect r, double rad) => RRect.fromRectAndRadius(r, Radius.circular(rad));

  Color _sky(int light, {bool dusk = false}) {
    if (dusk) return [const Color(0xFFE79B5C), const Color(0xFFD9825A), const Color(0xFFC96F4F)][light % 3];
    return [const Color(0xFF9CC7E8), const Color(0xFFA9D0E6), const Color(0xFF8FBBDD)][light % 3];
  }

  // --- the counter (A in the morning, C in the late afternoon) --------------------
  void _counterSpot(Canvas c, {required bool late, required int light}) {
    final g = geo;
    c.drawRect(Rect.fromLTWH(0, 0, 360, g.h), _p(late ? const Color(0xFFD8C9AE) : const Color(0xFFE5DAC3)));
    c.drawRect(Rect.fromLTWH(0, 0, 360, 20), _p(const Color(0xFF5C5348)));
    // The window.
    final big = late && view.vista;
    final win = big ? Rect.fromLTWH(10, g.stage.top - 24, 340, g.stage.height * 0.58) : Rect.fromLTWH(196, g.stage.top - 40, 152, g.stage.height * 0.40);
    c.drawRRect(_rr(win.inflate(5), 4), _p(const Color(0xFF5C5348)));
    c.drawRect(win, _p(_sky(light, dusk: late)));
    if (big) {
      c.drawRect(Rect.fromLTWH(win.left, win.bottom - win.height * 0.28, win.width, win.height * 0.28), _p(const Color(0xFF6B5A3E)));
      c.drawRect(Rect.fromLTWH(win.left + 120, win.bottom - win.height * 0.32, 70, 8), _p(const Color(0xFF8C8A84)));
      for (var i = 0; i < 6; i++) {
        c.drawRect(Rect.fromLTWH(win.left + i * 60.0, win.top + 30 - (i * 11 % 14), 44, 40), _p(const Color(0xFFB07A58)));
      }
    } else if (late) {
      // The lane at dusk: ground, the DTR plinth, a pole and a tree.
      c.drawRect(Rect.fromLTWH(win.left, win.bottom - 22, win.width, 22), _p(const Color(0xFF6B5A3E)));
      c.drawRect(Rect.fromLTWH(win.left + 52, win.bottom - 52, 22, 30), _p(const Color(0xFF6A7380)));
      c.drawRect(Rect.fromLTWH(win.left + 112, win.top + 10, 4, win.height - 30), _p(const Color(0xFF4A4036)));
      c.drawCircle(Offset(win.left + 24, win.bottom - 46), 16, _p(const Color(0xFF3F5B34)));
      c.drawRect(Rect.fromLTWH(win.left + 22, win.bottom - 32, 4, 12), _p(const Color(0xFF4A3A28)));
    } else {
      // The crew van and the line-up outside.
      c.drawRect(Rect.fromLTWH(win.left, win.bottom - 20, win.width, 20), _p(const Color(0xFF7C7A72)));
      c.drawRRect(_rr(Rect.fromLTWH(win.left + 82, win.bottom - 52, 60, 34), 4), _p(const Color(0xFFF2F2EE)));
      for (var i = 0; i < view.crewCols.length && i < 4; i++) {
        final x = win.left + 12 + i * 16.0;
        c.drawCircle(Offset(x, win.bottom - 40), 4, _p(const Color(0xFFF3D0A8)));
        c.drawRRect(_rr(Rect.fromLTWH(x - 4.5, win.bottom - 35, 9, 16), 2), _p(view.crewCols[i]));
      }
    }
    // The counter.
    final top = g.stage.top + g.stage.height * 0.50;
    c.drawRect(Rect.fromLTRB(0, top, 360, g.h), _p(const Color(0xFF8B6B4A)));
    c.drawRect(Rect.fromLTRB(0, top, 360, top + 8), _p(const Color(0xFFA98558)));
    // The store hatch (morning).
    if (!late) {
      final h = Rect.fromLTWH(10, g.stage.top - 40, 120, g.stage.height * 0.40);
      c.drawRRect(_rr(h.inflate(4), 4), _p(const Color(0xFF5C5348)));
      c.drawRect(h, _p(const Color(0xFF3B3732)));
      c.drawRect(Rect.fromLTWH(h.left + 6, h.top + 22, h.width - 12, 5), _p(const Color(0xFF6B635A)));
      c.drawRect(Rect.fromLTWH(h.left + 6, h.top + 52, h.width - 12, 5), _p(const Color(0xFF6B635A)));
    }
  }

  // --- the lane (B) ------------------------------------------------------------------
  void _laneSpot(Canvas c, {required int light}) {
    final g = geo;
    final ky = g.stage.height / 450;
    final gy = g.stage.top + g.stage.height * 0.40;
    c.drawRect(Rect.fromLTWH(0, 0, 360, gy), _p(_sky(light)));
    // Far roofs.
    for (var i = 0; i < 7; i++) {
      c.drawRect(Rect.fromLTWH(i * 56.0 - 8, gy - (38 + (i * 13 % 16)) * ky, 46, 60 * ky), _p(const Color(0xFFB6B0A3)));
    }
    c.drawRect(Rect.fromLTRB(0, gy, 360, g.h), _p(const Color(0xFF6E7A52)));
    c.drawRect(Rect.fromLTRB(0, gy + 6 * ky, 360, gy + 32 * ky), _p(const Color(0xFF9A8B6E)));
    final laneX = view.laneLeft ? 18.0 : 196.0;
    final mainX = view.laneLeft ? 196.0 : 18.0;
    _dtr(c, laneX, gy, ky, open: true);
    _dtr(c, mainX, gy, ky, open: false);
    // The two lines: the lane's span and the main-road line.
    final wire = _p(_ink, w: 1.5, stroke: true);
    for (final x in [laneX, mainX]) {
      c.drawLine(Offset(x + 40, gy - 96 * ky), Offset(x + 150, gy - 80 * ky), wire);
      c.drawLine(Offset(x + 150, gy - 80 * ky), Offset(x + 150, gy - 40 * ky), wire);
    }
  }

  /// A DTR on its plinth with its AB switch (three blades) and HG fuses.
  void _dtr(Canvas c, double x, double gy, double ky, {required bool open}) {
    c.drawRect(Rect.fromLTWH(x, gy - 30 * ky, 70, 12 * ky), _p(const Color(0xFF8C8A84)));
    final tank = Rect.fromLTWH(x + 6, gy - 74 * ky, 36, 46 * ky);
    c.drawRRect(_rr(tank, 4), _p(const Color(0xFF7C8A7A)));
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(tank.left - 4, tank.top + (6 + i * 10.0) * ky, 4, 6 * ky), _p(const Color(0xFF66745F)));
    }
    // The pole, the cross-arm and the AB switch (same size either way).
    c.drawRect(Rect.fromLTWH(x + 52, gy - 118 * ky, 6, 100 * ky), _p(const Color(0xFF6E6A63)));
    c.drawRect(Rect.fromLTWH(x + 34, gy - 112 * ky, 42, 4 * ky), _p(const Color(0xFF4F4A42)));
    final blade = _p(const Color(0xFFB9C0C7), w: 2.2, stroke: true);
    for (var i = 0; i < 3; i++) {
      final bx = x + 38 + i * 14.0;
      c.drawLine(Offset(bx, gy - 100 * ky), open ? Offset(bx + 3, gy - 112 * ky) : Offset(bx + 9, gy - 100 * ky), blade);
    }
    // HG fuses beside it.
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(x + 38 + i * 14.0, gy - 92 * ky, 4, 14 * ky), _p(const Color(0xFFCBD2D8)));
    }
    // The handle down the pole: locked and tagged only on the isolated one.
    c.drawLine(Offset(x + 58, gy - 98 * ky), Offset(x + 58, gy - 40 * ky), _p(const Color(0xFF8D949B), w: 1.2, stroke: true));
    c.drawRect(Rect.fromLTWH(x + 54, gy - 46 * ky, 10, 6 * ky), _p(const Color(0xFFB23A2E)));
    if (open) {
      c.drawCircle(Offset(x + 66, gy - 38 * ky), 3, _p(const Color(0xFF333333)));
      c.drawRect(Rect.fromLTWH(x + 62, gy - 36 * ky, 8, 10 * ky), _p(const Color(0xFFF2D24A)));
    }
  }

  // --- props ------------------------------------------------------------------------------
  void _prop(Canvas c, M7GObj o, Rect r) {
    switch (o.kind) {
      case M7GKind.none:
        break;
      case M7GKind.person:
        _person(c, r, o);
      case M7GKind.idCard:
        _idCard(c, r, o);
      case M7GKind.copy:
        _copy(c, r, o);
      case M7GKind.book:
        c.drawRRect(_rr(r, 3), _p(const Color(0xFF3F5E8C)));
        c.drawRect(Rect.fromLTWH(r.left + 5, r.top + 4, r.width - 10, r.height - 8), _p(const Color(0xFFF4F0E2)));
        for (var i = 0; i < 4; i++) {
          c.drawLine(Offset(r.left + 9, r.top + 10 + i * 8), Offset(r.right - 9, r.top + 10 + i * 8), _p(const Color(0x66000000), w: 0.8, stroke: true));
        }
      case M7GKind.chit:
        c.drawRect(r, _p(const Color(0xFFF1EBD2)));
        if (o.a == 1) {
          c.drawLine(Offset(r.left + 4, r.top + r.height * 0.35), Offset(r.right - 6, r.top + r.height * 0.35), _p(const Color(0xFF244A8A), w: 1.2, stroke: true));
          c.drawLine(Offset(r.left + 4, r.top + r.height * 0.6), Offset(r.right - 12, r.top + r.height * 0.6), _p(const Color(0xFF244A8A), w: 1.2, stroke: true));
        }
      case M7GKind.logbook:
        c.drawRRect(_rr(r, 3), _p(const Color(0xFF5A3A2A)));
        c.drawRect(Rect.fromLTWH(r.left + 6, r.top + 4, r.width - 12, r.height - 8), _p(const Color(0xFFF7F2E3)));
        for (var i = 0; i < 3; i++) {
          c.drawLine(Offset(r.left + 10, r.top + 12 + i * 9), Offset(r.right - 10, r.top + 12 + i * 9), _p(const Color(0x55000000), w: 0.8, stroke: true));
        }
        if (o.a == 1) {
          c.drawLine(Offset(r.left + 12, r.top + 21), Offset(r.right - 16, r.top + 21), _p(const Color(0xFF244A8A), w: 1.3, stroke: true));
        }
      case M7GKind.glove:
        for (var i = 0; i < 2; i++) {
          final gx = r.left + i * r.width * 0.5;
          final w = r.width * 0.44;
          c.drawRRect(_rr(Rect.fromLTWH(gx, r.top + r.height * 0.34, w, r.height * 0.62), 6), _p(const Color(0xFFE5701D)));
          c.drawRect(Rect.fromLTWH(gx + 2, r.top + r.height * 0.1, w - 4, r.height * 0.28), _p(const Color(0xFF2A2A2A)));
          if (o.a == 1 && i == 0) c.drawLine(Offset(gx + 4, r.top + r.height * 0.6), Offset(gx + w - 4, r.top + r.height * 0.78), _p(const Color(0xFF222222), w: 2, stroke: true));
        }
        _textIn(c, o.txt, Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.32), size: 6.5, color: const Color(0xFFFFFFFF));
      case M7GKind.helmet:
        c.drawArc(Rect.fromLTWH(r.left + 4, r.top + 4, r.width - 8, r.height * 1.5), math.pi, math.pi, true, _p(o.col));
        c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.7, r.width, 5), _p(o.col));
        _text(c, o.txt, Offset(r.left + 2, r.top + r.height * 0.3), size: 7.5, color: const Color(0xFF1C2126), maxW: r.width - 4, align: TextAlign.center);
      case M7GKind.bag:
        c.drawRRect(_rr(Rect.fromLTWH(r.left, r.top + r.height * 0.3, r.width, r.height * 0.7), 5), _p(const Color(0xFFB8E0F0)));
        c.drawArc(Rect.fromLTWH(r.left + 8, r.top, r.width - 16, r.height * 0.9), math.pi, math.pi, true, _p(const Color(0xFFD9D9D9)));
      case M7GKind.gate:
        c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.15, 8, r.height * 0.85), _p(const Color(0xFF8A8478)));
        c.drawRect(Rect.fromLTWH(r.right - 8, r.top + r.height * 0.15, 8, r.height * 0.85), _p(const Color(0xFF8A8478)));
        c.drawRect(Rect.fromLTRB(r.left + 8, r.top + r.height * 0.3, r.right - 8, r.bottom), _p(const Color(0xFF4F6B4A)));
        final nb = Rect.fromLTWH(r.left + 12, r.top, r.width - 24, r.height * 0.34);
        c.drawRect(nb, _p(const Color(0xFFFFFBEF)));
        c.drawRect(nb, _p(const Color(0xFF7A5C2E), w: 1, stroke: true));
        _textIn(c, o.txt, nb.deflate(2), size: 7.5);
      case M7GKind.wall:
        c.drawRect(r, _p(const Color(0xFFB4A58C)));
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 5), _p(const Color(0xFF8E8068)));
        if (o.a == 1) {
          c.drawRRect(_rr(Rect.fromLTWH(r.center.dx - 4, r.top - r.height * 0.55, 8, r.height * 0.7), 3), _p(const Color(0xFF2F4F7F)));
          c.drawRRect(_rr(Rect.fromLTWH(r.center.dx - 5, r.top - r.height * 0.62, 12, 6), 2), _p(const Color(0xFF3A2A1A)));
        }
      case M7GKind.door:
        c.drawRRect(_rr(r, 3), _p(const Color(0xFF6B4A32)));
        c.drawRect(Rect.fromLTWH(r.left + 5, r.top + 5, r.width - 10, r.height - 10), _p(const Color(0xFF86603F)));
        if (o.a == 1) {
          c.drawCircle(Offset(r.center.dx, r.center.dy), 5, _p(const Color(0xFFB0B0B0)));
        }
      case M7GKind.curtain:
        c.drawRect(r, _p(const Color(0xFF9A4A58)));
        for (var i = 1; i < 6; i++) {
          c.drawLine(Offset(r.left + i * r.width / 6, r.top), Offset(r.left + i * r.width / 6, r.bottom), _p(const Color(0x55000000), w: 1, stroke: true));
        }
      case M7GKind.conduit when o.a == 1:
        final w = Path()
          ..moveTo(r.left, r.center.dy)
          ..quadraticBezierTo(r.center.dx, r.center.dy + 8, r.right, r.center.dy);
        c.drawPath(w, _p(_ink, w: 1.6, stroke: true));
      case M7GKind.conduit:
        c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), _p(const Color(0xFF7A7A82), w: 5, stroke: true));
        c.drawLine(Offset(r.right, r.center.dy), Offset(r.right, r.top), _p(const Color(0xFF7A7A82), w: 5, stroke: true));
      case M7GKind.meter:
        c.drawRRect(_rr(r, 4), _p(const Color(0xFF5B5E63)));
        final face = Rect.fromLTWH(r.left + r.width * 0.2, r.top + r.height * 0.14, r.width * 0.6, r.height * 0.4);
        c.drawRRect(_rr(face, 3), _p(const Color(0xFFDAD6CC)));
        c.drawRect(Rect.fromLTWH(face.left + 4, face.top + 6, face.width - 8, 8), _p(const Color(0xFF2E3B2E)));
        // Two seals; a cut one hangs open, a magnet sits on the face.
        for (var i = 0; i < 2; i++) {
          final sx = r.left + r.width * (0.3 + i * 0.4);
          c.drawCircle(Offset(sx, r.top + r.height * 0.78), 5, _p(const Color(0xFFB23A2E)));
          if (o.a & 1 == 1 && i == 1) c.drawLine(Offset(sx - 6, r.top + r.height * 0.78), Offset(sx + 6, r.top + r.height * 0.9), _p(const Color(0xFF111111), w: 1.4, stroke: true));
        }
        if (o.a & 2 == 2) c.drawRect(Rect.fromLTWH(face.right - 12, face.bottom - 12, 12, 10), _p(const Color(0xFF222222)));
      case M7GKind.hook:
        // A bare copper wire thrown over the line and hanging down.
        final top = Offset(r.left, r.top);
        c.drawLine(top, Offset(r.right, r.top + r.height * 0.1), _p(const Color(0xFF3A3A3A), w: 2, stroke: true));
        c.drawLine(Offset(r.center.dx, r.top + 3), Offset(r.center.dx + 8, r.bottom), _p(const Color(0xFFC77A2E), w: 2.4, stroke: true));
        c.drawCircle(Offset(r.center.dx, r.top + 3), 3.2, _p(const Color(0xFFC77A2E)));
      case M7GKind.tester:
        c.drawRRect(_rr(r, 4), _p(const Color(0xFFE8B620)));
        final d = Rect.fromLTWH(r.left + 4, r.top + 4, r.width - 8, r.height * 0.5);
        c.drawRect(d, _p(const Color(0xFF223322)));
        _textIn(c, o.txt, d, size: 8, color: const Color(0xFF9CFF9C));
      case M7GKind.earth:
        c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom - 4), _p(const Color(0xFF3FA34D), w: o.a == 1 ? 0.0 : 2.2, stroke: true));
        c.drawRect(Rect.fromLTWH(r.center.dx - 7, r.bottom - 8, 14, 6), _p(const Color(0xFF8A7A66)));
        if (o.a != 1) c.drawRect(Rect.fromLTWH(r.center.dx - 5, r.top, 10, 6), _p(const Color(0xFF3FA34D)));
      case M7GKind.paper:
        c.drawRect(r, _p(const Color(0xFFFFFBEF)));
        c.drawRect(r, _p(const Color(0xFFB08A4A), w: 0.8, stroke: true));
        c.drawLine(Offset(r.left + 3, r.top + 6), Offset(r.right - 3, r.top + 6), _p(const Color(0x66000000), w: 0.8, stroke: true));
      case M7GKind.roof:
        c.drawRect(r, _p(const Color(0xFFB4A58C)));
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 6), _p(const Color(0xFF8E8068)));
        // Masons at work.
        for (var i = 0; i < 2; i++) {
          final x = r.left + r.width * (0.25 + i * 0.4);
          c.drawCircle(Offset(x, r.top - 10), 4, _p(const Color(0xFFF3D0A8)));
          c.drawRRect(_rr(Rect.fromLTWH(x - 5, r.top - 6, 10, 16), 2), _p(const Color(0xFF8A9A6A)));
        }
      case M7GKind.clothes:
        c.drawLine(Offset(r.left, r.top + 4), Offset(r.right, r.top + 4), _p(const Color(0xFF555555), w: 1.2, stroke: true));
        for (var i = 0; i < 3; i++) {
          c.drawRect(Rect.fromLTWH(r.left + 8 + i * r.width * 0.3, r.top + 4, r.width * 0.2, r.height * 0.7), _p(const [Color(0xFF9A3A3A), Color(0xFF3A6A9A), Color(0xFFD8C060)][i]));
        }
      case M7GKind.pads:
        if (o.a == 1) {
          c.drawOval(r, _p(const Color(0xFF3D3A35)));
        } else {
          c.drawOval(r, _p(const Color(0xFF3D3A35)));
          for (var i = 0; i < 3; i++) {
            c.drawRect(Rect.fromLTWH(r.left + 8 + i * r.width * 0.28, r.center.dy - 6, r.width * 0.24, 10), _p(const Color(0xFF2E5E8E)));
          }
          c.drawArc(r.deflate(2), 0, math.pi * 2, false, _p(const Color(0xFFF2D24A), w: 3, stroke: true));
        }
      case M7GKind.hose:
        final mir = o.a == 1;
        final path = Path()
          ..moveTo(mir ? r.right : r.left, r.top)
          ..quadraticBezierTo(r.center.dx, r.bottom, mir ? r.left : r.right, r.center.dy);
        c.drawPath(path, _p(const Color(0xFF2A2A2A), w: 3.4, stroke: true));
      case M7GKind.drum when o.a == 2:
        c.drawRRect(_rr(r, 5), _p(const Color(0xFF7C8A7A)));
        for (var i = 0; i < 5; i++) {
          c.drawRect(Rect.fromLTWH(r.left - 4, r.top + 8 + i * (r.height - 16) / 5, 4, (r.height - 16) / 7), _p(const Color(0xFF66745F)));
        }
        c.drawRect(Rect.fromLTWH(r.center.dx - 3, r.bottom, 6, 6), _p(const Color(0xFF3A3A3A)));
      case M7GKind.drum:
        c.drawRRect(_rr(r, 5), _p(const Color(0xFF3F6BA8)));
        c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.3, r.width, 3), _p(const Color(0xFF2E4F7E)));
        c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.65, r.width, 3), _p(const Color(0xFF2E4F7E)));
        if (o.a == 1) c.drawOval(Rect.fromLTWH(r.left + 6, r.top - 3, r.width - 12, 8), _p(const Color(0xFF2A2A2A)));
      case M7GKind.drain:
        c.drawRect(r, _p(const Color(0xFF30343A)));
        for (var i = 1; i < 5; i++) {
          c.drawLine(Offset(r.left + i * r.width / 5, r.top + 2), Offset(r.left + i * r.width / 5, r.bottom - 2), _p(const Color(0xFF696F77), w: 2, stroke: true));
        }
      case M7GKind.bucket:
        final b = Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right - 6, r.bottom)
          ..lineTo(r.left + 6, r.bottom)
          ..close();
        c.drawPath(b, _p(const Color(0xFFCB4B3A)));
        c.drawOval(Rect.fromLTWH(r.left, r.top - 4, r.width, 8), _p(const Color(0xFF2A2A2A)));
      case M7GKind.truck:
        c.drawRRect(_rr(Rect.fromLTWH(r.left, r.top + r.height * 0.2, r.width * 0.72, r.height * 0.6), 4), _p(o.col));
        c.drawRRect(_rr(Rect.fromLTWH(r.left + r.width * 0.72, r.top + r.height * 0.36, r.width * 0.28, r.height * 0.44), 4), _p(const Color(0xFF3A4A5A)));
        c.drawCircle(Offset(r.left + r.width * 0.2, r.bottom - 6), 6, _p(const Color(0xFF222222)));
        c.drawCircle(Offset(r.left + r.width * 0.78, r.bottom - 6), 6, _p(const Color(0xFF222222)));
        _textIn(c, o.txt, Rect.fromLTWH(r.left + 3, r.top + r.height * 0.22, r.width * 0.68, r.height * 0.5), size: 7, color: const Color(0xFFFFFFFF));
      case M7GKind.bin:
        c.drawRRect(_rr(r, 4), _p(o.col));
        c.drawRect(Rect.fromLTWH(r.left - 2, r.top - 3, r.width + 4, 6), _p(o.col2));
      case M7GKind.ladder:
        c.drawLine(Offset(r.left + 6, r.bottom), Offset(r.center.dx, r.top), _p(const Color(0xFFB8864A), w: 2.4, stroke: true));
        c.drawLine(Offset(r.right - 6, r.bottom), Offset(r.center.dx + 8, r.top), _p(const Color(0xFFB8864A), w: 2.4, stroke: true));
        for (var i = 1; i < 6; i++) {
          final y = r.top + i * r.height / 6;
          final t = i / 6;
          c.drawLine(Offset(r.center.dx - (r.center.dx - r.left - 6) * t, y), Offset(r.center.dx + 8 + (r.right - 6 - r.center.dx - 8) * t, y), _p(const Color(0xFFB8864A), w: 1.6, stroke: true));
        }
      case M7GKind.tool:
        c.drawLine(Offset(r.left, r.bottom - 4), Offset(r.right, r.top + 4), _p(const Color(0xFF8E959C), w: 4, stroke: true));
        c.drawCircle(Offset(r.right, r.top + 4), 5, _p(const Color(0xFF8E959C), w: 2, stroke: true));
      case M7GKind.sheet:
        c.drawRect(r, _p(const Color(0xFFFFFBEF)));
        c.drawRect(r, _p(const Color(0xFFB08A4A), w: 1, stroke: true));
        for (var i = 0; i < 3; i++) {
          c.drawLine(Offset(r.left + 6, r.top + 10 + i * 9), Offset(r.right - 6, r.top + 10 + i * 9), _p(const Color(0x55000000), w: 0.8, stroke: true));
        }
        final box = Rect.fromLTWH(r.left + 6, r.bottom - 22, r.width - 12, 16);
        c.drawRect(box, _p(const Color(0xFF7A5C2E), w: 0.9, stroke: true));
        if (o.a == 1) c.drawLine(Offset(box.left + 4, box.bottom - 3), Offset(box.right - 6, box.top + 4), _p(const Color(0xFF244A8A), w: 1.4, stroke: true));
        _text(c, o.txt, Offset(r.left + 6, r.top + 2), size: 6.5, maxW: r.width - 8);
      case M7GKind.pole:
        c.drawRect(Rect.fromLTWH(r.center.dx - 3, r.top, 6, r.height), _p(const Color(0xFF6E6A63)));
        c.drawRect(Rect.fromLTWH(r.center.dx - 16, r.top + 4, 32, 4), _p(const Color(0xFF4F4A42)));
      case M7GKind.tree:
        c.drawRect(Rect.fromLTWH(r.center.dx - 3, r.center.dy, 6, r.height * 0.5), _p(const Color(0xFF4A3A28)));
        c.drawCircle(Offset(r.center.dx, r.top + r.height * 0.34), r.width * 0.42, _p(const Color(0xFF3F5B34)));
        c.drawCircle(Offset(r.center.dx - r.width * 0.24, r.top + r.height * 0.5), r.width * 0.28, _p(const Color(0xFF4A6A3A)));
      case M7GKind.van:
        c.drawRRect(_rr(Rect.fromLTWH(r.left, r.top + r.height * 0.2, r.width, r.height * 0.6), 5), _p(const Color(0xFFF2F2EE)));
        c.drawRect(Rect.fromLTWH(r.left + r.width * 0.62, r.top + r.height * 0.3, r.width * 0.3, r.height * 0.22), _p(const Color(0xFF6A8AA8)));
        c.drawCircle(Offset(r.left + r.width * 0.22, r.bottom - 4), 5, _p(const Color(0xFF222222)));
        c.drawCircle(Offset(r.left + r.width * 0.78, r.bottom - 4), 5, _p(const Color(0xFF222222)));
      case M7GKind.cart:
        c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.3, r.width, r.height * 0.35), _p(const Color(0xFF8A6A3A)));
        c.drawCircle(Offset(r.left + r.width * 0.25, r.bottom - 6), 7, _p(const Color(0xFF222222)));
        c.drawCircle(Offset(r.left + r.width * 0.75, r.bottom - 6), 7, _p(const Color(0xFF222222)));
      case M7GKind.dtrAb:
        break;
    }
  }

  /// A man: poses 0 stand · 1 arm up · 2 bandaged hand · 3 leaning away ·
  /// 4 on a pole (up) · 5 pushing aside. `a & 8`: card on the lanyard.
  void _person(Canvas c, Rect r, M7GObj o) {
    final pose = o.a & 7;
    final cx = r.center.dx;
    if (pose == 4) c.drawRect(Rect.fromLTWH(cx - 3, r.top - 6, 6, r.height + 6), _p(const Color(0xFF6E6A63)));
    final headR = math.min(r.width, r.height) * 0.17;
    final lean = pose == 3 ? 5.0 : 0.0;
    c.drawRRect(_rr(Rect.fromLTWH(cx - r.width * 0.2 + lean, r.top + headR * 2.2, r.width * 0.4, r.height * 0.5), 4), _p(o.col));
    // Legs.
    c.drawRect(Rect.fromLTWH(cx - r.width * 0.16 + lean, r.top + headR * 2.2 + r.height * 0.5, r.width * 0.12, r.height * 0.25), _p(const Color(0xFF3A4660)));
    c.drawRect(Rect.fromLTWH(cx + r.width * 0.04 + lean, r.top + headR * 2.2 + r.height * 0.5, r.width * 0.12, r.height * 0.25), _p(const Color(0xFF3A4660)));
    c.drawCircle(Offset(cx + lean, r.top + headR * 1.4), headR, _p(const Color(0xFFF3D0A8)));
    c.drawArc(Rect.fromCircle(center: Offset(cx + lean, r.top + headR * 1.3), radius: headR * 1.15), math.pi, math.pi, true, _p(o.col2));
    final arm = _p(o.col, w: 4, stroke: true);
    if (pose == 1) {
      c.drawLine(Offset(cx + r.width * 0.2, r.top + headR * 2.6), Offset(cx + r.width * 0.42, r.top + headR * 0.6), arm);
    } else if (pose == 5) {
      c.drawLine(Offset(cx + r.width * 0.2, r.top + headR * 2.6), Offset(cx + r.width * 0.46, r.top + headR * 3.2), arm);
    } else {
      c.drawLine(Offset(cx + r.width * 0.2, r.top + headR * 2.6), Offset(cx + r.width * 0.3, r.top + headR * 5), arm);
    }
    if (pose == 2) c.drawCircle(Offset(cx + r.width * 0.3, r.top + headR * 5.1), 4.5, _p(const Color(0xFFFFFFFF)));
    if (o.a & 8 == 8) c.drawRect(Rect.fromLTWH(cx - 4, r.top + headR * 2.9, 8, 9), _p(const Color(0xFFFFFFFF)));
    if (o.txt.isNotEmpty) {
      // A worker's words: a small bubble beside him.
      final bw = math.min(r.width * 1.5, 92.0);
      final b = Rect.fromLTWH(cx + r.width * 0.3, r.top - 10, bw, 20);
      c.drawRRect(_rr(b, 6), _p(const Color(0xFFFFFFFF)));
      _textIn(c, o.txt, b.deflate(2), size: 8);
    }
  }

  void _idCard(Canvas c, Rect r, M7GObj o) {
    c.drawRRect(_rr(r, 3), _p(const Color(0xFFFFFFFF)));
    c.drawRRect(_rr(r, 3), _p(const Color(0xFF8A8A8A), w: 0.8, stroke: true));
    c.drawRect(Rect.fromLTWH(r.left + 3, r.top + 3, r.width * 0.34, r.height * 0.34), _p(const Color(0xFFBBBBBB)));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(r.left + 3, r.top + r.height * (0.52 + i * 0.14)), Offset(r.right - 3, r.top + r.height * (0.52 + i * 0.14)), _p(const Color(0xFF999999), w: 1, stroke: true));
    }
    c.drawLine(Offset(r.center.dx, r.top - 8), Offset(r.center.dx, r.top), _p(const Color(0xFF444444), w: 1, stroke: true));
  }

  /// A PTW copy: its name, the number, the boxes (a signature scribble or
  /// blank). `a & 1`: the issuer's box signed · `a & 2`: the receiver's box
  /// signed · `a & 4`: a blank sheet (no paper filled).
  void _copy(Canvas c, Rect r, M7GObj o) {
    c.drawRect(r, _p(const Color(0xFFFFFBEF)));
    c.drawRect(r, _p(const Color(0xFFB08A4A), w: 1, stroke: true));
    if (o.a & 4 == 4) return;
    _text(c, o.title, Offset(r.left + 4, r.top + 2), size: 7, maxW: r.width - 8);
    _text(c, o.txt, Offset(r.left + 4, r.top + 14), size: 7.5, maxW: r.width - 8);
    final bw = (r.width - 12) / 2;
    for (var i = 0; i < 2; i++) {
      final b = Rect.fromLTWH(r.left + 4 + i * (bw + 4), r.bottom - 26, bw, 20);
      c.drawRect(b, _p(const Color(0xFF7A5C2E), w: 0.9, stroke: true));
      final signed = i == 0 ? o.a & 1 == 1 : o.a & 2 == 2;
      if (signed) {
        final path = Path()
          ..moveTo(b.left + 4, b.bottom - 5)
          ..quadraticBezierTo(b.left + bw * 0.3, b.top + 2, b.left + bw * 0.5, b.bottom - 6)
          ..quadraticBezierTo(b.left + bw * 0.7, b.top + 3, b.right - 4, b.bottom - 8);
        c.drawPath(path, _p(const Color(0xFF244A8A), w: 1.3, stroke: true));
      }
    }
  }

  @override
  bool shouldRepaint(M7GWorldPainter old) => old.geo != geo || old.view.pan != view.pan || old.view.key != view.key || old.view.fixed != view.fixed;
}

/// A deadly move plays out in colour over the frozen scene (0 → 1).
class M7GHarmPainter extends CustomPainter {
  const M7GHarmPainter({required this.at, required this.k});
  final Offset at;
  final double k;

  @override
  void paint(Canvas c, Size size) {
    if (k <= 0) return;
    final r = 18 + 140 * Curves.easeOut.transform(k.clamp(0.0, 1.0));
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: (1 - k) * 0.95),
          const Color(0xFFFFE066).withValues(alpha: (1 - k) * 0.8),
          const Color(0x00FF8A00),
        ]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: (1 - k).clamp(0.0, 1.0))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(at.dx, at.dy - 60);
    for (var i = 1; i <= 5; i++) {
      path.lineTo(at.dx + (i.isOdd ? 12 : -12), at.dy - 60 + i * 12);
    }
    c.drawPath(path, bolt);
  }

  @override
  bool shouldRepaint(M7GHarmPainter old) => old.k != k || old.at != at;
}
