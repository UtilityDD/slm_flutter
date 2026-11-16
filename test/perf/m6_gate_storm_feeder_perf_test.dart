// m6_gate_storm_feeder (the Module 6 rank gate "ঝড়ের রাত: ফিডার ফেরান") at
// rest: once the guide has said the call, the panorama, the docket band and
// the belt draw nothing while the player reads — with animations and with
// reduced motion; again after a swipe across the panorama, and with the lens
// open on a device.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_gate_storm_feeder.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: 'm6/gate',
  kind: CatalogRungKind.gate,
  lessonId: '6.11',
  lessonTitleBn: '',
  ladderStep: 180,
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
    debugPrint('PERF m6_gate_storm_feeder $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final p = M6GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6GateStormFeederPage(ctx: _ctx, pack: m6GatePacks['gate_m6']!, muted: true, seed: 5, probe: p))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      expect(p.phase, 'idle');
      await idle(t, reduce ? 'reduce' : 'anim');
      // A swipe across the panorama, then still again.
      await t.drag(find.byKey(const ValueKey('m6g-pano')), const Offset(-400, 0));
      await _pump(t, 200);
      expect(p.pan, greaterThan(100));
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a swipe');
      // The lens open on a device.
      p.panTo(M6GDev.cb);
      await t.pump();
      await t.tap(find.byKey(const ValueKey('m6g-tok-eye')));
      await _pump(t, 200);
      await t.tap(find.byKey(const ValueKey('m6g-dev-cb')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.phase, 'lens');
      await idle(t, '${reduce ? 'reduce' : 'anim'} with the lens open');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
