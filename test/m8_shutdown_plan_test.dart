// Lesson 8.3 (SoP: সময়ের মূল্য), কাজ 2 "শাটডাউনের ছক": the rules (a maintenance
// block wholly inside 06:00–17:00 — both edges allowed; a job over 6 h also at
// least 72 h after 'এখন'; an emergency LT wire break inside the live limit of
// its zone, night allowed; wheels that match the board; the shutdown morning:
// ask every porch first, the lever not while a para has not heard, 'আগে জানাই'
// only when one did not), the deal, the libraries, the coworker's two pushes
// (listening = a slip; the level has no deadly act), the drawn places, and the
// level in the shell: the guide first, a full clean play (a block dragged onto
// the planner, a reason pick each job, the coworker refused, the notice wheels
// and the mic, the lane), a slip card that keeps the step, three slips, the
// confirm and the lever wait for the coworker, the praise window takes no
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
import 'package:slm_flutter/features/game/m8_shutdown_plan.dart';
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
  rungId: '8.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8ShutdownPlanPacks['do_8_3_b']!;
typedef L = M8ShutdownPlanLines;
typedef Mk = M8ShutdownPlanMistakes;

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
M8PlanGeo get _geo => M8PlanGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8PlanRun get _live => M8ShutdownPlanProbe.run!;

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

/// The block of the current job dragged onto [day] from [hour].
Future<void> _place(WidgetTester t, int day, int hour) async {
  final len = _live.job.len;
  final g = _geo;
  final to = Offset(g.hourX(hour + len / 2), g.strip(day).center.dy);
  final at = _live.placed;
  // From the tray, or picked up from where it stands on the board.
  await _drag(t, at == null ? g.trayBlock(len).center : g.blockRect(at.$1, at.$2, len).center, to);
  expect(_live.placed, (day, hour));
}

/// Wheel [i] swiped until it shows [target] (up = next).
Future<void> _wheelTo(WidgetTester t, int i, int target) async {
  final n = i == 0 ? 5 : 24;
  int cur() => _live.wheels[i];
  var guard = 0;
  while (cur() != target && guard++ < 30) {
    final fwd = i == 2 ? ((target - cur()) % n + n) % n : ((target - cur()) % n + n) % n;
    final up = fwd <= n - fwd;
    final steps = math.min(up ? fwd : n - fwd, 6);
    final c = _geo.wheel(i).center;
    await _drag(t, c, c + Offset(0, (up ? -1 : 1) * (30.0 * steps + 3)));
  }
  expect(cur(), target);
}

Future<void> _hold(WidgetTester t, Offset design, int ms) async {
  final g = await t.startGesture(design * _k);
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

/// A HUD button held (found by its label; the lever).
Future<void> _holdLabel(WidgetTester t, String label, int ms) async {
  final g = await t.startGesture(t.getCenter(_label(label)));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8ShutdownPlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8PlanDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8PlanDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t, M8PlanPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// A reason after a right step.
Future<void> _reason(WidgetTester t, M8PlanDeal d, int step) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (step $step)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[step == 4 ? 3 : step]]!);
  await _pump(t, 3000);
}

/// One job placed right and confirmed (the coworker refused if dealt here).
Future<void> _playJob(WidgetTester t, M8PlanDeal d, int i) async {
  final job = d.jobs[i];
  expect(_live.index, i);
  final (day, hour) = job.validPlacements[job.validPlacements.length ~/ 2];
  await _place(t, day, hour);
  if (d.push == M8PlanPush.notice && i == d.longJob) await _refuse(t, d.push);
  await t.tap(_label(L.confirm));
  await _pump(t, 500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  expect(_live.roundDone, isTrue, reason: 'job $i');
  await _reason(t, d, i);
}

Future<void> _playNotice(WidgetTester t, M8PlanDeal d, {int settle = 3000}) async {
  expect(_live.index, 3);
  final (day, hour) = _live.noticeBlock;
  await _wheelTo(t, 0, day);
  await _wheelTo(t, 1, hour);
  await _wheelTo(t, 2, hour + _live.noticeJob.len);
  await _hold(t, _geo.mic, kM8MicMs + 300);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(_live.announced, isTrue);
  if (settle > 0) await _pump(t, settle);
}

Future<void> _playMorning(WidgetTester t, M8PlanDeal d) async {
  expect(_live.index, 4);
  if (d.push == M8PlanPush.miking) await _refuse(t, d.push);
  for (var i = 0; i < 3; i++) {
    await _tapAt(t, _geo.porch(i).center);
  }
  await _pump(t, 800);
  expect(_live.allAsked, isTrue);
  if (d.unheard >= 0) {
    await t.tap(_label(L.informLabel));
    await _pump(t, 500);
    expect(_live.informed, isTrue);
  }
  await _holdLabel(t, L.leverLabel, kM8LeverMs + 300);
}

M8PlanJob _jobOf(M8PlanKind k, {int len = 3, int nowMin = 9 * 60, M8PlanZone zone = M8PlanZone.town}) => M8PlanJob(kind: k, para: 'বাগানপাড়া', len: len, nowMin: nowMin, zone: zone);

M8PlanRun _runOf({M8PlanJob? first, int unheard = -1, M8PlanPush push = M8PlanPush.notice}) {
  final jobs = [
    first ?? _jobOf(M8PlanKind.maint),
    _jobOf(M8PlanKind.maint, len: 8, nowMin: 10 * 60 + 30),
    _jobOf(M8PlanKind.emergency, len: 2, nowMin: 20 * 60, zone: M8PlanZone.village),
  ];
  return M8PlanRun(M8PlanDeal(
    weekday: 2,
    date0: 14,
    jobs: jobs,
    noticeJob: 0,
    paras: const ['বাগানপাড়া', 'মাঝেরপাড়া', 'স্টেশনপাড়া'],
    unheard: unheard,
    push: push,
    why: const [M8PlanWhy.window, M8PlanWhy.early, M8PlanWhy.night, M8PlanWhy.allKnow],
    wheels: const [0, 3, 5],
  ));
}

/// Gets a run to the notice sheet / the morning (every job placed right).
void _toNotice(M8PlanRun r) {
  for (var i = 0; i < 3; i++) {
    final job = r.job;
    final (d, h) = job.validPlacements.first;
    r.place(d, h);
    expect(r.confirm(), isNull);
    r.next();
  }
}

void main() {
  group('rules', () {
    test('deals: one short maintenance job (2–4 h), one LONG (7–9 h), one emergency; a right placement always exists; the reason fits; plays differ', () {
      final seen = <String>{};
      final whys = <M8PlanWhy>{};
      var allKnow = 0, heard = 0;
      final pushes = <M8PlanPush>{};
      final zones = <M8PlanZone>{};
      final firstKinds = <M8PlanKind>{};
      for (var s = 0; s < 300; s++) {
        final d = m8PlanDeal(math.Random(s));
        expect(d.jobs, hasLength(3));
        final maint = d.jobs.where((j) => j.kind == M8PlanKind.maint).toList();
        expect(maint, hasLength(2));
        expect(d.jobs.where((j) => j.kind == M8PlanKind.emergency), hasLength(1));
        expect(maint.where((j) => j.isLong), hasLength(1));
        expect(maint.where((j) => !j.isLong).single.len, inInclusiveRange(2, 4));
        expect(maint.singleWhere((j) => j.isLong).len, inInclusiveRange(7, 9));
        expect(d.jobs[d.noticeJob].kind, M8PlanKind.maint);
        expect(d.jobs[d.longJob].isLong, isTrue);
        expect({for (final j in d.jobs) j.para}, hasLength(3));
        for (final (i, j) in d.jobs.indexed) {
          final v = j.validPlacements;
          expect(v, isNotEmpty, reason: 'seed $s job $i');
          if (j.kind == M8PlanKind.maint) {
            expect(v.length, greaterThanOrEqualTo(3), reason: 'several valid slots (seed $s job $i)');
            expect(j.nowMin ~/ 60, inInclusiveRange(9, 16));
          } else {
            expect(j.nowMin ~/ 60, inInclusiveRange(18, 20));
            expect(j.len, inInclusiveRange(2, 3));
          }
          expect(j.nowMin % 30, 0);
          final fits = switch (j.kind) {
            M8PlanKind.emergency => {M8PlanWhy.night},
            M8PlanKind.maint => j.isLong ? {M8PlanWhy.early, M8PlanWhy.window} : {M8PlanWhy.window},
          };
          expect(fits, contains(d.why[i]));
          whys.add(d.why[i]);
          if (j.kind == M8PlanKind.emergency) zones.add(j.zone);
        }
        firstKinds.add(d.jobs.first.kind);
        expect(d.paras.toSet(), hasLength(3));
        expect(d.unheard, inInclusiveRange(-1, 2));
        expect(d.why.last, d.unheard < 0 ? M8PlanWhy.allKnow : M8PlanWhy.heard);
        if (d.unheard < 0) {
          allKnow++;
        } else {
          heard++;
        }
        expect(d.wheels[0], inInclusiveRange(0, 4));
        expect(d.wheels[1], inInclusiveRange(0, 23));
        expect(d.wheels[2], inInclusiveRange(1, 24));
        expect(d.days, hasLength(5));
        expect(d.days.map((e) => e.name).toSet(), hasLength(5));
        pushes.add(d.push);
        seen.add('${d.weekday}${d.date0}${[for (final j in d.jobs) '${j.kind.index}${j.len}${j.nowMin}${j.zone.index}'].join()}${d.noticeJob}${d.unheard}${d.push.index}');
      }
      expect(seen.length, greaterThan(280));
      expect(whys, M8PlanWhy.values.toSet().difference({M8PlanWhy.heard, M8PlanWhy.allKnow}));
      expect(pushes, M8PlanPush.values.toSet());
      expect(zones, M8PlanZone.values.toSet());
      expect(firstKinds, M8PlanKind.values.toSet(), reason: 'the order is dealt');
      expect(allKnow, inInclusiveRange(90, 150), reason: 'about 40 % of plays every para heard');
      expect(heard, greaterThan(150));
    });

    test('a maintenance block: wholly inside 06:00–17:00 (both edges allowed); a short job needs no 3 days; a long one starts 72 h after now', () {
      final short = _jobOf(M8PlanKind.maint, len: 3, nowMin: 9 * 60);
      expect(short.judge(0, 14), isNull, reason: '14–17 on the same day');
      expect(short.judge(0, 15), Mk.night, reason: 'ends at 18:00');
      expect(short.judge(1, 6), isNull, reason: '06:00 allowed');
      expect(short.judge(1, 5), Mk.night);
      expect(short.judge(1, 0), Mk.night);
      expect(short.judge(1, 20), Mk.night);
      expect(short.judge(4, 14), isNull);
      expect(short.judge(0, 10), isNull, reason: 'no 3 days for a job of 6 h or less');
      final six = _jobOf(M8PlanKind.maint, len: 6, nowMin: 9 * 60);
      expect(six.isLong, isFalse, reason: '6 h is not over 6 h');
      expect(six.judge(0, 10), isNull);
      final long = _jobOf(M8PlanKind.maint, len: 8, nowMin: 10 * 60 + 30);
      expect(long.isLong, isTrue);
      expect(long.judge(1, 6), Mk.notice, reason: 'a day later');
      expect(long.judge(2, 8), Mk.notice);
      expect(long.judge(3, 6), Mk.notice, reason: '67.5 h');
      expect(long.judge(3, 9), Mk.notice, reason: '09:00 on day 4 is 70.5 h');
      expect(long.judge(4, 6), isNull);
    });

    test('the 72-hour edge: a long job started exactly 72 h after now is right; one hour short is a slip', () {
      final long = _jobOf(M8PlanKind.maint, len: 7, nowMin: 9 * 60);
      expect(long.judge(3, 9), isNull, reason: '72 h exactly (09:00 + 3 days, ends 16:00)');
      expect(long.judge(3, 8), Mk.notice, reason: '71 h');
      expect(long.judge(4, 6), isNull);
      // A late 'এখন' rolls it to the last day.
      final late = _jobOf(M8PlanKind.maint, len: 9, nowMin: 16 * 60);
      expect(late.validPlacements.every((p) => p.$1 == 4), isTrue, reason: '${late.validPlacements}');
      expect(late.validPlacements.map((p) => p.$2).toSet(), {6, 7, 8});
    });

    test('an emergency LT wire break: the block ends within the zone limit (town 4 h, village 10 h) of the registration, night allowed', () {
      final town = _jobOf(M8PlanKind.emergency, len: 2, nowMin: 20 * 60);
      expect(town.judge(0, 20), isNull);
      expect(town.judge(0, 22), isNull, reason: 'ends 24:00 = 4 h');
      expect(town.judge(1, 0), Mk.late);
      expect(town.judge(1, 10), Mk.late);
      expect(town.validPlacements, [(0, 20), (0, 21), (0, 22)]);
      final village = _jobOf(M8PlanKind.emergency, len: 3, nowMin: 20 * 60, zone: M8PlanZone.village);
      expect(village.judge(0, 21), isNull);
      expect(village.judge(1, 3), isNull, reason: 'ends 06:00 = 10 h');
      expect(village.judge(1, 4), Mk.late);
    });

    test('a block never goes before now and never past midnight; a strip with no room refuses it', () {
      final r = _runOf(first: _jobOf(M8PlanKind.maint, len: 3, nowMin: 15 * 60 + 30));
      expect(r.clampPlace(0, 2), (0, 16), reason: 'never before 15:30');
      expect(r.clampPlace(0, 30), (0, 21));
      expect(r.clampPlace(2, -4), (2, 0));
      expect(r.clampPlace(7, 3), isNull);
      final tight = _runOf(first: _jobOf(M8PlanKind.maint, len: 4, nowMin: 21 * 60));
      expect(tight.clampPlace(0, 21), isNull, reason: 'no room left on day 1');
      expect(tight.clampPlace(1, 8), (1, 8));
    });

    test('the board: place, pick it up, confirm; a slip keeps the block and counts; a right block is accepted and tagged with its gap', () {
      final r = _runOf();
      expect(r.confirm(), isNull, reason: 'no block yet');
      expect(r.slips, 0);
      expect(r.place(0, 15), isTrue);
      expect(r.confirm(), Mk.night);
      expect(r.slips, 1);
      expect(r.placed, (0, 15), reason: 'the block stays on the board');
      r.lift();
      expect(r.placed, isNull);
      expect(r.place(1, 8), isTrue);
      expect(r.confirm(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.accepted[0], (1, 8));
      expect(r.caught.single, contains('08:00–11:00'));
      expect(r.caught.single, contains('নোটিশের 23 ঘন্টা পরে'));
      expect(r.place(2, 8), isFalse, reason: 'the job is done');
      expect(r.thorough, isFalse);
      r.next();
      expect(r.thorough, isTrue, reason: 'each step counts its own slips');
      expect(r.job.isLong, isTrue);
    });

    test('the notice sheet: wheels turn both ways and round; a mismatch is a slip and the sheet stays; matching rings the auto', () {
      final r = _runOf();
      _toNotice(r);
      expect(r.stage, M8PlanStage.notice);
      final (d, h) = r.noticeBlock;
      expect(r.wheelsMatch, isFalse, reason: 'the wheels never start on the answer');
      r.turn(0, 1);
      expect(r.wheels[0], (r.deal.wheels[0] + 1) % 5);
      r.wheels = [4, 23, 24];
      r
        ..turn(0, 1)
        ..turn(1, 1)
        ..turn(2, 1);
      expect(r.wheels, [0, 0, 1], reason: 'round');
      r
        ..turn(0, -1)
        ..turn(1, -1)
        ..turn(2, -1);
      expect(r.wheels, [4, 23, 24]);
      expect(r.announce(), Mk.wheels);
      expect(r.roundDone, isFalse);
      r.wheels = [d, h, h + r.noticeJob.len];
      expect(r.wheelsMatch, isTrue);
      expect(r.announce(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.announced, isTrue);
      expect(r.caught, contains(L.caughtNotice));
      expect(r.slips, 1);
    });

    test('the morning: the clock stands 30 min before the start, a question takes 5 min; the lever or "আগে জানাই" before every porch is asked is a slip', () {
      final r = _runOf();
      _toNotice(r);
      final (_, h) = r.noticeBlock;
      r.next();
      r.wheels = [0, 0, 1];
      expect(r.index, 4);
      expect(r.stage, M8PlanStage.morning);
      expect(r.morningMin, h * 60 - 30);
      expect(r.lever(), Mk.unchecked);
      expect(r.inform(), Mk.unchecked);
      expect(r.ask(0), isTrue);
      expect(r.ask(0), isFalse, reason: 'once');
      expect(r.morningMin, h * 60 - 25);
      expect(r.ask(1), isTrue);
      expect(r.lever(), Mk.unchecked, reason: 'one porch still unasked');
      expect(r.ask(2), isTrue);
      expect(r.morningMin, h * 60 - 15);
      expect(r.allAsked, isTrue);
      expect(r.slips, 3);
    });

    test('the morning, all three know: the lever is right; "আগে জানাই" is a needless hold (a slip)', () {
      final r = _runOf();
      _toNotice(r);
      r.next();
      for (var i = 0; i < 3; i++) {
        r.ask(i);
      }
      expect(r.inform(), Mk.needless);
      expect(r.lever(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtLane));
      expect(r.slips, 1);
    });

    test('the morning, one para did not hear: the lever is a slip until the crew has told it; then the lever is right; telling twice is needless', () {
      final r = _runOf(unheard: 1);
      _toNotice(r);
      r.next();
      for (var i = 0; i < 3; i++) {
        r.ask(i);
      }
      expect(r.knows(0), isTrue);
      expect(r.knows(1), isFalse);
      expect(r.lever(), Mk.unheard);
      expect(r.roundDone, isFalse);
      expect(r.inform(), isNull);
      expect(r.knows(1), isTrue);
      expect(r.inform(), Mk.needless);
      expect(r.lever(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.slips, 2);
    });

    test('no deadly act in this level; listening to him is a slip (X2/B1); three slips fail; a clean step pays its bonus', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'M8-1: SoP timing and notice are slips');
      expect(Mk.push(M8PlanPush.notice), Mk.pushNotice);
      expect(Mk.push(M8PlanPush.miking), Mk.pushMiking);
      final r = _runOf();
      for (var i = 0; i < 3; i++) {
        r.place(0, 15);
        r.confirm();
      }
      expect(r.percent, 55);
      r.pushSlip(Mk.pushNotice);
      expect(r.percent, 40);
      expect(r.thorough, isFalse);
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.startMaint,
        L.startEmergency,
        L.startNotice,
        L.startMorning,
        ...L.tasks,
        L.noticeOk,
        L.informedLine,
        L.confirm,
        L.leverLabel,
        L.informLabel,
        L.askBubble,
        ...L.replyKnow,
        L.replyNo,
        L.replyTold,
        L.wheelDay,
        L.wheelStart,
        L.wheelEnd,
        ...L.paras,
        for (var n = 0; n < 5; n++) L.stepName(n),
        for (final z in M8PlanZone.values) L.zone(z),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8PlanPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtNotice,
        L.caughtLane,
        L.caughtCall,
        for (final j in m8PlanDeal(math.Random(3)).jobs) ...L.docket(j),
        L.caughtJob(m8PlanDeal(math.Random(3)).jobs.first, m8PlanDeal(math.Random(3)).days, 1, 9),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|সুইচ অন|এলটি|এইচটি|কেভি|বন্ধ.*AB|AB বন্ধ').hasMatch(l), isFalse, reason: 'ON/OFF, LT, HT, kV in English letters: $l');
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        // য় ড় ঢ় as base + nukta (the app's form): never the single code points.
        expect(RegExp('[' + String.fromCharCodes([0x09DC, 0x09DD, 0x09DF]) + ']').hasMatch(l), isFalse, reason: 'nukta form: $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.3/m8_shutdown_plan/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 5));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_shutdown_plan/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n != '.gitkeep').toSet();
      expect(files, used);
      expect(m8ShutdownPlanPacks.keys, ['do_8_3_b']);
      // The numbers are today's lesson: 6 h, 3 days (72 h), town 4 h / village 10 h, 06:00–17:00.
      expect(kM8LongOver, 6);
      expect(kM8NoticeH, 72);
      expect(m8Limit(M8PlanZone.town), 4);
      expect(m8Limit(M8PlanZone.village), 10);
      expect([kM8WindowFrom, kM8WindowTo], [6, 17]);
      expect(Mk.notice.textBn, contains('3 দিন'));
      expect(Mk.late.textBn, contains('4 ঘন্টা'));
    });

    test('the docket never says night is allowed; the same confirm label for every job; the readout is times only', () {
      final d = m8PlanDeal(math.Random(5));
      for (final j in d.jobs) {
        final dk = L.docket(j).join(' ');
        expect(dk.contains('রাত'), isFalse);
        expect(dk.contains('জরুরী'), isFalse);
        expect(dk.contains('অনুমতি'), isFalse);
      }
      expect(L.readout('বুধ', 10, 3), 'বুধ 10:00–13:00');
      expect(L.hh(24), '24:00');
      expect(L.docket(_jobOf(M8PlanKind.maint)).single, contains('3 ঘন্টা'));
      expect(L.docket(_jobOf(M8PlanKind.emergency, len: 2, nowMin: 20 * 60 + 30)).last, contains('20:30'));
    });

    test('libraries: same length, big enough, never a rule marked wrong; the coworker\'s cards alike', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M8PlanWhy.values) {
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
      expect(L.coworkerNotice.right, contains('না, 6 ঘন্টার বেশি বন্ধ রাখলে 3 দিন আগে নোটিশ দিতেই হবে'), reason: 'the live-lesson refusal');
      expect(L.coworkerMiking.right, contains('না, আগে নিশ্চিত হই সবাই খবর পেয়েছে'), reason: 'the spec\'s refusal');
      expect(L.replyKnow.length, greaterThanOrEqualTo(2));
    });

    test('spoken lines: his exit is recorded; his two new pushes and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'কাল সকালেই বন্ধ করে দাও, নোটিশ-টোটিশ লাগে না!',
        'মাইকিং-এ কী আসে যায়? এখনই লাইন বন্ধ করো!',
      ]);
      expect({for (final p in M8PlanPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.startMaint,
            L.startEmergency,
            L.startNotice,
            L.startMorning,
            ...L.tasks,
            L.noticeOk,
            L.informedLine,
            ...L.whyQ.values,
            for (final p in M8PlanPush.values) L.callHeld(p),
            L.allSet,
            L.quick,
            L.fail,
            ...L.tapWhy,
            for (final cw in L.allCoworkers) ...cw.asks,
            for (final m in Mk.all) m.textBn,
          }));
      // The reasons the spec lists, word for word.
      expect(L.whyQ.values, [
        'শাটডাউন এই সময়ে কেন রাখলেন?',
        'নোটিশ এত আগে কেন দিলেন?',
        'ছিঁড়ে যাওয়া লাইনের শাটডাউন রাতেই কেন?',
        'পাড়ায় মাইকিং হয়নি শুনে কেন থামলেন?',
        'সবাই জানে নিশ্চিত হয়ে কেন বন্ধ করলেন?',
      ]);
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_shutdown_plan: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas: on the scene, below the header, above the button row, clear of the guide and of each other', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M8PlanGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (var len = 2; len <= 9; len++) {
          final grab = g.trayGrab(len);
          expect(grab.left, greaterThanOrEqualTo(0), reason: 'h $h len $len');
          expect(grab.bottom, lessThan(h - 95), reason: 'h $h len $len above the button row');
          expect(grab.overlaps(guide), isFalse, reason: 'h $h len $len under the guide');
          expect(grab.overlaps(g.docket), isFalse, reason: 'the tray clear of the docket');
          expect(grab.top, greaterThan(g.board.bottom));
        }
        expect(g.docket.overlaps(guide), isFalse, reason: 'h $h docket under the guide');
        expect(g.board.top, greaterThan(125), reason: 'h $h below the header');
        expect(g.board.bottom, lessThan(h - 95), reason: 'h $h');
        for (var d = 0; d < kM8Days; d++) {
          expect(g.strip(d).left, kM8StripL);
          expect(g.strip(d).right, kM8StripR);
          expect(g.rowAt(g.strip(d).center.dy), d);
          if (d > 0) expect(g.strip(d).top, greaterThan(g.strip(d - 1).bottom), reason: 'rows apart');
        }
        final notice = <Rect>[for (var i = 0; i < 3; i++) g.wheel(i), g.micHit];
        for (final r in notice) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(g.miniBoard.bottom), reason: 'h $h: $r');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the button row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
        }
        for (final (i, a) in notice.indexed) {
          for (final b in notice.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        final lane = <Rect>[for (var i = 0; i < 3; i++) g.porch(i)];
        for (final r in lane) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(125));
          expect(r.bottom + 18, lessThan(g.lever.top), reason: 'h $h: porches above the controls');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
        }
        for (var i = 0; i < 3; i++) {
          expect(g.bubble(i).bottom, lessThanOrEqualTo(g.porch(i).top - 8 + 20));
        }
        // The two morning controls: equal size, apart, clear of the guide and the confirm.
        expect(g.lever.size, g.inform.size);
        expect(g.lever.overlaps(g.inform), isFalse);
        expect(g.inform.overlaps(guide), isFalse);
        expect(g.lever.right, lessThanOrEqualTo(g.inform.left));
        expect(g.confirmBtn.overlaps(guide), isFalse);
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

    testWidgets('the guide comes first: a tap does not skip him; then the planner and "বোর্ডে লাগান"', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8ShutdownPlanPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.boardLabel), findsOneWidget);
      expect(_label(L.confirm), findsOneWidget);
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
      final task = _live.job.kind == M8PlanKind.emergency ? L.askEmergency : L.askPlan;
      expect(lines.every((l) => l.contains(task)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play per push: the coworker on the long job's confirm, or before the lever
    // (each once with the lane all knowing and once with a para that did not hear).
    final flowSeeds = [
      _seedWhere((d) => d.push == M8PlanPush.notice && d.unheard < 0),
      _seedWhere((d) => d.push == M8PlanPush.miking && d.unheard >= 0),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three jobs, the notice sheet, the lane, reasons; he is refused → pass', (t) async {
        final d = m8PlanDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playJob(t, d, i);
        }
        await _playNotice(t, d);
        await _playMorning(t, d);
        // The lever, held to the end.
        await _pump(t, 200);
        expect(_live.roundDone, isTrue);
        await _reason(t, d, 4);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.3/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.3/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtNotice), findsOneWidget);
        expect(find.text(L.caughtLane), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a block on the planner: a held block shows its times only; a drop off the strips returns it; a slip keeps the block and the step', (t) async {
      final seed = _seedWhere((d) => d.jobs.first.kind == M8PlanKind.maint && !d.jobs.first.isLong);
      final d = m8PlanDeal(math.Random(seed));
      final job = d.jobs.first;
      final c = await _open(t, seed);
      final g = _geo;
      final len = job.len;
      // Dropped below the board: back in the tray.
      await _drag(t, g.trayBlock(len).center, Offset(200, g.docket.bottom + 60));
      expect(_live.placed, isNull);
      // A held block over a strip: the readout carries times only.
      final gesture = await t.startGesture(g.trayBlock(len).center * _k);
      await gesture.moveTo(Offset(g.hourX(18 + len / 2), g.strip(2).center.dy) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(_live.placed, isNull, reason: 'not placed while held');
      await gesture.up();
      await _pump(t, 300);
      expect(_live.placed, (2, 18));
      // A slip: 18:00 is night.
      await t.tap(_label(L.confirm));
      await _pump(t, 500);
      expect(find.text(Mk.night.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.night.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 0, reason: 'the same job goes on');
      expect(_live.placed, (2, 18), reason: 'the block is still on the board');
      // The block picked up again and moved; then right.
      final (day, hour) = job.validPlacements.first;
      await _drag(t, g.blockRect(2, 18, len).center, Offset(g.hourX(hour + len / 2), g.strip(day).center.dy));
      expect(_live.placed, (day, hour));
      await t.tap(_label(L.confirm));
      await _pump(t, 500);
      expect(_live.roundDone, isTrue);
      await _close(t, c);
    });

    testWidgets('three slips on the planner strike the level out', (t) async {
      final seed = _seedWhere((d) => d.jobs.first.kind == M8PlanKind.maint && !d.jobs.first.isLong);
      final d = m8PlanDeal(math.Random(seed));
      final job = d.jobs.first;
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _place(t, 3, math.min(18, 24 - job.len));
        await t.tap(_label(L.confirm));
        await _pump(t, 500);
        if (i < 2) {
          expect(find.text(Mk.night.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.index, 0);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.night.key});
      await _close(t, c);
    });

    testWidgets('an emergency block beyond the limit is a slip (night is not); inside it passes', (t) async {
      final seed = _seedWhere((d) => d.jobs.first.kind == M8PlanKind.emergency && d.jobs.first.zone == M8PlanZone.town);
      final d = m8PlanDeal(math.Random(seed));
      final job = d.jobs.first;
      final c = await _open(t, seed);
      await _place(t, 3, 10);
      await t.tap(_label(L.confirm));
      await _pump(t, 500);
      expect(find.text(Mk.late.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      final (day, hour) = job.validPlacements.last;
      expect(hour, greaterThanOrEqualTo(18), reason: 'a night slot is right here');
      await _place(t, day, hour);
      await t.tap(_label(L.confirm));
      await _pump(t, 500);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.late.key);
      await _close(t, c);
    });

    testWidgets('the long job\'s confirm waits for the coworker; listening is a slip and the job goes on', (t) async {
      final seed = _seedWhere((d) => d.push == M8PlanPush.notice && d.jobs.first.isLong);
      final d = m8PlanDeal(math.Random(seed));
      final job = d.jobs.first;
      final c = await _open(t, seed);
      final (day, hour) = job.validPlacements.first;
      await _place(t, day, hour);
      // At once, well inside his 1.2–2.4 s timer: the confirm.
      await t.tap(_label(L.confirm));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.roundDone, isFalse, reason: 'the confirm did not go through');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworker(d.push).wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.pushNotice.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      expect(_live.placed, (day, hour));
      await t.tap(_label(L.confirm));
      await _pump(t, 500);
      expect(_live.roundDone, isTrue, reason: 'after him the confirm works');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.pushNotice.key});
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the next job follows', (t) async {
      final seed = flowSeeds.first;
      final d = m8PlanDeal(math.Random(seed));
      final c = await _open(t, seed);
      final job = d.jobs.first;
      final (day, hour) = job.validPlacements.first;
      await _place(t, day, hour);
      if (d.push == M8PlanPush.notice && d.longJob == 0) await _refuse(t, d.push);
      await t.tap(_label(L.confirm));
      await _pump(t, 100);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(60, 128));
        await t.pump(const Duration(milliseconds: 150));
        await _drag(t, _geo.blockRect(day, hour, job.len).center, Offset(200, _geo.strip(4).center.dy));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.placed, (day, hour), reason: 'the block stood still');
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[d.why[0]]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    // To the notice sheet quickly: a play whose first two jobs and the notice job need no coworker beat.
    final noticeSeed = _seedWhere((d) => d.push == M8PlanPush.miking);
    Future<ProviderContainer> toNotice(WidgetTester t) async {
      final d = m8PlanDeal(math.Random(noticeSeed));
      final c = await _open(t, noticeSeed);
      for (var i = 0; i < 3; i++) {
        await _playJob(t, d, i);
      }
      return c;
    }

    testWidgets('the notice sheet: a mic released early does nothing; wheels that do not match are a slip; matching rings the auto', (t) async {
      final c = await toNotice(t);
      expect(_live.index, 3);
      // Released early: nothing.
      await _hold(t, _geo.mic, 400);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      // Held to the end with the dealt wheels: a slip.
      await _hold(t, _geo.mic, kM8MicMs + 300);
      expect(find.text(Mk.wheels.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 3, reason: 'the sheet stays');
      // One wheel right is not enough.
      final (day, hour) = _live.noticeBlock;
      await _wheelTo(t, 0, day);
      expect(_live.wheelsMatch, isFalse);
      await _wheelTo(t, 1, hour);
      await _wheelTo(t, 2, hour + _live.noticeJob.len);
      await _hold(t, _geo.mic, kM8MicMs + 300);
      expect(_live.announced, isTrue);
      await _pump(t, 3000);
      expect(_live.index, 4);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.wheels.key);
      await _close(t, c);
    });

    testWidgets('the lane: the lever or "আগে জানাই" before every porch is asked is a slip; an early release of the lever does nothing; the questions cost 5 game min', (t) async {
      final d = m8PlanDeal(math.Random(noticeSeed));
      final c = await toNotice(t);
      await _playNotice(t, d);
      expect(_live.index, 4);
      await _refuse(t, d.push);
      final min0 = _live.morningMin;
      // An early release: nothing.
      await _holdLabel(t, L.leverLabel, 300);
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      // 'আগে জানাই' before anyone is asked: a slip.
      await t.tap(_label(L.informLabel));
      await _pump(t, 500);
      expect(find.text(Mk.unchecked.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // The lever before anyone is asked: a slip.
      await _holdLabel(t, L.leverLabel, kM8LeverMs + 300);
      expect(find.text(Mk.unchecked.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.morningMin, min0);
      await _tapAt(t, _geo.porch(0).center);
      expect(_live.morningMin, min0 + 5);
      expect(_live.asked, [true, false, false]);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.unchecked.key});
      await _close(t, c);
    });

    testWidgets('the lane, a para that did not hear: the lever is a slip; then "আগে জানাই", then the lever', (t) async {
      final seed = _seedWhere((d) => d.push == M8PlanPush.miking && d.unheard >= 0);
      final d = m8PlanDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playJob(t, d, i);
      }
      await _playNotice(t, d);
      await _refuse(t, d.push);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.porch(i).center);
      }
      await _pump(t, 1200);
      await _holdLabel(t, L.leverLabel, kM8LeverMs + 300);
      expect(find.text(Mk.unheard.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_label(L.informLabel));
      await _pump(t, 500);
      expect(_live.informed, isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      await _holdLabel(t, L.leverLabel, kM8LeverMs + 300);
      expect(_live.roundDone, isTrue);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.unheard.key});
      await _close(t, c);
    });

    testWidgets('the lane, every para heard: "আগে জানাই" is a needless hold; the lever then works', (t) async {
      final seed = _seedWhere((d) => d.push == M8PlanPush.miking && d.unheard < 0);
      final d = m8PlanDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playJob(t, d, i);
      }
      await _playNotice(t, d);
      await _refuse(t, d.push);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.porch(i).center);
      }
      await _pump(t, 1200);
      await t.tap(_label(L.informLabel));
      await _pump(t, 500);
      expect(find.text(Mk.needless.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _holdLabel(t, L.leverLabel, kM8LeverMs + 300);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.needless.key});
      await _close(t, c);
    });

    testWidgets('the lever waits for the coworker on a morning play; listening is a slip', (t) async {
      final seed = _seedWhere((d) => d.push == M8PlanPush.miking);
      final d = m8PlanDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playJob(t, d, i);
      }
      await _playNotice(t, d, settle: 0);
      for (var ms = 0; ms < 6000 && _live.index != 4; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(_live.index, 4);
      // At once, inside his timer: the lever (held).
      await _holdLabel(t, L.leverLabel, kM8LeverMs + 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.slips, 0, reason: 'the lever did not pull');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworker(d.push).wrong);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.pushMiking.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.pushMiking.key});
      await _close(t, c);
    });

    testWidgets('gesture hand: idle on the planner shows a nudge that presses nothing; any touch hides it; none while the block is in hand', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.jobs.first.kind == M8PlanKind.maint && !d.jobs.first.isLong);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the planner');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a drag nudge presses nothing');
      await _tapAt(t, const Offset(200, 200));
      expect(scene().showing, isFalse);
      // The block on the board: a sweep over it and the confirm button.
      final job = _live.job;
      final (day, hour) = job.validPlacements.first;
      await _place(t, day, hour);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'block placed, waiting');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
