// m7_crew_papers (lesson 7.10 কাজ 1 "যোগ্য হাতে কাজ") at rest: once the guide
// has said the task, the yard, the board and the gang draw nothing while the
// player reads — with animations and with reduced motion; and again with a
// wallet open and a card in the tray.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_crew_papers.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '7.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 0,
  doCount: 1,
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
    debugPrint('PERF m7_crew_papers $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7CrewPapersPage(ctx: _ctx, pack: m7CrewPapersPacks['do_7_10_a']!, muted: true, seed: 5))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await idle(t, reduce ? 'reduce' : 'anim');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // A wallet open (a sleeve swiped) and a card in the tray: still again.
      final run = M7CrewPapersProbe.run!;
      await t.tap(find.byKey(ValueKey('person-${run.roundIdx}-0')), warnIfMissed: false);
      await _pump(t, 500);
      await t.drag(find.byKey(const ValueKey('wallet-sleeve')), const Offset(-120, 0), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('wallet')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('wallet-close')), warnIfMissed: false);
      await _pump(t, 400);
      final card = find.byKey(const ValueKey('job-0'));
      await t.drag(card, t.getCenter(find.byKey(const ValueKey('tray'))) - t.getCenter(card), warnIfMissed: false);
      await _pump(t, 600);
      expect(run.isHeld(0), isTrue);
      await idle(t, '${reduce ? 'reduce' : 'anim'} with a card held');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
  // The deal this seed plays is fixed; keep the import used.
  test('the deal of the perf seed is stable', () {
    final a = m7PapersDeal(math.Random(5));
    final b = m7PapersDeal(math.Random(5));
    expect(a.rounds.first.jobs, b.rounds.first.jobs);
  });
}
