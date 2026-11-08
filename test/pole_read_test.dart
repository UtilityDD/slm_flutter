// Lesson 1.3 (পোলের ভাষা): pole rules, deals for PCC and steel, and both
// levels in the shell (idle perf; a clean PCC play with the pressure refused).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/pole_read.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

LevelContext _ctx(int doIndex) => LevelContext(
      rungId: '1.3/do/${doIndex - 1}',
      kind: CatalogRungKind.doKind,
      lessonId: '1.3',
      lessonTitleBn: '',
      ladderStep: 7 + doIndex,
      doIndex: doIndex,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

void main() {
  group('rules', () {
    for (final kind in PoleKind.values) {
      test('deals ($kind): 4 poles, 2–3 condemned, the headline fault once, faults of the kind only', () {
        for (var s = 0; s < 60; s++) {
          final d = dealPoles(math.Random(s), kind);
          expect(d.poles.length, 4);
          final bad = d.poles.where((p) => p.condemned).length;
          expect(bad, inInclusiveRange(2, 3));
          final allowed = kind == PoleKind.pcc ? pccDefects : steelDefects;
          for (final p in d.poles) {
            for (final f in p.flaws) {
              expect(allowed, contains(f.defect));
            }
          }
          final headline = kind == PoleKind.pcc ? PoleDefect.hairline : PoleDefect.groundRust;
          expect(d.poles.where((p) => p.has(headline)).length, 1);
          expect(d.poles[d.callPole].condemned, isTrue);
        }
      });
    }

    test('climbing a condemned pole is deadly with that fault', () {
      final d = dealPoles(math.Random(3), PoleKind.pcc);
      final run = PoleRun(d)..index = d.poles.indexWhere((p) => p.condemned);
      final m = run.decide(climb: true);
      expect(m, PoleMistakes.climbed(run.current.flaws.first.defect));
      expect(m!.deadly, isTrue);
      expect(run.ended, isTrue);
    });

    test('a sound pole: climbing unchecked or reporting is a slip; checked climb is clean', () {
      final d = dealPoles(math.Random(3), PoleKind.steel);
      final ok = d.poles.indexWhere((p) => !p.condemned);
      final a = PoleRun(d)..index = ok;
      expect(a.decide(climb: true), PoleMistakes.skipped);
      final b = PoleRun(d)..index = ok;
      expect(b.decide(climb: false), PoleMistakes.falseReport);
      final c = PoleRun(d)..index = ok;
      c
        ..check(PoleCheck.walk)
        ..check(PoleCheck.base)
        ..check(PoleCheck.sound);
      expect(c.decide(climb: true), isNull);
    });

    test('hollow is heard only; back-side faults are not seen from the front', () {
      const hollow = PoleFlaw(PoleDefect.hollow, PoleSide.front);
      expect(hollow.seenFrom(PoleSide.front), isFalse);
      expect(PoleDefect.hollow.soundsBad, isTrue);
      const back = PoleFlaw(PoleDefect.hairline, PoleSide.back);
      expect(back.seenFrom(PoleSide.front), isFalse);
      expect(back.seenFrom(PoleSide.back), isTrue);
      const lean = PoleFlaw(PoleDefect.lean, PoleSide.back);
      expect(lean.seenFrom(PoleSide.front), isTrue);
    });

    test('every pole mistake has its picture and a lesson point', () {
      for (final m in PoleMistakes.all) {
        expect(m.art, startsWith('assets/game/art/pole/'));
        expect(m.lessonPoint, isNotNull);
      }
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

    for (final pack in poleReadPacks.values) {
      for (final reduce in [false, true]) {
        testWidgets('${pack.id} waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
          t.view.physicalSize = const Size(720, 1600);
          t.view.devicePixelRatio = 2.0;
          t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
          final doIndex = pack.kind == PoleKind.pcc ? 1 : 2;
          await t.pumpWidget(ProviderScope(
            child: MaterialApp(home: PoleReadPage(ctx: _ctx(doIndex), pack: pack, muted: true, seed: 2)),
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
          debugPrint('PERF ${pack.id} ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
    }

    testWidgets('flow (PCC): check each pole, refuse the pressure, right call each time → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 7;
      final pack = poleReadPacks['do_1_3_a']!;
      final deal = dealPoles(math.Random(seed), PoleKind.pcc);
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => PoleReadPage(ctx: _ctx(1), pack: pack, muted: true, seed: seed),
      )));
      await _pump(t, 2000);
      await _skipIntro(t);
      final zones = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'পোলের অংশ');

      Future<void> closeCall() async {
        if (find.text(PoleLines.holdOut).evaluate().isNotEmpty) {
          await t.tap(find.text(PoleLines.holdOut));
          await _pump(t, 500);
        }
      }

      for (var i = 0; i < 4; i++) {
        // Walk round, look at the base (closing the lens), tap for sound.
        await t.tap(find.text(PoleLines.walk));
        await _pump(t, 500);
        await closeCall();
        await t.tap(zones.at(2), warnIfMissed: false); // base (map order: top, waist, base)
        await _pump(t, 500);
        await t.tapAt(const Offset(30, 300));
        await _pump(t, 400);
        await closeCall();
        await t.tap(find.text(PoleLines.tap));
        await _pump(t, 500);
        await closeCall();
        final p = deal.poles[i];
        await t.tap(find.text(p.condemned ? PoleLines.report : PoleLines.climb));
        await _pump(t, 900);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i');
        await t.tap(find.text(i == 3 ? PoleLines.finish : PoleLines.next));
        await _pump(t, i == 3 ? 3000 : 600);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.3/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(PoleLines.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
