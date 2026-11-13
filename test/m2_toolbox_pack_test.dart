// Lesson 2.1, কাজ 1 (টুলবক্স সাজাও): rules of the pegboard, the close look (a
// fault shows only where the hand has been; the tester on the live point),
// deal variety, fair reason libraries, and the level in the shell (idle perf;
// guide first; a full clean flow with the docket, a plain tool set aside, the
// slide, the live-point test, the reasons, the coworker and the replacement;
// a slip card; a deadly freeze; three slips; the coworker on a fast play, his
// line fitting the moment, no tap skipping him; the praise window; the
// gesture hints; putting back tells nothing, setting a sound tool aside costs
// a slip).
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
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_toolbox_pack.dart';
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
  rungId: '2.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.1',
  lessonTitleBn: '',
  ladderStep: 32,
  doIndex: 1,
  doCount: 2,
);

TbTool _good(TbRound r) => r.tools.firstWhere((x) => x.sound);
TbTool _plain(TbRound r) => r.tools.firstWhere((x) => x.plain);
TbTool _flawed(TbRound r) => r.tools.firstWhere((x) => x.insulated && x.flaw != TbFlaw.none);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seedCalling(int round, {bool? tape}) {
  for (var s = 0;; s++) {
    final d = dealToolbox(math.Random(s));
    if (d.callRound == round && (tape == null || d.preferTape == tape)) return s;
  }
}

Finder _peekSaying(String line) => find.byWidgetPredicate((w) => w is CoworkerPeek && w.lineBn == line);

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
  await confirmChoice(t);
  // A right reason zooms and waits for এগিয়ে যান; his deck just closes.
  await tapReasonProceed(t);
}

void main() {
  group('rules', () {
    test('every deal: pliers first, all four tools once; one stripper/screwdriver round has no good tool', () {
      for (var s = 0; s < 80; s++) {
        final d = dealToolbox(math.Random(s));
        expect(d.rounds.length, 4);
        expect(d.rounds.first.kind, TbKind.pliers);
        expect(d.rounds.map((r) => r.kind).toSet(), TbKind.values.toSet());
        final holds = d.rounds.where((r) => r.noneFits).toList();
        expect(holds, hasLength(1));
        expect(holds.single.kind, isIn([TbKind.stripper, TbKind.screwdriver]));
        for (final r in d.rounds) {
          if (!r.noneFits) expect(r.tools.where((x) => x.sound).length, 1);
          if (r.kind == TbKind.tester) {
            expect(r.tools.any((x) => x.plain), isFalse);
            expect(r.tools.where((x) => x.flaw == TbFlaw.deadNeon), isNotEmpty);
          } else {
            expect(r.tools.where((x) => x.plain).length, 1, reason: 'one plain, unmarked tool on every board');
          }
          for (final x in r.tools) {
            expect(x.flaw == TbFlaw.none || tbFlawsOf(r.kind).contains(x.flaw), isTrue);
          }
        }
        expect(d.rounds[d.callRound].kind, isNot(TbKind.tester));
      }
    });

    test('a clean play: each tool waits for its reason; the tester only after the live-point test', () {
      final run = TbRun(dealToolbox(math.Random(3)));
      for (var i = 0; i < 4; i++) {
        final r = run.current;
        if (r.noneFits) {
          expect(run.holdJob().verdict, TbVerdict.right);
        } else {
          final g = _good(r);
          if (g.kind == TbKind.tester) expect(run.test(g), isTrue);
          expect(run.pack(g).verdict, TbVerdict.right);
          expect(run.packed[i], g);
        }
        expect(run.shown, isTrue);
        expect(run.round, i, reason: 'moves on only after the reason');
        expect(run.holdJob().verdict, TbVerdict.slip, reason: 'nothing more on a decided tool');
        run.next();
      }
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.packed.length, 3);
      expect(run.caught, containsAll([TbLines.caughtMark, TbLines.caughtTest, TbLines.caughtHold]));
    });

    test('a plain tool packed is deadly', () {
      final a = TbRun(dealToolbox(math.Random(1)));
      final o = a.pack(_plain(a.current));
      expect(o.verdict, TbVerdict.deadly);
      expect(o.mistake!.deadly, isTrue);
      expect(o.mistake!.key, TbMistakes.noMark(TbKind.pliers).key);
      expect(a.ended, isTrue);
    });

    test('a damaged tool packed is a slip and goes aside; an untested tester is a slip and stays; replacing when a good one hangs is a slip', () {
      final run = TbRun(dealToolbox(math.Random(5)));
      final bad = _flawed(run.current);
      final o = run.pack(bad);
      expect(o.verdict, TbVerdict.slip);
      expect(o.mistake!.key, TbMistakes.forFlaw(bad).key);
      expect(o.mistake!.deadly, isFalse);
      expect(run.rejected, contains(bad.id));
      expect(run.holdJob().mistake, TbMistakes.heldWhenRight);
      expect(run.slips, 2);

      final b = TbRun(dealToolbox(math.Random(5)));
      b.round = b.deal.rounds.indexWhere((r) => r.kind == TbKind.tester);
      final g = _good(b.current);
      expect(b.pack(g).mistake, TbMistakes.untested);
      expect(b.rejected, isNot(contains(g.id)), reason: 'a good tester goes back on the board');
      expect(b.test(g), isTrue);
      expect(b.pack(g).verdict, TbVerdict.right);
    });

    test('setting aside is a decision: a plain or damaged tool goes in the crate; a sound one is a wrong flag (a slip) and stays', () {
      final run = TbRun(dealToolbox(math.Random(5)));
      final r = run.current;
      final good = _good(r);
      final o = run.setAside(good);
      expect(o.verdict, TbVerdict.slip, reason: 'a wrong flag costs a slip');
      expect(o.mistake!.key, TbMistakes.asideSound(r.kind).key);
      expect(o.mistake!.deadly, isFalse);
      expect(run.rejected, isNot(contains(good.id)), reason: 'the good tool goes back on the board');
      expect(run.slips, 1);
      expect(run.setAside(_plain(r)).verdict, TbVerdict.right);
      expect(run.setAside(_flawed(r)).verdict, TbVerdict.right, reason: 'the decision counts, found or not');
      expect(run.rejected, containsAll([_plain(r).id, _flawed(r).id]));
      expect(run.setAside(_plain(r)).mistake, isNull, reason: 'already in the crate: nothing');
      expect(run.slips, 1);
      expect(run.caught, containsAll([TbLines.caughtPlain, TbLines.caughtFlaw]));
      expect(run.pack(good).verdict, TbVerdict.right);
      run.next();
      expect(run.spotted, isEmpty);
      expect(run.rejected, isEmpty);
    });

    test('a dead tester is found only by the live-point test; a good tester set aside is a slip', () {
      final run = TbRun(dealToolbox(math.Random(9)));
      run.round = run.deal.rounds.indexWhere((r) => r.kind == TbKind.tester);
      final dead = run.current.tools.firstWhere((x) => x.flaw == TbFlaw.deadNeon);
      run.spot(dead);
      expect(run.spotted, isEmpty, reason: 'the eye cannot see a dead neon');
      expect(run.test(dead), isFalse);
      expect(run.spotted, contains(dead.id));
      expect(run.setAside(dead).verdict, TbVerdict.right);
      expect(ToolPainter.flawSeen(dead, null), isFalse);
      final good = _good(run.current);
      expect(run.setAside(good).mistake!.key, TbMistakes.asideSound(TbKind.tester).key);
    });

    test('the coworker pushes only a tool still on the board', () {
      const r = TbRound(kind: TbKind.pliers, tools: [
        TbTool(id: 'g', kind: TbKind.pliers),
        TbTool(id: 'c', kind: TbKind.pliers, flaw: TbFlaw.crack),
        TbTool(id: 'p', kind: TbKind.pliers, insulated: false),
      ]);
      expect(tbPushFor(r, {}, preferTape: true), TbPush.tape);
      expect(tbPushFor(r, {}, preferTape: false), TbPush.gloves);
      expect(tbPushFor(r, {'p'}, preferTape: false), TbPush.tape);
      expect(tbPushFor(r, {'c'}, preferTape: true), TbPush.gloves);
      expect(tbPushFor(r, {'c', 'p'}, preferTape: true), isNull);
      expect(tbPushedTool(r, TbPush.tape, {})!.id, 'c');
      expect(tbPushedTool(r, TbPush.gloves, {})!.id, 'p');
      const blunt = TbRound(kind: TbKind.stripper, tools: [TbTool(id: 'b', kind: TbKind.stripper, flaw: TbFlaw.blunt)]);
      expect(tbPushFor(blunt, {}, preferTape: true), isNull, reason: 'tape is for a damaged handle only');
      const tester = TbRound(kind: TbKind.tester, tools: [TbTool(id: 't', kind: TbKind.tester, flaw: TbFlaw.deadNeon)]);
      expect(tbPushFor(tester, {}, preferTape: true), isNull);
    });

    test('his line fits the moment: tape only for a damaged handle in hand whose fault was found', () {
      const r = TbRound(kind: TbKind.pliers, tools: [
        TbTool(id: 'g', kind: TbKind.pliers),
        TbTool(id: 'c', kind: TbKind.pliers, flaw: TbFlaw.crack),
        TbTool(id: 'p', kind: TbKind.pliers, insulated: false),
      ]);
      final good = r.tools[0], cracked = r.tools[1], plain = r.tools[2];
      // The dealt tape push waits while the cracked one still hangs unfound.
      expect(tbPushNow(r, held: null, rejected: {}, spotted: {}, preferTape: true), isNull);
      expect(tbPushNow(r, held: good, rejected: {}, spotted: {}, preferTape: true), isNull);
      // A decisive control waiting for him: what fits now (the plain one is there).
      expect(tbPushNow(r, held: good, rejected: {}, spotted: {}, preferTape: true, forced: true), TbPush.gloves);
      // In hand but not found: he never names a fault the player has not seen.
      expect(tbPushNow(r, held: cracked, rejected: {}, spotted: {}, preferTape: true, forced: true), TbPush.gloves);
      expect(tbPushNow(r, held: cracked, rejected: {'p'}, spotted: {}, preferTape: true, forced: true), isNull);
      // Found in hand: the tape push.
      expect(tbPushNow(r, held: cracked, rejected: {}, spotted: {'c'}, preferTape: true), TbPush.tape);
      expect(tbPushNow(r, held: cracked, rejected: {'p'}, spotted: {'c'}, preferTape: false), TbPush.tape);
      // The gloves push while the plain tool is still there; nothing once it is aside.
      expect(tbPushNow(r, held: null, rejected: {}, spotted: {}, preferTape: false), TbPush.gloves);
      expect(tbPushNow(r, held: plain, rejected: {}, spotted: {}, preferTape: false), TbPush.gloves);
      expect(tbPushNow(r, held: null, rejected: {'p'}, spotted: {}, preferTape: false), isNull);
      expect(tbPushNow(r, held: null, rejected: {'p', 'c'}, spotted: {'c'}, preferTape: true, forced: true), isNull);
    });

    test('English digits on everything the scene shows', () {
      final bnDigit = RegExp('[০-৯]');
      final shown = [
        ...TbLines.times,
        ...TbLines.jobs,
        ...TbLines.feeders,
        for (final k in TbKind.values) ...[k.mark, k.nameBn, ...TbLines.packRight(k), ...TbLines.packWrong(k), TbLines.ask(k)],
        ...TbLines.holdRight,
        ...TbLines.holdWrong,
        for (final p in TbPush.values) ...[TbLines.coworker(p).line, ...TbLines.coworker(p).right, ...TbLines.coworker(p).wrong, ...TbLines.coworker(p).asks],
        TbLines.intro,
        TbLines.callHeld,
        TbLines.callHeldTape,
        TbLines.caughtMark,
        for (final m in TbMistakes.all) m.textBn,
      ];
      for (final l in shown) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) dealToolbox(math.Random(s))];
      expect(deals.map((d) => d.rounds.map((r) => r.kind.index).join()).toSet().length, greaterThan(3));
      expect(deals.map((d) => _flawed(d.rounds.first).flaw).toSet(), {TbFlaw.crack, TbFlaw.cut, TbFlaw.burn});
      expect(deals.map((d) => d.rounds.firstWhere((r) => r.noneFits).kind).toSet(), {TbKind.stripper, TbKind.screwdriver});
      expect(deals.map((d) => d.callRound).toSet().length, greaterThan(2));
      expect(deals.map((d) => d.preferTape).toSet(), {true, false});
      expect(deals.map((d) => d.docket.jobBn).toSet().length, greaterThan(1));
    });

    test('the close look: a fault shows only where the hand has been', () {
      for (final f in [TbFlaw.crack, TbFlaw.cut, TbFlaw.burn, TbFlaw.blunt, TbFlaw.bentTip]) {
        final t = TbTool(id: 'x1', kind: f == TbFlaw.bentTip ? TbKind.screwdriver : TbKind.stripper, flaw: f);
        final u = ToolPainter.flawU(t)!;
        expect(ToolPainter.flawSeen(t, {}), isFalse);
        expect(ToolPainter.flawSeen(t, {toolBin(u)}), isTrue);
        expect(ToolPainter.flawSeen(t, null), isTrue);
        final far = {for (var i = 0; i < kToolBins; i++) if ((i - toolBin(u)).abs() > 2) i};
        expect(ToolPainter.flawSeen(t, far), isFalse, reason: f.name);
      }
      const sound = TbTool(id: 's', kind: TbKind.pliers);
      expect(ToolPainter.flawSeen(sound, null), isFalse);
      const s = Size(300, 120);
      expect(ToolPainter.uAt(s, 0), 0);
      expect(ToolPainter.uAt(s, 300), 1);
      expect(ToolPainter.uAt(s, ToolPainter.xAt(s, 0.4)), closeTo(0.4, 0.001));
    });

    test('reason and choice libraries: same length, big enough; his exit line is recorded', () {
      expectSameLength('pack', [for (final k in TbKind.values) ...TbLines.packRight(k), ...TbLines.packWrong(TbKind.tester)]);
      for (final k in TbKind.values) {
        expectLibrary('pack ${k.name}', TbLines.packRight(k), TbLines.packWrong(k));
      }
      expect(TbLines.packWrong(TbKind.pliers), isNot(contains(TbLines.testerMyth)));
      expectSameLength('hold', [...TbLines.holdRight, ...TbLines.holdWrong]);
      expectLibrary('hold', TbLines.holdRight, TbLines.holdWrong);
      for (final p in TbPush.values) {
        final c = TbLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull);
      }
      // Every mistake a play can show has a real picture and a lesson point.
      final ms = [
        for (final k in TbKind.values) ...[TbMistakes.noMark(k), TbMistakes.tape(k)],
        for (final f in [TbFlaw.crack, TbFlaw.cut, TbFlaw.burn]) TbMistakes.handle(TbKind.pliers, f),
        TbMistakes.blunt,
        TbMistakes.bentTip,
        TbMistakes.deadNeon,
        TbMistakes.untested,
        TbMistakes.heldWhenRight,
      ];
      for (final m in ms) {
        expect(m.art, startsWith('assets/safety/library/tools/'));
        expect(m.lessonPoint, isNotNull);
        expect(m.key, startsWith('2.1/'));
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

    Future<(ProviderContainer, TbDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealToolbox(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2ToolboxPage(ctx: _ctx, pack: m2ToolboxPack21, muted: true, seed: seed),
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

    final tools = _label(TbLines.toolLabel);

    Future<void> lift(WidgetTester t, TbRound r, TbTool tool) async {
      await t.tap(tools.at(r.tools.indexOf(tool)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(TbLines.take), findsOneWidget);
    }

    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(TbLines.handLabel));
      final g = await t.startGesture(Offset(box.left + 2, box.center.dy));
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly in the store (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2ToolboxPage(ctx: _ctx, pack: m2ToolboxPack21, muted: true, seed: _seedCalling(3))),
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
        debugPrint('PERF m2 toolbox ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(find.text(TbLines.docket), findsOneWidget);
        expect(find.text(TbLines.hold), findsOneWidget);
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
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: M2ToolboxPage(ctx: _ctx, pack: m2ToolboxPack21, muted: true, seed: _seedCalling(3))),
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
        expect(line, contains(TbLines.ask(TbKind.pliers)));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, docket, plain tool aside, slide and pack, test the tester, replace → pass', (t) async {
      final (c, deal) = await open(t, _seedCalling(0, tape: false));

      await _pump(t, 3500);
      expect(_peekSaying(TbLines.coworkerGloves.line), findsOneWidget, reason: 'the plain tool hangs: the gloves push');
      await _pickRight(t, TbLines.coworkerGloves.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      await t.tap(find.text(TbLines.docket));
      await _pump(t, 500);
      expect(find.text('${TbLines.lineBn} · ${deal.docket.jobBn}'), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text('${TbLines.lineBn} · ${deal.docket.jobBn}'), findsNothing);

      for (var i = 0; i < 4; i++) {
        final r = deal.rounds[i];
        if (r.kind != TbKind.tester) {
          await lift(t, r, _plain(r));
          expect(find.text(TbKind.pliers.mark), findsNothing, reason: 'no mark on a plain tool');
          await t.tap(find.text(TbLines.aside));
          await _pump(t, 800);
          expect(find.text(TbLines.rejected), findsOneWidget, reason: 'the plain tool goes into the crate, tagged');
        }
        if (r.noneFits) {
          // Feel one damaged tool: its fault shows, so it goes aside too.
          await lift(t, r, _flawed(r));
          await slide(t);
          await t.tap(find.text(TbLines.aside));
          await _pump(t, 800);
          expect(find.text(TbLines.rejected), findsNWidgets(2));
          await t.tap(find.text(TbLines.hold));
          await _pump(t, 3500);
          await _pickRight(t, TbLines.holdRight);
          await _pump(t, i == 3 ? 6000 : 4000);
          continue;
        }
        await lift(t, r, _good(r));
        expect(find.text(r.kind.mark), findsOneWidget, reason: 'the mark is readable up close');
        await slide(t);
        if (r.kind == TbKind.tester) {
          await t.tap(_label(TbLines.liveLabel));
          await _pump(t, 300);
        }
        await t.tap(find.text(TbLines.take));
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, TbLines.packRight(r.kind));
        await _pump(t, i == 3 ? 6000 : 3500);
      }

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.1/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.1/do/0'], greaterThan(0));
      expect(find.text(TbLines.caughtCall), findsOneWidget);
      expect(find.text(TbLines.caughtHold), findsOneWidget);
      expect(find.text(TbLines.caughtTest), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him is deadly (freeze, then the card)', (t) async {
      final seed = _seedCalling(0, tape: false);
      final (c, _) = await open(t, seed);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await waitChoiceDeck(t);
      const push = TbPush.gloves;
      final wrong = _onScreen(TbLines.coworker(push).wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      final m = TbMistakes.noMark(TbKind.pliers);
      expect(find.text(m.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker comes even on a fast play: packing waits for him, then works', (t) async {
      // The dealt push is the tape: he waits for a found handle, so a player
      // who packs the good tool at once would never meet him without the hold.
      final (c, deal) = await open(t, _seedCalling(0, tape: true));
      final r = deal.rounds.first;
      await lift(t, r, _good(r));
      await t.tap(find.text(TbLines.take));
      await t.pump(const Duration(milliseconds: 300));
      expect(_peekSaying(TbLines.coworkerGloves.line), findsOneWidget, reason: 'nothing found in hand: the gloves push, never the tape');
      expect(find.text(TbLines.take), findsOneWidget, reason: 'the tool is still in hand, not packed');
      await _pickRight(t, TbLines.coworkerGloves.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(find.text(TbLines.take));
      await _pump(t, 3500);
      await _pickRight(t, TbLines.packRight(TbKind.pliers));
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(find.byType(MistakeCard), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('his tape push comes only once the hand has found the damaged handle; refused, it goes aside', (t) async {
      final (c, deal) = await open(t, _seedCalling(0, tape: true));
      final r = deal.rounds.first;
      await lift(t, r, _flawed(r));
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he never names a fault the player has not seen');
      await slide(t);
      await _pump(t, 2500);
      expect(_peekSaying(TbLines.coworkerTape.line), findsOneWidget);
      await _pickRight(t, TbLines.coworkerTape.right);
      await _pump(t, 2500);
      await t.tap(find.text(TbLines.aside));
      await _pump(t, 800);
      expect(find.text(TbLines.rejected), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('a tap on a tool while he talks neither skips nor refuses him', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final (c, deal) = await open(t, _seedCalling(0, tape: false));
      for (var i = 0; i < 80 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: his line alone');
      final r = deal.rounds.first;
      await t.tap(tools.at(r.tools.indexOf(_good(r))), warnIfMissed: false);
      await _pump(t, 400);
      expect(find.text(TbLines.take), findsNothing, reason: 'no tool comes off the board while he talks');
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he is still there');
      await _pickRight(t, TbLines.coworkerGloves.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('the praise window takes no touch: the docket stays on its nail', (t) async {
      final (c, deal) = await open(t, _seedCalling(3));
      final r = deal.rounds.first;
      await lift(t, r, _good(r));
      await t.tap(find.text(TbLines.take));
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(find.text(TbLines.docket), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('docket-zoom')), findsNothing);
      await t.tap(tools.at(r.tools.indexOf(_plain(r))), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.text(TbLines.take), findsNothing, reason: 'no tool comes off the board in the praise window');
      await _pump(t, 3000);
      await _pickRight(t, TbLines.packRight(TbKind.pliers));
      await _pump(t, 3000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('gesture hints: a sweep over the board, a slide nudge in hand, then a sweep over the controls', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final (c, deal) = await open(t, _seedCalling(3));
      final scene = find.byWidgetPredicate((w) => w is IdleHint && w.controller != null);
      expect(scene, findsOneWidget);
      await _pump(t, 9000);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget);
      final r = deal.rounds.first;
      expect(t.state<IdleHintState>(scene).debugOptions, hasLength(r.tools.length + 1), reason: 'every tool and the replacement button, never one');
      await lift(t, r, _good(r));
      expect(find.byKey(const ValueKey('gesture-hint')), findsNothing, reason: 'a touch hides it');
      await _pump(t, 9000);
      expect(t.state<IdleHintState>(scene).showing, isTrue);
      expect(t.state<IdleHintState>(scene).debugOptions, isEmpty, reason: 'a slide nudge, not a sweep');
      await slide(t);
      await _pump(t, 9000);
      expect(t.state<IdleHintState>(scene).showing, isTrue);
      expect(t.state<IdleHintState>(scene).debugOptions, hasLength(3), reason: 'put back, set aside and pack alike');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a damaged tool packed is a slip card and goes aside; a plain one freezes first, then the card', (t) async {
      final (c, deal) = await open(t, _seedCalling(3));
      final r = deal.rounds[0];
      await lift(t, r, _flawed(r));
      await t.tap(find.text(TbLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(TbLines.rejected), findsOneWidget);

      await lift(t, r, _plain(r));
      await t.tap(find.text(TbLines.take));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the scene freezes first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(TbMistakes.noMark(TbKind.pliers).textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.length, greaterThanOrEqualTo(1));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('putting back tells nothing: a sound and a damaged tool, felt all over, both go back on the board the same way', (t) async {
      final (c, deal) = await open(t, _seedCalling(3));
      final r = deal.rounds.first;
      final heard = <String>[];
      for (final tool in [_good(r), _flawed(r)]) {
        await lift(t, r, tool);
        await slide(t);
        await t.tap(find.text(TbLines.putBack));
        await _pump(t, 800);
        expect(find.text(TbLines.take), findsNothing);
        expect(find.text(TbLines.rejected), findsNothing, reason: 'nothing goes into the crate on a put-back');
        expect(find.text(MistakeLines.slipHead), findsNothing);
        heard.add(c.read(guideDirectorProvider).line);
      }
      expect(heard.toSet(), hasLength(1), reason: 'the same reply for either');
      expect(heard.first, contains(TbLines.ask(TbKind.pliers)));
      // Both still hang: either can be lifted again.
      await lift(t, r, _flawed(r));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('setting a sound tool aside is a wrong flag: a slip card, and it goes back on the board', (t) async {
      final (c, deal) = await open(t, _seedCalling(3));
      final r = deal.rounds.first;
      await lift(t, r, _good(r));
      await t.tap(find.text(TbLines.aside));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(TbMistakes.asideSound(TbKind.pliers).textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((e) => e.key), contains(TbMistakes.asideSound(TbKind.pliers).key));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(TbLines.rejected), findsNothing, reason: 'the good tool is not in the crate');
      await lift(t, r, _good(r));
      await t.tap(find.text(TbLines.take));
      await _pump(t, 3500);
      await _pickRight(t, TbLines.packRight(TbKind.pliers));
      await _pump(t, 3000);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, _) = await open(t, _seedCalling(3));
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(TbLines.hold));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(TbLines.hold));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.1/do/0'), isTrue);
      expect(s.rungProgress['2.1/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
