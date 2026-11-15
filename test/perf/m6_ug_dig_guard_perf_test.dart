// m6_ug_dig_guard (lesson 6.5 কাজ 2 "খোঁড়ার আগে কেবিলের পথ") at rest: once
// the guide has said the task, the street, the covers and the chalk buttons
// draw nothing while the player thinks — with animations and with reduced
// motion; and again after a cover is lifted, a close look is open and a
// chalk leg is laid (all still).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_ug_dig_guard.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '6.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

/// The level's art is read from disk until the director adds the folder to
/// pubspec's bundle.
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
    debugPrint('PERF m6_ug_dig_guard $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  const seed = 4;
  const k = 392 / 360;

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: DefaultAssetBundle(
            bundle: _DiskBundle(),
            child: M6UgDigGuardPage(ctx: _ctx, pack: m6UgDigGuardPacks['do_6_5_b']!, muted: true, seed: seed),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A cover lifted, the pole top's close look, the first chalk leg: then
      // still again.
      final geo = M6DigGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
      final d = m6DigDeal(math.Random(seed));
      final lay = d.layoutOn(geo);
      await t.dragFrom(lay.covers.first * k, const Offset(0, -60));
      await t.pump(const Duration(milliseconds: 200));
      await t.tapAt(geo.riserTop * k);
      await t.pump(const Duration(milliseconds: 200));
      await t.tapAt(geo.poleFoot * k);
      await t.pump(const Duration(milliseconds: 200));
      await t.tapAt(lay.covers[d.jointRoute.first] * k);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a lift, a look and a leg');
      expect(M6DigProbe.run!.chain, hasLength(2));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
