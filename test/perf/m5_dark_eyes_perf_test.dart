// Lesson 5.7 কাজ 2 (m5_dark_eyes, "আঁধারে চোখ-কান"): an idle screen draws zero
// frames — at the start (headlamp on, by the house), in the dark after the
// eyes have adapted on a sound stretch (the stars out, nothing to find), and
// on the fault stretch with the clue shown and the reason deck up (the clue's
// light plays once, then holds a still frame). With and without reduced motion.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_dark_eyes.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '5.7/do/1', kind: CatalogRungKind.doKind, lessonId: '5.7', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

int _seedWhere(bool Function(M5DarkEyesDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5DarkEyesDeal(math.Random(s))));

/// Walks to the first stretch and refuses the coworker there.
Future<void> _firstStretch(WidgetTester t, M5DarkEyesProbe p) async {
  for (var i = 0; i < 40 && p.run!.zone != 0; i++) {
    await t.dragFrom(const Offset(150, 400), const Offset(90, 0));
    await _pump(t, 250);
  }
  expect(p.run!.zone, 0);
  for (var ms = 0; ms < 6000 && find.byType(CoworkerPeek).evaluate().isEmpty; ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await waitChoiceDeck(t);
  final right = [
    for (final r in M5DarkEyesLines.coworker.right)
      if (_label(r).evaluate().isNotEmpty) _label(r),
  ];
  expect(right, hasLength(1));
  await t.tap(right.single, warnIfMissed: false);
  await tapReasonProceed(t);
  await _pump(t, 2600);
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
    debugPrint('PERF m5_dark_eyes $what: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20), reason: what);
    expect(frames, lessThan(12), reason: what);
  }

  Future<M5DarkEyesProbe> open(WidgetTester t, int seed, bool reduce) async {
    t.view.physicalSize = const Size(784, 1700);
    t.view.devicePixelRatio = 2.0;
    t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
    final p = M5DarkEyesProbe();
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(home: M5DarkEyesPage(ctx: _ctx, pack: m5DarkEyesPacks['do_5_7_b']!, muted: true, seed: seed, probe: p)),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('শুরু'), findsNothing);
    await waitIntro(t);
    return p;
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    t.view.reset();
  }

  for (final reduce in [false, true]) {
    final mode = reduce ? 'reduce' : 'anim';

    testWidgets('waits quietly at the start ($mode)', (t) async {
      await open(t, 4, reduce);
      await measure(t, 'start $mode');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await close(t);
    });

    testWidgets('waits quietly in the dark on a sound stretch, the eyes adapted ($mode)', (t) async {
      final p = await open(t, _seedWhere((d) => d.stretch != 0), reduce);
      await _firstStretch(t, p);
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 6000);
      expect(p.run!.adapted, isTrue);
      expect(p.run!.clueSeen, isFalse);
      await measure(t, 'dark $mode');
      await close(t);
    });

    testWidgets('waits quietly on the fault stretch, the clue shown and the reason deck up ($mode)', (t) async {
      final p = await open(t, _seedWhere((d) => d.stretch == 0 && d.clue == M5Clue.flash && d.sound != M5Sound.none), reduce);
      await _firstStretch(t, p);
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 6000);
      expect(p.run!.clueSeen, isTrue);
      expect(find.byKey(const ValueKey('clue')), findsOneWidget);
      await measure(t, 'clue $mode');
      expect(find.byType(ChoiceDeck), findsOneWidget);
      await close(t);
    });
  }
}
