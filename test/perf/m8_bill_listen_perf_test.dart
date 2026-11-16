// m8_bill_listen (lesson 8.1 কাজ "তর্ক নয়, তথ্য দিন") at rest: with animations
// and with reduced motion, (1) while he waits ('শুনছেন?', the pad not held),
// (2) after a slip card is dismissed, and (3) at the open table — the scene, the
// pad, the figures and the table draw nothing while the player looks.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_bill_listen.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.1',
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
    debugPrint('PERF m8_bill_listen $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8BillListenPage(ctx: _ctx, pack: m8BillListenPacks['do_8_1_a']!, muted: true, seed: 4))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      // (1) He talks, nobody holds the pad: he stops and waits.
      await idle(t, '$tag waiting');
      expect(M8BillListenProbe.rant!.waiting, isTrue);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // (2) A press and a release is an interruption: the card, then still again.
      final g = M8BillGeo.forScene(800, 0);
      final press = await t.startGesture(g.padCentre);
      await _pump(t, 600);
      await press.up();
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      await idle(t, '$tag after a slip');
      // (3) Hold to his real end, release, flip or pan: the open table rests.
      final hold = await t.startGesture(g.padCentre);
      for (var i = 0; i < 600 && M8BillListenProbe.phase != 'endHeld'; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(M8BillListenProbe.phase, 'endHeld');
      await hold.up();
      await _pump(t, 300);
      final round = M8BillListenProbe.run!.round;
      if (round.flips) {
        await t.dragFrom(g.billHand.center, const Offset(0, -90));
      } else {
        await t.dragFrom(g.sceneCentre, const Offset(-100, 0));
      }
      for (var i = 0; i < 200 && M8BillListenProbe.phase != 'table'; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(M8BillListenProbe.phase.isEmpty || M8BillListenProbe.phase == 'table' || M8BillListenProbe.phase == 'evidence', isTrue);
      await idle(t, '$tag table');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
