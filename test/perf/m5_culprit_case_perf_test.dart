// Lesson 5.3 কাজ 1 "অপরাধী কে? সূত্রের সুতো" (m5_culprit_case): an idle
// screen draws (almost) no frames and rebuilds little — on the scene, in the
// raised phone and on the case board, with and without reduce motion.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_culprit_case.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '5.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.3',
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
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

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

  Future<void> idle(WidgetTester t, String what) async {
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
    debugPrint('PERF m5_culprit_case $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly: the scene, the phone, the board (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final probe = M5CulpritProbe();
      // A play whose first spot is not the bird spot (no coworker on the board).
      final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m5CulpritDeal(math.Random(s)).birdIndex != 0);
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M5CulpritCasePage(ctx: _ctx, pack: m5CulpritPacks['do_5_3_a']!, muted: true, seed: seed, probe: probe)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await idle(t, 'scene ${reduce ? 'reduce' : 'anim'}');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The phone, zoomed in, one sharp shot of a clue.
      await t.tap(_label(M5CulpritLines.phone));
      await _pump(t, 300);
      for (var k = 0; k < 3; k++) {
        await t.tap(_label(M5CulpritLines.zoomIn));
        await _pump(t, 150);
      }
      final i = probe.run!.spot.real.indexOf(true);
      final d = probe.aim - probe.itemDesign(i)!;
      await t.dragFrom(const Offset(196, 330), d * probe.zoom * (392 / 360));
      await _pump(t, 200);
      await t.tap(_label(M5CulpritLines.shutter));
      await idle(t, 'phone ${reduce ? 'reduce' : 'anim'}');
      expect(probe.run!.pins, isNotEmpty);
      // The case board.
      await t.tap(_label(M5CulpritLines.lower));
      await _pump(t, 300);
      await t.tap(_label(M5CulpritLines.board));
      await _pump(t, 500);
      expect(probe.phase, 'board');
      await idle(t, 'board ${reduce ? 'reduce' : 'anim'}');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
