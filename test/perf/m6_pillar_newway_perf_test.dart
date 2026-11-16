// m6_pillar_newway (lesson 6.9 কাজ 2 "নতুন লাইন জুড়ুন") at rest: once the
// guide has said the task (and the coworker has been refused), the street,
// the pillar, the LT switch box and the stand draw nothing while the player
// thinks — with animations and with reduced motion; and again after the LT
// handle has been dragged OFF (the handle stays where it stopped, still).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_pillar_newway.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '6.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.9',
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
    debugPrint('PERF m6_pillar_newway $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // His (B) push: he comes by his timer; the PPE stand does not wait for him.
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m6NwDeal(math.Random(s)).push == M6NwPush.sfuOnly);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6PillarNewwayPage(ctx: _ctx, pack: m6PillarNewwayPacks['do_6_9_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // He comes by his timer: refuse him first.
      for (var ms = 0; ms < 6000 && find.byType(ChoiceDeck).evaluate().isEmpty; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final right = M6PillarNewwayLines.coworkerSfu.right.where((l) => find.byKey(ValueKey('deal-$l')).evaluate().isNotEmpty).first;
      await pickChoice(t, right, proceed: false);
      await _pump(t, 2600);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The LT handle dragged OFF — then still again.
      final g = M6NwGeo.forScene(800, 0);
      await t.dragFrom(g.ltHandle, const Offset(0, 48));
      await t.pump(const Duration(milliseconds: 300));
      expect(M6PillarNewwayProbe.run!.ltOn, isFalse);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after the LT handle');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
