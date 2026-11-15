// Lesson 6.2 (সার্কিট ব্রেকার), কাজ 2 "তিন অবস্থান": the rules (hands-on in
// SERVICE = deadly, in TEST a slip; the ON/OFF test only in TEST, ON with the
// spring at DISCHARGED a slip, the manual handle charges it; a dark TRIP
// CIRCUIT HEALTHY breaker never into service, a lit one never reported, no
// report before the lamp could be seen; an action that does not fit the
// docket a slip; between positions nothing happens), the deal, the
// libraries, the coworker's pushes (listening = the act he pushes), the
// drawn places, and the level in the shell: the guide first, a full clean
// play (the crank turned by a circular drag, a reason pick each job, the
// coworker refused), the two-step action pick, a slip card that keeps the
// job, three slips, the deadly freeze (own act; listening to his deadly
// push), the crank waits for him on a fast play, the praise window takes no
// touch, and the gesture hand shows how (never what) only while the level
// waits.
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
import 'package:slm_flutter/features/game/m6_breaker_rack.dart';
import 'package:slm_flutter/features/game/m6_breaker_rack_world.dart';
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
  rungId: '6.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6BreakerRackPacks['do_6_2_b']!;
typedef L = M6BreakerRackLines;
typedef Mk = M6BreakerRackMistakes;

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
M6RackGeo get _geo => M6RackGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M6RackRun get _live => M6BreakerRackProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _docket(WidgetTester t) => _tapAt(t, M6RackGeo.docket.center);

/// Turn the crank by [steps] (+ = anticlockwise = racks out; clockwise racks
/// in, as on a real truck) with a circular drag that starts on its grip.
Future<void> _crank(WidgetTester t, double steps) async {
  final g = _geo;
  final th0 = -math.pi / 2 - _live.t * 2 * math.pi;
  Offset at(double a) => (g.crank + Offset(math.cos(a), math.sin(a)) * g.crankR) * _k;
  final total = -steps * 2 * math.pi;
  final n = math.max(4, (total.abs() / (math.pi / 18)).ceil());
  final gesture = await t.startGesture(at(th0));
  for (var i = 1; i <= n; i++) {
    await gesture.moveTo(at(th0 + total * i / n));
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _pump(t, 250);
}

Future<void> _crankTo(WidgetTester t, M6RackPos p) async {
  final d = p.index - _live.t;
  if (d.abs() > 0.01) await _crank(t, d);
  expect(_live.pos, p, reason: 'cranked to $p (t ${_live.t})');
}

/// An action through its preview: tap → ✓.
Future<void> _act(WidgetTester t, M6RackAction a) async {
  await t.tap(_label(L.action(a)));
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue, reason: 'the preview of $a');
  await _pump(t, 400);
}

Future<void> _stroke(WidgetTester t) async {
  await t.dragFrom(_geo.grip * _k, const Offset(0, 64));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6BreakerRackPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6RackDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m6RackDeal(math.Random(s))));

/// The coworker comes (the docket of his job read): refuse him.
Future<void> _refuse(WidgetTester t, M6RackPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// One job played right (the coworker refused if he is dealt on it).
Future<void> _playJob(WidgetTester t, M6RackDeal d, int i) async {
  final j = d.jobs[i];
  await _docket(t);
  if (d.coworkerJob == i) await _refuse(t, d.push);
  switch (j.kind) {
    case M6RackJobKind.maintain:
      await _crankTo(t, M6RackPos.isolated);
      await _act(t, M6RackAction.work);
    case M6RackJobKind.onOff:
      await _crankTo(t, M6RackPos.test);
      await _act(t, M6RackAction.test);
      expect(_live.testArmed, isTrue);
      if (!j.selfCharge) {
        expect(_live.springCharged, isFalse);
        await _tapAt(t, _geo.socket);
        expect(_live.handleFitted, isTrue);
        for (var k = 0; k < kM6RackStrokes; k++) {
          await _stroke(t);
        }
        expect(_live.springCharged, isTrue);
      }
      await _tapAt(t, _geo.onBtn);
      expect(_live.breakerOn, isTrue);
      await _tapAt(t, _geo.offBtn);
    case M6RackJobKind.toService:
      if (j.healthy) {
        await _crankTo(t, M6RackPos.service);
        await _act(t, M6RackAction.service);
      } else {
        if (j.start == M6RackPos.isolated) {
          // A report before the lamp can be seen: no cost, look first.
          await _act(t, M6RackAction.report);
          expect(find.byType(MistakeCard), findsNothing);
          expect(_live.roundDone, isFalse);
          await _crankTo(t, M6RackPos.test);
        }
        await _act(t, M6RackAction.report);
      }
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${j.kind}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${j.kind})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  await _pump(t, 3000);
}

M6RackJob _jobOf(M6RackJobKind k, {M6RackPos? start, bool selfCharge = true, bool healthy = true}) => M6RackJob(
      kind: k,
      face: M6RackFace.vcb,
      feeder: 3,
      start: start ?? m6RackStarts(k).first,
      counter: 1200,
      selfCharge: selfCharge,
      healthy: healthy,
    );

/// A run whose first job is [first]; the docket already read.
M6RackRun _runOf(M6RackJob first, {bool read = true}) {
  final r = M6RackRun(M6RackDeal(
    jobs: [first, for (final k in M6RackJobKind.values) if (k != first.kind) _jobOf(k)],
    coworkerJob: 0,
    push: M6RackPush.isolator,
    why: const [M6RackWhy.rackOut, M6RackWhy.testPos, M6RackWhy.healthy],
  ));
  if (read) r.readDocket();
  return r;
}

void main() {
  group('rules', () {
    test('deals: one job of each kind; a start never its own place; his push fits his job; the reason fits; plays differ', () {
      final seen = <String>{};
      final pushes = <M6RackPush>{};
      final whys = <M6RackWhy>{};
      final coworkerKinds = <M6RackJobKind>{};
      var flat = 0, dark = 0, ocb = 0;
      for (var s = 0; s < 150; s++) {
        final d = m6RackDeal(math.Random(s));
        expect(d.jobs.map((j) => j.kind).toSet(), M6RackJobKind.values.toSet());
        expect(d.jobs.map((j) => j.feeder).toSet(), hasLength(3));
        for (final (i, j) in d.jobs.indexed) {
          expect(m6RackStarts(j.kind), contains(j.start));
          expect(j.start, isNot(j.target), reason: 'the truck never starts where the job is done');
          if (j.kind != M6RackJobKind.onOff) expect(j.selfCharge, isTrue);
          if (j.kind != M6RackJobKind.toService) expect(j.healthy, isTrue);
          final fits = switch (j.kind) {
            M6RackJobKind.maintain => {M6RackWhy.rackOut},
            M6RackJobKind.onOff => {M6RackWhy.testPos, if (!j.selfCharge) M6RackWhy.spring},
            M6RackJobKind.toService => {j.healthy ? M6RackWhy.healthy : M6RackWhy.report},
          };
          expect(fits, contains(d.why[i]), reason: '${j.kind} ${d.why[i]}');
          if (j.kind == M6RackJobKind.onOff && !j.selfCharge) flat++;
          if (j.kind == M6RackJobKind.toService && !j.healthy) dark++;
          if (j.face == M6RackFace.ocb) ocb++;
        }
        final him = d.jobs[d.coworkerJob];
        expect(m6RackPushesFor(him), contains(d.push));
        if (d.push != M6RackPush.isolator) expect(him.start, M6RackPos.service, reason: '"green, work here" / "pull to TEST" only where the truck is in SERVICE');
        if (him.kind == M6RackJobKind.toService) {
          expect((him.healthy, him.start), (false, M6RackPos.test), reason: '"leave the breaker in repair" only where the lamp already shows dark');
        }
        pushes.add(d.push);
        whys.addAll(d.why);
        coworkerKinds.add(him.kind);
        seen.add('${d.jobs.map((j) => '${j.kind.index}${j.start.index}${j.face.index}${j.selfCharge}${j.healthy}').join('|')}|${d.coworkerJob}${d.push.name}');
      }
      expect(seen.length, greaterThan(120));
      expect(pushes, M6RackPush.values.toSet());
      expect(whys, M6RackWhy.values.toSet());
      expect(coworkerKinds, {M6RackJobKind.maintain, M6RackJobKind.toService}, reason: 'never on the test (no push fits it)');
      for (final x in [flat, dark]) {
        expect(x, inInclusiveRange(40, 110));
      }
      expect(ocb, inInclusiveRange(150, 300), reason: 'VCB or OCB on each panel');
    });

    test('positions: seated only near a step; the control plug is in for SERVICE and TEST only', () {
      expect(m6RackPosAt(0), M6RackPos.service);
      expect(m6RackPosAt(1.1), M6RackPos.test);
      expect(m6RackPosAt(1.9), M6RackPos.isolated);
      expect(m6RackPosAt(0.5), isNull);
      expect(m6RackPosAt(1.5), isNull);
      expect(m6RackControlOn(1), isTrue);
      expect(m6RackControlOn(2), isFalse);
      expect(m6RackControlOn(1.5), isFalse);
      // The lamps live on the control plug (HEATER on the panel's own supply).
      const rig = M6RackRig(face: M6RackFace.vcb, feeder: 1, counter: 1);
      expect(m6RackLamps(rig), [false, true, false, true, true]);
      expect(m6RackLamps(const M6RackRig(face: M6RackFace.vcb, feeder: 1, counter: 1, controlOn: false)), [false, false, false, false, true]);
      expect(m6RackLamps(const M6RackRig(face: M6RackFace.vcb, feeder: 1, counter: 1, healthy: false)), [false, true, false, false, true]);
      expect(m6RackLamps(const M6RackRig(face: M6RackFace.vcb, feeder: 1, counter: 1, breakerOn: true)), [true, false, false, true, true]);
    });

    test('the crank: nothing before the docket; stops at SERVICE and ISOLATED; between positions an action does nothing', () {
      final r = _runOf(_jobOf(M6RackJobKind.maintain, start: M6RackPos.service), read: false);
      expect(r.crank(0.5), 0, reason: 'the docket first');
      expect(r.act(M6RackAction.work), isNull);
      expect(r.deadly, isNull);
      r.readDocket();
      expect(r.crank(-1), 0, reason: 'SERVICE is the inner stop');
      expect(r.crank(0.5), closeTo(0.5, 1e-9));
      expect(r.pos, isNull);
      expect(r.act(M6RackAction.work), isNull);
      expect(r.slips, 0);
      expect(r.roundDone, isFalse);
      expect(r.crank(5), closeTo(1.5, 1e-9));
      expect(r.t, kM6RackMax);
      expect(r.pos, M6RackPos.isolated);
    });

    test('রক্ষণাবেক্ষণ: hands-on in SERVICE deadly (R6), in TEST a slip (R7), in ISOLATED right; other actions slips', () {
      final a = _runOf(_jobOf(M6RackJobKind.maintain, start: M6RackPos.service));
      final m = a.act(M6RackAction.work);
      expect(m, Mk.handsService);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      expect(a.slips, 0);
      final b = _runOf(_jobOf(M6RackJobKind.maintain, start: M6RackPos.test));
      expect(b.act(M6RackAction.work), Mk.handsTest);
      expect(b.act(M6RackAction.test), Mk.wrongJob);
      expect(b.act(M6RackAction.service), Mk.wrongJob);
      expect(b.act(M6RackAction.report), Mk.needlessReport);
      expect(b.slips, 4);
      b.crank(1);
      expect(b.pos, M6RackPos.isolated);
      expect(b.act(M6RackAction.work), isNull);
      expect(b.roundDone, isTrue);
      expect(b.caught, contains(L.caughtRackOut));
    });

    test('ON-OFF পরীক্ষা: only in TEST; ON with the flag at DISCHARGED a slip; the handle charges it; ON then OFF; the crank locked meanwhile', () {
      final s = _runOf(_jobOf(M6RackJobKind.onOff, start: M6RackPos.service, selfCharge: false));
      expect(s.act(M6RackAction.test), Mk.testService);
      expect(s.act(M6RackAction.work), Mk.handsService, reason: 'hands-on in SERVICE is deadly in any job');
      final i = _runOf(_jobOf(M6RackJobKind.onOff, start: M6RackPos.isolated, selfCharge: false));
      expect(i.act(M6RackAction.test), Mk.testIsolated);
      expect(i.act(M6RackAction.work), Mk.wrongJob, reason: 'safe, but not the docket\'s job');
      expect(i.pressOn(), isNull, reason: 'no test under way: the buttons do nothing');
      i.crank(-1);
      expect(i.pos, M6RackPos.test);
      expect(i.act(M6RackAction.test), isNull);
      expect(i.testArmed, isTrue);
      expect(i.canCrank, isFalse);
      expect(i.crank(1), 0);
      expect(i.pressOff(), isFalse, reason: 'already OFF');
      expect(i.springSlipped, isFalse);
      expect(i.pressOn(), Mk.springFlat);
      expect(i.springSlipped, isTrue, reason: 'the spring reason would not fit this job');
      expect(i.breakerOn, isFalse);
      expect(i.stroke(), isFalse, reason: 'no handle in yet');
      expect(i.fitHandle(), isTrue);
      for (var k = 1; k < kM6RackStrokes; k++) {
        expect(i.stroke(), isFalse);
      }
      expect(i.stroke(), isTrue);
      expect(i.springCharged, isTrue);
      expect(i.handleFitted, isFalse);
      final before = i.counter;
      expect(i.pressOn(), isNull);
      expect(i.breakerOn, isTrue);
      expect(i.counter, before + 1);
      expect(i.springCharged, isFalse, reason: 'no motor: the spring is spent');
      expect(i.pressOff(), isTrue);
      expect(i.roundDone, isTrue);
      expect(i.caught, containsAll([L.caughtTest, L.caughtSpring]));
      expect(i.slips, 3);
      // A spring that charges itself: no handle, ready again after ON.
      final m = _runOf(_jobOf(M6RackJobKind.onOff, start: M6RackPos.isolated))..crank(-1);
      expect(m.act(M6RackAction.test), isNull);
      expect(m.fitHandle(), isFalse, reason: 'charged already');
      expect(m.pressOn(), isNull);
      expect(m.springCharged, isTrue);
      expect(m.canCrank, isFalse, reason: 'a closed breaker cannot be racked');
      expect(m.pressOff(), isTrue);
      expect(m.caught, isNot(contains(L.caughtSpring)));
    });

    test('সার্ভিসে ফেরত (lit): into service only in SERVICE; a report is a needless stop (R32)', () {
      final r = _runOf(_jobOf(M6RackJobKind.toService, start: M6RackPos.isolated));
      expect(r.sawHealthy, isFalse, reason: 'ISOLATED: the control plug is out, the lamp dark');
      expect(r.reportUnseen(M6RackAction.report), isTrue);
      expect(r.act(M6RackAction.report), isNull, reason: 'a report before the lamp is seen: no cost, the guide says look first');
      expect(r.slips, 0);
      expect(r.roundDone, isFalse);
      expect(r.act(M6RackAction.service), Mk.notInService);
      r.crank(-1);
      expect(r.sawHealthy, isTrue);
      expect(r.reportUnseen(M6RackAction.report), isFalse);
      expect(r.act(M6RackAction.service), Mk.notInService);
      expect(r.act(M6RackAction.report), Mk.litReport);
      expect(r.act(M6RackAction.test), Mk.wrongJob);
      r.crank(-1);
      expect(r.pos, M6RackPos.service);
      expect(r.act(M6RackAction.service), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtHealthy));
    });

    test('সার্ভিসে ফেরত (dark): never into service (R36); a report once the lamp was seen', () {
      final r = _runOf(_jobOf(M6RackJobKind.toService, start: M6RackPos.isolated, healthy: false));
      r.crank(-2);
      expect(r.act(M6RackAction.service), Mk.darkIn);
      expect(r.act(M6RackAction.report), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtReport));
      final t = _runOf(_jobOf(M6RackJobKind.toService, start: M6RackPos.test, healthy: false));
      expect(t.sawHealthy, isTrue, reason: 'TEST: the lamp shows from the start');
      expect(t.act(M6RackAction.report), isNull);
    });

    test('listening to him is the act he pushes (X2/B1): green-here and myth 2 (isolator) deadly, test-enough a slip', () {
      expect(Mk.push(M6RackPush.greenHere), Mk.handsService);
      expect(Mk.push(M6RackPush.greenHere).deadly, isTrue);
      expect(Mk.push(M6RackPush.testEnough), Mk.handsTest);
      expect(Mk.push(M6RackPush.isolator), Mk.pushIsolator);
      expect(Mk.push(M6RackPush.testEnough).deadly, isFalse);
      expect(Mk.push(M6RackPush.isolator).deadly, isTrue, reason: 'owner 2026-11-15: feeder on the isolator = deadly');
      expect(m6RackPushesFor(_jobOf(M6RackJobKind.maintain, start: M6RackPos.service)), M6RackPush.values);
      expect(m6RackPushesFor(_jobOf(M6RackJobKind.maintain, start: M6RackPos.test)), [M6RackPush.isolator]);
      expect(m6RackPushesFor(_jobOf(M6RackJobKind.onOff)), isEmpty);
      expect(m6RackPushesFor(_jobOf(M6RackJobKind.toService, start: M6RackPos.test)), isEmpty, reason: 'a sound breaker: "leave it in repair" does not fit');
      expect(m6RackPushesFor(_jobOf(M6RackJobKind.toService, start: M6RackPos.isolated, healthy: false)), isEmpty, reason: 'the lamp cannot be seen yet');
      expect(m6RackPushesFor(_jobOf(M6RackJobKind.toService, start: M6RackPos.test, healthy: false)), [M6RackPush.isolator]);
    });

    test('three slips and the play fails; a thorough job pays its bonus', () {
      final r = _runOf(_jobOf(M6RackJobKind.maintain, start: M6RackPos.test));
      for (var i = 0; i < 3; i++) {
        r.act(M6RackAction.report);
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      r.act(M6RackAction.report);
      expect(r.percent, 40);
      r
        ..crank(1)
        ..act(M6RackAction.work)
        ..next();
      expect(r.thorough, isTrue, reason: 'each job counts its own slips');
      expect(r.docketRead, isFalse, reason: 'a new panel, a new docket');
    });

    test('English digits only; jol not pani; every mistake has its picture; the deadly set; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.docketFirst,
        L.midway,
        L.docket,
        L.docketOff,
        for (var n = 1; n <= 8; n++) L.feeder(n),
        for (final k in M6RackJobKind.values) L.job(k),
        for (final a in M6RackAction.values) L.action(a),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6RackPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.handsService, Mk.pushIsolator});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.2/m6_breaker_rack/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      for (final k in M6RackJobKind.values) {
        expect(m6RackLessonPoint(k), inInclusiveRange(0, 3));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_breaker_rack/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6BreakerRackPacks.keys, ['do_6_2_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the four actions alike', () {
      expectSameLength('actions', [for (final a in M6RackAction.values) L.action(a)]);
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6RackWhy.values) {
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
      }
    });

    test('rival lines: his exit is recorded; his three new pushes and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'ঝামেলা কোরো না, ব্রেকার তো OFF — সবুজ জ্বলছে, এখানেই খুলে কাজ সারো!',
        'টেস্ট পর্যন্ত টানলেই হবে, পাওয়ার তো কাটা — কাজ ধরো।',
        'ব্রেকার মেরামতে থাক, আইসোলেটর দিয়েই ফিডার চালিয়ে দাও — যেকোনো সুইচই তো সার্কিট ব্রেকার।',
      ]);
      expect({for (final p in M6RackPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, L.askDocket, L.midway, L.lookFirst, ...L.whyQ.values, for (final m in Mk.all) m.textBn]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_breaker_rack: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, clear of the header, the guide and the action row', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6RackGeo.forScene(h, 0);
        final rects = <Rect>[M6RackGeo.docket, g.onHit, g.offHit, g.socketHit, g.strokeHit, g.crankHit];
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the action row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          // The guide's speech bubble (right side, above him) hides what is
          // under it: keep the targets clear of it.
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        // The crank's touch circle stays clear of every other target.
        for (final r in [M6RackGeo.docket, g.onHit, g.offHit, g.socketHit, g.strokeHit]) {
          final near = Offset(g.crank.dx.clamp(r.left, r.right), g.crank.dy.clamp(r.top, r.bottom));
          expect((near - g.crank).distance, greaterThan(g.crankTouch), reason: 'h $h: $r');
        }
        for (final (i, a) in [M6RackGeo.docket, g.onHit, g.offHit, g.socketHit].indexed) {
          for (final b in [M6RackGeo.docket, g.onHit, g.offHit, g.socketHit].skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        expect(g.strokeHit.overlaps(g.onHit) || g.strokeHit.overlaps(g.offHit), isFalse);
        expect(g.glass.bottom, lessThanOrEqualTo(g.floorY));
        expect(g.window.bottom, lessThan(g.glass.top));
        expect(g.crankHit.bottom, lessThan(g.glass.top + 20), reason: 'h $h: the crank above the glass');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the four actions', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6BreakerRackPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.docket), findsOneWidget);
      for (final a in M6RackAction.values) {
        expect(_label(L.action(a)), findsOneWidget);
      }
      final d = m6RackDeal(math.Random(3));
      expect(find.text(L.job(d.jobs.first.kind)), findsNothing, reason: 'the docket is folded until read');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time; the docket read, the job is the task', (t) async {
      final c = await _open(t, 5);
      final d = m6RackDeal(math.Random(5));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askDocket)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _docket(t);
      expect(find.text(L.job(d.jobs.first.kind)), findsOneWidget);
      expect(c.read(guideDirectorProvider).line, contains(L.askJob(d.jobs.first.kind)));
      await _close(t, c);
    });

    // One play with the deadly push (refused), a flat spring and a dark
    // return-to-service that starts ISOLATED; one with myth 2 on a return job
    // whose lamp shows dark.
    final flowSeeds = [
      _seedWhere((d) =>
          d.push == M6RackPush.greenHere &&
          d.jobs.any((j) => j.kind == M6RackJobKind.onOff && !j.selfCharge) &&
          d.jobs.any((j) => j.kind == M6RackJobKind.toService && !j.healthy && j.start == M6RackPos.isolated)),
      _seedWhere((d) => d.push == M6RackPush.isolator && d.jobs[d.coworkerJob].kind == M6RackJobKind.toService),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three panels, crank, actions, a test, reasons; he is refused → pass', (t) async {
        final d = m6RackDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playJob(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.2/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.2/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final maintFirstAlone = _seedWhere((d) => d.jobs.first.kind == M6RackJobKind.maintain && d.jobs.first.start == M6RackPos.test && d.coworkerJob != 0);
    testWidgets('an action is two steps: a tap opens it and answers nothing, ✕ sets it aside, ✓ judges it', (t) async {
      final c = await _open(t, maintFirstAlone);
      await _docket(t);
      await t.tap(_label(L.action(M6RackAction.report)));
      await _pump(t, 300);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      final aside = t.widget<CardAside>(find.ancestor(of: _label(L.action(M6RackAction.report)), matching: find.byType(CardAside)));
      expect(aside.aside, isTrue, reason: 'set aside, dimmed');
      await _act(t, M6RackAction.report);
      expect(find.text(Mk.needlessReport.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.needlessReport.key);
      await _close(t, c);
    });

    testWidgets('a slip (hands-on in TEST) shows its card; the same job goes on after it; between positions nothing happens', (t) async {
      final c = await _open(t, maintFirstAlone);
      await _docket(t);
      await _act(t, M6RackAction.work);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.handsTest.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0, reason: 'the same job');
      // Half a turn: the truck between TEST and ISOLATED.
      await _crank(t, 0.5);
      expect(_live.t, closeTo(1.5, 0.02), reason: 'the crank counts from the touch-down');
      expect(_live.pos, isNull);
      await _act(t, M6RackAction.work);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.midway));
      await _crank(t, 0.5);
      await _act(t, M6RackAction.work);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.handsTest.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, maintFirstAlone);
      await _docket(t);
      for (var i = 0; i < 3; i++) {
        await _act(t, M6RackAction.report);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final serviceFirstAlone = _seedWhere((d) => d.jobs.first.kind == M6RackJobKind.maintain && d.jobs.first.start == M6RackPos.service && d.coworkerJob != 0);
    testWidgets('hands-on in SERVICE: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, serviceFirstAlone);
      await _docket(t);
      await _act(t, M6RackAction.work);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.handsService.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final greenFirst = _seedWhere((d) => d.coworkerJob == 0 && d.push == M6RackPush.greenHere);
    testWidgets('listening to "green, work here" = deadly: freeze, then the card', (t) async {
      final c = await _open(t, greenFirst);
      await _docket(t);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerGreen.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.handsService.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: the crank waits for the coworker; he cuts in at once', (t) async {
      final c = await _open(t, greenFirst);
      await _docket(t);
      // At once, well inside his 1.2–2.4 s timer: a turn of the crank.
      final t0 = _live.t;
      await _crank(t, 1);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.t, t0, reason: 'the crank did not turn');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerGreen.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _crank(t, 2);
      expect(_live.pos, M6RackPos.isolated, reason: 'after him the crank turns');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m6RackDeal(math.Random(maintFirstAlone));
      final c = await _open(t, maintFirstAlone);
      await _docket(t);
      await _crankTo(t, M6RackPos.isolated);
      await _act(t, M6RackAction.work);
      // The ◆ on the table, the deck open at once: the scene takes nothing
      // (the docket, the crank) and the action row is gone.
      expect(_label(L.action(M6RackAction.report)), findsNothing);
      final t0 = _live.t;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(M6RackGeo.docket.center * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(_geo.crankGrip(_live.t) * _k, const Offset(-60, 30));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.t, t0, reason: 'the crank did not turn');
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[d.why[0]]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a tap on the docket first; then three taps on nothing show a hand that presses no action', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, maintFirstAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the docket not read');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way on, not a pick');
      await _docket(t);
      expect(scene().showing, isFalse);
      // Three taps on nothing (the wall over the panel) show the hand at once.
      final empty = const Offset(30, 200) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge or a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
