// m8_hearing_balance (lesson 8.1 "জনশুনানির দাঁড়িপাল্লা") at rest: with the file
// in hand and the guide done, the hall, the balance and the figures draw
// nothing while the player thinks; and again in the hearing with hands up and
// the mic idle (the clock runs, but it only redraws when something visible
// changes: a hand rising, a sentence ending, a step of the bar) — with
// animations and with reduced motion.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_hearing_balance.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '8.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.1',
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

  Future<void> idle(WidgetTester t, String tag, {int settle = 14000}) async {
    await _pump(t, settle);
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
    debugPrint('PERF m8_hearing_balance $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // The coworker is dealt on the mic here, so he never turns up in the proposal.
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m8Deal(math.Random(s)).coworkerOn == M8CwOn.mic);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8HearingBalancePage(ctx: _ctx, pack: m8HearingBalancePacks['do_8_1_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // The file in hand, the hall still.
      await idle(t, reduce ? 'reduce file' : 'anim file');
      final run = M8HearingProbe.run!;
      expect(run.phase, M8Phase.proposal);
      // The proposal done by hand, then the hearing with hands up and the mic idle.
      final from = t.getCenter(find.byKey(const ValueKey('file-box')));
      final to = t.getCenter(find.byKey(const ValueKey('bench-target')));
      final g = await t.startGesture(from);
      await g.moveBy(const Offset(0, -24));
      await t.pump(const Duration(milliseconds: 30));
      for (var k = 1; k <= 6; k++) {
        await g.moveTo(Offset.lerp(from + const Offset(0, -24), to, k / 6)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 600);
      expect(run.fileRight, isTrue);
      await waitChoiceDeck(t);
      final right = M8HearingLines.whyRight[M8Why.proposal]!;
      final card = [for (final r in right) find.byWidgetPredicate((w) => w is Semantics && w.properties.label == r)].firstWhere((f) => f.evaluate().isNotEmpty);
      await t.tap(card, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 2500);
      expect(run.phase, M8Phase.hearing);
      for (var k = 0; k < 400 && run.raisedHands.length < 3; k++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(run.raisedHands.length, greaterThanOrEqualTo(3));
      expect(run.clockMs, lessThan(run.deal.foulAtMs - 5000));
      await idle(t, reduce ? 'reduce hearing' : 'anim hearing', settle: 600);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
