// m7_ptw_inquiry (lesson 7.4 কাজ 2 "বৈধ PTW ছিল কি?") at rest: once the guide
// has said the task, the desk — folder, corkboard photo, film strip, logbook
// and the three hold controls — draws nothing while the player thinks, with
// animations and with reduced motion; again after a page swipe and a scrub
// of the strip; and after a hold control was only tapped (its ring rests).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_ptw_inquiry.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

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
    for (var i = 0; i < 14000; i += 50) {
      await t.pump(const Duration(milliseconds: 50));
    }
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
    debugPrint('PERF m7_ptw_inquiry $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // A play whose first case is not the coworker's (he waits for a hold).
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) => m7PtwDeal(math.Random(s)).coworkerCase != 0);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      // 360 × 800 dp: the scene's design height is exactly 800.
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7PtwInquiryPage(ctx: _ctx, pack: m7PtwInquiryPacks['do_7_4_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A page swiped and the strip scrubbed — then still again.
      final g = M7PtwGeo.forScene(800, 0);
      await t.dragFrom(Offset(200, g.book.center.dy), const Offset(-130, 0));
      await t.pump(const Duration(milliseconds: 300));
      await t.dragFrom(g.knob(0, 6), const Offset(160, 0));
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a swipe and a scrub');
      // A stamp only tapped: its ring rests.
      await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == M7PtwInquiryLines.noRowStamp));
      await idle(t, '${reduce ? 'reduce' : 'anim'} after a tapped stamp');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
