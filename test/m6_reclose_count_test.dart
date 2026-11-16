// Lesson 6.8 (অটো-রিক্লোজার ও সেকশনালাইজার), কাজ 1 "চেষ্টা গুনুন": the rules
// (the cycle of each fault: a passing fault holds, a main-line fault locks
// out after the setting's tries, a branch fault's sectionalizer opens in the
// pause before the last try and the last try lights the other branch; the
// calls: লাইন চালু / লক-আউট / শাখা বন্ধ on a branch line, each slip of the
// spec at each moment; a right call ends the cycle at once), the deal, the
// libraries, the coworker (lesson myth 1, listening = deadly), every spoken
// line listed, the drawn places, and the level in the shell: the guide
// first, a full clean play (docket, tally, coworker refused, magnets, a
// reason pick each round), a slip card that keeps the round and lets the
// cycle play on, three slips, the deadly freeze, the board waits for him,
// the praise window takes no touch, and the gesture hand shows how (never
// what) only while the level waits.
import 'dart:async';
import 'dart:convert';
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
import 'package:slm_flutter/features/game/m6_reclose_count.dart';
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
  rungId: '6.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6RecloseCountPacks['do_6_8_a']!;
typedef L = M6RecloseCountLines;
typedef Mk = M6RecloseCountMistakes;

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

/// The app's form of য় ড় ঢ় (base + nukta), for comparing with the lesson file.
String _nukta(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
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
M6RcGeo get _geo => M6RcGeo.forScene(360 * 850 / 392, 0);
M6RcRun get _live => M6RecloseCountProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tuck(WidgetTester t) => _tapAt(t, _geo.docket.center);

/// A magnet dragged from its tray onto [to] (design px).
Future<void> _drop(WidgetTester t, M6RcCall c, Offset to) async {
  final from = _geo.magnet(c.index).center;
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Offset _target(M6RcCall c, [M6RcBranch? b]) => c == M6RcCall.branch ? _geo.branchZone(b!).center : _geo.sk(0.18, 0.2);

/// The right call for the round on screen.
Future<void> _callRight(WidgetTester t) async {
  final r = _live.round;
  final (c, b) = switch (r.outcome) {
    M6RcOutcome.transient => (M6RcCall.on, null),
    M6RcOutcome.main => (M6RcCall.lockout, null),
    M6RcOutcome.branchA => (M6RcCall.branch, M6RcBranch.a),
    M6RcOutcome.branchB => (M6RcCall.branch, M6RcBranch.b),
  };
  await _drop(t, c, _target(c, b));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6RecloseCountPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6RcDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m6RcDeal(math.Random(s))));

/// The coworker comes in his dead pause: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 16000), isTrue, reason: 'he comes');
  expect(_live.coworkerPause, isTrue, reason: 'in a dead pause, tries left');
  expect(_live.tries, _live.deal.coworkerAfter);
  expect(_live.tries, lessThan(_live.deal.setting));
  await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// One round played right (the coworker refused if he is dealt on it).
Future<void> _playRound(WidgetTester t, M6RcDeal d, int i) async {
  expect(_live.index, i);
  await _tuck(t);
  expect(_live.tucked, isTrue);
  if (d.coworkerRound == i) await _refuse(t);
  expect(await _pumpUntil(t, () => _live.settled, maxMs: 20000), isTrue, reason: 'the cycle ends (round $i)');
  // The player's own count on the tally (scores nothing).
  for (var k = 0; k < _live.tries; k++) {
    await _tapAt(t, _geo.clicker.center);
  }
  expect(_live.taps, _live.tries);
  await _callRight(t);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${d.rounds[i].outcome}');
  expect(_live.roundDone, isTrue);
  expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'the reason deck');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  await _pump(t, 3000);
}

M6RcRound _roundOf(M6RcOutcome o, {int setting = 3, int hold = 1}) =>
    M6RcRound(outcome: o, pauses: [for (var i = 0; i < setting; i++) 2000], hold: o == M6RcOutcome.transient ? hold : 0);

/// A run whose first round is [o]; the docket tucked.
M6RcRun _runOf(M6RcOutcome o, {int setting = 3, int hold = 1, int cwAfter = 1}) {
  final rest = M6RcOutcome.values.where((x) => x != o).take(2);
  final r = M6RcRun(M6RcDeal(
    setting: setting,
    rounds: [_roundOf(o, setting: setting, hold: hold), for (final x in rest) _roundOf(x, setting: setting)],
    coworkerRound: o == M6RcOutcome.transient ? 1 : 0,
    coworkerAfter: cwAfter,
    why: [m6RcWhyFor(o), for (final x in rest) m6RcWhyFor(x)],
  ));
  r.tuck();
  return r;
}

/// Plays beats until [stop] says so (or the cycle ends).
void _playUntil(M6RcRun r, bool Function() stop) {
  while (!stop() && r.applyStep() != null) {}
}

void main() {
  group('rules', () {
    test('deals: 3 or 4 tries; three different faults (at least two lasting); he comes in a lasting round after try 1 or 2; reasons fit; plays differ', () {
      final seen = <String>{};
      final settings = <int>{}, cwAfter = <int>{}, dusk = <int>{};
      final outs = <M6RcOutcome>{};
      final whys = <M6RcWhy>{};
      final cwOut = <M6RcOutcome>{};
      var mirror = 0;
      for (var s = 0; s < 200; s++) {
        final d = m6RcDeal(math.Random(s));
        expect(d.setting, inInclusiveRange(3, 4));
        expect(d.rounds, hasLength(3));
        expect(d.rounds.map((r) => r.outcome).toSet(), hasLength(3), reason: 'three different faults');
        expect(d.rounds.where((r) => r.lasting).length, greaterThanOrEqualTo(2));
        expect(d.rounds[d.coworkerRound].lasting, isTrue, reason: 'he comes only where the line stays tripped');
        expect(d.coworkerAfter, inInclusiveRange(1, 2));
        expect(d.coworkerAfter, lessThan(d.setting), reason: 'tries always left when he comes');
        for (final (i, r) in d.rounds.indexed) {
          expect(r.pauses, hasLength(d.setting));
          for (final p in r.pauses) {
            expect(p, inInclusiveRange(1600, 3200));
          }
          if (r.outcome == M6RcOutcome.transient) {
            expect(r.hold, inInclusiveRange(1, 2));
          }
          final fit = {m6RcWhyFor(r.outcome), if (i == d.coworkerRound) M6RcWhy.refused};
          expect(fit, contains(d.why[i]));
          outs.add(r.outcome);
        }
        settings.add(d.setting);
        cwAfter.add(d.coworkerAfter);
        dusk.add(d.dusk);
        whys.addAll(d.why);
        cwOut.add(d.rounds[d.coworkerRound].outcome);
        if (d.mirror) mirror++;
        seen.add('${d.setting}|${d.rounds.map((r) => '${r.outcome.index}${r.hold}${r.pauses.join(',')}').join('|')}|${d.coworkerRound}${d.coworkerAfter}${d.mirror}');
      }
      expect(seen.length, 200);
      expect(settings, {3, 4});
      expect(cwAfter, {1, 2});
      expect(dusk, {0, 1, 2});
      expect(outs, M6RcOutcome.values.toSet());
      expect(whys, M6RcWhy.values.toSet());
      expect(cwOut, {M6RcOutcome.main, M6RcOutcome.branchA, M6RcOutcome.branchB});
      expect(mirror, inInclusiveRange(60, 140));
    });

    test('the cycle of each fault: a passing fault holds; a main fault locks out after the setting; a branch is cut off before the last try', () {
      for (final setting in [3, 4]) {
        // Passing (holds at try 2).
        final tr = _runOf(M6RcOutcome.transient, setting: setting, hold: 2);
        expect(tr.nextStep!.kind, M6RcStepKind.fault);
        tr.applyStep();
        expect((tr.lightsA, tr.lightsB), (false, false), reason: 'the trip: both dark');
        expect(tr.bolts, 1);
        _playUntil(tr, () => tr.settled);
        expect((tr.tries, tr.lightsA, tr.lightsB, tr.nextStep), (2, true, true, null));
        // Main: every try trips at once, then dark for good.
        final mn = _runOf(M6RcOutcome.main, setting: setting);
        var flicks = 0;
        while (true) {
          final s = mn.applyStep();
          if (s == null) break;
          if (s.kind == M6RcStepKind.tryOn) {
            flicks++;
            expect(mn.nextStep!.kind, M6RcStepKind.trip);
            expect(mn.nextStep!.ms, kM6RcFlickMs, reason: 'a lasting fault trips at once');
          }
        }
        expect((flicks, mn.tries, mn.lightsA, mn.lightsB, mn.settled), (setting, setting, false, false, true));
        // Branch A: S-A opens in the last pause; the last try lights B only.
        final a = _runOf(M6RcOutcome.branchA, setting: setting);
        _playUntil(a, () => a.saOpen);
        expect(a.tries, setting - 1);
        expect((a.lightsA, a.lightsB, a.settled), (false, false, false), reason: 'opens on a dead line');
        a.applyStep();
        expect((a.tries, a.lightsA, a.lightsB, a.settled), (setting, false, true, true));
        // Branch B: the last try lights A only.
        final b = _runOf(M6RcOutcome.branchB, setting: setting);
        _playUntil(b, () => b.settled);
        expect((b.tries, b.lightsA, b.lightsB, b.sbOpen, b.saOpen), (setting, true, false, true, false));
      }
    });

    test('his dead pause: in his round, right after try 1 or 2 trips, lines dark, tries left', () {
      for (final after in [1, 2]) {
        final r = _runOf(M6RcOutcome.main, setting: 3, cwAfter: after);
        var seen = 0;
        while (r.nextStep != null) {
          if (r.coworkerPause) {
            seen++;
            expect(r.tries, after);
            expect(r.lightsA || r.lightsB, isFalse);
          }
          r.applyStep();
        }
        expect(seen, 1);
      }
      final other = _runOf(M6RcOutcome.transient);
      _playUntil(other, () => other.coworkerPause);
      expect(other.coworkerPause, isFalse, reason: 'never in a passing fault');
    });

    test('before the fault nothing has tripped: no call decides or slips (the board is live from the first trip)', () {
      for (final o in M6RcOutcome.values) {
        final r = _runOf(o);
        expect(r.step, 0);
        expect(r.live, isFalse);
        expect(r.call(M6RcCall.on), isNull);
        expect(r.call(M6RcCall.lockout), isNull);
        expect(r.call(M6RcCall.branch, M6RcBranch.a), isNull);
        expect(r.call(M6RcCall.branch, M6RcBranch.b), isNull);
        expect((r.slips, r.roundDone), (0, false), reason: '$o');
        r.applyStep();
        expect(r.live, isTrue, reason: 'the fault: the board is live');
      }
    });

    test('a passing fault that held: লাইন চালু right; লক-আউট or শাখা বন্ধ = needless patrol; before it held, every call is a slip', () {
      final r = _runOf(M6RcOutcome.transient, hold: 2);
      r.applyStep();
      expect(r.call(M6RcCall.on), Mk.onDark, reason: 'dark now');
      expect(r.call(M6RcCall.lockout), Mk.lockEarly);
      expect(r.call(M6RcCall.branch, M6RcBranch.a), Mk.noBranch);
      expect(r.call(M6RcCall.branch), isNull, reason: 'a branch magnet off the branch lines decides nothing');
      _playUntil(r, () => r.settled);
      expect(r.call(M6RcCall.lockout), Mk.needless);
      expect(r.call(M6RcCall.branch, M6RcBranch.b), Mk.needless);
      expect(r.slips, 5);
      expect(r.roundDone, isFalse, reason: 'the cycle plays on after a slip');
      r.taps = 2;
      expect(r.call(M6RcCall.on), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, containsAll([L.caughtOn, L.caughtCount]));
      expect(r.call(M6RcCall.on), isNull, reason: 'nothing after the call');
      expect(r.slips, 5);
    });

    test('a passing fault reads "held" only once its lights outlast a flick: a drop as they come on is too early', () {
      for (final hold in [1, 2]) {
        final r = _runOf(M6RcOutcome.transient, hold: hold);
        _playUntil(r, () => r.tries == hold);
        expect((r.lightsA, r.lightsB, r.settled), (true, true, false), reason: 'just lit: not held yet');
        expect(r.nextStep!.kind, M6RcStepKind.held);
        expect(r.nextStep!.ms, greaterThan(kM6RcFlickMs * 2));
        expect(r.call(M6RcCall.on), Mk.onDark, reason: 'a guess, not a reading');
        r.applyStep();
        expect((r.settled, r.nextStep), (true, null));
        expect(r.call(M6RcCall.on), isNull);
        expect(r.roundDone, isTrue);
      }
    });

    test('the quick time is the dealt cycle waits plus a fixed allowance (every deal can earn it)', () {
      final rng = math.Random(68);
      var lo = 1 << 30, hi = 0;
      for (var i = 0; i < 400; i++) {
        final d = m6RcDeal(rng);
        final waits = m6RcDealtWaitMs(d);
        var sum = 0;
        for (final r in d.rounds) {
          for (final s in m6RcSteps(r, d.setting)) {
            sum += s.ms;
          }
        }
        expect(waits, sum);
        expect(m6RcQuickMs(d), waits + m6RecloseCountQuickAllowanceMs);
        lo = math.min(lo, waits);
        hi = math.max(hi, waits);
      }
      expect(lo, greaterThan(10000));
      expect(hi, lessThan(45000));
      expect(m6RecloseCountQuickAllowanceMs, 38000);
      expect(m6RecloseCountPacks['do_6_8_a']!.quickAllowanceMs, m6RecloseCountQuickAllowanceMs);
    });

    test('main: লক-আউট only once the setting\'s tries are over; then চালু and a branch are slips', () {
      final r = _runOf(M6RcOutcome.main, setting: 4);
      _playUntil(r, () => r.tries == 3);
      expect(r.call(M6RcCall.lockout), Mk.lockEarly, reason: 'tries < setting');
      _playUntil(r, () => r.settled);
      expect(r.call(M6RcCall.on), Mk.onDark);
      expect(r.call(M6RcCall.branch, M6RcBranch.a), Mk.noBranch);
      r.taps = 2;
      expect(r.call(M6RcCall.lockout), isNull);
      expect(r.caught, contains(L.caughtLock));
      expect(r.caught, isNot(contains(L.caughtCount)), reason: 'the tally was off');
    });

    test('branch A: right once S-A hangs open (the rest of the cycle plays at once); the other branch or লক-আউট are slips', () {
      final r = _runOf(M6RcOutcome.branchA);
      _playUntil(r, () => r.tries == 1);
      expect(r.call(M6RcCall.branch, M6RcBranch.a), Mk.noBranch, reason: 'too early: nothing cut off yet');
      _playUntil(r, () => r.saOpen);
      expect(r.call(M6RcCall.branch, M6RcBranch.b), Mk.branchWrong);
      expect(r.call(M6RcCall.lockout), Mk.lockEarly, reason: 'a try still to come');
      expect(r.call(M6RcCall.on), Mk.onDark);
      expect(r.call(M6RcCall.branch, M6RcBranch.a), isNull);
      expect((r.tries, r.lightsB, r.lightsA, r.settled), (3, true, false, true), reason: 'the last try played at once');
      expect(r.caught, contains(L.caughtBranch));
      // After the last try: লক-আউট is the needless lock-out of a cut-off branch.
      final s = _runOf(M6RcOutcome.branchA);
      _playUntil(s, () => s.settled);
      expect(s.call(M6RcCall.lockout), Mk.lockBranch);
      expect(s.call(M6RcCall.on), Mk.onDark, reason: 'a branch stays dark');
    });

    test('branch B: known only from the last try (S-B is far away); then B right, A wrong, লক-আউট a slip', () {
      final r = _runOf(M6RcOutcome.branchB, setting: 4);
      _playUntil(r, () => r.sbOpen);
      expect(r.settled, isFalse);
      expect(r.call(M6RcCall.branch, M6RcBranch.b), Mk.noBranch, reason: 'not seen yet');
      r.applyStep();
      expect(r.call(M6RcCall.branch, M6RcBranch.a), Mk.branchWrong);
      expect(r.call(M6RcCall.lockout), Mk.lockBranch);
      expect(r.call(M6RcCall.branch, M6RcBranch.b), isNull);
      expect(r.slips, 3);
    });

    test('three slips and the play fails; each round counts its own slips; the docket again each round', () {
      final r = _runOf(M6RcOutcome.main);
      r.applyStep();
      for (var i = 0; i < 3; i++) {
        r.call(M6RcCall.lockout);
      }
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      r.call(M6RcCall.lockout);
      expect(r.percent, 40);
      _playUntil(r, () => r.settled);
      r
        ..call(M6RcCall.lockout)
        ..next();
      expect(r.thorough, isTrue);
      expect(r.tucked, isFalse);
      expect((r.tries, r.taps, r.lightsA, r.lightsB), (0, 0, true, true));
      expect(r.tap(), isFalse, reason: 'no count before the docket is away');
      r.tuck();
      expect(r.tap(), isTrue);
      expect(r.taps, 1);
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; the deadly set; keys unique; lesson points', () {
      final all = <String>[
        ...L.newGuideLines,
        ...L.tasks,
        L.docket,
        L.recloser,
        L.setting(3),
        L.setting(4),
        for (var n = 1; n <= 3; n++) L.round(n),
        L.tally(7),
        L.radio(4),
        L.sceneLabel,
        L.clickerLabel,
        for (final c in M6RcCall.values) L.magnet(c),
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        L.caughtOn,
        L.caughtLock,
        L.caughtBranch,
        L.caughtCount,
        L.caughtCall,
        L.quick,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অন|অফ').hasMatch(l.replaceAll('অন্ধকার', '')), isFalse, reason: 'ON/OFF in English: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'য় ড় ঢ় as base + nukta: $l');
      }
      expect(Mk.all.where((m) => m.deadly).toList(), [Mk.climbMidCycle]);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.8/m6_reclose_count/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      for (final o in M6RcOutcome.values) {
        expect(m6RcLessonPoint(o), inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m6_reclose_count/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m6RecloseCountPacks.keys, ['do_6_8_a']);
    });

    test('lesson words: the coworker\'s push is myth 1 word for word; the deadly card is its reality word for word', () {
      final data = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync());
      Map<String, dynamic>? find68(Object? o) {
        if (o is Map<String, dynamic>) {
          if (o['id'] == '6.8' && o['content'] is Map) return o;
          for (final v in o.values) {
            final x = find68(v);
            if (x != null) return x;
          }
        } else if (o is List) {
          for (final v in o) {
            final x = find68(v);
            if (x != null) return x;
          }
        }
        return null;
      }

      final lesson = find68(data)!;
      final myth = (lesson['content']['myth_buster']['myths'] as List).first as Map;
      expect(L.coworker.line, _nukta(myth['myth'] as String));
      expect(Mk.climbMidCycle.textBn, _nukta(myth['reality'] as String));
      final points = lesson['content']['sections'][0]['points'] as List;
      expect(points, hasLength(3), reason: 'lesson points 0–2');
    });

    test('libraries: same length, big enough, never a rule marked wrong; the three magnets alike', () {
      expectSameLength('magnets', [for (final c in M6RcCall.values) L.magnet(c)]);
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6RcWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      const cw = L.coworker;
      expectSameLength('coworker choice', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker choice', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('every spoken line is listed: his push (rival) and every guide line, why-question, ask and mistake text', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull, reason: 'his exit line is recorded');
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([
        L.intro,
        ...L.tasks,
        L.docketFirst,
        L.pickBranch,
        ...L.whyQ.values,
        L.coworker.asks[1],
        L.callHeld,
        L.allSet,
        L.fail,
        for (final m in Mk.all) m.textBn,
      ]));
      for (final l in [...L.newRivalLines, ...L.newGuideLines]) {
        debugPrint('LINE m6_reclose_count: $l');
      }
    });

    test('tap areas: on the scene, below the header, clear of the guide and its bubble; magnets apart; branch zones inside the sketch', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6RcGeo.forScene(h, 0);
        final rects = <Rect>[g.docket, g.clicker, g.sketch, for (var i = 0; i < 3; i++) g.magnet(i)];
        final guide = Rect.fromLTRB(253, h - 12 - 107, 360, h);
        final bubble = Rect.fromLTRB(147, h - 12 - 107 - 52, 360, h - 12 - 107);
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          expect(r.overlaps(bubble), isFalse, reason: 'h $h: $r under the bubble');
        }
        for (var i = 0; i < 3; i++) {
          expect(g.board.contains(g.magnet(i).center), isTrue);
          expect(g.sketch.overlaps(g.magnet(i)), isFalse, reason: 'a magnet in the tray is not on the sketch');
          for (var j = i + 1; j < 3; j++) {
            expect(g.magnet(i).overlaps(g.magnet(j)), isFalse);
          }
        }
        for (final b in M6RcBranch.values) {
          final z = g.branchZone(b);
          expect(g.sketch.contains(z.topLeft) && g.sketch.contains(z.bottomRight - const Offset(0.1, 0.1)), isTrue, reason: '$b inside the sketch');
          expect(z.contains(g.skEnd(b)), isTrue, reason: 'the branch line runs through its zone');
        }
        expect(g.branchZone(M6RcBranch.a).overlaps(g.branchZone(M6RcBranch.b)), isFalse);
        expect(g.clicker.overlaps(g.board), isFalse);
        expect(g.docket.overlaps(g.clicker), isFalse);
        // Each village carries its letter sign (A / B as on the sketch); the
        // signs follow the dealt mirror.
        for (final mirror in [false, true]) {
          for (final b in M6RcBranch.values) {
            final v = g.village(b, mirror);
            expect(g.villageSign(b, mirror).dx, inInclusiveRange(v.left, v.right), reason: '$b sign at its own village');
          }
          final aLeft = g.villageSign(M6RcBranch.a, mirror).dx < g.villageSign(M6RcBranch.b, mirror).dx;
          expect(aLeft, mirror, reason: 'A behind the pole on the right; mirrored, on the left');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket, the tally and the three magnets', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M6RecloseCountPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.docket), findsOneWidget);
      expect(_label(L.clickerLabel), findsOneWidget);
      for (final c in M6RcCall.values) {
        expect(_label(L.magnet(c)), findsOneWidget);
      }
      expect(find.text(L.setting(m6RcDeal(math.Random(3)).setting)), findsOneWidget, reason: 'the docket shows the setting');
      expect(_live.lightsA && _live.lightsB, isTrue, reason: 'no fault before the docket is away');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time; with the docket away the task is the count', (t) async {
      final c = await _open(t, 5);
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
      await _tuck(t);
      expect(c.read(guideDirectorProvider).line, contains(L.askCount));
      expect(_label(L.docket), findsNothing, reason: 'tucked away');
      await _close(t, c);
    });

    // One play where he is asked about in the reason ("ওর কথায় উঠলেন না কেন?");
    // one with him on a branch-A round (S-A opens on our pole).
    final flowSeeds = [
      _seedWhere((d) => d.why[d.coworkerRound] == M6RcWhy.refused && d.coworkerRound > 0),
      _seedWhere((d) => d.rounds[d.coworkerRound].outcome == M6RcOutcome.branchA && d.why[d.coworkerRound] != M6RcWhy.refused && d.setting == 4),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three storms, the tally, the magnets, reasons; he is refused → pass', (t) async {
        final d = m6RcDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRound(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.8/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.8/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtCount), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final mainFirstAlone = _seedWhere((d) => d.rounds.first.outcome == M6RcOutcome.main && d.coworkerRound != 0);
    testWidgets('a slip (লক-আউট with tries left) shows its card; the cycle waits, then plays on in the same round; a branch magnet off the lines asks which', (t) async {
      final c = await _open(t, mainFirstAlone);
      await _tuck(t);
      await _pump(t, 1200);
      expect(_live.lightsA || _live.lightsB, isFalse, reason: 'the fault');
      await _drop(t, M6RcCall.lockout, _target(M6RcCall.lockout));
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.lockEarly.textBn), findsOneWidget);
      final step = _live.step;
      await _pump(t, 5000);
      expect(_live.step, step, reason: 'the cycle waits while the card is read');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0);
      // শাখা বন্ধ dropped on the sketch but off both branch lines: nothing.
      await _drop(t, M6RcCall.branch, _geo.sk(0.12, 0.12));
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.pickBranch));
      expect(await _pumpUntil(t, () => _live.settled, maxMs: 20000), isTrue, reason: 'the cycle played on');
      await _callRight(t);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.lockEarly.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, mainFirstAlone);
      await _tuck(t);
      await _pump(t, 1200);
      for (var i = 0; i < 3; i++) {
        await _drop(t, M6RcCall.on, _target(M6RcCall.on));
        if (i < 2) {
          expect(find.text(Mk.onDark.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('no giveaway: the guide line, its task and the hint stay the same across the last trip of a main round', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, mainFirstAlone);
      final guide = find.byKey(const ValueKey('hud-guide'));
      IdleHint hint() => t.widget<IdleHint>(find.byType(IdleHint).first);
      await _tuck(t);
      expect(await _pumpUntil(t, () => _live.step == _live.steps.length - 1, maxMs: 20000), isTrue, reason: 'just before the last trip');
      expect(_live.settled, isFalse);
      final line = c.read(guideDirectorProvider).line;
      final key = hint().waitKey;
      final waiting = hint().waiting;
      expect(await _pumpUntil(t, () => _live.settled, maxMs: 2000), isTrue, reason: 'the last trip');
      await _pump(t, 1500);
      expect(c.read(guideDirectorProvider).line, line, reason: 'no word when R locks out');
      expect(hint().waitKey, key, reason: 'the hint does not reset at the lock-out');
      expect(hint().waiting, waiting);
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await _pump(t, 400);
      expect(c.read(guideDirectorProvider).line, contains(L.askCount), reason: 'the same task after the lock-out');
      await _close(t, c);
    });

    final himFirst = _seedWhere((d) => d.coworkerRound == 0);
    testWidgets('listening to him (lesson myth 1) = up the pole mid-cycle: the scene freezes first, then the card', (t) async {
      final c = await _open(t, himFirst);
      await _tuck(t);
      expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 16000), isTrue);
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final step = _live.step;
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(_live.step, step, reason: 'the next try waited for him');
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.climbMidCycle.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('in his dead pause the next try and the board wait: a magnet brings him in at once and decides nothing', (t) async {
      final d = m6RcDeal(math.Random(himFirst));
      final c = await _open(t, himFirst);
      await _tuck(t);
      expect(await _pumpUntil(t, () => _live.coworkerPause, maxMs: 16000), isTrue);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet: his 1.2–2.4 s timer');
      await _drop(t, M6RcCall.lockout, _target(M6RcCall.lockout));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.byType(MistakeCard), findsNothing);
      final step = _live.step;
      await _pump(t, 6000);
      expect(_live.step, step, reason: 'the next try waits for him');
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await _pickRight(t, L.coworker.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(await _pumpUntil(t, () => _live.settled, maxMs: 20000), isTrue, reason: 'after him the cycle goes on');
      expect(_live.tries, d.setting);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, mainFirstAlone);
      await _tuck(t);
      expect(await _pumpUntil(t, () => _live.settled, maxMs: 20000), isTrue);
      await _callRight(t);
      // The deck is up at once (it covers the tally and the magnet tray);
      // the scene above it — the sketch, the field — takes nothing.
      expect(find.byType(ChoiceDeck), findsOneWidget);
      final step = _live.step;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.sk(0.5, 0.3) * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(_geo.sk(0.2, 0.2) * _k, const Offset(80, 20));
        await t.pump(const Duration(milliseconds: 150));
        await t.tapAt(const Offset(200, 300) * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.step, step);
      expect(_live.index, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byKey(const ValueKey('choice-confirm')), findsNothing, reason: 'no card opened by a scene touch');
      expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue);
      expect(find.text(L.radio(_live.tries)), findsOneWidget, reason: 'the radio reads back R\'s counter after the call');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M6RcWhy.lockout]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a tap on the docket first; then three taps on nothing show a hand that presses no magnet', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, mainFirstAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the docket still up');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way on, not a pick');
      await _tuck(t);
      expect(scene().showing, isFalse);
      final empty = const Offset(160, 200) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      final opts = scene().debugOptions;
      if (opts.isNotEmpty) {
        expect(opts, hasLength(5), reason: 'a sweep over the three magnets and both branch lines alike');
        expect(scene().debugFrame?.ripple, isNull);
      }
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
