// Lesson 5.3 (সাধারণ ফল্ট), কাজ 2 "পোড়া জোড়, নরম তার": the rules (a bare
// end: tester → earth; earth first = slip; climbing with an end bare =
// deadly; each spot: spanner off the clamp, bend, tape and cut beyond the soft
// length or only the connector on sound metal; a cut in soft metal = a dark
// face slip; a jumper cut too far / a sound conductor cut = slips; the
// connector alone on soft or melted metal = slip; listening = slip), the deal,
// the libraries (a myth pool per round), the four spot kinds drawn as
// themselves (the jumper's U, the long sleeve, two snapped pieces with no
// clamp), and the level in the shell: the guide first, a full clean
// play with a reason after every round and the coworker refused at the jumper
// spot, the next control waiting for him on a fast play, a slip card that
// keeps the round, three slips, the deadly freeze, and the gesture hand.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_anneal_cut.dart';
import 'package:slm_flutter/features/game/m5_anneal_cut_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '5.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5AnnealPacks['do_5_3_b']!;

/// The new art may not be bundled yet: tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M5AnnealGeo get _geo => M5AnnealGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _scr(Offset design) => design * _k;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(_scr(design));
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {M5AnnealProbe? probe}) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5AnnealPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

/// The section, right: a bare end tested then earthed; climb; the reason.
Future<void> _site(WidgetTester t, M5AnnealDeal d) async {
  if (d.bare) {
    final left = d.bareLeft;
    await _tool(t, M5AnnealLines.tester);
    await _tapAt(t, _geo.endHit(left).center);
    expect(find.text('R ${M5AnnealLines.dead}'), findsOneWidget);
    await _tool(t, M5AnnealLines.earth);
    await _tapAt(t, _geo.endHit(left).center);
  }
  await _tool(t, M5AnnealLines.climb);
  await _pump(t, 1000);
  await _reason(t, M5AnnealLines.siteWhy(d.bare));
}

/// The drawn conductor line at [u] on spot [s] (design px).
double _lineY(M5AnnealSpot s, double u) => _geo.lineY(s.kind, s.jumperRight, u);

/// The spanner once and a quarter round the old clamp's nut.
Future<void> _unbolt(WidgetTester t) async {
  final n = _geo.nut;
  const r = 36.0;
  final g = await t.startGesture(_scr(n + const Offset(r, 0)));
  for (var i = 1; i <= 48; i++) {
    final a = i * 2 * math.pi * 1.25 / 48;
    await g.moveTo(_scr(n + Offset(r * math.cos(a), r * math.sin(a))));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

Future<void> _bendAt(WidgetTester t, M5AnnealSpot s, double u) async {
  await t.longPressAt(_scr(Offset(_geo.xOf(u), _lineY(s, u))));
  await _pump(t, 800);
}

Future<void> _dragTape(WidgetTester t, M5AnnealSpot s, double u) async {
  final from = _scr(_geo.tray.center);
  final to = _scr(Offset(_geo.xOf(u), _lineY(s, u)));
  await t.dragFrom(from, to - from);
  await _pump(t, 300);
}

Future<void> _cutAt(WidgetTester t, M5AnnealSpot s, double u) async {
  final x = _geo.xOf(u);
  await t.dragFrom(_scr(Offset(x, _lineY(s, u) - 44)), const Offset(0, 88) * _k);
  await _pump(t, 400);
}

Future<void> _refuseCoworker(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M5AnnealLines.coworker.right);
  await _pump(t, 2600);
}

/// A spot played right (the coworker refused at the jumper); the reason.
Future<void> _spot(WidgetTester t, M5AnnealSpot s, {required bool coworker}) async {
  // A snapped conductor has no clamp: its round starts with the pieces apart.
  if (s.kind != M5AnnealKind.snapped) await _unbolt(t);
  if (coworker) await _refuseCoworker(t);
  await _bendAt(t, s, 0.15);
  if (!s.soft) {
    await t.tap(find.byKey(const ValueKey('anneal-connector-only')));
    await _pump(t, 1000);
  } else {
    for (final u in [if (s.softLeft) s.lo - 0.05, if (s.softRight) s.hi + 0.05]) {
      await _dragTape(t, s, u);
      await _cutAt(t, s, u);
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: '$s cut at $u');
    }
    await _pump(t, 1000);
  }
  await _reason(t, M5AnnealLines.spotWhy(s));
}

int _seedWhere(bool Function(M5AnnealDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5AnnealDeal(math.Random(s))));

/// A run on the bench at the spot of [kind].
M5AnnealRun _atSpot(M5AnnealSpot s) {
  final r = M5AnnealRun(M5AnnealDeal(spots: [s, s, s]))..climb();
  return r..next();
}

void main() {
  group('rules', () {
    test('deals: jumper always + two of the others; at least one cut and one no-cut spot; earth states, light, order and lengths vary', () {
      final seen = <String>{};
      final earths = <String>{};
      final lights = <M5AnnealLight>{};
      final jumperAt = <int>{};
      for (var s = 0; s < 120; s++) {
        final d = m5AnnealDeal(math.Random(s));
        expect(d.spots, hasLength(3));
        expect(d.spots.where((x) => x.kind == M5AnnealKind.jumper), hasLength(1));
        expect(d.spots.map((x) => x.kind).toSet(), hasLength(3), reason: 'three different spots');
        expect(d.spots.any((x) => x.soft), isTrue, reason: 'a cut somewhere');
        expect(d.spots.any((x) => !x.soft), isTrue, reason: 'a connector-only somewhere');
        expect(d.bareLeft && d.bareRight, isFalse);
        for (final x in d.spots) {
          if (x.kind == M5AnnealKind.connector) expect(x.soft, isFalse);
          if (x.kind == M5AnnealKind.sleeve || x.kind == M5AnnealKind.snapped) {
            expect(x.softLeft && x.softRight, isTrue, reason: '$x');
          }
          if (x.kind == M5AnnealKind.jumper && x.soft) {
            expect(x.softLeft != x.softRight, isTrue, reason: 'one side: $x');
            expect(x.jumperRight, x.softRight);
          }
          if (x.soft) {
            // A good cut fits between the soft end and the spare, inside the gloves.
            expect(x.lo - m5AnnealSpare, greaterThan(m5AnnealMinU - 0.01), reason: '$x');
            expect(x.hi + m5AnnealSpare, lessThan(m5AnnealMaxU + 0.08), reason: '$x');
          }
        }
        earths.add('${d.bareLeft}${d.bareRight}');
        lights.add(d.light);
        jumperAt.add(d.jumperAt);
        seen.add('${d.spots.map((x) => '${x.kind.name}${x.soft}').join(',')}|${d.bareLeft}${d.bareRight}|${d.light.name}');
      }
      expect(earths, hasLength(3), reason: 'both on, pole 7 bare, pole 9 bare');
      expect(lights, M5AnnealLight.values.toSet());
      expect(jumperAt, {0, 1, 2});
      expect(seen.length, greaterThan(30));
    });

    test('কাজের জায়গা: earth before the tester is a slip (no earth goes on); tester then earth; climbing with an end bare is deadly', () {
      const deal = M5AnnealDeal(spots: [M5AnnealSpot(kind: M5AnnealKind.connector)], bareLeft: true);
      final a = M5AnnealRun(deal);
      expect(a.earthR, isTrue);
      expect(a.earth(true), M5AnnealMistakes.testFirst);
      expect(a.earthL, isFalse);
      expect(a.test(false), isNull, reason: 'the other end is no proof here');
      expect(a.earth(true), M5AnnealMistakes.testFirst);
      expect(a.test(true), isNull);
      expect(a.earth(true), isNull);
      expect(a.earthL, isTrue);
      expect(a.slips, 2);
      expect(a.climb(), isNull);
      expect(a.roundDone, isTrue);
      expect(a.caught, contains(M5AnnealLines.caughtEarth));
      expect(a.caught, isNot(contains(M5AnnealLines.caughtTest)), reason: 'not thorough');
      final b = M5AnnealRun(deal);
      final m = b.climb();
      expect(m, M5AnnealMistakes.noEarth);
      expect(m!.deadly, isTrue);
      expect(b.ended, isTrue);
      final c = M5AnnealRun(deal)..test(true);
      expect(c.climb(), M5AnnealMistakes.noEarth, reason: 'tested but not earthed');
      final both = M5AnnealRun(const M5AnnealDeal(spots: [M5AnnealSpot(kind: M5AnnealKind.connector)]));
      expect(both.climb(), isNull, reason: 'both ends already earthed');
      expect(both.earth(true), isNull);
    });

    test('a spot: nothing before the clamp is off; bends: soft stays kinked, sound springs back', () {
      const s = M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.30, hi: 0.70);
      final r = _atSpot(s);
      expect(r.spot, s);
      expect(r.bend(0.4), isNull);
      expect(r.placeTape(0.2), isFalse);
      expect(r.connectorOnly(), isNull);
      r.unbolt();
      expect(r.bend(0.4), isTrue);
      expect(r.bend(0.15), isFalse);
      expect(r.bend(0.5), isNull, reason: 'the gap: no metal');
      expect(r.kinks, [0.4]);
      expect(r.slips, 0);
    });

    test('an annealed sleeve: tape and cut beyond both soft ends finishes; a cut in soft metal is a dark-face slip (re-cut further out)', () {
      const s = M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.30, hi: 0.70);
      final r = _atSpot(s)..unbolt();
      expect(r.placeTape(0.35), isTrue);
      expect(r.placeTape(0.80), isTrue);
      expect(r.placeTape(0.20), isFalse, reason: 'two tapes only');
      expect(r.cut(0), M5AnnealMistakes.softFace);
      expect(r.endL, closeTo(0.35, 1e-9));
      expect(r.darkL, isTrue);
      expect(r.onMetal(0.4), isFalse, reason: 'cut away');
      expect(r.cut(0), isNull, reason: 'the right side at 0.80');
      expect(r.roundDone, isFalse);
      expect(r.placeTape(0.25), isTrue);
      expect(r.cut(0), isNull);
      expect(r.darkL, isFalse);
      expect(r.roundDone, isTrue);
      expect(r.fitted, isTrue);
      expect(r.slips, 1);
      expect(r.caught, isNot(contains(M5AnnealLines.caughtCut)));
    });

    test('connector only: right on sound metal; a slip on soft metal and on melted ends', () {
      final sound = _atSpot(const M5AnnealSpot(kind: M5AnnealKind.connector))..unbolt();
      expect(sound.connectorOnly(), isNull);
      expect(sound.roundDone, isTrue);
      expect(sound.caught, contains(M5AnnealLines.caughtSound));
      final soft = _atSpot(const M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.3, hi: 0.7))..unbolt();
      expect(soft.connectorOnly(), M5AnnealMistakes.connectorOnly);
      expect(soft.roundDone, isFalse);
      final snapped = _atSpot(const M5AnnealSpot(kind: M5AnnealKind.snapped, lo: 0.38, hi: 0.62))..unbolt();
      expect(snapped.connectorOnly(), M5AnnealMistakes.beadJoint);
      final jumper = _atSpot(const M5AnnealSpot(kind: M5AnnealKind.jumper, lo: 0.5, hi: 0.70))..unbolt();
      expect(jumper.connectorOnly(), M5AnnealMistakes.connectorOnly);
    });

    test('a soft jumper: one cut on its side; too far = too short for a U (stopped); the line side and sound metal are not cut', () {
      const s = M5AnnealSpot(kind: M5AnnealKind.jumper, lo: 0.5, hi: 0.70);
      final r = _atSpot(s)..unbolt();
      r.placeTape(0.30);
      expect(r.cut(0), M5AnnealMistakes.needless, reason: 'the line side is sound');
      expect(r.endL, m5AnnealGapLo, reason: 'the cutter was stopped');
      r.placeTape(0.90);
      expect(r.cut(0), M5AnnealMistakes.shortJumper);
      expect(r.endR, m5AnnealGapHi);
      r.placeTape(0.76);
      expect(r.cut(0), isNull);
      expect(r.roundDone, isTrue);
      expect(r.slips, 2);
      final sound = _atSpot(const M5AnnealSpot(kind: M5AnnealKind.connector))..unbolt();
      sound.placeTape(0.7);
      expect(sound.cut(0), M5AnnealMistakes.needless);
      expect(sound.roundDone, isFalse);
      final clean = _atSpot(s)..unbolt();
      clean.placeTape(0.75);
      expect(clean.cut(0), isNull);
      expect(clean.caught, contains(M5AnnealLines.caughtU));
    });

    test('a span cut far beyond the soft end wastes good metal (a slip); listening is a slip; next() clears the bench', () {
      const snapped = M5AnnealSpot(kind: M5AnnealKind.snapped, lo: 0.38, hi: 0.62);
      final r = M5AnnealRun(const M5AnnealDeal(spots: [snapped, M5AnnealSpot(kind: M5AnnealKind.connector), snapped]))
        ..climb()
        ..next();
      expect(r.clampOff, isTrue, reason: 'a snapped conductor has no clamp to take off');
      r.placeTape(0.10);
      expect(r.cut(0), M5AnnealMistakes.needless);
      expect(r.listened(), M5AnnealMistakes.listen);
      expect(r.slips, 2);
      r.placeTape(0.30);
      r.bend(0.45);
      r.next();
      expect(r.clampOff, isFalse);
      expect(r.tapes, isEmpty);
      expect(r.kinks, isEmpty);
      expect(r.roundSlips, 0);
      expect(r.endL, m5AnnealGapLo);
      r.next();
      expect(r.spot!.kind, M5AnnealKind.snapped);
      expect(r.clampOff, isTrue, reason: 'snapped again: pieces apart from the start');
    });

    test('a cut takes the kinks of the length it removes with it (no splay left floating in the gap)', () {
      const s = M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.30, hi: 0.70);
      final r = _atSpot(s)..unbolt();
      expect(r.bend(0.40), isTrue);
      expect(r.bend(0.34), isTrue);
      expect(r.bend(0.62), isTrue);
      expect(r.kinks, hasLength(3));
      r.placeTape(0.37);
      expect(r.cut(0), M5AnnealMistakes.softFace);
      expect(r.kinks, unorderedEquals([0.34, 0.62]), reason: 'the kink at 0.40 went with the cut-away length');
      r.placeTape(0.25);
      expect(r.cut(0), isNull);
      r.placeTape(0.78);
      expect(r.cut(0), isNull);
      expect(r.fitted, isTrue);
      expect(r.kinks, isEmpty);
    });

    test('the bench line: the jumper hangs in a U on its side only; a snapped end droops; a sleeve and a connector lie straight', () {
      for (final right in [true, false]) {
        double dy(double u) => m5AnnealRestDy(M5AnnealKind.jumper, right, u);
        final jumperSide = right ? [0.6, 0.75, 0.9] : [0.4, 0.25, 0.1];
        final lineSide = right ? [0.1, 0.3, 0.45] : [0.55, 0.7, 0.9];
        for (final u in jumperSide) {
          expect(dy(u), greaterThan(8), reason: 'U at $u (right $right)');
        }
        for (final u in lineSide) {
          expect(dy(u), 0, reason: 'line side at $u (right $right)');
        }
        expect(dy(right ? 0.745 : 0.255), closeTo(m5AnnealUDepth, 1.5), reason: 'the bottom of the U');
        expect(dy(right ? m5AnnealGapHi : m5AnnealGapLo), 0, reason: 'level at the clamp');
        expect(dy(right ? 0.97 : 0.03), 0, reason: 'back up at the glove');
      }
      expect(m5AnnealRestDy(M5AnnealKind.snapped, true, m5AnnealGapLo), closeTo(m5AnnealSnapDroop, 1e-9));
      expect(m5AnnealRestDy(M5AnnealKind.snapped, true, m5AnnealGapHi), closeTo(m5AnnealSnapDroop, 1e-9));
      expect(m5AnnealRestDy(M5AnnealKind.snapped, true, 0.2), 0);
      for (final u in [0.1, 0.3, 0.7, 0.9]) {
        expect(m5AnnealRestDy(M5AnnealKind.sleeve, true, u), 0);
        expect(m5AnnealRestDy(M5AnnealKind.connector, false, u), 0);
      }
      // The touch band follows the drawn line.
      final g = M5AnnealGeo.forScene(780, 0);
      final bottom = Offset(g.xOf(0.745), g.condY + m5AnnealUDepth);
      expect(g.onLine(bottom, M5AnnealKind.jumper, true), isTrue);
      expect(g.onLine(Offset(bottom.dx, g.condY - 6), M5AnnealKind.jumper, true), isFalse, reason: 'above the U is not the conductor');
      expect(g.onLine(Offset(bottom.dx, g.condY), M5AnnealKind.connector, true), isTrue);
    });

    testWidgets('the four kinds paint differently (the U, the long sleeve, two pieces with no clamp, the PG clamp); the spanner lap goes all round the nut', (t) async {
      final g = M5AnnealGeo.forScene(780, 0);
      Future<List<int>> paint(M5AnnealSpot s, {bool off = false}) async {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        const size = Size(360, 780);
        M5AnnealBenchPainter(
          geo: g,
          light: M5AnnealLight.day,
          bench: M5AnnealBench(
            kind: s.kind,
            lo: s.lo,
            hi: s.hi,
            jumperRight: s.jumperRight,
            clampOff: off,
            turn: 0,
            endL: m5AnnealGapLo,
            endR: m5AnnealGapHi,
            darkL: false,
            darkR: false,
            tapes: const [],
            trayLeft: 2,
            kinks: const [],
            fitted: false,
          ),
        ).paint(c, size);
        final img = await rec.endRecording().toImage(360, 780);
        final bytes = await img.toByteData();
        return bytes!.buffer.asUint8List().toList();
      }

      await t.runAsync(() async {
        final kinds = <String, List<int>>{
          'jumperR': await paint(const M5AnnealSpot(kind: M5AnnealKind.jumper)),
          'jumperL': await paint(const M5AnnealSpot(kind: M5AnnealKind.jumper, jumperRight: false)),
          'sleeve': await paint(const M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.4, hi: 0.6)),
          'connector': await paint(const M5AnnealSpot(kind: M5AnnealKind.connector)),
          'snapped': await paint(const M5AnnealSpot(kind: M5AnnealKind.snapped, lo: 0.4, hi: 0.6), off: true),
        };
        final names = kinds.keys.toList();
        for (var i = 0; i < names.length; i++) {
          for (var j = i + 1; j < names.length; j++) {
            expect(listEquals(kinds[names[i]], kinds[names[j]]), isFalse, reason: '${names[i]} vs ${names[j]}');
          }
        }
        final lap = m5AnnealNutLap(g.nut);
        expect(lap.first.center, lap.last.center, reason: 'back to the start');
        expect(lap.any((r) => r.center.dx < g.nut.dx - 10), isTrue);
        expect(lap.any((r) => r.center.dx > g.nut.dx + 10), isTrue);
        expect(lap.any((r) => r.center.dy < g.nut.dy - 10), isTrue);
        expect(lap.any((r) => r.center.dy > g.nut.dy + 10), isTrue);
      });
    });

    test('a whole play: four rounds, 100 % with no slips; three slips fail the mark', () {
      final d = m5AnnealDeal(math.Random(5));
      final r = M5AnnealRun(d);
      if (d.bare) {
        r.test(d.bareLeft);
        r.earth(d.bareLeft);
      }
      expect(r.climb(), isNull);
      r.next();
      for (final s in d.spots) {
        r.unbolt();
        if (s.soft) {
          for (final u in [if (s.softLeft) s.lo - 0.05, if (s.softRight) s.hi + 0.05]) {
            expect(r.placeTape(u), isTrue);
            expect(r.cut(r.tapes.length - 1), isNull);
          }
        } else {
          expect(r.connectorOnly(), isNull);
        }
        expect(r.roundDone, isTrue, reason: '$s');
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, contains(M5AnnealLines.caughtEarth));
      final bad = M5AnnealRun(d)..slips = 3;
      expect(bad.percent, 55);
      bad.slips = 4;
      expect(bad.percent, 40);
    });

    test('tool row: every tool, never laid out tester → earth → climb; rows differ', () {
      expect(m5AnnealInWorkOrder(const [M5AnnealTool.tester, M5AnnealTool.earth, M5AnnealTool.climb]), isTrue);
      final rows = <String>{};
      for (var s = 0; s < 60; s++) {
        final row = m5AnnealToolRow(math.Random(s));
        expect(row.toSet(), M5AnnealTool.values.toSet());
        expect(m5AnnealInWorkOrder(row), isFalse, reason: '$row');
        rows.add(row.map((t) => t.name).join(','));
      }
      expect(rows.length, greaterThanOrEqualTo(4));
    });

    test('English digits only; locked words; every mistake has its picture; one deadly; keys unique', () {
      final all = <String>[
        M5AnnealLines.intro,
        ...M5AnnealLines.tasks,
        ...M5AnnealLines.rounds,
        ...M5AnnealLines.allWhyRight,
        ...M5AnnealLines.myths,
        M5AnnealLines.siteBothQ,
        M5AnnealLines.siteTestQ,
        M5AnnealLines.cutQ,
        M5AnnealLines.noCutQ,
        M5AnnealLines.connectorOnly,
        ...M5AnnealLines.coworker.recordedLines,
        ...M5AnnealLines.coworker.right,
        ...M5AnnealLines.coworker.wrong,
        ...M5AnnealLines.coworker.asks,
        for (final m in M5AnnealMistakes.all) m.textBn,
        M5AnnealLines.allSet,
        M5AnnealLines.fail,
        M5AnnealLines.callHeld,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('সেফটি বেল্ট'), isFalse, reason: l);
      }
      expect(M5AnnealMistakes.all.where((m) => m.deadly), [M5AnnealMistakes.noEarth]);
      expect(M5AnnealMistakes.all.map((m) => m.key).toSet(), hasLength(M5AnnealMistakes.all.length));
      for (final m in M5AnnealMistakes.all) {
        expect(m.key, startsWith('5.3/m5_anneal_cut/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // The ruling's exact order card (M5-2).
      expect(M5AnnealMistakes.testFirst.textBn, contains('আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক'));
      expect(m5AnnealPacks.keys, ['do_5_3_b']);
      // No unused art in the folder.
      final files = Directory('assets/game/art/m5_anneal_cut').listSync().whereType<File>().map((f) => f.path.replaceAll('\\', '/').split('/').last).toSet();
      expect(files, M5AnnealMistakes.all.map((m) => m.art.split('/').last).toSet());
    });

    test('libraries: same length, big enough, never a rule marked wrong; a myth pool per round (no off-topic wrong cards); the coworker lines are listed for his voice', () {
      expectSameLength('why', [...M5AnnealLines.allWhyRight, ...M5AnnealLines.myths]);
      expect(M5AnnealLines.myths.toSet().intersection(M5AnnealLines.allWhyRight.toSet()), isEmpty);
      expect(M5AnnealLines.siteMyths.toSet().intersection(M5AnnealLines.spotMyths.toSet()), isEmpty);
      // The section's wrong cards are all earth / tester excuses; the spots'
      // are all about the conductor.
      for (final m in M5AnnealLines.siteMyths) {
        expect(m.contains('আর্থ') || m.contains('টেস্টার') || m.contains('লাইন'), isTrue, reason: m);
      }
      for (final m in M5AnnealLines.spotMyths) {
        expect(m.contains('আর্থ') || m.contains('টেস্টার'), isFalse, reason: m);
      }
      expect(M5AnnealLines.mythsFor(null), M5AnnealLines.siteMyths);
      expect(M5AnnealLines.mythsFor(const M5AnnealSpot(kind: M5AnnealKind.connector)), M5AnnealLines.spotMyths);
      final sets = <(List<String>, List<String>)>[
        (M5AnnealLines.siteWhy(true), M5AnnealLines.siteMyths),
        (M5AnnealLines.siteWhy(false), M5AnnealLines.siteMyths),
        for (final s in const [
          M5AnnealSpot(kind: M5AnnealKind.jumper),
          M5AnnealSpot(kind: M5AnnealKind.jumper, lo: 0.5, hi: 0.7),
          M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.3, hi: 0.7),
          M5AnnealSpot(kind: M5AnnealKind.snapped, lo: 0.4, hi: 0.6),
          M5AnnealSpot(kind: M5AnnealKind.connector),
        ])
          (M5AnnealLines.spotWhy(s), M5AnnealLines.mythsFor(s)),
      ];
      for (final (right, wrong) in sets) {
        expectLibrary('why ${right.first}', right, wrong);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          for (final o in deal.where((o) => !o.correct)) {
            expect(wrong, contains(o.textBn));
          }
        }
      }
      // M5-15(a): softness by colour and feel, never the bend as the proof.
      for (final l in [...M5AnnealLines.allWhyRight, ...M5AnnealLines.coworker.right, for (final m in M5AnnealMistakes.all) m.textBn]) {
        expect(l.contains('বাঁকিয়ে') || l.contains('বাঁকালে'), isFalse, reason: l);
      }
      expect(M5AnnealLines.spotQuestion(const M5AnnealSpot(kind: M5AnnealKind.connector)), M5AnnealLines.noCutQ);
      expect(M5AnnealLines.spotQuestion(const M5AnnealSpot(kind: M5AnnealKind.sleeve, lo: 0.3, hi: 0.7)), M5AnnealLines.cutQ);
      final cw = M5AnnealLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.recordedLines, [cw.line, cw.exitLine]);
      expect(cw.line, 'নতুন ক্ল্যাম্প লাগিয়ে দাও, তার দেখার দরকার নেই।');
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: 'his exit line is recorded');
    });

    test('tap areas stay on the 360-wide scene, below the header; the tray sits clear below the cut band', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5AnnealGeo.forScene(h, 0);
        for (final left in [true, false]) {
          final r = g.endHit(left);
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(120), reason: 'below the header');
          expect(r.bottom, lessThan(g.groundY));
        }
        expect(g.endHit(true).overlaps(g.endHit(false)), isFalse);
        expect(g.condY, greaterThan(150));
        expect(g.tray.top, greaterThan(g.condY + 40), reason: 'h $h');
        expect(g.tray.bottom, lessThan(h - 112 + 1));
        expect(g.uOf(g.xOf(0.37)), closeTo(0.37, 1e-9));
      }
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the tools, not in working order', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
          child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M5AnnealPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5AnnealLines.tester), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      final row = [...M5AnnealTool.values]..sort((a, b) =>
          t.getCenter(_label(M5AnnealLines.toolLabel(a))).dx.compareTo(t.getCenter(_label(M5AnnealLines.toolLabel(b))).dx));
      expect(m5AnnealInWorkOrder(row), isFalse, reason: 'the row on screen: $row');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5AnnealLines.askSite)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One deal with a bare end and a snapped spot (no clamp to unbolt), one
    // with both ends earthed and a soft jumper (cut on its U).
    for (final bare in [true, false]) {
      testWidgets('flow (${bare ? 'a bare end, a snapped spot' : 'both earthed, a soft jumper'}): section, three spots, the coworker refused, right reasons → pass', (t) async {
        final seed = _seedWhere((d) =>
            d.bare == bare &&
            (bare ? d.spots.any((s) => s.kind == M5AnnealKind.snapped) : d.spots.any((s) => s.kind == M5AnnealKind.jumper && s.soft)));
        final deal = m5AnnealDeal(math.Random(seed));
        final probe = M5AnnealProbe();
        final c = await _open(t, seed, probe: probe);
        await _site(t, deal);
        expect(probe.run!.index, 1);
        for (final (i, s) in deal.spots.indexed) {
          await _spot(t, s, coworker: i == deal.jumperAt);
          expect(probe.run!.index, i + 2, reason: 'spot $i done: $s');
        }
        await _pump(t, 2000);
        final save = c.read(gameSaveProvider);
        expect(save.rungProgress['5.3/do/1'], 'cleared');
        expect(save.mistakes, isEmpty);
        expect(save.starsByRung['5.3/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5AnnealLines.caughtCall), findsOneWidget);
        expect(find.text(M5AnnealLines.caughtEarth), findsOneWidget);
        if (bare) expect(find.text(M5AnnealLines.caughtTest), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (earth before the tester) shows its card; the same round goes on after it', (t) async {
      final seed = _seedWhere((d) => d.bare);
      final deal = m5AnnealDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _tool(t, M5AnnealLines.earth);
      await _tapAt(t, _geo.endHit(deal.bareLeft).center);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5AnnealMistakes.testFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M5AnnealLines.tester), findsOneWidget, reason: 'the same round');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5AnnealMistakes.testFirst.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a cut in soft metal: the dark-face card, then a re-cut further out finishes the spot', (t) async {
      // A deal whose first spot is the annealed sleeve, both ends earthed.
      final seed = _seedWhere((d) => !d.bare && d.spots.first.kind == M5AnnealKind.sleeve);
      final deal = m5AnnealDeal(math.Random(seed));
      final s = deal.spots.first;
      final probe = M5AnnealProbe();
      final c = await _open(t, seed, probe: probe);
      await _site(t, deal);
      await _unbolt(t);
      expect(probe.run!.clampOff, isTrue);
      final inside = s.lo + 0.03;
      await _dragTape(t, s, inside);
      expect(probe.run!.tapes, hasLength(1));
      await _cutAt(t, s, inside);
      expect(find.text(M5AnnealMistakes.softFace.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(probe.run!.darkL, isTrue);
      for (final u in [s.lo - 0.05, s.hi + 0.05]) {
        await _dragTape(t, s, u);
        await _cutAt(t, s, u);
      }
      await _pump(t, 1000);
      await _reason(t, M5AnnealLines.spotWhy(s));
      expect(probe.run!.index, 2);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5AnnealMistakes.softFace.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => d.bare);
      final deal = m5AnnealDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _tool(t, M5AnnealLines.earth);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.endHit(deal.bareLeft).center);
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a fast play at the jumper: the next control waits for the coworker; listening is a slip and the spot goes on', (t) async {
      final seed = _seedWhere((d) => !d.bare && d.jumperAt == 0);
      final deal = m5AnnealDeal(math.Random(seed));
      final s = deal.spots.first;
      final probe = M5AnnealProbe();
      final c = await _open(t, seed, probe: probe);
      await _site(t, deal);
      await _unbolt(t);
      // At once: well inside his 1.2–2.4 s timer.
      await t.tap(find.byKey(const ValueKey('anneal-connector-only')));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(probe.run!.roundDone, isFalse, reason: 'the button waited for him');
      expect(probe.run!.slips, 0);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5AnnealLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.text(M5AnnealMistakes.listen.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      // The spot goes on, played right now.
      if (!s.soft) {
        await t.tap(find.byKey(const ValueKey('anneal-connector-only')));
      } else {
        for (final u in [if (s.softLeft) s.lo - 0.05, if (s.softRight) s.hi + 0.05]) {
          await _dragTape(t, s, u);
          await _cutAt(t, s, u);
        }
      }
      await _pump(t, 1000);
      await _reason(t, M5AnnealLines.spotWhy(s));
      expect(probe.run!.index, 2);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5AnnealMistakes.listen.key);
      await _close(t, c);
    });

    testWidgets('climbing with an end bare: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.bare);
      final c = await _open(t, seed);
      await _tool(t, M5AnnealLines.climb);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5AnnealMistakes.noEarth.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the tools and both ends; on the bench only while waiting, never during the coworker', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => !d.bare && d.jumperAt == 0);
      final deal = m5AnnealDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      // The hand comes ~8 s after the last touch and plays two laps.
      Future<bool> showsSoon() async {
        for (var ms = 0; ms < 12000 && !scene().showing; ms += 100) {
          await t.pump(const Duration(milliseconds: 100));
        }
        return scene().showing;
      }
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the section');
      expect(scene().debugOptions, hasLength(5), reason: '3 tools + 2 ends');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _site(t, deal);
      expect(scene().showing, isFalse);
      expect(await showsSoon(), isTrue, reason: 'idle at the clamp');
      // A lap round the nut, not a straight line past it.
      final lap = scene().debugOptions;
      expect(lap, hasLength(5));
      final nut = _scr(_geo.nut);
      final local = t.getTopLeft(find.byType(IdleHint).first);
      final centres = [for (final r in lap) r.center + local];
      expect(centres.any((c) => c.dx < nut.dx - 10) && centres.any((c) => c.dx > nut.dx + 10), isTrue, reason: 'both sides: $centres vs $nut');
      expect(centres.any((c) => c.dy < nut.dy - 10) && centres.any((c) => c.dy > nut.dy + 10), isTrue, reason: 'above and below: $centres vs $nut');
      await _unbolt(t);
      expect(scene().showing, isFalse);
      // He is due: no hand while he comes and talks.
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the coworker deck has its own sweep');
      await _pickRight(t, M5AnnealLines.coworker.right);
      expect(await showsSoon(), isTrue, reason: 'idle on the bench');
      // Three taps on nothing show it at once.
      await _bendAt(t, deal.spots.first, 0.15);
      expect(scene().showing, isFalse);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_scr(Offset(300, _geo.condY - 100)));
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
