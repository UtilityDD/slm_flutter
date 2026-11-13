// Lesson 5.1 কাজ 1 "কন্ট্রোল রুমের ফোন" (m5_trip_call): an idle screen draws
// zero frames — while the phone waits to be picked up and while the operator
// waits for the next question — with and without reduce motion.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_trip_call.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '5.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.1',
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

  Future<(double, int)> measure(WidgetTester t) async {
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
    return (perSec, frames);
  }

  for (final reduce in [false, true]) {
    testWidgets('m5_trip_call waits quietly: ringing, then on the call (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M5TripCallPage(ctx: _ctx, pack: m5TripCallPacks['do_5_1_a']!, muted: true, seed: 4)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final (ringPerSec, ringFrames) = await measure(t);
      debugPrint('PERF m5_trip_call ring ${reduce ? 'reduce' : 'anim'}: ${ringPerSec.toStringAsFixed(0)} rebuilds/s, $ringFrames frames idle');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      expect(ringPerSec, lessThan(20));
      expect(ringFrames, lessThan(12));
      // Pick up (drag the handset up) and wait on the call.
      final g = M5TripGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0));
      const k = 392 / 360;
      await t.dragFrom(g.handsetRest.center * k, const Offset(0, -70));
      await _pump(t, 400);
      expect(find.text(M5TripLines.tile[M5TripTopic.how]!), findsOneWidget);
      final (talkPerSec, talkFrames) = await measure(t);
      debugPrint('PERF m5_trip_call talk ${reduce ? 'reduce' : 'anim'}: ${talkPerSec.toStringAsFixed(0)} rebuilds/s, $talkFrames frames idle');
      expect(t.takeException(), isNull);
      expect(talkPerSec, lessThan(20));
      expect(talkFrames, lessThan(12));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
