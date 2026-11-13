// Lesson 5.9 কাজ 1 (m5_cable_fault_type): idle at the start (the cable room,
// nothing in hand) and idle with the megger's clips on and its reading shown
// draw no frames (with and without reduced motion).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_cable_fault_type.dart';
import 'package:slm_flutter/features/game/m5_cable_fault_type_world.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '5.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

const _k = 392 / 360;
M5CableGeo get _geo => M5CableGeo.forScene(360 * 850 / 392, 0);

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
    debugPrint('PERF m5_cable_fault_type $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  // A play with both ends OFF and no coworker in round 1.
  final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
    final d = m5CableDeal(math.Random(s));
    return d.cases[0].onEnd == null && d.cwRound == 1;
  });

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M5CableFaultTypePage(ctx: _ctx, pack: m5CableFaultTypePacks['do_5_9_a']!, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('শুরু'), findsNothing);
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }

  testWidgets('waits quietly with the megger clips on and the reading shown', (t) async {
    t.view.physicalSize = const Size(784, 1700);
    t.view.devicePixelRatio = 2.0;
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(home: M5CableFaultTypePage(ctx: _ctx, pack: m5CableFaultTypePacks['do_5_9_a']!, muted: true, seed: seed)),
    ));
    await t.pump(const Duration(milliseconds: 100));
    await waitIntro(t);
    await _pump(t, 1200);
    var view = 0;
    Future<void> tapW(Offset world) async {
      await t.tapAt((world - Offset(360.0 * view, 0)) * _k);
      await _pump(t, 300);
    }

    Future<void> holdW(Offset world) async {
      final g = await t.startGesture((world - Offset(360.0 * view, 0)) * _k);
      await _pump(t, 1300);
      await g.up();
      await _pump(t, 300);
    }

    for (final e in M5End.values) {
      if (e == M5End.far) {
        await t.tap(_label(M5CableLines.farEnd));
        await _pump(t, 700);
        view = 1;
      }
      await holdW(_geo.haspHit(e).center);
      await tapW(_geo.tagHit(e).center);
    }
    await _pump(t, 1500);
    final r = find.byType(ChoiceDeck);
    expect(r, findsOneWidget);
    await _pump(t, 800);
    await waitChoiceDeck(t);
    final right = M5CableLines.isoWhy.where((l) => _label(l).evaluate().isNotEmpty).toList();
    await t.tap(_label(right.single), warnIfMissed: false);
    await tapReasonProceed(t);
    await _pump(t, 1500);
    await t.tap(_label(M5CableLines.nearEnd));
    await _pump(t, 700);
    view = 0;
    await t.tap(_label(M5CableLines.rod));
    await _pump(t, 300);
    await tapW(_geo.hit(M5Pt.nearR).center);
    await tapW(_geo.hit(M5Pt.nearY).center);
    await t.tap(_label(M5CableLines.megger));
    await _pump(t, 300);
    await tapW(_geo.hit(M5Pt.nearR).center);
    await tapW(_geo.hit(M5Pt.nearY).center);
    final g = await t.startGesture(_geo.testPad.center * _k);
    await _pump(t, 1500);
    await g.up();
    await idle(t, 'clips on');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    t.view.reset();
  });
}
