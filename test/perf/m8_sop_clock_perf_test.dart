// m8_sop_clock (lesson 8.3 কাজ 1 "ঘড়ি টিক-টিক") at rest: once the guide has
// said the task, the map, its pins and the toolbar draw nothing while the
// player thinks — with animations and with reduced motion; again with a docket
// card open, in a close-up, and with the phone open (the game clock moves only
// with the player's moves).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_sop_clock.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 0,
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
    debugPrint('PERF m8_sop_clock $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A play whose rural myth coworker is not the one on the map (so the
  // timers he keeps are the quiet ones) and that has the docket push.
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m8SopDeal(math.Random(s)).push == M8SopPush.docket);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8SopClockPage(ctx: _ctx, pack: m8SopClockPacks['do_8_3_a']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, tag);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      final g = M8SopGeo.forScene(800, 0);
      final run = M8SopClockProbe.run!;
      // A docket card open.
      await t.tapAt(g.pinHit(run.deal.pins[1].unit).center);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('docket-card-1')), findsOneWidget);
      await idle(t, '$tag with a docket');
      await t.tap(find.byKey(const ValueKey('docket-close')));
      await t.pump(const Duration(milliseconds: 300));
      // The phone open.
      await t.tapAt(g.phoneBtn.center);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('phone-sheet')), findsOneWidget);
      await idle(t, '$tag with the phone');
      await t.tap(find.byKey(const ValueKey('phone-close')));
      await t.pump(const Duration(milliseconds: 300));
      // The van to a pin: its close-up, then still again.
      final g2 = await t.startGesture(g.mapAt(run.van));
      for (var i = 1; i <= 10; i++) {
        await g2.moveTo(Offset.lerp(g.mapAt(run.van), g.pinHit(run.deal.pins[1].unit).center, i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await g2.up();
      await _pump(t, 1500);
      expect(M8SopClockProbe.closeup, isTrue);
      await idle(t, '$tag in a close-up');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
