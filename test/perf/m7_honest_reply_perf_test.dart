// m7_honest_reply (lesson 7.9 কাজ 2 "সৎ জবাব") at rest: once the customer has
// said it all and the guide has said the task, the lane, the figures, the
// strip and the tray of six tiles draw nothing while the player thinks — with
// animations and with reduced motion; and again with the strip full and
// 'বলুন' waiting (the figures and the bubble stay still).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_honest_reply.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.9',
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
    debugPrint('PERF m7_honest_reply $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A seed with no coworker on the first customer (he would come at its 'বলুন').
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m7HonestDeal(math.Random(s)).coworkerAt != 0);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7HonestReplyPage(ctx: _ctx, pack: m7HonestReplyPacks['do_7_9_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // His bubbles are over by the end of the idle wait.
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(M7HonestReplyProbe.run!.phase, M7Phase.stopped);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // Two honest tiles on the strip, then still again.
      final run = M7HonestReplyProbe.run!;
      final honest = [for (final x in run.tray) if (x.honest) x];
      for (final (i, tile) in honest.indexed) {
        final from = t.getCenter(find.byKey(ValueKey('tile-${tile.text}')));
        final to = t.getCenter(find.byKey(ValueKey('slot-$i')));
        final g = await t.startGesture(from);
        await g.moveBy(const Offset(0, -24));
        await t.pump(const Duration(milliseconds: 30));
        for (var k = 1; k <= 6; k++) {
          await g.moveTo(Offset.lerp(from + const Offset(0, -24), to, k / 6)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await _pump(t, 300);
      }
      expect(run.stripFull, isTrue);
      await idle(t, '${reduce ? 'reduce' : 'anim'} strip full');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
