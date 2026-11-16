// m7_doorstep_visit (lesson 7.9 কাজ 1 "দরজা থেকে মিটার বক্স") at rest: once the
// guide has said the task, the lane, the van with its docket and the
// colleague draw nothing while the player thinks — with animations and with
// reduced motion; and again at the gate (the tray up, the customer at the
// door), and inside (the cutaway with its conduit, waiting for a room drag).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_doorstep_visit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.9',
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
    debugPrint('PERF m7_doorstep_visit $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> drag(WidgetTester t, Offset from, Offset to) async {
    const k = 1.0;
    final g = await t.startGesture(from * k);
    for (var i = 1; i <= 8; i++) {
      await g.moveTo(Offset.lerp(from, to, i / 8)! * k);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await _pump(t, 500);
  }

  // A first visit where someone answers, goes in, and no coworker is dealt on
  // it (he would hold the first act).
  final seed = [for (var s = 0; s < 4000; s++) s].firstWhere((s) {
    final d = m7DvDeal(math.Random(s));
    return d.cwVisit != 0 && d.visits[0].entryRight && !d.visits[0].woman;
  });

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M7DoorstepVisitPage(ctx: _ctx, pack: m7DoorstepVisitPacks['do_7_9_a']!, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, tag);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      final g = M7DvGeo.forScene(800, 0);
      final run = M7DoorstepVisitProbe.run!;
      // At the gate: the tray up, the customer at the door.
      await drag(t, g.traineeStart.center, g.gateFront.center);
      expect(run.phase, M7DvPhase.door);
      await idle(t, '$tag at the gate');
      // Show the ID, then go in: the cutaway waits for a room drag.
      final idAt = run.visit.trayOrder.indexOf(M7DvItem.id);
      await drag(t, g.trayItem(idAt).center, g.cust.center);
      expect(run.idShown, isTrue);
      // A reason may be open (the ID reason): let the deck stand, then pick nothing.
      if (find.byKey(const ValueKey('why-deck')).evaluate().isEmpty) {
        await drag(t, g.traineeGate.center, g.gate.center);
        expect(run.phase, anyOf(M7DvPhase.inside, M7DvPhase.work));
        await idle(t, '$tag inside');
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
