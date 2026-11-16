import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 7.8 কাজ 2 "ঠিক হাতে বর্জ্য" (m7_waste_handover.dart):
// the section depot's yard at its gate, seen from the side with a little
// depth. A trolley holds the week's waste as plain pictures (no label, no
// colour code), a padded lamp box and a red and a green bin stand in a row
// above it, and vehicles pull in at the gate one at a time with only the
// signboard a worker reads. Nothing glows, points or is ticked: the boards
// on the vehicles are the only text.
//
// Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's height; a
// tall phone gets more yard above the trolley, never a stretched picture.

/// What lies on the trolley (lesson 7.8 points 1–3 and pro tip 2).
enum M7Waste { oilDrum, battery, board, tube, cfl, vapour, rags, pads, cups, paper }

/// The five kinds of waste.
enum M7Kind { oil, elec, lamp, oily, general }

extension M7WasteInfo on M7Waste {
  M7Kind get kind => switch (this) {
        M7Waste.oilDrum => M7Kind.oil,
        M7Waste.battery || M7Waste.board => M7Kind.elec,
        M7Waste.tube || M7Waste.cfl || M7Waste.vapour => M7Kind.lamp,
        M7Waste.rags || M7Waste.pads => M7Kind.oily,
        M7Waste.cups || M7Waste.paper => M7Kind.general,
      };
}

/// The vehicles that pull in at the gate.
enum M7Vehicle { recycler, collection, disposal, municipal, unmarked }

/// The signboards (a worker's own words; the unmarked van has none).
abstract final class M7HandSigns {
  static const recycler = 'অনুমোদিত রিসাইক্লিং এজেন্সি';
  static const collection = 'কোম্পানির সংগ্রহ কেন্দ্র';
  static const disposal = 'অনুমোদিত ডিসপোজাল এজেন্সি';
  static const municipal = 'পৌরসভা';

  static String? of(M7Vehicle v) => switch (v) {
        M7Vehicle.recycler => recycler,
        M7Vehicle.collection => collection,
        M7Vehicle.disposal => disposal,
        M7Vehicle.municipal => municipal,
        M7Vehicle.unmarked => null,
      };
}

/// Where things are (design px, 360 wide).
@immutable
class M7HandGeo {
  const M7HandGeo._(this.height, this.bottom, this.trolleyTop);

  factory M7HandGeo.forScene(double height, double inset) {
    final bottom = height - inset * 0.5;
    return M7HandGeo._(height, bottom, math.max(404.0, bottom - 196));
  }

  final double height;

  /// The lowest line controls may use (over the system inset).
  final double bottom;

  /// The top of the trolley.
  final double trolleyTop;

  /// How much taller than the smallest scene (the gate road drops by half).
  double get extra => trolleyTop - 404;

  /// The gate road: the vehicle stands here (its bed is the drop place).
  Rect get bay => Rect.fromLTWH(20, 112 + extra * 0.5, 320, 150);

  /// The open bed (a drop on it hands the piece to the vehicle).
  Rect get bed => Rect.fromLTWH(bay.left + 6, bay.top + 22, 212, 96);

  /// The "যান" tab under the cab.
  Rect get yan => Rect.fromLTWH(bay.right - 100, bay.bottom + 2, 96, 44);

  /// The row of the lamp box and the two bins.
  double get rowTop => trolleyTop - 104;
  Rect get lampBox => Rect.fromLTWH(14, rowTop, 100, 92);
  Rect get redBin => Rect.fromLTWH(124, rowTop, 96, 92);
  Rect get greenBin => Rect.fromLTWH(232, rowTop, 100, 92);

  /// The trolley (left of the guide's corner).
  Rect get trolley => Rect.fromLTWH(8, trolleyTop, 232, 176);

  static const int slots = 12;
  static const double cellW = 54, cellH = 52;

  /// Cell [i] of the trolley deck (4 columns × 3 rows).
  Rect slot(int i) => Rect.fromLTWH(trolley.left + 12 + (i % 4) * (cellW + 1), trolley.top + 10 + (i ~/ 4) * (cellH + 6), cellW, cellH);

  /// Piece [i] of [n] loaded on the bed.
  Rect bedItem(int i) => Rect.fromLTWH(bay.left + 14 + (i % 5) * 38.0, bay.top + 56 + (i ~/ 5) * 30.0, 36, 32);

  /// A drop this near a thing counts as on it.
  static const double reach = 8;

  /// Which thing a release at [p] lands on.
  M7Place placeAt(Offset p, {required bool bedOpen}) {
    if (bedOpen && bed.inflate(reach).contains(p)) return M7Place.bed;
    if (lampBox.inflate(reach).contains(p)) return M7Place.lampBox;
    if (redBin.inflate(reach).contains(p)) return M7Place.redBin;
    if (greenBin.inflate(reach).contains(p)) return M7Place.greenBin;
    if (trolley.inflate(reach).contains(p)) return M7Place.trolley;
    return M7Place.none;
  }

  @override
  bool operator ==(Object other) => other is M7HandGeo && other.height == height && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(height, bottom);
}

/// Where a release lands.
enum M7Place { none, trolley, lampBox, redBin, greenBin, bed }

// ============================================================================
// The yard
// ============================================================================

class M7HandYardPainter extends CustomPainter {
  const M7HandYardPainter({required this.geo});
  final M7HandGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    final bay = geo.bay;
    // Sky and the far wall under the header.
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, bay.top + 40),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA7CBE6), Color(0xFFD6E6EE)])
            .createShader(Rect.fromLTWH(0, 0, 360, bay.top + 40)),
    );
    // The depot wall with its gate posts.
    final wallTop = bay.top - 34;
    c.drawRect(Rect.fromLTWH(0, wallTop, 360, 60), Paint()..color = const Color(0xFFB9AE9A));
    c.drawRect(Rect.fromLTWH(0, wallTop, 360, 6), Paint()..color = const Color(0xFF8E846F));
    final brick = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = wallTop + 14; y < wallTop + 58; y += 12) {
      c.drawLine(Offset(0, y), Offset(360, y), brick);
    }
    for (final x in [6.0, 340.0]) {
      c.drawRect(Rect.fromLTWH(x, wallTop - 14, 14, 74), Paint()..color = const Color(0xFF8A8070));
      c.drawRect(Rect.fromLTWH(x - 2, wallTop - 18, 18, 6), Paint()..color = const Color(0xFF6F6657));
    }
    // A pole and a far tree.
    c.drawRect(Rect.fromLTWH(300, wallTop - 70, 4, 76), Paint()..color = const Color(0xFF6B5B45));
    c.drawLine(Offset(286, wallTop - 62), Offset(318, wallTop - 62), Paint()..color = const Color(0xFF6B5B45)..strokeWidth = 3);
    c.drawCircle(Offset(60, wallTop - 14), 26, Paint()..color = const Color(0xFF6E9A52));
    c.drawCircle(Offset(84, wallTop - 4), 20, Paint()..color = const Color(0xFF7BA85E));
    // The gate road: asphalt with a dashed edge.
    final road = Rect.fromLTWH(0, wallTop + 56, 360, bay.bottom - (wallTop + 56) + 8);
    c.drawRect(road, Paint()..color = const Color(0xFF7B7A76));
    c.drawRect(Rect.fromLTWH(0, road.top, 360, 4), Paint()..color = const Color(0xFF5E5D59));
    final dash = Paint()
      ..color = const Color(0xCCF3EBD3)
      ..strokeWidth = 2;
    for (var x = 4.0; x < 360; x += 26) {
      c.drawLine(Offset(x, road.bottom - 8), Offset(x + 12, road.bottom - 8), dash);
    }
    // The yard ground down to the bottom: gravel with patches.
    final yard = Rect.fromLTWH(0, road.bottom, 360, h - road.bottom);
    c.drawRect(
      yard,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB5AA92), Color(0xFF9D927B)]).createShader(yard),
    );
    final patch = Paint()..color = const Color(0x22FFFFFF);
    final rnd = math.Random(11);
    for (var i = 0; i < 26; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(rnd.nextDouble() * 360, yard.top + 8 + rnd.nextDouble() * (yard.height - 16)), width: 16, height: 5), patch);
    }
    // A painted standing line under the three containers.
    final row = geo.rowTop + 92;
    c.drawRect(Rect.fromLTWH(8, row + 2, 344, 3), Paint()..color = const Color(0x33FFFFFF));
  }

  @override
  bool shouldRepaint(M7HandYardPainter old) => old.geo != geo;
}

// ============================================================================
// The trolley, the containers and the waste
// ============================================================================

class M7HandTrolleyPainter extends CustomPainter {
  const M7HandTrolleyPainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    // The handle, the deck and its low rail, the wheels.
    final steel = Paint()
      ..color = const Color(0xFF55616B)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(w - 4, h - 28), Offset(w - 4, 8), steel);
    final deck = Rect.fromLTWH(0, 0, w - 10, h - 24);
    c.drawRRect(
      RRect.fromRectAndRadius(deck, const Radius.circular(8)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9D3C4), Color(0xFFBDB6A4)]).createShader(deck),
    );
    c.drawRRect(
        RRect.fromRectAndRadius(deck, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFF6C675A));
    c.drawRect(Rect.fromLTWH(0, h - 30, w - 10, 6), Paint()..color = const Color(0xFF6C675A));
    for (final x in [28.0, w - 46]) {
      c.drawCircle(Offset(x, h - 10), 11, Paint()..color = const Color(0xFF2B2F33));
      c.drawCircle(Offset(x, h - 10), 4.5, Paint()..color = const Color(0xFF9AA3AB));
    }
  }

  @override
  bool shouldRepaint(M7HandTrolleyPainter old) => false;
}

/// One waste as a plain picture (design box 56 × 52).
class M7WastePainter extends CustomPainter {
  const M7WastePainter(this.waste, {this.cracked = false});
  final M7Waste waste;
  final bool cracked;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 56, size.height / 52);
    switch (waste) {
      case M7Waste.oilDrum:
        _drum(c);
      case M7Waste.battery:
        _battery(c);
      case M7Waste.board:
        _board(c);
      case M7Waste.tube:
        _tube(c);
      case M7Waste.cfl:
        _cfl(c);
      case M7Waste.vapour:
        _vapour(c);
      case M7Waste.rags:
        _rags(c);
      case M7Waste.pads:
        _pads(c);
      case M7Waste.cups:
        _cups(c);
      case M7Waste.paper:
        _paper(c);
    }
    c.restore();
  }

  void _shadow(Canvas c, double cx, double w) => c.drawOval(Rect.fromCenter(center: Offset(cx, 48.5), width: w, height: 5), Paint()..color = const Color(0x33000000));

  void _drum(Canvas c) {
    _shadow(c, 28, 32);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 8, 28, 38), const Radius.circular(4));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF2F4A5E), Color(0xFF5C7F99), Color(0xFF2B4254)]).createShader(const Rect.fromLTWH(14, 8, 28, 38)));
    final rib = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 1.6;
    for (final y in [16.0, 27.0, 38.0]) {
      c.drawLine(Offset(14, y), Offset(42, y), rib);
    }
    c.drawOval(const Rect.fromLTWH(14, 5, 28, 8), Paint()..color = const Color(0xFF6E92AD));
    c.drawOval(const Rect.fromLTWH(14, 5, 28, 8), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF22384A));
    c.drawCircle(const Offset(34, 9), 2.2, Paint()..color = const Color(0xFF22384A));
    c.drawCircle(const Offset(22, 9), 1.6, Paint()..color = const Color(0xFF22384A));
  }

  void _battery(Canvas c) {
    _shadow(c, 28, 40);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 16, 40, 30), const Radius.circular(3)), Paint()..color = const Color(0xFF3D4852));
    c.drawRect(const Rect.fromLTWH(8, 16, 40, 7), Paint()..color = const Color(0xFF56626D));
    c.drawRect(const Rect.fromLTWH(14, 10, 8, 7), Paint()..color = const Color(0xFFD7332A));
    c.drawRect(const Rect.fromLTWH(34, 10, 8, 7), Paint()..color = const Color(0xFF1B1F23));
    final line = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.4;
    for (final x in [18.0, 28.0, 38.0]) {
      c.drawLine(Offset(x, 26), Offset(x, 44), line);
    }
    // Acid weeping from a corner.
    c.drawOval(const Rect.fromLTWH(40, 40, 8, 5), Paint()..color = const Color(0xAAC8D23A));
  }

  void _board(Canvas c) {
    _shadow(c, 28, 44);
    final r = RRect.fromRectAndRadius(const Rect.fromLTWH(5, 10, 46, 34), const Radius.circular(3));
    c.drawRRect(r, Paint()..color = const Color(0xFF2E7D4F));
    c.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF1B5133));
    final trace = Paint()
      ..color = const Color(0xFFE2C46A)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(9, 40)
          ..lineTo(9, 30)
          ..lineTo(20, 30)
          ..moveTo(47, 14)
          ..lineTo(36, 14)
          ..lineTo(36, 22)
          ..moveTo(10, 15)
          ..lineTo(22, 15),
        trace);
    c.drawRect(const Rect.fromLTWH(22, 22, 14, 10), Paint()..color = const Color(0xFF1E2226));
    c.drawRect(const Rect.fromLTWH(10, 20, 8, 5), Paint()..color = const Color(0xFF1E2226));
    c.drawCircle(const Offset(40, 36), 3.6, Paint()..color = const Color(0xFF3A2A1E));
    c.drawLine(const Offset(5, 44), const Offset(51, 44), Paint()..color = const Color(0x33000000));
  }

  void _tube(Canvas c) {
    _shadow(c, 28, 44);
    c.save();
    c.translate(28, 28);
    c.rotate(-0.42);
    final r = RRect.fromRectAndRadius(const Rect.fromLTRB(-25, -4, 25, 4), const Radius.circular(4));
    c.drawRRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFCBD3D8)]).createShader(const Rect.fromLTRB(-25, -4, 25, 4)));
    c.drawRect(const Rect.fromLTRB(-27, -4.5, -23, 4.5), Paint()..color = const Color(0xFF7C858C));
    c.drawRect(const Rect.fromLTRB(23, -4.5, 27, 4.5), Paint()..color = const Color(0xFF7C858C));
    c.restore();
  }

  void _cfl(Canvas c) {
    _shadow(c, 28, 24);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 37, 16, 10), const Radius.circular(2)), Paint()..color = const Color(0xFF9BA3AA));
    c.drawRect(const Rect.fromLTWH(22, 46, 12, 3), Paint()..color = const Color(0xFF6F777E));
    final coil = Paint()
      ..color = const Color(0xFFF3F1E6)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final edge = Paint()
      ..color = const Color(0xFFB9B7A8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final y = 33.0 - i * 7;
      c.drawArc(Rect.fromLTWH(18, y - 4, 20, 8), 0, math.pi, false, coil);
      c.drawArc(Rect.fromLTWH(18, y - 4, 20, 8), math.pi, math.pi, false, edge);
    }
  }

  void _vapour(Canvas c) {
    _shadow(c, 28, 30);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 34, 12, 13), const Radius.circular(2)), Paint()..color = const Color(0xFF8E959B));
    final ring = Paint()
      ..color = const Color(0xFF5C6368)
      ..strokeWidth = 1.2;
    for (final y in [38.0, 42.0]) {
      c.drawLine(Offset(22, y), Offset(34, y), ring);
    }
    c.drawOval(const Rect.fromLTWH(12, 4, 32, 34), Paint()..shader = const RadialGradient(colors: [Color(0xFFFFFBE0), Color(0xFFD9D5B0)]).createShader(const Rect.fromLTWH(12, 4, 32, 34)));
    c.drawOval(const Rect.fromLTWH(12, 4, 32, 34), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF9C987A));
    c.drawOval(const Rect.fromLTWH(21, 14, 14, 12), Paint()..color = const Color(0x33FFFFFF));
  }

  void _rags(Canvas c) {
    _shadow(c, 28, 40);
    final p = Path()
      ..moveTo(8, 40)
      ..quadraticBezierTo(4, 28, 14, 22)
      ..quadraticBezierTo(14, 10, 26, 12)
      ..quadraticBezierTo(34, 6, 40, 16)
      ..quadraticBezierTo(52, 18, 48, 32)
      ..quadraticBezierTo(52, 42, 38, 44)
      ..quadraticBezierTo(24, 48, 8, 40)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFF7B6A4C));
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF4B3F2C));
    final stain = Paint()..color = const Color(0xCC1E1812);
    c.drawOval(const Rect.fromLTWH(16, 26, 14, 9), stain);
    c.drawOval(const Rect.fromLTWH(32, 20, 9, 7), stain);
    final fold = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(18, 18)
          ..quadraticBezierTo(26, 24, 24, 36)
          ..moveTo(38, 30)
          ..quadraticBezierTo(32, 36, 36, 42),
        fold);
  }

  void _pads(Canvas c) {
    _shadow(c, 28, 44);
    for (final (dx, dy, a) in [(4.0, 8.0, -0.12), (10.0, 18.0, 0.1)]) {
      c.save();
      c.translate(28 + dx - 6, 28 + dy - 6);
      c.rotate(a);
      const r = Rect.fromLTWH(-20, -9, 40, 22);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF8D9296));
      c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFF55595C));
      c.drawOval(const Rect.fromLTWH(-8, -3, 18, 10), Paint()..color = const Color(0xCC1E1812));
      c.restore();
    }
  }

  void _cups(Canvas c) {
    _shadow(c, 28, 40);
    void cup(double x, double y, double a) {
      c.save();
      c.translate(x, y);
      c.rotate(a);
      final p = Path()
        ..moveTo(-9, -12)
        ..lineTo(9, -12)
        ..lineTo(6, 12)
        ..lineTo(-6, 12)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFFF7F3EA));
      c.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = const Color(0xFF8A6A3C));
      c.drawRect(const Rect.fromLTRB(-8, -6, 8, -1), Paint()..color = const Color(0xFFD9573A));
      c.restore();
    }

    cup(20, 32, -0.2);
    cup(36, 30, 0.9);
  }

  void _paper(Canvas c) {
    _shadow(c, 28, 38);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF8A8576);
    final p1 = Path()
      ..moveTo(8, 36)
      ..lineTo(14, 14)
      ..lineTo(32, 10)
      ..lineTo(38, 30)
      ..lineTo(24, 42)
      ..close();
    final p2 = Path()
      ..moveTo(26, 40)
      ..lineTo(30, 20)
      ..lineTo(46, 22)
      ..lineTo(48, 40)
      ..lineTo(38, 46)
      ..close();
    c.drawPath(p1, Paint()..color = const Color(0xFFFAF8F0));
    c.drawPath(p1, line);
    c.drawPath(p2, Paint()..color = const Color(0xFFEEEBDF));
    c.drawPath(p2, line);
    c.drawLine(const Offset(14, 14), const Offset(24, 42), line);
    c.drawLine(const Offset(30, 20), const Offset(38, 46), line);
  }

  @override
  bool shouldRepaint(M7WastePainter old) => old.waste != waste || old.cracked != cracked;
}

/// What a container is.
enum M7BoxKind { lampBox, redBin, greenBin }

/// The padded lamp box and the two bins (design box 100 × 92).
class M7BoxPainter extends CustomPainter {
  const M7BoxPainter(this.kind, {this.fill = 0});
  final M7BoxKind kind;

  /// How many pieces lie inside (a little of them shows over the rim).
  final int fill;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 92);
    switch (kind) {
      case M7BoxKind.lampBox:
        _lampBox(c);
      case M7BoxKind.redBin:
        _bin(c, const Color(0xFFC62F2A), const Color(0xFF8E1F1B), const Color(0xFFE35A52));
      case M7BoxKind.greenBin:
        _bin(c, const Color(0xFF2E8B4A), const Color(0xFF1E6133), const Color(0xFF52B06C));
    }
    c.restore();
  }

  void _lampBox(Canvas c) {
    c.drawOval(const Rect.fromLTWH(8, 80, 84, 9), Paint()..color = const Color(0x33000000));
    // The inside: foam, with the tips of lamps standing in it.
    const body = Rect.fromLTWH(10, 28, 80, 56);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFFC59D5F));
    c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF8A6A3C));
    c.drawRect(const Rect.fromLTWH(14, 30, 72, 12), Paint()..color = const Color(0xFFF1E9D2));
    final cut = Paint()..color = const Color(0xFFD9CFB3);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18 + i * 17.0, 33, 12, 6), const Radius.circular(3)), cut);
    }
    for (var i = 0; i < math.min(fill, 3); i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20 + i * 22.0, 14, 9, 24), const Radius.circular(4)), Paint()..color = const Color(0xFFF5F2E4));
      c.drawRect(Rect.fromLTWH(20 + i * 22.0, 34, 9, 4), Paint()..color = const Color(0xFF8E959B));
    }
    // Padding on the front: a quilted band.
    c.drawRect(const Rect.fromLTWH(12, 50, 76, 14), Paint()..color = const Color(0x55F1E9D2));
    final stitch = Paint()
      ..color = const Color(0x558A6A3C)
      ..strokeWidth = 1;
    for (var x = 24.0; x < 88; x += 16) {
      c.drawLine(Offset(x, 50), Offset(x, 64), stitch);
    }
  }

  void _bin(Canvas c, Color a, Color b, Color lid) {
    c.drawOval(const Rect.fromLTWH(10, 80, 80, 9), Paint()..color = const Color(0x33000000));
    final body = Path()
      ..moveTo(16, 24)
      ..lineTo(84, 24)
      ..lineTo(78, 82)
      ..lineTo(22, 82)
      ..close();
    c.drawPath(body, Paint()..shader = LinearGradient(colors: [b, a, b]).createShader(const Rect.fromLTWH(16, 24, 68, 58)));
    final rib = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.6;
    for (final x in [38.0, 50.0, 62.0]) {
      c.drawLine(Offset(x, 30), Offset(x - 1, 78), rib);
    }
    if (fill > 0) {
      c.drawOval(const Rect.fromLTWH(26, 12, 22, 14), Paint()..color = const Color(0xFFEEE7D4));
      c.drawOval(const Rect.fromLTWH(46, 9, 24, 16), Paint()..color = const Color(0xFF7B6A4C));
    }
    // The lid, a little open.
    c.save();
    c.translate(84, 24);
    c.rotate(-0.12);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-72, -8, 76, 10), const Radius.circular(3)), Paint()..color = lid);
    c.restore();
    c.drawCircle(const Offset(26, 80), 5, Paint()..color = const Color(0xFF2B2F33));
    c.drawCircle(const Offset(74, 80), 5, Paint()..color = const Color(0xFF2B2F33));
  }

  @override
  bool shouldRepaint(M7BoxPainter old) => old.kind != kind || old.fill != fill;
}

// ============================================================================
// The vehicles
// ============================================================================

/// A vehicle standing at the gate (design box 320 × 150; the "যান" tab is a
/// separate widget). The three authorised vehicles are the same grey open
/// truck with a different board; the municipal truck is the green garbage
/// truck; the unmarked van is a plain white panel van with no board.
class M7VehiclePainter extends CustomPainter {
  const M7VehiclePainter(this.vehicle);
  final M7Vehicle vehicle;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 320, size.height / 150);
    // Shadow and wheels.
    c.drawOval(const Rect.fromLTWH(14, 128, 296, 14), Paint()..color = const Color(0x44000000));
    switch (vehicle) {
      case M7Vehicle.unmarked:
        _van(c);
      case M7Vehicle.municipal:
        _garbage(c);
      case M7Vehicle.recycler || M7Vehicle.collection || M7Vehicle.disposal:
        _openTruck(c);
    }
    for (final x in [56.0, 150.0, 262.0]) {
      c.drawCircle(Offset(x, 124), 14, Paint()..color = const Color(0xFF22262A));
      c.drawCircle(Offset(x, 124), 6, Paint()..color = const Color(0xFF9AA3AB));
    }
    c.restore();
  }

  void _cab(Canvas c, Color body) {
    final cab = Path()
      ..moveTo(222, 118)
      ..lineTo(222, 52)
      ..lineTo(262, 52)
      ..lineTo(292, 80)
      ..lineTo(314, 84)
      ..lineTo(314, 118)
      ..close();
    c.drawPath(cab, Paint()..color = body);
    c.drawPath(
        cab,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x66000000));
    c.drawPath(
        Path()
          ..moveTo(230, 58)
          ..lineTo(260, 58)
          ..lineTo(282, 80)
          ..lineTo(230, 80)
          ..close(),
        Paint()..color = const Color(0xFF9FD3EE));
    // The driver, waiting.
    c.drawCircle(const Offset(244, 70), 6, Paint()..color = const Color(0xFFC98E62));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(237, 75, 14, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF3E6AA8));
    c.drawRect(const Rect.fromLTWH(308, 104, 8, 6), Paint()..color = const Color(0xFFF6E27A));
    c.drawRect(const Rect.fromLTWH(222, 112, 94, 6), Paint()..color = const Color(0xFF3B4147));
  }

  /// The signboard over the bed.
  void _board(Canvas c, String text, Rect r, {Color bg = const Color(0xFFF7F1DE), Color ink = const Color(0xFF2A2018)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: ink, height: 1.1)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: r.width - 10);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 2)), const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = bg);
    c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x99000000));
    tp.paint(c, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
    // Two short posts onto the bed.
    final post = Paint()..color = const Color(0xFF5E6770);
    c.drawRect(Rect.fromLTWH(r.left + 14, r.bottom, 4, 8), post);
    c.drawRect(Rect.fromLTWH(r.right - 18, r.bottom, 4, 8), post);
  }

  void _openTruck(Canvas c) {
    // The open bed: three sides and a floor, seen from the side.
    const bed = Rect.fromLTWH(6, 44, 212, 76);
    c.drawRRect(RRect.fromRectAndRadius(bed, const Radius.circular(4)), Paint()..color = const Color(0xFF59636C));
    c.drawRect(const Rect.fromLTWH(12, 50, 200, 64), Paint()..color = const Color(0xFF2E353B));
    c.drawRect(const Rect.fromLTWH(6, 44, 212, 8), Paint()..color = const Color(0xFF7A858F));
    c.drawRect(const Rect.fromLTWH(6, 112, 212, 8), Paint()..color = const Color(0xFF3B4248));
    // The front of the bed (near side) hides the floor's lower part.
    c.drawRect(const Rect.fromLTWH(6, 98, 212, 22), Paint()..color = const Color(0xFF6B7680));
    c.drawRect(const Rect.fromLTWH(6, 98, 212, 3), Paint()..color = const Color(0xFF8995A0));
    _cab(c, const Color(0xFF8C98A3));
    final sign = M7HandSigns.of(vehicle)!;
    _board(c, sign, const Rect.fromLTWH(10, 8, 204, 28));
  }

  void _garbage(Canvas c) {
    const body = Rect.fromLTWH(6, 34, 212, 86);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(10)), Paint()..color = const Color(0xFF3D8C55));
    c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF21573A));
    // The open hopper at the top (the bed).
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 44, 200, 60), const Radius.circular(6)), Paint()..color = const Color(0xFF26352B));
    c.drawRect(const Rect.fromLTWH(6, 98, 212, 22), Paint()..color = const Color(0xFF47A062));
    c.drawRect(const Rect.fromLTWH(6, 98, 212, 3), Paint()..color = const Color(0xFF6BBE84));
    final rib = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.6;
    for (final x in [40.0, 80.0, 120.0, 160.0, 196.0]) {
      c.drawLine(Offset(x, 102), Offset(x, 118), rib);
    }
    _cab(c, const Color(0xFF3D8C55));
    _board(c, M7HandSigns.municipal, const Rect.fromLTWH(54, 4, 112, 26), bg: const Color(0xFFFFFFFF), ink: const Color(0xFF1E5A36));
  }

  void _van(Canvas c) {
    // A closed white panel van: nothing on it to read, and nothing to see inside.
    const body = Rect.fromLTWH(6, 46, 212, 74);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(8)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFAFAF7), Color(0xFFD7D9D8)]).createShader(body));
    c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x66000000));
    c.drawLine(const Offset(150, 52), const Offset(150, 116), Paint()..color = const Color(0x44000000));
    c.drawRect(const Rect.fromLTWH(140, 82, 6, 3), Paint()..color = const Color(0xFF6F777E));
    _cab(c, const Color(0xFFEDEEEC));
  }

  @override
  bool shouldRepaint(M7VehiclePainter old) => old.vehicle != vehicle;
}
