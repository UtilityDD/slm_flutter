// m8_gate_case_file (the Module 8 rank gate "আইনের ডকেট: আলো ফেরান, প্রমাণ
// রাখুন") at rest: once the guide has said the call, the lane, the docket band
// and the belt draw nothing while the player reads — with animations and with
// reduced motion; again after a swipe across the lane, with a token up, with
// the roof sheet open, and in the hearing with the file fan on the bench.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_gate_case_file.dart';
import 'package:slm_flutter/features/game/m8_gate_case_file_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: 'm8/gate',
  kind: CatalogRungKind.gate,
  lessonId: '8.10',
  lessonTitleBn: '',
  ladderStep: 210,
);

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
    debugPrint('PERF m8_gate_case_file $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final p = M8GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8GateCaseFilePage(ctx: _ctx, pack: m8GatePacks['gate_m8']!, muted: true, seed: 5, probe: p))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      expect(p.phase, 'idle');
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, tag);
      // A swipe across the lane, then still again.
      final before = p.pan;
      await t.drag(find.byKey(const ValueKey('m8g-pano')), Offset(p.deal!.mirror ? 400 : -400, 0));
      await _pump(t, 200);
      expect((p.pan - before).abs(), greaterThan(100));
      await idle(t, '$tag after a swipe');
      // A token up.
      await t.tap(find.byKey(const ValueKey('m8g-tok-camera')));
      await _pump(t, 300);
      expect(p.phase, 'lifted');
      await idle(t, '$tag with a token up');
      await t.tap(find.byKey(const ValueKey('m8g-tok-camera')));
      await _pump(t, 300);
      expect(p.phase, 'idle');
      // The roof sheet open on a house.
      p.panTo(M8GTgt.house(1));
      await t.pump();
      await t.longPress(find.byKey(const ValueKey('m8g-tgt-house1')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.phase, 'roof');
      await idle(t, '$tag with the roof sheet open');
      await t.tap(find.byKey(const ValueKey('m8g-roof-close')));
      await _pump(t, 300);
      // The hearing: home (the coworker holds the way home; listening is a slip
      // and ACT 2 opens), then the bench and the file fan.
      await t.tap(find.byKey(const ValueKey('m8g-home')), warnIfMissed: false);
      for (var i = 0; i < 200 && !p.coworkerUp; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(p.coworkerUp, isTrue);
      Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
      for (var i = 0; i < 200 && !M8GateLines.pushReport.wrong.any((x) => label(x).hitTestable().evaluate().isNotEmpty); i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final wrong = M8GateLines.pushReport.wrong.firstWhere((x) => label(x).hitTestable().evaluate().isNotEmpty);
      await t.tap(label(wrong), warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      for (var i = 0; i < 200 && find.text(MistakeLines.gotIt).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.tap(find.text(MistakeLines.gotIt));
      for (var i = 0; i < 400 && !(p.stage == 'hearing' && p.phase == 'hear'); i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(p.stage, 'hearing');
      await idle(t, '$tag in the hearing');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
