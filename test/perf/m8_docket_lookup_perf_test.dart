// m8_docket_lookup (lesson 8.6 কাজ "ডকেট নম্বরটা দিন") at rest: once the
// consumer has spoken, the lane, the house, the slip, the tablet with its
// list, the chips and the home key draw nothing while the player looks — with
// animations and with reduced motion; and again after a row was chosen and
// the list scrolled.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_docket_lookup.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.6',
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

/// A seed whose coworker comes at the report (so he does not walk in during
/// the idle window).
int _quietSeed() => [for (var s = 0; s < 500; s++) s].firstWhere((s) {
      final d = m8DocketDeal(math.Random(s));
      return d.cw == M8CwKind.report;
    });

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
    debugPrint('PERF m8_docket_lookup $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8DocketLookupPage(ctx: _ctx, pack: m8DocketPacks['do_8_6_b']!, muted: true, seed: _quietSeed()))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A row chosen and the list flicked: still again afterwards (no cost).
      final run = M8DocketProbe.run!;
      await t.fling(find.byKey(const ValueKey('docket-list')), const Offset(0, -240), 1200);
      await _pump(t, 1500);
      expect(run.slips, 0);
      expect(run.selected, isNull);
      M8DocketProbe.scroll!.jumpTo(0);
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byKey(ValueKey('row-${run.deal.rows[0].number}')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 200));
      expect(run.selected, isNotNull);
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a flick and a choice');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
