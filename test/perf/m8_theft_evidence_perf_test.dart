// m8_theft_evidence (lesson 8.2 "আগে প্রমাণ, পরে কাটা") at rest: once the
// guide has said the task, the lane draws nothing while the player thinks —
// with animations and with reduced motion; again at a premises (the three
// tiles), with the phone up (REC), while recording with a trace on screen,
// and with clip thumbnails showing.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_theft_evidence.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.2',
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
    debugPrint('PERF m8_theft_evidence $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A play whose coworker comes at the shop: nothing comes at the first premises.
  final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
    final d = m8TheftDeal(math.Random(s));
    return d.push == M8Push.tray && !d.access;
  });

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8TheftEvidencePage(ctx: _ctx, pack: m8TheftPacks['do_8_2_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, '$tag lane');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // At the first stealing premises: the three tiles.
      final probe = M8TheftProbe.current!;
      final d = probe.deal;
      probe.tapPremises(d.firstHooking);
      await _pump(t, 1500);
      expect(probe.inLane, isFalse);
      await idle(t, '$tag tiles');
      // The phone up: REC.
      probe.phone();
      await _pump(t, 300);
      expect(probe.phoneOpen, isTrue);
      await idle(t, '$tag phone');
      // Recording, a trace on the scene.
      probe.startRec();
      probe.drag(M8Geo.hookWire(d.looks[d.firstHooking]).take(12).toList());
      await _pump(t, 300);
      expect(probe.trace, isNotEmpty);
      await idle(t, '$tag recording');
      // Stopped: a clip thumbnail on screen.
      probe.stopRec();
      await _pump(t, 400);
      expect(probe.run.clips[d.firstHooking], hasLength(1));
      await idle(t, '$tag thumbnail');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
