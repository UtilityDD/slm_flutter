// Lesson 5.6 কাজ 1 "দুই শত্রুর খাতা" (m5_fault_casebook): waiting for the
// first clue — and again with a clue's lens gone and the notebook holding its
// note — the scene is still and draws no frames (with and without reduced
// motion).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_fault_casebook.dart';
import 'package:slm_flutter/features/game/m5_fault_casebook_world.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(rungId: '5.6/do/0', kind: CatalogRungKind.doKind, lessonId: '5.6', lessonTitleBn: '', ladderStep: 0, doIndex: 1, doCount: 2);

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

  // A deal whose first case is not the coworker's (the clue opens at once).
  final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m5CasebookDeal(math.Random(s)).coworkerCase != 0);

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
    debugPrint('PERF m5_fault_casebook $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  for (final reduce in [false, true]) {
    testWidgets('do_5_6_a waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M5FaultCasebookPage(ctx: _ctx, pack: m5FaultCasebookPacks['do_5_6_a']!, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await idle(t, '${reduce ? 'reduce' : 'anim'} · first clue');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // Open the person's clue (tap), then wait again: the lens goes, the note stays.
      final g = M5CaseGeo.forScene((360 * 800 / 360).clamp(560.0, 900.0), 0);
      await t.tapAt(g.hit(M5Spot.person).center);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('note-person')), findsOneWidget);
      await idle(t, '${reduce ? 'reduce' : 'anim'} · after a clue');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
