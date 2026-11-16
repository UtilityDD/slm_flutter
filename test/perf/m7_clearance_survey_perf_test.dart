// m7_clearance_survey (lesson 7.3 কাজ 1 "আইনের মাপজোখ") at rest: once the
// guide has said the task, the patrol site, the tape and its case draw
// nothing while the player thinks — with animations and with reduced motion;
// again with one handle on a point; and with the register row up (the drum
// and the stamps still).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_clearance_survey.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _drag(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await t.pump(const Duration(milliseconds: 300));
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
    debugPrint('PERF m7_clearance_survey $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A play whose first site is legal (no coworker, no phone on it).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m7ClrDeal(math.Random(s)).sites.first.legal);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M7ClearanceSurveyPage(ctx: _ctx, pack: m7ClearanceSurveyPacks['do_7_3_a']!, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // One handle on a point — then still again.
      final g = M7ClrGeo.forScene(800, 0);
      final run = M7ClearanceSurveyProbe.run!;
      final site = run.site;
      final pair = site.rightPair.toList();
      await _drag(t, g.park(0), g.at(site.layout.points[pair[0]]!));
      expect(run.handles[0], pair[0]);
      await idle(t, '${reduce ? 'reduce' : 'anim'} one handle down');
      // Both down and written: the register row waits.
      await _drag(t, g.park(1), g.at(site.layout.points[pair[1]]!));
      await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == M7ClearanceSurveyLines.write));
      await t.pump(const Duration(milliseconds: 300));
      expect(run.stage, M7ClrStage.rule);
      await idle(t, '${reduce ? 'reduce' : 'anim'} at the register');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
