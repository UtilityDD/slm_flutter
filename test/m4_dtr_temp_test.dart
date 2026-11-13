// Lesson 4.5 (ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা), কাজ 2 "গরম কতটা?": the
// rules (measure from afar with the IR thermometer — a hand on the tank is
// deadly; read normal vs overheating; find the cause; decide), the deal, the
// option libraries, and the level in the shell: idle perf, the guide first,
// the guide's tap, a full clean play with the coworker refused, a slip card,
// the deadly freezes (the hand; the hand on his say-so), the 3-slip strike-out,
// a wrong cause costing a slip with a neutral reply, the coworker on a fast
// play (the tool pick waits for him), the praise window, the gesture hints.
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
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_dtr_temp.dart';
import 'package:slm_flutter/features/game/m4_dtr_temp_world.dart' show M4DtrTempGunPainter;
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '4.5/do/1', kind: CatalogRungKind.doKind, lessonId: '4.5', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

final _pack = m4DtrTempPacks['do_4_5_b']!;
typedef _L = M4DtrTempLines;

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
M4DtrTempGeo get _geo => M4DtrTempGeo.forScene(850 / _k, 0);
Offset _screen(Offset design) => design * _k;

Future<ProviderContainer> _open(WidgetTester t, int seed, {int settleMs = 600}) async {
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
        builder: (_) => M4DtrTempPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
      ),
    ),
  );
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, settleMs);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Offset _spotOf(M4DtrTempLook l) => switch (l) {
  M4DtrTempLook.gauge => _geo.gauge,
  M4DtrTempLook.fins => _geo.fins.center,
  M4DtrTempLook.load => _geo.load,
  M4DtrTempLook.ir => _geo.tank.center,
};

/// Plays job [i] right (refusing him on his job).
Future<void> _playRight(WidgetTester t, M4DtrTempDeal deal, int i) async {
  final j = deal.jobs[i];
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2000);
  }
  await t.tap(_label(_L.ir));
  await _pump(t, 400);
  await t.tapAt(_screen(_geo.tank.center));
  await _pump(t, 600);
  expect(find.byKey(const ValueKey('look-art')), findsOneWidget, reason: 'the thermometer screen, job $i');
  await t.tap(find.text(j.hot ? _L.over : _L.normal));
  await _pump(t, 600);
  if (j.hot) {
    // A fine spot first (a free look, no verdict), then the cause, flagged.
    final fine = M4DtrTempLook.values.firstWhere((l) => l != M4DtrTempLook.ir && l != j.cause);
    await t.tapAt(_screen(_spotOf(fine)));
    await _pump(t, 500);
    expect(find.text(_L.flagCause), findsOneWidget, reason: 'the flag under any look');
    await t.tapAt(_screen(_spotOf(j.cause!)));
    await _pump(t, 500);
    await t.tap(find.text(_L.flagCause));
    expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 6000), isTrue, reason: 'the decision, job $i');
    await _pump(t, 700);
    await _pickRight(t, _L.actRight(j.kase));
    await _pump(t, 900);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(j));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals three transformers: one overloaded, two of fins / low oil / normal; fresh each play', () {
      final seen = <String>{};
      final calls = <int>{};
      final irLeft = <bool>{};
      for (var s = 0; s < 60; s++) {
        final d = m4DtrTempDeal(math.Random(s));
        expect(d.jobs.length, 3);
        expect(d.jobs.where((j) => j.kase == M4DtrTempCase.overload), hasLength(1));
        expect(d.jobs.map((j) => j.kase).toSet().length, 3);
        expect(d.jobs.where((j) => j.hot).length, greaterThanOrEqualTo(2));
        calls.add(d.callAt);
        irLeft.addAll(d.jobs.map((j) => j.irLeft));
        seen.add(d.jobs.map((j) => '${j.kase.name}${j.topic.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(30));
      expect(calls, {0, 1, 2});
      expect(irLeft, {true, false}, reason: 'the tool stand is shuffled (the safe tool is not always first)');
    });

    M4DtrTempRun run1(M4DtrTempCase k) => M4DtrTempRun(
      M4DtrTempDeal(
        jobs: [M4DtrTempJob(kase: k, topic: M4DtrTempTopic.cause)],
        callAt: 0,
      ),
    );

    test('a hand on the tank is deadly; the IR thermometer goes on to aim, then read', () {
      final a = run1(M4DtrTempCase.overload);
      expect(a.pick(M4DtrTempTool.hand), M4DtrTempMistakes.handOnTank);
      expect(a.deadly!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = run1(M4DtrTempCase.overload);
      expect(b.pick(M4DtrTempTool.ir), isNull);
      expect(b.phase, M4DtrTempPhase.aim);
      expect(b.caught, contains(_L.caughtIr));
      b.aim();
      expect(b.phase, M4DtrTempPhase.read);
    });

    M4DtrTempRun toRead(M4DtrTempCase k) => run1(k)
      ..pick(M4DtrTempTool.ir)
      ..aim();

    test('read: normal called hot and hot called normal are slips; a hot one goes on to the cause', () {
      final a = toRead(M4DtrTempCase.normal);
      expect(a.judge(hot: true), M4DtrTempMistakes.mythHot);
      expect(a.phase, M4DtrTempPhase.done);
      expect(a.slips, 1);
      final b = toRead(M4DtrTempCase.normal);
      expect(b.judge(hot: false), isNull);
      expect(b.phase, M4DtrTempPhase.done);
      expect(b.caught, contains(_L.caughtRead));
      final c = toRead(M4DtrTempCase.fins);
      expect(c.judge(hot: false), M4DtrTempMistakes.missedHot);
      expect(c.phase, M4DtrTempPhase.find, reason: 'the guide puts it right; find the cause');
      final d = toRead(M4DtrTempCase.lowOil);
      expect(d.judge(hot: true), isNull);
      expect(d.phase, M4DtrTempPhase.find);
    });

    test('find: looks are free and give no verdict; flagging a wrong spot is a slip; the cause opens the decision; a wrong decision is a slip', () {
      for (final k in [M4DtrTempCase.overload, M4DtrTempCase.fins, M4DtrTempCase.lowOil]) {
        final r = toRead(k)..judge(hot: true);
        final cause = r.job.cause!;
        expect(r.flag(cause), isNull, reason: 'no flag before a look');
        expect(r.phase, M4DtrTempPhase.find);
        for (final l in M4DtrTempGeo.spots) {
          expect(r.look(l), isTrue);
          expect(r.phase, M4DtrTempPhase.find, reason: 'a look decides nothing');
        }
        expect(r.slips, 0);
        expect(r.look(M4DtrTempLook.ir), isFalse);
        for (final l in M4DtrTempGeo.spots) {
          if (l == cause) continue;
          expect(r.flag(l), M4DtrTempMistakes.wrongCause);
          expect(r.phase, M4DtrTempPhase.find, reason: 'the search goes on');
        }
        expect(r.slips, 2);
        expect(r.flag(cause), isNull);
        expect(r.phase, M4DtrTempPhase.act);
        expect(r.clean, isFalse);
        final w = toRead(k)
          ..judge(hot: true)
          ..look(cause)
          ..flag(cause);
        expect(w.act(right: false), M4DtrTempMistakes.wrongAct(k));
        expect(w.phase, M4DtrTempPhase.done);
        expect(r.act(right: true), isNull);
        final c = toRead(k)
          ..judge(hot: true)
          ..look(cause)
          ..flag(cause)
          ..act(right: true);
        expect(c.clean, isTrue);
        expect(c.phase, M4DtrTempPhase.done);
      }
      expect(M4DtrTempJob(kase: M4DtrTempCase.overload, topic: M4DtrTempTopic.cause).cause, M4DtrTempLook.load);
      expect(M4DtrTempJob(kase: M4DtrTempCase.fins, topic: M4DtrTempTopic.cause).cause, M4DtrTempLook.fins);
      expect(M4DtrTempJob(kase: M4DtrTempCase.lowOil, topic: M4DtrTempTopic.cause).cause, M4DtrTempLook.gauge);
    });

    test('mark: 100 − 15 per slip; next job starts at measure', () {
      final r = M4DtrTempRun(m4DtrTempDeal(math.Random(3)));
      r.slips = 3;
      expect(r.percent, 55);
      r.next();
      expect(r.phase, M4DtrTempPhase.measure);
      expect(r.checked, isEmpty);
    });

    test('English digits only; every mistake has its picture, a stable key; the one deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        _L.askLook,
        _L.flagCause,
        _L.missAim,
        ..._L.measureWhy,
        ..._L.normalWhy,
        ..._L.loadWhy,
        ..._L.finsWhy,
        ..._L.oilWhy,
        ..._L.whyWrong,
        ..._L.actLoad,
        ..._L.actFins,
        ..._L.actOil,
        ..._L.actWrong,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in M4DtrTempMistakes.all) m.textBn,
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4DtrTempMistakes.all.where((m) => m.deadly).toSet(), {M4DtrTempMistakes.handOnTank});
      for (final m in M4DtrTempMistakes.all) {
        expect(m.key, startsWith('4.5/m4_dtr_temp/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M4DtrTempMistakes.all.map((m) => m.key).toSet().length, M4DtrTempMistakes.all.length);
      for (final k in M4DtrTempCase.values) {
        expect(M4DtrTempMistakes.all, contains(M4DtrTempMistakes.wrongAct(k)));
      }
      expect(m4DtrTempPacks.keys, ['do_4_5_b']);
      expect(_pack.quickMs, 70000);
    });

    test('reasons and decisions fit, same length, big enough; his choices too', () {
      expectSameLength('why', [..._L.measureWhy, ..._L.normalWhy, ..._L.loadWhy, ..._L.finsWhy, ..._L.oilWhy, ..._L.whyWrong]);
      expectSameLength('act', [..._L.actLoad, ..._L.actFins, ..._L.actOil, ..._L.actWrong]);
      for (final k in M4DtrTempCase.values) {
        for (final tp in M4DtrTempTopic.values) {
          final j = M4DtrTempJob(kase: k, topic: tp);
          expectLibrary('$k $tp', _L.whyRight(j), _L.whyWrong);
          for (var s = 0; s < 10; s++) {
            final deal = dealChoices(_L.whyRight(j), _L.whyWrong, math.Random(s));
            expect(deal.where((o) => o.correct).length, 1);
            expect(deal.map((o) => o.textBn).toSet().length, 3);
          }
        }
        expectLibrary('act $k', _L.actRight(k), _L.actWrong);
      }
      expectSameLength('choice', [..._L.coworker.right, ..._L.coworker.wrong]);
      expectLibrary('choice', _L.coworker.right, _L.coworker.wrong);
      expect(_L.recordLines, hasLength(2));
    });

    test('the decision deck needs the cause: another cause\'s action is in it, no word gives the right one away', () {
      const hot = [M4DtrTempCase.overload, M4DtrTempCase.fins, M4DtrTempCase.lowOil];
      List<String> words(String s) => s.split(RegExp(r'[\s,—]+')).where((w) => w.isNotEmpty).toList();
      for (final k in hot) {
        final others = _L.actOthers(k);
        expect(others, hasLength(4), reason: '$k: both other causes');
        expect(others.toSet().intersection(_L.actRight(k).toSet()), isEmpty);
        // The words every right card of k shares are also on some card that
        // can be dealt wrong with it.
        final shared = words(_L.actRight(k).first).toSet();
        for (final r in _L.actRight(k).skip(1)) {
          shared.retainAll(words(r));
        }
        for (final w in shared) {
          expect([...others, ..._L.actWrong].any((o) => o.contains(w)), isTrue, reason: '$k: "$w" only on the right cards');
        }
        for (var s = 0; s < 40; s++) {
          final d = _L.dealAct(k, math.Random(s));
          expect(d, hasLength(3));
          expect(d.map((o) => o.textBn).toSet().length, 3);
          expect(d.where((o) => o.correct).map((o) => o.textBn).single, isIn(_L.actRight(k)));
          expect(d.where((o) => !o.correct && others.contains(o.textBn)), hasLength(1), reason: 'another cause\'s action');
          expect(d.where((o) => !o.correct && _L.actWrong.contains(o.textBn)), hasLength(1));
        }
      }
      // Cause-blind play ("always the card with word w") stays near chance.
      const tells = ['রিপোর্ট', 'শাটডাউন', 'বন্ধ', 'লোড', 'তেল', 'ফিন', 'লিক', 'টপ-আপ', 'লতা', 'লাইন'];
      for (final w in tells) {
        var wins = 0;
        var n = 0;
        for (final k in hot) {
          for (var s = 0; s < 400; s++) {
            final rng = math.Random(s * 7 + k.index);
            final d = _L.dealAct(k, rng);
            final has = d.where((o) => o.textBn.contains(w)).toList();
            final pick = (has.isEmpty ? d : has)[rng.nextInt(has.isEmpty ? d.length : has.length)];
            if (pick.correct) wins++;
            n++;
          }
        }
        expect(wins / n, lessThan(0.5), reason: '"$w" picks the right card ${(100 * wins / n).round()} % of the time');
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
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    int seedWhere(bool Function(M4DtrTempDeal d) ok) {
      var s = 0;
      while (!ok(m4DtrTempDeal(math.Random(s)))) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final seed = seedWhere((d) => d.callAt != 0);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: M4DtrTempPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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
        debugPrint('PERF m4_dtr_temp ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: M4DtrTempPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.ir), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(_label(_L.ir), findsOneWidget);
      expect(_label(_L.hand), findsOneWidget);
      expect(find.text(_L.jobBn(0)), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askMeasure)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final withNormal in [true, false]) {
      testWidgets('flow: three transformers right, him refused (${withNormal ? 'one normal' : 'all hot'}) → pass', (t) async {
        final seed = seedWhere((d) => d.jobs.any((j) => !j.hot) == withNormal);
        final deal = m4DtrTempDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRight(t, deal, i);
        }
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.5/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.5/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(_L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('overheating called normal: the slip card, then on to the cause', (t) async {
      final seed = seedWhere((d) => d.jobs[0].hot && d.callAt != 0);
      final c = await _open(t, seed);
      await t.tap(_label(_L.ir));
      await _pump(t, 400);
      // A miss is not scored: the guide asks again.
      await t.tapAt(_screen(const Offset(40, 200)));
      await _pump(t, 300);
      expect(find.text(_L.normal), findsNothing);
      await t.tapAt(_screen(_geo.tank.center));
      await _pump(t, 600);
      await t.tap(find.text(_L.normal));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DtrTempMistakes.missedHot.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(c.read(guideDirectorProvider).line, _L.putRightHot);
      await _close(t, c);
    });

    testWidgets('a hand on the tank: the yard freezes first, then the card (near-miss)', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      await t.tap(_label(_L.hand));
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4DtrTempMistakes.handOnTank.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = the palm on the tank: freeze, then the deadly card', (t) async {
      final seed = seedWhere((d) => d.callAt == 0);
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.last.key, M4DtrTempMistakes.handOnTank.key);
      expect(s.mistakes.last.deadly, isTrue);
      await _close(t, c);
    });

    /// IR, aim, and the reading of job 0.
    Future<void> toRead(WidgetTester t) async {
      await t.tap(_label(_L.ir));
      await _pump(t, 400);
      await t.tapAt(_screen(_geo.tank.center));
      await _pump(t, 600);
    }

    Future<void> gotIt(WidgetTester t) async {
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
    }

    testWidgets('a wrong cause: the looks give no verdict, the flag costs a slip, the reply stays neutral', (t) async {
      final seed = seedWhere((d) => d.jobs[0].hot && d.callAt != 0);
      final deal = m4DtrTempDeal(math.Random(seed));
      final cause = deal.jobs[0].cause!;
      final fine = M4DtrTempGeo.spots.firstWhere((l) => l != cause);
      final c = await _open(t, seed);
      await toRead(t);
      await t.tap(find.text(_L.over));
      await _pump(t, 600);
      // Any look gets the same words: no "all fine" before the call.
      final said = <String>[];
      for (final l in [fine, cause]) {
        await t.tapAt(_screen(_spotOf(l)));
        await _pump(t, 400);
        said.add(c.read(guideDirectorProvider).line);
        expect(find.byType(ChoiceDeck), findsNothing, reason: 'a look opens no decision');
      }
      expect(said, [_L.askLook, _L.askLook]);
      await t.tapAt(_screen(_spotOf(fine)));
      await _pump(t, 400);
      await t.tap(find.text(_L.flagCause));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DtrTempMistakes.wrongCause.key);
      await gotIt(t);
      expect(c.read(guideDirectorProvider).line, _L.askFind, reason: 'the search goes on with no hint of where');
      expect(find.text(_L.flagCause), findsNothing, reason: 'the close-up is closed');
      // The real cause still opens the decision.
      await t.tapAt(_screen(_spotOf(cause)));
      await _pump(t, 400);
      await t.tap(find.text(_L.flagCause));
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 6000), isTrue);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = seedWhere((d) => d.jobs[0].hot && d.callAt != 0);
      final deal = m4DtrTempDeal(math.Random(seed));
      final fine = M4DtrTempGeo.spots.firstWhere((l) => l != deal.jobs[0].cause);
      final c = await _open(t, seed);
      await toRead(t);
      // 1: overheating called normal.
      await t.tap(find.text(_L.normal));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      await gotIt(t);
      // 2 and 3: a fine spot flagged as the cause, twice.
      for (var k = 0; k < 2; k++) {
        await t.tapAt(_screen(_spotOf(fine)));
        await _pump(t, 400);
        await t.tap(find.text(_L.flagCause));
        await _pump(t, 900);
        if (k == 0) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await gotIt(t);
        }
      }
      expect(await _pumpUntil(t, find.byType(StruckOutCard), maxMs: 4000), isTrue);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.5/do/1'], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key).toSet(), {M4DtrTempMistakes.missedHot.key, M4DtrTempMistakes.wrongCause.key});
      expect(find.byType(LevelPassPanel), findsNothing);
      await _close(t, c);
    });

    testWidgets('a fast play: the tool pick waits for him, then works', (t) async {
      final seed = seedWhere((d) => d.callAt == 0);
      final c = await _open(t, seed, settleMs: 0);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not come yet');
      await t.tap(_label(_L.ir));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he comes at once on the pick');
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter is M4DtrTempGunPainter), isEmpty, reason: 'the pick did nothing yet');
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await t.tap(_label(_L.ir));
      await _pump(t, 400);
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter is M4DtrTempGunPainter), isNotEmpty, reason: 'now the thermometer is in his hand');
      await _close(t, c);
    });

    testWidgets('the praise window: the play gate is shut until the reason is paid; taps book nothing', (t) async {
      final seed = seedWhere((d) => !d.jobs[0].hot && d.callAt != 0);
      final c = await _open(t, seed);
      M4DtrTempPlayGate gate() => t.allStates.whereType<M4DtrTempPlayGate>().single;
      await toRead(t);
      expect(gate().debugCanPlay, isTrue, reason: 'the reading is live');
      final at = t.getCenter(find.text(_L.normal));
      await t.tap(find.text(_L.normal));
      await t.pump(const Duration(milliseconds: 50));
      // The ◆ waits on the table: the gate itself is shut (not only the phase).
      expect(gate().debugCanPlay, isFalse, reason: 'the praise window (tableBusy)');
      for (final p in [at, _screen(_geo.tank.center), _screen(_geo.gauge), t.getCenter(find.byKey(const ValueKey('hud-guide')))]) {
        await t.tapAt(p);
        await t.pump(const Duration(milliseconds: 50));
        expect(gate().debugCanPlay, isFalse);
      }
      await waitChoiceDeck(t);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(gate().debugCanPlay, isFalse, reason: 'the reason deck is up (tableBusy)');
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // Paid: the next transformer is live again.
      await _pickRight(t, _L.whyRight(m4DtrTempDeal(math.Random(seed)).jobs[0]));
      expect(await _pumpUntil(t, _label(_L.ir), maxMs: 6000), isTrue);
      expect(gate().debugCanPlay, isTrue, reason: 'the next job');
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over both tools, a tap on the tank, a sweep over both calls and every spot', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = seedWhere((d) => d.jobs[0].hot && d.callAt != 0);
      final c = await _open(t, seed);
      IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      Future<void> idle() async {
        for (var ms = 0; ms < 10000 && !hint().showing; ms += 100) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }

      await idle();
      expect(hint().showing, isTrue, reason: 'measure');
      expect(hint().debugOptions, hasLength(2), reason: 'a sweep over both tools, pressing none');
      await t.tap(_label(_L.ir));
      await _pump(t, 400);
      await idle();
      expect(hint().showing, isTrue, reason: 'aim');
      expect(hint().debugOptions, isEmpty, reason: 'a tap (the tank is the one way forward)');
      await t.tapAt(_screen(_geo.tank.center));
      await _pump(t, 600);
      await idle();
      expect(hint().debugOptions, hasLength(2), reason: 'a sweep over both calls');
      await t.tap(find.text(_L.over));
      await _pump(t, 600);
      await idle();
      expect(hint().debugOptions, hasLength(3), reason: 'a sweep over every spot, the cause no different');
      final fine = M4DtrTempGeo.spots.firstWhere((l) => l != m4DtrTempDeal(math.Random(seed)).jobs[0].cause);
      await t.tapAt(_screen(_spotOf(fine)));
      await _pump(t, 500);
      await idle();
      expect(hint().debugOptions, hasLength(4), reason: 'every spot and the flag');
      await t.tap(find.text(_L.flagCause));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 6000);
      expect(hint().showing, isFalse, reason: 'no hint over a card');
      await _close(t, c);
    });
  });
}
