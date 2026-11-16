// m8_voltage_band (lesson 8.4 কাজ 2 "ভোল্টেজ সীমায় রাখো") at rest: once the
// guide has said the task, the panel (window, dial, OLTC, bank switch, log)
// draws nothing while the player thinks — with animations and with reduced
// motion; and again after a hold-step and the bank twisted ON (the needle
// stays where it eased to, still).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_voltage_band.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
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

  Future<void> idle(WidgetTester t, String tag) async {
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
    debugPrint('PERF m8_voltage_band $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A seed whose first round has no coworker on it (he would hold the pen).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m8VbDeal(math.Random(s)).coworkerRound != 0);
  // 360 × 800 dp: the scene's design height is exactly 800.
  const k = 1.0;

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8VoltageBandPage(ctx: _ctx, pack: m8VoltageBandPacks['do_8_4_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      // A hold-step on RAISE (the ring fills, the needle eases), the bank
      // twisted ON — then still again.
      final g = M8VbGeo.forScene(800, 0);
      final hold = await t.startGesture(g.raise.center * k);
      await _pump(t, 1000);
      await hold.up();
      await _pump(t, 800);
      final run = M8VoltageBandProbe.run!;
      expect(run.stepsUsed, 1, reason: 'a hold steps the tap');
      final from = g.cap.center * k;
      final twist = await t.startGesture(from);
      for (var i = 1; i <= 10; i++) {
        await twist.moveTo(from + Offset(7.0 * i, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await twist.up();
      await _pump(t, 800);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after the step');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
