// Lesson 3.3, কাজ 1 (সঠিক ক্রস-আর্ম, সঠিক ক্ল্যাম্প): rules of the rack (the
// docket's line and pole decide the type; rust and bend show only where the
// hand has been), deal variety, fair reason libraries, and the level in the
// shell (idle perf; guide first; a full clean flow with the docket, a faulty
// part to the drum, the reasons, the coworker and the replacement; a slip
// card; listening to the coworker; three slips; a fast take cannot skip the
// coworker; he comes only with something to push; the praise window takes no
// input; gesture hints in each waiting state).
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_crossarm_pick.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '3.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.3',
  lessonTitleBn: '',
  ladderStep: 60,
  doIndex: 1,
  doCount: 2,
);

typedef _Item = M3CrossarmPickItem;
typedef _Round = M3CrossarmPickRound;

_Item _good(_Round r) => r.items.firstWhere((x) => x.shape == r.want && x.sound);
_Item _flawed(_Round r) => r.items.firstWhere((x) => x.shape == r.want && !x.sound);
_Item _wrongType(_Round r) => r.items.firstWhere((x) => x.shape != r.want);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seed(bool Function(M3CrossarmPickDeal) ok) {
  for (var s = 0;; s++) {
    if (ok(m3CrossarmPickDeal(math.Random(s)))) return s;
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

void main() {
  group('rules', () {
    test('every deal: three parts, nuts last; the docket decides the type; one of arm/clamp has no good part', () {
      for (var s = 0; s < 80; s++) {
        final d = m3CrossarmPickDeal(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds.last.slot, M3CrossarmPickSlot.nuts);
        expect(d.rounds.map((r) => r.slot).toSet(), M3CrossarmPickSlot.values.toSet());
        final holds = d.rounds.where((r) => r.noneFits).toList();
        expect(holds, hasLength(1));
        expect(holds.single.slot, isNot(M3CrossarmPickSlot.nuts));
        for (final r in d.rounds) {
          expect(r.want, d.docket.want(r.slot));
          expect(r.items.every((x) => x.shape.slot == r.slot), isTrue);
          expect(r.items.any((x) => x.shape != r.want), isTrue, reason: 'a wrong type on every rack');
          expect(r.items.length, inInclusiveRange(3, 4));
          if (!r.noneFits) expect(r.items.where((x) => x.shape == r.want && x.sound).length, 1);
          for (final x in r.items) {
            if (x.flaw == M3CrossarmPickFlaw.bend) expect(r.slot, M3CrossarmPickSlot.crossarm);
          }
        }
      }
      const pcc = M3CrossarmPickDocket(line: M3CrossarmPickLine.ltVertical, pole: M3CrossarmPickPole.pcc, feederBn: '', timeBn: '');
      expect(pcc.want(M3CrossarmPickSlot.crossarm), M3CrossarmPickShape.vArm);
      expect(pcc.want(M3CrossarmPickSlot.clamp), M3CrossarmPickShape.wrapClamp);
      expect(M3CrossarmPickLine.ltHorizontal.arm, M3CrossarmPickShape.iArm);
      expect(M3CrossarmPickLine.ht.arm, M3CrossarmPickShape.channel);
      expect(M3CrossarmPickPole.rail.clamp, M3CrossarmPickShape.boltClamp);
      expect(M3CrossarmPickPole.hBeam.clamp, M3CrossarmPickShape.boltClamp);
    });

    test('a clean play: each part waits for its reason', () {
      final run = M3CrossarmPickRun(m3CrossarmPickDeal(math.Random(3)));
      for (var i = 0; i < 3; i++) {
        final r = run.current;
        if (r.noneFits) {
          expect(run.holdJob().verdict, M3CrossarmPickVerdict.right);
        } else {
          final g = _good(r);
          expect(run.pack(g).verdict, M3CrossarmPickVerdict.right);
          expect(run.packed[i], g);
        }
        expect(run.shown, isTrue);
        expect(run.round, i, reason: 'moves on only after the reason');
        expect(run.holdJob().verdict, M3CrossarmPickVerdict.slip, reason: 'nothing more on a decided part');
        run.next();
      }
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.packed.length, 2);
      expect(run.caught, containsAll([M3CrossarmPickLines.caughtNuts, M3CrossarmPickLines.caughtHold]));
    });

    test('a wrong type is a slip and stays on the rack; a faulty one is a slip and goes to the drum; replacing a good one is a slip', () {
      final run = M3CrossarmPickRun(m3CrossarmPickDeal(math.Random(5)));
      final r = run.current;
      final wrong = _wrongType(r);
      final o = run.pack(wrong);
      expect(o.verdict, M3CrossarmPickVerdict.slip);
      expect(o.mistake, r.slot == M3CrossarmPickSlot.crossarm ? M3CrossarmPickMistakes.wrongArm : M3CrossarmPickMistakes.wrongClamp);
      expect(o.mistake!.deadly, isFalse);
      expect(run.rejected, isNot(contains(wrong.id)));
      final bad = _flawed(r);
      final b = run.pack(bad);
      expect(b.mistake!.key, M3CrossarmPickMistakes.forPack(bad, r.want)!.key);
      expect(run.rejected, contains(bad.id));
      expect(run.slips, 2);
      if (!r.noneFits) {
        expect(run.holdJob().mistake, M3CrossarmPickMistakes.heldWhenRight);
        expect(run.slips, 3);
        expect(run.passed, isFalse);
      }

      final n = M3CrossarmPickRun(m3CrossarmPickDeal(math.Random(5)));
      n.round = 2;
      expect(n.pack(n.current.items.firstWhere((x) => x.shape == M3CrossarmPickShape.nutsBare)).mistake, M3CrossarmPickMistakes.noWasher);
      expect(n.pack(n.current.items.firstWhere((x) => x.flaw == M3CrossarmPickFlaw.rust)).mistake, M3CrossarmPickMistakes.rust(M3CrossarmPickSlot.nuts));
    });

    test('putting back: only a part whose fault was found goes to the drum', () {
      final run = M3CrossarmPickRun(m3CrossarmPickDeal(math.Random(5)));
      final r = run.current;
      final bad = _flawed(r);
      expect(run.putBack(_wrongType(r)), isFalse);
      expect(run.putBack(bad), isFalse, reason: 'not looked for: putting back gives nothing away');
      run.spot(_wrongType(r));
      run.spot(bad);
      expect(run.putBack(bad), isTrue);
      expect(run.slips, 0);
      expect(run.caught, contains(M3CrossarmPickLines.caughtFlaw));
      run.next();
      expect(run.spotted, isEmpty);
      expect(run.rejected, isEmpty);
    });

    test('the coworker pushes only a part still on the rack', () {
      const r = M3CrossarmPickRound(slot: M3CrossarmPickSlot.clamp, want: M3CrossarmPickShape.wrapClamp, items: [
        M3CrossarmPickItem(id: 'g', shape: M3CrossarmPickShape.wrapClamp),
        M3CrossarmPickItem(id: 'r', shape: M3CrossarmPickShape.wrapClamp, flaw: M3CrossarmPickFlaw.rust),
        M3CrossarmPickItem(id: 'w', shape: M3CrossarmPickShape.boltClamp),
      ]);
      expect(m3CrossarmPickPushFor(r, {}, preferRust: true), M3CrossarmPickPush.rust);
      expect(m3CrossarmPickPushFor(r, {}, preferRust: false), M3CrossarmPickPush.anyClamp);
      expect(m3CrossarmPickPushFor(r, {'r'}, preferRust: true), M3CrossarmPickPush.anyClamp);
      expect(m3CrossarmPickPushed(r, M3CrossarmPickPush.anyClamp, {})!.id, 'w');
      expect(m3CrossarmPickPushed(r, M3CrossarmPickPush.rust, {})!.id, 'r');
      const arm = M3CrossarmPickRound(slot: M3CrossarmPickSlot.crossarm, want: M3CrossarmPickShape.vArm, items: [
        M3CrossarmPickItem(id: 'b', shape: M3CrossarmPickShape.vArm, flaw: M3CrossarmPickFlaw.bend),
        M3CrossarmPickItem(id: 'i', shape: M3CrossarmPickShape.iArm),
      ]);
      expect(m3CrossarmPickPushFor(arm, {}, preferRust: false), isNull, reason: '"any clamp" only on the clamp rack');
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) m3CrossarmPickDeal(math.Random(s))];
      expect(deals.map((d) => d.rounds.map((r) => r.slot.index).join()).toSet().length, 2);
      expect(deals.map((d) => d.docket.line).toSet(), M3CrossarmPickLine.values.toSet());
      expect(deals.map((d) => d.docket.pole).toSet(), M3CrossarmPickPole.values.toSet());
      expect(deals.map((d) => d.rounds.firstWhere((r) => r.noneFits).slot).toSet(), {M3CrossarmPickSlot.crossarm, M3CrossarmPickSlot.clamp});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1});
      expect(deals.map((d) => d.preferRust).toSet(), {true, false});
    });

    test('the close look: a fault shows only where the hand has been', () {
      for (final (shape, f) in [
        (M3CrossarmPickShape.vArm, M3CrossarmPickFlaw.rust),
        (M3CrossarmPickShape.channel, M3CrossarmPickFlaw.bend),
        (M3CrossarmPickShape.wrapClamp, M3CrossarmPickFlaw.rust),
        (M3CrossarmPickShape.nutsSpring, M3CrossarmPickFlaw.rust),
      ]) {
        final t = M3CrossarmPickItem(id: 'part7', shape: shape, flaw: f);
        final u = M3CrossarmPickPainter.flawU(t)!;
        expect(M3CrossarmPickPainter.flawSeen(t, {}), isFalse);
        expect(M3CrossarmPickPainter.flawSeen(t, {m3CrossarmPickBin(u)}), isTrue);
        expect(M3CrossarmPickPainter.flawSeen(t, null), isTrue);
        final far = {for (var i = 0; i < kM3CrossarmPickBins; i++) if ((i - m3CrossarmPickBin(u)).abs() > 2) i};
        expect(M3CrossarmPickPainter.flawSeen(t, far), isFalse, reason: f.name);
      }
      expect(M3CrossarmPickPainter.flawSeen(const M3CrossarmPickItem(id: 's', shape: M3CrossarmPickShape.iArm), null), isFalse);
      const s = Size(300, 120);
      expect(M3CrossarmPickPainter.uAt(s, 0), 0);
      expect(M3CrossarmPickPainter.uAt(s, 300), 1);
      expect(M3CrossarmPickPainter.uAt(s, M3CrossarmPickPainter.xAt(s, 0.4)), closeTo(0.4, 0.001));
    });

    test('reason and choice libraries: same length, big enough; his exit line is recorded', () {
      final rights = [
        for (final sh in M3CrossarmPickShape.values)
          if (sh != M3CrossarmPickShape.nutsBare) ...M3CrossarmPickLines.packRight(sh),
      ];
      expectSameLength('pack', {...rights, ...M3CrossarmPickLines.packWrong}.toList());
      for (final sh in M3CrossarmPickShape.values) {
        expectLibrary('pack ${sh.name}', M3CrossarmPickLines.packRight(sh), M3CrossarmPickLines.packWrong);
      }
      expectSameLength('hold', [...M3CrossarmPickLines.holdRight, ...M3CrossarmPickLines.holdWrong]);
      expectLibrary('hold', M3CrossarmPickLines.holdRight, M3CrossarmPickLines.holdWrong);
      for (final p in M3CrossarmPickPush.values) {
        final c = M3CrossarmPickLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull);
      }
      final keys = M3CrossarmPickMistakes.all.map((m) => m.key).toList();
      expect(keys.toSet().length, keys.length);
      for (final m in M3CrossarmPickMistakes.all) {
        expect(m.art, startsWith('assets/game/art/m3_crossarm_pick/'));
        expect(m.lessonPoint, isNotNull);
        expect(m.key, startsWith('3.3/crossarm_pick/'));
        expect(m.deadly, isFalse);
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

    Future<(ProviderContainer, M3CrossarmPickDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = m3CrossarmPickDeal(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M3CrossarmPickPage(ctx: _ctx, pack: m3CrossarmPickPack33, muted: true, seed: seed),
      )));
      await _pump(t, 1500);
      await waitIntro(t);
      return (c, deal);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    final parts = _label(M3CrossarmPickLines.partLabel);

    Future<void> lift(WidgetTester t, _Round r, _Item item) async {
      await t.tap(parts.at(r.items.indexOf(item)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(M3CrossarmPickLines.take), findsOneWidget);
    }

    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(M3CrossarmPickLines.handLabel));
      final g = await t.startGesture(Offset(box.left + 2, box.center.dy));
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    final late = _seed((d) => d.callRound == 1);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly in the store (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3CrossarmPickPage(ctx: _ctx, pack: m3CrossarmPickPack33, muted: true, seed: late)),
        ));
        await t.pump(const Duration(milliseconds: 100));
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
        debugPrint('PERF m3 crossarm ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(find.text(M3CrossarmPickLines.docket), findsOneWidget);
        expect(find.text(M3CrossarmPickLines.hold), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('guide first: no start button, a tap does not skip; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final deal = m3CrossarmPickDeal(math.Random(late));
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: M3CrossarmPickPage(ctx: _ctx, pack: m3CrossarmPickPack33, muted: true, seed: late)),
      ));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(360, 800));
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      final guide = t.getRect(find.byType(AiLinemanGuide).last);
      final heard = <String>{};
      for (var i = 0; i < 3; i++) {
        await t.tapAt(guide.bottomRight - const Offset(50, 50));
        await _pump(t, 200);
        final line = c.read(guideDirectorProvider).line;
        expect(line, contains(M3CrossarmPickLines.ask(deal.rounds.first.slot)));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, docket, faulty part to the drum, load, replace → pass', (t) async {
      final (c, deal) = await open(t, _seed((d) => d.callRound == 0));

      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [...M3CrossarmPickLines.coworkerClamp.right, ...M3CrossarmPickLines.coworkerRust.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      await t.tap(find.text(M3CrossarmPickLines.docket));
      await _pump(t, 500);
      expect(find.text(deal.docket.pole.nameBn), findsWidgets);
      expect(find.textContaining(deal.docket.feederBn), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.textContaining(deal.docket.feederBn), findsNothing);

      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        // Feel one faulty part: its fault shows, so it goes to the drum.
        await lift(t, r, _flawed(r));
        await slide(t);
        await t.tap(find.text(M3CrossarmPickLines.putBack));
        await _pump(t, 800);
        expect(find.text(M3CrossarmPickLines.rejected), findsOneWidget, reason: 'the faulty part goes to the drum, tagged');
        if (r.noneFits) {
          await t.tap(find.text(M3CrossarmPickLines.hold));
          await _pump(t, 3500);
          await _pickRight(t, M3CrossarmPickLines.holdRight);
          await _pump(t, 4000);
          continue;
        }
        await lift(t, r, _good(r));
        await slide(t);
        await t.tap(find.text(M3CrossarmPickLines.take));
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, M3CrossarmPickLines.packRight(r.want));
        await _pump(t, i == 2 ? 6000 : 3500);
      }

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.3/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.3/do/0'], greaterThan(0));
      expect(find.text(M3CrossarmPickLines.caughtCall), findsOneWidget);
      expect(find.text(M3CrossarmPickLines.caughtHold), findsOneWidget);
      expect(find.text(M3CrossarmPickLines.caughtNuts), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him loads his part — a slip card', (t) async {
      final seed = _seed((d) => d.callRound == 0);
      final (c, deal) = await open(t, seed);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final r = deal.rounds.first;
      final push = m3CrossarmPickPushFor(r, {}, preferRust: deal.preferRust)!;
      await waitChoiceDeck(t);
      final wrong = _onScreen(M3CrossarmPickLines.coworker(push).wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      final m = M3CrossarmPickMistakes.forPack(m3CrossarmPickPushed(r, push, {})!, r.want)!;
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(m.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a wrong type loaded is a slip card and stays on the rack', (t) async {
      final (c, deal) = await open(t, late);
      final r = deal.rounds[0];
      await lift(t, r, _wrongType(r));
      await t.tap(find.text(M3CrossarmPickLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(M3CrossarmPickLines.rejected), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.length, greaterThanOrEqualTo(1));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: a fast take cannot skip him — the take waits, he comes, the part goes back on its shelf', (t) async {
      final seed = _seed((d) =>
          d.callRound == 0 && !d.rounds.first.noneFits && m3CrossarmPickPushFor(d.rounds.first, {}, preferRust: d.preferRust) != null);
      final (c, deal) = await open(t, seed);
      final r = deal.rounds.first;
      // In hand before he turns up (he is due 1.2–2.4 s after the start).
      await lift(t, r, _good(r));
      // He never talks over the close look ...
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      // ... but loading is decisive: it waits for him, and he comes now.
      await t.tap(find.text(M3CrossarmPickLines.take));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(M3CrossarmPickLines.take), findsNothing, reason: 'the part went back on its shelf, nothing judged');
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, [...M3CrossarmPickLines.coworkerClamp.right, ...M3CrossarmPickLines.coworkerRust.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      // Now the take works.
      await lift(t, r, _good(r));
      await t.tap(find.text(M3CrossarmPickLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M3CrossarmPickLines.packRight(r.want));
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: on a rack with nothing he could push he does not come; he comes on the next part', (t) async {
      final seed = _seed((d) =>
          d.callRound == 0 &&
          d.rounds.first.slot == M3CrossarmPickSlot.crossarm &&
          !d.rounds.first.noneFits &&
          m3CrossarmPickPushFor(d.rounds.first, {}, preferRust: d.preferRust) == null);
      final (c, deal) = await open(t, seed);
      final r = deal.rounds.first;
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'no rust and no clamp here: his line would not fit');
      await lift(t, r, _good(r));
      await t.tap(find.text(M3CrossarmPickLines.take));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'the take is not held for a push that does not fit');
      await _pump(t, 3200);
      await _pickRight(t, M3CrossarmPickLines.packRight(r.want));
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the clamp rack always has a wrong clamp to push');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: sending his last push to the drum waits for him too — the part goes back on its shelf', (t) async {
      // A fast player who rubs the rusty part first and drums it would leave
      // him nothing to push (he never came on such a play before).
      final seed = _seed((d) =>
          d.callRound == 1 &&
          d.rounds[0].slot == M3CrossarmPickSlot.clamp &&
          !d.rounds[0].noneFits &&
          m3CrossarmPickPushFor(d.rounds[1], {}, preferRust: d.preferRust) == M3CrossarmPickPush.rust &&
          d.rounds[1].items.where((x) => x.flaw == M3CrossarmPickFlaw.rust).length == 1);
      final (c, deal) = await open(t, seed);
      final r0 = deal.rounds[0];
      await lift(t, r0, _good(r0));
      await t.tap(find.text(M3CrossarmPickLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M3CrossarmPickLines.packRight(r0.want));
      // Round 1 (he is armed now): the rusty part in hand at once, felt, put back.
      // (The new rack deals in first, ~0.7 s; he is due 1.2–2.4 s after the
      // next part comes up, and never while a part is in hand.)
      await _pump(t, 900);
      final r1 = deal.rounds[1];
      final rusty = r1.items.firstWhere((x) => x.flaw == M3CrossarmPickFlaw.rust);
      await lift(t, r1, rusty);
      await slide(t);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he never talks over the close look');
      await t.tap(find.text(M3CrossarmPickLines.putBack));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the put back waits for him: his last push');
      expect(find.text(M3CrossarmPickLines.rejected), findsNothing, reason: 'back on its shelf, not in the drum yet');
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, M3CrossarmPickLines.coworkerRust.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      // Now it goes to the drum as usual.
      await lift(t, r1, rusty);
      await t.tap(find.text(M3CrossarmPickLines.putBack));
      await _pump(t, 600);
      expect(find.text(M3CrossarmPickLines.rejected), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    // The praise window (tableBusy) here always lies inside _run.shown: both
    // right moves set it before putOnTable, so this guards the behaviour, not
    // which of the two flags holds it.
    testWidgets('praise window: taps on the replace button or the docket do nothing until the reason', (t) async {
      final (c, deal) = await open(t, _seed((d) => d.callRound == 1 && !d.rounds.first.noneFits));
      final r = deal.rounds.first;
      final holdAt = t.getCenter(find.text(M3CrossarmPickLines.hold));
      final docketAt = t.getCenter(find.text(M3CrossarmPickLines.docket));
      await lift(t, r, _good(r));
      await t.tap(find.text(M3CrossarmPickLines.take));
      await t.pump(const Duration(milliseconds: 80));
      for (var i = 0; i < 3; i++) {
        await t.tapAt(holdAt);
        await t.tapAt(docketAt);
        await t.pump(const Duration(milliseconds: 120));
      }
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.textContaining(deal.docket.feederBn), findsNothing, reason: 'the docket did not open');
      await _pickRight(t, M3CrossarmPickLines.packRight(r.want));
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('gesture hints: a sweep over the rack and the replace button; a nudge along the part in hand; then a sweep over put back / load', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final (c, deal) = await open(t, late);
      final r = deal.rounds.first;
      final hand = find.byKey(const ValueKey('gesture-hint'));
      IdleHintState frame() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(hand, findsOneWidget);
      expect(frame().debugOptions, hasLength(r.items.length + 1), reason: 'every part on the rack and the replace button, alike');
      await lift(t, r, _flawed(r));
      expect(hand, findsNothing, reason: 'a touch hides it');
      await _pump(t, 9000);
      expect(hand, findsOneWidget);
      expect(frame().debugOptions, isEmpty, reason: 'a short drag nudge, not a sweep');
      await slide(t);
      await _pump(t, 9000);
      expect(hand, findsOneWidget);
      expect(frame().debugOptions, hasLength(2), reason: 'put back and load, alike');
      await t.tap(find.text(M3CrossarmPickLines.putBack));
      await _pump(t, 400);
      expect(hand, findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, deal) = await open(t, _seed((d) => d.callRound == 1 && !d.rounds.first.noneFits));
      expect(deal.rounds.first.noneFits, isFalse);
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(M3CrossarmPickLines.hold));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(M3CrossarmPickLines.hold));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('3.3/do/0'), isTrue);
      expect(s.rungProgress['3.3/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
