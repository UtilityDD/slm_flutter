// Lesson 1.3 (পোলের ভাষা): pole rules, deals for PCC and steel, fair reason
// libraries that fit the pole, his recorded lines, and both levels in the
// shell: idle perf, a full clean play per pack (walk round — by swipe and by
// the button — look close with the lens, knock, decide, the reasons, the
// coworker refused), a slip, the 3-slip strike-out and the deadly freeze.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/pole_read.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

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

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Taps the one right card on the deck now up.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

/// Opens the page on a navigator and waits for the guide and the walk to the
/// first pole.
Future<ProviderContainer> _open(WidgetTester t, PoleReadPack pack, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  final doIndex = pack.kind == PoleKind.pcc ? 1 : 2;
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => PoleReadPage(ctx: _ctx(doIndex), pack: pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Walk round (by a swipe on the scene, or the button), look close at the
/// base and up to the top with the lens, then knock.
Future<void> _readPole(WidgetTester t, {required bool swipe, Future<void> Function()? onCoworker}) async {
  if (swipe) {
    await t.drag(_label(PoleLines.poleLabel), const Offset(-260, 0), warnIfMissed: false);
  } else {
    await t.tap(find.text(PoleLines.walk));
  }
  await _pump(t, 1500);
  if (onCoworker != null) await onCoworker();
  await t.tap(find.text(PoleLines.look));
  await _pump(t, 500);
  expect(_label(PoleLines.lensLabel), findsOneWidget);
  // The lens moves with the finger: drag up to look up to the top.
  await t.drag(_label(PoleLines.lensLabel), const Offset(0, -900), warnIfMissed: false);
  await _pump(t, 300);
  await t.tap(_label(PoleLines.lensClose), warnIfMissed: false);
  await _pump(t, 400);
  expect(_label(PoleLines.lensLabel), findsNothing);
  await t.tap(find.text(PoleLines.tap));
  await _pump(t, 900);
}

void main() {
  group('rules', () {
    for (final kind in PoleKind.values) {
      test('deals ($kind): 4 poles, 2–3 condemned, the headline fault once, faults of the kind only; he comes on any pole', () {
        final seen = <String>{};
        var hisSound = 0, hisBad = 0;
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
          expect(d.callPole, inInclusiveRange(0, 3));
          d.poles[d.callPole].condemned ? hisBad++ : hisSound++;
          seen.add(d.poles.map((p) => p.flaws.map((f) => '${f.defect}${f.side}').join()).join('|'));
        }
        expect(seen.length, greaterThan(20), reason: 'every play is dealt fresh');
        // His coming does not give the answer away: sometimes a sound pole.
        expect(hisSound, greaterThan(5));
        expect(hisBad, greaterThan(5));
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

    test('a sound pole: climbing unchecked is a slip; reporting is a slip and the pole stays; checked climb is clean', () {
      final d = dealPoles(math.Random(3), PoleKind.steel);
      final ok = d.poles.indexWhere((p) => !p.condemned);
      final a = PoleRun(d)..index = ok;
      expect(a.decide(climb: true), PoleMistakes.skipped);
      expect(a.shown, isTrue);
      final b = PoleRun(d)..index = ok;
      expect(b.decide(climb: false), PoleMistakes.falseReport);
      expect(b.slips, 1);
      expect(b.shown, isFalse, reason: 'still to read');
      b
        ..check(PoleCheck.walk)
        ..check(PoleCheck.base)
        ..check(PoleCheck.sound);
      expect(b.decide(climb: true), isNull);
      expect(b.thorough, isFalse);
      final c = PoleRun(d)..index = ok;
      for (final k in PoleCheck.values) {
        c.check(k);
      }
      expect(c.thorough, isTrue);
      expect(c.decide(climb: true), isNull);
      expect(c.caught, contains(PoleLines.caughtHabit));
      // Up a sound pole on his say-so: the slip, even after every check.
      final e = PoleRun(d)..index = ok;
      for (final k in PoleCheck.values) {
        e.check(k);
      }
      expect(e.decide(climb: true, pushed: true), PoleMistakes.skipped);
      expect(e.slips, 1);
    });

    test('spalling is found by sight (the hammer sounds solid); a loose cross-arm turns or breaks', () {
      expect(PoleDefect.spalling.soundsBad, isFalse);
      expect(PoleDefect.hollow.soundsBad, isTrue);
      expect(PoleLines.defectBn(PoleDefect.crossArm), contains('আলগা'));
      expect(PoleMistakes.climbed(PoleDefect.crossArm).textBn, contains('আলগা'));
      expect(PoleMistakes.climbed(PoleDefect.crossArm).key, '1.3/pole/cross-arm');
    });

    test('three false reports on a sound pole: 3 slips', () {
      final d = dealPoles(math.Random(3), PoleKind.pcc);
      final run = PoleRun(d)..index = d.poles.indexWhere((p) => !p.condemned);
      for (var i = 0; i < 3; i++) {
        expect(run.decide(climb: false), PoleMistakes.falseReport);
      }
      expect(run.slips, 3);
      expect(run.percent, 55);
    });

    test('a right report tags what was caught (back side, sound)', () {
      const back = PoleCase(id: 'b', kind: PoleKind.pcc, flaws: [PoleFlaw(PoleDefect.hairline, PoleSide.back)]);
      const hollow = PoleCase(id: 'h', kind: PoleKind.pcc, flaws: [PoleFlaw(PoleDefect.hollow, PoleSide.front)]);
      final run = PoleRun(const PoleDeal(poles: [back, hollow], callPole: 0));
      expect(run.decide(climb: false), isNull);
      run.next();
      expect(run.decide(climb: false), isNull);
      expect(run.caught, containsAll([PoleLines.caughtReport, PoleLines.caughtBack, PoleLines.caughtSound]));
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

    test('walking round: half a turn is the back side; the collapse fits the fault', () {
      expect(poleSideOf(0), PoleSide.front);
      expect(poleSideOf(0.5), PoleSide.back);
      expect(poleSideOf(1.5), PoleSide.back);
      expect(poleSideOf(-0.5), PoleSide.back);
      expect(poleSideOf(0.9), PoleSide.front);
      expect(collapseFor(PoleDefect.insulator), PoleCollapse.spark);
      expect(collapseFor(PoleDefect.crossArm), PoleCollapse.arm);
      expect(collapseFor(PoleDefect.groundRust), PoleCollapse.fall);
    });

    test('every pole mistake has its picture and a lesson point (0–3 of lesson 1.3)', () {
      for (final m in PoleMistakes.all) {
        expect(m.art, startsWith('assets/game/art/pole/'));
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
    });

    for (final kind in PoleKind.values) {
      test('reasons ($kind): fit the pole, same length, big enough; his lines are recorded', () {
        final pool = kind == PoleKind.pcc ? pccDefects : steelDefects;
        final myths = PoleLines.myths(kind);
        final sound = kind == PoleKind.pcc ? PoleLines.soundPcc : PoleLines.soundSteel;
        // Tighter than the default 1.3: the right card must not be the long one.
        expectSameLength('why $kind', [...sound, for (final d in pool) ...PoleLines.defectWhy(d), ...myths], ratio: 1.15);
        final okPole = PoleCase(id: 'ok', kind: kind, flaws: const []);
        expect(PoleLines.whyWrong(okPole), myths, reason: 'climbed: the myths are the wrong reasons');
        expectLibrary('sound $kind', sound, myths);
        for (final d in pool) {
          final p = PoleCase(id: 'x', kind: kind, flaws: [PoleFlaw(d, PoleSide.front)]);
          expectLibrary('$d', PoleLines.defectWhy(d), PoleLines.whyWrong(p));
          expect(PoleLines.whyRight(p), PoleLines.defectWhy(d));
        }
        expect(PoleLines.whyRight(okPole), sound);
        for (var s = 0; s < 20; s++) {
          final deal = dealChoices(sound, myths, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
        for (final d in pool) {
          final p = PoleCase(id: 'x', kind: kind, flaws: [PoleFlaw(d, PoleSide.front)]);
          for (var s = 0; s < 10; s++) {
            final deal = dealChoices(PoleLines.whyRight(p), PoleLines.whyWrong(p), math.Random(s));
            expect(deal.where((o) => o.correct).length, 1);
            expect(deal.map((o) => o.textBn).toSet().length, 3);
          }
        }
        final c = PoleLines.coworker(kind);
        expectSameLength('choice $kind', [...c.right, ...c.wrong]);
        expectLibrary('choice $kind', c.right, c.wrong);
        for (final l in c.recordedLines) {
          expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
        }
      });
    }
  });

  test('the report deck: every wrong card is a reason not to climb, for a fault this pole did not have', () {
    final mythSet = {...PoleLines.mythsPcc, ...PoleLines.mythsSteel};
    for (final kind in PoleKind.values) {
      final pool = kind == PoleKind.pcc ? pccDefects : steelDefects;
      for (final d in pool) {
        final p = PoleCase(id: 'x', kind: kind, flaws: [PoleFlaw(d, PoleSide.back)]);
        final notHis = {
          for (final o in pool)
            if (o != d) ...PoleLines.defectWhy(o),
        };
        for (var s = 0; s < 12; s++) {
          for (final o in dealChoices(PoleLines.whyRight(p), PoleLines.whyWrong(p), math.Random(s)).where((o) => !o.correct)) {
            expect(mythSet, isNot(contains(o.textBn)), reason: '$d: a myth is a reason to climb');
            expect(notHis, contains(o.textBn), reason: '$d: ${o.textBn}');
            expect(PoleLines.defectWhy(d), isNot(contains(o.textBn)));
          }
        }
      }
    }
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
          expect(find.text('শুরু'), findsNothing);
          await waitIntro(t);
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

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: PoleReadPage(ctx: _ctx(1), pack: poleReadPacks['do_1_3_a']!, muted: true, seed: 2)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(PoleLines.report), findsNothing);
      await waitIntro(t);
      await _pump(t, 1800);
      expect(find.text(PoleLines.report), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, poleReadPacks['do_1_3_a']!, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(PoleLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final (packId, seed) in const [('do_1_3_a', 7), ('do_1_3_b', 11)]) {
      testWidgets('flow ($packId): read each pole, refuse him, right call and reason each time → pass', (t) async {
        final pack = poleReadPacks[packId]!;
        final deal = dealPoles(math.Random(seed), pack.kind);
        final c = await _open(t, pack, seed);
        for (var i = 0; i < 4; i++) {
          final p = deal.poles[i];
          var met = false;
          await _readPole(
            t,
            swipe: i.isEven,
            onCoworker: i == deal.callPole
                ? () async {
                    // He peeps in after the first check; the guide asks; refuse him.
                    await _pump(t, 3500);
                    expect(find.byType(CoworkerPeek), findsOneWidget);
                    await _pickRight(t, PoleLines.coworker(pack.kind).right);
                    await _pump(t, 2500);
                    met = true;
                  }
                : null,
          );
          if (i == deal.callPole) expect(met, isTrue);
          await t.tap(find.text(p.condemned ? PoleLines.report : PoleLines.climb));
          await _pump(t, 2500);
          expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i');
          if (p.condemned) {
            // The deck asks what he found: the fault is not named yet.
            expect(find.text(PoleLines.whyReport), findsWidgets);
            expect(find.byKey(const ValueKey('reveal-0')), findsNothing, reason: 'pole $i: no label under the deck');
          }
          await _pickRight(t, PoleLines.whyRight(p));
          if (p.condemned) {
            await _pump(t, 2300);
            expect(find.byKey(const ValueKey('reveal-0')), findsOneWidget, reason: 'pole $i: named once paid');
            await _pump(t, i == 3 ? 6000 : 3500);
          } else {
            await _pump(t, i == 3 ? 6000 : 3500);
          }
        }
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress[pack.kind == PoleKind.pcc ? '1.3/do/0' : '1.3/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung[pack.kind == PoleKind.pcc ? '1.3/do/0' : '1.3/do/1'], greaterThan(0));
        expect(find.text(PoleLines.caughtCall), findsOneWidget);
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a false report is a slip with its card; the pole stays; three of them strike out', (t) async {
      final pack = poleReadPacks['do_1_3_a']!;
      var seed = 0;
      while (dealPoles(math.Random(seed), pack.kind).poles.first.condemned) {
        seed++;
      }
      final c = await _open(t, pack, seed);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text(PoleLines.report));
        await _pump(t, 900);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          expect(find.text(MistakeLines.readLesson), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(find.text(PoleLines.report), findsOneWidget, reason: 'the same pole is still to read');
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key), contains(PoleMistakes.falseReport.key));
      await _close(t, c);
    });

    testWidgets('listening to him on a sound pole: the climb-without-reading slip, no freeze', (t) async {
      final pack = poleReadPacks['do_1_3_a']!;
      var seed = 3;
      while (true) {
        final d = dealPoles(math.Random(seed), pack.kind);
        if (d.callPole == 0 && !d.poles[0].condemned) break;
        seed++;
      }
      final c = await _open(t, pack, seed);
      await t.tap(find.text(PoleLines.tap));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(PoleLines.coworker(pack.kind).wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, PoleMistakes.skipped.key);
      await _close(t, c);
    });

    testWidgets('listening to him = up a condemned pole: the scene freezes first, then the card', (t) async {
      final pack = poleReadPacks['do_1_3_b']!;
      // A deal where he comes on a condemned pole.
      var seed = 11;
      while (true) {
        final d = dealPoles(math.Random(seed), pack.kind);
        if (d.poles[d.callPole].condemned) break;
        seed++;
      }
      final deal = dealPoles(math.Random(seed), pack.kind);
      final c = await _open(t, pack, seed);
      // Right calls up to his pole.
      for (var i = 0; i < deal.callPole; i++) {
        await _readPole(t, swipe: false);
        final p = deal.poles[i];
        await t.tap(find.text(p.condemned ? PoleLines.report : PoleLines.climb));
        await _pump(t, 2500);
        await _pickRight(t, PoleLines.whyRight(p));
        await _pump(t, 6000);
      }
      await t.tap(find.text(PoleLines.walk));
      await _pump(t, 1500);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(PoleLines.coworker(pack.kind).wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
