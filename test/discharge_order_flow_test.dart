// Lesson 1.5, কাজ 2 (আগে মাটি, পরে লাইন) on the shared level kit: the order
// rules and the deadly/slip split, the deal, the drawn scene's geometry, fair
// reason libraries, his recorded voice, and the level in the shell — idle
// perf, the guide first, the hands-on drags, the reasons, the coworker, a
// slip, three slips, the deadly freeze (near-miss, then death) and a clean pass.
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
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/scene_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '1.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: '',
  ladderStep: 15,
  doIndex: 2,
  doCount: 2,
);

Finder _onCard(String text) => find.descendant(of: find.byType(MistakeCard), matching: find.text(text));

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

/// A seed whose deal passes [ok]; [retry] also checks the next play (seed + 1).
int _seedWhere(bool Function(DischargeDeal d) ok, {bool Function(DischargeDeal d)? retry}) {
  for (var s = 0; s < 500; s++) {
    if (ok(dealDischarge(math.Random(s))) && (retry == null || retry(dealDischarge(math.Random(s + 1))))) return s;
  }
  throw StateError('no seed');
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The scene's geometry as built on this screen.
DischargeGeo _geo(WidgetTester t) {
  final r = t.getRect(_label(DischargeLines.sceneLabel));
  return DischargeGeo.forScene(r.height * 360 / r.width, 0);
}

Offset _screen(WidgetTester t, Offset design) {
  final r = t.getRect(_label(DischargeLines.sceneLabel));
  return r.topLeft + design * (r.width / 360);
}

/// Picks up what is at [from] (design px) and lets it go at [to].
Future<void> _drag(WidgetTester t, Offset from, Offset to, [int after = 600]) async {
  final a = _screen(t, from);
  final b = _screen(t, to);
  final g = await t.startGesture(a);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(a, b, i / 10)!);
    await t.pump(const Duration(milliseconds: 30));
  }
  await g.up();
  await _pump(t, after);
}

/// Where the rod's hook is now (design px), read from the gear painter.
Offset _hookNow(WidgetTester t) {
  final w = t.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && '${w.painter.runtimeType}' == '_GearPainter'));
  return (w.painter! as dynamic).hook as Offset;
}

/// Taps the one right card on the deck now up.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = [
    for (final x in right)
      if (find.descendant(of: find.byType(ChoiceDeck), matching: find.text(x)).evaluate().isNotEmpty) x,
  ];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(find.descendant(of: find.byType(ChoiceDeck), matching: find.text(r.single)), warnIfMissed: false);
}

void main() {
  group('rules', () {
    test('deals vary: earth side, the coworker\'s moment and the view', () {
      final deals = [for (var s = 0; s < 60; s++) dealDischarge(math.Random(s))];
      expect(deals.map((d) => d.goodLeft).toSet(), {true, false});
      expect(deals.map((d) => d.callAfter).toSet(), {0, 1, 2});
      expect(deals.every((d) => d.view >= 0 && d.view < 1), isTrue);
      expect(deals.map((d) => (d.view * 10).floor()).toSet().length, greaterThan(5));
    });

    test('earth first, phases in any order, chain; off in reverse, earth last', () {
      final r = OrderRun(dischargeRounds());
      for (final id in [DischargeIds.earth, DischargeIds.y, DischargeIds.b, DischargeIds.r]) {
        expect(r.tap(id).kind, OrderTapKind.ok);
      }
      expect(r.tap(DischargeIds.chain).roundDone, isTrue);
      expect(r.tap(DischargeIds.hookOff).kind, OrderTapKind.ok);
      expect(r.tap(DischargeIds.chainOff).kind, OrderTapKind.ok);
      expect(r.tap(DischargeIds.clampOff).allDone, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
    });

    test('the deadly/slip split is kept', () {
      expect(OrderRun(dischargeRounds()).tap(DischargeIds.r).mistake, DischargeMistakes.lineBeforeEarth);
      expect(OrderRun(dischargeRounds()).tap(DischargeIds.chain).mistake, DischargeMistakes.chainInsteadOfRod);
      final r = OrderRun(dischargeRounds());
      expect(r.tap(DischargeIds.rusty).mistake, DischargeMistakes.rustyEarth);
      r.tap(DischargeIds.earth);
      expect(r.tap(DischargeIds.chain).mistake, DischargeMistakes.chainEarly);
      for (final id in [...DischargeIds.phases, DischargeIds.chain]) {
        r.tap(id);
      }
      expect(r.tap(DischargeIds.clampOff).mistake, DischargeMistakes.earthOffFirst);
      expect(r.slips, 3);
      expect(r.ended, isFalse);
      for (final m in [DischargeMistakes.lineBeforeEarth, DischargeMistakes.chainInsteadOfRod, DischargeMistakes.skipDischarge]) {
        expect(m.deadly, isTrue, reason: m.key);
      }
      for (final m in [DischargeMistakes.rustyEarth, DischargeMistakes.chainEarly, DischargeMistakes.earthOffFirst]) {
        expect(m.deadly, isFalse, reason: m.key);
      }
    });

    test('every mistake: its picture exists, its lesson point is in lesson 1.5 (0-based, 6 points)', () {
      for (final m in DischargeMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 5), reason: m.key);
        expect(RegExp('[০-৯]').hasMatch(m.textBn), isFalse, reason: 'English digits on screen: ${m.key}');
      }
    });

    test('the scene: three wires apart between the poles, the hook finds the one it touches', () {
      for (final h in [560.0, 640.0, 720.0, 800.0, 900.0]) {
        final g = DischargeGeo.forScene(h, 0);
        for (var x = DischargeGeo.poleX + 50; x < DischargeGeo.farX - 20; x += 10) {
          final y = g.wireY(DischargeIds.y, x);
          final r = g.wireY(DischargeIds.r, x);
          final b = g.wireY(DischargeIds.b, x);
          expect(r - y, greaterThan(24), reason: 'h $h x $x');
          expect(b - r, greaterThan(24), reason: 'h $h x $x');
          for (final p in DischargeIds.phases) {
            expect(g.wireNear(Offset(x, g.wireY(p, x) + 4)), p);
          }
        }
        expect(g.wireNear(Offset(200, g.wireY(DischargeIds.b, 200) + 40)), isNull);
        // Wires below the header, the ground above the guide's corner.
        expect(g.wireY(DischargeIds.y, DischargeGeo.poleX), greaterThanOrEqualTo(100));
        expect((g.spikeLeft - g.spikeRight).distance, greaterThan(80));
        expect((g.clampRest - g.spikeRight).distance, greaterThan(40));
      }
    });

    test('reason and choice libraries: same length, big enough, no Bangla digits; his lines are recorded', () {
      final sets = {
        'earth': (DischargeLines.earthRight, DischargeLines.earthWrong),
        'phase': (DischargeLines.phaseRight, DischargeLines.phaseWrong),
        'chain': (DischargeLines.chainRight, DischargeLines.chainWrong),
        'last': (DischargeLines.lastRight, DischargeLines.lastWrong),
        'choice': (DischargeLines.coworker.right, DischargeLines.coworker.wrong),
      };
      for (final MapEntry(key: name, value: (right, wrong)) in sets.entries) {
        expectSameLength(name, [...right, ...wrong]);
        expectLibrary(name, right, wrong);
        for (final l in [...right, ...wrong]) {
          expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        }
      }
      expect(DischargeLines.coworker.asks.length, greaterThanOrEqualTo(2));
      for (final l in DischargeLines.coworker.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
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

    Future<(ProviderContainer, GlobalKey<NavigatorState>)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      await _pump(t, 100);
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => DischargeOrderPage(ctx: _ctx, pack: dischargePack15, muted: true, seed: seed),
      )));
      await _pump(t, 600);
      await waitIntro(t);
      await _pump(t, 400);
      return (c, nav);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        // Seed 1: the coworker's moment is the first move — an idle screen never calls him.
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: DischargeOrderPage(ctx: _ctx, pack: dischargePack15, muted: true, seed: 1)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        await _pump(t, 14000);
        expect(find.byType(CoworkerPeek), findsNothing);
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
        debugPrint('PERF discharge order ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: no start button, a tap does not skip him; tapping him restates the task', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: DischargeOrderPage(ctx: _ctx, pack: dischargePack15, muted: true, seed: 3)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(180, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1500);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(DischargeLines.askOn)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await close(t, c);
    });

    testWidgets('flow: a slip, refuse him, earth → R/Y/B → chain → off in reverse, a reason each time → pass', (t) async {
      final seed = _seedWhere((d) => d.callAfter == 2);
      final deal = dealDischarge(math.Random(seed));
      final (c, _) = await open(t, seed);
      final g = _geo(t);
      final good = g.spike(good: true, goodLeft: deal.goodLeft);
      final bad = g.spike(good: false, goodLeft: deal.goodLeft);
      expect(find.text('আর্থ পয়েন্ট'), findsNothing, reason: 'no names on the scene');

      // A drop on nothing costs nothing.
      await _drag(t, g.clampRest, g.clampRest.translate(-20, -120));
      expect(find.byType(MistakeCard), findsNothing);

      // The rusty spike: a slip with its picture card; the play goes on.
      await _drag(t, g.clampRest, bad, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(_onCard(DischargeMistakes.rustyEarth.textBn), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);

      // The sound spike: ◆ on the table, then "কেন …?".
      await _drag(t, g.clampRest, good, 3000);
      expect(find.text(DischargeLines.earthAsk), findsWidgets);
      await _pickRight(t, DischargeLines.earthRight);
      await _pump(t, 3000);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'the level goes on by itself');

      // The hook to R: a spark. Then he peeps in (his moment: two steps done).
      final hx = g.hands.dx - 60;
      var at = Offset(hx, g.wireY(DischargeIds.r, hx));
      await _drag(t, g.hookRest, at, 4000);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(DischargeLines.coworkerLine), findsOneWidget);
      await _pickRight(t, DischargeLines.coworker.right);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing);

      for (final p in [DischargeIds.b, DischargeIds.y]) {
        final to = Offset(hx + 12, g.wireY(p, hx + 12));
        await _drag(t, at, to, 1200);
        at = to;
      }
      await _pump(t, 2000);
      await _pickRight(t, DischargeLines.phaseRight);
      await _pump(t, 3000);

      // The chain over the wires.
      final throwAt = Offset(270, g.wireY(DischargeIds.r, 270));
      await _drag(t, g.coilRest, throwAt, 3000);
      await _pickRight(t, DischargeLines.chainRight);
      await _pump(t, 4500);

      // Off in reverse: the chain and the hook down, the earth last.
      final x = g.chainSpot(throwAt.dx);
      await _drag(t, g.chainGrab(x), Offset(x, g.groundY - 10), 1200);
      await _drag(t, at, g.hookRest, 1200);
      await _drag(t, good.translate(0, 4), g.clampRest, 3000);
      await _pickRight(t, DischargeLines.lastRight);
      await _pump(t, 9000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.5/do/1'], 'cleared');
      expect(s.deaths, 0);
      expect(s.mistakes.single.key, DischargeMistakes.rustyEarth.key);
      expect(s.starsByRung['1.5/do/1'], 1, reason: 'one slip: one star');
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(DischargeLines.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    // A player who keeps working (the phases flicked ~60 ms apart) still meets
    // him once, whatever his dealt moment: his timer is not restarted by each
    // drop, he may come mid-drag, and the last phase waits for him. Seeds 3
    // and 6 beat his timer, so there the last phase is held until he has come.
    final fastSeeds = {for (final a in [0, 1, 2]) _seedWhere((d) => d.callAfter == a), 3, 6};
    for (final seed in fastSeeds) {
      testWidgets('a fast player still meets him once (seed $seed, his moment: ${dealDischarge(math.Random(seed)).callAfter} steps)', (t) async {
        final deal = dealDischarge(math.Random(seed));
        final (c, _) = await open(t, seed);
        final g = _geo(t);
        var seen = 0;
        var was = false;
        void look() {
          final now = find.byType(CoworkerPeek).evaluate().isNotEmpty;
          if (now && !was) seen++;
          was = now;
        }

        bool hisDeck() => find.byType(ChoiceDeck).evaluate().isNotEmpty && find.text(DischargeLines.coworkerLine).evaluate().isNotEmpty;
        Future<void> wait(int ms) async {
          for (var i = 0; i < ms; i += 50) {
            await t.pump(const Duration(milliseconds: 50));
            look();
          }
        }

        Future<void> answerHim() async {
          if (!hisDeck()) return;
          await _pickRight(t, DischargeLines.coworker.right);
          await wait(2500);
        }

        await _drag(t, g.clampRest, g.spike(good: true, goodLeft: deal.goodLeft), 2500);
        look();
        await _pickRight(t, DischargeLines.earthRight);
        await wait(2500);
        await answerHim();

        final hx = g.hands.dx - 60;
        for (var lap = 0; lap < 4 && find.text(DischargeLines.phaseAsk).evaluate().isEmpty; lap++) {
          for (final (i, p) in DischargeIds.phases.indexed) {
            await answerHim();
            if (find.text(DischargeLines.phaseAsk).evaluate().isNotEmpty) break;
            final x = hx + 10.0 * i;
            // A quick flick (~60 ms a phase).
            final from = _screen(t, _hookNow(t));
            final to = _screen(t, Offset(x, g.wireY(p, x)));
            final f = await t.startGesture(from);
            await f.moveTo(from + (to - from) / (to - from).distance * 24);
            await t.pump(const Duration(milliseconds: 16));
            await f.moveTo(to);
            await t.pump(const Duration(milliseconds: 16));
            await f.up();
            await t.pump(const Duration(milliseconds: 30));
            look();
          }
          await wait(2500);
          await answerHim();
        }
        expect(seen, 1, reason: 'he comes once, even for a fast player');
        expect(find.text(DischargeLines.phaseAsk), findsWidgets, reason: 'the three phases are discharged');
        await _pickRight(t, DischargeLines.phaseRight);
        await wait(3000);
        expect(seen, 1);
        expect(find.byType(CoworkerPeek), findsNothing);
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    }

    testWidgets('first deadly move is a near-miss (freeze, then the card); the next is a death and Do levels fall', (t) async {
      final (c, _) = await open(t, 5);
      final save = c.read(gameSaveProvider.notifier);
      await save.markRungCleared('1.1/learn');
      await save.markRungCleared('1.1/do/0');
      expect(find.textContaining('ধাপ '), findsOneWidget);

      // The hook on Y before the earth: the scene freezes first.
      var g = _geo(t);
      final hx = g.hands.dx - 50;
      await _drag(t, g.hookRest, Offset(hx, g.wireY(DischargeIds.y, hx)), 400);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(_onCard(DischargeMistakes.lineBeforeEarth.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).deaths, 0);
      expect(c.read(gameSaveProvider).nearMissUsed, isTrue);

      // Try again; the chain thrown before the earth: a real death.
      await t.tap(find.text(MistakeLines.tryAgain));
      await _pump(t, 600);
      await waitIntro(t);
      await _pump(t, 800);
      g = _geo(t);
      await _drag(t, g.coilRest, Offset(250, g.wireY(DischargeIds.r, 250)), 3400);
      expect(find.text(MistakeLines.deadlyHead), findsOneWidget);
      expect(_onCard(DischargeMistakes.chainInsteadOfRod.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).deaths, 0, reason: 'recorded on leaving, so the ladder shows the fall');

      await t.tap(find.text(MistakeLines.toLadder));
      await _pump(t, 1200);
      expect(find.byType(DischargeOrderPage), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.deaths, 1);
      expect(s.rungProgress['1.1/do/0'], 'prove');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('listening to him ("5 মিনিট বন্ধ") is the deadly skip: freeze, then its card', (t) async {
      final seed = _seedWhere((d) => d.callAfter == 0);
      final (c, _) = await open(t, seed);
      final g = _geo(t);
      // A first move (dropped on nothing) — his moment.
      await _drag(t, g.coilRest, g.coilRest.translate(-30, -40), 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = [
        for (final x in DischargeLines.coworker.wrong)
          if (find.descendant(of: find.byType(ChoiceDeck), matching: find.text(x)).evaluate().isNotEmpty) x,
      ];
      expect(wrong, hasLength(2));
      await t.tap(find.descendant(of: find.byType(ChoiceDeck), matching: find.text(wrong.first)), warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      expect(_onCard(DischargeMistakes.skipDischarge.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, DischargeMistakes.skipDischarge.key);
      await close(t, c);
    });

    testWidgets('three slips strike the level out; the lesson card insists', (t) async {
      final seed = _seedWhere((d) => d.callAfter == 2);
      final deal = dealDischarge(math.Random(seed));
      final (c, _) = await open(t, seed);
      final g = _geo(t);
      await _drag(t, g.clampRest, g.spike(good: false, goodLeft: deal.goodLeft), 900);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _drag(t, g.clampRest, g.spike(good: true, goodLeft: deal.goodLeft), 3000);
      await _pickRight(t, DischargeLines.earthRight);
      await _pump(t, 3000);
      // The chain before the three phases, twice.
      for (var i = 0; i < 2; i++) {
        await _drag(t, g.coilRest, Offset(250, g.wireY(DischargeIds.r, 250)), 1200);
        if (i == 0) {
          expect(_onCard(DischargeMistakes.chainEarly.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['1.5/do/1'], isNot('cleared'));
      await close(t, c);
    });
  });
}
