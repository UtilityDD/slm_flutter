// m8_day_dial (lesson 8.7 কাজ "দিনভর নজর") at rest: once the guide has said
// the task, the sky, the premises, the sun, the book and the trainee draw
// nothing while the player looks — with animations and with reduced motion;
// again after the sun was dragged through the day (the stamps now open), and
// again after a stamp was lifted and dropped off the line.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_day_dial.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.7',
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
    debugPrint('PERF m8_day_dial $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      // A seed whose first stop is not his (the coworker would take the stage).
      var seed = 0;
      while (true) {
        final d = m8DayDeal(math.Random(seed));
        if (!d.stops[0].factory && d.coworkerStop != 0) break;
        seed++;
      }
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8DayDialPage(ctx: _ctx, pack: m8DayDialPacks['do_8_7_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, tag);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The sun dragged dawn to midnight (the stamps open), then still again.
      final g = M8DayGeo.forScene(800, 0);
      final gesture = await t.startGesture(g.sunAt(0));
      for (var i = 1; i <= 24; i++) {
        await gesture.moveTo(g.sunAt(i / 24));
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      expect(M8DayDialProbe.run!.stage, M8DayStage.stamp);
      expect(M8DayDialProbe.run!.slips, 0);
      await idle(t, '$tag after the day');
      // A stamp lifted and dropped on empty sky (no cost) — then still again.
      final from = g.stamp(1).center;
      final st = await t.startGesture(from);
      for (var i = 1; i <= 10; i++) {
        await st.moveTo(Offset.lerp(from, const Offset(300, 190), i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await st.up();
      expect(M8DayDialProbe.run!.slips, 0);
      await idle(t, '$tag after a stamp');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
