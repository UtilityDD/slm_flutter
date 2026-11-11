// Ladder step 21 (lesson 1.7 কাজ 2, "গোল্ডেন মিনিট"): the order rules, the
// deal, the CPR rhythm (AHA 100–120 a minute), fair reason libraries that fit
// each step, the coworker's recorded lines, and the level in the shell: idle
// perf, the guide first, a full clean play for each ending (the ambulance
// arrives / he comes round) with every reason and the coworker refused, his
// call-step myth before CPR even after a fast bystander tap, the slips (out
// of order, calling yourself, stopping CPR — a second stop only a reminder —
// listening to him) and the 3-slip strike-out.
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
import 'package:slm_flutter/features/game/golden_minute.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

final _ctx = LevelContext(
  rungId: '1.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.7',
  lessonTitleBn: '',
  ladderStep: 21,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Taps the one right card on the deck now up.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

/// The first seed whose deal satisfies [ok].
int _seedWhere(bool Function(GoldenDeal d) ok) {
  for (var s = 0;; s++) {
    if (ok(dealGolden(math.Random(s)))) return s;
  }
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => GoldenMinutePage(ctx: _ctx, pack: goldenPack17, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

// --- hands-on helpers ----------------------------------------------------------
Future<void> _shoulder(WidgetTester t) async {
  await t.tap(_label(GoldenLines.zoneShoulder), warnIfMissed: false);
  await _pump(t, 3200);
}

Future<void> _face(WidgetTester t) async {
  final g = await t.startGesture(t.getCenter(_label(GoldenLines.zoneFace)));
  await _pump(t, 2200);
  await g.up();
  await _pump(t, 2600);
}

Future<void> _crowd(WidgetTester t, int who) async {
  await t.tap(_label(GoldenLines.zoneCrowd).at(who), warnIfMissed: false);
  await _pump(t, 3400);
}

/// CPR in rhythm (one compression every [ms]) for [count] compressions.
Future<void> _cpr(WidgetTester t, {int ms = 545, int count = 20}) async {
  final chest = _label(GoldenLines.zoneChest);
  await t.tap(chest, warnIfMissed: false);
  for (var i = 0; i < count; i++) {
    await t.pump(Duration(milliseconds: ms));
    if (chest.evaluate().isEmpty) break;
    await t.tap(chest, warnIfMissed: false);
  }
}

Future<void> _reason(WidgetTester t, List<String> right, {int after = 3200}) async {
  await _pickRight(t, right);
  await _pump(t, after);
}

Future<void> _refuse(WidgetTester t, CrowdMyth m) async {
  await _pump(t, 3600);
  expect(find.byType(CoworkerPeek), findsOneWidget);
  await _pickRight(t, GoldenLines.coworker(m).right);
}

void main() {
  group('rules', () {
    test('the order: response, breathing, call, CPR, keep going; a step out of order is a slip and stays', () {
      final r = GoldenRun(dealGolden(math.Random(1)));
      expect(r.act(GoldenAct.chest).mistake, GoldenMistakes.order);
      expect(r.act(GoldenAct.crowd).mistake, GoldenMistakes.order);
      expect(r.act(GoldenAct.face).mistake, GoldenMistakes.order);
      expect(r.pending, GoldenStep.response);
      expect(r.act(GoldenAct.shoulder).kind, GoldenMoveKind.ok);
      expect(r.act(GoldenAct.shoulder).kind, GoldenMoveKind.ignored, reason: 'already done');
      expect(r.act(GoldenAct.chest).mistake, GoldenMistakes.order, reason: 'breathing first');
      expect(r.act(GoldenAct.face).kind, GoldenMoveKind.ok);
      expect(r.act(GoldenAct.chest).mistake, GoldenMistakes.cprFirst, reason: 'someone calls first');
      expect(r.act(GoldenAct.crowd).kind, GoldenMoveKind.ok);
      expect(r.act(GoldenAct.phone).kind, GoldenMoveKind.ignored, reason: 'the call is made');
      expect(r.act(GoldenAct.chest).kind, GoldenMoveKind.ok);
      expect(r.inCpr, isTrue);
      expect(r.act(GoldenAct.shoulder).kind, GoldenMoveKind.ignored, reason: 'during CPR');
      r.helpCame();
      expect(r.done, isTrue);
      expect(r.slips, 5);
      expect(r.orderSlips, 5);
      expect(r.percent, 25);
      expect(r.passed, isFalse);
    });

    test('calling the ambulance yourself (before the call is made) is a slip', () {
      final r = GoldenRun(dealGolden(math.Random(2)));
      expect(r.act(GoldenAct.phone).mistake, GoldenMistakes.callSelf);
      r
        ..act(GoldenAct.shoulder)
        ..act(GoldenAct.face);
      expect(r.act(GoldenAct.phone).mistake, GoldenMistakes.callSelf);
      expect(r.pending, GoldenStep.call);
      expect(r.slips, 2);
      expect(r.orderSlips, 0);
    });

    test('stopping CPR before help comes: a slip the first time, then only a reminder', () {
      final r = GoldenRun(dealGolden(math.Random(3)));
      expect(r.stopped(), isNull, reason: 'not in CPR');
      for (final a in [GoldenAct.shoulder, GoldenAct.face, GoldenAct.crowd, GoldenAct.chest]) {
        r.act(a);
      }
      expect(r.stopped(), GoldenMistakes.stopped);
      expect(r.stopped(), isNull);
      expect(r.slips, 1);
      expect(r.listened(CrowdMyth.mud), GoldenMistakes.myth(CrowdMyth.mud));
      expect(r.slips, 2);
      expect(r.percent, 70);
      expect(r.passed, isTrue);
    });

    test('no deadly here; every mistake has its lesson point and picture', () {
      for (final m in GoldenMistakes.all) {
        expect(m.deadly, isFalse, reason: m.key);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(GoldenMistakes.all.map((m) => m.key).toSet().length, GoldenMistakes.all.length);
    });

    test('the deal: one of the three myths; before CPR he comes at breathing or the call, "talking" only after he comes round', () {
      final seen = <String>{};
      final myths = <CrowdMyth>{};
      for (var s = 0; s < 80; s++) {
        final d = dealGolden(math.Random(s));
        expect(dealtMyths, contains(d.myth));
        myths.add(d.myth);
        if (d.myth == CrowdMyth.home) {
          expect(d.mythAt, isNull);
          expect(d.comesRound, isTrue);
        } else {
          expect([GoldenStep.breathing, GoldenStep.call], contains(d.mythAt));
          expect(d.comesRound, isFalse);
        }
        expect(d.crowd, hasLength(3));
        expect(d.crowd.toSet(), hasLength(3));
        seen.add('${d.myth}-${d.mythAt}-${d.crowd}-${d.phoneLeft}');
      }
      expect(myths, dealtMyths.toSet());
      expect(seen.length, greaterThan(20), reason: 'plays differ');
    });

    test('the rhythm: 100–120 a minute (AHA) is good; too slow or too fast is not; pauses are not intervals', () {
      GoldenRhythm at(int ms, int n) {
        final r = GoldenRhythm();
        for (var i = 0; i < n; i++) {
          r.add(i * ms);
        }
        return r;
      }

      expect(at(545, 16).good, isTrue);
      expect(at(545, 16).rate, 110);
      expect(at(500, 12).good, isTrue);
      expect(at(600, 12).good, isTrue);
      expect(at(800, 12).good, isFalse, reason: '75 a minute');
      expect(at(350, 20).good, isFalse, reason: '171 a minute');
      expect(at(545, 5).good, isFalse, reason: 'too few');
      final p = at(545, 8)..add(7 * 545 + 4000);
      expect(p.intervals, hasLength(7));
      expect(p.average, 110);
    });
  });

  group('libraries', () {
    test('each step\'s deck: one right, all cards about the same length, big enough', () {
      for (final s in GoldenStep.values) {
        final right = {
          ...GoldenLines.whyRight(s, awake: true),
          ...GoldenLines.whyRight(s),
        }.toList();
        final wrong = GoldenLines.whyWrong(s);
        expectSameLength('why $s', [...right, ...wrong]);
        expectLibrary('why $s', GoldenLines.whyRight(s), wrong);
        expect(right.toSet().intersection(wrong.toSet()), isEmpty);
        for (var seed = 0; seed < 12; seed++) {
          final deal = dealChoices(GoldenLines.whyRight(s), wrong, math.Random(seed));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
    });

    test('the CPR deck says why (no rate card the meter would give away); CPR only if trained; the keep reasons fit the ending', () {
      for (final l in [...GoldenLines.whyRight(GoldenStep.cpr), ...GoldenLines.whyWrong(GoldenStep.cpr)]) {
        expect(l, isNot(contains('AHA')), reason: l);
        expect(l, isNot(contains('100')), reason: l);
      }
      expect(GoldenLines.askCpr, contains('প্রশিক্ষিত'), reason: 'lesson 1.7 point 4: প্রশিক্ষিত হলে CPR');
      expect(GoldenMistakes.cprFirst.textBn, contains('প্রশিক্ষিত'));
      // "CPR" on a card is no tell: wrong cards carry it too.
      for (final s in [GoldenStep.breathing, GoldenStep.call, GoldenStep.keep]) {
        expect(GoldenLines.whyWrong(s).any((l) => l.contains('CPR')), isTrue, reason: '$s');
      }
      expect(GoldenLines.whyRight(GoldenStep.keep, awake: true).any((l) => l.contains('জ্ঞান')), isTrue);
      expect(GoldenLines.whyRight(GoldenStep.keep).any((l) => l.contains('অ্যাম্বুলেন্স')), isTrue);
    });

    test('the coworker: his choices fair and big enough; his lines in his recorded voice', () {
      for (final c in GoldenLines.coworkers) {
        expectSameLength('choice ${c.line}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${c.line}', c.right, c.wrong);
        for (final l in c.recordedLines) {
          expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
        }
      }
      for (final m in dealtMyths) {
        expect(GoldenLines.coworker(m), isNotNull);
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: GoldenMinutePage(ctx: _ctx, pack: goldenPack17, muted: true, seed: 2)),
        ));
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
        debugPrint('PERF golden ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: GoldenMinutePage(ctx: _ctx, pack: goldenPack17, muted: true, seed: 2)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(GoldenLines.zoneShoulder), findsNothing);
      await waitIntro(t);
      await _pump(t, 1000);
      expect(_label(GoldenLines.zoneShoulder), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(GoldenLines.askFirst)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final ending in ['ambulance', 'awake']) {
      testWidgets('flow ($ending): every step by hand, every reason, CPR in rhythm, the coworker refused → pass', (t) async {
        final seed = _seedWhere((d) => ending == 'awake' ? d.comesRound : d.mythAt == GoldenStep.breathing);
        final deal = dealGolden(math.Random(seed));
        final c = await _open(t, seed);
        await _shoulder(t);
        expect(find.text(GoldenLines.noResponse), findsOneWidget);
        await _reason(t, GoldenLines.whyRight(GoldenStep.response));
        if (deal.mythAt == GoldenStep.breathing) {
          await _refuse(t, deal.myth);
          await _pump(t, 3000);
        }
        await _face(t);
        expect(find.text(GoldenLines.noBreath), findsOneWidget);
        await _reason(t, GoldenLines.whyRight(GoldenStep.breathing));
        if (deal.mythAt == GoldenStep.call) {
          await _refuse(t, deal.myth);
          await _pump(t, 3000);
        }
        await _crowd(t, 1);
        await _reason(t, GoldenLines.whyRight(GoldenStep.call));
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _cpr(t);
        await _pump(t, 3500);
        expect(find.text(GoldenLines.aha), findsOneWidget, reason: 'the meter cites the guideline');
        await _reason(t, GoldenLines.whyRight(GoldenStep.cpr));
        await _reason(t, GoldenLines.whyRight(GoldenStep.keep, awake: deal.comesRound), after: 1500);
        if (deal.comesRound) {
          await _refuse(t, deal.myth);
        }
        await _pump(t, 9000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['1.7/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['1.7/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        for (final l in [GoldenLines.caughtOrder, GoldenLines.caughtRhythm, GoldenLines.caughtKeep, GoldenLines.caughtCrowd]) {
          expect(find.text(l), findsOneWidget, reason: l);
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a step out of order is a slip with its card; the step stays to do', (t) async {
      final c = await _open(t, _seedWhere((d) => d.comesRound));
      await t.tap(_label(GoldenLines.zoneChest), warnIfMissed: false);
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, GoldenMistakes.order.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _shoulder(t);
      expect(find.text(GoldenLines.noResponse), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('calling yourself, then two steps out of order: three slips strike out', (t) async {
      final c = await _open(t, _seedWhere((d) => d.comesRound));
      Future<void> slip(Finder f) async {
        await t.tap(f, warnIfMissed: false);
        await _pump(t, 900);
      }

      await slip(_label(GoldenLines.zonePhone));
      expect(c.read(gameSaveProvider).mistakes.first.key, GoldenMistakes.callSelf.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      await slip(_label(GoldenLines.zoneChest));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      await slip(_label(GoldenLines.zoneCrowd).at(0));
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['1.7/do/1'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('stopping CPR before help comes is a slip; carrying on still passes', (t) async {
      final seed = _seedWhere((d) => d.comesRound);
      final c = await _open(t, seed);
      await _shoulder(t);
      await _reason(t, GoldenLines.whyRight(GoldenStep.response));
      await _face(t);
      await _reason(t, GoldenLines.whyRight(GoldenStep.breathing));
      await _crowd(t, 0);
      await _reason(t, GoldenLines.whyRight(GoldenStep.call));
      await _cpr(t, count: 3);
      await _pump(t, 3200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, GoldenMistakes.stopped.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _cpr(t, count: 18);
      await _pump(t, 3500);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'help came: the CPR reason');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('his myth at the call: a fast bystander tap does not push him past CPR', (t) async {
      final seed = _seedWhere((d) => d.mythAt == GoldenStep.call && !d.comesRound);
      final deal = dealGolden(math.Random(seed));
      final c = await _open(t, seed);
      await _shoulder(t);
      await _reason(t, GoldenLines.whyRight(GoldenStep.response));
      await _face(t);
      await _pickRight(t, GoldenLines.whyRight(GoldenStep.breathing));
      // The bystander the moment play opens, before he can walk in.
      for (var i = 0; i < 60 && find.text(GoldenLines.askCall).evaluate().isEmpty; i++) {
        await t.tap(_label(GoldenLines.zoneCrowd).at(1), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(GoldenLines.askCall), findsOneWidget);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'too fast for him');
      await _pump(t, 3400);
      await _pickRight(t, GoldenLines.whyRight(GoldenStep.call));
      // At once the chest: play waits for him, he comes before CPR.
      for (var i = 0; i < 40 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.tap(_label(GoldenLines.zoneChest), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(GoldenLines.perMinute), findsNothing, reason: 'CPR has not started');
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pump(t, 3600);
      await _pickRight(t, GoldenLines.coworker(deal.myth).right);
      await _pump(t, 4000);
      await _cpr(t);
      await _pump(t, 3500);
      await _reason(t, GoldenLines.whyRight(GoldenStep.cpr));
      await _reason(t, GoldenLines.whyRight(GoldenStep.keep), after: 1500);
      await _pump(t, 9000);
      expect(find.byType(LevelPassPanel), findsOneWidget, reason: 'no coworker left for the wrap-up');
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.7/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(GoldenLines.caughtCrowd), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a second stop in CPR is only the reminder: no card, no strike', (t) async {
      final seed = _seedWhere((d) => d.comesRound);
      final c = await _open(t, seed);
      await _shoulder(t);
      await _reason(t, GoldenLines.whyRight(GoldenStep.response));
      await _face(t);
      await _reason(t, GoldenLines.whyRight(GoldenStep.breathing));
      await _crowd(t, 0);
      await _reason(t, GoldenLines.whyRight(GoldenStep.call));
      await _cpr(t, count: 3);
      await _pump(t, 3200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _cpr(t, count: 3);
      await _pump(t, 3200);
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'the second stop');
      expect(c.read(guideDirectorProvider).line, GoldenLines.dontStop);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      await _cpr(t, count: 18);
      await _pump(t, 3500);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'help came: the CPR reason');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('listening to him: his myth\'s card with the lesson\'s reason, then the play goes on', (t) async {
      final seed = _seedWhere((d) => d.mythAt == GoldenStep.breathing);
      final deal = dealGolden(math.Random(seed));
      final c = await _open(t, seed);
      await _shoulder(t);
      await _reason(t, GoldenLines.whyRight(GoldenStep.response));
      await _pump(t, 3600);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(GoldenLines.coworker(deal.myth).wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(GoldenMistakes.myth(deal.myth).textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, GoldenMistakes.myth(deal.myth).key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _face(t);
      expect(find.text(GoldenLines.noBreath), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
