// Lesson 5.4 কাজ 2 (m5_reblow_clock): the level waits for the player to read
// today's logbook page — the scene is still and draws no frames (with and
// without reduced motion); and while the line holds after a re-fit (the clock
// is the only control) it stays still too.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_reblow_clock.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(rungId: '5.4/do/1', kind: CatalogRungKind.doKind, lessonId: '5.4', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

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

  Future<void> measure(WidgetTester t, String what) async {
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
    debugPrint('PERF m5_reblow_clock $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    t.view.reset();
  }

  for (final reduce in [false, true]) {
    testWidgets('m5_reblow_clock waits quietly on the page (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5ReblowPage(ctx: _ctx, pack: m5ReblowPacks['do_5_4_b']!, muted: true, seed: 4))));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await measure(t, reduce ? 'reduce' : 'anim');
      await close(t);
    });
  }

  testWidgets('m5_reblow_clock waits quietly while the line holds', (t) async {
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) {
      final c = m5ReblowDeal(math.Random(s)).cases.first;
      return c.page == M5ReblowLog.fresh && c.kind == M5ReblowKind.transient;
    });
    await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5ReblowPage(ctx: _ctx, pack: m5ReblowPacks['do_5_4_b']!, muted: true, seed: seed))));
    await t.pump(const Duration(milliseconds: 100));
    await waitIntro(t);
    await _pump(t, 1200);
    await t.tap(find.byKey(const ValueKey('reblow-check')));
    await _pump(t, 1500);
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('reblow-do'))));
    await _pump(t, 1200);
    await g.up();
    await _pump(t, 400);
    expect(find.byKey(const ValueKey('reblow-do')), findsNothing, reason: 'the line holds; the clock waits');
    await measure(t, 'holding');
    await close(t);
  });
}
