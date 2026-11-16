// m7_scene_guard (lesson 7.7 কাজ 1): an idle screen draws (almost) no frames —
// waiting for the trainee to take his place after the guide, and waiting on
// the first reason deck, with and without reduce motion.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_scene_guard.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
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

  Future<void> pump(WidgetTester t, int ms) async {
    for (var i = 0; i < ms; i += 50) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<(double, int)> measure(WidgetTester t) async {
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
    return (perSec, frames);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly to take his place and on the first reason deck (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final probe = M7SceneGuardProbe();
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M7SceneGuardPage(ctx: _ctx, pack: m7SceneGuardPacks['do_7_7_a']!, muted: true, seed: 4, probe: probe)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await pump(t, 14000);
      final (posRebuilds, posFrames) = await measure(t);
      debugPrint('PERF m7_scene_guard position ${reduce ? 'reduce' : 'anim'}: ${posRebuilds.toStringAsFixed(0)} rebuilds/s, $posFrames frames idle');
      expect(t.takeException(), isNull);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      expect(posRebuilds, lessThan(20));
      expect(posFrames, lessThan(12));

      // Take his place, play the first hand (block evidence, let care), then
      // wait on its reason deck.
      expect(probe.phase, 'position');
      await t.dragFrom(probe.workerGlobal!, probe.dragTo(120)!);
      for (var ms = 0; ms < 20000 && !(probe.phase == 'reach' && probe.run!.active); ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(probe.phase, 'reach');
      final plan = probe.run!.current;
      if (m7KindOf(plan.item) == M7Kind.evidence) {
        await pump(t, 400);
        await t.dragFrom(probe.workerGlobal!, probe.dragTo(probe.run!.geo.laneX(plan.item))!);
      }
      for (var ms = 0; ms < 12000 && !(probe.run!.resolved && find.byType(Scrollable).evaluate().isNotEmpty); ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await pump(t, 14000);
      final (deckRebuilds, deckFrames) = await measure(t);
      debugPrint('PERF m7_scene_guard deck ${reduce ? 'reduce' : 'anim'}: ${deckRebuilds.toStringAsFixed(0)} rebuilds/s, $deckFrames frames idle');
      expect(probe.run!.slips, 0);
      expect(deckRebuilds, lessThan(20));
      expect(deckFrames, lessThan(12));

      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
