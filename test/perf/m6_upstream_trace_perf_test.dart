// m6_upstream_trace (lesson 6.8 কাজ 2 "তার ধরে সোর্সের দিকে") at rest: once
// the guide has said the task, the panorama, the docket and PTT draw nothing
// while the player thinks — with animations and with reduced motion; and
// again after the docket is read and the chalk dragged a span along the wire
// (it stays where it stopped, still).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_upstream_trace.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '6.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.8',
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
    debugPrint('PERF m6_upstream_trace $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A seed with no coworker in the first job (he would come at a tap).
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m6UtDeal(math.Random(s)).coworkerJob != 0);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6UpstreamTracePage(ctx: _ctx, pack: m6UpstreamTracePacks['do_6_8_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The docket read and a span of the wire traced — then still again.
      await t.tapAt(M6UtGeo.docket.center);
      await t.pump(const Duration(milliseconds: 300));
      final run = M6UpstreamTraceProbe.run!;
      final g = M6UpstreamTraceProbe.geo!;
      final cam = M6UpstreamTraceProbe.cam!;
      final path = run.map.upstreamPath();
      final a = g.node(run.map, path[0]);
      final b = g.node(run.map, path[1]);
      Offset screen(Offset w) => w - Offset(cam.value, 0);
      final gesture = await t.startGesture(screen(a));
      for (var i = 1; i <= 16; i++) {
        await gesture.moveTo(screen(M6UtGeo.span(a, b, i / 16)));
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      expect(run.path.length, 2, reason: 'the chalk reached the next pole');
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a span');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
