// Step 30 rank gate (gate_watch): the job plays by itself, so "idle" is a
// stop waiting for the player to tap where the mistake is — the scene is held
// still and draws no frames (with and without reduced motion).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/gate_watch.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(rungId: 'm1/gate', kind: CatalogRungKind.gate, lessonId: '1.10', lessonTitleBn: '', ladderStep: 30);

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

  // A deal whose first mistake is not the coworker's (a plain stop).
  var seed = 1;
  while (true) {
    final d = dealGate(math.Random(seed));
    final first = d.moments.indexWhere((x) => !x.right);
    if (first != d.coworkerAt) break;
    seed++;
  }

  for (final reduce in [false, true]) {
    testWidgets('gate_m1 waits quietly in a stop (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final p = GateWatchProbe();
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: GateWatchPage(ctx: _ctx, pack: gateWatchPacks['gate_m1']!, muted: true, seed: seed, probe: p)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      final first = p.deal!.moments.indexWhere((x) => !x.right);
      for (var ms = 0; ms < 90000 && !(p.index == first && p.phase == 'play'); ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(p.phase, 'play');
      await _pump(t, 300);
      await t.tap(find.byKey(const ValueKey('gate-stop')), warnIfMissed: false);
      await t.pump();
      expect(p.phase, 'spot');
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
      debugPrint('PERF gate_m1 ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
