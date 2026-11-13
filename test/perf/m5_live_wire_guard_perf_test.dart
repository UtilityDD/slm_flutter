// m5_live_wire_guard (lesson 5.6 কাজ 2): an idle screen draws (almost) no
// frames — waiting on the opening deck after the guide, and in the demo
// (after its hand's two laps), with and without reduce motion.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_live_wire_guard.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '5.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      // Other agents' test runs rebuild the shared test bundle: without its
      // manifest, images resolve to their plain key (read from disk).
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

  Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

  Future<void> pick(WidgetTester t, List<String> right) async {
    await waitChoiceDeck(t);
    final r = [for (final x in right) if (label(x).evaluate().isNotEmpty) label(x)];
    expect(r, hasLength(1));
    await t.tap(r.single, warnIfMissed: false);
    await tapReasonProceed(t);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly on the deck and in the demo (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final probe = M5LiveWireProbe();
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M5LiveWireGuardPage(ctx: _ctx, pack: m5LiveWirePacks['do_5_6_b']!, muted: true, seed: 4, probe: probe)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await pump(t, 14000);
      final (deckRebuilds, deckFrames) = await measure(t);
      debugPrint('PERF m5_live_wire_guard deck ${reduce ? 'reduce' : 'anim'}: ${deckRebuilds.toStringAsFixed(0)} rebuilds/s, $deckFrames frames idle');
      expect(t.takeException(), isNull);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      expect(deckRebuilds, lessThan(20));
      expect(deckFrames, lessThan(12));

      // The demo waits for the swipe: after its hand's laps, idle again.
      await pick(t, M5LiveWireLines.openRight);
      await pump(t, 2000);
      await pick(t, M5LiveWireLines.why[M5WhyKind.opening]!);
      for (var ms = 0; ms < 10000 && probe.phase != 'demo'; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(probe.phase, 'demo');
      await pump(t, 14000);
      final (demoRebuilds, demoFrames) = await measure(t);
      debugPrint('PERF m5_live_wire_guard demo ${reduce ? 'reduce' : 'anim'}: ${demoRebuilds.toStringAsFixed(0)} rebuilds/s, $demoFrames frames idle');
      expect(demoRebuilds, lessThan(20));
      expect(demoFrames, lessThan(12));

      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
