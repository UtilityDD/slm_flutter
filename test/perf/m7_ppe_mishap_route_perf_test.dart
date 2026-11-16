// m7_ppe_mishap_route (lesson 7.6 কাজ 2 "ক্ষতি হলে কার কাছে?") at rest: with
// the mishap's item in his hands (the carry), and at the work decision (the
// docket, the pin and the diary), and on a slip card, nothing draws while the
// player reads — with animations and with reduced motion.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_ppe_mishap_route.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '7.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.6',
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

const _k = 392 / 360;
M7PpeGeo get _geo => M7PpeGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

/// Seed 1's first mishap is a damaged item (checked below).
const _seed = 1;

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
    debugPrint('PERF m7_ppe_mishap_route $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      final tag = reduce ? 'reduce' : 'anim';
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7PpeMishapRoutePage(ctx: _ctx, pack: m7PpeMishapRoutePacks['do_7_6_b']!, muted: true, seed: _seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final run = M7PpeMishapRouteProbe.run!;
      expect(run.kind.damaged, isTrue, reason: 'seed $_seed starts with a damaged item');
      for (var i = 0; i < 60 && run.stage != M7PpeStage.route; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // The item in his hands, the player reading — at rest.
      await idle(t, '$tag carry');
      // A slip card (the shop) — at rest.
      Future<void> carry(Rect to) async {
        final g = await t.startGesture(_geo.hand * _k);
        for (var i = 1; i <= 10; i++) {
          await g.moveTo(Offset.lerp(_geo.hand, to.center, i / 10)! * _k);
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await _pump(t, 400);
      }

      await carry(M7PpeGeo.shop);
      expect(find.byType(MistakeCard), findsOneWidget);
      await idle(t, '$tag card');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // The report, its reason, then the work decision — at rest.
      await carry(M7PpeGeo.supervisor);
      await _pump(t, 800);
      await waitChoiceDeck(t);
      final right = find.byWidgetPredicate((w) => w is Semantics && M7PpeMishapRouteLines.whyRight[M7PpeWhy.report]!.contains(w.properties.label ?? '\u0000'));
      await t.tap(right.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1800);
      expect(run.stage, M7PpeStage.decide);
      await idle(t, '$tag decision');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
