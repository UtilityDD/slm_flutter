// m8_net_bill (lesson 8.8 কাজ "নেট মিটারের হিসাব") at rest: once the guide has
// said the task, the house, the meter, the clipboard and the trainee draw
// nothing while the player looks — with animations and with reduced motion; and
// again after the meter's button was pressed, a digit rolled and the slip
// dropped back on empty ground.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_net_bill.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.8',
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
    debugPrint('PERF m8_net_bill $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8NetBillPage(ctx: _ctx, pack: m8NetBillPacks['do_8_8_b']!, muted: true, seed: 4))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      final g = M8Geo.forScene(800, 0);
      // The meter's button pressed: one page on the glass — then still again.
      await t.tapAt(g.push.center);
      await t.pump(const Duration(milliseconds: 100));
      expect(M8NetBillProbe.run!.presses, 1);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a press');
      // A digit rolled up one step — then still again.
      final d = await t.startGesture(g.dig(2).center);
      for (var i = 1; i <= 8; i++) {
        await d.moveTo(g.dig(2).center - Offset(0, 3.5 * i));
        await t.pump(const Duration(milliseconds: 16));
      }
      await d.up();
      expect(M8NetBillProbe.run!.slip.units, greaterThan(0));
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a digit');
      // The slip carried off and dropped on empty sky (no cost) — then still again.
      final s = await t.startGesture(g.handle.center);
      for (var i = 1; i <= 10; i++) {
        await s.moveTo(Offset.lerp(g.handle.center, const Offset(200, 176), i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await s.up();
      expect(M8NetBillProbe.run!.slips, 0);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a drag');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
