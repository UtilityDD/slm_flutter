// m7_ptw_sign (lesson 7.4 কাজ 1 "সইয়ের আগে") at rest: once the guide has
// said the task, the counter, the issuer, the carbon book and the pen draw
// nothing while the player thinks — with animations and with reduced motion;
// and again after the top sheet is peeled up and the pen picked up (the
// sheet stays folded, the pen lifted, still).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_ptw_sign.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

/// The new art is read from disk until the director wires it into pubspec.
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
    debugPrint('PERF m7_ptw_sign $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A seed with no coworker on the first permit (he would hold the pen).
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m7PtwDeal(math.Random(s)).coworkerPermit != 0);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M7PtwSignPage(ctx: _ctx, pack: m7PtwSignPacks['do_7_4_a']!, muted: true, seed: seed)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // Peel the top sheet up, pick up the pen — then still again.
      final g = M7PtwGeo.forScene(800, 0);
      await t.dragFrom(g.corner.center, const Offset(0, -50));
      await t.pump(const Duration(milliseconds: 300));
      await t.tapAt(g.pen.center);
      await t.pump(const Duration(milliseconds: 300));
      expect(M7PtwSignProbe.run!.peeled, isTrue);
      expect(M7PtwSignProbe.run!.penUp, isTrue);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after the peel and the pen');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
