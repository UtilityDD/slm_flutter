// m6_trip_log (lesson 6.2 কাজ 1 "ট্রিপের খাতা") at rest: once the guide has
// said the task, the control room draws nothing while the player thinks —
// with animations and with reduced motion; and again in the breaker room
// after panels are chalk-marked. The busiest still states too: the lens and
// the register up in the log stage, and the radio reply deck open.
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
import 'package:slm_flutter/features/game/m6_trip_log.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '6.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.2',
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

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

Future<void> _tapLabel(WidgetTester t, String l) async {
  await t.tap(_label(l));
  await _pump(t, 300);
}

/// Picks the one right card of [right] on the open deck.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  final r = [for (final x in right) if (_label(x).evaluate().isNotEmpty) _label(x)];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
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
    debugPrint('PERF m6_trip_log $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  const k = 392 / 360;
  const seed = 7;
  final d = m6TripDeal(math.Random(seed));
  final geo = M6TripGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0));

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6TripLogPage(ctx: _ctx, pack: m6TripLogPacks['do_6_2_a']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      await idle(t, '$tag control room');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // The breaker room, two panels chalk-marked: still again.
      await t.tapAt(M6TripGeo.doorToBreakers.center * k);
      await _pump(t, 600);
      await t.tapAt(geo.panel(0, d.n).center * k);
      await t.tapAt(geo.panel(1, d.n).center * k);
      await idle(t, '$tag breaker room');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }

  // The busiest still states: lens + register up (log stage), then the radio
  // reply deck open. A play whose coworker comes at the register.
  final logSeed = [for (var s = 0; s < 600; s++) s].firstWhere((s) => m6TripDeal(math.Random(s)).push == M6Push.log);
  final dl = m6TripDeal(math.Random(logSeed));
  for (final reduce in [false, true]) {
    testWidgets('waits quietly with the lens and register up, and with the reply deck (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6TripLogPage(ctx: _ctx, pack: m6TripLogPacks['do_6_2_a']!, muted: true, seed: logSeed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await _pump(t, 1200);
      final tag = reduce ? 'reduce' : 'anim';
      // The panels read right, the green reason.
      await t.tapAt(M6TripGeo.doorToBreakers.center * k);
      await _pump(t, 600);
      for (var i = 0; i < dl.n; i++) {
        if (dl.isOpen(i)) {
          await t.tapAt(geo.panel(i, dl.n).center * k);
          await _pump(t, 300);
        }
      }
      await _tapLabel(t, M6TripLogLines.lookDone);
      await _pickRight(t, M6TripLogLines.whyRight[M6WhyTopic.green]!);
      await _pump(t, 1600);
      await t.tapAt(M6TripGeo.doorToControl.center * k);
      await _pump(t, 600);
      // The tripped relay read: the lens and the register up.
      await t.tapAt(M6TripGeo.relay(dl.tripped, dl.n).center * k);
      await _pump(t, 300);
      expect(_label(M6TripLogLines.write), findsOneWidget, reason: 'the register is up');
      await idle(t, '$tag lens + register');
      // The register filled; he is refused; written; the reason; the crew asks.
      await _tapLabel(t, dl.names[dl.tripped]);
      for (final p in dl.flags) {
        await _tapLabel(t, M6TripLogLines.phases[p]);
      }
      await _tapLabel(t, M6TripLogLines.faultChip(dl.fault));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes at the register');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M6TripLogLines.coworkerLog.right);
      await _pump(t, 2600);
      await _tapLabel(t, M6TripLogLines.write);
      await _pickRight(t, M6TripLogLines.whyRight[dl.logWhy]!);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('reply-deck')), maxMs: 10000), isTrue, reason: 'the reply deck');
      await idle(t, '$tag reply deck');
      expect(find.byKey(const ValueKey('reply-deck')), findsOneWidget, reason: 'the deck waits for the player');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
