// m7_street_warn (lesson 7.3 কাজ 2 "পাড়ার পাহারা") at rest: the game clock
// runs only while people walk (that is play, not idle); whenever the play
// waits for the player it stops and the street draws nothing — with the hold
// chip open, and with a mistake card up — with animations and with reduced
// motion.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_street_warn.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '7.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.3',
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
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
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
    debugPrint('PERF m7_street_warn $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> hold(WidgetTester t, M7StreetWarnProbe p, M7WarnTarget target) async {
    final g = await t.startGesture(p.targetGlobal(target)!);
    await t.pump(const Duration(milliseconds: 350));
    await t.pump(const Duration(milliseconds: 350));
    await g.up();
    await t.pump(const Duration(milliseconds: 100));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly on the chip and on a card (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final p = M7StreetWarnProbe();
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: DefaultAssetBundle(
            bundle: _DiskBundle(),
            child: M7StreetWarnPage(ctx: _ctx, pack: m7StreetWarnPacks['do_7_3_b']!, muted: true, seed: 4, probe: p),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await t.pump(const Duration(milliseconds: 200));
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The hold chip on house D: the clock stops; the player thinks.
      await hold(t, p, const M7WarnTarget.place(M7WarnSpot.houseD));
      expect(p.phase, 'chip');
      expect(p.clockRunning, isFalse);
      await idle(t, '${reduce ? 'reduce' : 'anim'} chip');
      // A needless warning: its card waits for the button, the street still.
      await t.tap(find.byKey(const ValueKey('chip-warn')));
      await t.pump(const Duration(milliseconds: 100));
      expect(await confirmChoice(t), isTrue);
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(MistakeCard), findsOneWidget);
      await idle(t, '${reduce ? 'reduce' : 'anim'} card');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
