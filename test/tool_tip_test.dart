// Lesson 1.2, কাজ 2 (লম্বা টুলের ডগা): tool choice, reach-or-shutdown, the
// tip's rest, deal variety, fair reason libraries, his voice, and the level in
// the shell (idle perf; a full clean flow with the coworker and the reasons).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/distance_spot.dart' show StreetGeo;
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/rod_pick.dart' show RodRating;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/game/tool_tip.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

Offset _kite(KiteRound r) => Offset(250, StreetGeo.y(r.gapM));

const _ctx = LevelContext(
  rungId: '1.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.2',
  lessonTitleBn: '',
  ladderStep: 6,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

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

/// Drags the stick's tip to [to] (design px of the street) and lets go.
Future<void> _dragTipTo(WidgetTester t, Offset to) async {
  final street = t.getRect(_label(ToolTipLines.stickLabel).first);
  final k = street.height / StreetGeo.size.height;
  final start = street.topLeft + const Offset(160, 380) * k;
  final end = street.topLeft + to * k;
  final g = await t.startGesture(start);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(start, end, i / 10)!);
    await t.pump(const Duration(milliseconds: 30));
  }
  await g.up();
}

void main() {
  group('rules', () {
    test('deals: each voltage once, an inside and an outside kite, clear margins', () {
      for (var s = 0; s < 80; s++) {
        final d = dealKites(math.Random(s));
        expect(d.rounds.map((r) => r.line).toSet(), RodRating.values.toSet());
        expect(d.rounds.any((r) => r.inside), isTrue);
        expect(d.rounds.any((r) => !r.inside), isTrue);
        for (final r in d.rounds) {
          expect((r.gapM - r.distanceM).abs(), greaterThan(0.25), reason: 'seed $s');
          expect(r.tools.toSet(), LongTool.values.toSet());
        }
        expect(d.callRound, inInclusiveRange(0, 2));
      }
    });

    test('bamboo and PVC are deadly; the hot stick moves on to the decision', () {
      expect(KiteRun(dealKites(math.Random(1))).pickTool(LongTool.bamboo), ToolTipMistakes.bamboo);
      expect(KiteRun(dealKites(math.Random(1))).pickTool(LongTool.pvc), ToolTipMistakes.pvc);
      final run = KiteRun(dealKites(math.Random(1)));
      expect(run.pickTool(LongTool.hotStick), isNull);
      expect(run.phase, KitePhase.decide);
    });

    test('reach inside = deadly; shutdown outside = slip; the right call each round passes', () {
      final d = dealKites(math.Random(4));
      final inside = d.rounds.indexWhere((r) => r.inside);
      final outside = d.rounds.indexWhere((r) => !r.inside);

      final a = KiteRun(d)..round = inside;
      a.pickTool(LongTool.hotStick);
      expect(a.decide(reach: true), ToolTipMistakes.tipInside);
      expect(a.ended, isTrue);

      final b = KiteRun(d)..round = outside;
      b.pickTool(LongTool.hotStick);
      expect(b.decide(reach: false), ToolTipMistakes.needlessShutdown);
      expect(b.slips, 1);
      expect(b.ended, isFalse);
      expect(b.phase, KitePhase.decide, reason: 'the kite is still to do');
      expect(b.restTip(b.current.distanceM + 0.2), isNull);
      expect(b.decide(reach: true), isNull);

      final c = KiteRun(d);
      for (var i = 0; i < 3; i++) {
        c.pickTool(LongTool.hotStick);
        expect(c.decide(reach: !c.current.inside), isNull);
        c.next();
      }
      expect(c.passed, isTrue);
      expect(c.percent, 100);
    });

    test('the tip resting inside the distance is deadly, outside is not', () {
      final run = KiteRun(dealKites(math.Random(4)))..pickTool(LongTool.hotStick);
      expect(run.restTip(run.current.distanceM + 0.3), isNull);
      expect(run.restTip(run.current.distanceM - 0.1), ToolTipMistakes.tipInside);
      expect(run.ended, isTrue);
    });

    test('reason and choice libraries: same length, big enough; his lines are recorded', () {
      expectSameLength('tool', [...ToolTipLines.toolRight, ...ToolTipLines.toolWrong]);
      expectLibrary('tool', ToolTipLines.toolRight, ToolTipLines.toolWrong);
      expectSameLength('decide', [...ToolTipLines.reachRight, ...ToolTipLines.shutRight, ...ToolTipLines.decideWrong]);
      expectLibrary('reach', ToolTipLines.reachRight, ToolTipLines.decideWrong);
      expectLibrary('shut', ToolTipLines.shutRight, ToolTipLines.decideWrong);
      const c = ToolTipLines.coworker;
      expectSameLength('choice', [...c.right, ...c.wrong]);
      expectLibrary('choice', c.right, c.wrong);
      for (final l in c.recordedLines) {
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: ToolTipPage(ctx: _ctx, pack: toolTipPack12, muted: true, seed: 3)),
        ));
        await t.pump(const Duration(milliseconds: 100));
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
        debugPrint('PERF tool tip ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('flow: refuse the helper, hot stick each time, right call each kite → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 5;
      final deal = dealKites(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => ToolTipPage(ctx: _ctx, pack: toolTipPack12, muted: true, seed: seed),
      )));
      await _pump(t, 2000);
      await _skipIntro(t);
      await _pump(t, 300);
      final tools = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'টুল');
      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        if (i == deal.callRound) {
          // He peeps in; the guide asks; refuse him.
          await _pump(t, 3500);
          expect(find.byType(CoworkerPeek), findsOneWidget);
          await _pickRight(t, ToolTipLines.coworker.right);
          await _pump(t, 2500);
        }
        await t.tap(tools.at(r.tools.indexOf(LongTool.hotStick)), warnIfMissed: false);
        await _pump(t, i == 0 ? 3500 : 800);
        if (i == 0) {
          await _pickRight(t, ToolTipLines.toolRight);
          await _pump(t, 3000);
        }
        if (r.inside) {
          await t.tap(find.text(ToolTipLines.shutdown));
        } else {
          await _dragTipTo(t, _kite(r));
        }
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, r.inside ? ToolTipLines.shutRight : ToolTipLines.reachRight);
        await _pump(t, i == 2 ? 6000 : 3500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(ToolTipLines.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
