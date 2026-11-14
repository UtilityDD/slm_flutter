// LinemanFigure (scene_kit.dart) wakes for awakeMs after a change of pose and
// then draws nothing; walk and spray run only while the level holds that mode.
// It sits on its own repaint layer, so a wake repaints the figure, not the
// scene around it (audit-kit-08): checked on the figure alone and in three
// levels from different modules (2.3, 3.3, 5.7), none of which wrap it.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_lug_pick.dart';
import 'package:slm_flutter/features/game/m3_crossarm_pick.dart';
import 'package:slm_flutter/features/game/m5_dark_eyes.dart';
import 'package:slm_flutter/features/game/scene_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<int> _frames(WidgetTester t, int ms) async {
  var frames = 0;
  for (var i = 0; i < ms ~/ 16; i++) {
    if (t.binding.hasScheduledFrame) frames++;
    await t.pump(const Duration(milliseconds: 16));
  }
  return frames;
}

/// The nearest repaint layer of [r], and how many render objects it repaints.
(Size, int) _layerOf(RenderObject r) {
  RenderObject? b = r;
  while (b != null && !b.isRepaintBoundary) {
    b = b.parent;
  }
  var n = 0;
  void count(RenderObject o) {
    n++;
    o.visitChildren((c) {
      if (!c.isRepaintBoundary) count(c);
    });
  }

  count(b!);
  return ((b as RenderBox).size, n);
}

int _seedWhere<D>(D Function(math.Random) deal, bool Function(D) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(deal(math.Random(s))));

Future<void> _push(WidgetTester t, Widget page, {Size size = const Size(720, 1600)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 2.0;
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(ProviderScope(child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox()))));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(builder: (_) => page)));
  await _pump(t, 1500);
  await waitIntro(t);
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  RivalTalk.reset();
  t.view.reset();
}

void _expectOwnLayer(WidgetTester t, String what) {
  for (final e in find.byType(LinemanFigure).evaluate()) {
    final figure = e.renderObject! as RenderBox;
    final (size, n) = _layerOf(figure);
    debugPrint('PERF lineman figure $what: ${figure.size.width.round()}×${figure.size.height.round()} figure, '
        'repaint layer ${size.width.round()}×${size.height.round()} with $n render objects');
    expect(size, figure.size, reason: '$what: the figure repaints on its own layer');
    expect(n, lessThan(6), reason: what);
  }
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
  });

  group('the figure alone', () {
    Widget scene(LinemanMode mode, {int wake = 0}) => MaterialApp(
          home: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFF223344))),
            Positioned(left: 40, top: 200, width: 100, height: 200, child: LinemanFigure(look: LinemanLook.trainee, mode: mode, wake: wake)),
          ]),
        );

    testWidgets('a wake plays for awakeMs, on its own layer, then nothing', (t) async {
      await t.pumpWidget(scene(LinemanMode.idle));
      await _pump(t, 3200);
      expect(await _frames(t, 1000), 0, reason: 'asleep');
      await t.pumpWidget(scene(LinemanMode.talk, wake: 1));
      expect(await _frames(t, 1000), greaterThan(50), reason: 'he moves on a change');
      _expectOwnLayer(t, 'alone');
      await _pump(t, 2200);
      expect(await _frames(t, 1000), 0, reason: 'asleep again after awakeMs');
    });

    testWidgets('walk runs while the level holds it and stops with the mode', (t) async {
      await t.pumpWidget(scene(LinemanMode.walk));
      await _pump(t, 4000);
      expect(await _frames(t, 1000), greaterThan(50), reason: 'walking is open-ended');
      await t.pumpWidget(scene(LinemanMode.idle));
      await _pump(t, 3200);
      expect(await _frames(t, 1000), 0);
    });
  });

  testWidgets('2.3 lug pick: the figure repaints on its own layer', (t) async {
    const ctx = LevelContext(rungId: '2.3/do/0', kind: CatalogRungKind.doKind, lessonId: '2.3', lessonTitleBn: '', ladderStep: 7, doIndex: 1, doCount: 2);
    await _push(t, M2LugPickPage(ctx: ctx, pack: m2LugPickPack23, muted: true, seed: _seedWhere(dealLugs, (d) => d.callRound == 0)));
    expect(find.byType(LinemanFigure), findsWidgets);
    _expectOwnLayer(t, '2.3 lug pick');
    await _close(t);
  });

  testWidgets('3.3 crossarm pick: the figure repaints on its own layer', (t) async {
    const ctx = LevelContext(rungId: '3.3/do/0', kind: CatalogRungKind.doKind, lessonId: '3.3', lessonTitleBn: '', ladderStep: 60, doIndex: 1, doCount: 2);
    await _push(t, M3CrossarmPickPage(ctx: ctx, pack: m3CrossarmPickPack33, muted: true, seed: _seedWhere(m3CrossarmPickDeal, (d) => d.callRound == 0)));
    expect(find.byType(LinemanFigure), findsWidgets);
    _expectOwnLayer(t, '3.3 crossarm pick');
    await _close(t);
  });

  testWidgets('5.7 dark eyes: the figure repaints on its own layer', (t) async {
    const ctx = LevelContext(rungId: '5.7/do/1', kind: CatalogRungKind.doKind, lessonId: '5.7', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);
    await _push(t, M5DarkEyesPage(ctx: ctx, pack: m5DarkEyesPacks['do_5_7_b']!, muted: true, seed: 4, probe: M5DarkEyesProbe()), size: const Size(784, 1700));
    expect(find.byType(LinemanFigure), findsWidgets);
    _expectOwnLayer(t, '5.7 dark eyes');
    await _close(t);
  });
}
