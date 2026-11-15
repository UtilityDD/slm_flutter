// m6_fuse_chain (lesson 6.3 কাজ 2 "কোন প্রহরী পড়ল?") at rest: once the guide
// has said the call, the lane, the transformer, the docket and the house draw
// nothing while the player reads — with animations and with reduced motion;
// and again in the work, with the belt up and the HG close-up on the card.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_fuse_chain.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '6.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.3',
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

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

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
    debugPrint('PERF m6_fuse_chain $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A day whose first call is a house fall and the coworker elsewhere (the
  // verdict is 'ক্রম ঠিক'; the work starts with no visit).
  final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
    final d = m6ChainDeal(math.Random(s));
    return d.calls.first.fallen == M6Tier.house && d.coworkerCall != 0 && !m6WhyAtVerdict(d.calls.first.why);
  });

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6FuseChainPage(ctx: _ctx, pack: m6FuseChainPacks['do_6_3_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The reads and the verdict: the HG close-up up, the belt in — still again.
      const k = 392 / 360;
      final g = M6ChainGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
      await t.tapAt(g.hgHit.center * k);
      await _pump(t, 300);
      await t.tapAt(g.ltBox.center * k);
      await _pump(t, 300);
      await t.tap(_label(M6ChainLines.chainOk));
      await _pump(t, 300);
      await t.tap(_label(M6ChainLines.goLook));
      await _pump(t, 600);
      expect(_label(M6ChainLines.tool(M6Tool.tester)), findsOneWidget);
      await idle(t, '${reduce ? 'reduce' : 'anim'} in the work');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
