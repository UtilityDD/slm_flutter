// Kit-check Do level (lesson 1.1, কাজ 1): once the tray is dealt and the coach
// has asked, the screen waits for the player with no loop running, with and
// without "remove animations". Item names never show in the tray.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/kit_check.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

var _rebuilds = 0;

const _ctx = LevelContext(
  rungId: '1.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.1',
  lessonTitleBn: 'প্রথম দিনের ইউনিফর্ম ও পিপিই (PPE)',
  ladderStep: 2,
  doIndex: 1,
  doCount: 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
  ZlFx.setMuted(true);
  setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
  tearDown(() => debugOnRebuildDirtyWidget = null);

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    testWidgets('kit check waits quietly for the first pick ($tag)', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: SlmTheme.night(),
          home: const KitCheckPage(ctx: _ctx, pack: kitCheckPack11, muted: true, seed: 7),
        ),
      ));
      // Intro line, first ask, tray deal.
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      _rebuilds = 0;
      for (var i = 0; i < 125; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final perSec = _rebuilds / 2.0;
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (tester.binding.hasScheduledFrame) frames++;
        await tester.pump(const Duration(milliseconds: 16));
      }
      debugPrint('PERF kit check $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames in an idle second');

      expect(tester.takeException(), isNull);
      expect(find.text('পাঠ 1.1 · কাজ 1/2'), findsOneWidget, reason: 'shell chip from the level context');
      // Same seed as the page: the first deal of this play.
      final torso = dealKit(kitCheckPack11, math.Random(7)).items.where((i) => i.slot == KitSlot.torso).length;
      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard'),
        findsNWidgets(torso),
        reason: 'the tray offers the shirt slot first',
      );
      for (final i in kitCheckPack11.pool) {
        expect(find.text(i.labelBn), findsNothing, reason: 'no names in the tray: "${i.labelBn}"');
        for (final f in i.flaws) {
          expect(find.text(f.labelBn), findsNothing, reason: 'no names in the tray: "${f.labelBn}"');
        }
      }
      expect(perSec, lessThan(20), reason: 'nothing rebuilds every frame while waiting');
      expect(frames, lessThan(12), reason: 'no 60 fps loop while waiting');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.view.reset();
    });
  }
}
