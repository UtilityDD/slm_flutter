// Step 23 কোন আগুনে কী: with the gesture hint on (as in the app), the hand
// plays its two laps over the tool stand and then the waiting scene draws
// (almost) nothing again — idle = zero frames (AGENTS.md §1).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/fire_choose.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

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
  tearDown(() {
    debugOnRebuildDirtyWidget = null;
    GestureHints.debugEnableInTests = false;
  });

  for (final reduce in [false, true]) {
    testWidgets('fire choose: the hint plays, then the scene waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      GestureHints.debugEnableInTests = true;
      var seed = 0;
      while (dealFires(math.Random(seed)).pushRound == 0) {
        seed++;
      }
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: FireChoosePage(
            ctx: const LevelContext(
              rungId: '1.8/do/0',
              kind: CatalogRungKind.doKind,
              lessonId: '1.8',
              lessonTitleBn: '',
              ladderStep: 23,
              doIndex: 1,
              doCount: 2,
            ),
            pack: firePack18,
            muted: true,
            seed: seed,
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      // ~8 s idle → the hand; two laps of a sweep over four tools (~7 s); then
      // quiet. (Reduced motion: a still hand, which the kit's controller plays
      // through much faster today — so only "it showed" is checked, not when.)
      var saw = false;
      for (var i = 0; i < 18000; i += 50) {
        await t.pump(const Duration(milliseconds: 50));
        if (hint().showing) saw = true;
        if (i < 7000) expect(hint().showing, isFalse, reason: 'no hand before ~8 s idle');
      }
      expect(saw, isTrue, reason: 'the hand shows when stuck');
      expect(hint().showing, isFalse, reason: 'two laps, then it rests');
      expect(hint().shows, 1);
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
      debugPrint('PERF fire choose (hint on) ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
      expect(t.takeException(), isNull);
      expect(perSec, lessThan(20));
      expect(frames, lessThan(12));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 30));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
