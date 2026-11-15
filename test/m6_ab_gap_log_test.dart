// Lesson 6.4 (AB সুইচ ও আইসোলেটর), কাজ 1 "এক টানে তিন ফেজ": the rules (the
// earth lead looked at and whole before the handle is held — else a slip and
// the handle locks until it is put right; the stroke begun before the breaker
// OFF = deadly (R4/X3); a stalled stroke a slip, speed never (M6-3); a tick
// only for a phase seen fully open; a phone report only for the phase seen
// stuck; a needless report a slip (R32)), the deal, the libraries, the
// coworker's push in the breaker wait (listening = deadly, B1), and the level
// in the shell: the guide first, two full clean plays (a reason each job, the
// coworker refused, earth faults put right, a stuck phase phoned in), a slip
// card that keeps the job, three slips, the deadly freeze (stroke on load;
// listening to "সামান্য লোড"), the handle waits for the coworker, and the
// gesture hand only while the level waits.
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
import 'package:slm_flutter/features/game/m6_ab_gap_log.dart';
import 'package:slm_flutter/features/game/m6_ab_gap_log_world.dart' show M6AbRig, m6SceneBladeTips, m6SceneJaws;
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
  rungId: '6.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6AbGapLogPacks['do_6_4_a']!;
typedef L = M6AbGapLogLines;
typedef Mk = M6AbGapLogMistakes;

M6AbJob _job({M6AbEarth earth = M6AbEarth.ok, int stuck = -1, bool part = false, bool wait = false}) =>
    M6AbJob(kind: M6AbBreak.horizontal, place: M6AbPlace.road, earth: earth, stuck: stuck, part: part, wait: wait);

M6AbRun _runOf(M6AbJob j0, [M6AbJob? j1]) =>
    M6AbRun(M6AbDeal(jobs: [j0, j1 ?? _job(wait: !j0.wait)], waitJob: j0.wait ? 0 : 1, why: const [M6AbWhy.seen, M6AbWhy.earth]));

/// A run ready to log: earth looked, breaker OFF, stroked.
M6AbRun _opened(M6AbJob j) {
  final r = _runOf(j)
    ..lookEarth()
    ..call();
  if (j.wait) r.replyWait();
  r.confirmOff();
  expect(r.grab(), isNull);
  expect(r.beginStroke(), isNull);
  r.strokeDone();
  expect(r.stroked, isTrue);
  return r;
}

/// Plays the run's job to a full docket with the slips asked for.
void _playWith(M6AbRun r, {bool earthSlip = false, bool stall = false, bool unseen = false, bool tickStuck = false, bool needless = false}) {
  final j = r.job;
  if (earthSlip) expect(r.grab(), Mk.earthUnchecked);
  r
    ..lookEarth()
    ..fixEarth(j.earth)
    ..call();
  if (j.wait) r.replyWait();
  r.confirmOff();
  expect(r.grab(), isNull);
  expect(r.beginStroke(), isNull);
  if (stall) {
    expect(r.stall(), Mk.stall);
    r
      ..grab()
      ..beginStroke();
  }
  r.strokeDone();
  if (unseen) expect(r.tick(0), Mk.unseen);
  for (var p = 0; p < 3; p++) {
    r.view(p);
  }
  if (tickStuck && j.stuck >= 0) expect(r.tick(j.stuck), Mk.tickStuck);
  if (needless) expect(r.report(j.stuck == 0 ? 1 : 0), Mk.needless);
  for (var p = 0; p < 3; p++) {
    if (p == j.stuck) {
      expect(r.report(p), isNull);
    } else {
      expect(r.tick(p), isNull);
    }
  }
  expect(r.finishJob(math.Random(r.slips)), isTrue);
}

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
M6AbGeo get _geo => M6AbGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _earthLook(WidgetTester t) async {
  await t.dragFrom(_geo.leadSwipeFrom * _k, const Offset(0, 90));
  await _pump(t, 400);
}

Future<void> _fix(WidgetTester t, M6AbEarth e) async {
  const v = M6AbGeo.view;
  if (e == M6AbEarth.cut) {
    await t.dragFrom((v.topLeft + M6EarthView.spareHome) * _k, (M6EarthView.gap - M6EarthView.spareHome) * _k);
  } else if (e == M6AbEarth.loose) {
    await t.longPressAt((v.topLeft + M6EarthView.nut) * _k);
  }
  await _pump(t, 400);
}

Future<void> _closeView(WidgetTester t) async {
  await t.tap(_label(L.viewClose));
  await _pump(t, 300);
}

Future<void> _phone(WidgetTester t) async {
  await t.tap(_label(L.phone));
  await _pump(t, 300);
}

/// Hold the handle, then drag it along its arc to [upTo] (1 = the OFF stop);
/// [stallMs] > 0: stop there that long before letting go.
Future<void> _stroke(WidgetTester t, {double upTo = 1, int stallMs = 0}) async {
  final g = _geo;
  final gesture = await t.startGesture(g.grip(0) * _k);
  await t.pump(const Duration(milliseconds: 650));
  for (var i = 1; i <= 20; i++) {
    await gesture.moveTo(g.grip(upTo * i / 20) * _k);
    await t.pump(const Duration(milliseconds: 20));
  }
  if (stallMs > 0) await _pump(t, stallMs);
  await gesture.up();
  await _pump(t, 400);
}

/// Tilt up and pan R → Y → B.
Future<void> _lookAll(WidgetTester t) async {
  await t.dragFrom(_geo.swipeFrom * _k, const Offset(0, -110));
  await _pump(t, 300);
  for (var i = 0; i < 2; i++) {
    await t.dragFrom(M6AbGeo.view.center * _k, const Offset(-100, 0));
    await _pump(t, 300);
  }
}

Future<void> _tickBox(WidgetTester t, int p) async {
  await t.tap(_label(L.box(p)));
  await _pump(t, 400);
}

Future<void> _report(WidgetTester t, int p) async {
  await _phone(t);
  await t.tap(_label(L.key(p)));
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue);
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6AbGapLogPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6AbDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6AbDeal(math.Random(s))));

/// The coworker comes in the breaker wait: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// One job played right (the coworker refused in its wait).
Future<void> _playJob(WidgetTester t, M6AbDeal d, int i) async {
  final j = d.jobs[i];
  await _earthLook(t);
  if (j.earth != M6AbEarth.ok) await _fix(t, j.earth);
  await _closeView(t);
  await _phone(t);
  await _pump(t, 1700);
  if (j.wait) await _refuse(t);
  expect(find.textContaining(j.wait ? L.replyOff : L.replyNow[j.reply]), findsOneWidget, reason: 'the breaker is OFF (job $i)');
  await _stroke(t);
  expect(find.byType(MistakeCard), findsNothing, reason: 'a clean stroke (job $i)');
  await _lookAll(t);
  for (var p = 0; p < 3; p++) {
    if (p != j.stuck) await _tickBox(t, p);
  }
  if (j.stuck >= 0) await _report(t, j.stuck);
  expect(find.byType(MistakeCard), findsNothing, reason: 'a clean log (job $i)');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (job $i)');
  await _pump(t, 700);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  await _pump(t, 3000);
}

void main() {
  group('rules', () {
    test('deals: one horizontal and one vertical break; one wait job; earth, stuck phase and reply vary; the reason fits; plays differ', () {
      final seen = <String>{};
      var stuckJobs = 0;
      var parts = 0;
      final earths = <M6AbEarth>{};
      final whys = <M6AbWhy>{};
      final waits = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m6AbDeal(math.Random(s));
        expect(d.jobs.map((j) => j.kind).toSet(), M6AbBreak.values.toSet());
        expect(d.jobs.where((j) => j.wait), hasLength(1));
        expect(d.jobs[d.waitJob].wait, isTrue);
        expect(d.jobs[0].place, isNot(d.jobs[1].place));
        expect(d.why[0], isNot(d.why[1]));
        waits.add(d.waitJob);
        for (var i = 0; i < 2; i++) {
          final j = d.jobs[i];
          expect(m6AbWhysFor(j), contains(d.why[i]));
          if (d.why[i] == M6AbWhy.wait) expect(j.wait, isTrue);
          if (d.why[i] == M6AbWhy.stuck) expect(j.stuck, greaterThanOrEqualTo(0));
          earths.add(j.earth);
          whys.add(d.why[i]);
          if (j.stuck >= 0) {
            stuckJobs++;
            if (j.part) parts++;
          }
        }
        seen.add('${d.waitJob}|${d.jobs.map((j) => '${j.kind.name}${j.earth.name}${j.stuck}${j.part}${j.reply}').join(',')}|${d.why}');
      }
      expect(seen.length, greaterThan(150));
      expect(waits, {0, 1});
      expect(earths, M6AbEarth.values.toSet());
      expect(whys, M6AbWhy.values.toSet());
      // ~40 % of jobs have a stuck phase; both degrees are dealt.
      expect(stuckJobs / 600, inInclusiveRange(0.3, 0.5));
      expect(parts, inInclusiveRange(stuckJobs ~/ 4, stuckJobs * 3 ~/ 4));
    });

    test('the handle before the earth look is a slip and locks it; a cut or loose lead a slip until fixed', () {
      final r = _runOf(_job());
      expect(r.grab(), Mk.earthUnchecked);
      expect(r.handleLocked, isTrue);
      expect(r.grab(), isNull, reason: 'locked: no second slip');
      expect(r.slips, 1);
      r.lookEarth();
      expect(r.handleLocked, isFalse, reason: 'looked and whole');
      expect(r.grab(), isNull);
      for (final e in [M6AbEarth.cut, M6AbEarth.loose]) {
        final s = _runOf(_job(earth: e))..lookEarth();
        expect(s.earthSafe, isFalse);
        expect(s.grab(), Mk.earthBroken);
        expect(s.handleLocked, isTrue);
        final other = e == M6AbEarth.cut ? M6AbEarth.loose : M6AbEarth.cut;
        expect(s.fixEarth(other), isFalse, reason: 'the wrong fix does nothing');
        expect(s.fixEarth(e), isTrue);
        expect(s.handleLocked, isFalse);
        expect(s.grab(), isNull);
        expect(s.slips, 1);
      }
      // A fix needs the look first; a whole lead takes no fix.
      final u = _runOf(_job(earth: M6AbEarth.cut));
      expect(u.fixEarth(M6AbEarth.cut), isFalse);
      final ok = _runOf(_job())..lookEarth();
      expect(ok.fixEarth(M6AbEarth.cut), isFalse);
      expect(ok.fixEarth(M6AbEarth.loose), isFalse);
    });

    test('the stroke before the breaker OFF is deadly (R4): not called, waiting for the reply, or in the "এক মিনিট" wait', () {
      final a = _runOf(_job())..lookEarth();
      expect(a.grab(), isNull);
      expect(a.beginStroke(), Mk.onLoad);
      expect(a.deadly, Mk.onLoad);
      final b = _runOf(_job())
        ..lookEarth()
        ..call();
      b.grab();
      expect(b.beginStroke(), Mk.onLoad, reason: 'called, no reply yet');
      final c = _runOf(_job(wait: true))
        ..lookEarth()
        ..call()
        ..replyWait();
      expect(c.waiting, isTrue);
      expect(m6AbPushGate(c), isTrue);
      c.grab();
      expect(c.beginStroke(), Mk.onLoad, reason: '"এক মিনিট" is not OFF');
      final d = _runOf(_job(wait: true))
        ..lookEarth()
        ..call()
        ..replyWait()
        ..confirmOff();
      expect(m6AbPushGate(d), isFalse);
      d.grab();
      expect(d.beginStroke(), isNull);
      d.strokeDone();
      expect(d.stroked, isTrue);
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.onLoad, Mk.pushLoad});
    });

    test('a stalled stroke is a slip (the handle falls back); nothing else about the stroke is scored', () {
      final r = _runOf(_job())
        ..lookEarth()
        ..call()
        ..confirmOff();
      r.grab();
      expect(r.beginStroke(), isNull);
      expect(r.stall(), Mk.stall);
      expect(r.stroked, isFalse);
      r.grab();
      r.beginStroke();
      r.strokeDone();
      expect(r.stroked, isTrue);
      expect(r.stall(), isNull, reason: 'done: no stall');
      expect(r.slips, 1);
      expect(Mk.all.where((m) => m.key.contains('fast') || m.key.contains('speed')), isEmpty, reason: 'M6-3: speed is never a slip');
    });

    test('the log: a tick only for a phase seen fully open; unseen or before the stroke a slip; a stuck or part-open phase ticked a slip', () {
      final pre = _runOf(_job())..lookEarth();
      expect(pre.tick(0), Mk.unseen, reason: 'before the stroke');
      final r = _opened(_job(stuck: 1));
      r.view(0);
      expect(r.tick(2), Mk.unseen);
      expect(r.tick(0), isNull);
      expect(r.tick(0), isNull, reason: 'a second tick does nothing');
      r
        ..view(1)
        ..view(2);
      expect(r.tick(1), Mk.tickStuck);
      expect(r.tick(2), isNull);
      expect(r.logged, isFalse);
      expect(r.finishJob(), isFalse);
      expect(r.report(1), isNull);
      expect(r.logged, isTrue);
      expect(r.finishJob(), isTrue);
      expect(r.caught, contains(L.caughtStuck));
      expect(r.slips, 2);
      final p = _opened(_job(stuck: 0, part: true))..view(0);
      expect(p.job.blade(0), M6AbBlade.part);
      expect(p.tick(0), Mk.tickStuck, reason: 'only just clear is not fully open');
      expect(m6BladeOpen(M6AbBlade.part), inExclusiveRange(0.0, 0.3));
    });

    test('a report: only for the phase seen not fully open; a clear phase reported is a needless report (R32); unseen a slip', () {
      final r = _opened(_job());
      expect(r.report(0), Mk.unseen);
      r.view(0);
      expect(r.report(0), Mk.needless);
      expect(r.reported, -1);
      final s = _opened(_job(stuck: 2));
      s
        ..view(0)
        ..view(1)
        ..view(2);
      expect(s.report(1), Mk.needless, reason: 'the wrong phase');
      expect(s.report(2), isNull);
      expect(s.report(2), isNull, reason: 'one report a job');
      expect(s.tick(2), isNull, reason: 'phoned in: its box takes no tick');
      expect(s.ticked, isEmpty);
      // The report needs the switch opened.
      final u = _runOf(_job(stuck: 0))..lookEarth();
      expect(u.report(0), isNull);
    });

    test('three slips and the play fails; a clean play of two jobs passes with its caught lines', () {
      final r = _runOf(_job());
      for (var i = 0; i < 3; i++) {
        r.tick(0);
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      // A clean play.
      final c = M6AbRun(M6AbDeal(
        jobs: [_job(earth: M6AbEarth.cut, wait: true), _job(stuck: 1)],
        waitJob: 0,
        why: const [M6AbWhy.wait, M6AbWhy.stuck],
      ));
      for (var j = 0; j < 2; j++) {
        c
          ..lookEarth()
          ..fixEarth(c.job.earth)
          ..call();
        if (c.job.wait) c.replyWait();
        c.confirmOff();
        expect(c.grab(), isNull);
        c
          ..beginStroke()
          ..strokeDone();
        for (var p = 0; p < 3; p++) {
          c.view(p);
          if (p == c.job.stuck) {
            c.report(p);
          } else {
            c.tick(p);
          }
        }
        expect(c.finishJob(), isTrue);
        c.next();
      }
      expect(c.passed, isTrue);
      expect(c.percent, 100);
      expect(c.caught, containsAll([L.caughtWait, L.caughtEarth, L.caughtStuck, L.caughtSeen, L.caughtStroke]));
    });

    test('the reason fits what was done: a slip rules out the question it would make untrue', () {
      // Dealt earth then stroke; an earth slip in job 1 and a stall in job 2.
      final r = M6AbRun(M6AbDeal(jobs: [_job(), _job(wait: true)], waitJob: 1, why: const [M6AbWhy.earth, M6AbWhy.stroke]));
      _playWith(r, earthSlip: true);
      expect(r.why, isNot(M6AbWhy.earth));
      expect(r.why, isIn([M6AbWhy.seen, M6AbWhy.stroke]));
      final first = r.why;
      r.next();
      _playWith(r, stall: true);
      expect(r.why, isNot(M6AbWhy.stroke));
      expect(r.why, isNot(first), reason: 'never the question job 1 asked');
      // No slip: the dealt question stays.
      final c = M6AbRun(M6AbDeal(jobs: [_job(stuck: 2), _job(wait: true)], waitJob: 1, why: const [M6AbWhy.stuck, M6AbWhy.wait]));
      _playWith(c);
      expect(c.why, M6AbWhy.stuck);
      c.next();
      _playWith(c);
      expect(c.why, M6AbWhy.wait);
      // A stuck phase ticked: neither the stuck nor the seen question.
      final t = M6AbRun(M6AbDeal(jobs: [_job(stuck: 1), _job(wait: true)], waitJob: 1, why: const [M6AbWhy.stuck, M6AbWhy.wait]));
      _playWith(t, tickStuck: true);
      expect(t.why, isIn([M6AbWhy.earth, M6AbWhy.stroke]));
      // Random deals and random slips: never an untrue question.
      final rnd = math.Random(7);
      for (var s = 0; s < 400; s++) {
        final run = M6AbRun(m6AbDeal(math.Random(s)));
        for (var i = 0; i < 2; i++) {
          final f = [for (var k = 0; k < 5; k++) rnd.nextDouble() < 0.25];
          _playWith(run, earthSlip: f[0], stall: f[1], unseen: f[2], tickStuck: f[3], needless: f[4]);
          final w = run.why!;
          final j = run.job;
          final stuckTicked = f[3] && j.stuck >= 0;
          if (f[0]) expect(w, isNot(M6AbWhy.earth));
          if (f[1]) expect(w, isNot(M6AbWhy.stroke));
          // Earth, stroke and sight all slipped in a job with no wait: nothing
          // is fully true, so the seen question (every phase seen by the end).
          final none = run.validWhys().isEmpty;
          if (none) expect(w, M6AbWhy.seen);
          if ((f[2] || stuckTicked) && !none) expect(w, isNot(M6AbWhy.seen));
          if (f[2] || stuckTicked || f[4]) expect(w, isNot(M6AbWhy.stuck));
          if (w == M6AbWhy.wait) expect(j.wait, isTrue);
          if (w == M6AbWhy.stuck) expect(j.stuck, greaterThanOrEqualTo(0));
          if (!f.contains(true) && (i == 0 || run.deal.why[1] != run.asked[0])) expect(w, run.deal.why[i]);
          if (i == 1 && run.validWhys().any((x) => x != run.asked[0])) expect(w, isNot(run.asked[0]));
          run.next();
        }
      }
    });

    test('the scene blades follow the handle: in their jaws before the stroke, open only as far as each can', () {
      final g = _geo;
      final jaws = m6SceneJaws(g);
      for (final kind in M6AbBreak.values) {
        final rig = M6AbRig(place: M6AbPlace.road, kind: kind, blades: [1.0, 0.0, m6BladeOpen(M6AbBlade.part)]);
        final at0 = m6SceneBladeTips(g, rig, 0);
        for (var i = 0; i < 3; i++) {
          expect((at0[i] - jaws[i]).distance, lessThan(0.01), reason: '$kind phase $i before the stroke');
        }
        final half = m6SceneBladeTips(g, rig, 0.5);
        final full = m6SceneBladeTips(g, rig, 1);
        expect((half[0] - jaws[0]).distance, greaterThan(1), reason: 'the open blade turns with the handle');
        expect((full[0] - half[0]).distance, greaterThan(1));
        expect((full[1] - jaws[1]).distance, lessThan(0.01), reason: 'the stuck blade stays in its jaw');
        expect(full[2], half[2], reason: 'the part-open blade stops just clear');
        expect((full[2] - jaws[2]).distance, inExclusiveRange(0.5, 12));
      }
    });

    test('English digits only; jol not pani; every mistake has its picture; keys unique; lesson points; every art file used', () {
      final all = <String>[
        L.title,
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.locked,
        L.sceneLabel,
        L.handleLabel,
        L.docket,
        L.gapRow,
        L.phone,
        L.substation,
        L.viewClose,
        L.gapView,
        L.earthView,
        L.spareLead,
        L.clampNut,
        L.stuckKeys,
        for (var i = 0; i < 2; i++) L.job(i),
        for (var p = 0; p < 3; p++) ...[L.box(p), L.key(p), L.reportCard(p), L.reportSent(p)],
        L.myCall,
        ...L.replyNow,
        L.replyWait,
        L.replyOff,
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
        L.caughtWait,
        L.caughtEarth,
        L.caughtStuck,
        L.caughtSeen,
        L.caughtStroke,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.4/m6_ab_gap_log/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
      const dir = 'assets/game/art/m6_ab_gap_log/';
      final used = {for (final m in Mk.all) if (m.art.startsWith(dir)) m.art.split('/').last};
      final files = Directory('assets/game/art/m6_ab_gap_log').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6AbGapLogPacks.keys, ['do_6_4_a']);
      // The operator texts give only the breaker status.
      for (final r in [...L.replyNow, L.replyWait, L.replyOff]) {
        expect(r, contains('ব্রেকার'));
      }
    });

    test('libraries: same length, big enough, one right per deal, never a myth marked right', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6AbWhy.values) {
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
      expectSameLength('report keys', [for (var p = 0; p < 3; p++) L.reportCard(p)]);
    });

    test('rival lines: his exit is recorded; his push is the lesson myth word for word and listed for recording; the guide drafts are listed', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.coworker.line, 'সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না।');
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.newGuideLines, [L.intro, L.askJob, L.askLog, L.locked, L.callHeld, L.allSet, L.fail]);
      for (final l in [...L.newRivalLines]) {
        debugPrint('RIVAL m6_ab_gap_log: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas stay on the scene, under the header, above the phone row, clear of the docket, the views and the guide', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M6AbGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (final r in [g.handleHit, g.earthZone, M6AbGeo.docket, M6AbGeo.view]) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(125), reason: 'h $h: below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: above the phone row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, g.groundY - 129, 360, g.groundY - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        expect(g.handleHit.overlaps(M6AbGeo.view), isFalse, reason: 'h $h');
        expect(g.handleHit.overlaps(M6AbGeo.docket), isFalse);
        expect(M6AbGeo.docket.overlaps(M6AbGeo.view), isFalse);
        expect(g.structureZone.contains(g.swipeFrom), isTrue);
        expect(M6AbGeo.view.contains(g.swipeFrom), isFalse, reason: 'h $h: the tilt starts on the open scene');
        expect(g.earthZone.contains(g.leadSwipeFrom), isTrue);
        // The arc reads back its own grip positions.
        for (var k = 0; k <= 10; k++) {
          expect(g.progressAt(g.grip(k / 10)), closeTo(k / 10, 0.001));
          expect(g.handleHit.contains(g.grip(k / 10)), isTrue);
        }
        expect(g.progressAt(g.pivot + const Offset(-30, 10)), isNull, reason: 'behind the pole');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket, the phone and the handle', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M6AbGapLogPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.text('${L.docket} · ${L.job(0)}'), findsOneWidget);
      for (var p = 0; p < 3; p++) {
        expect(_label(L.box(p)), findsOneWidget);
      }
      expect(_label(L.phone), findsOneWidget);
      expect(_label(L.handleLabel), findsOneWidget);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askJob)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with an earth fault and a stuck phase, one with the wait first.
    final flowSeeds = <int>{
      _seedWhere((d) => d.jobs.any((j) => j.earth == M6AbEarth.cut) && d.jobs.any((j) => j.stuck >= 0) && d.waitJob == 1),
      _seedWhere((d) => d.waitJob == 0 && d.jobs.any((j) => j.earth == M6AbEarth.loose)),
    }.toList();
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): two switches — earth, breaker, stroke, sight, log, reasons; he is refused → pass', (t) async {
        final d = m6AbDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 2; i++) {
          await _playJob(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.4/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.4/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtSeen), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final okFirst = _seedWhere((d) => d.jobs[0].earth == M6AbEarth.ok && !d.jobs[0].wait);
    testWidgets('the handle before the earth look: a slip card; the same job goes on and the handle stays locked until the look', (t) async {
      final c = await _open(t, okFirst);
      await _stroke(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.earthUnchecked.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _stroke(t);
      expect(find.byType(MistakeCard), findsNothing, reason: 'locked: no second slip');
      expect(c.read(guideDirectorProvider).line, L.locked);
      expect(find.text('${L.docket} · ${L.job(0)}'), findsOneWidget, reason: 'the same job');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.earthUnchecked.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a stalled stroke is a slip: the handle falls back; then one motion opens it', (t) async {
      final c = await _open(t, okFirst);
      await _earthLook(t);
      await _closeView(t);
      await _phone(t);
      await _pump(t, 1700);
      await _stroke(t, upTo: 0.5, stallMs: 1000);
      expect(find.text(Mk.stall.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _stroke(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.stall.key);
      await _close(t, c);
    });

    testWidgets('three slips (ticks on unseen phases) strike the level out', (t) async {
      final c = await _open(t, okFirst);
      for (var i = 0; i < 3; i++) {
        await _tickBox(t, i);
        if (i < 2) {
          expect(find.text(Mk.unseen.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the stroke before the breaker OFF: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, okFirst);
      await _earthLook(t);
      await _closeView(t);
      await _stroke(t);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.onLoad.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final waitFirst = _seedWhere((d) => d.waitJob == 0 && d.jobs[0].earth == M6AbEarth.ok);
    testWidgets('listening to "সামান্য লোড" in the wait = deadly: freeze, then the card', (t) async {
      final c = await _open(t, waitFirst);
      await _phone(t);
      await _pump(t, 1700);
      expect(find.textContaining(L.replyWait), findsOneWidget);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      expect(find.textContaining(L.replyOff), findsNothing, reason: 'the OFF waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.pushLoad.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: the handle in the wait waits for the coworker; he cuts in at once; the OFF comes after him', (t) async {
      final c = await _open(t, waitFirst);
      await _earthLook(t);
      await _closeView(t);
      await _phone(t);
      await _pump(t, 1500);
      expect(find.textContaining(L.replyWait), findsOneWidget);
      // At once, well inside his 1.2–2.4 s timer: hold the handle.
      final gesture = await t.startGesture(_geo.grip(0) * _k);
      await t.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(_geo.grip(0.5) * _k);
      await t.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'the handle did not move');
      await _refuse(t);
      expect(find.textContaining(L.replyOff), findsOneWidget);
      await _stroke(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final stuckFirst = _seedWhere((d) => d.jobs[0].stuck >= 0 && !d.jobs[0].wait && d.jobs[0].earth == M6AbEarth.ok);
    testWidgets('the stuck phase: ticking it is a slip; a needless report is a slip; its key and ✓ phone it in', (t) async {
      final d = m6AbDeal(math.Random(stuckFirst));
      final j = d.jobs[0];
      final c = await _open(t, stuckFirst);
      await _earthLook(t);
      await _closeView(t);
      await _phone(t);
      await _pump(t, 1700);
      await _stroke(t);
      await _lookAll(t);
      await _tickBox(t, j.stuck);
      expect(find.text(Mk.tickStuck.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      final clear = (j.stuck + 1) % 3;
      await _report(t, clear);
      expect(find.text(Mk.needless.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // A key tapped opens its preview and answers nothing; ✕ sets it aside.
      await _phone(t);
      await t.tap(_label(L.key(j.stuck)));
      await _pump(t, 500);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, hasLength(2));
      await t.tap(_label(L.key(j.stuck)));
      await _pump(t, 200);
      expect(await confirmChoice(t), isTrue);
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing);
      for (var p = 0; p < 3; p++) {
        if (p != j.stuck) await _tickBox(t, p);
      }
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the job is logged: the reason deck');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.tickStuck.key, Mk.needless.key]);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the handle, the phone and the docket alike while waiting; none during the reply', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, waitFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle before the call');
      expect(scene().debugOptions, hasLength(3), reason: 'the handle, the phone, the docket');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _phone(t);
      await _pump(t, 1500);
      expect(find.textContaining(L.replyWait), findsOneWidget);
      expect(scene().showing, isFalse, reason: 'the reply is pending: no hand');
      await _close(t, c);
    });
  });
}
