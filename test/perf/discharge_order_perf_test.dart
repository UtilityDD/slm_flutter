// "আগে মাটি, পরে লাইন" (lesson 1.5, কাজ 2): while the player looks at the
// pole, nothing loops — with and without "remove animations" — and no names
// of the things to tap show on screen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

var _rebuilds = 0;

const _ctx = LevelContext(
  rungId: '1.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: '',
  ladderStep: 15,
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
  setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
  tearDown(() => debugOnRebuildDirtyWidget = null);

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    // Seed 1: the pressure call is not up at the start (it would be its own
    // still card anyway).
    testWidgets('discharge order waits quietly for the first tap ($tag)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: DischargeOrderPage(ctx: _ctx, pack: dischargePack15, muted: true, seed: 1)),
      ));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
      for (var i = 0; i < 100; i++) {
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
      debugPrint('PERF discharge order $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames in an idle second');

      expect(t.takeException(), isNull);
      expect(find.textContaining('ধাপ '), findsOneWidget);
      for (final name in ['আর্থ পয়েন্ট', 'R ফেজ', 'Y ফেজ', 'B ফেজ', 'চেইন']) {
        expect(find.text(name), findsNothing, reason: 'no names on screen: "$name"');
      }
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
