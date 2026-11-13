// Lesson 5.7 কাজ 1 "সার্চলাইটের টহল" (m5_searchlight_patrol): the depot waits
// for the player after the guide's intro — the scene is still and draws no
// frames (with and without reduced motion). The stopped van on the patrol is
// checked in test/m5_searchlight_patrol_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_searchlight_patrol.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(rungId: '5.7/do/0', kind: CatalogRungKind.doKind, lessonId: '5.7', lessonTitleBn: '', ladderStep: 0, doIndex: 1, doCount: 2);

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

  for (final reduce in [false, true]) {
    testWidgets('do_5_7_a waits quietly at the depot (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M5SearchlightPage(ctx: _ctx, pack: m5SearchlightPacks['do_5_7_a']!, muted: true, seed: 4)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
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
      debugPrint('PERF m5_searchlight_patrol ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
      expect(t.takeException(), isNull);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
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
