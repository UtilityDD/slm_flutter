// Lesson 2.6, কাজ 1 (সঠিক ছুরি, সঠিক প্রস্তুতি): rules of the jobs (gloves,
// test, tool for the cable, blade check, hold on LIVE), the lens (a flaw shows
// only where it has been), deal variety, fair reason libraries that fit the
// cable, the coworker's pushes, and the level in the shell (idle perf; guide
// first; a full clean flow; a slip card; a deadly freeze; three slips).
// Audit 2026-11-11: he comes even on a fast play (the tester / a tool wait for
// him, his push fits the tap); no tool named in the close-up; rejecting a sound
// tool costs a slip, putting back tells nothing; the praise window takes no
// tap; gesture hints sweep, never point.
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_skin_tools.dart';
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
  rungId: '2.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

/// The level's own mistake art is a new folder the director adds to
/// pubspec.yaml; until then the test reads it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m2_skin_tools/')) {
      final bytes = File(key).readAsBytesSync();
      return ByteData.sublistView(bytes);
    }
    return rootBundle.load(key);
  }
}

SkinItem _right(SkinJob j) => j.items.firstWhere((x) => x.tool == j.cable.rightTool && x.flaw == BladeFlaw.none);
int _liveAt(SkinDeal d) => d.jobs.indexWhere((j) => j.live);

Set<String> _words(String s) => s.split(RegExp(r'[\s,—!?।\-]+')).where((w) => w.isNotEmpty).toSet();

/// No word on every right card is missing from every wrong card.
void _expectNoMarkWord(String name, List<String> right, List<String> wrong) {
  final onWrong = {for (final x in wrong) ..._words(x)};
  final common = right.map(_words).reduce((a, b) => a.intersection(b));
  expect(common.difference(onWrong), isEmpty, reason: '$name: these words mark the right card');
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seedWhere(bool Function(SkinDeal d) ok) {
  for (var s = 0;; s++) {
    if (ok(dealSkin(math.Random(s)))) return s;
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
  await confirmChoice(t);
  // A right reason zooms and waits for এগিয়ে যান; his deck closes by itself.
  await tapReasonProceed(t);
}

void main() {
  group('rules', () {
    test('every deal: three cables, one sound right tool each, a kitchen knife, never live first', () {
      for (var s = 0; s < 80; s++) {
        final d = dealSkin(math.Random(s));
        expect(d.jobs.map((j) => j.cable).toSet(), SkinCable.values.toSet());
        expect(d.jobs.first.live, isFalse);
        expect(d.jobs.where((j) => j.live).length, lessThanOrEqualTo(1));
        expect(d.jobs.any((j) => j.items.any((x) => x.flaw != BladeFlaw.none)), isTrue, reason: 'a blade to catch every play');
        for (final j in d.jobs) {
          expect(j.items.length, inInclusiveRange(3, 4));
          expect(j.items.where((x) => x.tool == j.cable.rightTool && x.flaw == BladeFlaw.none).length, 1);
          expect(j.items.where((x) => x.tool == SkinTool.kitchen).length, 1);
          for (final x in j.items) {
            if (x.flaw != BladeFlaw.none) expect(x.tool, j.cable.rightTool, reason: 'flaws only on the right tool\'s twin');
            if (x.tool != SkinTool.kitchen && x.tool != j.cable.rightTool) {
              expect(x.tool, SkinTool.stripper, reason: 'the only decoy: the wire stripper on a big cable');
              expect(j.cable, isNot(SkinCable.wire));
            }
          }
          expect(j.items.map((x) => x.id).toSet().length, j.items.length);
        }
        expect(d.callRound, inInclusiveRange(0, 2));
      }
    });

    test('a clean play: gloves, test, the right tool (or hold on LIVE) — each waits for its reason', () {
      final run = SkinRun(dealSkin(math.Random(_seedWhere((d) => _liveAt(d) == 2))));
      run.wearGloves();
      for (var i = 0; i < 2; i++) {
        expect(run.test(), isFalse);
        expect(run.take(_right(run.current)).verdict, SkinVerdict.right);
        expect(run.shown, isTrue);
        expect(run.round, i, reason: 'the job moves on only after the reason');
        run.next();
        expect(run.tested, isFalse, reason: 'every job is tested afresh');
      }
      expect(run.test(), isTrue);
      expect(run.holdJob().verdict, SkinVerdict.right);
      run.next();
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([SkinLines.caughtGloves, SkinLines.caughtTest, SkinLines.caughtTool, SkinLines.caughtHold]));
    });

    test('cutting a live cable is deadly, tested or not', () {
      final seed = _seedWhere((d) => _liveAt(d) == 1);
      final a = SkinRun(dealSkin(math.Random(seed)))..round = 1;
      expect(a.take(_right(a.current)).mistake, SkinMistakes.liveCut);
      expect(a.ended, isTrue);
      final b = SkinRun(dealSkin(math.Random(seed)))
        ..round = 1
        ..wearGloves();
      expect(b.test(), isTrue);
      expect(b.take(_right(b.current)).verdict, SkinVerdict.deadly);
    });

    test('slips: untested, kitchen knife, wrong size, bad blade, no gloves; the tool goes aside where it shows', () {
      final seed = _seedWhere((d) => d.jobs.first.items.any((x) => x.flaw != BladeFlaw.none));
      final run = SkinRun(dealSkin(math.Random(seed)));
      final j = run.current;
      expect(run.take(_right(j)).mistake, SkinMistakes.untested);
      expect(run.rejected, isEmpty, reason: 'the tool goes back; the cable must be tested');
      run.test();
      final k = run.take(j.items.firstWhere((x) => x.tool == SkinTool.kitchen));
      expect(k.mistake, SkinMistakes.kitchen);
      expect(k.aside, isTrue);
      final twin = j.items.firstWhere((x) => x.flaw != BladeFlaw.none);
      expect(run.take(twin).mistake, twin.flaw == BladeFlaw.blunt ? SkinMistakes.blunt : SkinMistakes.dirty);
      expect(run.rejected, contains(twin.id));
      expect(run.take(_right(j)).mistake, SkinMistakes.noGloves);
      expect(run.slips, 4);
      run.wearGloves();
      expect(run.take(_right(j)).verdict, SkinVerdict.right);

      final ab = SkinRun(dealSkin(math.Random(_seedWhere((d) => d.jobs.first.cable == SkinCable.ab))))
        ..wearGloves()
        ..test();
      expect(ab.take(ab.current.items.firstWhere((x) => x.tool == SkinTool.stripper)).mistake, SkinMistakes.mismatch);
    });

    test('rejecting: the kitchen knife, the wrong size and a bad blade go aside for free; a sound right tool is a slip', () {
      final seed = _seedWhere((d) => d.jobs.first.cable == SkinCable.ab && d.jobs.first.items.any((x) => x.flaw != BladeFlaw.none));
      final run = SkinRun(dealSkin(math.Random(seed)));
      final j = run.current;
      final twin = j.items.firstWhere((x) => x.flaw != BladeFlaw.none);
      final good = run.reject(_right(j));
      expect(good.mistake, SkinMistakes.goodRejected, reason: 'flagging everything is not free');
      expect(good.aside, isFalse);
      expect(run.rejected, isNot(contains(_right(j).id)), reason: 'the sound tool stays in the roll');
      expect(run.slips, 1);
      expect(run.reject(j.items.firstWhere((x) => x.tool == SkinTool.kitchen)).aside, isTrue);
      expect(run.reject(j.items.firstWhere((x) => x.tool == SkinTool.stripper)).aside, isTrue);
      run.spot(_right(j));
      expect(run.spotted, isEmpty);
      run.spot(twin);
      expect(run.reject(twin).aside, isTrue);
      expect(run.rejected.length, 3);
      expect(run.slips, 1);
      expect(run.caught, containsAll([SkinLines.caughtKnife, SkinLines.caughtTool, SkinLines.caughtBlade]));
      expect(run.take(_right(j)).mistake, SkinMistakes.untested, reason: 'the job goes on after a wrong reject');
    });

    test('a bad blade set aside unseen goes aside but is not counted as caught', () {
      final seed = _seedWhere((d) => d.jobs.first.items.any((x) => x.flaw != BladeFlaw.none));
      final run = SkinRun(dealSkin(math.Random(seed)));
      final twin = run.current.items.firstWhere((x) => x.flaw != BladeFlaw.none);
      expect(run.reject(twin).aside, isTrue);
      expect(run.slips, 0);
      expect(run.caught, isNot(contains(SkinLines.caughtBlade)));
    });

    test('hold: nothing before the test; a slip when the tester showed 0 V', () {
      final run = SkinRun(dealSkin(math.Random(1)));
      expect(run.holdJob().mistake, isNull);
      expect(run.slips, 0);
      run.test();
      expect(run.holdJob().mistake, SkinMistakes.heldWhenDead);
      expect(run.slips, 1);
    });

    test('listening to him: the teeth are a slip; the skipped test is deadly on the live job, a slip on a dead one', () {
      final run = SkinRun(dealSkin(math.Random(_seedWhere((d) => _liveAt(d) == 1))));
      expect(run.listen(SkinPush.teeth).mistake, SkinMistakes.teeth);
      expect(run.listen(SkinPush.skipTest).mistake, SkinMistakes.untested);
      expect(run.ended, isFalse);
      run.round = 1;
      expect(run.listen(SkinPush.skipTest).verdict, SkinVerdict.deadly);
    });

    test('his push fits the job: teeth only on the small wire, the skipped test only before the tester', () {
      const wire = SkinJob(cable: SkinCable.wire, items: []);
      const ab = SkinJob(cable: SkinCable.ab, items: []);
      expect(skinPushFor(wire, tested: false, shown: false, preferTeeth: true), SkinPush.teeth);
      expect(skinPushFor(wire, tested: false, shown: false, preferTeeth: false), SkinPush.skipTest);
      expect(skinPushFor(wire, tested: true, shown: false, preferTeeth: false), SkinPush.teeth);
      expect(skinPushFor(ab, tested: false, shown: false, preferTeeth: true), SkinPush.skipTest);
      expect(skinPushFor(ab, tested: true, shown: false, preferTeeth: true), isNull);
      expect(skinPushFor(wire, tested: false, shown: true, preferTeeth: true), isNull);
      const liveWire = SkinJob(cable: SkinCable.wire, items: [], live: true);
      expect(skinPushFor(liveWire, tested: true, shown: false, preferTeeth: true), isNull, reason: 'a LIVE cable is held, not skinned');
      expect(skinPushFor(liveWire, tested: false, shown: false, preferTeeth: false), SkinPush.skipTest);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) dealSkin(math.Random(s))];
      expect(deals.map((d) => d.jobs.first.cable).toSet(), SkinCable.values.toSet());
      expect(deals.map(_liveAt).toSet(), {-1, 1, 2});
      expect(deals.expand((d) => d.jobs).expand((j) => j.items).map((x) => x.flaw).toSet(), BladeFlaw.values.toSet());
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.callTeeth).toSet(), {true, false});
    });

    test('the lens: a flaw shows only where it has been; the whole blade counts as looked over', () {
      final all = {for (var i = 0; i < kBladeBins; i++) i};
      expect(SkinToolPainter.flawSeen(BladeFlaw.blunt, {0, 1}), isFalse);
      expect(SkinToolPainter.flawSeen(BladeFlaw.blunt, {6}), isTrue);
      expect(SkinToolPainter.flawSeen(BladeFlaw.dirty, {6}), isFalse);
      expect(SkinToolPainter.flawSeen(BladeFlaw.dirty, {2}), isTrue);
      expect(SkinToolPainter.flawSeen(BladeFlaw.none, all), isFalse);
      expect(SkinToolPainter.allSeen({1, 2}), isFalse);
      expect(SkinToolPainter.allSeen(all), isTrue);
      for (final tool in SkinTool.values) {
        final (a, b) = SkinToolPainter.bladeSpan(tool);
        expect(SkinToolPainter.binAt(tool, a), 0);
        expect(SkinToolPainter.binAt(tool, b - 0.001), kBladeBins - 1);
        expect(SkinToolPainter.binAt(tool, 0.95), isNull, reason: 'the handle is not the blade');
      }
    });

    test('reason and choice libraries: same length, big enough, fit the cable; his lines listed for recording', () {
      expectSameLength('tool', [
        for (final c in SkinCable.values) ...SkinLines.toolRight(c, looked: true),
        ...SkinLines.toolMyths,
      ]);
      for (final c in SkinCable.values) {
        for (final looked in [true, false]) {
          expectLibrary('tool ${c.name} $looked', SkinLines.toolRight(c, looked: looked), SkinLines.toolWrong(c));
        }
        for (final r in SkinLines.toolFor(c)) {
          expect(SkinLines.toolWrong(c), isNot(contains(r)));
        }
        expect(SkinLines.toolRight(c, looked: false), isNot(contains(SkinLines.bladeChecked)), reason: 'only when the blade was looked over');
      }
      expectSameLength('hold', [...SkinLines.holdRight, ...SkinLines.holdWrong]);
      expectLibrary('hold', SkinLines.holdRight, SkinLines.holdWrong);
      // No word alone marks the right card: the right cards' key words are on
      // wrong ones too.
      for (final w in ['টেস্টার', 'লাইভ', 'ডেড']) {
        expect(SkinLines.holdWrong.any((x) => x.contains(w)), isTrue, reason: 'hold: "$w" also on a wrong card');
      }
      for (final c in SkinCable.values) {
        for (final w in ['স্ট্রিপার', 'নাইফ', 'এবি', 'XLPE', 'ব্লেড']) {
          expect(SkinLines.toolWrong(c).any((x) => x.contains(w)), isTrue, reason: 'tool ${c.name}: "$w" also on a wrong card');
        }
      }
      // The small wire's ডকেট words and the hold cards' নয় on wrong cards too.
      for (final w in ['ছোট', 'তারে', 'ওয়্যার']) {
        expect(SkinLines.toolWrong(SkinCable.wire).any((x) => x.contains(w)), isTrue, reason: 'tool wire: "$w" also on a wrong card');
      }
      for (final w in ['নয়', 'ছুরি', 'কেবিলে']) {
        expect(SkinLines.holdWrong.any((x) => x.contains(w)), isTrue, reason: 'hold: "$w" also on a wrong card');
      }
      // Deck fairness: one right card is dealt with two wrong ones, so no word
      // on every right card may be missing from every wrong card.
      for (final c in SkinCable.values) {
        for (final looked in [true, false]) {
          _expectNoMarkWord('tool ${c.name} $looked', SkinLines.toolRight(c, looked: looked), SkinLines.toolWrong(c));
        }
      }
      _expectNoMarkWord('hold', SkinLines.holdRight, SkinLines.holdWrong);
      for (final p in SkinPush.values) {
        _expectNoMarkWord('choice ${p.name}', SkinLines.coworker(p).right, SkinLines.coworker(p).wrong);
      }
      for (final p in SkinPush.values) {
        final c = SkinLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(SkinLines.recordLines, contains(c.line));
      }
      expect(LearnVoice.resolve(SkinLines.coworkerExit, rival: true), isNotNull, reason: 'his snarl is already recorded');
      for (final m in SkinMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
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

    Widget app(ProviderContainer c, Widget home, {GlobalKey<NavigatorState>? nav}) => UncontrolledProviderScope(
          container: c,
          child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(navigatorKey: nav, home: home)),
        );

    Future<(ProviderContainer, SkinDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealSkin(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(app(c, const Scaffold(body: SizedBox()), nav: nav));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2SkinToolsPage(ctx: _ctx, pack: m2SkinToolsPack26, muted: true, seed: seed),
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

    final tools = _label(SkinLines.toolLabel);

    Future<void> lift(WidgetTester t, SkinJob j, SkinItem it) async {
      await t.tap(tools.at(j.items.indexOf(it)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(SkinLines.take), findsOneWidget);
    }

    /// Drags the lens along the whole tool.
    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(SkinLines.handLabel));
      final g = await t.startGesture(Offset(box.left + 2, box.center.dy));
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> testCable(WidgetTester t) async {
      await t.tap(_label(SkinLines.testerLabel), warnIfMissed: false);
      await _pump(t, 700);
    }

    /// Job [j], done right: test, then hold on LIVE or skin it with the right tool.
    Future<void> doJob(WidgetTester t, SkinJob j) async {
      await testCable(t);
      expect(find.text(j.live ? SkinLines.live : SkinLines.dead), findsOneWidget);
      if (j.live) {
        await t.tap(find.text(SkinLines.hold));
        await _pump(t, 3500);
        await _pickRight(t, SkinLines.holdRight);
      } else {
        await lift(t, j, _right(j));
        await slide(t);
        await t.tap(find.text(SkinLines.take));
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, SkinLines.toolRight(j.cable, looked: true));
      }
      await _pump(t, 3500);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the pole (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final c = ProviderContainer();
        await t.pumpWidget(app(c, M2SkinToolsPage(ctx: _ctx, pack: m2SkinToolsPack26, muted: true, seed: _seedWhere((d) => d.callRound == 2))));
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
        debugPrint('PERF skin tools ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(find.text(SkinLines.jobCard), findsOneWidget);
        expect(find.text(SkinLines.hold), findsNothing, reason: 'the hold comes only after the test');
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        c.dispose();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('guide first: no start button, a tap does not skip; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(app(c, M2SkinToolsPage(ctx: _ctx, pack: m2SkinToolsPack26, muted: true, seed: _seedWhere((d) => d.callRound == 2))));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.textContaining(RegExp('শুরু')), findsNothing, reason: 'no start button of any wording');
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
        expect(line, contains(SkinLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, job card, gloves, test each cable, right tools under the lens, hold on LIVE → pass', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0 && _liveAt(d) > 0);
      final (c, deal) = await open(t, seed);

      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [...SkinLines.coworkerTeeth.right, ...SkinLines.coworkerSkip.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      final j1 = deal.jobs[0];
      await t.tap(find.text(SkinLines.jobCard));
      await _pump(t, 500);
      expect(find.text(SkinLines.jobLine(j1)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(SkinLines.jobLine(j1)), findsNothing);

      await t.tap(_label(SkinLines.glovesLabel), warnIfMissed: false);
      await _pump(t, 600);
      expect(_label(SkinLines.glovesLabel), findsNothing, reason: 'the gloves are on');

      // The kitchen knife set aside without a cut goes aside, tagged.
      await testCable(t);
      await lift(t, j1, j1.items.firstWhere((x) => x.tool == SkinTool.kitchen));
      await t.tap(find.text(SkinLines.reject));
      await _pump(t, 800);
      expect(find.text(SkinLines.rejected), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await lift(t, j1, _right(j1));
      await slide(t);
      await t.tap(find.text(SkinLines.take));
      await _pump(t, 3500);
      await _pickRight(t, SkinLines.toolRight(j1.cable, looked: true));
      await _pump(t, 3500);

      for (final j in deal.jobs.skip(1)) {
        await doJob(t, j);
      }
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.6/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.6/do/0'], greaterThan(0));
      expect(find.text(SkinLines.caughtCall), findsOneWidget);
      expect(find.text(SkinLines.caughtHold), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: the kitchen knife is a slip card and goes aside; cutting the live cable freezes first, then the card', (t) async {
      final seed = _seedWhere((d) => d.callRound == 2 && _liveAt(d) == 1);
      final (c, deal) = await open(t, seed);
      final j1 = deal.jobs[0];
      await t.tap(_label(SkinLines.glovesLabel), warnIfMissed: false);
      await _pump(t, 600);
      await testCable(t);
      await lift(t, j1, j1.items.firstWhere((x) => x.tool == SkinTool.kitchen));
      await t.tap(find.text(SkinLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(SkinMistakes.kitchen.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(SkinLines.rejected), findsOneWidget);
      await lift(t, j1, _right(j1));
      await t.tap(find.text(SkinLines.take));
      await _pump(t, 3500);
      await _pickRight(t, SkinLines.toolRight(j1.cable, looked: false));
      await _pump(t, 3500);

      // Job 2 is live: cut without testing.
      final j2 = deal.jobs[1];
      await lift(t, j2, _right(j2));
      await t.tap(find.text(SkinLines.take));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the scene freezes first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(SkinMistakes.liveCut.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.length, greaterThanOrEqualTo(2));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to "টেস্ট লাগবে না" on a dead cable is a slip card', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0 && (!d.callTeeth || d.jobs.first.cable != SkinCable.wire));
      final (c, _) = await open(t, seed);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(SkinLines.coworkerSkip.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.text(SkinMistakes.untested.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker comes even on a fast play: the tester waits for him and he says "টেস্ট লাগবে না"', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0);
      final (c, _) = await open(t, seed);
      // At once, before his timer: the tester does nothing, he cuts in now.
      await testCable(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'a fast tap cannot skip him');
      expect(find.text(SkinLines.dead), findsNothing);
      expect(find.text(SkinLines.live), findsNothing);
      await _pickRight(t, SkinLines.coworkerSkip.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await testCable(t);
      expect(find.text(SkinLines.dead), findsOneWidget, reason: 'after him the tester works');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker on a fast tool tap on the small wire: the teeth, and no close-up opens', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0 && d.callTeeth && d.jobs.first.cable == SkinCable.wire);
      final (c, deal) = await open(t, seed);
      final j1 = deal.jobs[0];
      await t.tap(tools.at(j1.items.indexOf(_right(j1))), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(SkinLines.take), findsNothing, reason: 'the tool waits for him');
      await waitChoiceDeck(t);
      expect(_onScreen(SkinLines.coworkerTeeth.right), hasLength(1), reason: 'his push fits the tap: the teeth');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('the close-up names no tool; rejecting a sound right tool is a slip, putting back tells nothing', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2));
      final j1 = deal.jobs[0];
      await t.tap(_label(SkinLines.glovesLabel), warnIfMissed: false);
      await _pump(t, 600);
      await testCable(t);
      for (final it in j1.items) {
        await lift(t, j1, it);
        for (final tool in SkinTool.values) {
          expect(find.text(tool.nameBn), findsNothing, reason: 'no name in the close-up (${tool.name})');
        }
        await t.tap(find.text(SkinLines.putBack));
        await _pump(t, 500);
        expect(find.text(SkinLines.rejected), findsNothing, reason: 'putting back never sets aside');
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'putting back never costs');
      }
      await lift(t, j1, _right(j1));
      await t.tap(find.text(SkinLines.reject));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(SkinMistakes.goodRejected.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      expect(find.text(SkinLines.rejected), findsNothing, reason: 'the sound tool stays in the roll');
      await lift(t, j1, _right(j1));
      await t.tap(find.text(SkinLines.take));
      await _pump(t, 3500);
      await _pickRight(t, SkinLines.toolRight(j1.cable, looked: false));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('praise window: after a right cut no scene control takes a tap until the reason', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2));
      final j1 = deal.jobs[0];
      await t.tap(_label(SkinLines.glovesLabel), warnIfMissed: false);
      await _pump(t, 600);
      await testCable(t);
      await lift(t, j1, _right(j1));
      await t.tap(find.text(SkinLines.take));
      await t.pump(const Duration(milliseconds: 200));
      final other = j1.items.firstWhere((x) => x.id != _right(j1).id);
      await t.tap(tools.at(j1.items.indexOf(other)), warnIfMissed: false);
      await t.tap(find.text(SkinLines.jobCard), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(SkinLines.take), findsNothing, reason: 'no close-up in the praise window');
      expect(find.byKey(const ValueKey('job-zoom')), findsNothing);
      await _pickRight(t, SkinLines.toolRight(j1.cable, looked: false));
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    group('gesture hint', () {
      tearDown(() => GestureHints.debugEnableInTests = false);

      testWidgets('a sweep over the scene\'s controls while waiting, a lens drag in the close-up, none on a card', (t) async {
        GestureHints.debugEnableInTests = true;
        final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2));
        IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
        expect(hint().showing, isFalse);
        await _pump(t, 9000);
        expect(hint().showing, isTrue, reason: 'stuck at the pole: the hand shows');
        expect(hint().debugOptions.length, greaterThanOrEqualTo(4), reason: 'a sweep over gloves, tester, every tool, the ডকেট');
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 120));
          final f = hint().debugFrame;
          if (f != null) expect(f.press, 0, reason: 'a sweep never presses a control');
        }
        // The close-up: first a short drag on the blade (how to use the lens).
        final j1 = deal.jobs[0];
        await lift(t, j1, j1.items.first);
        await _pump(t, 9000);
        expect(hint().showing, isTrue);
        expect(hint().debugOptions, isEmpty, reason: 'a drag, not a pick');
        // A slip card: no hand.
        await t.tap(find.text(SkinLines.take));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget);
        await _pump(t, 9000);
        expect(hint().showing, isFalse, reason: 'never on a card');
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2));
      final j1 = deal.jobs[0];
      for (var i = 0; i < 2; i++) {
        await lift(t, j1, _right(j1));
        await t.tap(find.text(SkinLines.take));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await lift(t, j1, _right(j1));
      await t.tap(find.text(SkinLines.take));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.6/do/0'), isTrue);
      expect(s.rungProgress['2.6/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
