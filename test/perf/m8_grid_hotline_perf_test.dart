// m8_grid_hotline (lesson 8.4 কাজ 1 "হটলাইন বাজছে") at rest: with the state
// deck up, with the slip card up, with the lit hotline waiting after its
// redial, with the meter at rest while the player picks a switch, and with the
// open register — the room, the meter, the bays and the desk draw nothing
// while the player thinks — with animations and with reduced motion.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_grid_hotline.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.4',
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

Future<bool> _until(WidgetTester t, bool Function() ok, {int maxMs = 30000}) async {
  for (var ms = 0; ms < maxMs; ms += 50) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 50));
  }
  return ok();
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
    debugPrint('PERF m8_grid_hotline $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // First incident: no state question, no coworker, the hotline alone or with
  // the black phone; it is missed inside ~12 s of the intro.
  final seed = [for (var s = 0; s < 3000; s++) s].firstWhere((s) {
    final d = m8GridDeal(math.Random(s));
    final i = d.incidents[0];
    return d.askIncident == 1 && d.coworkerIncident == 1 && i.n == 1 && i.driftMs + i.missAtMs <= 10500;
  });
  // A play that opens on the state deck (a normal reading).
  final seedDeck = [for (var s = 0; s < 3000; s++) s].firstWhere((s) {
    final d = m8GridDeal(math.Random(s));
    return d.askIncident == 0 && d.readState == M8State.normal;
  });

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    testWidgets('waits quietly ($tag)', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8GridHotlinePage(ctx: _ctx, pack: m8GridHotlinePacks['do_8_4_a']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final run = M8GridHotlineProbe.run!;
      final g = M8GridGeo.forScene(800, 0);
      // The hotline rang and was missed: the slip card waits.
      expect(await _until(t, () => find.text(M8GridHotlineMistakes.ringMissed.textBn).evaluate().isNotEmpty, maxMs: 16000), isTrue);
      await idle(t, '$tag slip card');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // Read it; the hotline rings again, then the lit lamp waits.
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(await _until(t, () => M8GridHotlineProbe.phones!().hotLit, maxMs: 12000), isTrue);
      await idle(t, '$tag lit hotline');
      // Lift it: the caption, then the race.
      await t.dragFrom(g.hotline.center, const Offset(0, -46));
      await _pump(t, 400);
      expect(await _until(t, () => run.stage == M8Stage.shed, maxMs: 6000), isTrue);
      // The window passes: the card, then the meter rests at its floor.
      expect(await _until(t, () => find.text(M8GridHotlineMistakes.raceLost.textBn).evaluate().isNotEmpty, maxMs: 24000), isTrue);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 3500);
      await idle(t, '$tag shed beat, meter at rest');
      // The open register.
      await t.tapAt(g.register.center);
      await _pump(t, 400);
      expect(M8GridHotlineProbe.regOpen, isTrue);
      await idle(t, '$tag register open');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });

    testWidgets('waits quietly with the state deck up ($tag)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8GridHotlinePage(ctx: _ctx, pack: m8GridHotlinePacks['do_8_4_a']!, muted: true, seed: seedDeck))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      expect(M8GridHotlineProbe.run!.stage, M8Stage.state);
      await idle(t, '$tag state deck');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
