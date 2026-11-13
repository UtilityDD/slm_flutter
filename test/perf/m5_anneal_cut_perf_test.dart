// Lesson 5.3 কাজ 2 (m5_anneal_cut): an idle screen draws zero frames — in the
// section waiting for the first tool (with and without reduced motion), and
// on the workbench waiting at the old clamp.
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
import 'package:slm_flutter/features/game/m5_anneal_cut.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '5.3/do/1', kind: CatalogRungKind.doKind, lessonId: '5.3', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

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

  // Both ends earthed: one tap on উঠুন clears the section.
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => !m5AnnealDeal(math.Random(s)).bare);

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
    debugPrint('PERF m5_anneal_cut $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    await t.pumpWidget(ProviderScope(
      child: DefaultAssetBundle(
        bundle: _DiskBundle(),
        child: MaterialApp(home: M5AnnealPage(ctx: _ctx, pack: m5AnnealPacks['do_5_3_b']!, muted: true, seed: seed)),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('শুরু'), findsNothing);
    await waitIntro(t);
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    t.view.reset();
  }

  for (final reduce in [false, true]) {
    testWidgets('m5_anneal_cut waits quietly in the section (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await open(t);
      await measure(t, 'section ${reduce ? 'reduce' : 'anim'}');
      await close(t);
    });
  }

  testWidgets('m5_anneal_cut waits quietly on the workbench', (t) async {
    await open(t);
    await _pump(t, 1200);
    await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == M5AnnealLines.climb));
    for (var ms = 0; ms < 8000 && find.byType(ChoiceDeck).evaluate().isEmpty; ms += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await waitChoiceDeck(t);
    final right = M5AnnealLines.siteWhy(false);
    final card = find.byWidgetPredicate((w) => w is Semantics && right.contains(w.properties.label));
    await t.tap(card.first, warnIfMissed: false);
    await tapReasonProceed(t);
    await _pump(t, 3000);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == M5AnnealLines.climb), findsNothing, reason: 'on the bench now');
    await measure(t, 'bench');
    await close(t);
  });
}
