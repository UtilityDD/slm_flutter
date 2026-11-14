// The careless coworker (CoworkerMoment / CoworkerPeek) waits with the player:
// once he has said his line and the deck is up he settles and holds still, so
// the screen draws zero frames while the player thinks (audit-kit-03). He
// moves while he talks and on his entrance and exit beats only. His puppet
// sits on its own repaint layer, and his picture decodes near display size.
// Measured in three levels from different modules (2.3, 3.3, 5.7) and on the
// peek alone (beat 1 held by his voice, then beat 2).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_lug_pick.dart';
import 'package:slm_flutter/features/game/m3_crossarm_pick.dart';
import 'package:slm_flutter/features/game/m5_dark_eyes.dart';
import 'package:slm_flutter/features/game/myth_rival_puppet.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seedWhere<D>(D Function(math.Random) deal, bool Function(D) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(deal(math.Random(s))));

var _rebuilds = 0;
var _puppetBuilds = 0;

/// Frames scheduled and rebuilds over [ms] of 16 ms pumps.
Future<(int frames, double rebuildsPerSec, double puppetPerSec)> _window(WidgetTester t, int ms) async {
  _rebuilds = 0;
  _puppetBuilds = 0;
  var frames = 0;
  final n = ms ~/ 16;
  for (var i = 0; i < n; i++) {
    if (t.binding.hasScheduledFrame) frames++;
    await t.pump(const Duration(milliseconds: 16));
  }
  return (frames, _rebuilds * 1000 / ms, _puppetBuilds * 1000 / ms);
}

/// The puppet's nearest repaint layer.
Size _puppetLayer(WidgetTester t) {
  RenderObject? r = t.renderObject(find.byType(MythRivalPuppet));
  while (r != null && !r.isRepaintBoundary) {
    r = r.parent;
  }
  return (r! as RenderBox).size;
}

/// The coworker is on screen with the deck up: measure while the player thinks,
/// second by second from the moment the deck is up.
Future<void> _measureWaiting(WidgetTester t, String what) async {
  await waitChoiceDeck(t);
  expect(find.byType(CoworkerPeek), findsOneWidget, reason: what);
  final frames = <int>[];
  final rebuilds = <int>[];
  final puppet = <int>[];
  for (var s = 0; s < 8; s++) {
    final (f, r, p) = await _window(t, 1008);
    frames.add(f);
    rebuilds.add(r.round());
    puppet.add(p.round());
  }
  final layer = _puppetLayer(t);
  debugPrint('PERF coworker $what, deck up, per second for 8 s: frames $frames, rebuilds $rebuilds, puppet rebuilds $puppet; '
      'total ${frames.fold(0, (a, b) => a + b)} frames; puppet layer ${layer.width.round()}×${layer.height.round()}');
  expect(t.takeException(), isNull);
  expect(find.byType(CoworkerPeek), findsOneWidget, reason: '$what: he is still waiting');
  // He settles within 0.7 s of beat 2 (the deck): from then on his puppet
  // draws nothing. (The guide's own line may still animate: not his.)
  expect(puppet.first, lessThan(45), reason: '$what: a short settle at most');
  for (var s = 1; s < 8; s++) {
    expect(puppet[s], 0, reason: '$what s$s: he holds still while the player thinks');
  }
  // Once the guide has asked, the screen is still (blink beats aside).
  expect(frames.last, lessThan(6), reason: what);
  expect(layer.width * layer.height, lessThan(300 * 400), reason: '$what: his puppet repaints on its own layer');
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  RivalTalk.reset();
  t.view.reset();
}

Future<void> _push(WidgetTester t, Widget page, {Size size = const Size(720, 1600)}) async {
  // As on a muted phone: beat 1 holds his caption for a reading time.
  CoworkerTiming.debugReadHoldInTests = true;
  addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 2.0;
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(ProviderScope(child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox()))));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(builder: (_) => page)));
  await _pump(t, 1500);
  await waitIntro(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }
  ZlFx.setMuted(true);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpokenOnce.resetForTest();
    debugOnRebuildDirtyWidget = (e, _) {
      _rebuilds++;
      if (e.widget is MythRivalPuppet) _puppetBuilds++;
    };
  });
  tearDown(() => debugOnRebuildDirtyWidget = null);

  testWidgets('2.3 lug pick: the coworker waits still with the deck up', (t) async {
    const ctx = LevelContext(rungId: '2.3/do/0', kind: CatalogRungKind.doKind, lessonId: '2.3', lessonTitleBn: '', ladderStep: 7, doIndex: 1, doCount: 2);
    final seed = _seedWhere(dealLugs, (d) => d.callRound == 0);
    await _push(t, M2LugPickPage(ctx: ctx, pack: m2LugPickPack23, muted: true, seed: seed));
    await _pump(t, 3500);
    await _measureWaiting(t, '2.3 lug pick');
    await _close(t);
  });

  testWidgets('3.3 crossarm pick: the coworker waits still with the deck up', (t) async {
    const ctx = LevelContext(rungId: '3.3/do/0', kind: CatalogRungKind.doKind, lessonId: '3.3', lessonTitleBn: '', ladderStep: 60, doIndex: 1, doCount: 2);
    final seed = _seedWhere(m3CrossarmPickDeal, (d) => d.callRound == 0);
    await _push(t, M3CrossarmPickPage(ctx: ctx, pack: m3CrossarmPickPack33, muted: true, seed: seed));
    await _pump(t, 3500);
    await _measureWaiting(t, '3.3 crossarm pick');
    await _close(t);
  });

  testWidgets('5.7 dark eyes: the coworker waits still with the deck up', (t) async {
    const ctx = LevelContext(rungId: '5.7/do/1', kind: CatalogRungKind.doKind, lessonId: '5.7', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);
    final p = M5DarkEyesProbe();
    await _push(t, M5DarkEyesPage(ctx: ctx, pack: m5DarkEyesPacks['do_5_7_b']!, muted: true, seed: 4, probe: p), size: const Size(784, 1700));
    for (var i = 0; i < 40 && p.run!.zone != 0; i++) {
      await t.dragFrom(const Offset(150, 400), const Offset(90, 0));
      await _pump(t, 250);
    }
    expect(p.run!.zone, 0);
    for (var ms = 0; ms < 6000 && find.byType(CoworkerPeek).evaluate().isEmpty; ms += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _measureWaiting(t, '5.7 dark eyes');
    await _close(t);
  });

  group('the peek alone', () {
    Widget peek({required bool captionFull, CoworkerExit? exit, bool quiet = false}) => MaterialApp(
          home: Stack(children: [
            CoworkerPeek(fromLeft: false, exit: exit, quiet: quiet, lineBn: 'ধুর, এত দেখার কী আছে!', tagBn: 'অসাবধান লাইনম্যান', captionFull: captionFull),
          ]),
        );

    testWidgets('he moves while he talks (beat 1), then settles and holds still (beat 2)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      RivalTalk.begin();
      await t.pumpWidget(peek(captionFull: true));
      final (talkFrames, _, talkPuppet) = await _window(t, 6000);
      debugPrint('PERF coworker peek talking: $talkFrames frames / 6 s, puppet ${talkPuppet.toStringAsFixed(0)}/s');
      expect(talkFrames, greaterThan(300), reason: 'he keeps moving the whole time he talks');
      RivalTalk.end();
      await t.pumpWidget(peek(captionFull: false));
      final (settle, _, _) = await _window(t, 800);
      expect(settle, lessThan(50), reason: 'a short settle');
      final (frames, perSec, puppet) = await _window(t, 3000);
      debugPrint('PERF coworker peek waiting: $frames frames / 3 s, ${perSec.toStringAsFixed(0)} rebuilds/s');
      expect(frames, 0);
      expect(puppet, 0);
      expect(_puppetLayer(t).width, lessThan(300));
      // His exit lap plays, then nothing.
      await t.pumpWidget(peek(captionFull: false, exit: CoworkerExit.beaten));
      final (exitFrames, _, _) = await _window(t, 400);
      expect(exitFrames, greaterThan(10), reason: 'he moves as he leaves');
      await _pump(t, 1600);
      final (after, _, _) = await _window(t, 1000);
      expect(after, 0);
      await _close(t);
    });

    testWidgets('quiet: no bob at all', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      RivalTalk.begin();
      await t.pumpWidget(peek(captionFull: true, quiet: true));
      await _pump(t, 500);
      final (frames, _, puppet) = await _window(t, 1000);
      expect(frames, 0);
      expect(puppet, 0);
      RivalTalk.end();
      await _close(t);
    });

    testWidgets('his picture decodes near display size, not 864 × 1152', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(peek(captionFull: true, quiet: true));
      final img = t.widget<Image>(find.descendant(of: find.byType(MythRivalPuppet), matching: find.byType(Image)));
      expect(img.image, isA<ResizeImage>());
      final r = img.image as ResizeImage;
      final h = r.height ?? 0;
      // Box 172.8 × 210.8 dp at dpr 2, with 10 % headroom: 464 px, not 1152.
      expect(h, inInclusiveRange(1, 1151));
      expect(h, lessThanOrEqualTo((math.min(200.0, 360 * 0.48) * 1.22 * 2 * 1.1).round() + 1));
      await _close(t);
    });
  });
}
