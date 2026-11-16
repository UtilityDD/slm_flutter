// Lesson 6.10 (এনার্জি মিটার), কাজ 1 "মিটারের নাড়ি": the rules (a verdict
// with a load still on, 'meter bad' before the checks and a wrong LED reading
// are slips; a leak with every load off; a steady LED → the 100 W bulb for a
// full hour, under an hour a slip; the reading rises; a blank meter: the
// tester on the incoming terminals, then the fault place; a dark house with
// the meter on: the neutral), the deal, the libraries, the coworker's pushes
// (listening = a slip; the level has no deadly act), the drawn places, and the
// level in the shell: the guide first, a full clean play (switches hunted by
// panning, the LED window, a reason pick each call, the coworker refused), the
// two-step place pick, a slip card that keeps the call, three slips, the LED
// window takes no touch, the clock waits for the coworker on a fast play, the
// praise window takes no touch, and the gesture hand shows how (never what)
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
import 'package:slm_flutter/features/game/m6_meter_pulse.dart';
import 'package:slm_flutter/features/game/m6_meter_pulse_world.dart';
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
  rungId: '6.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6MeterPulsePacks['do_6_10_a']!;
typedef L = M6MeterPulseLines;
typedef Mk = M6MeterPulseMistakes;

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
M6PulseGeo get _geo => M6PulseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M6PulseRun get _live => M6MeterPulseProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

/// Pans the house so the camera stands at [target] (design px).
Future<void> _panTo(WidgetTester t, double target) async {
  for (var k = 0; k < 4; k++) {
    final d = M6MeterPulseProbe.camX - target;
    if (d.abs() < 1) return;
    await t.dragFrom(Offset(200, _geo.y(0.12)) * _k, Offset(d, 0) * _k);
    await _pump(t, 200);
  }
}

/// Every running load switched OFF (panning to each switch).
Future<void> _allOff(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    if (!_live.switches[i]) continue;
    await _panTo(t, (M6PulseGeo.roomX(i) - 150).clamp(0.0, kM6PulseCamMax));
    await _tapAt(t, _geo.switchOnScreen(i, M6MeterPulseProbe.camX).center);
    expect(_live.switches[i], isFalse, reason: 'room $i off');
  }
}

Future<void> _goMeter(WidgetTester t) async {
  await t.tap(_label(L.goMeter));
  await _pump(t, 400);
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

/// Turn the clock's minute hand on by [minutes] (a circular drag on the hand).
Future<void> _turnClock(WidgetTester t, double minutes) async {
  final g = _geo;
  final m0 = _live.clockMinute;
  final th0 = -math.pi / 2 + m0 / 60 * 2 * math.pi;
  final r = g.clockR * 0.82;
  Offset at(double a) => (g.clock + Offset(math.cos(a), math.sin(a)) * r) * _k;
  final total = minutes / 60 * 2 * math.pi;
  final n = math.max(4, (total.abs() / (math.pi / 18)).ceil());
  final gesture = await t.startGesture(at(th0));
  for (var i = 1; i <= n; i++) {
    await gesture.moveTo(at(th0 + total * i / n));
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _pump(t, 250);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6MeterPulsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6PulseDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m6PulseDeal(math.Random(s))));

/// The coworker comes (the bulb plugged in): refuse him.
Future<void> _refuse(WidgetTester t, M6PulsePush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// One call played right (the coworker refused if he is dealt on it).
Future<void> _playCall(WidgetTester t, M6PulseDeal d, int i) async {
  final c = d.calls[i];
  expect(_live.index, i);
  switch (c.kind) {
    case M6PulseCallKind.fast:
      await _allOff(t);
      await _goMeter(t);
      expect(_live.stage, M6PulseStage.watch);
      await _pump(t, kM6PulseLedMs + 600);
      expect(_live.stage, M6PulseStage.verdict);
      await _pickOwn(t, L.verdicts[c.leak ? M6PulseVerdict.leak : M6PulseVerdict.steady]!);
      if (!c.leak) {
        expect(_live.stage, M6PulseStage.plug);
        await _drag(t, _geo.bulbTray.center, _geo.socket);
        expect(_live.plugged, isTrue);
        if (d.coworkerCall == i) await _refuse(t, d.push);
        final before = _live.readingTenths;
        await _turnClock(t, 62);
        expect(_live.minutes, greaterThanOrEqualTo(60));
        expect(_live.readingTenths, before + 1, reason: 'the 100 W bulb for an hour: 0.1 kWh');
        await t.tap(_label(L.readNow));
        await _pump(t, 500);
        expect(_live.stage, M6PulseStage.judge);
        await _pickOwn(t, L.judgeRight);
      }
    case M6PulseCallKind.blank:
      await _goMeter(t);
      expect(_live.stage, M6PulseStage.test);
      await _drag(t, _geo.testerTray.center, _geo.incomingHit.center);
      expect(_live.tested, isTrue);
      await _tapAt(t, c.voltage ? _geo.meterHit.center : _geo.cableHit.center);
      expect(await confirmChoice(t), isTrue);
      await _pump(t, 400);
    case M6PulseCallKind.dark:
      await _goMeter(t);
      expect(_live.stage, M6PulseStage.neutral);
      await _pump(t, 300);
      await _pickOwn(t, L.neutralRight);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${c.kind}');
  expect(_live.roundDone, isTrue, reason: '${c.kind}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${c.kind})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  if (c.leak) {
    expect(await _pumpUntil(t, _label(L.explain), maxMs: 3000), isTrue, reason: 'explain the customer\'s appliances');
    await t.tap(_label(L.explain));
    await _pump(t, 2600);
  } else {
    await _pump(t, 3000);
  }
}

M6PulseCall _callOf(M6PulseCallKind k, {bool leak = false, bool voltage = false, List<bool>? switches, int startHund = 123457}) => M6PulseCall(
      kind: k,
      rooms: const [M6PulseAppliance.fan, M6PulseAppliance.tube, M6PulseAppliance.tv, M6PulseAppliance.fridge, M6PulseAppliance.pump],
      switches: switches ?? const [true, false, true, false, true],
      startHund: startHund,
      startMinute: 10,
      leak: leak,
      voltage: voltage,
    );

M6PulseRun _runOf(M6PulseCall first) => M6PulseRun(M6PulseDeal(
      calls: [first, _callOf(M6PulseCallKind.fast), _callOf(M6PulseCallKind.dark)],
      coworkerCall: 1,
      push: M6PulsePush.five,
      why: const [M6PulseWhy.loadsOff, M6PulseWhy.fullHour, M6PulseWhy.neutral],
    ));

void main() {
  group('rules', () {
    test('deals: a fast call first; 1–2 fast (one steady at least) + blank/dark; 3–5 running, one out of view; the reason fits; plays differ', () {
      final seen = <String>{};
      final whys = <M6PulseWhy>{};
      var leaks = 0, twoFast = 0, blank = 0, dark = 0, lit = 0, pushes = <M6PulsePush>{};
      for (var s = 0; s < 200; s++) {
        final d = m6PulseDeal(math.Random(s));
        expect(d.calls, hasLength(3));
        expect(d.calls.first.kind, M6PulseCallKind.fast);
        final fast = d.calls.where((c) => c.kind == M6PulseCallKind.fast).toList();
        expect(fast.length, inInclusiveRange(1, 2));
        expect(fast.where((c) => !c.leak), isNotEmpty, reason: 'at least one steady call');
        expect(d.calls.where((c) => c.kind != M6PulseCallKind.fast), isNotEmpty);
        if (fast.length == 1) expect(d.calls.map((c) => c.kind).toSet(), M6PulseCallKind.values.toSet());
        expect(d.calls[d.coworkerCall].kind, M6PulseCallKind.fast);
        expect(d.calls[d.coworkerCall].leak, isFalse, reason: 'he comes on a steady call (the known-load test)');
        for (final (i, c) in d.calls.indexed) {
          expect(c.rooms.toSet(), M6PulseAppliance.values.toSet());
          expect(c.rooms[4], M6PulseAppliance.pump, reason: 'the pump in the yard');
          expect(c.startHund, inInclusiveRange(100000, 899999));
          expect(c.startHund % 10, inInclusiveRange(3, 7), reason: 'the 0.1 kWh tick lands mid-hour');
          expect(c.startMinute, inInclusiveRange(0, 59));
          if (c.kind == M6PulseCallKind.fast) {
            expect(c.runningAtStart, inInclusiveRange(3, 5));
            expect(c.switches[3] || c.switches[4], isTrue, reason: 'one running load out of the first view');
          }
          if (c.kind != M6PulseCallKind.fast) expect(c.leak, isFalse);
          if (c.kind != M6PulseCallKind.blank) expect(c.voltage, isFalse);
          final fits = switch (c.kind) {
            M6PulseCallKind.fast => c.leak ? {M6PulseWhy.blink, M6PulseWhy.loadsOff} : {M6PulseWhy.fullHour, M6PulseWhy.loadsOff},
            M6PulseCallKind.blank => {M6PulseWhy.incoming},
            M6PulseCallKind.dark => {M6PulseWhy.neutral},
          };
          expect(fits, contains(d.why[i]));
          if (c.leak) leaks++;
          if (c.kind == M6PulseCallKind.blank) {
            blank++;
            if (c.voltage) lit++;
          }
          if (c.kind == M6PulseCallKind.dark) dark++;
        }
        if (fast.length == 2) twoFast++;
        whys.addAll(d.why);
        pushes.add(d.push);
        seen.add([for (final c in d.calls) '${c.kind.index}${c.leak}${c.voltage}${c.rooms.map((r) => r.index).join()}${c.switches.map((b) => b ? 1 : 0).join()}'].join('|'));
      }
      expect(seen.length, greaterThan(190));
      expect(whys, M6PulseWhy.values.toSet());
      expect(pushes, M6PulsePush.values.toSet());
      expect(twoFast, inInclusiveRange(70, 130));
      expect(leaks, greaterThan(30));
      expect(blank, greaterThan(60));
      expect(dark, greaterThan(60));
      expect(lit, inInclusiveRange((blank * 0.3).round(), (blank * 0.7).round()));
    });

    test('the LED: a load on blinks it (faster with more), a leak blinks it with all off, else steady; the same window for every truth', () {
      final r = _runOf(_callOf(M6PulseCallKind.fast, switches: const [true, true, false, false, false]));
      expect(r.led, M6PulseLed.faster);
      r.toggle(0);
      expect(r.led, M6PulseLed.fast);
      r.toggle(1);
      expect(r.led, M6PulseLed.steady);
      final l = _runOf(_callOf(M6PulseCallKind.fast, leak: true, switches: const [false, false, false, true, false]));
      expect(l.led, M6PulseLed.faster);
      l.toggle(3);
      expect(l.led, M6PulseLed.leak);
      // The lesson: with every load off a leak blinks the LED very fast —
      // quicker than one load running, never a slow blink.
      int flashes(M6PulseLed p) {
        var n = 0;
        var was = false;
        for (var ms = 0.0; ms < kM6PulseLedMs; ms += 10) {
          final lit = M6PulseLedPainter.litAt(p, ms);
          if (lit && !was) n++;
          was = lit;
        }
        return n;
      }
      expect(flashes(M6PulseLed.leak), greaterThan(flashes(M6PulseLed.fast)));
      // A blank or dark house draws nothing.
      expect(_runOf(_callOf(M6PulseCallKind.dark)).loadsOn, 0);
      // A blank meter has no supply: its LED is off and never lights, at
      // rest or in a look.
      final b = _runOf(_callOf(M6PulseCallKind.blank));
      expect(b.led, M6PulseLed.off);
      for (var ms = 0.0; ms < kM6PulseLedMs; ms += 37) {
        expect(M6PulseLedPainter.litAt(M6PulseLed.off, ms), isFalse);
      }
      // Steady never goes dark; every blink pattern goes dark at some point
      // in the window; at rest (no look running) the LED is lit for all.
      for (var ms = 0.0; ms < kM6PulseLedMs; ms += 37) {
        expect(M6PulseLedPainter.litAt(M6PulseLed.steady, ms), isTrue);
      }
      for (final p in [M6PulseLed.leak, M6PulseLed.fast, M6PulseLed.faster]) {
        final states = {for (var ms = 0.0; ms < kM6PulseLedMs; ms += 37) M6PulseLedPainter.litAt(p, ms)};
        expect(states, {true, false}, reason: '$p');
      }
    });

    test('the house: switches flip only in the hunt; the meter stage per call kind; home again from the verdict', () {
      final r = _runOf(_callOf(M6PulseCallKind.fast));
      expect(r.stage, M6PulseStage.hunt);
      expect(r.toggle(0), isTrue);
      expect(r.switches[0], isFalse);
      expect(r.goMeter(), isTrue);
      expect(r.stage, M6PulseStage.watch);
      expect(r.toggle(2), isFalse, reason: 'at the meter');
      expect(r.verdict(M6PulseVerdict.steady), isNull, reason: 'not before the window ends');
      expect(r.slips, 0);
      r.watchDone();
      expect(r.stage, M6PulseStage.verdict);
      expect(r.goHome(), isTrue);
      expect(r.stage, M6PulseStage.hunt);
      final b = _runOf(_callOf(M6PulseCallKind.blank))..goMeter();
      expect(b.stage, M6PulseStage.test);
      final dk = _runOf(_callOf(M6PulseCallKind.dark))..goMeter();
      expect(dk.stage, M6PulseStage.neutral);
    });

    test('the verdict: with a load on every verdict is a slip and back to the house; "meter bad" a slip; a wrong reading a slip', () {
      final r = _runOf(_callOf(M6PulseCallKind.fast, switches: const [false, false, false, false, true]))
        ..goMeter()
        ..watchDone();
      expect(r.verdict(M6PulseVerdict.steady), Mk.loadOn);
      expect(r.stage, M6PulseStage.hunt);
      expect(r.loadSlipped, isTrue);
      r
        ..toggle(4)
        ..goMeter()
        ..watchDone();
      expect(r.verdict(M6PulseVerdict.bad), Mk.meterBadEarly);
      expect(r.verdict(M6PulseVerdict.leak), Mk.ledFalseBlink);
      expect(r.slips, 3);
      expect(r.verdict(M6PulseVerdict.steady), isNull);
      expect(r.stage, M6PulseStage.plug);
      expect(r.roundDone, isFalse, reason: 'on to the known load');
      expect(r.caught, contains(L.caughtLoads));
      // A leak.
      final l = _runOf(_callOf(M6PulseCallKind.fast, leak: true, switches: const [true, false, false, false, false]))..toggle(0);
      l
        ..goMeter()
        ..watchDone();
      expect(l.verdict(M6PulseVerdict.steady), Mk.ledMissedBlink);
      expect(l.verdict(M6PulseVerdict.leak), isNull);
      expect(l.roundDone, isTrue);
      expect(l.caught, containsAll([L.caughtLoads, L.caughtLeak]));
      expect(l.toExplain(), isTrue);
      expect(l.stage, M6PulseStage.explain);
      expect(l.explain(), isTrue);
      expect(l.explain(), isFalse, reason: 'once');
      expect(l.caught, contains(L.caughtExplain));
    });

    test('the known load: plug, then the clock; under a full hour a slip (the test goes on); the reading rises one tenth an hour; the judgement', () {
      for (final start in [123400, 123457, 123499, 555591]) {
        final r = _runOf(_callOf(M6PulseCallKind.fast, switches: List.filled(5, false), startHund: start))
          ..goMeter()
          ..watchDone()
          ..verdict(M6PulseVerdict.steady);
        final before = r.readingTenths;
        expect(before, start ~/ 10);
        expect(r.turnClock(30), 0, reason: 'the bulb first');
        expect(r.readNow(), isNull);
        expect(r.plug(), isTrue);
        expect(r.stage, M6PulseStage.clock);
        expect(r.turnClock(-10), 0, reason: 'never before the start');
        expect(r.turnClock(40), 40);
        expect(r.readNow(), Mk.shortHour);
        expect(r.stage, M6PulseStage.clock, reason: 'the test goes on');
        expect(r.readingTenths, inInclusiveRange(before, before + 1));
        r.turnClock(20);
        expect(r.readingTenths, before + 1, reason: 'a full hour: 0.1 kWh ($start)');
        expect(r.clockHour, 8, reason: 'the clock shows the hour gone');
        expect(r.readNow(), isNull);
        expect(r.stage, M6PulseStage.judge);
        expect(r.judge(right: false), Mk.knownWrong);
        expect(r.judge(right: true), isNull);
        expect(r.roundDone, isTrue);
        expect(r.caught, contains(L.caughtHour));
        expect(r.slips, 2);
      }
    });

    test('a blank meter: a place before the test costs nothing; lit → inside the meter; dark → the cable or the pole', () {
      final lit = _runOf(_callOf(M6PulseCallKind.blank, voltage: true))..goMeter();
      expect(lit.placeEarly(), isTrue);
      expect(lit.place(M6PulsePlace.meter), isNull);
      expect(lit.roundDone, isFalse);
      expect(lit.slips, 0);
      expect(lit.test(), isTrue);
      expect(lit.placeEarly(), isFalse);
      expect(lit.place(M6PulsePlace.cable), Mk.blankLit);
      expect(lit.place(M6PulsePlace.pole), Mk.blankLit);
      expect(lit.place(M6PulsePlace.meter), isNull);
      expect(lit.roundDone, isTrue);
      expect(lit.caught, contains(L.caughtIncoming));
      for (final p in [M6PulsePlace.cable, M6PulsePlace.pole]) {
        final dead = _runOf(_callOf(M6PulseCallKind.blank))
          ..goMeter()
          ..test();
        expect(dead.place(M6PulsePlace.meter), Mk.blankDead);
        expect(dead.place(p), isNull, reason: 'the lesson: service cable or pole connection');
        expect(dead.roundDone, isTrue);
      }
    });

    test('a dark house with the meter on: the neutral; anything else a slip', () {
      final r = _runOf(_callOf(M6PulseCallKind.dark))..goMeter();
      expect(r.neutral(right: false), Mk.darkNotNeutral);
      expect(r.neutral(right: true), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtNeutral));
    });

    test('no deadly act in this level; listening to him is a slip (X2/B1); three slips fail; a thorough call pays its bonus', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'spec: do_6_10_a has no deadly');
      expect(Mk.push(M6PulsePush.five), Mk.pushFive);
      expect(Mk.push(M6PulsePush.skip), Mk.pushSkip);
      final r = _runOf(_callOf(M6PulseCallKind.dark))..goMeter();
      for (var i = 0; i < 3; i++) {
        r.neutral(right: false);
      }
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      r.pushSlip(Mk.pushFive);
      expect(r.percent, 40);
      r
        ..neutral(right: true)
        ..next();
      expect(r.thorough, isTrue, reason: 'each call counts its own slips');
      expect(r.stage, M6PulseStage.hunt, reason: 'a new house');
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        for (final l in L.complaints.values) ...l,
        ...L.tasks,
        L.steadyOk,
        L.testFirst,
        L.explainLine,
        L.goMeter,
        L.goHome,
        L.readNow,
        L.explain,
        for (var n = 1; n <= 3; n++) L.callName(n),
        for (final a in M6PulseAppliance.values) L.switchName(a),
        for (final p in M6PulsePlace.values) L.place(p),
        for (final l in L.verdicts.values) ...l,
        ...L.judgeRight,
        ...L.judgeWrong,
        ...L.neutralRight,
        ...L.neutralWrong,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6PulsePush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|সুইচ অন|এলটি|এইচটি|কেভি').hasMatch(l), isFalse, reason: 'ON/OFF, LT, HT, kV in English letters: $l');
        // The standalone state word অন (e.g. 'মিটার অন') is ON too.
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        // য় ড় ঢ় as base + nukta (the app's form).
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: 'nukta form: $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.10/m6_meter_pulse/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_meter_pulse/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6MeterPulsePacks.keys, ['do_6_10_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the decks and the places alike', () {
      expectSameLength('places', [for (final p in M6PulsePlace.values) L.place(p)]);
      expectSameLength('verdicts', [for (final l in L.verdicts.values) ...l]);
      for (final l in L.verdicts.values) {
        expect(l.length, greaterThanOrEqualTo(2));
      }
      expectSameLength('judge', [...L.judgeRight, ...L.judgeWrong]);
      expectLibrary('judge', L.judgeRight, L.judgeWrong);
      expectSameLength('neutral', [...L.neutralRight, ...L.neutralWrong]);
      expectLibrary('neutral', L.neutralRight, L.neutralWrong);
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6PulseWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
        expect(cw.right, contains('না, পুরো এক ঘণ্টা চালিয়ে রিডিং দেখব'), reason: 'the spec\'s refusal');
      }
    });

    test('spoken lines: his exit is recorded; his two new pushes and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'এক ঘণ্টা কে বসে থাকবে? পাঁচ মিনিট দেখেই লিখে দাও মিটার খারাপ!',
        'ঘড়ি ঘোরানোর দরকার নেই, বাল্ব জ্বলছে মানেই মিটার ঠিক — চলো!',
      ]);
      expect({for (final p in M6PulsePush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            for (final l in L.complaints.values) ...l,
            ...L.tasks,
            L.steadyOk,
            L.testFirst,
            L.explainLine,
            ...L.whyQ.values,
            for (final p in M6PulsePush.values) L.callHeld(p),
            L.allSet,
            L.quick,
            L.fail,
            ...L.tapWhy,
            for (final cw in L.allCoworkers) ...cw.asks,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_meter_pulse: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas: on the scene, below the header, above the button row, clear of the guide and of each other', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6PulseGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final veranda = <Rect>[g.meterHit, g.incomingHit, g.cableHit, g.poleHit, g.socketHit, g.bulbTray, g.testerTray, g.clockHit];
        for (final r in veranda) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the button row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
        }
        for (final (i, a) in veranda.indexed) {
          for (final b in veranda.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        for (var i = 0; i < 5; i++) {
          final s = g.switchAt(i);
          expect(s.top, greaterThan(125));
          expect(s.bottom, lessThan(h - 95));
          for (final cam in [0.0, kM6PulseCamMax / 2, kM6PulseCamMax]) {
            expect(g.switchOnScreen(i, cam).overlaps(guide), isFalse, reason: 'h $h: room $i at $cam under the guide');
          }
          expect(s.left, greaterThanOrEqualTo(0));
          expect(s.right, lessThanOrEqualTo(kM6PulsePanoW));
        }
        // Rooms 0–2 in the first view; room 3 and the yard out of it.
        for (var i = 0; i < 3; i++) {
          expect(g.switchOnScreen(i, 0).right, lessThanOrEqualTo(360), reason: 'h $h: room $i in the first view');
        }
        expect(g.switchOnScreen(3, 0).left, greaterThan(360));
        expect(g.switchOnScreen(4, 0).left, greaterThan(360));
        expect(g.switchOnScreen(4, kM6PulseCamMax).right, lessThanOrEqualTo(360), reason: 'the yard switch reachable');
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

    testWidgets('the guide comes first: a tap does not skip him; then the house and "মিটারে যাই"', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6MeterPulsePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.houseLabel), findsOneWidget);
      expect(_label(L.goMeter), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askHunt)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with a leak (and its explanation), a steady call (the coworker
    // refused) and a blank or dark call; one with a steady call, a blank call
    // and a dark call.
    final flowSeeds = [
      _seedWhere((d) => d.calls.any((c) => c.leak) && d.calls.first.leak),
      _seedWhere((d) => d.calls.where((c) => c.kind == M6PulseCallKind.fast).length == 1 && d.calls[1].kind == M6PulseCallKind.blank && d.calls[1].voltage),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three calls, the hunt, the LED, the tests, reasons; he is refused → pass', (t) async {
        final d = m6PulseDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playCall(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.10/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.10/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final leakThenBlank = _seedWhere((d) => d.calls.first.leak && d.calls[1].kind == M6PulseCallKind.blank && !d.calls[1].voltage);
    testWidgets('a fault place is two steps: before the test it costs nothing; a tap opens it, ✕ sets it aside, ✓ judges it', (t) async {
      final d = m6PulseDeal(math.Random(leakThenBlank));
      final c = await _open(t, leakThenBlank);
      await _playCall(t, d, 0);
      await _goMeter(t);
      expect(_live.stage, M6PulseStage.test);
      await _tapAt(t, _geo.meterHit.center);
      expect(find.byType(CardPreviewOverlay), findsNothing, reason: 'measure first');
      expect(c.read(guideDirectorProvider).line, contains(L.testFirst));
      await _drag(t, _geo.testerTray.center, _geo.incomingHit.center);
      expect(_live.tested, isTrue);
      await _tapAt(t, _geo.poleHit.center);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(_live.roundDone, isFalse);
      // The tester was dark: the meter is the wrong place.
      await _tapAt(t, _geo.meterHit.center);
      expect(await confirmChoice(t), isTrue);
      await _pump(t, 500);
      expect(find.text(Mk.blankDead.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.blankDead.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 1, reason: 'the same call goes on');
      await _tapAt(t, _geo.cableHit.center);
      expect(await confirmChoice(t), isTrue);
      await _pump(t, 400);
      expect(_live.roundDone, isTrue);
      await _close(t, c);
    });

    final steadyFirst = _seedWhere((d) => !d.calls.first.leak && d.coworkerCall == 0);
    testWidgets('a verdict with a load on: a slip, back into the house; three of them strike the level out', (t) async {
      final c = await _open(t, steadyFirst);
      for (var i = 0; i < 3; i++) {
        expect(_live.stage, M6PulseStage.hunt);
        await _goMeter(t);
        await _pump(t, kM6PulseLedMs + 600);
        await _pickOwn(t, L.verdicts[M6PulseVerdict.steady]!);
        if (i < 2) {
          expect(find.text(Mk.loadOn.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.index, 0, reason: 'the same call');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.loadOn.key});
      await _close(t, c);
    });

    testWidgets('the LED window takes no touch and shows no deck; then the deck and the way home', (t) async {
      final c = await _open(t, steadyFirst);
      await _allOff(t);
      await _goMeter(t);
      expect(_live.stage, M6PulseStage.watch);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.meterHit.center * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(_geo.bulbTray.center * _k, const Offset(40, -120));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(_label(L.goHome), findsNothing);
      expect(_live.plugged, isFalse);
      await _pump(t, kM6PulseLedMs);
      expect(_live.stage, M6PulseStage.verdict);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      await t.tap(_label(L.goHome));
      await _pump(t, 400);
      expect(_live.stage, M6PulseStage.hunt);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a fast play: the clock waits for the coworker; listening is a slip and the test goes on', (t) async {
      final d = m6PulseDeal(math.Random(steadyFirst));
      final c = await _open(t, steadyFirst);
      await _allOff(t);
      await _goMeter(t);
      await _pump(t, kM6PulseLedMs + 600);
      await _pickOwn(t, L.verdicts[M6PulseVerdict.steady]!);
      await _drag(t, _geo.bulbTray.center, _geo.socket);
      expect(_live.plugged, isTrue);
      // At once, well inside his 1.2–2.4 s timer: a turn of the clock.
      await _turnClock(t, 30);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.minutes, 0, reason: 'the clock did not turn');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworker(d.push).wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.push(d.push).textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      await _turnClock(t, 30);
      expect(_live.minutes, closeTo(30, 1.5), reason: 'after him the clock turns');
      await t.tap(_label(L.readNow));
      await _pump(t, 500);
      expect(find.text(Mk.shortHour.textBn), findsOneWidget, reason: 'half an hour is not the hour');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.push(d.push).key, Mk.shortHour.key});
      await _close(t, c);
    });

    final leakFirst = _seedWhere((d) => d.calls.first.leak);
    testWidgets('the praise window and the reason deck take no touch; then the explanation, then the next call', (t) async {
      final d = m6PulseDeal(math.Random(leakFirst));
      final c = await _open(t, leakFirst);
      await _allOff(t);
      await _goMeter(t);
      await _pump(t, kM6PulseLedMs + 600);
      await waitChoiceDeck(t);
      final right = _textsOnScreen(L.verdicts[M6PulseVerdict.leak]!).single;
      await t.tap(find.byKey(ValueKey('deal-$right')), warnIfMissed: false);
      await confirmChoice(t);
      // The ◆ on the table, the deck open at once: the scene and the way home
      // take nothing.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(60, 128));
        await t.pump(const Duration(milliseconds: 150));
        await t.tapAt(_geo.meterHit.center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.stage, M6PulseStage.verdict);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[d.why[0]]!);
      expect(await _pumpUntil(t, _label(L.explain), maxMs: 3000), isTrue);
      expect(_live.index, 0, reason: 'waits for the explanation');
      await t.tap(_label(L.explain));
      await _pump(t, 2600);
      expect(_live.index, 1);
      expect(_live.caught, contains(L.caughtExplain));
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle in the house shows a hand that presses nothing; any touch hides it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, steadyFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the house');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a swipe or a sweep presses nothing');
      await _tapAt(t, const Offset(200, 200));
      expect(scene().showing, isFalse);
      // At the meter, during the LED window: no hand.
      await _goMeter(t);
      await _pump(t, 4000);
      expect(scene().showing, isFalse, reason: 'the LED window waits for nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
