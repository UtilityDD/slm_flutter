// Lesson 2.7 কাজ 1 (মেগারের আগে): the rules of the preparation (whole leads;
// switch OFF → prove dead → discharge before any lead; 500V for the 415V
// motor; L and E set; nobody touching; TEST; discharge again), the deadly
// moves (anything on the live motor; listening to the coworker), the deal,
// the option libraries, and the level in the shell: idle perf, the guide
// first, tap-the-guide, a full clean play to the pass, a slip card, the
// deadly freeze and the coworker; the 3-slip strike-out; the coworker on a
// fast play (the switch waits for him); the praise lock; the knob after a
// wrong voltage once 500V is set; the gesture hint.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_megger_prep.dart';
import 'package:slm_flutter/features/game/m2_megger_prep_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _rung = '2.7/do/1';
final _pack = m2MeggerPrepPacks['do_2_7_a']!;
typedef L = MeggerPrepLines;
typedef M = MeggerPrepMistakes;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.doKind,
      lessonId: '2.7',
      lessonTitleBn: '',
      ladderStep: 1,
      doIndex: 1,
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

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// The one painter of type [T] on screen (the room, the gear, the display).
T _painter<T extends CustomPainter>() => _painters<T>().single;

List<T> _painters<T extends CustomPainter>() => [
      for (final e in find.byWidgetPredicate((w) => w is CustomPaint && w.painter is T).evaluate()) (e.widget as CustomPaint).painter! as T,
    ];

Future<void> _tap(WidgetTester t, String label, {int ms = 900}) async {
  await t.tap(_label(label), warnIfMissed: false);
  await _pump(t, ms);
}

/// A knob position on the close-up: its tap opens it big; ✓ turns the knob.
Future<void> _volt(WidgetTester t, int v) async {
  await t.tap(find.byKey(ValueKey('volt-$v')));
  expect(await confirmChoice(t), isTrue, reason: '$v');
}

/// A run with the whole leads taken.
MeggerPrepRun _ready() => MeggerPrepRun()..pickLeads(whole: true);

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M2MeggerPrepPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

String _wholeLeads(int seed) => dealMeggerPrep(math.Random(seed)).crackedLeft ? L.leadsRightLabel : L.leadsLeftLabel;
String _crackedLeads(int seed) => dealMeggerPrep(math.Random(seed)).crackedLeft ? L.leadsLeftLabel : L.leadsRightLabel;

/// Whole leads, refuse him, OFF → prove → discharge and its reason: the
/// megger is next.
Future<void> _toMegger(WidgetTester t, int seed) async {
  await _leadsDone(t, seed);
  await _pump(t, 2000);
  expect(find.byType(CoworkerPeek), findsOneWidget);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2500);
  await _tap(t, L.switchLabel);
  await _tap(t, L.testerLabel, ms: 1500);
  await _tap(t, L.earthLeadLabel, ms: 2400);
  expect(find.text(L.isoAsk), findsWidgets);
  await _pickRight(t, L.isoRight);
  await _pump(t, 3000);
}

/// Whole leads, the reason, then the coworker is due.
Future<void> _leadsDone(WidgetTester t, int seed) async {
  await _tap(t, _wholeLeads(seed), ms: 2200);
  expect(find.text(L.leadAsk), findsWidgets);
  await _pickRight(t, L.leadRight);
  await _pump(t, 2600);
}

void main() {
  group('rules', () {
    test('leads: the split pair is a slip (choose again); nothing in the room counts before the leads', () {
      final r = MeggerPrepRun();
      expect(r.stage, 0);
      expect(r.tap(MeggerIds.off).kind, OrderTapKind.ignored);
      expect(r.pickLeads(whole: false), M.crackedLead);
      expect(r.slips, 1);
      expect(r.stage, 0);
      expect(r.pickLeads(whole: true), isNull);
      expect(r.stage, 1);
    });

    test('a clean preparation: OFF → prove → discharge → 500V, L, E → (helper back) TEST → discharge again', () {
      final r = _ready();
      for (final id in [MeggerIds.off, MeggerIds.prove, MeggerIds.discharge]) {
        expect(r.tap(id).kind, OrderTapKind.ok, reason: id);
      }
      expect(r.stage, 2);
      for (final id in [MeggerIds.leadE, MeggerIds.v500, MeggerIds.leadL]) {
        expect(r.tap(id).kind, OrderTapKind.ok, reason: 'any order: $id');
      }
      r.clearHelper();
      expect(r.tap(MeggerIds.test).kind, OrderTapKind.ok);
      expect(r.tested, isTrue);
      final last = r.tap(MeggerIds.discharge2);
      expect(last.allDone, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.stage, 3);
      expect(r.isDone(MeggerIds.off), isTrue, reason: 'kept after the board is done');
    });

    test('deadly: a lead or the earth lead on the live motor; listening to him', () {
      for (final id in [MeggerIds.leadL, MeggerIds.leadE]) {
        final r = _ready();
        expect(r.tap(id).mistake, M.notIsolated, reason: id);
        expect(r.ended, isTrue);
      }
      final e = _ready();
      expect(e.tap(MeggerIds.discharge).mistake, M.earthLive);
      expect(e.deadly!.deadly, isTrue);
      final l = _ready()..listened();
      expect(l.deadly, M.liveMegger);
      expect(l.ended, isTrue);
      // Once a play has ended nothing else counts (no second deadly, no helper).
      final x = _ready()..tap(MeggerIds.leadL);
      x
        ..listened()
        ..clearHelper();
      expect(x.deadly, M.notIsolated);
      expect(x.helperClear, isFalse);
      expect(M.all.where((m) => m.deadly), unorderedEquals([M.notIsolated, M.earthLive, M.liveMegger]));
    });

    test('slips: prove before OFF, a lead before the prove or the discharge, a wrong voltage, TEST unset or touched', () {
      final a = _ready();
      expect(a.tap(MeggerIds.prove).mistake, M.offFirst);
      a.tap(MeggerIds.off);
      expect(a.tap(MeggerIds.leadL).mistake, M.proveFirst);
      a.tap(MeggerIds.prove);
      expect(a.tap(MeggerIds.leadE).mistake, M.noDischarge);
      a.tap(MeggerIds.discharge);
      for (final v in [1000, 2500, 5000]) {
        expect(a.tap(MeggerIds.volt(v)).mistake, M.wrongVolt, reason: '$v');
      }
      expect(a.tap(MeggerIds.test).mistake, M.notSet);
      a
        ..tap(MeggerIds.v500)
        ..tap(MeggerIds.leadL)
        ..tap(MeggerIds.leadE);
      expect(a.tap(MeggerIds.test).mistake, M.touching, reason: 'the helper\'s hand is on the motor');
      expect(a.deadly, isNull);
      expect(a.slips, 8);
      expect(a.passed, isFalse);
      // TEST with no lead on the motor is a slip, never a death.
      final b = _ready();
      expect(b.tap(MeggerIds.test).mistake, M.notSet);
      expect(b.ended, isFalse);
    });

    test('mistakes: pictures exist, lesson points (0 the daily check, 1 the procedure)', () {
      for (final m in M.all) {
        expect(m.art, startsWith('assets/game/art/m2_megger_prep/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
        expect(m.key, startsWith('2.7/megger/'));
      }
      expect(M.crackedLead.lessonPoint, 0);
      expect(M.all.map((m) => m.key).toSet(), hasLength(M.all.length));
    });

    test('deal: the split pair on either side, a healthy reading; fresh across plays', () {
      final sides = <bool>{};
      final readings = <int>{};
      for (var s = 0; s < 40; s++) {
        final d = dealMeggerPrep(math.Random(s));
        sides.add(d.crackedLeft);
        readings.add(d.reading);
        expect(d.reading, greaterThan(1), reason: 'above the 1 MΩ floor');
      }
      expect(sides, hasLength(2));
      expect(readings.length, greaterThan(2));
    });

    test('reasons and the coworker\'s deck: same length, big enough, one right per deal', () {
      final libs = {
        'lead': (L.leadRight, L.leadWrong),
        'iso': (L.isoRight, L.isoWrong),
        'volt': (L.voltRight, L.voltWrong),
        'after': (L.afterRight, L.afterWrong),
        'coworker': (L.coworker.right, L.coworker.wrong),
      };
      for (final MapEntry(key: name, value: (right, wrong)) in libs.entries) {
        expectSameLength(name, [...right, ...wrong]);
        expectLibrary(name, right, wrong);
        for (var s = 0; s < 12; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.coworker.line, L.coworkerLine);
      expect(L.coworker.recordedLines, contains('হুঁ! যা খুশি করুন।'));
    });

    test('English digits only; the words of the house', () {
      final all = <String>[
        ...L.guideLines,
        ...L.leadRight, ...L.leadWrong, ...L.isoRight, ...L.isoWrong, //
        ...L.voltRight, ...L.voltWrong, ...L.afterRight, ...L.afterWrong,
        L.coworker.line, ...L.coworker.right, ...L.coworker.wrong, ...L.coworker.asks,
        for (final m in M.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l, isNot(contains('পানি')), reason: l);
      }
      expect(meggerVolts.map(meggerVoltLabel), ['500V', '1kV', '2.5kV', '5kV']);
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
          child: MaterialApp(home: M2MeggerPrepPage(ctx: _ctx(), pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m2_megger_prep ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the leads are in reach', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M2MeggerPrepPage(ctx: _ctx(), pack: _pack, muted: true, seed: 3)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.leadsLeftLabel), findsOneWidget);
      expect(_label(L.leadsRightLabel), findsOneWidget);
      expect(_label(L.switchLabel), findsNothing, reason: 'the room waits for the leads');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askLeads)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: whole leads, refuse him, OFF → prove → discharge, 500V, L, E, helper back, TEST, discharge → pass', (t) async {
      const seed = 11;
      final c = await _open(t, seed);
      await _leadsDone(t, seed);
      await _pump(t, 2000);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, L.coworker.right);
      await _pump(t, 2500);
      await _tap(t, L.switchLabel);
      await _tap(t, L.testerLabel, ms: 1500);
      await _tap(t, L.earthLeadLabel, ms: 2400);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.text(L.isoAsk), findsWidgets);
      await _pickRight(t, L.isoRight);
      await _pump(t, 3000);
      await _tap(t, L.knobLabel, ms: 500);
      expect(find.text('500V'), findsOneWidget);
      await _volt(t, 500);
      await _pump(t, 2400);
      expect(find.text(L.voltAsk), findsWidgets);
      await _pickRight(t, L.voltRight);
      await _pump(t, 3000);
      await _tap(t, L.terminalLabel);
      await _tap(t, L.boltLabel);
      await _tap(t, L.helperLabel);
      await _tap(t, L.testLabel, ms: 3600);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _tap(t, L.earthLeadLabel, ms: 2400);
      expect(find.text(L.afterAsk), findsWidgets);
      await _pickRight(t, L.afterRight);
      await _pump(t, 5000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      expect(find.text(L.caughtAfter), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the split leads: a slip with its card, no freeze; then the whole pair', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      await _tap(t, _crackedLeads(seed), ms: 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M.crackedLead.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsNothing);
      await _tap(t, _wholeLeads(seed), ms: 2200);
      expect(find.text(L.leadAsk), findsWidgets);
      await _close(t, c);
    });

    testWidgets('the L lead on the live motor (after refusing him): frozen first, then the deadly card', (t) async {
      const seed = 2;
      final c = await _open(t, seed);
      await _leadsDone(t, seed);
      await _pump(t, 2000);
      await _pickRight(t, L.coworker.right);
      await _pump(t, 2500);
      await _tap(t, L.terminalLabel, ms: 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('zap')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M.notIsolated.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the coworker: once, the switch waits for him; listening is deadly', (t) async {
      const seed = 9;
      final c = await _open(t, seed);
      await _leadsDone(t, seed);
      // He may already be peeping once the leads are done; wait if not.
      for (var i = 0; i < 40 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await _pump(t, 100);
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(L.coworkerLine), findsOneWidget);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M.liveMegger.key);
      await _close(t, c);
    });

    testWidgets('three slips: the strike-out card, never a pass', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      for (var i = 0; i < 2; i++) {
        await _tap(t, _crackedLeads(seed), ms: 1200);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1}');
        expect(find.byType(StruckOutCard), findsNothing);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 900);
      }
      await _tap(t, _crackedLeads(seed), ms: 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(LevelPassPanel), findsNothing);
      expect(c.read(gameSaveProvider).rungProgress[_rung], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a fast play: the switch waits for him — he comes at once; refused, OFF works', (t) async {
      const seed = 11;
      final c = await _open(t, seed);
      await _tap(t, _wholeLeads(seed), ms: 2200);
      await _pickRight(t, L.leadRight);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his timer has not fired yet');
      // Straight to the switch, well before his 1.2–2.4 s timer.
      await t.tap(_label(L.switchLabel), warnIfMissed: false);
      await _pump(t, 200);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the switch brings him in now');
      expect(find.text(L.coworkerLine), findsOneWidget);
      expect(_painter<MeggerRoomPainter>().switchOn, isTrue, reason: 'the switch waited (no cost)');
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, L.coworker.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _tap(t, L.switchLabel);
      expect(_painter<MeggerRoomPainter>().switchOn, isFalse);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a lead on the live motor while he still talks is listening to him (deadly), never a refusal', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      const seed = 11;
      final c = await _open(t, seed);
      await _tap(t, _wholeLeads(seed), ms: 2200);
      await _pickRight(t, L.leadRight);
      await t.tap(_label(L.switchLabel), warnIfMissed: false);
      await _pump(t, 200);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: he is still talking');
      await _tap(t, L.terminalLabel, ms: 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M.liveMegger.key, reason: 'he pushed it: one deadly, his, no +10 refusal');
      await _close(t, c);
    });

    testWidgets('praise lock + knob: no step during the 500V praise; a wrong voltage after 500V leaves the knob at 500V', (t) async {
      const seed = 11;
      final c = await _open(t, seed);
      await _toMegger(t, seed);
      await _tap(t, L.knobLabel, ms: 500);
      await _volt(t, 500);
      await t.pump(const Duration(milliseconds: 120));
      // The ◆ is on the table: a tap on the terminal does nothing now.
      await t.tap(_label(L.terminalLabel), warnIfMissed: false);
      await _pump(t, 2400);
      expect(_painter<MeggerGearPainter>().lClipped, isFalse, reason: 'praise window: the scene is locked');
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.text(L.voltAsk), findsWidgets);
      await _pickRight(t, L.voltRight);
      await _pump(t, 3000);
      expect(_painter<MeggerDisplayPainter>().volt, 500);
      // The knob turned to 1kV after 500V was set: a slip, and the knob goes back to 500V.
      await _tap(t, L.knobLabel, ms: 500);
      // A tap on a position only opens it big: the knob is not turned yet.
      await t.tap(find.byKey(const ValueKey('volt-1000')));
      await _pump(t, 400);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(_painter<MeggerDisplayPainter>().volt, 500);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('choice-confirm')), findsNothing);
      expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsOneWidget, reason: '✕ sets it aside');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _volt(t, 1000);
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M.wrongVolt.key);
      expect(_painter<MeggerDisplayPainter>().volt, 500, reason: 'what the knob shows is what TEST uses');
      expect(_painter<MeggerGearPainter>().volt, 500);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 900);
      await _tap(t, L.terminalLabel);
      await _tap(t, L.boltLabel);
      await _tap(t, L.helperLabel);
      await _tap(t, L.testLabel, ms: 3600);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _tap(t, L.earthLeadLabel, ms: 2400);
      await _pickRight(t, L.afterRight);
      await _pump(t, 5000);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      await _close(t, c);
    });

    testWidgets('gesture hint: three taps on nothing sweep the hand over both lead pairs (no cost)', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 5);
      IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      expect(hint().showing, isFalse);
      for (var i = 0; i < 3; i++) {
        await t.tapAt(const Offset(200, 240));
        await _pump(t, 150);
      }
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(2));
      await t.tapAt(const Offset(200, 240));
      await _pump(t, 200);
      expect(hint().showing, isFalse, reason: 'a touch hides it');
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'a tap on nothing costs nothing');
      await _close(t, c);
    });
  });
}
