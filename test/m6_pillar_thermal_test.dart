// Lesson 6.9 (এলটি ফিডার পিলার), কাজ 1 "তাপের চোখ": the rules (a column
// counts as scanned after the frame stays on it; a hotter-than-its-sisters
// joint tagged on the live screen goes on the job card; an even joint tagged
// is a slip once; 'স্ক্যান শেষ' with a hotspot left behind or a column never
// scanned is a slip; listening to the coworker ends the scan with a slip;
// the job deck: tighten on a dead board right, water / bare hand / insulated
// spanner live / thick wire deadly, 'চলছে তো' a slip), the deal (columns,
// hotspots, tones that only compare within a column, the coworker before a
// hidden hotspot), the libraries, every spoken line listed, the drawn places,
// and the level in the shell: the guide first, a full clean play (the frame
// dragged over every column, the hotspots tagged, the reasons, the coworker
// refused, the jobs written, the card handed in), three slips, the deadly
// freeze, listening, the camera waiting for him on a fast play, the praise
// window taking no touch, and the gesture hand (how, never what).
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
import 'package:slm_flutter/features/game/m6_pillar_thermal.dart';
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
  rungId: '6.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6PillarThermalPacks['do_6_9_a']!;
typedef L = M6PillarThermalLines;
typedef Mk = M6PillarThermalMistakes;

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
const _h = 360 * 850 / 392;
M6ThermalRun get _live => M6PillarThermalProbe.run!;
M6ThermalGeo _geoOf(M6ThermalDeal d) => M6ThermalGeo.forScene(_h, 0, ways: d.ways, mirror: d.mirror);
M6ThermalGeo get _geo => _geoOf(_live.deal);

/// Drag the camera's frame onto column [u] (from wherever it is), then let
/// it stay [stay] ms.
Future<void> _aim(WidgetTester t, int u, {int stay = 1200}) async {
  final g = _geo;
  final from = Offset(_live.frameX, g.y(0.53));
  final to = Offset(g.unitX(u), g.y(0.53));
  final gesture = await t.startGesture(from * _k);
  const n = 10;
  for (var i = 1; i <= n; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / n)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _pump(t, stay);
}

Future<void> _tagAt(WidgetTester t, int u, M6Slot s) async {
  await t.tapAt(_geo.camJoint(u, s) * _k);
  await _pump(t, 400);
}

Future<void> _scanDone(WidgetTester t) async {
  await t.tap(_label(L.scanDone));
  await _pump(t, 500);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6PillarThermalPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6ThermalDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m6ThermalDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t) async {
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// Pick a card of the open job deck by text (preview → ✓).
Future<void> _pickFix(WidgetTester t, List<String> texts) async {
  await waitChoiceDeck(t);
  final r = _onScreen(texts);
  expect(r, isNotEmpty, reason: texts.first);
  await t.tap(r.first, warnIfMissed: false);
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue);
  await _pump(t, 800);
}

M6ThermalDeal _dealOf({int ways = 3, List<M6ThermalSpot> spots = const [M6ThermalSpot(unit: 2, slot: M6Slot.lugY)], int after = 1}) {
  final tones = [
    for (var u = 0; u <= ways; u++) {for (final s in M6Slot.values) s: 0.3},
  ];
  for (final p in spots) {
    tones[p.unit][p.slot] = 0.8;
  }
  return M6ThermalDeal(ways: ways, metal: true, mirror: false, spots: spots, tones: tones, coworkerAfter: after);
}

void main() {
  group('rules', () {
    test("uncheckedLeft: an unscanned column that looks fine (a late hotspot's blackened one does not count); cleanSeen counts passed-over columns", () {
      final r = M6ThermalRun(_dealOf(spots: const [M6ThermalSpot(unit: 1, slot: M6Slot.lugR), M6ThermalSpot(unit: 3, slot: M6Slot.lugB, late: true)]));
      expect(r.uncheckedLeft, isTrue);
      for (final u in [0, 1, 2, 3]) {
        r.see(u);
      }
      r.see(9);
      expect(r.cleanSeen, 2, reason: 'columns 0 and 2 passed over');
      expect(r.cleanScanned, 0, reason: 'passing over is not scanning');
      r.scan(0);
      r.scan(2);
      expect(r.uncheckedLeft, isTrue, reason: 'column 1 not yet scanned');
      expect(r.tag(1, M6Slot.lugR), M6Tag.hot);
      expect(r.uncheckedLeft, isFalse, reason: 'only the late (blackened) column is left: his "nothing to see" would be false');
      final q = M6ThermalRun(_dealOf())..tag(2, M6Slot.lugY);
      expect(q.uncheckedLeft, isTrue, reason: 'every hotspot carded, yet columns unscanned: his push still ends the scan early');
    });

    test('deals: 3–5 ways, 1–2 hotspots on any joint; a hotspot only stands out against its own column; he comes before a hidden one; plays differ', () {
      final seen = <String>{};
      final ways = <int>{};
      final counts = <int>{};
      final afters = <int>{};
      final slots = <M6Slot>{};
      var late = 0, mirror = 0, metal = 0, incomerHot = 0, overlap = 0;
      for (var s = 0; s < 400; s++) {
        final d = m6ThermalDeal(math.Random(s));
        ways.add(d.ways);
        counts.add(d.spots.length);
        afters.add(d.coworkerAfter);
        expect(d.tones, hasLength(d.units));
        expect(d.spots.map((p) => p.unit).toSet(), hasLength(d.spots.length), reason: 'one hotspot a column');
        for (final p in d.spots) {
          expect(m6SlotsOf(p.unit), contains(p.slot));
          slots.add(p.slot);
          if (p.unit == 0) incomerHot++;
          final others = [for (final x in m6SlotsOf(p.unit)) if (x != p.slot) d.tones[p.unit][x]!];
          expect(d.tones[p.unit][p.slot]! - others.reduce(math.max), greaterThanOrEqualTo(0.25), reason: 'hotter than its sisters');
          if (p.late) {
            late++;
            expect(d.spots, hasLength(2), reason: 'a late hotspot only as the second one');
          }
        }
        // Absolute tone does not give a hotspot away: some even joint
        // elsewhere on this pillar may glow warmer than a hotspot.
        final hot = [for (final p in d.spots) d.tones[p.unit][p.slot]!].reduce(math.min);
        final even = [
          for (var u = 0; u < d.units; u++)
            for (final x in m6SlotsOf(u))
              if (d.spots.every((p) => p.unit != u || p.slot != x)) d.tones[u][x]!,
        ].reduce(math.max);
        if (even > hot - 0.08) overlap++;
        // He comes after the after-th clean column (from the incomer
        // outward); an early hotspot is still to come then.
        final clean = [for (var u = 0; u < d.units; u++) if (!d.hotUnit(u)) u];
        expect(d.coworkerAfter, d.coworkerAfter == 2 ? 2 : 1);
        if (d.coworkerAfter == 2) expect(clean.length, greaterThanOrEqualTo(3), reason: 'a clean column is still left after him');
        final kth = clean[d.coworkerAfter - 1];
        expect(d.spots.any((p) => p.unit > kth && !p.late), isTrue, reason: 'a hidden hotspot still to come');
        if (d.mirror) mirror++;
        if (d.metal) metal++;
        seen.add('${d.ways}${d.mirror}${d.metal}${d.coworkerAfter}${d.spots.map((p) => '${p.unit}${p.slot.index}${p.late}').join()}');
      }
      expect(ways, {3, 4, 5});
      expect(counts, {1, 2});
      expect(afters, {1, 2});
      expect(slots, M6Slot.values.toSet(), reason: 'any joint: busbar side, lug side, neutral');
      expect(late, greaterThan(20));
      expect(incomerHot, greaterThan(10));
      expect(mirror, inInclusiveRange(140, 260));
      expect(metal, inInclusiveRange(140, 260));
      expect(overlap, greaterThan(20), reason: 'comparison within the column is the skill');
      expect(seen.length, greaterThan(300));
    });

    test('scan and tag: a column counts once; a hotspot tagged goes on the card; an even joint is a slip once', () {
      final r = M6ThermalRun(_dealOf());
      expect(r.scan(1), isTrue);
      expect(r.scan(1), isFalse);
      expect(r.scan(9), isFalse);
      expect(r.cleanScanned, 1);
      expect(r.tag(2, M6Slot.lugY), M6Tag.hot);
      expect(r.scanned, contains(2), reason: 'a tag means the column was seen');
      expect(r.tagged.single.unit, 2);
      expect(r.tag(2, M6Slot.lugY), M6Tag.again);
      expect(r.slips, 0);
      expect(r.tag(2, M6Slot.lugR), M6Tag.even);
      expect(r.slips, 1);
      expect(r.tag(2, M6Slot.lugR), M6Tag.again, reason: 'never carded twice');
      expect(r.slips, 1);
      expect(r.caught, contains(L.caughtHot));
      expect(L.entry(2, M6Slot.lugY), 'F2 · Y · কেবিল লাগ');
      expect(L.entry(0, M6Slot.n), 'ইনকামার · N · নিউট্রাল লিঙ্ক');
    });

    test('স্ক্যান শেষ: a hotspot left behind, else a column unscanned, is a slip; a full scan is right; the scan is over either way', () {
      final a = M6ThermalRun(_dealOf());
      for (var u = 0; u < 4; u++) {
        a.scan(u);
      }
      expect(a.endScan(), Mk.missedHot);
      expect(a.stage, M6ThermalStage.handIn, reason: 'nothing on the card: hand it in');
      expect(a.missed.single.unit, 2, reason: 'the missed hotspot is shown');
      expect(a.tag(1, M6Slot.lugR), M6Tag.closed);
      final b = M6ThermalRun(_dealOf())..tag(2, M6Slot.lugY);
      expect(b.endScan(), Mk.unscanned);
      expect(b.stage, M6ThermalStage.fix);
      expect(b.missed, isEmpty);
      final c = M6ThermalRun(_dealOf())..tag(2, M6Slot.lugY);
      for (var u = 0; u < 4; u++) {
        c.scan(u);
      }
      expect(c.endScan(), isNull);
      expect(c.slips, 0);
      expect(c.thorough, isTrue);
      expect(c.caught, contains(L.caughtScan));
      expect(c.fixSpot!.unit, 2);
    });

    test('listening ends the scan with a slip (X2/B1: ending the scan early is a slip)', () {
      final r = M6ThermalRun(_dealOf())..scan(1);
      final m = r.listen();
      expect(m, Mk.listened);
      expect(m.deadly, isFalse);
      expect(r.slips, 1);
      expect(r.stage, M6ThermalStage.handIn);
      expect(r.missed.single.unit, 2);
    });

    test('the job deck: tighten on a dead board right; water, bare hand, insulated spanner live, thick wire deadly; "চলছে তো" a slip', () {
      for (final f in M6ThermalFix.values) {
        final r = M6ThermalRun(_dealOf(spots: const [M6ThermalSpot(unit: 1, slot: M6Slot.busB), M6ThermalSpot(unit: 3, slot: M6Slot.n)]))
          ..tag(1, M6Slot.busB)
          ..tag(3, M6Slot.n);
        for (var u = 0; u < 4; u++) {
          r.scan(u);
        }
        expect(r.endScan(), isNull);
        final m = r.fix(f);
        switch (f) {
          case M6ThermalFix.deadTighten:
            expect(m, isNull);
            expect(r.fixIndex, 1);
            expect(r.stage, M6ThermalStage.fix);
            expect(r.fix(M6ThermalFix.deadTighten), isNull);
            expect(r.stage, M6ThermalStage.handIn);
            expect(r.caught, contains(L.caughtFix));
            expect(r.handIn(), isTrue);
            expect(r.passed, isTrue);
            expect(r.percent, 100);
          case M6ThermalFix.leaveIt:
            expect(m, Mk.leaveIt);
            expect(r.slips, 1);
            expect(r.stage, M6ThermalStage.fix, reason: 'the same hotspot, a new deck');
            expect(r.fixIndex, 0);
          default:
            expect(m!.deadly, isTrue, reason: '$f');
            expect(r.ended, isTrue);
            expect(r.passed, isFalse);
        }
      }
      expect(Mk.forFix(M6ThermalFix.water), Mk.water);
      expect(Mk.forFix(M6ThermalFix.bareHand), Mk.bareHand);
      expect(Mk.forFix(M6ThermalFix.insulatedLive), Mk.insulatedLive);
      expect(Mk.forFix(M6ThermalFix.thickWire), Mk.thickWire);
      for (final t in L.fixRight) {
        expect(L.fixOf(t), M6ThermalFix.deadTighten);
      }
      for (final e in L.fixWrong.entries) {
        expect(L.fixOf(e.value), e.key);
      }
    });

    test('three slips and the play fails; the mark falls 15 a slip', () {
      final r = M6ThermalRun(_dealOf());
      r
        ..tag(1, M6Slot.busR)
        ..tag(1, M6Slot.busY)
        ..tag(1, M6Slot.busB);
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      r.tag(1, M6Slot.lugB);
      expect(r.percent, 40);
    });

    test('English digits; জল not পানি; ডেড not মৃত; LT not এলটি; ON/OFF not অন/অফ; base + nukta; the deadly set; every picture used', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.moreHot,
        L.scanDone,
        L.handIn,
        L.jobCard,
        L.jobCardSub,
        ...L.stages,
        for (var u = 0; u <= 5; u++)
          for (final s in m6SlotsOf(u)) L.entry(u, s),
        ...L.fixRight,
        ...L.fixWrong.values,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        for (final m in Mk.all) m.textBn,
        for (final c in L.caughtAll) c,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('এলটি'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)($|[\s,।])').hasMatch(l), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.water, Mk.bareHand, Mk.insulatedLive, Mk.thickWire});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.9/m6_pillar_thermal/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m6ThermalLessonPoint, inInclusiveRange(0, 2));
      const dir = 'assets/game/art/m6_pillar_thermal/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6PillarThermalPacks.keys, ['do_6_9_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('jobs', [...L.fixRight, ...L.fixWrong.values]);
      expectLibrary('jobs', L.fixRight, L.fixWrong.values.toList());
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6ThermalWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      // A job deck always holds the right job and at least one deadly one.
      for (var k = 0; k < 40; k++) {
        final deal = dealChoices(L.fixRight, L.fixWrong.values.toList(), math.Random(k));
        expect(deal.where((o) => o.correct), hasLength(1));
        expect(deal.where((o) => !o.correct && (Mk.forFix(L.fixOf(o.textBn))?.deadly ?? false)), isNotEmpty);
      }
      final cw = L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('every spoken line is listed: his push for his voice; the guide\'s lines, why-questions and mistake texts for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['চোখে তো কিছু দেখা যাচ্ছে না, ক্যামেরা রাখো — সব ঠিক আছে।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll([
            L.intro,
            ...L.tasks,
            L.moreHot,
            ...L.whyQ.values,
            'ও বলছে ক্যামেরা রেখে দিতে। কী করবেন?',
            L.callHeld,
            L.allSet,
            L.fail,
            for (final m in Mk.all) m.textBn,
          ]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_pillar_thermal: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the drawn places: every column under the frame at its centre; touch boxes on the live screen apart; clear of the header, the guide and its bubble', () {
      for (final h in [600.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final ways in [3, 4, 5]) {
          for (final mirror in [false, true]) {
            final g = M6ThermalGeo.forScene(h, 0, ways: ways, mirror: mirror);
            final tag = 'h $h ways $ways mirror $mirror';
            expect(g.unitAt(g.frameStart), isNull, reason: '$tag: the frame starts on nothing');
            for (var u = 0; u <= ways; u++) {
              expect(g.unitAt(g.unitX(u)), u, reason: tag);
              final x = g.unitX(u).clamp(g.frameMinX, g.frameMaxX);
              expect(g.unitAt(x), u, reason: '$tag: the frame reaches column $u');
              for (final s in m6SlotsOf(u)) {
                expect(g.frameAt(g.unitX(u)).contains(g.joint(u, s)), isTrue, reason: '$tag: $u $s in the frame');
                final r = g.camJointHit(u, s);
                expect(g.cam.contains(r.topLeft) && g.cam.contains(r.bottomRight), isTrue, reason: '$tag: $r');
                expect(r.top, greaterThan(125), reason: '$tag: below the header');
              }
              final hits = [for (final s in m6SlotsOf(u)) g.camJointHit(u, s)];
              for (final (i, a) in hits.indexed) {
                for (final b in hits.skip(i + 1)) {
                  expect(a.overlaps(b), isFalse, reason: '$tag: $a / $b');
                }
              }
            }
            expect(g.work.top, greaterThan(g.cam.bottom), reason: tag);
            expect(g.work.bottom, lessThanOrEqualTo(g.floorY), reason: tag);
            final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
            expect(g.cam.overlaps(guide), isFalse, reason: tag);
            expect(g.dragHit.overlaps(guide), isFalse, reason: '$tag: the drag area clear of the guide');
            if (h >= 700) {
              final bubble = Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81);
              expect(g.frameAt(g.frameMaxX).overlaps(bubble), isFalse, reason: '$tag: the frame clear of the bubble');
              expect(g.cam.overlaps(bubble), isFalse, reason: tag);
            }
            expect(g.jobCard.right, lessThan(250), reason: '$tag: clear of the button');
          }
        }
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

    testWidgets('the guide comes first: a tap does not skip him; then the camera, the job card and স্ক্যান শেষ', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
          child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M6PillarThermalPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.camLabel), findsOneWidget);
      expect(_label(L.jobCard), findsOneWidget);
      expect(_label(L.scanDone), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askSweep)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with two hotspots (one late), he after two clean columns;
    // one with a single hotspot, mirrored, he after the first clean column.
    final flowSeeds = [
      _seedWhere((d) => d.spots.length == 2 && d.spots.any((p) => p.late) && d.coworkerAfter == 2 && !d.mirror),
      _seedWhere((d) => d.spots.length == 1 && d.mirror && d.coworkerAfter == 1 && d.ways == 5),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): every column scanned, hotspots tagged, reasons, he is refused, jobs written, card handed in → pass', (t) async {
        final d = m6ThermalDeal(math.Random(seed));
        final c = await _open(t, seed);
        var came = false;
        var first = true;
        for (var u = 0; u < d.units; u++) {
          await _aim(t, u);
          expect(_live.scanned, contains(u), reason: 'column $u counted after the dwell');
          if (!came && await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 2800)) {
            came = true;
            expect(_live.uncheckedLeft, isTrue, reason: 'a column still to scan');
            await _refuse(t);
          }
          for (final p in d.spots.where((p) => p.unit == u)) {
            await _tagAt(t, u, p.slot);
            if (!came && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
              // The frame passed over his clean columns on the way: the tag
              // waited for him.
              came = true;
              expect(_live.tagged, isNot(contains(p)), reason: 'the tag waited');
              await _refuse(t);
              await _tagAt(t, u, p.slot);
            }
            expect(_live.tagged, contains(p));
            if (first) {
              first = false;
              await _pickRight(t, L.whyRight[M6ThermalWhy.tag]!);
              await _pump(t, 2000);
            } else {
              await _pump(t, 1200);
            }
          }
        }
        expect(came, isTrue);
        expect(find.text(L.entry(d.spots.first.unit, d.spots.first.slot)), findsOneWidget, reason: 'on the job card');
        await _scanDone(t);
        expect(find.byType(MistakeCard), findsNothing);
        await _pickRight(t, L.whyRight[M6ThermalWhy.scan]!);
        await _pump(t, 2000);
        for (var i = 0; i < d.spots.length; i++) {
          await _pickFix(t, L.fixRight);
          expect(find.byType(MistakeCard), findsNothing);
          await _pickRight(t, L.whyRight[M6ThermalWhy.fix]!);
          await _pump(t, 2000);
        }
        expect(_live.stage, M6ThermalStage.handIn);
        await t.tap(_label(L.handIn));
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.9/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.9/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    // He after two clean columns; the column next to the frame's start is
    // clean, so going there passes over just one clean column.
    final quiet = _seedWhere((d) => d.coworkerAfter == 2 && !d.hotUnit(d.ways ~/ 2));
    final quietU = m6ThermalDeal(math.Random(quiet)).ways ~/ 2;
    // A first clean column well before any hotspot (gesture hand only).
    final calm = _seedWhere((d) => d.coworkerAfter == 2 && !d.hotUnit(0) && !d.hotUnit(1));
    testWidgets('an even joint tagged is a slip with its card; the scan goes on; three slips strike out', (t) async {
      final c = await _open(t, quiet);
      await _aim(t, quietU);
      for (final (i, s) in [M6Slot.lugR, M6Slot.lugY, M6Slot.lugB].indexed) {
        await _tagAt(t, quietU, s);
        if (i < 2) {
          expect(find.text(Mk.evenTag.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(find.byType(MistakeCard), findsNothing);
          expect(_live.stage, M6ThermalStage.scan, reason: 'the scan goes on');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('স্ক্যান শেষ with a hotspot left: a slip, the hotspot shown, then the hand-in', (t) async {
      final c = await _open(t, quiet);
      await _aim(t, quietU);
      await _scanDone(t);
      expect(find.text(Mk.missedHot.textBn), findsOneWidget);
      expect(_live.missed, hasLength(_live.deal.spots.length));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.stage, M6ThermalStage.handIn);
      expect(_label(L.handIn), findsOneWidget);
      expect(_label(L.scanDone), findsNothing);
      await _close(t, c);
    });

    // One hotspot next to the frame's start: the frame goes straight to it
    // over no clean column (a hot column never brings the coworker).
    final hotFirst = _seedWhere((d) => d.spots.length == 1 && (d.spots.single.unit - d.ways ~/ 2 - 0.5).abs() < 1);
    testWidgets('a deadly job (live joint): the scene freezes first, then the near-miss card', (t) async {
      final d = m6ThermalDeal(math.Random(hotFirst));
      final c = await _open(t, hotFirst);
      final u = d.spots.single.unit;
      await _aim(t, u);
      await _tagAt(t, u, d.spots.single.slot);
      await _pickRight(t, L.whyRight[M6ThermalWhy.tag]!);
      await _pump(t, 2000);
      await _scanDone(t);
      expect(find.text(Mk.unscanned.textBn), findsOneWidget, reason: 'the other columns never scanned');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      final deadly = [for (final e in L.fixWrong.entries) if (Mk.forFix(e.key)!.deadly) e.value];
      await _pickFix(t, deadly);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.last.deadly, isTrue);
      await _close(t, c);
    });

    final early = _seedWhere((d) => d.coworkerAfter == 1 && !d.hotUnit(0));
    testWidgets('listening to him: a slip, the scan ends, a missed hotspot is shown', (t) async {
      final c = await _open(t, early);
      await _aim(t, 0);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.text(Mk.listened.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.stage, isNot(M6ThermalStage.scan));
      expect(_live.missed, isNotEmpty);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listened.key);
      await _close(t, c);
    });

    testWidgets('a fast play: the camera waits for him; he cuts in at once', (t) async {
      final c = await _open(t, early);
      await _aim(t, 0);
      // At once, inside his 1.2–2.4 s timer: drag the camera on.
      final x0 = _live.frameX;
      await _aim(t, 1, stay: 100);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.frameX, x0, reason: 'the camera did not move');
      await _refuse(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _aim(t, 1);
      expect(_live.scanned, contains(1), reason: 'after him the camera moves');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    // A quick sweep over the whole pillar first (nothing scanned), then the
    // hotspot tagged: he still comes, and the tag waits for him.
    final sweep = _seedWhere((d) => d.spots.length == 1 && d.spots.single.unit == d.units - 1);
    testWidgets('a quick sweep first, then the tag: he still comes and the tag waits for him', (t) async {
      final d = m6ThermalDeal(math.Random(sweep));
      final c = await _open(t, sweep);
      final p = d.spots.single;
      await _aim(t, 0, stay: 50);
      await _aim(t, d.ways, stay: 50);
      expect(_live.cleanScanned, 0, reason: 'nothing stayed on');
      expect(_live.cleanSeen, d.units - 1, reason: 'every column passed over');
      expect(find.byType(CoworkerPeek), findsNothing);
      await _tagAt(t, p.unit, p.slot);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in at the tag');
      expect(_live.tagged, isEmpty, reason: 'the tag waited');
      await _refuse(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _tagAt(t, p.unit, p.slot);
      expect(_live.tagged.single, p);
      expect(_live.stage, M6ThermalStage.scan);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m6ThermalDeal(math.Random(hotFirst));
      final c = await _open(t, hotFirst);
      final u = d.spots.single.unit;
      await _aim(t, u);
      await _tagAt(t, u, d.spots.single.slot);
      expect(_label(L.scanDone), findsNothing, reason: 'the button is gone');
      final x0 = _live.frameX;
      final other = m6SlotsOf(u).firstWhere((s) => s != d.spots.single.slot);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.camJoint(u, other) * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(Offset(_live.frameX, _geo.y(0.53)) * _k, const Offset(80, 0));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.frameX, x0, reason: 'the camera did not move');
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[M6ThermalWhy.tag]!);
      await _pump(t, 2000);
      expect(_label(L.scanDone), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a drag nudge first; three taps on nothing then sweep the live screen and স্ক্যান শেষ alike', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, calm);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the camera not moved');
      expect(scene().debugOptions, isEmpty, reason: 'a drag nudge, not a pick');
      expect(scene().debugFrame?.ripple, isNull);
      await _aim(t, 0, stay: 300);
      expect(scene().showing, isFalse);
      // Three taps on nothing (the camera's bezel corner) bring the hand back.
      final empty = (_geo.cam.topLeft + const Offset(4, 4)) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(scene().debugOptions, hasLength(m6SlotsOf(0).length + 1), reason: 'every joint on the screen and স্ক্যান শেষ, alike');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });
  });
}
