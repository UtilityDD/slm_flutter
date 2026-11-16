// Lesson 6.10 (এনার্জি মিটার), কাজ 2 "মিটার বদল, ছবিতে প্রমাণ": the rules
// (seals alike until tugged, the close looks, the push-button's screens and the
// tamper screen only when scrolled; a change on a tampered meter and a report
// on a clean one are slips; the action deck: report closes the job, a bypass
// pulled by hand is deadly, the rest are slips; the isolation of live lesson
// 6.10 pro tip 2 (ruling X5): the box opened with the cut-out in = deadly, no
// 0 V / a tester not proved first / not proved again = slips; the photos: the
// electronic meter goes blank once the cut-out is out, a missing or non-kWh
// photo = slip; listening to either push = slip), the deal, the libraries, the
// spoken lines, and the level in the shell: the guide first, full clean plays
// (every wall, a reason each, the coworker refused — both his pushes), the
// two-step decision, a slip card, three slips, both deadly freezes, the phone
// waits for him, the table window and the gesture hand.
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
import 'package:slm_flutter/features/game/m6_meter_swap_proof.dart';
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
  rungId: '6.10/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6MeterSwapPacks['do_6_10_b']!;
typedef L = M6MeterSwapLines;
typedef Mk = M6MeterSwapMistakes;

/// The art is read from disk when the test bundle does not have it.
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
Finder _deal(String text) => find.byKey(ValueKey('deal-$text'));
List<String> _onDeck(List<String> texts) => [
      for (final x in texts)
        if (_deal(x).evaluate().isNotEmpty) x,
    ];

/// The one right card of [right] on the deck: tap, ✓, then এগিয়ে যান.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  final r = _onDeck(right);
  expect(r, hasLength(1), reason: right.first);
  await pickChoice(t, r.single);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M6SwapGeo get _geo => M6SwapGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6MeterSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6SwapDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6SwapDeal(math.Random(s))));

M6SwapRun get _r => M6MeterSwapProbe.run!;

// --- hands on ----------------------------------------------------------------
Future<void> _decide(WidgetTester t, {required bool start}) async {
  await t.tap(_label(start ? L.start : L.report));
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue, reason: 'the decision preview');
  await _pump(t, 400);
}

Future<void> _tool(WidgetTester t, M6SwapTool tool) async {
  await t.tap(_label(L.tool(tool)));
  await _pump(t, 300);
}

Future<void> _press(WidgetTester t) async {
  await t.tapAt(_geo.button * _k);
  await _pump(t, 200);
}

Future<void> _toKwh(WidgetTester t) async {
  for (var i = 0; i < 6 && _r.face.screen != M6SwapScreen.kwh && _r.face.screen != M6SwapScreen.drum; i++) {
    await _press(t);
  }
  expect(_r.face.screen, anyOf(M6SwapScreen.kwh, M6SwapScreen.drum));
}

Future<void> _pull(WidgetTester t) async {
  await t.dragFrom(_geo.carrier(true).center * _k, const Offset(0, 50 * _k));
  await _pump(t, 300);
}

Future<void> _pushIn(WidgetTester t) async {
  await t.dragFrom(_geo.carrier(false).center * _k, const Offset(0, -60 * _k));
  await _pump(t, 300);
}

Future<void> _testAt(WidgetTester t, M6SwapPoint p) async {
  await t.tapAt(_geo.pointHit(p).center * _k);
  await _pump(t, 300);
}

Future<void> _openBox(WidgetTester t) async {
  await _tool(t, M6SwapTool.driver);
  await t.tapAt(_geo.boxHit.center * _k);
  await _pump(t, 300);
}

Future<void> _refuse(WidgetTester t, M6SwapPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  final r = _onDeck(L.coworker(p).right);
  expect(r, hasLength(1));
  await pickChoice(t, r.single, proceed: false);
  await _pump(t, 2600);
}

/// A clean wall played right (snap first, isolate, swap, snap, card, reason).
Future<void> _cleanWall(WidgetTester t) async {
  await _decide(t, start: true);
  expect(_r.stage, M6SwapStage.swap);
  await _toKwh(t);
  final pushHere = _r.pushHere && _r.deal.push == M6SwapPush.photo;
  await _tool(t, M6SwapTool.phone);
  if (pushHere) {
    expect(_r.oldPhoto, isNull, reason: 'the phone waited for him');
    await _refuse(t, M6SwapPush.photo);
    await _tool(t, M6SwapTool.phone);
  }
  expect(_r.oldPhoto, isNotNull);
  await _pull(t);
  expect(_r.carrierIn, isFalse);
  await _tool(t, M6SwapTool.tester);
  await _testAt(t, M6SwapPoint.line);
  await _testAt(t, M6SwapPoint.load);
  await _testAt(t, M6SwapPoint.line);
  expect(_r.reproved, isTrue);
  await _openBox(t);
  expect(_r.swapped, isTrue);
  await _pump(t, 2700);
  await _pushIn(t);
  expect(_r.carrierIn, isTrue);
  await _toKwh(t);
  await _tool(t, M6SwapTool.phone);
  final topic = m6SwapCleanWhy(_r.job, snappedFirst: _r.snappedFirst);
  await _tool(t, M6SwapTool.card);
  await _pump(t, 1700);
  expect(find.byType(MistakeCard), findsNothing, reason: 'clean job card');
  await _pickRight(t, L.whyRight[topic]!);
  await _pump(t, 3000);
}

/// A tampered wall played right (a look, report, the deck, reason).
Future<void> _tamperWall(WidgetTester t) async {
  final j = _r.job;
  if (j.brokenSeal != null) {
    await t.longPressAt(_geo.seal(j.brokenSeal!) * _k);
    await _pump(t, 300);
  }
  final pushHere = _r.pushHere && _r.deal.push == M6SwapPush.magnet;
  await _decide(t, start: false);
  if (pushHere) await _refuse(t, M6SwapPush.magnet);
  await waitChoiceDeck(t);
  final right = _onDeck(L.actRight);
  expect(right, hasLength(1), reason: 'the action deck');
  await pickChoice(t, right.single, proceed: false);
  await _pump(t, 700);
  await _pickRight(t, L.whyRight[m6SwapTamperWhy(j)]!);
  await _pump(t, 3000);
}

// --- pure helpers --------------------------------------------------------------
M6SwapJob _job({M6SwapMeter meter = M6SwapMeter.lcd, M6SwapSign sign = M6SwapSign.none, M6SwapSeal? seal, M6SwapSpot? magnet, int start = 1, int newStart = 2}) => M6SwapJob(
      meter: meter,
      sign: sign,
      brokenSeal: seal,
      magnetAt: magnet,
      tamperWord: 'Tamper',
      startScreen: start,
      newStart: newStart,
      kwhTenths: 41276,
      kwHundredths: 42,
      volt: 231,
      newKwhTenths: 12,
      decoys: const {M6SwapSpot.top: M6SwapDecoy.clip, M6SwapSpot.side: M6SwapDecoy.nest, M6SwapSpot.under: M6SwapDecoy.grommet},
      palette: 0,
      whyRoll: 0,
    );

M6SwapRun _run(List<M6SwapJob> jobs, {M6SwapPush push = M6SwapPush.photo, int pushJob = 0}) => M6SwapRun(M6SwapDeal(jobs: jobs, push: push, pushJob: pushJob));

/// A clean electronic job isolated right, swapped, ready for the new photo.
M6SwapRun _swapped() {
  final r = _run([_job(start: 0), _job(), _job()]);
  r.decide(start: true);
  r.snap();
  r.pull();
  r.test(M6SwapPoint.line);
  r.test(M6SwapPoint.load);
  r.test(M6SwapPoint.line);
  expect(r.openBox(), isNull);
  r.pushIn();
  return r;
}

void main() {
  group('rules', () {
    test('deals: 1–2 tampered of 3, distinct signs, a tamper screen only on an electronic meter, a clean electronic meter, his push where it fits; plays differ', () {
      final signs = <M6SwapSign>{};
      final meters = <M6SwapMeter>{};
      final pushes = <M6SwapPush>{};
      final starts = <int>{};
      final tamperCounts = <int>{};
      final spots = <M6SwapSpot>{};
      final seals = <M6SwapSeal>{};
      final plays = <String>{};
      for (var s = 0; s < 200; s++) {
        final d = m6SwapDeal(math.Random(s));
        expect(d.jobs, hasLength(3));
        final t = d.jobs.where((j) => j.tampered).toList();
        expect(t.length, inInclusiveRange(1, 2));
        tamperCounts.add(t.length);
        expect(t.map((j) => j.sign).toSet(), hasLength(t.length), reason: 'distinct signs');
        expect(d.jobs.any((j) => !j.tampered && j.meter == M6SwapMeter.lcd), isTrue, reason: 'a clean electronic meter');
        for (final j in d.jobs) {
          signs.add(j.sign);
          meters.add(j.meter);
          starts.add(j.startScreen);
          if (j.sign == M6SwapSign.screen) expect(j.meter, M6SwapMeter.lcd);
          expect(j.brokenSeal != null, j.sign == M6SwapSign.seal);
          expect(j.magnetAt != null, j.sign == M6SwapSign.magnet);
          if (j.magnetAt != null) {
            expect(j.magnetAt, isNot(M6SwapSpot.junction));
            spots.add(j.magnetAt!);
          }
          if (j.brokenSeal != null) seals.add(j.brokenSeal!);
          expect(j.decoys.keys.toSet(), {M6SwapSpot.top, M6SwapSpot.side, M6SwapSpot.under});
        }
        pushes.add(d.push);
        final pj = d.jobs[d.pushJob];
        expect(d.push == M6SwapPush.magnet ? pj.sign == M6SwapSign.magnet : !pj.tampered, isTrue, reason: 'seed $s');
        plays.add([for (final j in d.jobs) '${j.meter.name}${j.sign.name}${j.startScreen}'].join('|'));
      }
      expect(signs, M6SwapSign.values.toSet());
      expect(meters, M6SwapMeter.values.toSet());
      expect(pushes, M6SwapPush.values.toSet());
      expect(starts, {0, 1, 2, 3});
      expect(tamperCounts, {1, 2});
      expect(spots, {M6SwapSpot.top, M6SwapSpot.side, M6SwapSpot.under});
      expect(seals, M6SwapSeal.values.toSet());
      expect(plays.length, greaterThan(60));
    });

    test('look: only the cut seal swings loose; a magnet only where it is; the bypass joint only on a bypass job; the screens scroll; a disc meter has none', () {
      final r = _run([_job(sign: M6SwapSign.seal, seal: M6SwapSeal.terminal), _job(), _job()]);
      expect(r.tug(M6SwapSeal.body), isFalse);
      expect(r.tug(M6SwapSeal.terminal), isTrue);
      expect(r.look(M6SwapSpot.junction), M6SwapThing.cable);
      expect(r.look(M6SwapSpot.top), M6SwapThing.clip);
      expect(r.look(M6SwapSpot.side), M6SwapThing.nest);
      expect(r.look(M6SwapSpot.under), M6SwapThing.grommet);
      final m = _run([_job(sign: M6SwapSign.magnet, magnet: M6SwapSpot.side), _job(), _job()]);
      expect(m.look(M6SwapSpot.side), M6SwapThing.magnet);
      expect(m.look(M6SwapSpot.top), M6SwapThing.clip);
      final b = _run([_job(sign: M6SwapSign.bypass), _job(), _job()]);
      expect(b.look(M6SwapSpot.junction), M6SwapThing.bypass);
      // The screens: kW (start 1) → V → A → kWh → kW; the tamper screen only
      // on a tampered one, only by scrolling.
      final s = _run([_job(start: 1), _job(), _job()]);
      expect(s.face.screen, M6SwapScreen.kw);
      final seen = <M6SwapScreen>[];
      for (var i = 0; i < 4; i++) {
        expect(s.press(), isTrue);
        seen.add(s.face.screen);
      }
      expect(seen, [M6SwapScreen.volt, M6SwapScreen.amp, M6SwapScreen.kwh, M6SwapScreen.kw]);
      expect(s.face.text, '0.42');
      final ts = _run([_job(sign: M6SwapSign.screen, start: 0), _job(), _job()]);
      expect(ts.face.screen, M6SwapScreen.kwh);
      expect(ts.face.text, '04127.6');
      final cyc = <M6SwapScreen>[for (var i = 0; i < 5; i++) if (ts.press()) ts.face.screen];
      expect(cyc, contains(M6SwapScreen.tamper));
      expect(ts.face.screen, M6SwapScreen.kwh);
      final d = _run([_job(meter: M6SwapMeter.disc), _job(), _job()]);
      expect(d.face.screen, M6SwapScreen.drum);
      expect(d.face.text, '04127');
      expect(d.press(), isFalse);
    });

    test('decide: a change on a tampered meter and a report on a clean one are slips (he looks again); the right ones go on', () {
      final r = _run([_job(sign: M6SwapSign.seal, seal: M6SwapSeal.body), _job(), _job()]);
      expect(r.decide(start: true), Mk.startTamper);
      expect(r.stage, M6SwapStage.look);
      expect(r.decide(start: false), isNull);
      expect(r.stage, M6SwapStage.act);
      final c = _run([_job(), _job(), _job()]);
      expect(c.decide(start: false), Mk.falseReport);
      expect(c.stage, M6SwapStage.look);
      expect(c.decide(start: true), isNull);
      expect(c.stage, M6SwapStage.swap);
      expect(r.slips + c.slips, 2);
    });

    test('the action deck: the report closes the job; the bypass pulled by hand is deadly; the magnet, a reseal, a change, no report are slips', () {
      for (final a in M6SwapAct.values) {
        final r = _run([_job(sign: M6SwapSign.bypass), _job(), _job()]);
        r.decide(start: false);
        final m = r.act(a);
        switch (a) {
          case M6SwapAct.report:
            expect(m, isNull);
            expect(r.stage, M6SwapStage.closed);
            expect(r.closed, [true]);
            expect(r.caught, containsAll([L.caughtTamper, L.caughtBypass]));
          case M6SwapAct.pullBypass:
            expect(m, Mk.pullBypass);
            expect(m!.deadly, isTrue);
            expect(r.ended, isTrue);
          case M6SwapAct.removeMagnet:
          case M6SwapAct.reseal:
          case M6SwapAct.startAnyway:
          case M6SwapAct.noReport:
            expect(m, Mk.act(a));
            expect(m!.deadly, isFalse);
            expect(r.slips, 1);
            expect(r.stage, M6SwapStage.act, reason: 'the deck comes again');
        }
      }
    });

    test('isolation (X5): the box with the cut-out in = deadly; out but no 0 V, a 0 V on an unproved tester, no re-proof = slips; live-dead-live → the swap', () {
      final live = _run([_job(), _job(), _job()])..decide(start: true);
      expect(live.openBox(), Mk.liveSwap);
      expect(live.openBox() ?? live.deadly, Mk.liveSwap);
      expect(Mk.liveSwap.deadly, isTrue);

      final r = _run([_job(), _job(), _job()])..decide(start: true);
      expect(r.pull(), isTrue);
      expect(r.openBox(), Mk.noTest);
      final first = r.test(M6SwapPoint.load);
      expect(first.live, isFalse);
      expect(first.mistake, Mk.testFirst);
      expect(r.dead, isFalse, reason: 'an unproved 0 V counts for nothing');
      expect(r.test(M6SwapPoint.line).live, isTrue);
      expect(r.provedLive, isTrue);
      expect(r.test(M6SwapPoint.load).live, isFalse);
      expect(r.dead, isTrue);
      expect(r.openBox(), Mk.noReprove);
      r.test(M6SwapPoint.line);
      expect(r.reproved, isTrue);
      expect(r.openBox(), isNull);
      expect(r.swapped, isTrue);
      expect(r.slips, 3);
      expect(r.caught, isNot(contains(L.caughtIsolate)));

      // The carrier back in: the 0 V is gone.
      final b = _run([_job(), _job(), _job()])..decide(start: true);
      b.pull();
      b.test(M6SwapPoint.line);
      b.test(M6SwapPoint.load);
      b.test(M6SwapPoint.line);
      b.pushIn();
      expect(b.dead, isFalse);
      expect(b.test(M6SwapPoint.load).live, isTrue, reason: 'the load side is live with the carrier in');
      expect(b.openBox(), Mk.liveSwap);

      final clean = _swapped();
      expect(clean.caught, contains(L.caughtIsolate));
      expect(clean.slips, 0);
    });

    test('A9: the tester proved on the load contact while it is live (carrier in) counts; then pull → 0 V there → re-prove on the line → no slip', () {
      final r = _run([_job(), _job(), _job()])..decide(start: true);
      expect(r.test(M6SwapPoint.load).live, isTrue);
      expect(r.provedLive, isTrue, reason: 'any known live point proves the tester');
      expect(r.pull(), isTrue);
      final zero = r.test(M6SwapPoint.load);
      expect(zero.live, isFalse);
      expect(zero.mistake, isNull);
      expect(r.dead, isTrue);
      expect(r.test(M6SwapPoint.line).live, isTrue);
      expect(r.reproved, isTrue);
      expect(r.openBox(), isNull);
      expect(r.slips, 0);
      expect(r.caught, contains(L.caughtIsolate));
    });

    test('the idle hand never sweeps the tools in the procedure order', () {
      const procedure = <M6SwapTool?>[M6SwapTool.phone, null, M6SwapTool.tester, M6SwapTool.driver];
      const procedureCard = <M6SwapTool?>[...procedure, M6SwapTool.card];
      final seen = <String>{};
      for (var seed = 0; seed < 400; seed++) {
        final a = m6SwapHintOrder(seed, withCard: false);
        final b = m6SwapHintOrder(seed, withCard: true);
        expect(a.toSet(), procedure.toSet());
        expect(b.toSet(), procedureCard.toSet());
        expect(a, isNot(equals(procedure)));
        expect(b, isNot(equals(procedureCard)));
        seen.add(a.join(','));
      }
      expect(seen.length, greaterThan(10), reason: 'the order varies wall to wall');
    });

    test('photos: the electronic meter blanks once the cut-out is out; the job card wants both kWh photos (one slip a card); a disc drum counts', () {
      final r = _swapped();
      expect(r.face.screen, M6SwapScreen.volt, reason: 'the new meter wakes on its dealt screen');
      r.press();
      r.press();
      expect(r.face.screen, M6SwapScreen.kwh);
      expect(r.face.text, '00001.2');
      r.snap();
      expect(r.jobCard(), isNull);
      expect(r.closed, [true]);
      expect(r.caught, containsAll([L.caughtPhoto, L.caughtSnapFirst]));

      // Pulled before the photo: the screen is blank; that photo is no kWh.
      final b = _run([_job(start: 0), _job(), _job()])..decide(start: true);
      b.pull();
      expect(b.face.screen, M6SwapScreen.blank);
      b.snap();
      expect(b.oldPhoto!.screen, M6SwapScreen.blank);
      b.test(M6SwapPoint.line);
      b.test(M6SwapPoint.load);
      b.test(M6SwapPoint.line);
      b.openBox();
      b.pushIn();
      for (var i = 0; i < 2; i++) {
        b.press();
      }
      expect(b.face.screen, M6SwapScreen.kwh);
      b.snap();
      expect(b.jobCard(), Mk.photoScreen);
      expect(b.stage, M6SwapStage.closed);
      expect(b.closed, [false]);

      // No new photo at all.
      final n = _run([_job(start: 0), _job(), _job()])..decide(start: true);
      n.snap();
      n.pull();
      n.test(M6SwapPoint.line);
      n.test(M6SwapPoint.load);
      n.test(M6SwapPoint.line);
      n.openBox();
      expect(n.jobCard(), Mk.photoMissing);

      // A disc meter: the drum is the kWh reading, it never blanks.
      final d = _run([_job(meter: M6SwapMeter.disc), _job(), _job()])..decide(start: true);
      d.pull();
      expect(d.face.screen, M6SwapScreen.drum);
      d.snap();
      d.test(M6SwapPoint.line);
      d.test(M6SwapPoint.load);
      d.test(M6SwapPoint.line);
      d.openBox();
      d.pushIn();
      while (d.face.screen != M6SwapScreen.kwh) {
        d.press();
      }
      d.snap();
      expect(d.jobCard(), isNull);
      expect(d.caught, isNot(contains(L.caughtSnapFirst)));
    });

    test('next wall: three closed jobs finish the play; the per-wall state starts afresh', () {
      final r = _run([_job(sign: M6SwapSign.seal, seal: M6SwapSeal.body), _job(start: 3), _job(sign: M6SwapSign.magnet, magnet: M6SwapSpot.top)]);
      r.tug(M6SwapSeal.body);
      r.decide(start: false);
      r.act(M6SwapAct.report);
      r.nextJob();
      expect(r.jobIndex, 1);
      expect(r.tugged, isEmpty);
      expect(r.face.screen, M6SwapScreen.amp);
      r.decide(start: true);
      r.snap();
      r.press();
      r.snap();
      r.pull();
      r.test(M6SwapPoint.line);
      r.test(M6SwapPoint.load);
      r.test(M6SwapPoint.line);
      r.openBox();
      r.pushIn();
      while (r.face.screen != M6SwapScreen.kwh) {
        r.press();
      }
      r.snap();
      expect(r.jobCard(), isNull);
      r.nextJob();
      r.decide(start: false);
      r.act(M6SwapAct.report);
      r.nextJob();
      expect(r.finished, isTrue);
      expect(r.passed, isTrue);
      expect(r.closed, [true, true, true]);
    });

    test('listening takes his push\'s class (B1): both are slips', () {
      final r = _run([_job(), _job(), _job()]);
      expect(r.listen(M6SwapPush.photo), Mk.listenPhoto);
      expect(r.listen(M6SwapPush.magnet), Mk.listenMagnet);
      expect(Mk.listenPhoto.deadly || Mk.listenMagnet.deadly, isFalse);
      expect(r.slips, 2);
      expect(Mk.push(M6SwapPush.photo), Mk.listenPhoto);
      expect(Mk.push(M6SwapPush.magnet), Mk.listenMagnet);
    });

    test('the reasons fit what this job had', () {
      final lcd = _job(meter: M6SwapMeter.lcd);
      final disc = _job(meter: M6SwapMeter.disc);
      final topics = <M6SwapWhy>{};
      for (var roll = 0; roll < 6; roll++) {
        final l = M6SwapJob(
          meter: lcd.meter, sign: lcd.sign, brokenSeal: null, magnetAt: null, tamperWord: 'Tamper', startScreen: 0, newStart: 0,
          kwhTenths: 1, kwHundredths: 1, volt: 230, newKwhTenths: 0, decoys: lcd.decoys, palette: 0, whyRoll: roll,
        );
        topics.add(m6SwapCleanWhy(l, snappedFirst: true));
        expect(m6SwapCleanWhy(l, snappedFirst: false), isNot(M6SwapWhy.snapFirst));
      }
      expect(topics, {M6SwapWhy.oldPhoto, M6SwapWhy.isolate, M6SwapWhy.snapFirst});
      expect(m6SwapCleanWhy(disc, snappedFirst: true), isNot(M6SwapWhy.snapFirst));
      expect(m6SwapTamperWhy(_job(sign: M6SwapSign.seal)), M6SwapWhy.reportSeal);
      expect(m6SwapTamperWhy(_job(sign: M6SwapSign.magnet)), M6SwapWhy.reportMagnet);
      expect(m6SwapTamperWhy(_job(sign: M6SwapSign.screen)), M6SwapWhy.reportScreen);
      expect(m6SwapTamperWhy(_job(sign: M6SwapSign.bypass)), M6SwapWhy.bypass);
    });

    test('the action deck deals 1 right + 2 wrongs that fit the sign; the bypass pull only where there is a bypass', () {
      for (final sign in [M6SwapSign.seal, M6SwapSign.bypass, M6SwapSign.magnet, M6SwapSign.screen]) {
        final acts = <M6SwapAct>{};
        for (var k = 0; k < 40; k++) {
          final d = m6SwapActDeal(_job(sign: sign), math.Random(k));
          expect(d, hasLength(3));
          expect(d.where((o) => o.correct), hasLength(1));
          expect(d.map((o) => o.textBn).toSet(), hasLength(3));
          for (final o in d) {
            final a = m6SwapActOf(o.textBn);
            expect(a == M6SwapAct.report, o.correct);
            acts.add(a);
          }
        }
        expect(acts.contains(M6SwapAct.pullBypass), sign == M6SwapSign.bypass, reason: '$sign');
        final own = switch (sign) {
          M6SwapSign.seal => M6SwapAct.reseal,
          M6SwapSign.magnet => M6SwapAct.removeMagnet,
          M6SwapSign.bypass => M6SwapAct.pullBypass,
          _ => null,
        };
        if (own != null) {
          for (var k = 0; k < 10; k++) {
            expect(m6SwapActDeal(_job(sign: sign), math.Random(k)).map((o) => m6SwapActOf(o.textBn)), contains(own));
          }
        }
      }
    });

    test('three slips: the mark falls to 55, then 40', () {
      final r = _run([_job(), _job(), _job()]);
      for (var i = 0; i < 3; i++) {
        r.decide(start: false);
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.decide(start: false);
      expect(r.percent, 40);
    });

    test('English digits only; jol not pani; owner terms (ডেড, ON/OFF, no precomposed nukta); every mistake has its picture; the deadly set; keys unique', () {
      final all = <String>[
        L.title,
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.docket,
        L.start,
        L.report,
        L.cutSwap,
        L.cutWalk,
        L.photoOld,
        L.photoNew,
        L.cardTitle,
        L.cardOld,
        L.cardNew,
        L.testerLive,
        L.testerDead,
        L.sceneLook,
        ...L.stages,
        for (final t in M6SwapTool.values) L.tool(t),
        ...L.actRight,
        ...L.allActWrong,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6SwapPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtPhoto,
        L.caughtSnapFirst,
        L.caughtIsolate,
        L.caughtTamper,
        L.caughtBypass,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$|[।,!?])').hasMatch(l), isFalse, reason: 'ON/OFF in English: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp('এলটি|এইচটি|কেভি').hasMatch(l), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.pullBypass, Mk.liveSwap});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.10/m6_meter_swap_proof/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_meter_swap_proof/';
      final used = {for (final m in Mk.all) if (m.art.startsWith(dir)) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m6_meter_swap_proof').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6MeterSwapPacks.keys, ['do_6_10_b']);
    });

    test('the lesson words: pro tips 2 and 3 and point 4 behind the texts', () {
      // The lesson file keeps single code points; the app writes base + nukta.
      final lesson = File('tool/all_training_chapters_bn.json').readAsStringSync().replaceAll('\u09DF', '\u09AF\u09BC').replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC');
      for (final w in ['ইনকামিং) কাটআউট', 'ফাইনাল রিডিং', 'প্রাথমিক রিডিং', 'বাইপাস', 'চুম্বক', 'অবিলম্বে আপনার কর্তৃপক্ষকে রিপোর্ট', 'বিপজ্জনক এবং অপেশাদার পদ্ধতিতে ওয়্যারিং']) {
        expect(lesson.contains(w), isTrue, reason: w);
      }
      expect(Mk.liveSwap.textBn, contains('ইনকামিং কাটআউট'));
      expect(Mk.photoMissing.textBn, contains('ফাইনাল রিডিং'));
      expect(Mk.pullBypass.textBn, contains('অপেশাদার'));
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6SwapWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('act', [...L.actRight, ...L.allActWrong]);
      expectLibrary('act', L.actRight, L.allActWrong);
      expectSameLength('decide', [L.start, L.report]);
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('spoken lines: his exit is recorded; his two pushes and every new guide line (questions, praise, mistakes) are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect({for (final p in M6SwapPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newRivalLines, [
        'চুম্বক-টুম্বক পুরনো কথা! ওটা সরিয়ে মিটার বদলে দাও — রিপোর্টের ঝামেলা কে করে?',
        'ছবি-টবি ছাড়ো, রিডিং মুখে মনে রাখো — তাড়াতাড়ি বদলাও!',
      ]);
      for (final q in L.whyQ.values) {
        expect(L.newGuideLines, contains(q));
      }
      for (final p in M6SwapPush.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
        for (final a in L.coworker(p).asks.where((a) => a.startsWith('ও বলছে'))) {
          expect(L.newGuideLines, contains(a));
        }
      }
      for (final m in Mk.all) {
        expect(L.newGuideLines, contains(m.textBn), reason: m.key);
      }
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, L.allSet, L.fail]));
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_meter_swap_proof: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, below the header, above the tool row and clear of the guide', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M6SwapGeo.forScene(h, 0);
        final rects = <String, Rect>{
          for (final s in M6SwapSeal.values) 'seal ${s.name}': g.sealHit(s),
          for (final s in M6SwapSpot.values) 'spot ${s.name}': g.spotHit(s),
          'button': g.buttonHit,
          'box': g.boxHit,
          for (final p in M6SwapPoint.values) 'point ${p.name}': g.pointHit(p),
          'carrier in': g.carrierHit(true),
        };
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final all = {...rects, 'carrier out': g.carrierHit(false)};
        for (final e in all.entries) {
          final r = e.value;
          expect(r.left, greaterThanOrEqualTo(0), reason: '$h ${e.key}');
          expect(r.right, lessThanOrEqualTo(360), reason: '$h ${e.key}');
          expect(r.top, greaterThan(125), reason: 'h $h: ${e.key} below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: ${e.key} above the tool row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: ${e.key} under the guide');
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, g.groundY - 129, 360, g.groundY - 81)), isFalse, reason: 'h $h: ${e.key} under the bubble');
        }
        for (final set in [rects, {...rects}..remove('carrier in')..['carrier out'] = g.carrierHit(false)]) {
          final l = set.entries.toList();
          for (var i = 0; i < l.length; i++) {
            for (var j = i + 1; j < l.length; j++) {
              expect(l[i].value.overlaps(l[j].value), isFalse, reason: 'h $h: ${l[i].key} / ${l[j].key}');
            }
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

    testWidgets('the guide comes first: a tap does not skip him; then the decision and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6MeterSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.start), findsOneWidget);
      expect(_label(L.report), findsOneWidget);
      expect(find.text(L.docket), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askLook)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in M6SwapPush.values) {
      testWidgets('a clean play, every wall right (a reason each), the coworker refused (${push.name}) → pass, saved with stars', (t) async {
        final seed = _seedWhere((d) => d.push == push);
        final c = await _open(t, seed);
        for (var w = 0; w < 3; w++) {
          expect(_r.jobIndex, w);
          if (_r.job.tampered) {
            await _tamperWall(t);
          } else {
            await _cleanWall(t);
          }
          expect(find.byType(MistakeCard), findsNothing, reason: 'wall $w');
        }
        await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 4000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.10/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.10/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtTamper), findsOneWidget);
        expect(find.text(L.caughtPhoto), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the decision is two steps: a tap opens the preview and answers nothing; ✕ sets it aside; ✓ answers', (t) async {
      final seed = _seedWhere((d) => !d.jobs[0].tampered);
      final c = await _open(t, seed);
      await t.tap(_label(L.report));
      await _pump(t, 200);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_r.slips, 0);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 300);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsOneWidget);
      expect(_r.stage, M6SwapStage.look);
      await _decide(t, start: true);
      expect(_r.stage, M6SwapStage.swap);
      expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsNothing);
      await _close(t, c);
    });

    testWidgets('a report on a clean meter: the slip card; he looks again', (t) async {
      final seed = _seedWhere((d) => !d.jobs[0].tampered);
      final c = await _open(t, seed);
      await _decide(t, start: false);
      expect(find.text(Mk.falseReport.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.falseReport.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      expect(_r.stage, M6SwapStage.look);
      expect(_label(L.start), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => !d.jobs[0].tampered);
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _decide(t, start: false);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 500);
        }
      }
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the box opened with the cut-out in: the scene freezes first, then the card (deadly)', (t) async {
      final seed = _seedWhere((d) => !d.jobs[0].tampered && d.push == M6SwapPush.magnet);
      final c = await _open(t, seed);
      await _decide(t, start: true);
      await _openBox(t);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.liveSwap.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the bypass pulled by hand from the action deck: freeze, then the card (deadly)', (t) async {
      final seed = _seedWhere((d) => d.jobs[0].sign == M6SwapSign.bypass);
      final c = await _open(t, seed);
      await t.tapAt(_geo.spot(M6SwapSpot.junction) * _k);
      await _pump(t, 300);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is M6SwapLookPainter && (w.painter! as M6SwapLookPainter).thing == M6SwapThing.bypass), findsOneWidget);
      await _decide(t, start: false);
      await waitChoiceDeck(t);
      final pull = _onDeck(L.actWrong[M6SwapAct.pullBypass]!);
      expect(pull, hasLength(1), reason: 'the bypass job deals its own wrong act');
      await pickChoice(t, pull.single, proceed: false);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.pullBypass.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a slip on the action deck: its card, then the deck again', (t) async {
      final seed = _seedWhere((d) => d.jobs[0].tampered && d.jobs[0].sign != M6SwapSign.bypass && !(d.push == M6SwapPush.magnet && d.pushJob == 0));
      final c = await _open(t, seed);
      await _decide(t, start: false);
      await waitChoiceDeck(t);
      final wrong = _onDeck(L.allActWrong);
      expect(wrong, hasLength(2));
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      expect(_onDeck(L.actRight), hasLength(1), reason: 'the deck again');
      await _close(t, c);
    });

    testWidgets('the photo push: the phone waits for him (no photo), listening is a slip; the cut-out out blanks the screen', (t) async {
      final seed = _seedWhere((d) => d.push == M6SwapPush.photo && d.pushJob == 0 && d.jobs[0].meter == M6SwapMeter.lcd);
      final c = await _open(t, seed);
      // A slow look first: longer than his 1.2–2.4 s timer; he still waits.
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'never on the timer');
      await _decide(t, start: true);
      await _tool(t, M6SwapTool.phone);
      expect(_r.oldPhoto, isNull, reason: 'the phone waited');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 1000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final w = _onDeck(L.coworkerPhoto.wrong);
      expect(w, isNotEmpty);
      await pickChoice(t, w.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.listenPhoto.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listenPhoto.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      // Pulled first: the electronic screen goes blank, and so does the photo.
      await _pull(t);
      expect(_r.face.screen, M6SwapScreen.blank);
      await _tool(t, M6SwapTool.phone);
      expect(_r.oldPhoto?.screen, M6SwapScreen.blank);
      expect(find.byKey(const ValueKey('photo-old')), findsOneWidget);
      // The carrier back: the screen wakes; snap again.
      await _pushIn(t);
      expect(_r.face.screen, isNot(M6SwapScreen.blank));
      await _close(t, c);
    });

    testWidgets('the photo push cannot be skipped: with no old photo the box waits for him too', (t) async {
      final seed = _seedWhere((d) => d.push == M6SwapPush.photo && d.pushJob == 0);
      final c = await _open(t, seed);
      await _decide(t, start: true);
      await _pull(t);
      await _tool(t, M6SwapTool.tester);
      await _testAt(t, M6SwapPoint.line);
      await _testAt(t, M6SwapPoint.load);
      await _testAt(t, M6SwapPoint.line);
      await _openBox(t);
      expect(_r.swapped, isFalse, reason: 'the box waited');
      await _refuse(t, M6SwapPush.photo);
      expect(_r.caught, contains(L.caughtCall));
      await _openBox(t);
      expect(_r.swapped, isTrue);
      await _close(t, c);
    });

    testWidgets('the ◆ on the table and its reason deck: the scene takes no touch', (t) async {
      final seed = _seedWhere((d) => d.jobs[0].sign == M6SwapSign.seal && !(d.push == M6SwapPush.magnet && d.pushJob == 0));
      final c = await _open(t, seed);
      await _decide(t, start: false);
      await waitChoiceDeck(t);
      await pickChoice(t, _onDeck(L.actRight).single, proceed: false);
      await _pump(t, 700);
      await waitChoiceDeck(t);
      // A tug above the deck does nothing now.
      await t.longPressAt(_geo.seal(M6SwapSeal.body) * _k);
      await _pump(t, 300);
      expect(_r.tugged, isEmpty);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[M6SwapWhy.reportSeal]!);
      await _pump(t, 3000);
      expect(_r.jobIndex, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a seal tug and a close look draw what is there; a missed tester (no 0 V) is a slip', (t) async {
      final seed = _seedWhere((d) => !d.jobs[0].tampered && d.jobs[0].meter == M6SwapMeter.lcd && !(d.push == M6SwapPush.photo && d.pushJob == 0));
      final c = await _open(t, seed);
      await t.longPressAt(_geo.seal(M6SwapSeal.terminal) * _k);
      await _pump(t, 300);
      expect(_r.tugged, {M6SwapSeal.terminal});
      await t.tapAt(_geo.spot(M6SwapSpot.under) * _k);
      await _pump(t, 300);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is M6SwapLookPainter), findsOneWidget);
      await _pump(t, 2800);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is M6SwapLookPainter), findsNothing, reason: 'the look closes by itself');
      await _decide(t, start: true);
      await _toKwh(t);
      await _tool(t, M6SwapTool.phone);
      await _pull(t);
      await _openBox(t);
      expect(find.text(Mk.noTest.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noTest.key);
      expect(_r.swapped, isFalse);
      await _close(t, c);
    });

    testWidgets('gesture hand: shows while the wall waits (no press), none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.jobs[0].tampered && !(d.push == M6SwapPush.magnet && d.pushJob == 0));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the wall');
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.emptyWall * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      await _decide(t, start: false);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _close(t, c);
    });
  });
}
