// m8_solar_backfeed (lesson 8.8 কাজ "ছাদে সূর্য, লাইনে বিপদ") at rest: once the
// guide has said the task, the lane, the pole board, the pouch and the ladder
// draw nothing while the player looks — with animations and with reduced
// motion; and again after the camera was panned and a house door marked.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_solar_backfeed.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.8',
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
    debugPrint('PERF m8_solar_backfeed $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 x 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8SolarBackfeedPage(ctx: _ctx, pack: m8SolarBackfeedPacks['do_8_8_a']!, muted: true, seed: 4))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The view panned across the lane and a door marked (a chalk sun): still again.
      final run = M8SolarBackfeedProbe.run!;
      final geo = M8SolarBackfeedProbe.geo!;
      final g = await t.startGesture(const Offset(300, 700));
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset(300 - 20.0 * i, 700));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      expect(M8SolarBackfeedProbe.cam!.value, greaterThan(M8Geo.camStart));
      final h = run.deal.houses.firstWhere((h) => M8Geo.isLeft(h.site) == false, orElse: () => run.deal.houses.first);
      M8SolarBackfeedProbe.cam!.value = M8Geo.isLeft(h.site) ? 0 : 240;
      await t.pump(const Duration(milliseconds: 50));
      await t.tapAt((geo.door(h.site, h.mirror).center - Offset(M8SolarBackfeedProbe.cam!.value, 0)));
      await t.pump(const Duration(milliseconds: 100));
      expect(run.slips, 0);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a pan and a mark');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
