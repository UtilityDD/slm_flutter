// Lesson 2.6 (কেবিল স্কিনিং-এর শিল্প), কাজ 2 "শরীরের উল্টো দিকে কাটুন": the
// cut rules (gloves, the mark at the lug barrel, away from the body, never a
// ring cut, a light groove first, never hard, a blunt blade swapped), the
// bench verdicts (a faulty end back, a clean end passed, a needless send-back
// not scored), the deal, the reason libraries, and the level in the shell:
// idle perf, the guide first, the guide's nudges, a full clean play with the
// coworker refused, a slip (card, the end redone) and three slips striking out.
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
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_skin_cut.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2SkinCutPacks['do_2_6_b']!;

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
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
SkinGeo get _geo => SkinGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

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
    builder: (_) => M2SkinCutPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

Future<void> _stroke(WidgetTester t, double strip, {Offset by = const Offset(48, 0)}) async {
  final from = _screen(Offset(SkinGeo.endX - strip + 8, _geo.cableY));
  await t.dragFrom(from, by * _k);
  await _pump(t, 300);
}

/// Skins cable [i] right: gloves, blade, the mark, a light then a medium stroke
/// (on his round he cuts in on the first stroke and is refused). Then the reason.
Future<void> _cutRight(WidgetTester t, SkinDeal deal, int i) async {
  final cable = deal.cables[i];
  if (i == 0) {
    await t.tap(_label(SkinLines.gloves));
    await _pump(t, 300);
  }
  await t.tap(_label(SkinLines.blade));
  await _pump(t, 500);
  await t.tap(find.text(cable.blunt ? SkinLines.newBlade : SkinLines.keepBlade));
  await _pump(t, 400);
  await t.tapAt(_screen(Offset(SkinGeo.endX - cable.barrel, _geo.cableY)));
  await _pump(t, 300);
  await t.tap(_label(SkinLines.light));
  await _pump(t, 200);
  await _stroke(t, cable.barrel);
  if (deal.push == SkinPush.cut && deal.callAt == i) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on cut $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, SkinLines.coworkerCut.right);
    await _pump(t, 1500);
    await _stroke(t, cable.barrel);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'cut $i');
  await t.tap(_label(SkinLines.medium));
  await _pump(t, 200);
  await _stroke(t, cable.barrel);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'cut $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, SkinLines.cutWhy);
  await _pump(t, 5000);
}

/// Judges bench end [i] right (taps the fault first).
Future<void> _judgeRight(WidgetTester t, SkinDeal deal, int i) async {
  final f = deal.ends[i];
  await t.tapAt(_screen(_geo.endRect(i).center));
  await _pump(t, 500);
  final lens = _label(SkinLines.lensLabel);
  expect(lens, findsOneWidget);
  if (f != SkinFault.none) {
    await t.tapAt(t.getTopLeft(lens) + skinFaultRect(f, const Size(296, 150)).center);
    await _pump(t, 300);
  }
  await t.tap(find.text(f == SkinFault.none ? SkinLines.pass : SkinLines.redo));
  await _pump(t, 300);
  if (deal.push == SkinPush.bench && deal.callEnd == i) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on end $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, SkinLines.coworkerBench.right);
    await _pump(t, 1500);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'end $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, SkinLines.faultWhy(f));
  await _pump(t, 5000);
}

void main() {
  group('rules', () {
    test('deals: two cables (different lugs), three bench ends with 1–2 faults; he pushes on a cut or a faulty end', () {
      final seen = <String>{};
      final pushes = <SkinPush>{};
      var blunts = 0;
      for (var s = 0; s < 80; s++) {
        final d = dealSkin(math.Random(s));
        expect(d.cables, hasLength(2));
        expect(d.cables[0].barrel, isNot(d.cables[1].barrel));
        expect(d.cables.where((c) => c.blunt).length, lessThanOrEqualTo(1));
        blunts += d.cables.where((c) => c.blunt).length;
        expect(d.ends, hasLength(3));
        final faults = d.ends.where((f) => f != SkinFault.none).toList();
        expect(faults.length, inInclusiveRange(1, 2));
        expect(faults.toSet().length, faults.length);
        pushes.add(d.push);
        if (d.push == SkinPush.cut) {
          expect(d.callAt, inInclusiveRange(0, 1));
          expect(d.callEnd, -1);
        } else {
          expect(d.callAt, 2);
          expect(d.ends[d.callEnd], isNot(SkinFault.none));
        }
        seen.add('${d.cables.map((c) => '${c.barrel}${c.blunt}').join()}${d.ends}${d.push}${d.callAt}${d.callEnd}');
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(pushes, SkinPush.values.toSet());
      expect(blunts, greaterThan(30));
    });

    SkinDeal deal1({bool blunt = false, List<SkinFault> ends = const [SkinFault.nick, SkinFault.none, SkinFault.edge]}) =>
        SkinDeal(cables: [SkinCable(id: 'a', barrel: 62, blunt: blunt, colour: 0), const SkinCable(id: 'b', barrel: 52, blunt: false, colour: 1)], ends: ends, push: SkinPush.cut, callAt: 0, callEnd: -1);
    SkinRun ready({bool blunt = false}) => SkinRun(deal1(blunt: blunt))
      ..putGloves()
      ..setMark(62);

    test('a clean cut: gloves, the mark at the barrel, a light groove then more pressure, away from the body', () {
      final r = ready();
      expect(r.stroke(SkinStroke.away, SkinPress.light), isNull);
      expect(r.depth, 1);
      expect(r.cutDone, isFalse);
      expect(r.stroke(SkinStroke.away, SkinPress.medium), isNull);
      expect(r.cutDone, isTrue);
      expect(r.slips, 0);
      expect(r.caught, containsAll([SkinLines.caughtAway, SkinLines.caughtGroove, SkinLines.caughtMark, SkinLines.caughtGloves]));
      // Three light strokes also get through.
      final l = ready();
      for (var i = 0; i < 3; i++) {
        expect(l.stroke(SkinStroke.away, SkinPress.light), isNull);
      }
      expect(l.cutDone, isTrue);
      // The mark may be a little off the barrel, not more.
      expect((SkinRun(deal1())..setMark(62 + kSkinMarkTol)).markRight, isTrue);
      expect((SkinRun(deal1())..setMark(62 + kSkinMarkTol + 2)).markRight, isFalse);
    });

    test('every wrong stroke is a slip with its own card (towards the body first)', () {
      expect(ready().stroke(SkinStroke.toward, SkinPress.light), SkinMistakes.towardBody);
      expect(SkinRun(deal1()).stroke(SkinStroke.toward, SkinPress.hard), SkinMistakes.towardBody, reason: 'the body before anything');
      expect(ready().stroke(SkinStroke.across, SkinPress.light), SkinMistakes.ringCut);
      expect((SkinRun(deal1())..setMark(62)).stroke(SkinStroke.away, SkinPress.light), SkinMistakes.noGloves);
      expect((SkinRun(deal1())..putGloves()).stroke(SkinStroke.away, SkinPress.light), SkinMistakes.wrongLength, reason: 'no mark');
      expect((SkinRun(deal1())..putGloves()..setMark(100)).stroke(SkinStroke.away, SkinPress.light), SkinMistakes.wrongLength);
      expect(ready(blunt: true).stroke(SkinStroke.away, SkinPress.light), SkinMistakes.bluntBlade);
      final swapped = ready(blunt: true)
        ..checkBlade()
        ..swapBlade();
      expect(swapped.stroke(SkinStroke.away, SkinPress.light), isNull);
      expect(swapped.caught, contains(SkinLines.caughtBlade));
      expect(ready().stroke(SkinStroke.away, SkinPress.hard), SkinMistakes.tooHard);
      expect(ready().stroke(SkinStroke.away, SkinPress.medium), SkinMistakes.noGroove);
      final r = ready()..stroke(SkinStroke.away, SkinPress.light);
      expect(r.stroke(SkinStroke.away, SkinPress.hard), SkinMistakes.tooHard, reason: 'never hard, even after the groove');
      expect(r.slips, 1);
      expect(r.percent, 85);
      // The end is cut back and skinned again: the mark and the depth go.
      r.redoCut();
      expect(r.mark, isNull);
      expect(r.depth, 0);
      expect(r.gloves, isTrue);
    });

    test('the mark moves until the first stroke; strokes read their way from the drag', () {
      final r = SkinRun(deal1())
        ..putGloves()
        ..setMark(90)
        ..setMark(62);
      expect(r.mark, 62);
      r.stroke(SkinStroke.away, SkinPress.light);
      r.setMark(30);
      expect(r.mark, 62);
      expect(skinStrokeOf(Offset.zero, const Offset(40, 4)), SkinStroke.away);
      expect(skinStrokeOf(Offset.zero, const Offset(-40, 4)), SkinStroke.toward);
      expect(skinStrokeOf(Offset.zero, const Offset(6, 40)), SkinStroke.across);
      expect(skinStrokeOf(Offset.zero, const Offset(10, 6)), isNull);
    });

    test('the bench: faulty ends back, clean ends pass; passing a fault is a slip; a clean end sent back is not scored', () {
      final r = SkinRun(deal1())
        ..next()
        ..next();
      expect(r.onBench, isTrue);
      expect(r.judge(1, redo: true), isNull);
      expect(r.verdicts.containsKey(1), isFalse, reason: 'needless: the end stays to judge');
      expect(r.needless, 1);
      expect(r.slips, 0);
      expect(r.judge(1, redo: false), isNull);
      expect(r.caught, contains(SkinLines.caughtClean));
      expect(r.judge(0, redo: false), SkinMistakes.passNick);
      expect(r.verdicts[0], isTrue, reason: 'sent back after the card');
      expect(r.judge(2, redo: false), SkinMistakes.passEdge);
      expect(r.slips, 2);
      expect(r.benchDone, isTrue);
      final s = SkinRun(deal1())
        ..next()
        ..next();
      s.spot(0, onFault: true);
      s.spot(2, onFault: false);
      expect(s.thoroughEnd(0), isTrue);
      expect(s.thoroughEnd(2), isFalse);
      expect(s.judge(0, redo: true), isNull);
      expect(s.caught, contains(SkinLines.caughtNick));
      for (final f in SkinFault.values.where((f) => f != SkinFault.none)) {
        expect(SkinMistakes.passed(f), f == SkinFault.edge ? SkinMistakes.passEdge : SkinMistakes.passNick);
      }
    });

    test('the lesson\'s words, English digits only; every mistake has its picture and a lesson point (or the pro tip)', () {
      final all = <String>[
        SkinLines.intro,
        ...SkinLines.tasks,
        ...SkinLines.cutWhy,
        ...SkinLines.cutMyths,
        for (final f in SkinFault.values) ...SkinLines.faultWhy(f),
        ...SkinLines.redoExcuses,
        ...SkinLines.passMyths,
        SkinLines.needless,
        for (final cw in [SkinLines.coworkerCut, SkinLines.coworkerBench]) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final m in SkinMistakes.all) m.textBn,
        SkinLines.allSet,
        SkinLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(SkinMistakes.all.where((m) => m.deadly), isEmpty, reason: 'the lesson: a serious injury, not a death');
      expect(SkinMistakes.ringCut.textBn, contains('গোল করে'));
      expect(SkinMistakes.towardBody.textBn, contains('বাইরের দিকে'));
      expect(SkinMistakes.noGroove.lessonPoint, isNull);
      for (final m in SkinMistakes.all) {
        if (m != SkinMistakes.noGroove) expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(m.key, startsWith('2.6/skin/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
    });

    test('quick bonus ≈ 85 % of a thorough play: 80 s; one pack', () {
      expect(_pack.quickMs, 80000);
      expect(m2SkinCutPacks.keys, ['do_2_6_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit line is recorded', () {
      final every = <String>{
        ...SkinLines.cutWhy,
        ...SkinLines.cutMyths,
        for (final f in SkinFault.values) ...SkinLines.faultWhy(f),
        ...SkinLines.redoExcuses,
        ...SkinLines.passMyths,
      }.toList();
      expectSameLength('why', every);
      expectLibrary('cut', SkinLines.cutWhy, SkinLines.cutMyths);
      final rules = {...SkinLines.cutWhy, for (final f in SkinFault.values) ...SkinLines.faultWhy(f)};
      for (final f in SkinFault.values) {
        final wrong = f == SkinFault.none ? SkinLines.passMyths : SkinLines.redoExcuses;
        expectLibrary('$f', SkinLines.faultWhy(f), wrong);
        expect(wrong.toSet().intersection(rules), isEmpty);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(SkinLines.faultWhy(f), wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      expect(SkinLines.cutMyths.toSet().intersection(rules), isEmpty);
      for (final cw in [SkinLines.coworkerCut, SkinLines.coworkerBench]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
        expect(SkinLines.toRecord, contains(cw.line));
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2SkinCutPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m2_skin_cut ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2SkinCutPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(SkinLines.gloves), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(SkinLines.gloves), findsOneWidget);
      expect(_label(SkinLines.light), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      var seed = 0;
      while (dealSkin(math.Random(seed)).push == SkinPush.cut && dealSkin(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(SkinLines.askCut)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in SkinPush.values) {
      testWidgets('flow (${push.name} push): two clean cuts, the bench judged, him refused → pass', (t) async {
        var seed = 1;
        while (true) {
          final d = dealSkin(math.Random(seed));
          if (d.push == push && d.cables.any((c) => c.blunt)) break;
          seed++;
        }
        final deal = dealSkin(math.Random(seed));
        final c = await _open(t, seed);
        await _cutRight(t, deal, 0);
        await _cutRight(t, deal, 1);
        for (var i = 0; i < 3; i++) {
          await _judgeRight(t, deal, i);
        }
        await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 6000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['2.6/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['2.6/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(SkinLines.caughtCall), findsOneWidget);
        expect(find.text(SkinLines.caughtBlade), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('cutting towards the body: the hurt, the card, then the end is skinned again', (t) async {
      var seed = 0;
      while (dealSkin(math.Random(seed)).push == SkinPush.cut && dealSkin(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final deal = dealSkin(math.Random(seed));
      final c = await _open(t, seed);
      final strip = deal.cables[0].barrel;
      await t.tap(_label(SkinLines.gloves));
      await _pump(t, 300);
      await t.tapAt(_screen(Offset(SkinGeo.endX - strip, _geo.cableY)));
      await _pump(t, 300);
      await t.dragFrom(_screen(Offset(SkinGeo.endX - 20, _geo.cableY)), const Offset(-60, 0));
      await _pump(t, 300);
      expect(find.text(SkinLines.ouch), findsOneWidget);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, SkinMistakes.towardBody.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(SkinLines.gloves), findsOneWidget, reason: 'the same cable, skinned again');
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      var seed = 0;
      while (dealSkin(math.Random(seed)).push == SkinPush.cut && dealSkin(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        // A ring cut, with no mark and no gloves.
        await t.dragFrom(_screen(Offset(SkinGeo.endX - 40, _geo.cableY - 14)), const Offset(0, 40));
        await _pump(t, 900);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(await _pumpUntil(t, find.byType(StruckOutCard), maxMs: 3000), isTrue);
      expect(c.read(gameSaveProvider).rungProgress['2.6/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('a clean end sent back is not scored: no card, the guide says why, the end stays', (t) async {
      var seed = 0;
      late SkinDeal deal;
      while (true) {
        deal = dealSkin(math.Random(seed));
        if (deal.push == SkinPush.bench) break;
        seed++;
      }
      final c = await _open(t, seed);
      await _cutRight(t, deal, 0);
      await _cutRight(t, deal, 1);
      final clean = deal.ends.indexOf(SkinFault.none);
      await t.tapAt(_screen(_geo.endRect(clean).center));
      await _pump(t, 500);
      await t.tap(find.text(SkinLines.redo));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(guideDirectorProvider).line, SkinLines.needless);
      expect(_label(SkinLines.lensLabel), findsOneWidget, reason: 'the end is still to judge');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
