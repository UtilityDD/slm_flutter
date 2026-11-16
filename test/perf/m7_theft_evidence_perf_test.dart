// m7_theft_evidence (lesson 7.5 কাজ 2 "দূর থেকে প্রমাণ") at rest: once the
// guide has said the task, the lane, the viewfinder, the live view, the zoom
// rail, the evidence slots and the roll draw nothing while the player thinks
// — with animations and with reduced motion; again after a shot (the flash
// done, the photo in the roll); and at the pole next morning (the scattered
// things, the trainee) once the guide has said the morning's task.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_theft_evidence.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '7.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

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
    debugPrint('PERF m7_theft_evidence $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A play with push (ii): nothing comes in phase 1.
  final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m7TheftDeal(math.Random(s)).push == M7Push.hook);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7TheftEvidencePage(ctx: _ctx, pack: m7TheftPacks['do_7_5_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, '$tag lane');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A shot: the flash, the photo in the roll — then still again.
      await t.tap(_label(M7TheftLines.shutter));
      await idle(t, '$tag after a shot');
      final probe = M7TheftProbe.current!;
      expect(probe.run.roll, hasLength(1));
      // The two proofs sent, the reason, the morning: still at the pole.
      final d = probe.deal;
      final g = probe.lane!;
      probe.aimAt(g.hook(d.thief).center, m7HookZoom);
      await t.pump(const Duration(milliseconds: 100));
      probe.shoot();
      probe.aimAt(g.entry(d.thief).center, m7EntryZoom);
      await t.pump(const Duration(milliseconds: 100));
      probe.shoot();
      final roll = probe.run.roll;
      probe.place(roll[roll.length - 2].id, 0);
      probe.place(roll.last.id, 1);
      await _pump(t, 300);
      await t.tap(_label(M7TheftLines.send));
      await _pump(t, 400);
      await waitChoiceDeck(t);
      final right = M7TheftLines.whyRight[d.reportWhy]!.firstWhere((x) => _label(x).evaluate().isNotEmpty);
      await t.tap(_label(right), warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 3000);
      expect(probe.run.phase, M7Phase.removal);
      expect(find.byType(ChoiceDeck), findsNothing);
      await idle(t, '$tag pole');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
