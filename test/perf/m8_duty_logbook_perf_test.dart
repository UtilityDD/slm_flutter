// m8_duty_logbook (lesson 8.10 কাজ 1 "ডিউটির খাতা") at rest: once the guide
// has said the task, the lane, the dash clock, the phone, the van and the
// tray draw nothing while the player thinks — with animations and with
// reduced motion — also after the phone has lit (it lights once, then rests),
// and again after the clock has been stamped into the logbook.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_duty_logbook.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

/// The new art is read from disk until the director wires it into pubspec.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      // Another agent's flutter run can rebuild the shared test asset folder
      // under us: an empty manifest and the repo's own files keep this test alone.
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<Object?, Object?>{})!;
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
    debugPrint('PERF m8_duty_logbook $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M8DutyLogbookPage(ctx: _ctx, pack: m8DutyLogbookPacks['do_8_10_a']!, muted: true, seed: 5)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // 14 s of rest: the phone lights once on the way (7-10 s), then rests.
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(M8DutyLogbookProbe.run!.phoneLit, isTrue);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The clock stamped into the logbook — then still again.
      final g = M8Geo.forScene(800, 0);
      await t.dragFrom(g.clock.center, g.trayCol(M8Col.taken).center - g.clock.center);
      await t.pump(const Duration(milliseconds: 300));
      expect(M8DutyLogbookProbe.run!.stamps[M8Col.taken], isNotNull);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a stamp');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
