// Lesson 5.5 কাজ 2 (m5_lv_load_test): idle while measuring — and idle with
// the leads on and the needle settled — draws no frames (with and without
// reduced motion).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_lv_load_test.dart';
import 'package:slm_flutter/features/game/m5_lv_load_test_world.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '5.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
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

  Future<void> idle(WidgetTester t, String what) async {
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
    debugPrint('PERF m5_lv_load_test $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      // His call is not the first, so the leads can go on undisturbed.
      final seed = [for (var s = 0; s < 100; s++) s].firstWhere((s) => m5LvLoadDeal(math.Random(s)).cwCall != 0);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M5LvLoadTestPage(ctx: _ctx, pack: m5LvLoadTestPacks['do_5_5_b']!, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await idle(t, '${reduce ? 'reduce' : 'anim'} measuring');
      // Both leads on, the needle settled.
      const k = 392 / 360;
      final g = M5LvLoadGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
      await t.tapAt(g.termAt(M5LvLoadTerm.p) * k);
      await _pump(t, 300);
      await t.tapAt(g.termAt(M5LvLoadTerm.n) * k);
      await idle(t, '${reduce ? 'reduce' : 'anim'} leads on');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
