// m8_chain_throw (lesson 8.5 কাজ "দুই প্রান্তে কবচ") at rest: once the guide
// has said the task, the substation, the bench, the work pole and an earth
// pole with its kit draw nothing while the player thinks — with animations
// and with reduced motion; and again after the padlock is fitted (the key
// out) and at an end.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_chain_throw.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '8.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.5',
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
    debugPrint('PERF m8_chain_throw $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A seed with no coworker at the left end (he would come on the first touch).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) {
    final d = m8ChainDeal(math.Random(s));
    return d.push == M8Push.early || d.coworkerEnd == 1;
  });

  // Design px → screen px on the 360 × 800 test screen (the scene's height is 800).
  const k = 1.0;
  final geo = M8Geo.forScene(800, 0);

  Future<void> drag(WidgetTester t, Offset from, Offset to) async {
    final g = await t.startGesture(from * k);
    for (var i = 1; i <= 8; i++) {
      await g.moveTo((from + (to - from) * (i / 8)) * k);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await _pump(t, 300);
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8ChainThrowPage(ctx: _ctx, pack: m8ChainThrowPacks['do_8_5_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The padlock fitted and the key out — then still again.
      final run = M8ChainThrowProbe.run!;
      await drag(t, geo.slot(run.tray.indexOf(M8TrayItem.padlock)).center, geo.handle);
      expect(run.key, M8Key.popped);
      await idle(t, '${reduce ? 'reduce' : 'anim'} key out');
      await drag(t, geo.slot(run.tray.indexOf(M8TrayItem.board)).center, geo.handle);
      await drag(t, geo.keyAt, geo.pocket);
      expect(run.key, M8Key.pocket);
      await _pump(t, 800);
      await waitChoiceDeck(t);
      final right = M8ChainLines.whyRight[M8Why.key]!;
      final card = right.map((r) => _label(r)).firstWhere((f) => f.evaluate().isNotEmpty);
      await t.tap(card, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1500);
      // The work pole, then an earth pole with its kit.
      await t.tap(_label(M8ChainLines.leave));
      await _pump(t, 800);
      expect(run.station, M8Station.work);
      await idle(t, '${reduce ? 'reduce' : 'anim'} work pole');
      await t.tap(_label(M8ChainLines.walkLeft));
      await _pump(t, 800);
      expect(run.station, M8Station.endA);
      await idle(t, '${reduce ? 'reduce' : 'anim'} earth pole');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
