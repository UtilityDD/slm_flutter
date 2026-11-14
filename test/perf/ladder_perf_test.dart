// Performance regression guard for the golden ladder (AdventureMap).
//
// Measures, in a widget test:
//  * widgets rebuilt per frame while the ladder sits idle (duty-core-03/04),
//  * how many idle-nudge cycles fire while nobody touches the screen
//    (duty-core-26),
//  * the same with the OS "remove animations" setting on,
//  * the same while another opaque route covers the ladder.
//
// Measured on c9ec1bd (before) vs this change (after), 400x800 dp, muted:
//   idle 2 s:      38880 rebuilds (324/frame; _MapBand 1200, _TopHeader 120,
//                  LadderGuideHost 120, AdventureWorld 120)  ->  1083 (9/frame;
//                  all four 0)
//   idle nudge:    17 cycles in 75 s, never stops  ->  3, then silent
//   covered route: 9 nudge cycles + 2943 rebuilds in 40 s  ->  0 and 0
//   reduce motion: 120 rebuilds / 2 s both before and after (the guide's
//                  eye loop in ai_lineman_guide.dart, outside this file set)
//
// The real catalog is loaded (327 rungs, 150 playable): the provider's own
// rootBundle read never finishes under the test's fake clock, so before
// 2026-11-14 every case here measured the 60-rung fallback with the loading
// spinner turning (reduce motion: 120 rebuilds / 2 s, all the spinner).
// On the real ladder, 400x800 dp: idle 2 s 1080 rebuilds (new player) and
// 1028 (40 rungs cleared); reduce motion 0; covered 0; nudge 3 cycles.
//
// Self-contained: no shared helpers. Run with
//   flutter test test/perf/ladder_perf_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/duty_slip/adventure_map.dart';
import 'package:slm_flutter/features/duty_slip/adventure_scenery.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_models.dart';
import 'package:slm_flutter/features/duty_slip/ladder_focus.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/ladder_builder.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';

class _CountingDirector extends GuideDirector {
  static int nudges = 0;

  @override
  void nudgePlay({required bool gift}) {
    nudges++;
    super.nudgePlay(gift: gift);
  }
}

class _Rebuilds {
  final byType = <String, int>{};
  int total = 0;

  /// Frames that had a frame scheduled before they were pumped.
  int framesWanted = 0;

  void start() {
    byType.clear();
    total = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      total++;
      final t = element.widget.runtimeType.toString();
      byType[t] = (byType[t] ?? 0) + 1;
    };
  }

  void stop() => debugOnRebuildDirtyWidget = null;

  int of(String type) => byType[type] ?? 0;
}

final _navKey = GlobalKey<NavigatorState>();

/// The bundled catalog, parsed synchronously (see the header).
ContentCatalog _catalog() => ContentCatalog.fromJson(
    jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map<String, dynamic>);

/// [cleared] rungs cleared in ladder order (0: a new player).
Future<void> _pumpLadder(WidgetTester tester, {bool reduceMotion = false, int cleared = 0}) async {
  final ids = [for (final r in const LadderBuilder().build(_catalog()).rungs) r.id];
  SharedPreferences.setMockInitialValues({
    if (cleared > 0)
      'game_save_v1': jsonEncode({
        'points': 900,
        'migratedFromDs': true,
        'currentRungId': ids[cleared],
        'rungProgress': {for (final id in ids.take(cleared)) id: 'cleared'},
      }),
  });
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  _CountingDirector.nudges = 0;

  final pack = await DsPack.load();
  final engine = DutySlipEngine(pack, seed: 7);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        guideDirectorProvider.overrideWith(_CountingDirector.new),
        contentCatalogProvider.overrideWith((ref) async => _catalog()),
        trainingLadderProvider.overrideWith((ref) async => <TrainingModuleItem>[]),
      ],
      child: MaterialApp(
        navigatorKey: _navKey,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: AdventureMap(
            engine: engine,
            onOpen: (_) {},
            scrollOut: ValueNotifier<double>(0),
            muted: true,
          ),
        ),
      ),
    ),
  );
  // Let the catalog load, the pin scroll run and the guide entrance finish.
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  // The guards below mean something only on the real ladder.
  final built = ProviderScope.containerOf(tester.element(find.byType(AdventureMap))).read(builtLadderProvider).value;
  expect(built, isNotNull, reason: 'the catalog must load (no fallback ladder, no spinner)');
  expect(built!.length, 327);
  expect(ladderPlayableSpan(built), 150);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  if (cleared > 0) {
    final save = ProviderScope.containerOf(tester.element(find.byType(AdventureMap))).read(gameSaveProvider);
    expect(ladderFocus(built, save, 0), cleared, reason: 'the climb stands on rung ${cleared + 1}');
  }
}

/// Pumps [seconds] of 60 fps frames and returns rebuild counts.
Future<_Rebuilds> _measureFrames(WidgetTester tester, {double seconds = 2}) async {
  final r = _Rebuilds()..start();
  final frames = (seconds * 60).round();
  for (var i = 0; i < frames; i++) {
    if (tester.binding.hasScheduledFrame) r.framesWanted++;
    await tester.pump(const Duration(milliseconds: 16));
  }
  r.stop();
  return r;
}

/// Paints so far of the layers that hold whole ladder bands (the nearest
/// RepaintBoundary above each built `_MapBand`).
int _bandLayerPaints(WidgetTester tester) {
  final layers = <RenderRepaintBoundary>{};
  for (final e in find.byWidgetPredicate((w) => w.runtimeType.toString() == '_MapBand').evaluate()) {
    RenderObject? o = e.renderObject;
    while (o != null && o is! RenderRepaintBoundary) {
      o = o.parent;
    }
    if (o is RenderRepaintBoundary) layers.add(o);
  }
  return layers.fold(0, (n, b) => n + b.debugSymmetricPaintCount + b.debugAsymmetricPaintCount);
}

/// The world's 10 background plates and their decode widths.
const _plates = {
  'depth_sky_a': 720, 'depth_sky_b': 720, //
  'depth_ridge_a': 780, 'depth_ridge_b': 780, 'depth_ridge_c': 780,
  'depth_mid_river': 900, 'depth_mid_falls': 900, 'depth_mid_forest': 900,
  'depth_near_a': 800, 'depth_near_b': 800,
};

/// Plates something still listens to (a held plate stays in memory even
/// after `imageCache.clear()`, which is what memory pressure calls).
Future<int> _platesHeld(WidgetTester tester) async {
  var n = 0;
  for (final e in _plates.entries) {
    final provider = ResizeImage.resizeIfNeeded(e.value, null, AssetImage('assets/duty_slip/world3d/${e.key}.webp'));
    final key = await tester.runAsync(() => provider.obtainKey(ImageConfiguration.empty));
    if (imageCache.statusForKey(key!).live) n++;
  }
  return n;
}

/// Plates the world's painter has to draw right now.
int _platesDrawn(WidgetTester tester) {
  for (final p in tester.widgetList<CustomPaint>(
      find.descendant(of: find.byType(AdventureWorld), matching: find.byType(CustomPaint)))) {
    final painter = p.painter;
    if (painter != null && painter.runtimeType.toString() == '_DepthPainter') {
      return ((painter as dynamic).images as Map).length;
    }
  }
  return -1;
}

/// Lets real image decoding finish (it runs outside the fake clock).
Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _idle(WidgetTester tester, Duration d) async {
  final steps = d.inMilliseconds ~/ 100;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _report(String label, _Rebuilds r) {
  final top = r.byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  // ignore: avoid_print
  print('[ladder-perf] $label: frames wanted ${r.framesWanted}, total=${r.total} '
      '_MapBand=${r.of('_MapBand')} _TopHeader=${r.of('_TopHeader')} '
      'LadderGuideHost=${r.of('LadderGuideHost')} AdventureWorld=${r.of('AdventureWorld')} '
      '_DepthStrip=${r.of('_DepthStrip')} top=${top.take(8).map((e) => '${e.key}:${e.value}').join(', ')}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final cleared in const [0, 40]) {
  testWidgets('idle ladder ($cleared rungs cleared): rebuild work per frame stays local to animated bits', (tester) async {
    await _pumpLadder(tester, cleared: cleared);
    // The mascot greets on open and breathes for one ~6 s cycle, then rests;
    // measure the settled ladder (dfd3fd1 mascot design).
    await _idle(tester, const Duration(seconds: 8));
    final bands0 = _bandLayerPaints(tester);
    final r = await _measureFrames(tester);
    final bandPaints = _bandLayerPaints(tester) - bands0;
    _report('idle 2s (120 frames), $cleared cleared', r);
    // ignore: avoid_print
    print('[ladder-perf] band layers repainted in 120 idle frames: $bandPaints');
    // The coin, badge and gleam animate on their own layers; a band's layer
    // (rails, plaque, coin face) must not repaint with them (LayoutBuilder
    // around the band: 120 = every frame).
    expect(bandPaints, lessThanOrEqualTo(4));
    // Header, bands, background and guide host must not rebuild per frame.
    expect(r.of('_MapBand'), lessThanOrEqualTo(4));
    expect(r.of('_TopHeader'), lessThanOrEqualTo(2));
    expect(r.of('LadderGuideHost'), lessThanOrEqualTo(2));
    expect(r.of('AdventureWorld'), lessThanOrEqualTo(2));
    expect(r.of('_DepthStrip'), lessThanOrEqualTo(2));
    // Whatever still animates is small leaf work: coin breath, play-button
    // glow + shimmer, helper badge bob, lively props (dfd3fd1) and guide blinks.
    // ~16 leaf rebuilds/frame settled; the structural widgets above stay at 0.
    expect(r.total, lessThan(120 * 20));
    await tester.pumpWidget(const SizedBox());
  });
  }

  testWidgets('every raster on the ladder decodes at display size (coach badge: 38 dp × DPR)', (tester) async {
    await _pumpLadder(tester, cleared: 40);
    await _idle(tester, const Duration(seconds: 8));
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final full = [
      for (final i in images)
        if (i.image is AssetImage) (i.image as AssetImage).assetName,
    ];
    // The guide's face decodes the same file by cacheHeight; the badge by cacheWidth.
    final badge = [
      for (final i in images)
        if (i.image case ResizeImage(:final AssetImage imageProvider, :final int width)
            when imageProvider.assetName.endsWith('coach_ready.webp'))
          width,
    ];
    // ignore: avoid_print
    print('[ladder-perf] images=${images.length} full-size=$full coach badge cacheWidth=$badge');
    expect(full, isEmpty, reason: 'decode ladder art at its display size');
    expect(badge, [76]); // 38 dp × DPR 2
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('idle nudge fires a bounded number of times', (tester) async {
    await _pumpLadder(tester);
    await _idle(tester, const Duration(seconds: 75));
    // ignore: avoid_print
    print('[ladder-perf] nudge cycles in 75 s idle: ${_CountingDirector.nudges}');
    expect(_CountingDirector.nudges, inInclusiveRange(1, 3));
    final r = await _measureFrames(tester);
    _report('after nudge ended, 2s', r);
    expect(r.of('_MapBand'), lessThanOrEqualTo(4));
    // The spell is over and nobody touched the ladder: its loops rest
    // (before the calm: 120/120 frames, ~7 rebuilds each). The guide's
    // blinks run on a Timer and rebuild only its face.
    expect(r.framesWanted, 0);
    expect(r.total, lessThan(20));

    // A touch wakes the ladder, and it calms again after the next spell.
    await tester.tap(find.byType(ListView), warnIfMissed: false);
    final woke = await _measureFrames(tester, seconds: 0.5);
    _report('after a tap, 0.5s', woke);
    expect(woke.framesWanted, greaterThan(20), reason: 'the coin and the glow move again');
    await _idle(tester, const Duration(seconds: 75));
    final calm = await _measureFrames(tester);
    _report('calm again, 2s', calm);
    expect(calm.framesWanted, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('idle calm: the live coin rests too, 40 rungs in', (tester) async {
    await _pumpLadder(tester, cleared: 40);
    await _idle(tester, const Duration(seconds: 75));
    final r = await _measureFrames(tester);
    _report('40 cleared, after the spell, 2s', r);
    expect(r.framesWanted, 0);
    expect(SchedulerBinding.instance.transientCallbackCount, 0, reason: 'no ticker left running');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('remove-animations: no loops, no nudge', (tester) async {
    await _pumpLadder(tester, reduceMotion: true);
    final r = await _measureFrames(tester);
    _report('reduce motion idle 2s', r);
    await _idle(tester, const Duration(seconds: 40));
    // ignore: avoid_print
    print('[ladder-perf] reduce motion nudge cycles: ${_CountingDirector.nudges}');
    expect(_CountingDirector.nudges, 0);
    expect(r.of('_MapBand'), lessThanOrEqualTo(2));
    expect(r.total, lessThanOrEqualTo(120 * 3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('covered by another route: no nudge timers, no ladder rebuilds', (tester) async {
    await _pumpLadder(tester);
    _navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('top'))));
    await _idle(tester, const Duration(seconds: 2));
    _CountingDirector.nudges = 0;
    final r = _Rebuilds()..start();
    await _idle(tester, const Duration(seconds: 40));
    r.stop();
    _report('covered 40s', r);
    // ignore: avoid_print
    print('[ladder-perf] covered nudge cycles: ${_CountingDirector.nudges}');
    expect(_CountingDirector.nudges, 0);
    expect(r.of('_MapBand'), lessThanOrEqualTo(2));
    expect(r.total, lessThan(200));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('covered by a level: the background plates are let go, and back at once', (tester) async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await _pumpLadder(tester);
    await _decode(tester);
    expect(_platesDrawn(tester), 10);
    expect(await _platesHeld(tester), 10);

    _navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('level'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // ignore: avoid_print
    print('[ladder-perf] plates held while covered: ${await _platesHeld(tester)} (was 10 = ~34 MB pinned)');
    expect(await _platesHeld(tester), 0, reason: 'the cache may evict them; memory pressure can free them');

    // Back while they are still cached: drawn in the very first frame.
    _navKey.currentState!.pop();
    await tester.pump();
    expect(_platesDrawn(tester), 10, reason: 'no blank flash coming back');
    await tester.pump(const Duration(milliseconds: 600));

    // Covered again, then memory pressure: nothing keeps them alive.
    _navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('level'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    imageCache.clear();
    expect(await _platesHeld(tester), 0);
    expect(imageCache.currentSizeBytes, 0);
    _navKey.currentState!.pop();
    await tester.pump();
    await _decode(tester);
    expect(_platesDrawn(tester), 10, reason: 'decoded again after a clear');
    await tester.pumpWidget(const SizedBox());
  });
}
