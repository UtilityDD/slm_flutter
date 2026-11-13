// Lesson 5.5 কাজ 1 "ড্রপ কোথায়?" (m5_lv_street_read): an idle street draws no
// frames — while the player thinks over the houses (asking) and at the LTDB
// close-up — with and without reduced motion.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_lv_street_read.dart';
import 'package:slm_flutter/features/game/m5_lv_street_read_world.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '5.5/do/0', kind: CatalogRungKind.doKind, lessonId: '5.5', lessonTitleBn: '', ladderStep: 0, doIndex: 1, doCount: 2);

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

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

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

  // A play whose first complaint has many houses and no coworker (the LTDB
  // close-up is reached without him).
  var seed = 0;
  while (true) {
    final d = m5LvDeal(math.Random(seed));
    if (d.complaints.first.area && d.coworkerAt != 0) break;
    seed++;
  }

  Future<void> measure(WidgetTester t, String what) async {
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
    debugPrint('PERF m5_lv_street_read $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  for (final reduce in [false, true]) {
    testWidgets('m5_lv_street_read waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final d = m5LvDeal(math.Random(seed));
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M5LvStreetReadPage(ctx: _ctx, pack: m5LvStreetReadPacks['do_5_5_a']!, muted: true, seed: seed)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      // Asking: the street with a neighbour's reply up.
      final c = d.complaints.first;
      final k = 360 / 360; // 720 px / 2 dpr = 360 dp wide: design px = screen px
      final geo = M5LvGeo.forScene((360 * 800 / 360).clamp(560.0, 900.0), 0);
      await t.tapAt(geo.house((c.caller + 1) % 10).center * k);
      await measure(t, '${reduce ? 'reduce' : 'anim'} asking');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The LTDB close-up with a reading.
      await t.tap(_label(M5LvLines.scopeMany), warnIfMissed: false);
      await confirmChoice(t); // scope chips are two-step now
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final right = [for (final l in M5LvLines.routeAreaRight) if (_label(l).evaluate().isNotEmpty) _label(l)];
      expect(right, hasLength(1));
      await t.tap(right.single, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      await t.tap(_label(M5LvLines.terminalLabel(0)), warnIfMissed: false);
      expect(find.byType(ChoiceDeck), findsNothing);
      await measure(t, '${reduce ? 'reduce' : 'anim'} LTDB');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
