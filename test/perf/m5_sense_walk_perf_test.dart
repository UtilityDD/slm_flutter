// Lesson 5.2 কাজ 2 (m5_sense_walk): an idle screen draws no frames — at the
// start (stopped on the road), after a walk and a look up at the pole top, and
// stopped at the fallen wire with the rope ready (with and without reduced
// motion). Walking itself runs a ticker only while the strip is held.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_sense_walk.dart';
import 'package:slm_flutter/features/game/m5_sense_walk_world.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '5.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.2',
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

  // The fallen wire lies ahead and the coworker comes on a span, not at it
  // (so the wire stop is a plain wait for the rope).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) {
    final d = senseWalkDeal(math.Random(s));
    return d.wire != SenseWireKind.drop && d.call == SenseCall.lookUp && d.gateX > d.wireAt + 12;
  });

  Future<void> measure(WidgetTester t, String what) async {
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
    debugPrint('PERF m5_sense_walk $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  for (final reduce in [false, true]) {
    testWidgets('m5_sense_walk waits quietly: start, eyes up, at the wire (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: SenseWalkPage(ctx: _ctx, pack: senseWalkPacks['do_5_2_b']!, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await measure(t, 'start ${reduce ? 'reduce' : 'anim'}');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);

      // A short walk, then a look up at the nearest pole top.
      final run = SenseWalkProbe.run!;
      final walk = await t.startGesture(const Offset(314, 808));
      await _pump(t, 1500);
      await walk.up();
      expect(run.pos, greaterThan(kSenseStart + 4));
      await t.dragFrom(const Offset(200, 420), const Offset(0, -140));
      await measure(t, 'eyes up ${reduce ? 'reduce' : 'anim'}');
      await t.dragFrom(const Offset(200, 300), const Offset(0, 140));

      // Stopped 12 m from the fallen wire: the rope waits.
      final stop = run.wireX! - kSenseWireHalf - 12;
      final g = await t.startGesture(const Offset(314, 808));
      for (var i = 0; i < 3000 && run.pos < stop - 0.05; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      expect(run.wireReady, isTrue);
      expect(run.deadly, isNull);
      await measure(t, 'at the wire ${reduce ? 'reduce' : 'anim'}');

      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
