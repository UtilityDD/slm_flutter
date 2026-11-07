// Lesson 1.4, কাজ 2 (ফিটিং আর অ্যাঙ্কর): fit spotting, anchor choice, the
// senior's push, deal variety, and the level in the shell.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/harness_fit.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _ctx = LevelContext(
  rungId: '1.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.4',
  lessonTitleBn: '',
  ladderStep: 12,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('rules', () {
    test('deals: one clean fit, the D-ring fault at least once, the sling always offered', () {
      for (var s = 0; s < 60; s++) {
        final d = dealClimbs(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds.where((r) => r.faults.isEmpty).length, 1);
        expect(d.rounds.where((r) => r.faults.contains(FitFault.dRingLow)).length, 1);
        for (final r in d.rounds) {
          expect(r.anchors.first, AnchorPoint.sling);
          expect(r.anchors.length, inInclusiveRange(3, 4));
          expect(r.anchors.toSet().length, r.anchors.length);
        }
      }
    });

    test('fit: exact marks are clean; a missed fault and a false mark are slips', () {
      final d = dealClimbs(math.Random(4));
      final faulty = d.rounds.indexWhere((r) => r.faults.isNotEmpty);
      final a = ClimbRun(d)..round = faulty;
      final exact = {for (final f in a.current.faults) f.zone};
      final c = a.checkFit(exact);
      expect(c.missed, isEmpty);
      expect(c.falseMarks, isEmpty);
      expect(a.slips, 0);

      final b = ClimbRun(d)..round = faulty;
      final miss = b.checkFit({});
      expect(miss.missed.length, b.current.faults.length);
      expect(b.slips, b.current.faults.length);

      final clean = d.rounds.indexWhere((r) => r.faults.isEmpty);
      final e = ClimbRun(d)..round = clean;
      expect(e.checkFit({FitZone.chest}).falseMarks, [FitZone.chest]);
    });

    test('anchor: the sling is right; every weak point is deadly; giving in is deadly', () {
      final d = dealClimbs(math.Random(4));
      for (final a in AnchorPoint.values.skip(1)) {
        final run = ClimbRun(d)
          ..checkFit({for (final f in d.rounds[0].faults) f.zone})
          ..toAnchor();
        final m = run.tieOff(a);
        expect(m, FitMistakes.anchor(a));
        expect(m!.deadly, isTrue);
      }
      final ok = ClimbRun(d)
        ..checkFit({for (final f in d.rounds[0].faults) f.zone})
        ..toAnchor();
      expect(ok.tieOff(AnchorPoint.sling), isNull);
      expect(ok.phase, ClimbPhase.anchored);
      expect(ClimbRun(d).noTieOff().deadly, isTrue);
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
          child: MaterialApp(home: HarnessFitPage(ctx: _ctx, pack: fitPack14, muted: true, seed: 2)),
        ));
        await _pump(t, 6000);
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
        debugPrint('PERF fit ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.text('পাঠ 1.4 · কাজ 2/2'), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('flow: mark the faults (turning round for the D-ring), refuse the push, tie to the sling → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 5;
      final deal = dealClimbs(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => HarnessFitPage(ctx: _ctx, pack: fitPack14, muted: true, seed: seed),
      )));
      await _pump(t, 2000);
      final straps = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'ফিতে');
      final anchors = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'অ্যাঙ্কর');
      const frontOrder = [FitZone.shoulder, FitZone.chest, FitZone.leg];

      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        for (final f in r.faults.where((f) => f != FitFault.dRingLow)) {
          await t.tap(straps.at(frontOrder.indexOf(f.zone)), warnIfMissed: false);
          await _pump(t, 150);
        }
        if (r.faults.contains(FitFault.dRingLow)) {
          await t.tap(find.text(FitLines.turn));
          await _pump(t, 500);
          await t.tap(straps.first, warnIfMissed: false);
          await _pump(t, 150);
        }
        await t.tap(find.text(FitLines.check));
        await _pump(t, 1200);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i fit');
        await t.tap(find.text(FitLines.toAnchor));
        await _pump(t, 600);
        if (find.text(FitLines.holdOut).evaluate().isNotEmpty) {
          await t.tap(find.text(FitLines.holdOut));
          await _pump(t, 500);
        }
        await t.tap(anchors.first, warnIfMissed: false);
        await _pump(t, 900);
        await t.tap(find.text(i == 2 ? FitLines.finish : FitLines.next));
        await _pump(t, i == 2 ? 3000 : 600);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.4/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(FitLines.caughtCall), findsOneWidget);
      expect(find.text(FitLines.caughtBack), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
