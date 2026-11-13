// Lesson 2.5 (অপারেটিং রড / হট স্টিক), কাজ 2 "দূর থেকে চালাও": the rules
// (get ready before the rod goes up; stand to the side of a DO fuse; both
// hands below the guard; hook; DO = face aside + one quick stroke, AB = the
// breaker opened first + a slow turn), the deal, the option libraries, and the
// level in the shell: idle perf, the guide first, a full clean play with the
// coworker refused, a slip card, the deadly freezes (no gloves; the AB switch
// on-load on his say-so), three slips strike out, he comes even on a fast play
// (grip / call), the grip's beat takes no hook tap, gesture hints (the DO
// stroke: a sweep over the stroke spot and the face button), the praise window
// shuts the kit, the raise and his entry, no dead call button after listening.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/do_parts.dart' show DoBigButton;
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_hotstick_operate.dart';
import 'package:slm_flutter/features/game/m2_hotstick_operate_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/reason_table.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '2.5/do/1', kind: CatalogRungKind.doKind, lessonId: '2.5', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

final _pack = m2HotstickOperatePacks['do_2_5_b']!;

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
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
HsGeo get _geo => HsGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );
  unawaited(
    nav.currentState!.push(
      MaterialPageRoute<bool>(
        builder: (_) => M2HotstickOperatePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
      ),
    ),
  );
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await waitChoiceDeck(t);
  await _pickRight(t, s.right);
  await _pump(t, 2000);
}

Future<void> _prep(WidgetTester t, HsJob j, {bool gloves = true}) async {
  for (final l in [if (gloves) HsLines.gloves, HsLines.shield, HsLines.lock, j.isDo ? HsLines.puller : HsLines.socket]) {
    await t.tap(_label(l));
    await _pump(t, 150);
  }
  if (_label(HsLines.offload).evaluate().isNotEmpty) {
    await t.tap(_label(HsLines.offload));
    await _pump(t, 150);
  }
}

Future<void> _gripRight(WidgetTester t) async {
  final r = t.getRect(find.byKey(const ValueKey('grip-rod')));
  await t.tapAt(Offset(r.center.dx, r.bottom - r.height * 0.14));
  await _pump(t, 200);
  await t.tapAt(Offset(r.center.dx, r.bottom - r.height * 0.32));
  await _pump(t, 800);
}

/// Plays job [i] right (refusing him on his job).
Future<void> _playRight(WidgetTester t, HsDeal deal, int i) async {
  final j = deal.jobs[i];
  final his = i == deal.callAt;
  if (his && !j.isDo) await _refuse(t, HsLines.coworkerAb);
  await _prep(t, j);
  await t.tap(find.text(HsLines.raise));
  await _pump(t, 500);
  final g = _geo;
  if (j.isDo) {
    await t.tapAt(_screen(Offset(HsGeo.phaseX[j.phase] - 70, g.groundY + 20)));
    await _pump(t, 900);
    if (his) await _refuse(t, HsLines.coworkerDo);
  }
  expect(await _pumpUntil(t, find.byKey(const ValueKey('grip-rod')), maxMs: 3000), isTrue, reason: 'grip, job $i');
  await _gripRight(t);
  await t.tapAt(_screen(hsTargetOf(g, j, open: j.kind == HsKind.doClose)));
  await _pump(t, 500);
  final start = _screen(const Offset(200, 380));
  if (j.isDo) {
    await t.tap(_label(HsLines.faceAside));
    await _pump(t, 200);
    await t.dragFrom(start, Offset(0, j.kind == HsKind.doOpen ? 140 : -140));
  } else {
    await t.timedDragFrom(start, const Offset(150, 0), const Duration(milliseconds: 1500));
  }
  await _pump(t, 600);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  await waitChoiceDeck(t);
  await _pickRight(t, HsLines.whyRight(j));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals three jobs: one AB switch, at least one DO open; fresh each play', () {
      final seen = <String>{};
      final calls = <bool>{};
      for (var s = 0; s < 60; s++) {
        final d = dealHotstick(math.Random(s));
        expect(d.jobs.length, 3);
        expect(d.jobs.where((j) => j.kind == HsKind.abOff), hasLength(1));
        expect(d.jobs.where((j) => j.kind == HsKind.doOpen), isNotEmpty);
        expect(d.callAt, inInclusiveRange(0, 2));
        calls.add(d.jobs[d.callAt].isDo);
        for (final j in d.jobs) {
          expect(j.isDo ? [HsTopic.stand, HsTopic.stroke] : [HsTopic.offload, HsTopic.turn], contains(j.topic));
        }
        seen.add(d.jobs.map((j) => '${j.kind.name}${j.phase}${j.topic.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(40));
      expect(calls, {true, false}, reason: 'he comes on a DO job and on the AB job');
    });

    HsRun run1(HsKind k, {int phase = 1}) => HsRun(
      HsDeal(
        jobs: [HsJob(kind: k, phase: phase, topic: HsTopic.stand)],
        callAt: 0,
      ),
    );
    HsRun ready(HsKind k) {
      final r = run1(k);
      for (final x in HsKit.values) {
        r.wear(x);
      }
      r.fit(k == HsKind.abOff ? HsHead.socket : HsHead.puller);
      return r;
    }

    test('the rod goes up only after gloves, head, lock, shield: no gloves = deadly; the rest are slips, put right', () {
      final a = run1(HsKind.doOpen);
      expect(a.raise(), HsMistakes.noGloves);
      expect(a.deadly!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = run1(HsKind.doOpen)
        ..wear(HsKit.gloves)
        ..wear(HsKit.shield)
        ..wear(HsKit.lock)
        ..fit(HsHead.socket);
      expect(b.raise(), HsMistakes.badHead, reason: 'a socket on a DO fuse');
      expect(b.slips, 1);
      expect(b.head, HsHead.puller, reason: 'the guide put it right');
      expect(b.phase, HsPhase.stand);
      final c = run1(HsKind.abOff)
        ..wear(HsKit.gloves)
        ..wear(HsKit.shield)
        ..fit(HsHead.socket);
      expect(c.raise(), HsMistakes.unlocked);
      expect(c.phase, HsPhase.grip, reason: 'no stand step at the AB switch');
      final d = run1(HsKind.doClose)
        ..wear(HsKit.gloves)
        ..wear(HsKit.lock)
        ..fit(HsHead.puller);
      expect(d.raise(), HsMistakes.noShield);
      final ok = ready(HsKind.doOpen);
      expect(ok.raise(), isNull);
      expect(ok.caught, contains(HsLines.caughtKit));
      expect(ok.slips, 0);
    });

    test('where to stand: under the fuse is a slip; too far is not scored; to the side is right', () {
      expect(hsStandOf(0), HsStand.under);
      expect(hsStandOf(-20), HsStand.under);
      expect(hsStandOf(70), HsStand.side);
      expect(hsStandOf(-70), HsStand.side);
      expect(hsStandOf(160), HsStand.far);
      final a = ready(HsKind.doOpen)..raise();
      expect(a.stand(200).$2, isNull);
      expect(a.phase, HsPhase.stand, reason: 'too far: the step stays');
      expect(a.slips, 0);
      expect(a.stand(5).$2, HsMistakes.underFuse);
      expect(a.slips, 1);
      expect(a.phase, HsPhase.grip);
      final b = ready(HsKind.doOpen)..raise();
      expect(b.stand(-60).$2, isNull);
      expect(b.caught, contains(HsLines.caughtStand));
    });

    test('the grip: a hand above the guard is a slip', () {
      final a = ready(HsKind.abOff)..raise();
      expect(a.grip(above: true), HsMistakes.aboveGuard);
      expect(a.phase, HsPhase.hook);
      final b = ready(HsKind.abOff)..raise();
      expect(b.grip(above: false), isNull);
      expect(b.caught, contains(HsLines.caughtGrip));
    });

    HsRun toOperate(HsRun r) {
      r.raise();
      if (r.job.isDo) r.stand(70);
      r
        ..grip(above: false)
        ..hook();
      expect(r.phase, HsPhase.operate);
      return r;
    }

    test('DO: one quick stroke (short / slow are not scored), off-load, face aside', () {
      final a = toOperate(ready(HsKind.doOpen));
      expect(a.operate(30, 100).$1, HsStroke.short);
      expect(a.operate(120, 2000).$1, HsStroke.slow);
      expect(a.slips, 0);
      expect(a.phase, HsPhase.operate);
      expect(a.operate(120, 300).$2, HsMistakes.faceIn);
      final b = toOperate(ready(HsKind.doOpen))..turnFace();
      expect(b.operate(120, 300), (HsStroke.done, null));
      expect(b.caught, contains(HsLines.caughtStroke));
      expect(b.clean, isTrue);
      final c = run1(HsKind.doClose)
        ..wear(HsKit.gloves)
        ..wear(HsKit.shield)
        ..wear(HsKit.lock)
        ..fit(HsHead.puller);
      toOperate(c).turnFace();
      expect(c.operate(120, 300).$2, HsMistakes.onLoadDo);
      expect(c.deadly, isNull);
    });

    test('AB: on-load is deadly (also on his say-so); a rushed turn is a slip; slow is right', () {
      final a = run1(HsKind.abOff)
        ..wear(HsKit.gloves)
        ..wear(HsKit.shield)
        ..wear(HsKit.lock)
        ..fit(HsHead.socket);
      toOperate(a);
      expect(a.operate(150, 1500).$2, HsMistakes.onLoadAb);
      expect(a.deadly!.deadly, isTrue);
      final b = ready(HsKind.abOff)..skippedCall = true;
      toOperate(b);
      expect(b.operate(150, 1500).$2, HsMistakes.onLoadAb, reason: 'he talked him out of the call');
      final c = toOperate(ready(HsKind.abOff));
      expect(c.operate(150, 300).$2, HsMistakes.rushAb);
      final d = toOperate(ready(HsKind.abOff));
      expect(d.operate(150, 1500), (HsStroke.done, null));
      expect(d.caught, containsAll([HsLines.caughtOffload, HsLines.caughtTurn]));
    });

    test('mark: 100 − 15 per slip; next job clears the kit', () {
      final r = HsRun(dealHotstick(math.Random(3)));
      r.slips = 3;
      expect(r.percent, 55);
      r.wear(HsKit.gloves);
      r.next();
      expect(r.kit, isEmpty);
      expect(r.phase, HsPhase.prep);
    });

    test('English digits only; every mistake has its picture, a stable key; the deadly two', () {
      final all = <String>[
        HsLines.intro,
        ...HsLines.tasks,
        ...HsLines.standWhy,
        ...HsLines.strokeWhy,
        ...HsLines.offloadWhy,
        ...HsLines.turnWhy,
        ...HsLines.whyWrong,
        for (final s in [HsLines.coworkerDo, HsLines.coworkerAb]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in HsMistakes.all) m.textBn,
        HsLines.allSet,
        HsLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(HsMistakes.all.where((m) => m.deadly).toSet(), {HsMistakes.noGloves, HsMistakes.onLoadAb});
      for (final m in HsMistakes.all) {
        expect(m.key, startsWith('2.5/hotstick-op/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(HsMistakes.all.map((m) => m.key).toSet().length, HsMistakes.all.length);
      expect(m2HotstickOperatePacks.keys, ['do_2_5_b']);
      expect(_pack.quickMs, 80000);
    });

    test('reasons fit the step, same length, big enough; his choices too', () {
      expectSameLength('why', [...HsLines.standWhy, ...HsLines.strokeWhy, ...HsLines.offloadWhy, ...HsLines.turnWhy, ...HsLines.whyWrong]);
      for (final j in dealHotstick(math.Random(1)).jobs) {
        expectLibrary('${j.topic}', HsLines.whyRight(j), HsLines.whyWrong);
      }
      for (final tp in HsTopic.values) {
        final j = HsJob(kind: tp == HsTopic.offload || tp == HsTopic.turn ? HsKind.abOff : HsKind.doOpen, phase: 0, topic: tp);
        final right = HsLines.whyRight(j);
        expectLibrary('$tp', right, HsLines.whyWrong);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, HsLines.whyWrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      for (final s in [HsLines.coworkerDo, HsLines.coworkerAb]) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
      }
      expect(HsLines.recordLines, hasLength(2));
    });

    test('no giveaways: "না" is not only on his right cards; the too-far reply never names the side', () {
      for (final s in [HsLines.coworkerDo, HsLines.coworkerAb]) {
        expect(s.wrong.any((w) => w.startsWith('না')), isTrue, reason: s.line);
        expect(s.right.every((r) => r.startsWith('না')), isFalse, reason: s.line);
      }
      expect(HsLines.tooFar, isNot(contains('পাশে')));
      // The lesson's key words are on a wrong card too (no word-only-on-right tell).
      for (final (s, words) in [
        (HsLines.coworkerAb, ['ব্রেকার', 'আগে']),
        (HsLines.coworkerDo, ['নিচে']),
      ]) {
        for (final w in words) {
          expect(s.wrong.any((x) => x.contains(w)), isTrue, reason: w);
        }
      }
    });

    test('the AB on-load card follows the lesson ("মারাত্মকভাবে ক্ষতিগ্রস্ত", not "শেষ")', () {
      expect(HsMistakes.onLoadAb.textBn, contains('মারাত্মকভাবে ক্ষতিগ্রস্ত'));
      expect(HsMistakes.onLoadAb.textBn, isNot(contains('শেষ')));
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    int seedWhere(bool Function(HsDeal d) ok) {
      var s = 0;
      while (!ok(dealHotstick(math.Random(s)))) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final seed = seedWhere((d) => d.jobs[d.callAt].isDo);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: M2HotstickOperatePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m2_hotstick_operate ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the kit', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: M2HotstickOperatePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(HsLines.raise), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(HsLines.raise), findsOneWidget);
      expect(find.text(HsLines.jobBn(dealHotstick(math.Random(seed)).jobs[0])), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(HsLines.askPrep)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final onDo in [true, false]) {
      testWidgets('flow: three jobs right, him refused (${onDo ? 'DO grip' : 'AB call'}) → pass', (t) async {
        final seed = seedWhere((d) => d.jobs[d.callAt].isDo == onDo);
        final deal = dealHotstick(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRight(t, deal, i);
        }
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['2.5/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['2.5/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(HsLines.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('standing under the fuse: the slip card, then the job goes on', (t) async {
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt != 0);
      final deal = dealHotstick(math.Random(seed));
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await _prep(t, j);
      await t.tap(find.text(HsLines.raise));
      await _pump(t, 500);
      await t.tapAt(_screen(Offset(HsGeo.phaseX[j.phase], _geo.groundY + 20)));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, HsMistakes.underFuse.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byKey(const ValueKey('grip-rod')), findsOneWidget, reason: 'on to the grip');
      await _close(t, c);
    });

    testWidgets('the rod up without গ্লাভস: the yard freezes first, then the card (near-miss)', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      await _prep(t, j, gloves: false);
      await t.tap(find.text(HsLines.raise));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, HsMistakes.noGloves.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him at the AB switch = turned on-load: freeze, then the deadly card', (t) async {
      final seed = seedWhere((d) => !d.jobs[d.callAt].isDo);
      final deal = dealHotstick(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(HsLines.coworkerAb.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1500);
      // He works on as told: ready, rod up, grip, hook, turn — no call.
      final j = deal.jobs[deal.callAt];
      expect(_label(HsLines.offload), findsNothing, reason: 'no dead call button after listening');
      await _prep(t, j);
      expect(find.text(HsLines.offloadDone), findsNothing);
      await t.tap(find.text(HsLines.raise));
      await _pump(t, 500);
      await _gripRight(t);
      await t.tapAt(_screen(_geo.handle));
      await _pump(t, 500);
      await t.timedDragFrom(_screen(const Offset(200, 380)), const Offset(150, 0), const Duration(milliseconds: 1500));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.last.key, HsMistakes.onLoadAb.key);
      expect(s.mistakes.last.deadly, isTrue);
      await _close(t, c);
    });

    Future<void> gotIt(WidgetTester t) async {
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
    }

    Future<void> standAside(WidgetTester t, HsJob j) async {
      await _prep(t, j);
      await t.tap(find.text(HsLines.raise));
      await _pump(t, 500);
      await t.tapAt(_screen(Offset(HsGeo.phaseX[j.phase] - 70, _geo.groundY + 20)));
    }

    Future<void> gripAbove(WidgetTester t) async {
      final r = t.getRect(find.byKey(const ValueKey('grip-rod')));
      await t.tapAt(Offset(r.center.dx, r.top + r.height * 0.1));
      await _pump(t, 200);
      await t.tapAt(Offset(r.center.dx, r.top + r.height * 0.25));
    }

    testWidgets('three slips (wrong head, under the fuse, a hand above the guard): struck out', (t) async {
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt != 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      for (final l in [HsLines.gloves, HsLines.shield, HsLines.lock, HsLines.socket, HsLines.offload]) {
        await t.tap(_label(l));
        await _pump(t, 150);
      }
      await t.tap(find.text(HsLines.raise));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'a socket on a DO fuse');
      await gotIt(t);
      await t.tapAt(_screen(Offset(HsGeo.phaseX[j.phase], _geo.groundY + 20)));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'under the fuse');
      await gotIt(t);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('grip-rod')), maxMs: 3000), isTrue);
      await gripAbove(t);
      await _pump(t, 1200);
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key).toSet(), {HsMistakes.badHead.key, HsMistakes.underFuse.key, HsMistakes.aboveGuard.key});
      expect(s.rungProgress['2.5/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: two quick hands on the grip wait for him (DO)', (t) async {
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt == 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      await standAside(t, j);
      await _pump(t, 400);
      // Well before his 1.2 s timer: both hands at once.
      final r = t.getRect(find.byKey(const ValueKey('grip-rod')));
      await t.tapAt(Offset(r.center.dx, r.bottom - r.height * 0.14));
      await t.pump(const Duration(milliseconds: 50));
      await t.tapAt(Offset(r.center.dx, r.bottom - r.height * 0.32));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the first hand waited for him');
      expect(find.byKey(const ValueKey('hud-face')), findsNothing);
      await _refuse(t, HsLines.coworkerDo);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('grip-rod')), maxMs: 3000), isTrue, reason: 'back to the grip');
      await _gripRight(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await t.tapAt(_screen(hsTargetOf(_geo, j, open: j.kind == HsKind.doClose)));
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('hud-face')), findsOneWidget, reason: 'on to the stroke');
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: the breaker call at once waits for him (AB)', (t) async {
      final seed = seedWhere((d) => !d.jobs[0].isDo && d.callAt == 0);
      final c = await _open(t, seed);
      await t.tap(_label(HsLines.offload));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the call waited for him');
      expect(find.text(HsLines.offloadDone), findsNothing);
      await _refuse(t, HsLines.coworkerAb);
      expect(find.text(HsLines.offloadDone), findsOneWidget, reason: 'refused: the call is made');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening at the grip is a slip (not deadly); the job goes on', (t) async {
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt == 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      await standAside(t, j);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(HsLines.coworkerDo.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, HsMistakes.aboveGuard.key);
      await gotIt(t);
      await t.tapAt(_screen(hsTargetOf(_geo, j, open: j.kind == HsKind.doClose)));
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('hud-face')), findsOneWidget, reason: 'hook, then the stroke');
      await _close(t, c);
    });

    testWidgets('the grip beat takes no hook tap: the hook waits until the card is read', (t) async {
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt != 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      await standAside(t, j);
      await _pump(t, 900);
      await gripAbove(t);
      // Inside the 350 ms beat: a quick tap on the ring.
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(_screen(hsTargetOf(_geo, j, open: j.kind == HsKind.doClose)));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await gotIt(t);
      expect(find.byKey(const ValueKey('hud-face')), findsNothing, reason: 'the hook tap in the beat did not count');
      await t.tapAt(_screen(hsTargetOf(_geo, j, open: j.kind == HsKind.doClose)));
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('hud-face')), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, HsMistakes.aboveGuard.key);
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over the kit after idle; taps on the sky call it at the stand step', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const hand = ValueKey('gesture-hint');
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt != 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      expect(find.byKey(hand), findsNothing);
      await _pump(t, 9000);
      expect(find.byKey(hand), findsOneWidget, reason: 'idle in the kit step');
      expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'a hint never presses anything');
      expect(find.text(HsLines.offloadDone), findsNothing);
      await _prep(t, j);
      expect(find.byKey(hand), findsNothing, reason: 'any touch hides it');
      await t.tap(find.text(HsLines.raise));
      await _pump(t, 1500);
      for (var i = 0; i < 3; i++) {
        await t.tapAt(_screen(Offset(60, _geo.armY - 60)));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byKey(hand), findsOneWidget, reason: 'taps on the sky call the hand');
      await _close(t, c);
    });

    testWidgets('gesture hints at a DO stroke: a sweep over the stroke spot and the face button, never a lone drag', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = seedWhere((d) => d.jobs[0].isDo && d.callAt != 0);
      final j = dealHotstick(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      await standAside(t, j);
      await _pump(t, 900);
      await _gripRight(t);
      await t.tapAt(_screen(hsTargetOf(_geo, j, open: j.kind == HsKind.doClose)));
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('hud-face')), findsOneWidget);
      final faceRect = t.getRect(find.byKey(const ValueKey('hud-face')));
      final sceneHint = find.byType(IdleHint).first;
      HintSpec spec() => t.widget<IdleHint>(sceneHint).spec(Size.zero)!;
      // Before the face is aside: a sweep over the stroke spot and the face button alike.
      final sweep = spec();
      expect(sweep.kind, HintKind.sweep);
      expect(sweep.options, hasLength(2));
      expect(sweep.options.where((r) => r.overlaps(faceRect)), hasLength(1), reason: 'the face button is one of the two');
      final hint = t.state<IdleHintState>(sceneHint);
      await _pump(t, 9000);
      expect(hint.showing, isTrue, reason: 'idle at the stroke');
      expect(hint.debugOptions, hasLength(2));
      // Face aside: now the stroke is the one way on — a short drag nudge.
      await t.tap(_label(HsLines.faceAside));
      await _pump(t, 200);
      final drag = spec();
      expect(drag.kind, HintKind.drag);
      expect(drag.travel, lessThanOrEqualTo(HintSpec.maxDragTravel));
      expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'a hint never presses anything');
      await _close(t, c);
    });

    testWidgets('praise window: while the ◆ table holds, the kit, the raise and his entry are shut', (t) async {
      final seed = seedWhere((d) => !d.jobs[0].isDo && d.callAt == 0);
      final c = await _open(t, seed);
      final st = t.allStates.whereType<ReasonTable>().single;
      final cw = st as CoworkerMoment;
      expect(cw.coworkerCanCome(), isTrue, reason: 'his AB moment, before the call');
      GestureDetector glovesTap() => t.widget<GestureDetector>(find.descendant(of: _label(HsLines.gloves), matching: find.byType(GestureDetector)));
      expect(glovesTap().onTap, isNotNull);
      st.putOnTable(15);
      await t.pump();
      expect(st.tableHolding, isTrue);
      expect(cw.coworkerCanCome(), isFalse, reason: 'he never cuts into the praise window');
      expect(glovesTap().onTap, isNull, reason: 'the kit is shut');
      // The raise without গ্লাভস would be deadly — straight past the frame's shield, it does nothing.
      t.widget<DoBigButton>(find.byType(DoBigButton)).onTapUp(TapUpDetails(kind: PointerDeviceKind.touch, globalPosition: const Offset(196, 700)));
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
