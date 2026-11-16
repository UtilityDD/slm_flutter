// m6_capbank_meter (lesson 6.7 কাজ 2 "মিটারে ব্যাংকের নাড়ি") at rest: once the
// guide has said the task, the yard (sky, banks, the trainee) draws nothing
// while the player thinks — with animations and with reduced motion; and
// again on the panel after two marks and the switch (the needles stay where
// they swung, still).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_capbank_meter.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '6.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.7',
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
    debugPrint('PERF m6_capbank_meter $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

  // A seed whose first bank is a sound one, with no coworker on it (he would
  // hold the lever).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) {
    final d = m6CbmDeal(math.Random(s));
    return d.coworkerBank != 0 && d.banks[0].state == M6CbmState.healthy;
  });

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6CapbankMeterPage(ctx: _ctx, pack: m6CapbankMeterPacks['do_6_7_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      // To the panel, both marks, the lever ON — then still again.
      await t.tap(label(M6CapbankMeterLines.toPanel));
      await t.pump(const Duration(milliseconds: 400));
      final g = M6CbmGeo.forScene(800, 0);
      final run = M6CapbankMeterProbe.run!;
      for (final mt in M6CbmMeter.values) {
        await t.tapAt(Offset(g.stripXOf(mt, run.value(mt)), g.strip(mt).center.dy));
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(run.beforeDone, isTrue);
      await t.tapAt(g.leverHit(0).center);
      await t.pump(const Duration(milliseconds: 300));
      expect(run.on[0], isTrue);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after the switch');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
