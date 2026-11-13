// Lesson 3.5 (লাইটনিং অ্যারেস্টার), কাজ 1 "এল এ-র খবর": the rules (spot the
// failed LA or "সব ঠিক", then report — not touch, not climb, not ignore), the
// deal, the tap geometry, the libraries, and the level in the shell: idle
// perf, the guide first, a full clean play (the coworker refused at the
// hanging lead), a missed fault (slip card), and the deadly freeze (listening
// to him: a hand on the hanging lead). Audit 2026-11-11: no word or dash
// gives a right card away, three slips strike out, he comes even on a fast
// play, the praise window takes no tap, and the looking hint sweeps over all
// three LAs and "সব ঠিক আছে" alike.
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_la_patrol.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '3.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m3LaPatrolPacks['do_3_5_a']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_la_patrol/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
    }
    return rootBundle.load(key);
  }
}

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
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3LaPatrolGeo get _geo => M3LaPatrolGeo.forScene(360 * 850 / 392, 0);

Future<void> _tapLa(WidgetTester t, M3LaPatrolPhase p) async {
  await t.tapAt(_geo.laBody(p).center * _k);
  await _pump(t, 600);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M3LaPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Plays DTR [i] right: spot (or "সব ঠিক"), refuse him / report, the reason.
Future<void> _playRight(WidgetTester t, M3LaPatrolDeal deal, int i) async {
  final c = deal.cases[i];
  if (c.healthy) {
    await t.tap(find.text(M3LaPatrolLines.allOk));
    await _pump(t, 600);
  } else {
    await _tapLa(t, c.phase);
    if (i == deal.callAt) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes at the hanging lead');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M3LaPatrolLines.coworker.right);
      await _pump(t, 1500);
    } else {
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the action deck, DTR $i');
      await _pump(t, 700);
      await _pickRight(t, M3LaPatrolLines.actRight);
      await _pump(t, 800);
    }
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'DTR $i ${c.fault}');
  final whyDeck = find.byWidgetPredicate((w) => w is ChoiceDeck && w.options.any((o) => M3LaPatrolLines.whyRight(c).contains(o.textBn)));
  expect(await _pumpUntil(t, whyDeck), isTrue, reason: 'the reason deck, DTR $i');
  await _pump(t, 700);
  await _pickRight(t, M3LaPatrolLines.whyRight(c));
  await _pump(t, 4000);
}

void main() {
  group('rules', () {
    test('deals: four DTRs — one healthy, one hanging lead (his), two other faults; cracks and bursts on porcelain', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = dealM3LaPatrol(math.Random(s));
        expect(d.cases.length, 4);
        final faults = d.cases.map((c) => c.fault).toList();
        expect(faults.where((f) => f == M3LaPatrolFault.healthy).length, 1);
        expect(faults.where((f) => f == M3LaPatrolFault.dropped).length, 1);
        expect(faults.toSet().length, 4, reason: 'four different DTRs');
        expect(d.cases[d.callAt].fault, M3LaPatrolFault.dropped);
        expect(d.cases.map((c) => c.dtrNo).toSet().length, 4);
        for (final c in d.cases) {
          if (c.fault == M3LaPatrolFault.cracked || c.fault == M3LaPatrolFault.burst) expect(c.body, M3LaPatrolBody.porcelain);
        }
        seen.add(d.cases.map((c) => '${c.fault.name}${c.phase.name}${c.body.name}').join('|'));
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
    });

    M3LaPatrolRun run1(M3LaPatrolFault f, {M3LaPatrolPhase p = M3LaPatrolPhase.y}) =>
        M3LaPatrolRun(M3LaPatrolDeal(cases: [M3LaPatrolCase(id: 'x', dtrNo: 7, body: M3LaPatrolBody.porcelain, fault: f, phase: p)], callAt: 0));

    test('a healthy DTR: "সব ঠিক" is right; marking an LA is a false alarm', () {
      final a = run1(M3LaPatrolFault.healthy);
      expect(a.spot(null), isNull);
      expect(a.stage, M3LaPatrolStage.why);
      expect(a.caught, contains(M3LaPatrolLines.caught[M3LaPatrolFault.healthy]));
      final b = run1(M3LaPatrolFault.healthy);
      expect(b.spot(M3LaPatrolPhase.r), M3LaPatrolMistakes.falseAlarm);
      expect(b.slips, 1);
      expect(b.shown, isTrue);
    });

    test('a failed LA: the right one moves on to "what now"; the wrong one or "সব ঠিক" is the missed fault', () {
      for (final f in M3LaPatrolFault.values.where((f) => f != M3LaPatrolFault.healthy)) {
        final a = run1(f);
        expect(a.spot(M3LaPatrolPhase.y), isNull);
        expect(a.stage, M3LaPatrolStage.act);
        expect(a.caught, contains(M3LaPatrolLines.caught[f]));
        expect(run1(f).spot(M3LaPatrolPhase.b), M3LaPatrolMistakes.missed(f));
        final n = run1(f);
        expect(n.spot(null), M3LaPatrolMistakes.missed(f));
        expect(n.slips, 1);
      }
    });

    test('what now: report is right; a hand on the lead or climbing is deadly; ignoring is a slip', () {
      M3LaPatrolRun found() => run1(M3LaPatrolFault.dropped)..spot(M3LaPatrolPhase.y);
      final ok = found();
      expect(ok.act(M3LaPatrolAct.report), isNull);
      expect(ok.stage, M3LaPatrolStage.why);
      expect(ok.caught, contains(M3LaPatrolLines.caughtReport));
      final t = found();
      expect(t.act(M3LaPatrolAct.touchLead), M3LaPatrolMistakes.touchLead);
      expect(t.ended, isTrue);
      expect(found().act(M3LaPatrolAct.climb), M3LaPatrolMistakes.climbLive);
      final i = found();
      expect(i.act(M3LaPatrolAct.ignore), M3LaPatrolMistakes.noReport);
      expect(i.slips, 1);
      expect(i.deadly, isNull);
      expect(run1(M3LaPatrolFault.dropped).act(M3LaPatrolAct.report), isNull, reason: 'no act before the spot');
    });

    test('three slips: percent 55 (the page strikes out at the third: see the page test)', () {
      final d = M3LaPatrolDeal(cases: [
        for (var i = 0; i < 4; i++) const M3LaPatrolCase(id: 'x', dtrNo: 3, body: M3LaPatrolBody.polymer, fault: M3LaPatrolFault.burnt),
      ], callAt: 0);
      final run = M3LaPatrolRun(d);
      for (var i = 0; i < 3; i++) {
        expect(run.spot(null), M3LaPatrolMistakes.missedBurnt);
        run.next();
      }
      expect(run.percent, 55);
    });

    test('taps: each LA reaches its own phase; a hanging lead end and a cut end reach theirs', () {
      final g = _geo;
      for (final p in M3LaPatrolPhase.values) {
        expect(g.hit(g.laBody(p).center), p);
        expect(g.hit(g.dropEnd(p), dropped: p), p);
        expect(g.hit(g.cutTop(p)), p);
        expect(g.hit(Offset(M3LaPatrolGeo.runX(p), g.groundY - 150)), p, reason: 'down the pole');
      }
      expect(g.hit(Offset(181, g.groundY + 150)), isNull, reason: 'the lane is nothing');
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; art; keys', () {
      void deck(String name, List<String> right, List<String> wrong) {
        expectLibrary(name, right, wrong);
        expectSameLength(name, [...right, ...wrong]);
        for (var s = 0; s < 10; s++) {
          final d = dealChoices(right, wrong, math.Random(s));
          expect(d.where((o) => o.correct).length, 1);
          expect(d.map((o) => o.textBn).toSet().length, 3);
        }
      }

      deck('act', M3LaPatrolLines.actRight, M3LaPatrolLines.actWrong.keys.toList());
      expect(M3LaPatrolLines.actWrong.values.toSet(), {M3LaPatrolAct.touchLead, M3LaPatrolAct.climb, M3LaPatrolAct.ignore});
      for (final f in M3LaPatrolFault.values) {
        final c = M3LaPatrolCase(id: 'x', dtrNo: 1, body: M3LaPatrolBody.porcelain, fault: f);
        deck('why ${f.name}', M3LaPatrolLines.whyRight(c), M3LaPatrolLines.whyWrong(c));
      }
      final cw = M3LaPatrolLines.coworker;
      deck('coworker', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final keys = <String>{};
      for (final m in M3LaPatrolMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('3.5/m3_la_patrol/'));
        keys.add(m.key);
      }
      expect(keys.length, M3LaPatrolMistakes.all.length);
      for (final f in M3LaPatrolFault.values) {
        expect(M3LaPatrolMistakes.all, contains(M3LaPatrolMistakes.missed(f)));
      }
      expect(M3LaPatrolMistakes.all.where((m) => m.deadly).map((m) => m.key).toSet(), {M3LaPatrolMistakes.touchLead.key, M3LaPatrolMistakes.climbLive.key});
      expect(m3LaPatrolPacks.keys, ['do_3_5_a']);
      expect(M3LaPatrolLines.intro.length, lessThan(70), reason: 'the guide\'s first line is short');
    });

    test('no giveaways: the right cards\' words are on wrong cards too; no dash or "না," only on the right ones', () {
      Set<String> words(Iterable<String> xs) => {
            for (final x in xs)
              for (final w in x.replaceAll(RegExp(r'[,।!?—]'), ' ').split(RegExp(r'\s+')))
                if (w.isNotEmpty) w,
          };
      final actWrong = M3LaPatrolLines.actWrong.keys;
      expect(words(M3LaPatrolLines.actRight).difference(words(actWrong)), isEmpty, reason: 'act deck: a word only on the right cards');
      for (final w in ['রিপোর্ট', 'লিখে', 'অফিসে', 'খাতায়', 'দূর']) {
        expect(actWrong.any((x) => x.contains(w)), isTrue, reason: 'act deck: "$w" on a wrong card too');
      }
      final cw = M3LaPatrolLines.coworker;
      expect(cw.right.where((x) => x.startsWith('না')), isEmpty, reason: 'a refusal must not be spotted by its first word');
      for (final w in ['রিপোর্ট', 'লিখে', 'হাত', 'লাইনে', 'খাতায়', 'ঝুলন্ত']) {
        expect(cw.wrong.any((x) => x.contains(w)), isTrue, reason: 'coworker deck: "$w" on a listening card too');
      }
      for (final f in M3LaPatrolFault.values) {
        final c = M3LaPatrolCase(id: 'x', dtrNo: 1, body: M3LaPatrolBody.porcelain, fault: f);
        final rightDash = M3LaPatrolLines.whyRight(c).any((x) => x.contains('—'));
        final wrongDash = M3LaPatrolLines.whyWrong(c).any((x) => x.contains('—'));
        expect(!rightDash || wrongDash, isTrue, reason: 'why ${f.name}: a dash only on the right cards');
        expect(words(M3LaPatrolLines.whyRight(c)).difference(words(M3LaPatrolLines.whyWrong(c))), isEmpty,
            reason: 'why ${f.name}: a word only on the right cards');
        // The usual excuse frame must not mark the wrong cards: it sits on a
        // right card too, or on at most half of the wrong ones.
        final wrong = M3LaPatrolLines.whyWrong(c);
        for (final w in ['তাই', 'ধরলাম', 'খারাপ']) {
          final onRight = M3LaPatrolLines.whyRight(c).any((x) => words([x]).contains(w));
          final share = wrong.where((x) => words([x]).contains(w)).length / wrong.length;
          expect(onRight || share <= 0.5, isTrue, reason: 'why ${f.name}: "$w" only on the wrong cards, on ${(share * 100).round()}%');
        }
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
          child: MaterialApp(home: M3LaPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m3_la_patrol ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3LaPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3LaPatrolLines.allOk), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3LaPatrolLines.allOk), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M3LaPatrolLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: four DTRs checked, failed LAs reported, the coworker refused → pass', (t) async {
      const seed = 5;
      final deal = dealM3LaPatrol(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 4; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.5/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.5/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3LaPatrolLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      await _close(t, c);
    });

    testWidgets('"সব ঠিক" on a failed LA: the slip card, the missed fault booked', (t) async {
      var seed = 0;
      while (dealM3LaPatrol(math.Random(seed)).cases[0].healthy) {
        seed++;
      }
      final c0 = dealM3LaPatrol(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await t.tap(find.text(M3LaPatrolLines.allOk));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3LaPatrolMistakes.missed(c0.fault).key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M3LaPatrolLines.allOk), findsOneWidget, reason: 'the next DTR');
      await _close(t, c);
    });

    testWidgets('listening to him at the hanging lead = deadly — freeze first, then the card', (t) async {
      var seed = 0;
      while (dealM3LaPatrol(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final c0 = dealM3LaPatrol(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await _tapLa(t, c0.phase);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M3LaPatrolLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3LaPatrolMistakes.touchLead.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips: the struck-out card, the level not cleared', (t) async {
      const seed = 7;
      final deal = dealM3LaPatrol(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        final ci = deal.cases[i];
        if (ci.healthy) {
          // A false alarm: an LA marked on a healthy DTR.
          await _tapLa(t, M3LaPatrolPhase.r);
        } else {
          await t.tap(find.text(M3LaPatrolLines.allOk));
          await _pump(t, 800);
        }
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 1500);
        }
      }
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(M3LaPatrolLines.allOk), findsNothing, reason: 'no more play after the strike-out');
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.5/do/0'], isNot('cleared'));
      expect(s.mistakes.length, 3);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: the action deck is up at once, and its first pick brings him in', (t) async {
      var seed = 0;
      while (dealM3LaPatrol(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final c0 = dealM3LaPatrol(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await t.tapAt(_geo.laBody(c0.phase).center * _k);
      await t.pump(const Duration(milliseconds: 60));
      // Rushing on: the other LAs, the same LA, where "সব ঠিক" was.
      for (final p in M3LaPatrolPhase.values) {
        await t.tapAt(_geo.laBody(p).center * _k);
        await t.pump(const Duration(milliseconds: 60));
      }
      final actDeck = find.byWidgetPredicate((w) => w is ChoiceDeck && w.options.any((o) => M3LaPatrolLines.actRight.contains(o.textBn)));
      expect(await _pumpUntil(t, actDeck, maxMs: 1000), isTrue, reason: 'something to do right after "এবার কী করবেন?"');
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he has not come yet');
      expect(find.byType(MistakeCard), findsNothing);
      // A fast pick — even a wrong one — before he came: he cuts in, no slip.
      await waitChoiceDeck(t);
      final wrongAct = _onScreen(M3LaPatrolLines.actWrong.keys.toList());
      expect(wrongAct, isNotEmpty);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'the pick comes before his timer');
      await t.tap(wrongAct.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the pick brings him in now');
      expect(actDeck, findsNothing, reason: 'his deck replaces the action deck');
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _pickRight(t, M3LaPatrolLines.coworker.right);
      await _pump(t, 1500);
      final whyDeck = find.byWidgetPredicate((w) => w is ChoiceDeck && w.options.any((o) => M3LaPatrolLines.whyRight(c0).contains(o.textBn)));
      expect(await _pumpUntil(t, whyDeck), isTrue, reason: 'refusing him reports the LA: the reason');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the praise window takes no tap: no slip, no second score', (t) async {
      var seed = 0;
      while (!dealM3LaPatrol(math.Random(seed)).cases[0].healthy) {
        seed++;
      }
      final c0 = dealM3LaPatrol(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await t.tap(find.text(M3LaPatrolLines.allOk));
      await t.pump(const Duration(milliseconds: 80));
      // Taps on the LAs and on the button's place while the ◆ waits on the table.
      for (final p in M3LaPatrolPhase.values) {
        await t.tapAt(_geo.laBody(p).center * _k);
        await t.pump(const Duration(milliseconds: 60));
      }
      await t.tapAt(const Offset(150, 800));
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      final whyDeck = find.byWidgetPredicate((w) => w is ChoiceDeck && w.options.any((o) => M3LaPatrolLines.whyRight(c0).contains(o.textBn)));
      expect(await _pumpUntil(t, whyDeck), isTrue, reason: 'the reason deck still comes');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('looking hint: a sweep over the three LAs and "সব ঠিক আছে"; off while a deck is up', (t) async {
      var seed = 0;
      while (dealM3LaPatrol(math.Random(seed)).cases[0].healthy || dealM3LaPatrol(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c0 = dealM3LaPatrol(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      final sceneHint = find.ancestor(of: find.byKey(const ValueKey('touch')), matching: find.byType(IdleHint));
      expect(sceneHint, findsOneWidget);
      var w = t.widget<IdleHint>(sceneHint);
      expect(w.waiting, isTrue, reason: 'the level waits for a look');
      final spec = w.spec(t.getSize(sceneHint))!;
      expect(spec.kind, HintKind.sweep);
      expect(spec.space, HintSpace.global);
      expect(spec.options, hasLength(4));
      for (final p in M3LaPatrolPhase.values) {
        expect((spec.options[p.index].center - _geo.laBody(p).center * _k).distance, lessThan(2), reason: 'LA ${p.name}');
      }
      expect(spec.options.last.contains(t.getCenter(find.text(M3LaPatrolLines.allOk))), isTrue, reason: 'the button too');
      await _tapLa(t, c0.phase);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      w = t.widget<IdleHint>(sceneHint);
      expect(w.waiting, isFalse, reason: 'the deck has its own sweep');
      await _close(t, c);
    });

    testWidgets('three taps on nothing while looking show the hand', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 3);
      final sceneHint = find.ancestor(of: find.byKey(const ValueKey('touch')), matching: find.byType(IdleHint));
      expect(t.state<IdleHintState>(sceneHint).showing, isFalse);
      for (var i = 0; i < 3; i++) {
        await t.tapAt(const Offset(340, 180) * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 100));
      expect(t.state<IdleHintState>(sceneHint).showing, isTrue);
      expect(find.byType(MistakeCard), findsNothing, reason: 'a tap on the sky costs nothing');
      await _close(t, c);
    });
  });
}
