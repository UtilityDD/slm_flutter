// Lesson 1.4, কাজ 1 (তিন মিনিটের পরীক্ষা): harness rules, dated labels, deal
// variety, and the level in the shell (idle perf; a full clean flow with the
// finger slide along the webbing).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/harness_check.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '1.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.4',
  lessonTitleBn: '',
  ladderStep: 11,
  doIndex: 1,
  doCount: 2,
);

final _today = DateTime(2026, 11, 7);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

void main() {
  group('rules', () {
    test('deals: waist belt, one sound harness, two damaged; expiry dates follow the flaw', () {
      for (var s = 0; s < 60; s++) {
        final d = dealHarnesses(math.Random(s), _today);
        expect(d.items.length, 4);
        expect(d.items.where((h) => h.kind == HarnessKind.waistBelt).length, 1);
        expect(d.items.where((h) => h.sound).length, 1);
        for (final h in d.items) {
          if (h.flaw == HarnessFlaw.expired) {
            expect(h.expiry.isBefore(_today), isTrue);
          } else {
            expect(h.expiry.isAfter(_today), isTrue);
          }
        }
        expect(d.items[d.pushIndex].kind, HarnessKind.fullBody);
        expect(d.items[d.pushIndex].flaw, isNot(HarnessFlaw.none));
      }
    });

    test('wearing the waist belt or a damaged harness is deadly; rejecting them is right', () {
      final d = dealHarnesses(math.Random(2), _today);
      for (var i = 0; i < 4; i++) {
        final h = d.items[i];
        if (h.sound) continue;
        final a = HarnessRun(d)..index = i;
        final m = a.decide(wear: true);
        expect(m!.deadly, isTrue);
        expect(m, HarnessMistakes.forFlaw(h));
        final b = HarnessRun(d)..index = i;
        expect(b.decide(wear: false), isNull);
      }
    });

    test('the sound harness: wear after all four checks; skipping or rejecting is a slip', () {
      final d = dealHarnesses(math.Random(2), _today);
      final ok = d.items.indexWhere((h) => h.sound);
      final a = HarnessRun(d)..index = ok;
      a.check(HarnessCheck.webbing);
      expect(a.decide(wear: true), HarnessMistakes.skipped);
      final b = HarnessRun(d)..index = ok;
      expect(b.decide(wear: false), HarnessMistakes.goodRejected);
      final c = HarnessRun(d)..index = ok;
      for (final k in HarnessCheck.values) {
        c.check(k);
      }
      expect(c.decide(wear: true), isNull);
    });
  });

  group('page', () {
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: HarnessCheckPage(ctx: _ctx, pack: harnessPack14, muted: true, seed: 2, today: _today)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
        await _pump(t, 6000);
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
        debugPrint('PERF harness ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('flow: all four checks on each, refuse the push, right call each time → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 5;
      final deal = dealHarnesses(math.Random(seed), _today);
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => HarnessCheckPage(ctx: _ctx, pack: harnessPack14, muted: true, seed: seed, today: _today),
      )));
      await _pump(t, 2000);
      await _skipIntro(t);

      Future<void> closeCall() async {
        if (find.text(HarnessLines.holdOut).evaluate().isNotEmpty) {
          await t.tap(find.text(HarnessLines.holdOut));
          await _pump(t, 500);
        }
      }

      Future<void> look(String label) async {
        await t.tap(find.text(label));
        await _pump(t, 450);
        if (label == HarnessLines.checks[0]) {
          final strip = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'ফিতে');
          final r = t.getRect(strip);
          await t.dragFrom(Offset(r.left + 2, r.center.dy), Offset(r.width - 4, 0));
          await _pump(t, 300);
        }
        await t.tap(find.text(HarnessLines.close));
        await _pump(t, 400);
        await closeCall();
      }

      for (var i = 0; i < 4; i++) {
        for (final l in HarnessLines.checks) {
          await look(l);
        }
        final h = deal.items[i];
        await t.tap(find.text(h.sound ? HarnessLines.wear : HarnessLines.reject));
        await _pump(t, 900);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'harness $i');
        await t.tap(find.text(i == 3 ? HarnessLines.finish : HarnessLines.next));
        await _pump(t, i == 3 ? 3000 : 600);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.4/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(HarnessLines.caughtCall), findsOneWidget);
      expect(find.text(HarnessLines.caughtHabit), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
