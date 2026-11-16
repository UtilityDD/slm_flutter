// m8_notice_calendar (lesson 8.2 কাজ "দিন গুনুন, তারপর কাটুন") at rest: once
// the guide has said the task, the pinned paper, then the opened docket and
// calendar, then the tiles, the notebook and the crate pads draw nothing while
// the player looks — with animations and with reduced motion; and again after
// a ribbon was dragged and measured.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_notice_calendar.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '8.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.2',
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
    debugPrint('PERF m8_notice_calendar $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  // The scene's design height is exactly 800 on a 360 × 800 dp screen.
  final geo = M8Geo.forScene(800, 0);

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      final name = reduce ? 'reduce' : 'anim';
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8NoticeCalendarPage(ctx: _ctx, pack: m8NoticeCalendarPacks['do_8_2_a']!, muted: true, seed: 4))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      // The pinned paper.
      await idle(t, '$name docket');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // Opened: the docket and the calendar.
      await t.tapAt(geo.closedDocket.center);
      await _pump(t, 600);
      expect(M8NoticeProbe.stage, 'measure');
      await idle(t, '$name calendar');
      // A ribbon dragged to 'আজ': the count and the tiles up.
      final h = M8NoticeProbe.run!.house;
      final start = h.docketDates.first;
      final a = geo.dateRect(h, start)!.center;
      final b = geo.todayRect(h).center;
      final g = await t.startGesture(a);
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(a, b, i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 600);
      expect(M8NoticeProbe.measured, isTrue);
      expect(M8NoticeProbe.run!.slips, 0);
      await idle(t, '$name tiles');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }

  // The notebook and the crate pads at rest (a play dealt to reach each).
  for (final reduce in [false, true]) {
    testWidgets('waits quietly at the notebook and the crate (${reduce ? 'reduce' : 'anim'})', (t) async {
      final name = reduce ? 'reduce' : 'anim';
      int seedWhere(M8Kind k) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) {
            final d = m8DealPlay(math.Random(s));
            return d.houses.first.kind == k && d.hisHouse != 0;
          });
      for (final k in [M8Kind.longNotice, M8Kind.oldCut]) {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8NoticeCalendarPage(ctx: _ctx, pack: m8NoticeCalendarPacks['do_8_2_a']!, muted: true, seed: seedWhere(k)))));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
        await t.tapAt(geo.closedDocket.center);
        await _pump(t, 600);
        final h = M8NoticeProbe.run!.house;
        final start = k == M8Kind.longNotice ? h.notice! : h.cut!;
        final a = geo.dateRect(h, start)!.center;
        final b = geo.todayRect(h).center;
        final g = await t.startGesture(a);
        for (var i = 1; i <= 10; i++) {
          await g.moveTo(Offset.lerp(a, b, i / 10)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await _pump(t, 600);
        final tile = h.answer;
        await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == M8NoticeLines.tile(tile)), warnIfMissed: false);
        await _pump(t, 700);
        await t.tap(find.byKey(const ValueKey('choice-confirm')), warnIfMissed: false);
        await _pump(t, 700);
        expect(M8NoticeProbe.stage, k == M8Kind.longNotice ? 'note' : 'crate');
        await idle(t, '$name ${k.name}');
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      }
    });
  }
}
