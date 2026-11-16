// m7_theft_trace (lesson 7.5 কাজ 1 "তারের পিছু পিছু") at rest: once the guide
// has said the task, the lane draws nothing while the player thinks — with
// animations and with reduced motion; and again after a wire is traced half
// way (the chalk stays where it stopped, still) and after the notebook opens
// at a wire's end.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_theft_trace.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.5',
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
    debugPrint('PERF m7_theft_trace $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> drag(WidgetTester t, List<Offset> pts) async {
    final g = await t.startGesture(pts.first);
    for (final p in pts.skip(1)) {
      await g.moveTo(p);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pump(const Duration(milliseconds: 300));
  }

  // The coworker comes at the send (never during this test's lane).
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m7TtDeal(math.Random(s)).coworkerAtSend);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design px are the screen's.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7TheftTracePage(ctx: _ctx, pack: m7TheftTracePacks['do_7_5_a']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A wire traced half way — then still again.
      final run = M7TheftTraceProbe.run!;
      final g = M7TheftTraceProbe.geo!;
      final w = run.lane.wires.first;
      final pts = run.pathOf(w.id, g);
      await drag(t, pts.sublist(0, pts.length ~/ 2));
      expect(run.s, greaterThan(0), reason: 'the chalk moved');
      expect(run.traced, isFalse);
      await idle(t, '${reduce ? 'reduce' : 'anim'} half a wire');
      // On to its end: the notebook opens — then still again.
      await drag(t, pts.sublist(pts.length ~/ 2 - 1));
      expect(run.traced, isTrue, reason: 'the notebook is up');
      await idle(t, '${reduce ? 'reduce' : 'anim'} notebook');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
