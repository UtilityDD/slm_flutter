// m8_oil_contain (lesson 8.9 কাজ 2 "এক ফোঁটাও মাটিতে নয়") at rest: once the
// guide has said the task, the yard, the van, the folded sheet, the drum and
// the trainee draw nothing while the player looks — with animations and with
// reduced motion; and again after a sheet corner was dragged and dropped. The
// oil clock redraws only while oil is running, so a waiting yard is still.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_oil_contain.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.9',
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
    debugPrint('PERF m8_oil_contain $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // The seed's first station is the DTR yard (the deal's order is fixed by it).
  int yardSeed() => [for (var s = 0; s < 400; s++) s].firstWhere((s) => m8OilDeal(math.Random(s)).order.first == M8Station.oil);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M8OilContainPage(ctx: _ctx, pack: m8OilContainPacks['do_8_9_b']!, muted: true, seed: yardSeed())),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A sheet corner lifted and dropped on empty ground (no cost) — then still again.
      final run = M8OilContainProbe.run!;
      final d = run.deal;
      final g = M8Geo.forScene(800, 0, flip: d.valveFlip, fx: d.fx, fw: d.fw);
      final from = g.sheetHome[0];
      final gesture = await t.startGesture(from);
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(Offset.lerp(from, from + const Offset(60, 20), i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      expect(run.slips, 0);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a drag');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
