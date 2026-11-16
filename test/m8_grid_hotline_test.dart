// Lesson 8.4 (গ্রিড কোড), কাজ 1 "হটলাইন বাজছে": the rules (the dealt incidents,
// the frequency path, the hotline and the black phone, the state question,
// the register's rotation, the race to 49.0, the customer), the libraries, the
// coworker's three pushes (listening = a slip; the level has no deadly act),
// the drawn places, and the level in the shell: the guide first, a full clean
// play (the state question and its reason, the hotline lifted, SLDC's caption,
// the register, the switches twisted, the coworker refused, a reason each
// incident, the customer), the black phone and a missed ring as slips, the
// race lost, three slips, and the gesture hand that shows how (never what)
// only while the level waits.
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
import 'package:slm_flutter/features/game/m8_grid_hotline.dart';
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
  rungId: '8.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8GridHotlinePacks['do_8_4_a']!;
typedef L = M8GridHotlineLines;
typedef Mk = M8GridHotlineMistakes;

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

/// Pumps until [ok] holds (false on a timeout).
Future<bool> _until(WidgetTester t, bool Function() ok, {int maxMs = 12000}) async {
  for (var ms = 0; ms < maxMs; ms += 50) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 50));
  }
  return ok();
}

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

/// A call's own deck (no proceed): the card from [texts] that is on screen.
Future<void> _pickOwn(WidgetTester t, List<String> texts) async {
  await waitChoiceDeck(t);
  final r = _textsOnScreen(texts);
  expect(r, hasLength(1), reason: texts.first);
  await pickChoice(t, r.single, proceed: false);
  await _pump(t, 500);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M8GridGeo get _geo => M8GridGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8GridRun get _live => M8GridHotlineProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

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

/// Twist a bay's switch clockwise by [quarters] of its quarter turn.
Future<void> _twist(WidgetTester t, int bay, {double quarters = 1.2}) async {
  final k = _geo.knob(bay);
  const r = 14.0;
  Offset at(double a) => (k + Offset(math.cos(a), math.sin(a)) * r) * _k;
  final total = quarters * math.pi / 2;
  final g = await t.startGesture(at(kM8KnobOn));
  for (var i = 1; i <= 12; i++) {
    await g.moveTo(at(kM8KnobOn + total * i / 12));
    await t.pump(const Duration(milliseconds: 16));
  }
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8GridHotlinePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8GridDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t, M8Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// The hotline lifted (once it rings), the order read: the shed beat.
Future<void> _toShed(WidgetTester t) async {
  expect(await _until(t, () => _live.stage == M8Stage.ring && _live.hotOn, maxMs: 16000), isTrue, reason: 'the hotline rings');
  await _drag(t, _geo.hotline.center, _geo.hotline.center + const Offset(0, -46));
  expect(_live.stage, M8Stage.order);
  expect(await _until(t, () => _live.stage == M8Stage.shed, maxMs: 6000), isTrue, reason: 'SLDC\'s caption is read');
}

/// One incident played right (the coworker refused if he is dealt on it).
Future<void> _playIncident(WidgetTester t, M8Deal d, int i) async {
  final inc = d.incidents[i];
  expect(_live.index, i);
  if (d.askIncident == i) {
    expect(await _until(t, () => _live.stage == M8Stage.state, maxMs: 12000), isTrue, reason: 'the state question');
    await _pickOwn(t, L.states[d.readState]!);
    expect(find.text(MistakeLines.slipHead), findsNothing);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the state reason');
    await _pump(t, 500);
    await _pickRight(t, L.stateWhyRight[d.readState]!);
    await _pump(t, 1800);
  }
  await _toShed(t);
  // The register: open, read, close.
  await _tapAt(t, _geo.register.center);
  expect(M8GridHotlineProbe.regOpen, isTrue);
  await _tapAt(t, _geo.registerHandle.center);
  expect(M8GridHotlineProbe.regOpen, isFalse);
  for (final b in inc.rightBays) {
    for (var attempt = 0; attempt < 3 && !_live.off[b]; attempt++) {
      await _twist(t, b);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty && !_live.off[b]) await _refuse(t, d.push);
    }
    expect(_live.off[b], isTrue, reason: 'bay $b OFF');
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'incident $i');
  expect(_live.stage, M8Stage.after);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the shed reason');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[_live.whyNow]!);
  // The customer rings.
  expect(await _until(t, () => _live.stage == M8Stage.callRing, maxMs: 4000), isTrue);
  await _drag(t, _geo.blackPhone.center, _geo.blackPhone.center + const Offset(0, -46));
  expect(_live.stage, M8Stage.callSay);
  await _pickOwn(t, L.consumerRight);
  await _pump(t, 2600);
}

M8Incident _incOf({
  int n = 1,
  M8BlackMode black = M8BlackMode.none,
  int rings = 3,
  M8Why why = M8Why.rotation,
  List<int>? bayArea,
  List<List<bool>>? marks,
}) =>
    M8Incident(
      cause: M8Cause.peak,
      fStart: 49.97,
      fRing: 49.70,
      driftMs: 4000,
      blackMode: black,
      rings: rings,
      n: n,
      areas: const ['বাজার', 'স্টেশন', 'নতুনপাড়া', 'কলেজ', 'বটতলা', 'রথতলা'],
      marks: marks ??
          [
            for (var r = 0; r < 6; r++)
              if (r < n) [false, false, false] else [r.isEven, true, false],
          ],
      bayArea: bayArea ?? const [0, 1, 2, 3, 4, 5],
      day: 12,
      why: why,
    );

M8GridRun _runOf({M8Incident? a, M8Incident? b, M8State read = M8State.low, int ask = 0}) => M8GridRun(M8Deal(
      incidents: [a ?? _incOf(), b ?? _incOf(n: 2)],
      askIncident: ask,
      readState: read,
      coworkerIncident: 1,
      push: M8Push.myth,
    ));

void main() {
  group('rules', () {
    test('deals: two incidents; exactly n unshed areas; the register order is fixed, the panel shuffled; paths and rings in range; plays differ', () {
      final seen = <String>{};
      final whys = <M8Why>{};
      final reads = <M8State>{}, pushes = <M8Push>{}, modes = <M8BlackMode>{}, causes = <M8Cause>{};
      final askAt = <int>{}, cwAt = <int>{}, rightPos = <int>{}, ns = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m8GridDeal(math.Random(s));
        expect(d.incidents, hasLength(2));
        expect(d.readState, isNot(M8State.danger), reason: 'the danger card is only ever the wrong one');
        reads.add(d.readState);
        pushes.add(d.push);
        askAt.add(d.askIncident);
        cwAt.add(d.coworkerIncident);
        expect(d.incidents[0].why, isNot(d.incidents[1].why), reason: 'two different reasons');
        for (final inc in d.incidents) {
          expect(inc.n, inInclusiveRange(1, 2));
          ns.add(inc.n);
          expect(inc.areas, hasLength(6));
          expect(inc.areas.toSet(), hasLength(6));
          final poolIdx = [for (final a in inc.areas) kM8AreaPool.indexOf(a)];
          expect(poolIdx.every((x) => x >= 0), isTrue);
          expect([...poolIdx]..sort(), poolIdx, reason: 'the register lists areas in a fixed order');
          expect([...inc.bayArea]..sort(), [0, 1, 2, 3, 4, 5], reason: 'every area behind exactly one bay');
          expect(inc.marks.where((r) => !r.any((m) => m)), hasLength(inc.n), reason: 'exactly n unshed areas');
          expect(inc.marks.where((r) => r.any((m) => m)), hasLength(6 - inc.n));
          expect(inc.rightBays, hasLength(inc.n));
          rightPos.addAll(inc.rightBays);
          expect(inc.fStart, inInclusiveRange(49.93, 50.03));
          expect(inc.fRing, inInclusiveRange(49.60, 49.82));
          expect(inc.driftMs, inInclusiveRange(3500, 5500));
          expect(inc.rings, inInclusiveRange(3, 4));
          if (inc.why == M8Why.hotline) expect(inc.blackMode, isNot(M8BlackMode.none), reason: 'the hotline question needs the black phone');
          expect(inc.why, isNot(M8Why.state));
          modes.add(inc.blackMode);
          causes.add(inc.cause);
          whys.add(inc.why);
          expect(inc.customer, inInclusiveRange(0, L.customerCaptions.length - 1));
        }
        expect(d.incidents[1].day, d.incidents[0].day + 1, reason: 'the second incident is a new register day');
        seen.add([for (final i in d.incidents) '${i.n}${i.blackMode.index}${i.bayArea.join()}${i.areas.join(',')}${i.marks.expand((r) => r).map((b) => b ? 1 : 0).join()}${i.fRing}'].join('|'));
      }
      expect(seen.length, greaterThan(290));
      expect(reads, {M8State.normal, M8State.low});
      expect(pushes, M8Push.values.toSet());
      expect(modes, M8BlackMode.values.toSet());
      expect(causes, M8Cause.values.toSet());
      expect(whys, {M8Why.rotation, M8Why.noQuestion, M8Why.hotline});
      expect(askAt, {0, 1});
      expect(cwAt, {0, 1});
      expect(ns, {1, 2});
      expect(rightPos, {0, 1, 2, 3, 4, 5}, reason: 'the right bays are never in a fixed place');
    });

    test('the frequency: the reading fits the dealt state; the race crosses 49.0 at the window and runs on past it; two decimals', () {
      for (var s = 0; s < 200; s++) {
        final d = m8GridDeal(math.Random(s));
        for (final inc in d.incidents) {
          // The question is asked at the start (normal, inside the lesson's
          // band) or after the drift (low, under 49.90).
          expect(inc.fStart, inInclusiveRange(49.90, 50.05));
          expect(inc.fRing, lessThan(49.90));
          expect(inc.fRing, greaterThan(kM8Danger), reason: 'never already in danger');
          expect(inc.raceFreq(0), closeTo(inc.fRing, 1e-9));
          expect(inc.raceFreq(inc.raceMs.toDouble()), closeTo(kM8Danger, 1e-6), reason: 'crosses 49.0 exactly at the window');
          expect(inc.raceFreq(inc.raceTotalMs), closeTo(kM8RaceFloor, 1e-9));
          expect(inc.raceFreq(inc.raceTotalMs * 3), closeTo(kM8RaceFloor, 1e-9));
          expect(inc.raceFreq(inc.raceMs / 2), greaterThan(kM8Danger));
          expect(inc.raceTotalMs, greaterThan(inc.raceMs));
          expect(inc.raceMs, inc.n == 1 ? kM8RaceOneMs : kM8RaceTwoMs);
          expect(inc.ringTotalMs, inc.missAtMs + kM8Redial * kM8RingMs);
          expect(inc.leadMs, inc.blackMode == M8BlackMode.first ? kM8BlackLead * kM8RingMs : 0);
        }
      }
      expect(M8MeterPainter.text(49.7), '49.70');
      expect(M8MeterPainter.text(50), '50.00');
      expect(M8MeterPainter.text(48.944), '48.94');
    });

    test('the state question: the dealt reading is right, any other card a slip; the danger card is never right', () {
      for (final read in [M8State.normal, M8State.low]) {
        final r = _runOf(read: read);
        if (read == M8State.low) {
          expect(r.stage, M8Stage.watch, reason: 'a low reading is asked after the drift');
          r.driftDone();
        }
        expect(r.stage, M8Stage.state);
        final wrong = M8State.values.where((s) => s != read).toList();
        expect(r.answerState(wrong[0]), Mk.state(read));
        expect(r.answerState(wrong[1]), Mk.state(read));
        expect(r.slips, 2);
        expect(r.answerState(M8State.danger), isNot(isNull));
        expect(r.slips, 3);
        expect(r.stateAnswered, isFalse);
        expect(r.answerState(read), isNull);
        expect(r.stateAnswered, isTrue);
        expect(r.caught, contains(L.caughtState));
        r.afterState();
        expect(r.stage, read == M8State.normal ? M8Stage.watch : M8Stage.ring, reason: 'a normal reading goes on to the drift, a low one to the ring');
      }
      expect(Mk.state(M8State.low), Mk.stateLow);
      expect(Mk.state(M8State.normal), Mk.stateNormal);
      // Only the hosting incident asks, and only once a play.
      final r = _runOf(read: M8State.low, ask: 1);
      expect(r.askHere, isFalse);
      r.driftDone();
      expect(r.stage, M8Stage.ring, reason: 'the first incident has no question');
    });

    test('the ring: the hotline is lifted once it rings; the black phone while it rings is a slip; a miss is a slip once and the hotline still lifts', () {
      final first = _incOf(black: M8BlackMode.first);
      final r = _runOf(a: first, ask: 1)..driftDone();
      expect(r.stage, M8Stage.ring);
      expect(r.hotOn, isFalse, reason: 'the black phone leads');
      expect(r.blackOn, isTrue);
      expect(r.lift(M8Phone.hot), M8Lift.ignored, reason: 'the hotline is not ringing yet');
      expect(r.lift(M8Phone.black), M8Lift.ignored, reason: 'the black phone alone is no slip');
      expect(r.slips, 0);
      r.hotStarts();
      expect(r.hotOn, isTrue);
      expect(r.lift(M8Phone.black), M8Lift.blackSlip);
      expect(r.blackSlip(), Mk.blackPhone);
      expect(r.slips, 1);
      expect(r.ringExpired(), Mk.ringMissed);
      expect(r.ringExpired(), isNull, reason: 'once an incident');
      expect(r.slips, 2);
      expect(r.lift(M8Phone.hot), M8Lift.hot);
      expect(r.stage, M8Stage.order);
      expect(r.caught, isNot(contains(L.caughtHot)), reason: 'not a clean ring');
      expect(r.ringExpired(), isNull);
      // A clean ring.
      final c = _runOf(a: _incOf(black: M8BlackMode.together), ask: 1)..driftDone();
      expect(c.hotOn && c.blackOn, isTrue);
      expect(c.lift(M8Phone.hot), M8Lift.hot);
      expect(c.slips, 0);
      expect(c.caught, contains(L.caughtHot));
      expect(c.blackOn, isFalse, reason: 'the customer rings off');
      // Hotline alone.
      final h = _runOf(a: _incOf(), ask: 1)..driftDone();
      expect(h.blackOn, isFalse);
      expect(h.hotOn, isTrue);
      expect(h.lift(M8Phone.black), M8Lift.blackSlip);
    });

    test('the shed: a recent area springs back as a slip; the right feeders ending it; the race is lost once and the round still ends; the order is read first', () {
      for (final n in [1, 2]) {
        final inc = _incOf(n: n, bayArea: const [3, 1, 4, 0, 5, 2]);
        final r = _runOf(a: inc, ask: 1)
          ..driftDone()
          ..lift(M8Phone.hot);
        expect(r.shed(0), isNull, reason: 'not before the order is read');
        r.orderRead();
        expect(r.stage, M8Stage.shed);
        final right = inc.rightBays;
        expect(right, hasLength(n));
        final wrongBay = [for (var b = 0; b < 6; b++) if (!right.contains(b)) b].first;
        expect(r.shed(wrongBay), Mk.recentShed);
        expect(r.off[wrongBay], isFalse, reason: 'springs back');
        expect(r.stage, M8Stage.shed);
        expect(r.recentSlips, 1);
        expect(r.raceLose(), Mk.raceLost);
        expect(r.raceLose(), isNull, reason: 'once an incident');
        expect(r.slips, 2);
        for (final (i, b) in right.indexed) {
          expect(r.stage, M8Stage.shed);
          expect(r.shed(b), isNull);
          expect(r.off[b], isTrue);
          expect(r.shed(b), isNull, reason: 'already OFF');
          if (i < right.length - 1) expect(r.stage, M8Stage.shed, reason: 'n = $n: not done until all are OFF');
        }
        expect(r.stage, M8Stage.after);
        expect(r.caught, isNot(contains(L.caughtShed)), reason: 'not in time');
        expect(r.caught, isNot(contains(L.caughtRotate)), reason: 'a recent area was tried');
        expect(r.raceLose(), isNull, reason: 'the race is over');
      }
      // A clean one.
      final inc = _incOf(n: 2);
      final c = _runOf(a: inc, ask: 1)
        ..driftDone()
        ..lift(M8Phone.hot)
        ..orderRead();
      for (final b in inc.rightBays) {
        c.shed(b);
      }
      expect(c.stage, M8Stage.after);
      expect(c.caught, containsAll([L.caughtShed, L.caughtRotate]));
      expect(c.slips, 0);
    });

    test('the customer: the myth, a local-fault story or arguing is a slip; the lesson\'s line closes the incident; then the next incident', () {
      final c = _runOf(a: _incOf(), ask: 1)
        ..driftDone()
        ..lift(M8Phone.hot)
        ..orderRead()
        ..shed(0);
      expect(c.stage, M8Stage.after);
      expect(c.consumerSay(right: true), isNull, reason: 'the phone has not been lifted');
      expect(c.consumerDone, isFalse);
      c.afterReason();
      expect(c.stage, M8Stage.callRing);
      expect(c.lift(M8Phone.hot), M8Lift.ignored);
      expect(c.lift(M8Phone.black), M8Lift.call);
      expect(c.consumerSay(right: false), Mk.consumerWrong);
      expect(c.consumerSay(right: true), isNull);
      expect(c.consumerDone, isTrue);
      expect(c.caught, contains(L.caughtExplain));
      expect(c.slips, 1);
      c.next();
      expect(c.index, 1);
      expect(c.off.every((o) => !o), isTrue, reason: 'a new incident');
      expect(c.thorough, isTrue, reason: 'each incident counts its own slips');
      expect(c.stage, M8Stage.watch);
    });

    test('the reason that fits: the hotline question only after a clean hotline', () {
      final inc = _incOf(black: M8BlackMode.together, why: M8Why.hotline);
      final clean = _runOf(a: inc, ask: 1)..driftDone();
      expect(clean.whyNow, M8Why.hotline);
      final slipped = _runOf(a: inc, ask: 1)..driftDone();
      slipped.lift(M8Phone.black);
      slipped.blackSlip();
      expect(slipped.whyNow, M8Why.noQuestion, reason: 'it was not the first phone lifted');
      final missed = _runOf(a: inc, ask: 1)..driftDone();
      missed.ringExpired();
      expect(missed.whyNow, M8Why.noQuestion);
      expect(_runOf(a: _incOf(why: M8Why.rotation), ask: 1).whyNow, M8Why.rotation);
    });

    test('no deadly act in this level; listening to him is a slip (X2/B1); three slips fail; the mark', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'rulings M8-1 / M8-4: slips only');
      expect(Mk.push(M8Push.myth), Mk.pushMyth);
      expect(Mk.push(M8Push.ask), Mk.pushAsk);
      expect(Mk.push(M8Push.book), Mk.pushBook);
      final r = _runOf(ask: 1);
      r.pushSlip(Mk.pushAsk);
      r.pushSlip(Mk.pushBook);
      expect(r.percent, 70);
      expect(r.thorough, isFalse);
      r.pushSlip(Mk.pushMyth);
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.done, isFalse);
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.consumerHeld,
        L.orderLine(1),
        L.orderLine(2),
        ...L.customerCaptions,
        L.sldcTag,
        L.customerTag,
        L.sceneLabel,
        L.registerLabel,
        L.registerHead,
        for (var n = 1; n <= 2; n++) L.incidentName(n),
        L.date(12),
        for (final l in L.states.values) ...l,
        ...L.consumerRight,
        ...L.consumerWrong,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.tapWhy,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8Push.values) L.callHeld(p),
        for (final a in kM8AreaPool) a,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtState,
        L.caughtHot,
        L.caughtShed,
        L.caughtRotate,
        L.caughtExplain,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,(—।])পানি').hasMatch(l), isFalse, reason: 'জল, never পানি: $l');
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ(?!িস)|সুইচ অন|এলটি|এইচটি|কেভি|AB বন্ধ').hasMatch(l), isFalse, reason: 'ON/OFF, LT, HT, kV in English letters; AB লাগানো: $l');
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta form: $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.4/m8_grid_hotline/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 4));
        expect(m.deadly, isFalse);
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_grid_hotline/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8GridHotlinePacks.keys, ['do_8_4_a']);
      // The lesson's numbers on screen.
      expect(Mk.stateNormal.textBn, contains('49.90'));
      expect(Mk.stateNormal.textBn, contains('50.05'));
      expect(Mk.raceLost.textBn, contains('49.0'));
    });

    test('libraries: same length, big enough, never a rule marked wrong; the decks alike', () {
      expectSameLength('states', [for (final l in L.states.values) ...l]);
      for (final l in L.states.values) {
        expect(l.length, greaterThanOrEqualTo(2));
      }
      expectSameLength('consumer', [...L.consumerRight, ...L.consumerWrong]);
      expectLibrary('consumer', L.consumerRight, L.consumerWrong);
      expect(L.consumerRight.first, contains('এটা লোকাল ফল্ট নয়, ওপর থেকে গ্রিড বাঁচাতে'), reason: 'the lesson\'s line');
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in [M8Why.rotation, M8Why.noQuestion, M8Why.hotline]) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
      }
      for (final s in [M8State.normal, M8State.low]) {
        expectLibrary('state why $s', L.stateWhyRight[s]!, L.myths);
      }
      expect(L.stateWhyRight.containsKey(M8State.danger), isFalse);
      expect(L.whyQ[M8Why.state], isNotEmpty);
      for (final w in [...L.whyRight.entries, ...L.stateWhyRight.entries]) {
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(w.value, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expect(L.coworkerMyth.line, 'আমাদের ছোট সাবস্টেশন বন্ধ করলে গ্রিডের কি বা এসে যাবে?', reason: 'the lesson\'s myth, word for word');
      expect(L.coworkerMyth.right, contains('না, হাজারটা ছোট ফিডার বন্ধ হলে তবেই ফ্রিকোয়েন্সি ফেরে'));
      expect(L.coworkerAsk.right, contains('না, অর্ডার এলে প্রশ্ন নয়, আগে লাইন কাটব'));
      expect(L.coworkerBook.right, contains('না, পালা করেই কাটব, খাতা দেখে মিলিয়ে'));
    });

    test('spoken lines: his exit is recorded; his three pushes and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'আমাদের ছোট সাবস্টেশন বন্ধ করলে গ্রিডের কি বা এসে যাবে?',
        'আরে আগে SLDC-কে ফোন করে জিজ্ঞেস করো, কেন কাটবে!',
        'খাতা দেখার সময় নেই, রোজ যেটা কাটি সেটাই কাটো!',
      ]);
      expect({for (final p in M8Push.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            L.consumerHeld,
            ...L.whyQ.values,
            for (final p in M8Push.values) L.callHeld(p),
            L.allSet,
            L.quick,
            L.fail,
            ...L.tapWhy,
            for (final cw in L.allCoworkers) ...cw.asks,
            for (final m in Mk.all) m.textBn,
          }));
      // The silent drawn figures are never spoken (M8-10).
      expect(L.newGuideLines, isNot(contains(L.orderLine(1))));
      for (final c in L.customerCaptions) {
        expect(L.newGuideLines, isNot(contains(c)));
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_grid_hotline: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas: on the scene, below the header, clear of the guide and of each other; the register page clears the guide', () {
      for (final h in [640.0, 700.0, 780.0, 850.0, 900.0]) {
        final g = M8GridGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final areas = <Rect>[g.hotline, g.blackPhone, g.register, g.trainee, for (var i = 0; i < kM8Bays; i++) g.switchHit(i)];
        for (final r in areas) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the floor');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
        }
        for (final (i, a) in areas.indexed) {
          if (a == g.trainee) continue;
          for (final b in areas.skip(i + 1)) {
            if (b == g.trainee) continue;
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        for (var i = 0; i < kM8Bays; i++) {
          expect(g.switchHit(i).top, greaterThan(g.bay(i).top), reason: 'the switch inside its bay');
          expect(g.switchHit(i).bottom, lessThan(g.bay(i).bottom));
          expect(g.bay(i).overlaps(guide), isFalse, reason: 'h $h: bay $i under the guide');
        }
        expect(g.bay(5).right, lessThanOrEqualTo(360));
        expect(g.registerPanel.overlaps(guide), isFalse, reason: 'h $h: the open register clears the guide');
        expect(g.registerPanel.height, greaterThan(190), reason: 'h $h: room for six rows');
        expect(g.registerHandle.height, greaterThanOrEqualTo(30));
        expect(g.meter.bottom, lessThan(g.registerPanel.top), reason: 'the meter stays in view over the register');
        expect(g.window.bottom, lessThan(g.baysTop));
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

    testWidgets('the guide comes first: a tap does not skip him; then the control room', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8GridHotlinePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == L.sceneLabel), findsOneWidget);
      expect(M8GridHotlineProbe.freq!(), closeTo(m8GridDeal(math.Random(3)).incidents[0].fStart, 0.2));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    // A play whose first incident hosts a normal reading (the deck opens at
    // once), the coworker on the first, black phone first.
    final seedNormal = _seedWhere((d) => d.readState == M8State.normal && d.askIncident == 0 && d.coworkerIncident == 0 && d.incidents[0].blackMode == M8BlackMode.first);
    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, seedNormal);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askState)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // A play with a low reading asked in the second incident, the coworker
    // on the second, the hotline alone first and both phones second.
    final seedLow = _seedWhere((d) => d.readState == M8State.low && d.askIncident == 1 && d.coworkerIncident == 1 && d.incidents[1].blackMode == M8BlackMode.together && d.incidents[0].n == 2);
    for (final seed in [seedNormal, seedLow]) {
      testWidgets('flow (seed $seed): two incidents, the state question, the hotline, the register, the switches, reasons, the customer; he is refused → pass', (t) async {
        final d = m8GridDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 2; i++) {
          await _playIncident(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.4/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.4/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtState), findsOneWidget);
        expect(find.text(L.caughtHot), findsOneWidget);
        expect(find.text(L.caughtRotate), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a wrong card on the state deck is a slip and the deck stays; the right card puts ◆ on the table and asks why', (t) async {
      final d = m8GridDeal(math.Random(seedNormal));
      final c = await _open(t, seedNormal);
      expect(_live.stage, M8Stage.state);
      await waitChoiceDeck(t);
      final wrong = L.states[M8State.low]!.where((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty).single;
      await pickChoice(t, wrong, proceed: false);
      await _pump(t, 700);
      expect(find.text(Mk.stateNormal.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.stateNormal.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.stage, M8Stage.state, reason: 'the same question goes on');
      expect(find.byType(ChoiceDeck), findsOneWidget);
      await _pickOwn(t, L.states[d.readState]!);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      expect(find.text(L.whyQ[M8Why.state]!), findsWidgets);
      await _close(t, c);
    });

    // The hotline alone and the black phone together, the state question in
    // the other incident.
    final seedBoth = _seedWhere((d) => d.askIncident == 1 && d.coworkerIncident == 1 && d.incidents[0].blackMode == M8BlackMode.together && d.incidents[0].n == 1);
    testWidgets('the black phone while the hotline rings is a slip and springs back; the hotline then lifts and the order shows as a caption', (t) async {
      final c = await _open(t, seedBoth);
      expect(await _until(t, () => _live.stage == M8Stage.ring && _live.hotOn, maxMs: 14000), isTrue);
      expect(_phonesNow().hotRinging && _phonesNow().blackRinging, isTrue, reason: 'both ring');
      await _drag(t, _geo.blackPhone.center, _geo.blackPhone.center + const Offset(0, -46));
      await _pump(t, 400);
      expect(find.text(Mk.blackPhone.textBn), findsOneWidget);
      expect(_phonesNow().blackLift, 0, reason: 'springs back');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.blackPhone.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.stage, M8Stage.ring, reason: 'the same ring goes on');
      await _drag(t, _geo.hotline.center, _geo.hotline.center + const Offset(0, -46));
      expect(_live.stage, M8Stage.order);
      expect(find.textContaining(L.orderLine(_live.inc.n)), findsOneWidget, reason: 'SLDC\'s order as a caption');
      expect(find.textContaining(L.sldcTag), findsWidgets);
      await _pump(t, 800);
      expect(_live.stage, M8Stage.order, reason: 'held for reading');
      expect(await _until(t, () => _live.stage == M8Stage.shed, maxMs: 6000), isTrue);
      expect(find.textContaining(L.orderLine(_live.inc.n)), findsNothing);
      expect(_live.slips, 1);
      await _close(t, c);
    });

    testWidgets('letting the hotline pass its rings is a slip once; it rings again; then the lamp stays lit and the desk is still', (t) async {
      final c = await _open(t, seedBoth);
      final inc = _live.inc;
      expect(await _until(t, () => _live.stage == M8Stage.ring && _live.hotOn, maxMs: 14000), isTrue);
      expect(await _pumpUntil(t, find.text(Mk.ringMissed.textBn), maxMs: inc.rings * kM8RingMs + 3000), isTrue, reason: 'the hotline passed its rings');
      expect(_live.slips, 1);
      expect(_live.ringMissed, isTrue);
      final at = _phonesNow();
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.stage, M8Stage.ring);
      await _pump(t, kM8Redial * kM8RingMs + 600);
      expect(_live.slips, 1, reason: 'a second miss costs nothing more');
      expect(_phonesNow().hotRinging, isFalse);
      expect(_phonesNow().hotLit, isTrue);
      expect(at.hotRinging, isTrue, reason: 'it was still ringing at the slip');
      await _drag(t, _geo.hotline.center, _geo.hotline.center + const Offset(0, -46));
      expect(_live.stage, M8Stage.order, reason: 'it can still be lifted');
      expect(_live.caught, isNot(contains(L.caughtHot)));
      await _close(t, c);
    });

    testWidgets('the register: a tap opens it, a swipe down or a tap on its handle closes it; nothing under it is reachable; no row is highlighted', (t) async {
      final c = await _open(t, seedBoth);
      await _toShed(t);
      await _tapAt(t, _geo.register.center);
      expect(M8GridHotlineProbe.regOpen, isTrue);
      expect(find.byKey(const ValueKey('register')), findsOneWidget);
      // Nothing under the page: a twist on a bay does nothing.
      final b = _live.inc.rightBays.first;
      await _twist(t, b);
      expect(_live.off[b], isFalse);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await t.dragFrom(_geo.registerHandle.center * _k, const Offset(0, 90));
      await _pump(t, 400);
      expect(M8GridHotlineProbe.regOpen, isFalse, reason: 'a swipe down closes it');
      await _tapAt(t, _geo.register.center);
      expect(M8GridHotlineProbe.regOpen, isTrue);
      await _tapAt(t, _geo.registerHandle.center);
      expect(M8GridHotlineProbe.regOpen, isFalse, reason: 'a tap on the handle closes it');
      await _close(t, c);
    });

    testWidgets('a switch let go before its stop springs back; a recent area is a slip; three of them strike the level out', (t) async {
      final c = await _open(t, seedBoth);
      await _toShed(t);
      final inc = _live.inc;
      final right = inc.rightBays.first;
      await _twist(t, right, quarters: 0.4);
      expect(_live.off[right], isFalse, reason: 'half a turn is not OFF');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      final recent = [for (var i = 0; i < 6; i++) if (inc.recent(i)) i];
      for (var i = 0; i < 3; i++) {
        await _twist(t, recent[i]);
        if (i < 2) {
          // The race is paused while the card is up; the coworker comes at his
          // first twist: refuse him once.
          if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
            await _refuse(t, _live.deal.push);
            await _twist(t, recent[i]);
          }
          expect(find.text(Mk.recentShed.textBn), findsOneWidget);
          expect(_live.off[recent[i]], isFalse, reason: 'springs back');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.index, 0, reason: 'the same incident');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.recentShed.key});
      await _close(t, c);
    });

    testWidgets('the race: the frequency falls after the order, passes 49.0 once as a slip, and the round still ends with the feeders off', (t) async {
      final d = m8GridDeal(math.Random(seedBoth));
      final c = await _open(t, seedBoth);
      await _toShed(t);
      final inc = d.incidents[0];
      final f0 = M8GridHotlineProbe.freq!();
      expect(f0, closeTo(inc.fRing, 0.01));
      await _pump(t, 3000);
      expect(M8GridHotlineProbe.freq!(), lessThan(f0 - 0.05), reason: 'it keeps falling');
      // The coworker pauses nothing here (he is dealt on the second incident):
      // wait for the window to pass.
      expect(await _pumpUntil(t, find.text(Mk.raceLost.textBn), maxMs: inc.raceMs + 2000), isTrue);
      expect(M8GridHotlineProbe.freq!(), lessThanOrEqualTo(kM8Danger));
      expect(_live.slips, 1);
      final held = M8GridHotlineProbe.freq!();
      await _pump(t, 1500);
      expect(M8GridHotlineProbe.freq!(), held, reason: 'the clock waits while the card is up');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 4000);
      expect(M8GridHotlineProbe.freq!(), closeTo(kM8RaceFloor, 0.001));
      expect(_live.slips, 1, reason: 'once an incident');
      for (final b in inc.rightBays) {
        await _twist(t, b);
        expect(_live.off[b], isTrue);
      }
      expect(_live.stage, M8Stage.after);
      expect(_live.caught, isNot(contains(L.caughtShed)));
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _close(t, c);
    });

    // The coworker on the first incident with the 'call SLDC first' push.
    final seedAsk = _seedWhere((d) => d.push == M8Push.ask && d.coworkerIncident == 0 && d.askIncident == 1 && d.incidents[0].n == 1);
    testWidgets('the first twist waits for the coworker; the frequency is paused while he is on; listening is a slip (and "call SLDC first" costs 3 s)', (t) async {
      final d = m8GridDeal(math.Random(seedAsk));
      final c = await _open(t, seedAsk);
      await _toShed(t);
      final inc = d.incidents[0];
      final b = inc.rightBays.first;
      // At once, inside his 1.2–2.4 s timer: a twist.
      await _twist(t, b);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.off[b], isFalse, reason: 'the twist did not go through');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final paused = M8GridHotlineProbe.freq!();
      await _pump(t, 1500);
      expect(M8GridHotlineProbe.freq!(), paused, reason: 'paused for both beats');
      final wrong = _textsOnScreen(L.coworker(d.push).wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.push(d.push).textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(M8GridHotlineProbe.freq!(), lessThan(paused - 0.08), reason: 'three seconds of the race went on the call');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.pushAsk.key});
      await _twist(t, b);
      expect(_live.off[b], isTrue, reason: 'after him the switch turns');
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; then the customer, then the next incident', (t) async {
      final d = m8GridDeal(math.Random(seedBoth));
      final c = await _open(t, seedBoth);
      await _toShed(t);
      for (final b in d.incidents[0].rightBays) {
        await _twist(t, b);
      }
      expect(_live.stage, M8Stage.after);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(60, 128));
        await t.pump(const Duration(milliseconds: 150));
        await t.tapAt(_geo.register.center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(M8GridHotlineProbe.regOpen, isFalse, reason: 'the scene takes nothing');
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[_live.whyNow]!);
      expect(await _until(t, () => _live.stage == M8Stage.callRing, maxMs: 4000), isTrue);
      expect(_phonesNow().blackRinging, isTrue, reason: 'the customer rings');
      // The hotline does not lift for the customer.
      await _drag(t, _geo.hotline.center, _geo.hotline.center + const Offset(0, -46));
      expect(_live.stage, M8Stage.callRing);
      await _drag(t, _geo.blackPhone.center, _geo.blackPhone.center + const Offset(0, -46));
      expect(_live.stage, M8Stage.callSay);
      expect(find.textContaining(L.customerTag), findsWidgets);
      // A wrong card is a slip; the deck stays.
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.consumerWrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 700);
      expect(find.text(Mk.consumerWrong.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _pickOwn(t, L.consumerRight);
      await _pump(t, 2600);
      expect(_live.index, 1);
      expect(_live.caught, contains(L.caughtExplain));
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.consumerWrong.key});
      await _close(t, c);
    });

    testWidgets('gesture hand: none in the watch beat; the lit hotline alone gets a nudge; any touch hides it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      // The hotline alone in the first incident.
      final seedAlone = _seedWhere((d) => d.askIncident == 1 && d.incidents[0].blackMode == M8BlackMode.none && d.incidents[0].driftMs < 4500);
      final c = await _open(t, seedAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 2500);
      expect(_live.stage, M8Stage.watch);
      expect(scene().showing, isFalse, reason: 'nothing rings yet');
      // It rings, nobody lifts it: the slip card, then the lit lamp waits.
      expect(await _pumpUntil(t, find.text(Mk.ringMissed.textBn), maxMs: 14000), isTrue);
      expect(scene().showing, isFalse, reason: 'no hand over a card');
      await t.tap(find.text(MistakeLines.gotIt));
      expect(await _until(t, () => scene().showing, maxMs: 24000), isTrue, reason: 'idle at the hotline');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      await _tapAt(t, const Offset(200, 330));
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      await _close(t, c);
    });

    testWidgets('gesture hand: the open register gets a swipe down on its handle, the switches a sweep that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, seedBoth);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _toShed(t);
      await _tapAt(t, _geo.register.center);
      expect(M8GridHotlineProbe.regOpen, isTrue);
      expect(await _until(t, () => scene().showing, maxMs: 11000), isTrue, reason: 'the open register waits for a swipe down');
      expect(scene().debugFrame?.ripple, isNull);
      await _tapAt(t, _geo.registerHandle.center);
      expect(scene().showing, isFalse);
      // The window passes (the race is lost), the card is read, the meter rests.
      expect(await _pumpUntil(t, find.text(Mk.raceLost.textBn), maxMs: 9000), isTrue);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 3000);
      expect(await _until(t, () => scene().showing, maxMs: 12000), isTrue, reason: 'idle at the switches');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(c.read(gameSaveProvider).mistakes.where((m) => m.key == Mk.recentShed.key), isEmpty);
      await _close(t, c);
    });
  });
}

M8Phones _phonesNow() => M8GridHotlineProbe.phones!();
