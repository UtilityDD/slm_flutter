// Lesson 6.7 (ক্যাপাসিটর ব্যাংক), কাজ 1 "ঘড়ি ধরে অপেক্ষা": the rules (the
// earthed rod's hook before its clamp is on earth = deadly; a hand on a
// terminal or can before every terminal had the rod = deadly; handing over
// with a terminal never rod-touched = deadly; the first terminal before 5
// game minutes = a slip that still discharges; one spark per terminal, none
// from the earthed line conductor; ≥ 10 minutes on a bank = the bonus), the
// deal, the reason fitted to the job, the libraries, the spoken lines (the
// coworker's pushes are the lesson's myths word for word), the tap areas,
// and the level in the shell: the guide first, a tap does not skip him, the
// guide's tap repeats the task, a full clean play (a reason pick each job,
// the coworker refused), the early-rod slip card, three slips, the deadly
// freezes (hand, hook before clamp, hand-over, listening), the hook waits
// for the coworker on a fast play, and the gesture hand shows only while the
// level waits.
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
import 'package:slm_flutter/features/game/m6_capbank_wait.dart';
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
  rungId: '6.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6CapbankWaitPacks['do_6_7_a']!;
typedef L = M6CapLines;
typedef Mk = M6CapMistakes;

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

/// The app writes য় ড় ঢ় as base + nukta; the lesson file may use the single
/// code points.
String _nfc(String s) => s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');

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

Future<void> _pickRight(WidgetTester t, List<String> right, {bool reason = true}) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  if (reason) {
    await tapReasonProceed(t);
  } else {
    await confirmChoice(t);
  }
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M6CapGeo get _geo => M6CapGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _drag(WidgetTester t, Offset from, Offset to) async {
  await t.dragFrom(from * _k, (to - from) * _k);
  await _pump(t, 400);
}

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6CapbankWaitPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6CapDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6CapDeal(math.Random(s))));

/// The bank's switch has flipped OFF for this job.
Future<void> _waitOff(WidgetTester t) async {
  expect(await _pumpUntil(t, _label(L.switchState(true)), maxMs: 6000), isTrue, reason: 'the switch flips OFF');
  await _pump(t, 200);
}

/// He is here: refuse him.
Future<bool> _refuseIfHere(WidgetTester t, M6CapDeal d) async {
  if (find.byType(CoworkerPeek).evaluate().isEmpty) return false;
  if (!await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 6000)) return false;
  await _pump(t, 600);
  await _pickRight(t, L.coworker(d.jobs[d.coworkerJob].kind).right, reason: false);
  await _pump(t, 2600);
  return true;
}

/// Lets the game clock reach [minutes] (refusing him if he comes meanwhile).
Future<void> _waitGame(WidgetTester t, M6CapDeal d, double minutes) async {
  for (var ms = 0; ms < 60000 && M6CapProbe.minutes < minutes; ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
    if (find.byType(ChoiceDeck).evaluate().isNotEmpty && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      await _refuseIfHere(t, d);
    }
  }
  expect(M6CapProbe.minutes, greaterThanOrEqualTo(minutes));
}

/// Carry the rod (a tap) and drag its earth clamp onto the earth.
Future<void> _ready(WidgetTester t, M6CapJob j) async {
  await _tapAt(t, _geo.rodHit.center);
  await _drag(t, _geo.clampSpot, _geo.earth(j.kind));
  expect(M6CapProbe.run!.ready, isTrue, reason: 'rod in hand, clamp on earth');
}

/// The rod's hook on terminal [i] (refusing him if the tap brought him in).
Future<void> _hook(WidgetTester t, M6CapDeal d, M6CapJob j, int i) async {
  final before = M6CapProbe.run!.discharged.length;
  await _tapAt(t, _geo.terminal(j.kind, j.cans, i));
  if (M6CapProbe.run!.discharged.length == before && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    await _refuseIfHere(t, d);
    await _tapAt(t, _geo.terminal(j.kind, j.cans, i));
  }
}

List<String> _whyRight(M6CapJob j, {bool early = false}) => switch (j.kind) {
      M6CapKind.bankEarthed => L.whyLineRight,
      M6CapKind.small => L.whySmallRight,
      M6CapKind.bankAlone => early ? L.whyFirstRight : [...L.whyWaitRight, ...L.whyRodRight],
    };

/// One job played right: wait the 5 minutes, every terminal, hand over, reason.
Future<void> _playJob(WidgetTester t, M6CapDeal d, int i, {double wait = 5.3}) async {
  final j = d.jobs[i];
  await _waitOff(t);
  await _ready(t, j);
  await _waitGame(t, d, wait);
  for (var k = 0; k < j.terminals; k++) {
    await _hook(t, d, j, k);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  expect(M6CapProbe.run!.allDischarged, isTrue);
  await t.tap(find.byKey(const ValueKey('handover-btn')));
  await _pump(t, 400);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  await _pickRight(t, _whyRight(j));
  await _pump(t, 2500);
}

M6CapJob _job(M6CapKind k, {int cans = 3}) =>
    M6CapJob(kind: k, flavor: k == M6CapKind.small ? M6CapFlavor.small : M6CapFlavor.fuse, cans: cans, bus: M6CapBus.star, badCan: 0, startMinute: 20, hour: 10);

M6CapRun _runOf(M6CapJob first, {int at = 1}) => M6CapRun(M6CapDeal(
      jobs: [first, _job(M6CapKind.bankEarthed, cans: 6), _job(M6CapKind.small)],
      coworkerJob: at,
      coworkerMinute: 2,
    ))
      ..switchOff();

void main() {
  group('rules', () {
    test('deals: an earthed bank, a bank on its own switch, and a small capacitor or another bank; 3 or 6 cans; plays differ', () {
      final seen = <String>{};
      final cans = <int>{};
      final buses = <M6CapBus>{};
      final at = <int>{};
      final minutes = <int>{};
      var small = 0;
      for (var s = 0; s < 200; s++) {
        final d = m6CapDeal(math.Random(s));
        expect(d.jobs, hasLength(3));
        final kinds = [for (final j in d.jobs) j.kind];
        expect(kinds, contains(M6CapKind.bankEarthed));
        expect(kinds, contains(M6CapKind.bankAlone));
        expect(kinds.where((k) => k == M6CapKind.small).length, lessThanOrEqualTo(1));
        if (kinds.contains(M6CapKind.small)) small++;
        final bankFlavors = [for (final j in d.jobs) if (j.bank) j.flavor];
        expect(bankFlavors.toSet(), hasLength(bankFlavors.length), reason: 'each bank job its own reason');
        for (final j in d.jobs) {
          expect(j.flavor == M6CapFlavor.small, j.kind == M6CapKind.small);
          expect(j.terminals, j.kind == M6CapKind.small ? 3 : j.cans);
          if (j.bank) {
            expect([3, 6], contains(j.cans));
            cans.add(j.cans);
            buses.add(j.bus);
          }
          expect(j.badCan, inInclusiveRange(0, j.cans - 1));
          expect(j.startMinute, inInclusiveRange(0, 59));
        }
        // His myth must fit the scene: an earthed line or the small capacitor.
        expect(d.jobs[d.coworkerJob].kind, isNot(M6CapKind.bankAlone));
        expect(d.coworkerMinute, inInclusiveRange(1, 3), reason: 'inside the wait, well before 5');
        at.add(d.coworkerJob);
        minutes.add(d.coworkerMinute);
        seen.add('${d.jobs.map((j) => '${j.kind.index}${j.flavor.index}${j.cans}${j.bus.index}${j.startMinute}').join('|')}|${d.coworkerJob}${d.coworkerMinute}');
      }
      expect(seen.length, greaterThan(190));
      expect(cans, {3, 6});
      expect(buses, M6CapBus.values.toSet());
      expect(at, {0, 1, 2});
      expect(minutes, {1, 2, 3});
      expect(small, inInclusiveRange(70, 130));
    });

    test('the rod: hook before the clamp is on earth = deadly (R9); nothing happens without the rod in hand', () {
      final r = _runOf(_job(M6CapKind.bankAlone));
      expect(r.hook(0, 6), isNull, reason: 'no rod in hand');
      expect(r.carry(), isTrue);
      expect(r.carry(), isFalse);
      final h = r.hook(0, 6);
      expect(h!.mistake, Mk.hookBeforeClamp);
      expect(h.mistake!.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.slips, 0);
      expect(r.discharged, isEmpty);
      // The earthed line conductor is not a bank terminal: a no-op, clamp on or not.
      final l = _runOf(_job(M6CapKind.bankEarthed))..carry();
      expect(l.hook(m6CapLine, 6), (spark: false, mistake: null));
      expect(l.ended, isFalse);
      expect(l.hook(0, 6)!.mistake, Mk.hookBeforeClamp, reason: 'a bank terminal before the clamp stays deadly');
    });

    test('discharge: one spark per terminal; the earthed line conductor never sparks and discharges nothing', () {
      final r = _runOf(_job(M6CapKind.bankEarthed, cans: 6))
        ..carry()
        ..clamp();
      expect(r.ready, isTrue);
      expect(r.hook(m6CapLine, 6), (spark: false, mistake: null));
      expect(r.discharged, isEmpty);
      expect(r.firstHookMin, isNull, reason: 'the line is not the bank');
      expect(r.hook(2, 6)!.spark, isTrue);
      expect(r.hook(2, 6.5)!.spark, isFalse, reason: 'already discharged: no second spark');
      for (var i = 0; i < 6; i++) {
        r.hook(i, 7);
      }
      expect(r.allDischarged, isTrue);
      expect(r.slips, 0);
    });

    test('the wait: the first terminal before 5 minutes = one slip, still discharges (R10); 5 and after = clean; ≥ 10 on a bank = the bonus', () {
      final r = _runOf(_job(M6CapKind.bankAlone))
        ..carry()
        ..clamp();
      final h = r.hook(0, 4.9);
      expect(h!.mistake, Mk.earlyRod);
      expect(h.mistake!.deadly, isFalse);
      expect(h.spark, isTrue, reason: 'the rod still discharges');
      expect(r.discharged, {0});
      expect(r.hook(1, 4.95)!.mistake, isNull, reason: 'one slip a job');
      expect(r.slips, 1);
      expect(r.early, isTrue);
      final ok = _runOf(_job(M6CapKind.bankAlone))
        ..carry()
        ..clamp();
      expect(ok.hook(0, 5.0)!.mistake, isNull);
      expect(ok.longWait, isFalse);
      final long = _runOf(_job(M6CapKind.bankEarthed))
        ..carry()
        ..clamp();
      long.hook(0, 10);
      expect(long.longWait, isTrue);
      final smallLong = _runOf(_job(M6CapKind.small))
        ..carry()
        ..clamp();
      smallLong.hook(0, 12);
      expect(smallLong.longWait, isFalse, reason: 'the bonus line is about a big 11 kV bank');
      // The optional wait past 5 minutes is taken off the quick-bonus clock.
      for (var i = 0; i < 3; i++) {
        long.hook(i, 10.5);
      }
      expect(long.handOver(), isNull);
      expect(long.longWaitMs, 5 * m6CapMsPerMinute);
    });

    test('a hand on a terminal or can before every terminal had the rod = deadly (R8); after that harmless', () {
      final r = _runOf(_job(M6CapKind.bankAlone));
      expect(r.touch(), Mk.handBeforeRod);
      expect(r.ended, isTrue);
      final s = _runOf(_job(M6CapKind.small))
        ..carry()
        ..clamp();
      s
        ..hook(0, 6)
        ..hook(1, 6);
      expect(s.touch(), Mk.handBeforeRod, reason: 'one terminal still charged');
      final done = _runOf(_job(M6CapKind.small))
        ..carry()
        ..clamp();
      for (var i = 0; i < 3; i++) {
        done.hook(i, 6);
      }
      expect(done.touch(), isNull);
      expect(done.ended, isFalse);
    });

    test('hand-over: a terminal never rod-touched = deadly; all touched → done with its tags; next job starts fresh', () {
      final r = _runOf(_job(M6CapKind.bankAlone))
        ..carry()
        ..clamp();
      r
        ..hook(0, 6)
        ..hook(1, 6);
      expect(r.firstCharged, 2);
      expect(r.handOver(), Mk.handoverCharged);
      expect(r.handOver(), isNull, reason: 'ended');
      final ok = _runOf(_job(M6CapKind.bankAlone))
        ..carry()
        ..clamp();
      for (var i = 0; i < 3; i++) {
        ok.hook(i, 6);
      }
      expect(ok.handOver(), isNull);
      expect(ok.roundDone, isTrue);
      expect(ok.caught, containsAll([L.caughtWait, L.caughtAll]));
      ok.next();
      expect(ok.index, 1);
      expect(ok.switchedOff, isFalse);
      expect(ok.rodHeld, isFalse);
      expect(ok.clampOn, isFalse);
      expect(ok.discharged, isEmpty);
      expect(ok.firstHookMin, isNull);
      expect(ok.carry(), isFalse, reason: 'nothing until the switch is OFF');
      ok.switchOff();
      expect(ok.carry(), isTrue);
    });

    test('a clean play passes; three early rods take the mark to 55; listening takes the class of his push (B1)', () {
      final d = m6CapDeal(math.Random(5));
      final r = M6CapRun(d);
      for (var i = 0; i < 3; i++) {
        r
          ..switchOff()
          ..carry()
          ..clamp();
        for (var k = 0; k < r.job.terminals; k++) {
          expect(r.hook(k, 5.5)!.mistake, isNull);
        }
        expect(r.handOver(), isNull);
        r.next();
      }
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, containsAll([L.caughtWait, L.caughtAll, L.caughtLine]));
      final e = M6CapRun(d);
      for (var i = 0; i < 3; i++) {
        e
          ..switchOff()
          ..carry()
          ..clamp()
          ..hook(0, 1);
        for (var k = 0; k < e.job.terminals; k++) {
          e.hook(k, 2);
        }
        e
          ..handOver()
          ..next();
      }
      expect(e.slips, 3);
      expect(e.percent, 55);
      expect(e.caught, isNot(contains(L.caughtWait)));
      expect(m6CapEndLine(e, quick: false), L.passSlipped, reason: 'a slipped pass never praises the wait');
      expect(m6CapEndLine(r, quick: false), L.allSet);
      expect(m6CapEndLine(r, quick: true), L.quick);
      // One early rod on job 2 of 3: no 'waited on the watch' tag, no allSet.
      final one = M6CapRun(d);
      for (var i = 0; i < 3; i++) {
        one
          ..switchOff()
          ..carry()
          ..clamp();
        for (var k = 0; k < one.job.terminals; k++) {
          one.hook(k, i == 1 ? 2 : 5.5);
        }
        one
          ..handOver()
          ..next();
        if (i == 0) expect(one.caught, contains(L.caughtWait));
      }
      expect(one.passed, isTrue);
      expect(one.slips, 1);
      expect(one.caught, isNot(contains(L.caughtWait)));
      expect(m6CapEndLine(one, quick: false), L.passSlipped);
      expect(m6CapEndLine(M6CapRun(d)..failDeadly(Mk.pushLine), quick: false), L.fail);
      expect(Mk.push(M6CapKind.bankEarthed), Mk.pushLine);
      expect(Mk.push(M6CapKind.small), Mk.pushSmall);
      expect(Mk.pushLine.deadly && Mk.pushSmall.deadly, isTrue);
      final f = _runOf(_job(M6CapKind.small))..failDeadly(Mk.pushSmall);
      expect(f.ended, isTrue);
    });

    test('the reason fits the job and what he did', () {
      expect(m6CapWhy(_job(M6CapKind.bankEarthed), early: false, waitQ: true).q, L.whyQLine);
      expect(m6CapWhy(_job(M6CapKind.bankEarthed), early: true, waitQ: true).q, L.whyQLine);
      expect(m6CapWhy(_job(M6CapKind.small), early: false, waitQ: false).q, L.whyQSmall);
      expect(m6CapWhy(_job(M6CapKind.bankAlone), early: false, waitQ: true).q, L.whyQWait);
      expect(m6CapWhy(_job(M6CapKind.bankAlone), early: false, waitQ: false).q, L.whyQRod);
      expect(m6CapWhy(_job(M6CapKind.bankAlone), early: true, waitQ: true).q, L.whyQFirst, reason: 'an early rod: no "you waited" question');
    });

    test('English digits; জল not পানি; গ্লাভস; owner terms (OFF, ডেড, 11 kV); nukta form; mistakes, keys, pictures, lesson points', () {
      final all = <String>[
        for (final f in M6CapFlavor.values) ...[L.intro(f), L.jobLine(f)],
        ...L.tasks,
        ...L.tapWhy,
        L.earthedLine,
        L.sceneLabel,
        L.watch,
        L.plate,
        L.rod,
        L.clamp,
        L.handover,
        L.plateBn,
        for (final k in M6CapKind.values) ...[L.earth(k), L.jobChip(k), L.can(k, 0)],
        for (final i in [m6CapLine, 0, 5]) L.terminal(i),
        L.switchState(true),
        L.switchState(false),
        ...L.allWhyQs,
        ...L.whyWaitRight, ...L.whyWaitWrong, ...L.whyRodRight, ...L.whyRodWrong, ...L.whyFirstRight, ...L.whyFirstWrong,
        ...L.whyLineRight, ...L.whyLineWrong, ...L.whySmallRight, ...L.whySmallWrong,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final k in M6CapKind.values) L.callHeld(k),
        for (final m in Mk.all) m.textBn,
        L.bonus,
        L.allSet,
        L.passSlipped,
        L.fail,
        L.caughtWait, L.caughtAll, L.caughtLine, L.caughtSmall, L.caughtLong, L.caughtCall,
        ...L.newGuideLines,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('গ্লোভস'), isFalse, reason: l);
        expect(RegExp(r'(^|[\s(])(অফ|অন)([\s।,—-]|$)').hasMatch(l), isFalse, reason: 'ON/OFF in English: $l');
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        for (final w in ['কেভি', 'এলটি', 'এইচটি']) {
          expect(l.contains(w), isFalse, reason: 'English letters: $l');
        }
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.handBeforeRod, Mk.hookBeforeClamp, Mk.handoverCharged, Mk.pushLine, Mk.pushSmall});
      expect(Mk.all.where((m) => !m.deadly).toSet(), {Mk.earlyRod});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.7/m6_capbank_wait/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
      final used = {for (final m in Mk.all) m.art.split('/').last};
      final files = Directory('assets/game/art/m6_capbank_wait').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used; no .gitkeep left');
      expect(m6CapbankWaitPacks.keys, ['do_6_7_a']);
      expect(m6CapMinWait, 5, reason: 'M6-6: 5 game minutes');
    });

    test('the lesson, word for word: his two pushes are the myths, the listening cards their realities; the plate is the lesson picture', () {
      final lessons = (jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
      final lesson = lessons.firstWhere((l) => l['id'] == '6.7');
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(L.mythLine, _nfc(myths[0]['myth'] as String));
      expect(L.mythSmall, _nfc(myths[1]['myth'] as String));
      expect(Mk.pushLine.textBn, _nfc(myths[0]['reality'] as String));
      expect(Mk.pushSmall.textBn, _nfc(myths[1]['reality'] as String));
      final text = _nfc(jsonEncode(lesson));
      expect(text.contains('মারাত্মক বা প্রাণঘাতী শক'), isTrue);
      expect(text.contains('কমপক্ষে ৫-১০ মিনিট অপেক্ষা করা বাধ্যতামূলক'), isTrue);
      expect(text.contains('Wait 5-10 minutes before touching'), isTrue);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      final sets = {
        'wait': (L.whyWaitRight, L.whyWaitWrong),
        'rod': (L.whyRodRight, L.whyRodWrong),
        'first': (L.whyFirstRight, L.whyFirstWrong),
        'line': (L.whyLineRight, L.whyLineWrong),
        'small': (L.whySmallRight, L.whySmallWrong),
      };
      for (final e in sets.entries) {
        final (right, wrong) = e.value;
        expectSameLength('why ${e.key}', [...right, ...wrong]);
        expectLibrary('why ${e.key}', right, wrong);
        expect(right.toSet().intersection(wrong.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expect(L.coworkerBank.right, contains('না, আগে অপেক্ষা — তারপর রডে সরাসরি ডিসচার্জ'), reason: 'the spec refusal');
    });

    test('spoken lines: his exit is recorded; his two pushes listed; every guide line, why-question and ask listed', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.mythLine, L.mythSmall]);
      expect(L.newRivalLines.toSet(), {for (final cw in L.allCoworkers) cw.line});
      expect(
        L.newGuideLines,
        containsAll([
          for (final f in M6CapFlavor.values) ...[L.intro(f), L.jobLine(f)],
          L.earthedLine,
          L.switchOff,
          L.askWait,
          L.askReady,
          ...L.allWhyQs,
          L.askLine,
          L.askSmall,
          L.callHeld(M6CapKind.bankEarthed),
          L.callHeld(M6CapKind.small),
          L.bonus,
          L.allSet,
          L.passSlipped,
          L.fail,
          for (final m in Mk.all) m.textBn,
        ]),
      );
      for (final cw in L.allCoworkers) {
        for (final a in cw.asks) {
          if (a == 'কী করবেন?' || a == 'ওর কথা শুনবেন, না নিয়ম?') continue;
          expect(L.newGuideLines, contains(a));
        }
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_capbank_wait: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, below the header, clear of the guide and his bubble', () {
      for (final h in [600.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6CapGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 116, 360, h);
        // The guide's bubble as drawn (232 wide, up to three lines).
        final bubble = Rect.fromLTRB(130, h - 212, 360, h - 116);
        for (final (kind, cans) in [(M6CapKind.bankEarthed, 3), (M6CapKind.bankEarthed, 6), (M6CapKind.bankAlone, 6), (M6CapKind.small, 3)]) {
          final rects = <String, Rect>{
            'watch': g.watchHit,
            'plate': g.plateHit(kind),
            'rod': g.rodHit,
            'clamp': g.clampHit,
            'earth': g.earthHit(kind),
            'handover': g.handover,
            for (var i = 0; i < g.terminalCount(kind, cans); i++) 't$i': g.terminalHit(kind, cans, i),
            if (kind == M6CapKind.bankEarthed) 'line': g.lineHit,
            for (final (i, r) in g.canHits(kind, cans).indexed) 'can$i': r,
          };
          for (final e in rects.entries) {
            final r = e.value;
            final tag = '${e.key} $kind/$cans h $h';
            expect(r.left, greaterThanOrEqualTo(0), reason: tag);
            expect(r.right, lessThanOrEqualTo(360), reason: tag);
            expect(r.top, greaterThan(125), reason: 'below the header: $tag');
            expect(r.bottom, lessThanOrEqualTo(h), reason: tag);
            expect(r.overlaps(guide), isFalse, reason: 'under the guide: $tag');
            if (e.key != 'handover') expect(r.overlaps(bubble), isFalse, reason: 'under his bubble: $tag');
          }
          final l = rects.entries.toList();
          for (var i = 0; i < l.length; i++) {
            for (var j = i + 1; j < l.length; j++) {
              expect(l[i].value.overlaps(l[j].value), isFalse, reason: 'h $h $kind/$cans: ${l[i].key}/${l[j].key}');
            }
          }
          expect(g.handover.height, greaterThanOrEqualTo(44), reason: 'a real touch target');
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

    testWidgets('the guide comes first: a tap does not skip him; then the switch flips OFF and the scene is live', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6CapbankWaitPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      final d = m6CapDeal(math.Random(3));
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _waitOff(t);
      expect(_label(L.watch), findsOneWidget);
      expect(_label(L.plate), findsOneWidget);
      expect(_label(L.rod), findsOneWidget);
      expect(_label(L.clamp), findsOneWidget);
      for (var i = 0; i < d.jobs.first.terminals; i++) {
        expect(_label(L.terminal(i)), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('handover-btn')), findsNothing, reason: 'the hand-over comes with the rod ready');
      expect(find.textContaining('মিনিট'), findsNothing, reason: 'no countdown, no time on screen');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    final aloneFirst = _seedWhere((d) => d.coworkerJob != 0);

    testWidgets('tapping the guide repeats the task, a different way each time (never when)', (t) async {
      final c = await _open(t, aloneFirst);
      await _waitOff(t);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askWait)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('the plate: a tap shows it up close, English and Bangla; no cost', (t) async {
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      await _waitOff(t);
      await _tapAt(t, _geo.plateHit(d.jobs.first.kind).center);
      expect(find.text(L.plateEn), findsOneWidget);
      expect(find.text(L.plateBn), findsOneWidget);
      await _pump(t, 4200);
      expect(find.text(L.plateEn), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final flowSeeds = [
      _seedWhere((d) => d.coworkerJob == 0 && d.jobs[0].kind == M6CapKind.bankEarthed),
      _seedWhere((d) => d.jobs.any((j) => j.kind == M6CapKind.small) && d.jobs[d.coworkerJob].kind == M6CapKind.small),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three jobs waited out, every terminal, hand-over, reasons; he is refused → pass', (t) async {
        final d = m6CapDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playJob(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.7/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.7/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtWait), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('waiting 10 minutes on a bank: the bonus ◆ and its tag', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob != 0 && d.jobs[0].bank);
      final d = m6CapDeal(math.Random(seed));
      final c = await _open(t, seed);
      final j = d.jobs[0];
      await _waitOff(t);
      await _ready(t, j);
      await _waitGame(t, d, 10.2);
      for (var k = 0; k < j.terminals; k++) {
        await _hook(t, d, j, k);
      }
      expect(M6CapProbe.run!.longWait, isTrue);
      await t.tap(find.byKey(const ValueKey('handover-btn')));
      await _pump(t, 400);
      expect(M6CapProbe.run!.caught, contains(L.caughtLong));
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _close(t, c);
    });

    testWidgets('the rod before 5 minutes is a slip: its card, the terminal still discharged, then the same job goes on', (t) async {
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      await _waitOff(t);
      await _ready(t, j);
      await _tapAt(t, _geo.terminal(j.kind, j.cans, 0));
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.earlyRod.textBn), findsOneWidget);
      expect(M6CapProbe.run!.discharged, {0});
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.earlyRod.key);
      for (var k = 1; k < j.terminals; k++) {
        await _hook(t, d, j, k);
      }
      expect(find.byType(MistakeCard), findsNothing, reason: 'one slip a job');
      await t.tap(find.byKey(const ValueKey('handover-btn')));
      await _pump(t, 400);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, _whyRight(j, early: true));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three early rods strike the level out', (t) async {
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      for (var i = 0; i < 3; i++) {
        final j = d.jobs[i];
        await _waitOff(t);
        await _ready(t, j);
        await _hook(t, d, j, 0);
        if (i == 2) break;
        expect(find.byType(MistakeCard), findsOneWidget, reason: 'job $i');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 600);
        for (var k = 1; k < j.terminals; k++) {
          await _hook(t, d, j, k);
        }
        await t.tap(find.byKey(const ValueKey('handover-btn')));
        await _pump(t, 400);
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
        await _pump(t, 700);
        await _pickRight(t, _whyRight(j, early: true));
        await _pump(t, 2500);
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a hand on a terminal before the rod: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      await _waitOff(t);
      await _tapAt(t, _geo.terminal(j.kind, j.cans, 0));
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.handBeforeRod.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the hook on a terminal before the clamp is on earth: deadly freeze', (t) async {
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      await _waitOff(t);
      await _tapAt(t, _geo.rodHit.center);
      await _waitGame(t, d, 5.5);
      await _tapAt(t, _geo.terminal(j.kind, j.cans, 0));
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.hookBeforeClamp.key);
      await _close(t, c);
    });

    testWidgets('"নিরাপদ" with a terminal never rod-touched: deadly freeze', (t) async {
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      await _waitOff(t);
      await _ready(t, j);
      await _waitGame(t, d, 5.4);
      await _hook(t, d, j, 0);
      await t.tap(find.byKey(const ValueKey('handover-btn')));
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.handoverCharged.key);
      await _close(t, c);
    });

    final himFirst = _seedWhere((d) => d.coworkerJob == 0);
    testWidgets('listening to him = deadly (his hand on the can): freeze, then the reality card', (t) async {
      final d = m6CapDeal(math.Random(himFirst));
      final c = await _open(t, himFirst);
      await _waitOff(t);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 12000), isTrue, reason: 'he comes inside the wait');
      expect(M6CapProbe.minutes, lessThan(m6CapMinWait), reason: 'never a "time is up" cue');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker(d.jobs[0].kind).wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.push(d.jobs[0].kind).key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: the first reach for the bank waits for him; he cuts in at once', (t) async {
      final d = m6CapDeal(math.Random(himFirst));
      final c = await _open(t, himFirst);
      final j = d.jobs.first;
      await _waitOff(t);
      await _ready(t, j);
      await t.tapAt(_geo.terminal(j.kind, j.cans, 0) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(M6CapProbe.run!.discharged, isEmpty, reason: 'the held hook did nothing');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworker(j.kind).right, reason: false);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: shows while the level waits; three taps on nothing show it; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m6CapDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _waitOff(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle');
      expect(scene().debugFrame?.ripple, isNull, reason: 'never a press');
      // A tap on nothing (the sky right of the watch) hides it; three show it.
      final empty = const Offset(170, 150) * _k;
      await t.tapAt(empty);
      await _pump(t, 4500);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      await _ready(t, j);
      await _waitGame(t, d, 5.3);
      for (var k = 0; k < j.terminals; k++) {
        await _hook(t, d, j, k);
      }
      await t.tap(find.byKey(const ValueKey('handover-btn')));
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse);
      await _close(t, c);
    });
  });
}
