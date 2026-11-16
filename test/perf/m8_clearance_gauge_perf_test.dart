// m8_clearance_gauge (lesson 8.5 কাজ 1 "ঝুলে পড়া তার — মেপে দেখুন") at rest:
// with the probes down and the stamps waiting, and again under a slip card,
// nothing draws while the player reads (the traffic stops after a few seconds)
// — with animations and with reduced motion.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_clearance_gauge.dart';
import 'package:slm_flutter/features/game/m8_clearance_gauge_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.5',
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

  // No coworker on span 1 (he would come on his own timer and move the scene).
  final seed = [for (var s = 0; s < 4000; s++) s].firstWhere((s) => m8GaugeDeal(math.Random(s)).coworkerSpan != 0);

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
    debugPrint('PERF m8_clearance_gauge $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> tapAt(WidgetTester t, double at) async {
    final geo = M8GaugeGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
    await t.tapAt(Offset(geo.x(at), M8GaugeGeo.top + 90) * (392 / 360));
    await _pump(t, 250);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8ClearanceGaugePage(ctx: _ctx, pack: m8ClearanceGaugePacks['do_8_5_a']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // Probes down, the stamps waiting — at rest.
      for (final p in [0.125, 0.375, 0.625]) {
        await tapAt(t, p);
      }
      expect(M8ClearanceGaugeProbe.run!.probes, hasLength(3));
      await idle(t, '${reduce ? 'reduce' : 'anim'} stamps');
      // A wrong stamp: the worst point revealed and the slip card — at rest.
      final span = M8ClearanceGaugeProbe.run!.span;
      final g = await t.startGesture(t.getCenter(find.byKey(ValueKey('gauge-stamp-${span.breach ? 'ok' : 'breach'}'))));
      await _pump(t, 950);
      await g.up();
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      await idle(t, '${reduce ? 'reduce' : 'anim'} card');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
