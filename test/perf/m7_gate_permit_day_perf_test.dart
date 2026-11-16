// m7_gate_permit_day (the Module 7 rank gate "সুপারভাইজারের ডকেট: সইয়ের দায়")
// at rest: once the guide has asked 'এগোতে দেবেন?', the world, the crew's
// bubble and the clipboard draw nothing while the player reads — with
// animations and with reduced motion; again with a close-up open, and after
// 'থামান' on an unlawful step (the crew frozen, waiting for the breach tap).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_gate_permit_day.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: 'm7/gate',
  kind: CatalogRungKind.gate,
  lessonId: '7.10',
  lessonTitleBn: '',
  ladderStep: 210,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seedWhere(bool Function(M7GDeal d) ok) {
  for (var s = 1; s < 60000; s++) {
    if (ok(dealM7G(math.Random(s)))) return s;
  }
  throw StateError('no seed');
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
    debugPrint('PERF m7_gate_permit_day $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // An unlawful first step (the permit), so the halted state can be reached.
  final seed = _seedWhere((d) => !d.steps.first.ver.lawful);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final p = M7GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7GatePermitDayPage(ctx: _ctx, pack: m7GatePacks['gate_m7']!, muted: true, seed: seed, probe: p))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      expect(p.phase, 'wait');
      await idle(t, reduce ? 'reduce' : 'anim');
      // A close-up open on the issuer.
      await t.tap(find.byKey(const ValueKey('m7g-obj-issuer')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.phase, 'closeup');
      await idle(t, '${reduce ? 'reduce' : 'anim'} with the close-up open');
      await t.tap(find.byKey(const ValueKey('m7g-lens-close')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.phase, 'wait');
      // After 'থামান': the crew frozen, waiting for the breach tap.
      await t.fling(find.byKey(const ValueKey('m7g-clip')), const Offset(0, 160), 900);
      await _pump(t, 300);
      expect(p.phase, 'halted');
      await idle(t, '${reduce ? 'reduce' : 'anim'} halted');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
