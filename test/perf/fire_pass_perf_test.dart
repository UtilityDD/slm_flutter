// PASS Do level (lesson 1.8, কাজ 2): while the player reads the wind and the
// three places to stand, nothing loops — with and without "remove
// animations". Gesture hints are off in widget tests (FLUTTER_TEST), so the
// idle wait stays at zero frames.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/fire_pass.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

var _rebuilds = 0;

const _ctx = LevelContext(
  rungId: '1.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.8',
  lessonTitleBn: '',
  ladderStep: 24,
  doIndex: 2,
  doCount: 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }
  ZlFx.setMuted(true);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpokenOnce.resetForTest();
    debugOnRebuildDirtyWidget = (_, _) => _rebuilds++;
  });
  tearDown(() => debugOnRebuildDirtyWidget = null);

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    testWidgets('PASS waits quietly where to stand ($tag)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: FirePassPage(ctx: _ctx, pack: passPack18, muted: true, seed: 4)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // The guide ends its breath lap up to 6 s after a line, then rests.
      for (var i = 0; i < 140; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      _rebuilds = 0;
      for (var i = 0; i < 125; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      final perSec = _rebuilds / 2.0;
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      debugPrint('PERF fire pass $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames in an idle second');

      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('spot-upwind')), findsOneWidget, reason: 'waiting where to stand');
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
