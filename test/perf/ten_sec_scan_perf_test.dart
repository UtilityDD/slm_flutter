// Ten-sec-scan Do level (lesson 1.10, কাজ 1): while the player examines the
// card and decides, nothing loops — with and without "remove animations" —
// and the idle screen draws zero frames.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/ten_sec_scan.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

var _rebuilds = 0;

const _ctx = LevelContext(
  rungId: '1.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.10',
  lessonTitleBn: '১০ সেকেন্ডের মেন্টাল চেকলিস্ট',
  ladderStep: 29,
  doIndex: 0,
  doCount: 1,
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
    testWidgets('ten-sec scan waits quietly for decision ($tag)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      SharedPreferences.setMockInitialValues({});

      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TenSecScanPage(
              ctx: _ctx,
              pack: tenSecPacks['do_1_10_a']!,
              muted: true,
              seed: 42,
            ),
          ),
        ),
      );

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
      debugPrint('PERF ten-sec scan $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames in an idle second');

      expect(t.takeException(), isNull);
      expect(find.text(TenSecLines.stopBtn), findsOneWidget);
      expect(find.text(TenSecLines.goBtn), findsOneWidget);
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
