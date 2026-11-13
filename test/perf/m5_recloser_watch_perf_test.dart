// Lesson 5.1 কাজ 2 (m5_recloser_watch): the watch plays by itself (dealt
// shots and decoys), so "idle" is the lock-out report waiting for the player's
// count and span — the scene is still and draws no frames (with and without
// reduced motion). Between two watch events nothing moves either.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_recloser_watch.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(rungId: '5.1/do/1', kind: CatalogRungKind.doKind, lessonId: '5.1', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

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

  // A deal with a long gap between its first two events (an idle second in
  // the watch) and a lock-out well inside a minute.
  var seed = 0;
  while (true) {
    final d = m5RecloserDeal(math.Random(seed));
    if (d.events[1].atMs - d.events[0].atMs - d.events[0].ms > 5500 && d.lockAtMs < 45000) break;
    seed++;
  }

  Future<(double, int)> measure(WidgetTester t) async {
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
    testWidgets('m5_recloser_watch waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final p = M5RecloserProbe();
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M5RecloserPage(ctx: _ctx, pack: m5RecloserPacks['do_5_1_b']!, muted: true, seed: seed, probe: p)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      final d = p.deal!;
      for (var ms = 0; ms < 15000 && !p.watching; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(p.watching, isTrue);
      // In the watch, between the first two events (the first has ended).
      final quietFrom = d.events[0].atMs + d.events[0].ms + 600;
      for (var ms = 0; ms < quietFrom; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final (watchRate, watchFrames) = await measure(t);
      debugPrint('PERF m5_recloser_watch watch ${reduce ? 'reduce' : 'anim'}: ${watchRate.toStringAsFixed(0)} rebuilds/s, $watchFrames frames');
      expect(watchFrames, lessThan(12), reason: 'nothing moves between two events');
      // The lock-out report waits for the player.
      for (var ms = 0; ms < 70000 && p.stage != M5RecloserStage.report; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(p.stage, M5RecloserStage.report);
      // The operator's lock-out call (~2.6 s), then the guide's question; then
      // the mascot's breath lap (~14 s after he speaks).
      for (var ms = 0; ms < 18000; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final (perSec, frames) = await measure(t);
      debugPrint('PERF m5_recloser_watch ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
