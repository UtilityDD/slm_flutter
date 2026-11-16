// m8_trim_not_fell (lesson 8.9 কাজ "ছাঁটা, কাটা নয়") at rest: once the guide
// has said the task, the lane, the tree, the pruner and the trainee draw
// nothing while the player looks — with animations and with reduced motion;
// again after the pruner head was dragged and dropped in the air; and with the
// owner's deck up.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_trim_not_fell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.9',
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

int _seedWhere(bool Function(M8TrimDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8TrimDeal(math.Random(s))));

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
    debugPrint('PERF m8_trim_not_fell $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> open(WidgetTester t, int seed, bool reduce) async {
    // 360 × 800 dp: the scene's design height is exactly 800.
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
    await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8TrimPage(ctx: _ctx, pack: m8TrimPacks['do_8_9_a']!, muted: true, seed: seed))));
    await t.pump(const Duration(milliseconds: 100));
    await waitIntro(t);
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    t.view.reset();
  }

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    testWidgets('waits quietly with nothing seated, and after a head dropped in the air ($tag)', (t) async {
      final seed = _seedWhere((d) => !m8HasOwner(d.trees.first.kind));
      await open(t, seed, reduce);
      await idle(t, tag);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The head lifted and dropped in the empty sky (no cost): still again.
      final run = M8TrimProbe.run!;
      final g = M8TrimGeo.forScene(800, 0, mirror: run.deal.mirror, poleLen: run.deal.poleLen);
      final gesture = await t.startGesture(g.headHome);
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(Offset.lerp(g.headHome, const Offset(300, 190), i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      expect(run.slips, 0);
      await idle(t, '$tag after a drag');
      await close(t);
    });

    testWidgets('waits quietly with the owner\'s deck up ($tag)', (t) async {
      final seed = _seedWhere((d) => m8HasOwner(d.trees.first.kind));
      await open(t, seed, reduce);
      await idle(t, '$tag owner deck');
      await close(t);
    });
  }
}
