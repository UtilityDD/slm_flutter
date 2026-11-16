// m6_pillar_thermal (lesson 6.9 কাজ 1 "তাপের চোখ") at rest: once the guide has
// said the task, the lane, the open pillar, the camera's live screen and the
// job card draw nothing while the player thinks — with animations and with
// reduced motion; and again after the camera was dragged onto a column and
// held there (the dwell is a timer, not a frame loop).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_pillar_thermal.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '6.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
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
    debugPrint('PERF m6_pillar_thermal $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A seed whose incomer column is hot (the frame on it brings no coworker).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m6ThermalDeal(math.Random(s)).hotUnit(0));

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6PillarThermalPage(ctx: _ctx, pack: m6PillarThermalPacks['do_6_9_a']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The camera dragged onto the incomer and held there — then still again.
      final run = M6PillarThermalProbe.run!;
      final g = M6ThermalGeo.forScene(800, 0, ways: run.deal.ways, mirror: run.deal.mirror);
      final from = Offset(run.frameX, g.y(0.53));
      final to = Offset(g.unitX(0), g.y(0.53));
      final gesture = await t.startGesture(from);
      for (var i = 1; i <= 12; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / 12)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await _pump(t, 1500);
      expect(run.scanned, contains(0));
      await idle(t, '${reduce ? 'reduce' : 'anim'} after the sweep');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
