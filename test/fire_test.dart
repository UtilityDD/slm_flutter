// Lesson 1.8 (মাঠে আগুন): fire-class rules with the gauge, PASS order and
// standing place; both levels in the shell (idle perf; full flows).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/fire_choose.dart';
import 'package:slm_flutter/features/game/fire_pass.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

LevelContext _ctx(int doIndex) => LevelContext(
      rungId: '1.8/do/${doIndex - 1}',
      kind: CatalogRungKind.doKind,
      lessonId: '1.8',
      lessonTitleBn: '',
      ladderStep: 22 + doIndex,
      doIndex: doIndex,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

FireRun _runAt(FireKind k, {int seed = 1}) {
  final d = dealFires(math.Random(seed));
  return FireRun(d)..round = d.fires.indexOf(k);
}

void main() {
  group('fire rules', () {
    test('water on oil or electrical is deadly; on grass it is right', () {
      final oil = _runAt(FireKind.oil);
      expect(oil.pick(FireTool.water), FireMistakes.waterOil);
      final el = _runAt(FireKind.electrical)
        ..phase = FirePhase.tool;
      expect(el.pick(FireTool.water), FireMistakes.waterElectric);
      final grass = _runAt(FireKind.grass);
      expect(grass.pick(FireTool.water), isNull);
      expect(grass.phase, FirePhase.out);
    });

    test('tools by class; electrical asks for power-off first', () {
      expect(FireTool.sand.fits(FireKind.oil), isTrue);
      expect(FireTool.sand.fits(FireKind.electrical), isFalse);
      expect(FireTool.co2.fits(FireKind.grass), isFalse);
      expect(FireTool.dcp.fits(FireKind.grass), isTrue);
      final el = _runAt(FireKind.electrical);
      expect(el.phase, FirePhase.power);
      expect(el.power(off: false), FireMistakes.noPowerOff);
      expect(el.phase, FirePhase.tool);
      expect(el.pick(FireTool.sand), FireMistakes.wrongTool);
    });

    test('the gauge: an empty extinguisher is a slip if used, a catch if put back', () {
      final d = dealFires(math.Random(4));
      final oil = d.fires.indexOf(FireKind.oil);
      final a = FireRun(d)..round = oil;
      a.pick(d.empty);
      expect(a.phase, FirePhase.gauge);
      expect(a.useHeld(use: true), FireMistakes.empty);
      expect(a.spent, contains(d.empty));
      final b = FireRun(d)..round = oil;
      b.pick(d.empty);
      expect(b.useHeld(use: false), isNull);
      expect(b.caught, contains(FireLines.caughtGauge));
      final good = d.empty == FireTool.dcp ? FireTool.co2 : FireTool.dcp;
      b.pick(good);
      expect(b.useHeld(use: true), isNull);
      expect(b.phase, FirePhase.out);
    });
  });

  group('PASS rules', () {
    test('order P-A-S-S; the right place depends on the wind', () {
      final r = OrderRun(passOrderRounds());
      expect(r.tap(PassIds.squeeze).mistake, PassMistakes.order);
      for (final c in passCards) {
        expect(r.tap(c.id).kind, OrderTapKind.ok);
      }
      expect(r.done, isTrue);
      final rounds = dealPass(math.Random(3));
      expect(rounds[0].windFromLeft, isNot(rounds[1].windFromLeft));
      expect(rounds.map((x) => x.kind).toSet().length, 2);
    });
  });

  group('pages', () {
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

    for (final which in ['choose', 'pass']) {
      for (final reduce in [false, true]) {
        testWidgets('$which waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
          t.view.physicalSize = const Size(720, 1600);
          t.view.devicePixelRatio = 2.0;
          t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
          await t.pumpWidget(ProviderScope(
            child: MaterialApp(
              home: which == 'choose'
                  ? FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: 2)
                  : FirePassPage(ctx: _ctx(2), pack: passPack18, muted: true, seed: 2),
            ),
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
          debugPrint('PERF fire $which ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
          expect(t.takeException(), isNull);
          expect(perSec, lessThan(20));
          expect(frames, lessThan(12));
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 15));
          MascotTalk.reset();
          t.platformDispatcher.clearAccessibilityFeaturesTestValue();
          t.view.reset();
        });
      }
    }

    Future<ProviderContainer> open(WidgetTester t, Widget page) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(builder: (_) => page)));
      await _pump(t, 1500);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    testWidgets('choose flow: refuse to wait, power off, read the gauge, right tool each fire → pass', (t) async {
      const seed = 5;
      final d = dealFires(math.Random(seed));
      final c = await open(t, FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: seed));
      Finder tool(FireTool x) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == FireLines.tool(x));
      for (var i = 0; i < 3; i++) {
        if (i == d.pushRound) {
          await t.tap(find.text(FireLines.holdOut));
          await _pump(t, 500);
        }
        final k = d.fires[i];
        if (k == FireKind.electrical) {
          await t.tap(find.text(FireLines.powerOff));
          await _pump(t, 500);
        }
        // Prefer a tool without a gauge where one fits; otherwise the full extinguisher.
        final full = d.empty == FireTool.dcp ? FireTool.co2 : FireTool.dcp;
        final pickTool = switch (k) {
          FireKind.oil => FireTool.sand,
          FireKind.grass => FireTool.water,
          FireKind.electrical => full,
        };
        await t.tap(tool(pickTool), warnIfMissed: false);
        await _pump(t, 500);
        if (pickTool.extinguisher) {
          await t.tap(find.text(FireLines.use));
          await _pump(t, 500);
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'fire $i');
        await t.tap(find.text(i == 2 ? FireLines.finish : FireLines.next));
        await _pump(t, i == 2 ? 3000 : 500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('pass flow: stand upwind, P-A(base)-S-S twice, send for refill → pass', (t) async {
      const seed = 6;
      final c = await open(t, FirePassPage(ctx: _ctx(2), pack: passPack18, muted: true, seed: seed));
      final spots = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'জায়গা');
      Finder card(String title) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == title);
      final base = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'গোড়া');
      for (var i = 0; i < 2; i++) {
        await t.tap(spots.first, warnIfMissed: false); // upwind is the first spot
        await _pump(t, 500);
        for (final s in passCards) {
          await t.ensureVisible(card(s.titleBn));
          await t.tap(card(s.titleBn), warnIfMissed: false);
          await _pump(t, 350);
          if (s.id == PassIds.aim) {
            await t.tap(base, warnIfMissed: false);
            await _pump(t, 350);
          }
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'fire $i');
        await t.ensureVisible(find.text(PassLines.next));
        await t.tap(find.text(PassLines.next));
        await _pump(t, 600);
      }
      await t.tap(find.text(PassLines.holdOut));
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(PassLines.caughtRefill), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
