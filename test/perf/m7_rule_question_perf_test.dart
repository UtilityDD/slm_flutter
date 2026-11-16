// m7_rule_question (lesson 7.1 কাজ 2 "প্রশ্ন করার অধিকার") at rest: once the
// order is heard, the lane, the phone and the two controls draw nothing while
// the player thinks — with animations and with reduced motion; and again with
// a close-up open, and with the rulebook open after a call.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_rule_question.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.1',
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
    debugPrint('PERF m7_rule_question $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

  // A seed with no coworker on the first order (he would hold the call).
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m7RqDeal(math.Random(s)).coworkerAt != 0);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7RuleQuestionPage(ctx: _ctx, pack: m7RuleQuestionPacks['do_7_1_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, tag);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      expect(M7RuleQuestionProbe.run!.stage, M7RqStage.deciding);
      // A close-up open, then still again.
      final g = M7RqGeo.forScene(800, 0);
      await t.tapAt(g.hit(M7RqKind.pillar).center);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('closeup-close')), findsOneWidget);
      await idle(t, '$tag close-up');
      await t.tap(find.byKey(const ValueKey('closeup-close')));
      await t.pump(const Duration(milliseconds: 300));
      // The call held through: the rulebook open, then still again.
      final hold = await t.startGesture(t.getCenter(label(M7RuleQuestionLines.call)));
      await _pump(t, 1400);
      await hold.up();
      await _pump(t, 600);
      expect(M7RuleQuestionProbe.run!.stage, M7RqStage.paging);
      await idle(t, '$tag rulebook');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
