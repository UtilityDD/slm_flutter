// Lesson 2.3, কাজ 1 (সঠিক ল্যাগ): rules of the tray (metal, size, faults,
// the strip, sending for the right lug), the close look (a crack shows only
// where the hand has been), deal variety, fair reason libraries that fit what
// the tray had, and the level in the shell (idle perf; the guide first; a full
// clean flow with the cable print, a faulty lug set aside, the strip, the
// reasons and the coworker; slip cards; three slips fail).
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
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_lug_pick.dart';
import 'package:slm_flutter/features/game/m2_lug_pick_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.3',
  lessonTitleBn: '',
  ladderStep: 7,
  doIndex: 1,
  doCount: 2,
);

/// Serves this level's mistake art from disk (its folder joins pubspec when
/// the director wires the level), everything else from the app bundle.
class _ArtBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m2_lug_pick/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(Uint8List.fromList(b).buffer);
    }
    return rootBundle.load(key);
  }
}

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) => MaterialApp(
      navigatorKey: nav,
      builder: (context, child) => DefaultAssetBundle(bundle: _ArtBundle(), child: child!),
      home: home,
    );

LugItem _right(LugRoundDeal r) => r.lugs.firstWhere(r.cable.fits);
LugItem _otherMetal(LugRoundDeal r) => r.lugs.firstWhere((x) => x.metal != r.cable.metal);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose coworker comes on cable [round].
int _seedCalling(int round) {
  for (var s = 0;; s++) {
    if (dealLugs(math.Random(s)).callRound == round) return s;
  }
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
}

/// A cable whose own-size lug has fault [f], for the hold reasons.
LugRoundDeal _holdCase(LugMetal m, LugFlaw f) => LugRoundDeal(
      cable: LugCable(metal: m, size: 25),
      lugs: [
        LugItem(id: 'a', metal: m, size: 25, flaw: f),
        LugItem(id: 'b', metal: m, size: 35),
        LugItem(id: 'c', metal: m.other, size: 25),
      ],
    );

void main() {
  group('rules', () {
    test('every deal: cables 1 and 2 have exactly one right lug; cable 3 has none; decoys are real', () {
      for (var s = 0; s < 80; s++) {
        final d = dealLugs(math.Random(s));
        expect(d.rounds.length, 3);
        for (final r in d.rounds.take(2)) {
          expect(r.lugs.where(r.cable.fits).length, 1);
          expect(r.lugs.where((x) => x.metal != r.cable.metal).length, 1, reason: 'one lug of the other metal');
          expect(r.lugs.where((x) => x.metal == r.cable.metal && x.size > r.cable.size).length, 1, reason: 'one size up');
        }
        expect(d.rounds[0].cable.metal, LugMetal.cu);
        expect(d.rounds[1].cable.metal, LugMetal.al);
        expect(d.rounds[1].twin, isNotNull, reason: 'cable 2 has a faulty twin');
        expect(d.rounds[2].noneFits, isTrue);
        expect(d.rounds[2].twin!.flaw, LugFlaw.crack, reason: 'a cracked lug is no use — a dirty one could be cleaned');
        for (final r in d.rounds) {
          expect(kLugSizes, contains(r.cable.size));
          expect(r.lugs.any((x) => x.size < r.cable.size), isFalse, reason: 'a smaller barrel would not even go on');
        }
        if (d.callMetal) expect(d.rounds[d.callRound].cable.metal, LugMetal.al);
      }
    });

    test('a clean play: right lug, strip, right lug, strip, send for the right one', () {
      final run = LugRun(dealLugs(math.Random(3)));
      expect(run.take(_right(run.current)).verdict, LugVerdict.right);
      expect(run.stripping, isTrue);
      expect(run.shown, isFalse, reason: 'the strip comes first');
      expect(run.take(_otherMetal(run.current)).mistake, isNull, reason: 'nothing more while stripping');
      expect(run.holdJob().mistake, isNull);
      expect(run.strip(1.05).verdict, LugVerdict.right);
      expect(run.shown, isTrue);
      expect(run.round, 0, reason: 'the cable moves on only after the reason');
      run.next();
      expect(run.take(_right(run.current)).verdict, LugVerdict.right);
      expect(run.strip(0.9).verdict, LugVerdict.right);
      run.next();
      expect(run.holdJob().verdict, LugVerdict.right);
      run.next();
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([LugLines.caughtMatch, LugLines.caughtStrip, LugLines.caughtHold]));
    });

    test('wrong metal, a bigger size, a cracked or dirty lug: each a slip, and it goes aside', () {
      final run = LugRun(dealLugs(math.Random(5)))..round = 1;
      final r = run.current;
      expect(run.take(_otherMetal(r)).mistake, LugMistakes.wrongMetal);
      expect(run.take(r.lugs.firstWhere((x) => x.size > r.cable.size)).mistake, LugMistakes.wrongSize);
      final twin = r.twin!;
      expect(run.take(twin).mistake, twin.flaw == LugFlaw.crack ? LugMistakes.crack : LugMistakes.dirt);
      expect(run.rejected.length, 3);
      expect(run.slips, 3);
      expect(run.take(twin).mistake, isNull, reason: 'already aside');
    });

    test('the strip: too short or too long is a slip and the strip is tried again', () {
      final run = LugRun(dealLugs(math.Random(2)));
      expect(run.strip(1).mistake, isNull, reason: 'no lug yet');
      run.take(_right(run.current));
      expect(run.strip(1 - kStripTolerance - 0.02).mistake, LugMistakes.stripShort);
      expect(run.strip(1 + kStripTolerance + 0.02).mistake, LugMistakes.stripLong);
      expect(run.stripping, isTrue);
      expect(run.slips, 2);
      expect(run.strip(1 + kStripTolerance - 0.01).verdict, LugVerdict.right);
      expect(run.strip(1).mistake, isNull, reason: 'decided');
    });

    test('putting back: a faulty lug whose fault was found goes aside for free; anything else back in the tray', () {
      final run = LugRun(dealLugs(math.Random(5)))..round = 1;
      final r = run.current;
      final twin = r.twin!;
      expect(run.putBack(_right(r)), isFalse);
      expect(run.putBack(_otherMetal(r)), isFalse);
      expect(run.putBack(twin), isFalse, reason: 'not looked for: putting back gives nothing away');
      run.spot(_right(r));
      expect(run.spotted, isEmpty, reason: 'a sound lug has nothing to find');
      run.spot(twin);
      expect(run.putBack(twin), isTrue);
      expect(run.slips, 0);
      expect(run.caught, contains(LugLines.caughtFlaw));
      run.take(_right(r));
      run.strip(1);
      run.next();
      expect(run.spotted, isEmpty, reason: 'a fresh cable');
      expect(run.fitted, isNull);
    });

    test('sending for the lug when the right one was there is a slip; the hold reason names the crack only once seen', () {
      final run = LugRun(dealLugs(math.Random(7)));
      expect(run.holdJob().mistake, LugMistakes.heldWhenRight);
      run.round = 2;
      final r = run.current;
      expect(run.flawKnown, isFalse);
      expect(LugLines.holdRight(r, flawKnown: false), LugLines.holdSound);
      expect(LugLines.holdWrong(r, flawKnown: false), LugLines.holdExcuses);
      run.spot(r.twin!);
      expect(run.flawKnown, isTrue);
      expect(LugLines.holdRight(r, flawKnown: true), contains(LugLines.flawWhy(LugFlaw.crack)));
      expect(LugLines.holdWrong(r, flawKnown: true), contains(LugLines.flawWhy(LugFlaw.dirt)));
    });

    test('the coworker pushes only a lug still in the tray; copper only on aluminium', () {
      const al = LugRoundDeal(cable: LugCable(metal: LugMetal.al, size: 35), lugs: [
        LugItem(id: 'a', metal: LugMetal.al, size: 35),
        LugItem(id: 'b', metal: LugMetal.al, size: 50),
        LugItem(id: 'c', metal: LugMetal.cu, size: 35),
      ]);
      expect(lugPushFor(al, {}, preferMetal: true), LugPush.metal);
      expect(lugPushFor(al, {}, preferMetal: false), LugPush.bigger);
      expect(lugPushFor(al, {'b'}, preferMetal: false), LugPush.metal);
      expect(lugPushFor(al, {'b', 'c'}, preferMetal: true), isNull);
      expect(lugPushed(al, {}, LugPush.metal)!.id, 'c');
      expect(lugPushed(al, {}, LugPush.bigger)!.id, 'b');
      const cu = LugRoundDeal(cable: LugCable(metal: LugMetal.cu, size: 16), lugs: [
        LugItem(id: 'a', metal: LugMetal.cu, size: 16),
        LugItem(id: 'c', metal: LugMetal.al, size: 16),
      ]);
      expect(lugPushFor(cu, {}, preferMetal: true), isNull, reason: 'no copper-on-aluminium push on a copper cable');
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) dealLugs(math.Random(s))];
      expect(deals.map((d) => d.rounds[0].cable.size).toSet().length, 3);
      expect(deals.map((d) => d.rounds[1].cable.size).toSet().length, 4);
      expect(deals.map((d) => d.rounds[2].cable.metal).toSet(), LugMetal.values.toSet());
      expect(deals.map((d) => d.rounds[1].twin!.flaw).toSet(), {LugFlaw.crack, LugFlaw.dirt});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.callMetal).toSet(), {true, false});
      expect(deals.map((d) => d.rounds[1].lugs.indexWhere(d.rounds[1].cable.fits)).toSet().length, greaterThan(2));
    });

    test('the close look: a crack shows only where the hand has been; the strip bench measures by the barrel', () {
      expect(LugSidePainter.crackSeen({}), isFalse);
      expect(LugSidePainter.crackSeen({0, 1, 2, 3}), isFalse);
      expect(LugSidePainter.crackSeen({lugBin(LugSidePainter.crackU)}), isTrue);
      expect(LugSidePainter.crackSeen(null), isTrue, reason: 'null = all looked at');
      const s = Size(300, 120);
      expect(LugSidePainter.barrelU(s, LugSidePainter.barrelX0(s)), 0);
      expect(LugSidePainter.barrelU(s, LugSidePainter.barrelX1(s)), 1);
      // A bigger lug has a longer barrel; the knife at 1 depth sits at its mouth.
      const box = Size(320, 168);
      final small = LugStripGeo(box, 10);
      final big = LugStripGeo(box, 95);
      expect(big.depth, greaterThan(small.depth));
      for (final g in [small, big]) {
        expect(g.knifeX(1), closeTo(g.cableEnd - g.depth, 0.001));
        expect(g.maxU, greaterThan(1.5));
        final lug = g.lugRect(g.cableEnd - g.depth, g.lugY);
        expect(lug.left + lug.width * 0.03, closeTo(g.cableEnd - g.depth, 0.01));
        expect(lug.left + lug.width * 0.6, closeTo(g.cableEnd, 0.01), reason: 'the barrel bottom over the cable end');
      }
    });

    test('reason and choice libraries: same length, big enough, fit what the tray had; his exit line is recorded', () {
      expectSameLength('pack', [for (final m in LugMetal.values) ...LugLines.packRight(m), ...LugLines.packMyths]);
      for (final m in LugMetal.values) {
        expectLibrary('pack ${m.name}', LugLines.packRight(m), LugLines.packWrong(m));
        expect(LugLines.packWrong(m), isNot(contains(LugLines.packMatch(m))));
      }
      final cases = [for (final m in LugMetal.values) for (final f in const [LugFlaw.crack, LugFlaw.dirt]) _holdCase(m, f)];
      expectSameLength('hold', [
        for (final c in cases) ...LugLines.holdRight(c, flawKnown: true),
        for (final c in cases) ...LugLines.holdWrong(c, flawKnown: true),
      ]);
      for (final c in cases) {
        final f = c.twin!.flaw;
        expectLibrary('hold ${f.name}', LugLines.holdRight(c, flawKnown: true), LugLines.holdWrong(c, flawKnown: true));
        expectLibrary('hold unseen ${f.name}', LugLines.holdRight(c, flawKnown: false), LugLines.holdWrong(c, flawKnown: false));
        expect(LugLines.holdRight(c, flawKnown: true), contains(LugLines.flawWhy(f)));
        expect(LugLines.holdWrong(c, flawKnown: true), isNot(contains(LugLines.flawWhy(f))));
        for (final x in const [LugFlaw.crack, LugFlaw.dirt]) {
          expect([...LugLines.holdRight(c, flawKnown: false), ...LugLines.holdWrong(c, flawKnown: false)], isNot(contains(LugLines.flawWhy(x))),
              reason: 'a fault never looked for is never a card');
        }
      }
      for (final p in LugPush.values) {
        final c = LugLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull, reason: c.exitLine);
        expect(LugLines.newRivalLines, contains(c.line), reason: 'his new push is listed for recording');
      }
      // Lesson 2.3's points: 1 = lug & tool match, 2 = the golden rules, 3 = good vs bad.
      for (final m in LugMistakes.all) {
        expect(m.deadly, isFalse);
        expect(m.lessonPoint, inInclusiveRange(1, 3));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m2LugPickPacks['do_2_3_a'], m2LugPickPack23);
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final msg = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      msg.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    Future<(ProviderContainer, LugDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealLugs(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2LugPickPage(ctx: _ctx, pack: m2LugPickPack23, muted: true, seed: seed),
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

    final lugs = _label(LugLines.lugLabel);

    Future<void> lift(WidgetTester t, LugRoundDeal r, LugItem l) async {
      await t.tap(lugs.at(r.lugs.indexOf(l)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(LugLines.take), findsOneWidget);
      expect(find.text(l.stamp), findsOneWidget, reason: 'the stamp is readable up close');
    }

    /// Runs a finger along the barrel and looks into the mouth.
    Future<void> inspect(WidgetTester t) async {
      final box = t.getRect(_label(LugLines.handLabel));
      final g = await t.startGesture(Offset(box.left + 2, box.center.dy));
      for (var i = 1; i <= 20; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width * 0.62) * i / 20, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(_label(LugLines.mouthLabel), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
    }

    /// Sets the knife at [u] barrel depths and strips.
    Future<void> strip(WidgetTester t, LugItem l, double u) async {
      expect(find.text(LugLines.strip), findsOneWidget);
      final bench = _label(LugLines.stripLabel);
      final g = LugStripGeo(t.getSize(bench), l.size);
      await t.drag(bench, const Offset(-700, 0));
      await t.pump(const Duration(milliseconds: 50));
      await t.drag(bench, Offset((g.maxU - u) * g.depth, 0));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.text(LugLines.strip));
      await _pump(t, 1600);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the bench (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: _app(M2LugPickPage(ctx: _ctx, pack: m2LugPickPack23, muted: true, seed: _seedCalling(1)))));
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
        debugPrint('PERF lug pick ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(find.text(LugLines.hold), findsOneWidget);
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
        child: _app(M2LugPickPage(ctx: _ctx, pack: m2LugPickPack23, muted: true, seed: _seedCalling(2))),
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
        expect(line, contains(LugLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: cable print, refuse the coworker, faulty lug aside, strip, reasons, send for the lug → pass', (t) async {
      final (c, deal) = await open(t, _seedCalling(0));

      // He peeps in on the first cable; the guide asks; refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [...LugLines.coworkerBigger.right, ...LugLines.coworkerMetal.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // Cable 1: read the print close; the other-metal lug put back (no tag).
      final r1 = deal.rounds[0];
      await t.tap(_label(LugLines.cableLabel));
      await _pump(t, 500);
      expect(find.text(LugLines.cableBn(r1.cable)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(LugLines.cableBn(r1.cable)), findsNothing);
      await lift(t, r1, _otherMetal(r1));
      await t.tap(find.text(LugLines.putBack));
      await _pump(t, 800);
      expect(find.text(LugLines.rejected), findsNothing);

      for (var i = 0; i < 2; i++) {
        final r = deal.rounds[i];
        if (i == 1) {
          // The faulty twin, looked over: its fault shows, so it goes aside.
          await lift(t, r, r.twin!);
          await inspect(t);
          await t.tap(find.text(LugLines.putBack));
          await _pump(t, 800);
          expect(find.text(LugLines.rejected), findsOneWidget, reason: 'found, so set aside');
        }
        await lift(t, r, _right(r));
        await inspect(t);
        await t.tap(find.text(LugLines.take));
        await _pump(t, 800);
        await strip(t, _right(r), 1);
        await _pump(t, 2500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, LugLines.packRight(r.cable.metal));
        await _pump(t, 3500);
      }

      // Cable 3: the own-size lug, felt along — cracked, aside; nothing fits.
      final r3 = deal.rounds[2];
      await lift(t, r3, r3.twin!);
      await inspect(t);
      await t.tap(find.text(LugLines.putBack));
      await _pump(t, 800);
      expect(find.text(LugLines.rejected), findsOneWidget);
      await t.tap(find.text(LugLines.hold));
      await _pump(t, 3500);
      await _pickRight(t, LugLines.holdRight(r3, flawKnown: true));
      await _pump(t, 6000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.3/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.3/do/0'], greaterThan(0));
      expect(find.text(LugLines.caughtCall), findsOneWidget);
      expect(find.text(LugLines.caughtHold), findsOneWidget);
      expect(find.text(LugLines.caughtStrip), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him takes the bigger lug — a slip card', (t) async {
      final (c, _) = await open(t, _seedCalling(0));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(LugLines.coworkerBigger.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(LugMistakes.wrongSize.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: the wrong metal is a slip and goes aside; a short strip is a slip and the strip comes again', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      await lift(t, r1, _otherMetal(r1));
      await t.tap(find.text(LugLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(LugMistakes.wrongMetal.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(LugLines.rejected), findsOneWidget);

      await lift(t, r1, _right(r1));
      await t.tap(find.text(LugLines.take));
      await _pump(t, 800);
      await strip(t, _right(r1), 0.3);
      expect(find.text(LugMistakes.stripShort.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await strip(t, _right(r1), 1);
      await _pump(t, 2500);
      await _pickRight(t, LugLines.packRight(r1.cable.metal));
      await _pump(t, 3500);
      expect(find.text(LugLines.hold), findsOneWidget, reason: 'on to cable 2');
      expect(c.read(gameSaveProvider).mistakes.length, 2);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, _) = await open(t, _seedCalling(2));
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(LugLines.hold));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(LugLines.hold));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.3/do/0'), isTrue);
      expect(s.rungProgress['2.3/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
