// Lesson 5.9 কাজ 2 "মাটির নিচের সূত্র" (m5_cable_route_locate): an idle screen
// draws (almost) no frames and rebuilds little — on the street, with the route
// map open, and in a joint pit's close-up — with and without reduce motion.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_cable_route_locate.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '5.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.9',
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
    debugPrint('PERF m5_cable_route_locate $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly: the street, the map, a pit (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      // A play whose coworker comes on the team path of street 2 (not here).
      final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) {
        final d = m5CrlDeal(math.Random(s));
        return d.push == M5CrlPush.team && d.pushStreet == 1;
      });
      final probe = M5CrlProbe();
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M5CableRouteLocatePage(ctx: _ctx, pack: m5CrlPacks['do_5_9_b']!, muted: true, seed: seed, probe: probe)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await idle(t, 'street ${reduce ? 'reduce' : 'anim'}');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The route map, open.
      await t.tap(_label(M5CrlLines.toolMap));
      await idle(t, 'map ${reduce ? 'reduce' : 'anim'}');
      await t.tap(_label(M5CrlLines.mapClose));
      await _pump(t, 300);
      // Walk to the first pit and open it.
      final run = probe.run!;
      final geo = probe.geo!;
      final i = run.street.ownPits.first;
      final to = run.street.pits[i].t - 0.01;
      final n = (to * geo.ownLength / 6).ceil();
      final g = await t.startGesture(probe.toScreen(geo.ownAt(0))!);
      for (var k = 1; k <= n; k++) {
        await g.moveTo(probe.toScreen(geo.ownAt(to * k / n))!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 300);
      final pit = run.street.pits[i];
      await t.tapAt(probe.toScreen(geo.pitAt(pit.path, pit.t))!);
      await _pump(t, 300);
      expect(run.pitOpen, i);
      await idle(t, 'pit ${reduce ? 'reduce' : 'anim'}');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
