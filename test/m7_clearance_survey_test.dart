// Lesson 7.3 (ন্যূনতম ক্লিয়ারেন্স), কাজ 1 "আইনের মাপজোখ": the rules (the
// tape's two points per site — the span's lowest point to the road, the
// চিলেকোঠা top or the roof to the wire, the balcony edge or the wall to the
// conductor — the wrong pair a slip; the drum's legal minimum per place and
// voltage, checked first; the verdict, a missed short gap or a needless
// report a slip; the phone on a short site), the deal (three sites, one of
// each, legal and short both, a crossover reading, side sites on 415 V or
// 33 kV only), the libraries, the coworker (myth 2; listening = a slip, the
// level has no deadly act), the drawn points, and the level in the shell: the
// guide first, a full clean patrol (the tape, the drum, the stamp, the phone,
// a reason each site, the coworker refused), a slip card that keeps the site,
// three slips, the phone waits for the coworker, and the gesture hand.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
import 'package:slm_flutter/features/game/m7_clearance_survey.dart';
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
  rungId: '7.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7ClearanceSurveyPacks['do_7_3_a']!;
typedef L = M7ClearanceSurveyLines;
typedef Mk = M7ClearanceSurveyMistakes;

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
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
List<String> _textsOnScreen(List<String> texts) => [
      for (final x in texts)
        if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x,
    ];

/// A reason (or the coworker's deck): the one right card, ✓, then proceed.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _textsOnScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await pickChoice(t, r.single);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M7ClrGeo get _geo => M7ClrGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7ClrRun get _live => M7ClearanceSurveyProbe.run!;

/// Drag [from] → [to] (design px) in small steps.
Future<void> _drag(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

/// Drag a widget onto another (screen px).
Future<void> _dragWidget(WidgetTester t, Finder from, Finder to) async {
  final a = t.getCenter(from), b = t.getCenter(to);
  final g = await t.startGesture(a);
  for (var i = 1; i <= 12; i++) {
    await g.moveTo(Offset.lerp(a, b, i / 12)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

/// The two handles onto [a] then [b].
Future<void> _measure(WidgetTester t, M7ClrPoint a, M7ClrPoint b) async {
  final pts = _live.site.layout.points;
  await _drag(t, _geo.park(0), _geo.at(pts[a]!));
  expect(_live.handles[0], a);
  await _drag(t, _geo.park(1), _geo.at(pts[b]!));
  expect(_live.handles[1], b);
}

Future<void> _write(WidgetTester t) async {
  await t.tap(_label(L.write));
  await _pump(t, 500);
}

/// The drum to [ruleT] (one swipe up per step).
Future<void> _drumTo(WidgetTester t, int ruleT) async {
  final target = kM7ClrDrum.indexOf(ruleT);
  var guard = 0;
  while (_live.drum != target && guard++ < 8) {
    await t.drag(find.byKey(const ValueKey('clr-drum')), const Offset(0, -30));
    await _pump(t, 250);
  }
  expect(_live.drumT, ruleT);
}

Future<void> _stamp(WidgetTester t, {required bool legal}) async {
  await _dragWidget(t, find.byKey(ValueKey('clr-stamp-${legal ? 'legal' : 'short'}')), find.byKey(const ValueKey('clr-slot')));
}

Future<void> _phone(WidgetTester t, {int ms = 1500}) async {
  final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('clr-phone'))));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7ClearanceSurveyPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7ClrDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7ClrDeal(math.Random(s))));

/// The coworker comes (after the short stamp): refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// One site played right (the coworker refused if he is dealt on it).
Future<void> _playSite(WidgetTester t, M7ClrDeal d, int i) async {
  final s = d.sites[i];
  expect(_live.index, i);
  final pair = s.rightPair.toList();
  await _measure(t, pair[0], pair[1]);
  expect(_live.readingT, s.readingT, reason: 'the tape reads the true clearance');
  expect(find.text(m7ClrMetres(s.readingT)), findsOneWidget, reason: 'the reading on release');
  await _write(t);
  expect(_live.stage, M7ClrStage.rule);
  expect(find.byKey(const ValueKey('clr-register')), findsOneWidget);
  await _drumTo(t, s.ruleT);
  await _stamp(t, legal: s.legal);
  if (!s.legal) {
    expect(_live.stage, M7ClrStage.phone);
    if (d.coworkerSite == i) await _refuse(t);
    await _phone(t);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${s.place}');
  expect(_live.roundDone, isTrue, reason: '${s.place}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${s.place})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[s.why]!);
  await _pump(t, 3000);
}

M7ClrRun _runOf(M7ClrSite first) => M7ClrRun(M7ClrDeal(
      sites: [
        first,
        M7ClrSite(place: M7ClrPlace.roof, volt: M7ClrVolt.kv11, readingT: 33, why: M7ClrWhy.short),
        M7ClrSite(place: M7ClrPlace.side, volt: M7ClrVolt.lt, readingT: 15, why: M7ClrWhy.legal),
      ],
      coworkerSite: 1,
      stampsSwapped: false,
    ));

void main() {
  group('rules', () {
    test('deals: one site of each kind; legal and short both; a crossover reading; side sites 415 V or 33 kV; readings around the rule; plays differ', () {
      final seen = <String>{};
      final whys = <M7ClrWhy>{};
      var mirrors = 0, chiles = 0, balconies = 0, swapped = 0, roofs = 0, sides = 0;
      final volts = <M7ClrPlace, Set<M7ClrVolt>>{};
      final starts = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m7ClrDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.map((x) => x.place).toSet(), M7ClrPlace.values.toSet());
        expect(d.sites.where((x) => x.legal), isNotEmpty);
        expect(d.sites.where((x) => !x.legal), isNotEmpty);
        expect(d.sites.where((x) => x.crossover), isNotEmpty, reason: 'a value legal for LT but short for HT');
        expect(d.coworkerSite, d.sites.indexWhere((x) => !x.legal), reason: 'he comes on the first short site');
        if (d.stampsSwapped) swapped++;
        for (final x in d.sites) {
          volts.putIfAbsent(x.place, () => {}).add(x.volt);
          final off = (x.readingT - x.ruleT).abs();
          expect(off, inInclusiveRange(1, 6), reason: '±0.1–0.6 m around the rule');
          if (x.place == M7ClrPlace.side) {
            expect(x.volt, isNot(M7ClrVolt.kv11), reason: 'M7-7: side sites on 415 V or 33 kV only');
            sides++;
            if (x.balcony) balconies++;
          }
          if (x.place == M7ClrPlace.roof) {
            roofs++;
            if (x.chile) chiles++;
          }
          if (x.mirror) mirrors++;
          starts.add(x.drumStart);
          expect(x.sagT, inInclusiveRange(4, 12));
          final fits = switch (x.place) {
            M7ClrPlace.road => {M7ClrWhy.lowPoint, x.ht ? M7ClrWhy.roadHt : M7ClrWhy.roadLt},
            M7ClrPlace.roof => {if (x.chile) M7ClrWhy.chile},
            M7ClrPlace.side => {if (x.balcony) M7ClrWhy.edge},
          }..addAll(x.legal ? {M7ClrWhy.legal} : {M7ClrWhy.short, M7ClrWhy.report});
          expect(fits, contains(x.why), reason: '${x.place} ${x.legal}');
          whys.add(x.why);
          // The right pair reads the true clearance on the drawing.
          final p = x.rightPair.toList();
          expect(M7ClrLayout.readingT(x.layout.points[p[0]]!, x.layout.points[p[1]]!), x.readingT, reason: '${x.place}');
        }
        seen.add([for (final x in d.sites) '${x.place.index}${x.volt.index}${x.readingT}${x.chile}${x.balcony}${x.mirror}'].join('|'));
      }
      expect(seen.length, greaterThan(290));
      expect(whys, M7ClrWhy.values.toSet());
      expect(volts[M7ClrPlace.road], M7ClrVolt.values.toSet());
      expect(volts[M7ClrPlace.roof], M7ClrVolt.values.toSet());
      expect(volts[M7ClrPlace.side], {M7ClrVolt.lt, M7ClrVolt.kv33});
      expect(starts, hasLength(kM7ClrDrum.length), reason: 'the drum starts anywhere');
      expect(mirrors, inInclusiveRange(350, 550));
      expect(swapped, inInclusiveRange(110, 190));
      expect(chiles / roofs, inInclusiveRange(0.6, 0.9));
      expect(balconies / sides, inInclusiveRange(0.6, 0.9));
    });

    test('the law: the drum holds only the lesson\'s six values; the rule per place and voltage (live 7.3, X5, M7-7)', () {
      expect(kM7ClrDrum, [12, 20, 25, 37, 58, 65]);
      expect(m7ClrRuleT(M7ClrPlace.road, M7ClrVolt.lt), 58);
      expect(m7ClrRuleT(M7ClrPlace.road, M7ClrVolt.kv11), 65);
      expect(m7ClrRuleT(M7ClrPlace.road, M7ClrVolt.kv33), 65);
      expect(m7ClrRuleT(M7ClrPlace.roof, M7ClrVolt.lt), 25);
      expect(m7ClrRuleT(M7ClrPlace.roof, M7ClrVolt.kv11), 37);
      expect(m7ClrRuleT(M7ClrPlace.roof, M7ClrVolt.kv33), 37);
      expect(m7ClrRuleT(M7ClrPlace.side, M7ClrVolt.lt), 12);
      expect(m7ClrRuleT(M7ClrPlace.side, M7ClrVolt.kv33), 20);
      expect(m7ClrRuleT(M7ClrPlace.side, M7ClrVolt.kv11), 12, reason: 'live lesson: HT up to 11 kV 1.2 m (never dealt)');
      // The crossover band: 6.1 m across a road is legal for LT, short for HT.
      expect(M7ClrSite(place: M7ClrPlace.road, volt: M7ClrVolt.lt, readingT: 61, why: M7ClrWhy.legal).legal, isTrue);
      expect(M7ClrSite(place: M7ClrPlace.road, volt: M7ClrVolt.kv11, readingT: 61, why: M7ClrWhy.short).legal, isFalse);
      expect(m7ClrMetres(61), '6.1 মি');
      expect(m7ClrPlate(M7ClrVolt.lt), '415 V');
    });

    test('the tape: handles snap to distinct points; the wrong pair is a slip and the tape goes back; the right pair writes the reading', () {
      final r = _runOf(M7ClrSite(place: M7ClrPlace.road, volt: M7ClrVolt.kv33, readingT: 62, why: M7ClrWhy.lowPoint, sagT: 8));
      expect(r.write(), isNull, reason: 'nothing to write yet');
      expect(r.put(0, M7ClrPoint.attachL), isTrue);
      expect(r.put(1, M7ClrPoint.attachL), isFalse, reason: 'not both on one point');
      expect(r.put(1, M7ClrPoint.chileTop), isFalse, reason: 'not a point of this site');
      expect(r.readingT, isNull);
      expect(r.put(1, M7ClrPoint.roadKerb), isTrue);
      expect(r.readingT, 70, reason: 'the pole attachment: 6.2 + 0.8 sag');
      expect(r.write(), Mk.pointsRoad);
      expect(r.handles, [null, null], reason: 'the tape goes back');
      expect(r.stage, M7ClrStage.measure);
      r
        ..put(0, M7ClrPoint.roadMid)
        ..put(1, M7ClrPoint.wireLow);
      expect(r.readingT, 62);
      expect(r.write(), isNull);
      expect(r.writtenT, 62);
      expect(r.stage, M7ClrStage.rule);
      expect(r.caught, contains(L.caughtLow));
      expect(r.put(0, M7ClrPoint.attachR), isFalse, reason: 'written: the tape is done');
      // Roof: the roof instead of the চিলেকোঠা top.
      final roof = _runOf(M7ClrSite(place: M7ClrPlace.roof, volt: M7ClrVolt.lt, readingT: 22, why: M7ClrWhy.chile, chile: true));
      roof
        ..put(0, M7ClrPoint.wireRoof)
        ..put(1, M7ClrPoint.roofTop);
      expect(roof.readingT, 22 + 24, reason: 'the চিলেকোঠা adds 2.4 m');
      expect(roof.write(), Mk.pointsRoof);
      roof
        ..put(0, M7ClrPoint.chileTop)
        ..put(1, M7ClrPoint.wireTop);
      expect(roof.write(), isNull);
      // No চিলেকোঠা: the roof under the wire.
      final flat = _runOf(M7ClrSite(place: M7ClrPlace.roof, volt: M7ClrVolt.kv33, readingT: 40, why: M7ClrWhy.legal, chile: false));
      expect(flat.site.layout.points.containsKey(M7ClrPoint.chileTop), isFalse);
      flat
        ..put(0, M7ClrPoint.wireTop)
        ..put(1, M7ClrPoint.roofTop);
      expect(flat.write(), isNull);
      // Side: the wall instead of the balcony edge.
      final side = _runOf(M7ClrSite(place: M7ClrPlace.side, volt: M7ClrVolt.kv33, readingT: 17, why: M7ClrWhy.edge, balcony: true, mirror: true));
      side
        ..put(0, M7ClrPoint.conductor)
        ..put(1, M7ClrPoint.wallFace);
      expect(side.readingT, 17 + 12, reason: 'the balcony juts 1.2 m');
      expect(side.write(), Mk.pointsSide);
      side
        ..put(0, M7ClrPoint.balconyEdge)
        ..put(1, M7ClrPoint.conductor);
      expect(side.readingT, 17);
      expect(side.write(), isNull);
      final wall = _runOf(M7ClrSite(place: M7ClrPlace.side, volt: M7ClrVolt.lt, readingT: 9, why: M7ClrWhy.short, balcony: false));
      wall
        ..put(0, M7ClrPoint.wallFace)
        ..put(1, M7ClrPoint.conductor);
      expect(wall.readingT, 9);
      expect(wall.write(), isNull);
    });

    test('the register: the drum wraps; the drum is checked first, then the verdict; legal ends the site; short → the phone', () {
      M7ClrRun written(M7ClrSite s) {
        final r = _runOf(s);
        final p = s.rightPair.toList();
        r
          ..put(0, p[0])
          ..put(1, p[1])
          ..write();
        return r;
      }

      final r = written(M7ClrSite(place: M7ClrPlace.road, volt: M7ClrVolt.kv11, readingT: 61, why: M7ClrWhy.report, drumStart: 5));
      expect(r.drumT, 65);
      expect(r.spin(1), isTrue);
      expect(r.drumT, 12, reason: 'a drum wraps round');
      expect(r.spin(-2), isTrue);
      expect(r.drumT, 58);
      expect(r.stamp(legal: false), Mk.ruleRoad, reason: 'the drum first: 5.8 is LT');
      expect(r.stage, M7ClrStage.rule);
      r.spin(1);
      expect(r.stamp(legal: true), Mk.missed, reason: '6.1 m across a road on 11 kV: below today\'s 6.5 m');
      expect(r.stamp(legal: false), isNull);
      expect(r.stage, M7ClrStage.phone);
      expect(r.roundDone, isFalse);
      expect(r.spin(1), isFalse, reason: 'the row is stamped');
      expect(r.call(), isTrue);
      expect(r.roundDone, isTrue);
      expect(r.caught, containsAll([L.caughtRule, L.caughtReport]));
      expect(r.slips, 2);
      expect(r.thorough, isFalse);
      final l = written(M7ClrSite(place: M7ClrPlace.side, volt: M7ClrVolt.lt, readingT: 15, why: M7ClrWhy.legal, drumStart: 0, balcony: false));
      expect(l.stamp(legal: false), Mk.falseReport);
      expect(l.stamp(legal: true), isNull);
      expect(l.roundDone, isTrue);
      expect(l.stage, M7ClrStage.rule, reason: 'no phone on a legal site');
      expect(l.call(), isFalse);
      expect(l.caught, contains(L.caughtLegal));
      final roof = written(M7ClrSite(place: M7ClrPlace.roof, volt: M7ClrVolt.lt, readingT: 30, why: M7ClrWhy.legal, drumStart: 3));
      expect(roof.stamp(legal: true), Mk.ruleRoof, reason: '3.7 is HT; LT over a roof is 2.5');
      final side = written(M7ClrSite(place: M7ClrPlace.side, volt: M7ClrVolt.kv33, readingT: 22, why: M7ClrWhy.legal, drumStart: 0));
      expect(side.stamp(legal: true), Mk.ruleSide, reason: '33 kV beside a house is 2.0');
    });

    test('no deadly act in this level (M7-6); listening is a slip (X2/B1); three slips fail; each site counts its own slips', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      final r = _runOf(M7ClrSite(place: M7ClrPlace.road, volt: M7ClrVolt.lt, readingT: 55, why: M7ClrWhy.short));
      for (var i = 0; i < 2; i++) {
        r
          ..put(0, M7ClrPoint.attachL)
          ..put(1, M7ClrPoint.roadKerb);
        expect(r.write(), Mk.pointsRoad);
      }
      expect(r.pushSlip(), Mk.listen);
      expect(r.percent, 55);
      expect(r.passed, isFalse, reason: 'not done yet');
      r
        ..put(0, M7ClrPoint.wireLow)
        ..put(1, M7ClrPoint.roadMid)
        ..write()
        ..spin(4 - r.drum)
        ..stamp(legal: false)
        ..call()
        ..next();
      expect(r.index, 1);
      expect(r.thorough, isTrue);
      expect(r.stage, M7ClrStage.measure);
      expect(r.handles, [null, null]);
    });

    test('English digits only; jol not pani; term rules; no old 6.1 m rule; every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.write,
        L.sceneLabel,
        L.registerLabel,
        L.measured,
        L.drumLabel,
        L.slotLabel,
        L.stampLegal,
        L.stampShort,
        L.phone,
        for (var n = 1; n <= 3; n++) L.siteName(n),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtLow,
        L.caughtTop,
        L.caughtNear,
        L.caughtRule,
        L.caughtLegal,
        L.caughtReport,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|সুইচ অন|এলটি|এইচটি|কেভি|ভোল্ট ').hasMatch(l), isFalse, reason: 'ON/OFF, LT, HT, kV in English letters: $l');
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta form: $l');
        expect(l.contains('6.1'), isFalse, reason: 'today\'s rule is 6.5 m (A2/X5): $l');
        expect(l.contains('বেআইনি'), isFalse, reason: 'A2: say "below today\'s rule", never "illegal": $l');
      }
      // Every number the level teaches is the live lesson's.
      for (final m in [Mk.ruleRoad, Mk.ruleRoof, Mk.ruleSide]) {
        for (final n in RegExp(r'\d\.\d').allMatches(m.textBn).map((x) => x.group(0)!)) {
          expect(kM7ClrDrum.map((t) => (t / 10).toStringAsFixed(1)), contains(n), reason: m.key);
        }
      }
      expect(Mk.ruleSide.textBn, contains('33 kV'), reason: 'M7-7: every 2.0 m text names 33 kV');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.3/m7_clearance_survey/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      const dir = 'assets/game/art/m7_clearance_survey/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m7ClearanceSurveyPacks.keys, ['do_7_3_a']);
      expect(L.coworker.line, 'ক্লিয়ারেন্স একটু কম হলে কিছু হয় না, কেউ তো আর মাপতে আসছে না।', reason: 'myth 2 word for word');
    });

    test('libraries: same length, big enough, never a rule marked wrong; the stamps alike', () {
      expectSameLength('stamps', [L.stampLegal, L.stampShort]);
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7ClrWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      expect(cw.right, containsAll(['মাপ কম — এখনই সুপারভাইজারকে জানাব', 'আইন মানা আমার কর্তব্য — রিপোর্ট করব']), reason: 'the spec\'s refusals');
    });

    test('spoken lines: his exit is recorded; his new push and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['ক্লিয়ারেন্স একটু কম হলে কিছু হয় না, কেউ তো আর মাপতে আসছে না।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            ...L.tapWhy,
            ...L.whyQ.values,
            ...L.coworker.asks,
            L.callHeld,
            L.allSet,
            L.quick,
            L.fail,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_clearance_survey: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the drawing: every snap point on the scene, under the header, clear of the guide and the tape case, apart from each other', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M7ClrGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (var s = 0; s < 60; s++) {
          for (final site in m7ClrDeal(math.Random(s)).sites) {
            final pts = {for (final e in site.layout.points.entries) e.key: g.at(e.value)};
            for (final e in pts.entries) {
              final p = e.value;
              final tag = 'h $h seed $s ${site.place} ${e.key} $p';
              expect(p.dx, inInclusiveRange(8, 352), reason: tag);
              expect(p.dy, greaterThan(M7ClrGeo.top + 20), reason: '$tag under the header');
              expect(p.dy, lessThanOrEqualTo(g.floorY + 0.01), reason: '$tag on or above the ground');
              expect(guide.contains(p), isFalse, reason: '$tag under the guide');
              for (final k in [0, 1]) {
                expect((p - g.park(k)).distance, greaterThan(36), reason: '$tag by the tape case');
              }
            }
            final list = pts.entries.toList();
            for (var i = 0; i < list.length; i++) {
              for (var j = i + 1; j < list.length; j++) {
                expect((list[i].value - list[j].value).distance, greaterThan(14), reason: 'h $h seed $s ${site.place} ${list[i].key}/${list[j].key}');
              }
            }
            // A drop on a point snaps to that point.
            for (final e in pts.entries) {
              expect(g.snapTo(e.value, site.layout.points), e.key);
            }
          }
        }
        expect(g.snapTo(g.park(0), const {}), isNull);
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

    testWidgets('the guide comes first: a tap does not skip him; then the patrol, no button until the tape is down', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7ClearanceSurveyPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.sceneLabel), findsOneWidget);
      expect(_label(L.write), findsNothing);
      expect(find.byKey(const ValueKey('clr-register')), findsNothing);
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
      expect(lines.every((l) => l.contains(L.askSite)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final flowSeeds = [
      _seedWhere((d) => d.sites.every((s) => s.chile && s.balcony) && d.sites.where((s) => !s.legal).length == 2 && d.stampsSwapped),
      _seedWhere((d) => d.sites.every((s) => !s.chile && !s.balcony) && d.sites.any((s) => s.mirror) && !d.stampsSwapped),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three sites, the tape, the drum, the stamp, the phone, reasons; he is refused → pass', (t) async {
        final d = m7ClrDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playSite(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.3/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.3/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final roadFirst = _seedWhere((d) => d.sites.first.place == M7ClrPlace.road);
    testWidgets('the wrong two points: a slip, the tape back in its case, the same site; three slips strike the level out', (t) async {
      final c = await _open(t, roadFirst);
      for (var i = 0; i < 3; i++) {
        expect(_live.stage, M7ClrStage.measure);
        await _measure(t, M7ClrPoint.attachL, M7ClrPoint.roadKerb);
        expect(find.byType(MistakeCard), findsNothing, reason: 'a reading is no answer');
        await _write(t);
        if (i < 2) {
          expect(find.text(Mk.pointsRoad.textBn), findsOneWidget);
          expect(find.byType(FreezeFrame), findsNothing);
          expect(_live.handles, [null, null]);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.index, 0, reason: 'the same site');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.pointsRoad.key});
      await _close(t, c);
    });

    final shortFirst = _seedWhere((d) => !d.sites.first.legal && d.sites.first.drumStart != kM7ClrDrum.indexOf(d.sites.first.ruleT));
    testWidgets('a wrong drum is a slip before the verdict; the phone waits for the coworker; listening is a slip and the call still works', (t) async {
      final d = m7ClrDeal(math.Random(shortFirst));
      final s = d.sites.first;
      expect(d.coworkerSite, 0);
      final c = await _open(t, shortFirst);
      final pair = s.rightPair.toList();
      await _measure(t, pair[0], pair[1]);
      await _write(t);
      // The verdict is right, but the drum still stands on a wrong value.
      await _stamp(t, legal: false);
      expect(find.text(Mk.rule(s.place).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _drumTo(t, s.ruleT);
      await _stamp(t, legal: false);
      expect(_live.stage, M7ClrStage.phone);
      // At once, well inside his 1.2–2.4 s timer: the phone.
      final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('clr-phone'))));
      await _pump(t, 400);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pump(t, 1400);
      await g.up();
      expect(_live.roundDone, isFalse, reason: 'the phone did not call');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.listen.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      expect(_live.stage, M7ClrStage.phone, reason: 'the call still has to be made');
      // A short press does not call.
      await _phone(t, ms: 400);
      expect(_live.roundDone, isFalse);
      await _phone(t);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.rule(s.place).key, Mk.listen.key});
      await _close(t, c);
    });

    final legalFirst = _seedWhere((d) => d.sites.first.legal);
    testWidgets('a needless report is a slip; the praise window and the reason deck take no touch; then the next site', (t) async {
      final d = m7ClrDeal(math.Random(legalFirst));
      final s = d.sites.first;
      final c = await _open(t, legalFirst);
      final pair = s.rightPair.toList();
      await _measure(t, pair[0], pair[1]);
      await _write(t);
      await _drumTo(t, s.ruleT);
      await _stamp(t, legal: false);
      expect(find.text(Mk.falseReport.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _stamp(t, legal: true);
      expect(_live.roundDone, isTrue);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(60, 300));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[s.why]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(_live.stage, M7ClrStage.measure);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.falseReport.key});
      await _close(t, c);
    });

    testWidgets('gesture hand: idle at the tape shows a short nudge that presses nothing; any touch hides it; none with a card up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, roadFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the tape');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      await t.tapAt(const Offset(60, 400));
      await _pump(t, 300);
      expect(scene().showing, isFalse);
      await _measure(t, M7ClrPoint.attachL, M7ClrPoint.roadKerb);
      await _write(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'no hand over a mistake card');
      await _close(t, c);
    });
  });
}
