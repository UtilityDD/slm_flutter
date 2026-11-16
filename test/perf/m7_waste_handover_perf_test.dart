// m7_waste_handover (lesson 7.8 কাজ 2 "ঠিক হাতে বর্জ্য") at rest: while the
// player sorts the trolley, on the slip card of a cracked lamp, and with a
// vehicle waiting at the gate, nothing draws while the player reads — with
// animations and with reduced motion.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_waste_handover.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '7.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

const _k = 392 / 360;
M7HandGeo get _geo => M7HandGeo.forScene(360 * 850 / 392, 0);
M7HandRun get _live => M7WasteHandoverProbe.run!;
Offset _slot(M7Waste w) => _geo.slot(_live.deal.slotOf[w]!).center;

Future<void> _carry(WidgetTester t, Offset from, Offset to, {bool hold = false}) async {
  final g = await t.startGesture(from * _k);
  if (hold) await _pump(t, kM7LiftMs + 250);
  final target = to.translate(0, kM7HeldLift);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, target, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Future<void> _reason(WidgetTester t) async {
  for (var ms = 0; ms < 8000 && find.byType(ChoiceDeck).evaluate().isEmpty; ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  final right = M7WasteHandoverLines.whyRight[_live.why!]!;
  await _pump(t, 400);
  await waitChoiceDeck(t);
  final f = [
    for (final x in right)
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == x),
  ].firstWhere((f) => f.evaluate().isNotEmpty);
  await t.tap(f, warnIfMissed: false);
  await tapReasonProceed(t);
  await _pump(t, 1800);
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
    debugPrint('PERF m7_waste_handover $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  Future<void> open(WidgetTester t, bool reduce) async {
    t.view.physicalSize = const Size(784, 1700);
    t.view.devicePixelRatio = 2.0;
    t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
    await t.pumpWidget(ProviderScope(
      child: DefaultAssetBundle(
        bundle: _DiskBundle(),
        child: MaterialApp(home: M7WasteHandoverPage(ctx: _ctx, pack: m7WasteHandoverPacks['do_7_8_b']!, muted: true, seed: 7)),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));
    await waitIntro(t);
  }

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    testWidgets('waits quietly ($tag)', (t) async {
      await open(t, reduce);
      // The sorting, waiting for the first move.
      await idle(t, '$tag sorting');
      // A lamp held and released off the box cracks: the slip card, at rest.
      final lamp = _live.deal.items.firstWhere((w) => w.kind == M7Kind.lamp);
      await _carry(t, _slot(lamp), _geo.redBin.center, hold: true);
      expect(find.byType(MistakeCard), findsOneWidget);
      await idle(t, '$tag card');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // Sort the rest, then a vehicle waits at the gate.
      for (final w in _live.deal.items.where((w) => w.kind == M7Kind.lamp && _live.spot[w] == M7Spot.trolley)) {
        await _carry(t, _slot(w), _geo.lampBox.center, hold: true);
      }
      if (_live.why != null) await _reason(t);
      for (final w in _live.deal.items.where((w) => w.kind == M7Kind.oily)) {
        await _carry(t, _slot(w), _geo.redBin.center);
      }
      await _reason(t);
      for (var ms = 0; ms < 12000 && !_live.here; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(_live.here, isTrue);
      await idle(t, '$tag vehicle waiting');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
