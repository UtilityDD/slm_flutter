// Lesson 1.4, কাজ 2 (ফিটিং আর অ্যাঙ্কর): the fit done with the hands (buckle,
// tail, strap, D-ring, the four-finger hand), anchor choice through the lens,
// his three shortcuts, fair reason libraries that fit the climb, his recorded
// lines, and the level in the shell: idle perf, the guide first, a full clean
// play with the reasons and the coworker refused, a slip, listening to him,
// the 3-slip strike-out (one strike per strap left), the coworker on a fast
// play, the gesture hints and the deadly freeze.
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
import 'package:slm_flutter/features/game/harness_fit.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
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
  rungId: '1.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.4',
  lessonTitleBn: '',
  ladderStep: 12,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
Finder _key(String k) => find.byKey(ValueKey(k));
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Taps the one right card on the deck now up (and এগিয়ে যান after a reason;
/// coworker decks have no proceed).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// A seed whose deal passes [ok].
int _seedWhere(bool Function(ClimbDeal d) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealClimbs(math.Random(s)))) {
    s++;
  }
  return s;
}

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
    builder: (_) => HarnessFitPage(ctx: _ctx, pack: fitPack14, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// The hand slid under the leg strap: what it felt.
Future<void> _feelLeg(WidgetTester t) async {
  final hand = _key('h-hand');
  await t.drag(hand, t.getCenter(_key('z-leg')) - t.getCenter(hand));
  await _pump(t, 400);
}

/// The fill of the chip that shows [text].
Color? _chipColor(WidgetTester t, String text) {
  final box = t.widget<DecoratedBox>(find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first);
  return (box.decoration as BoxDecoration).color;
}

Future<void> _turn(WidgetTester t, {bool swipe = false}) async {
  if (swipe) {
    await t.drag(_key('h-man'), const Offset(-220, 0));
  } else {
    await t.tap(find.text(FitLines.turn));
  }
  await _pump(t, 600);
}

/// Puts right, with the hands, each fault in [owed].
Future<void> _fixFit(WidgetTester t, Set<FitFault> owed, {bool swipe = false}) async {
  if (owed.contains(FitFault.twisted)) {
    // Grab the strap where the buckle does not cover it (it sits on top).
    final strap = t.getRect(_key('h-strap'));
    final at = owed.contains(FitFault.chestHigh) ? strap.bottomCenter - const Offset(0, 6) : strap.topCenter + const Offset(0, 6);
    await t.dragFrom(at, const Offset(0, 70));
    await _pump(t, 500);
  }
  if (owed.contains(FitFault.chestHigh)) {
    await t.drag(_key('h-chest'), const Offset(0, 200));
    await _pump(t, 300);
  }
  if (owed.contains(FitFault.loose)) {
    await _feelLeg(t);
    expect(find.text(FitLines.wholeHand), findsOneWidget);
    await t.drag(_key('h-tail'), const Offset(0, 80));
    await _pump(t, 500);
  }
  if (owed.contains(FitFault.dRingLow)) {
    await _turn(t, swipe: swipe);
    expect(_key('h-dring'), findsOneWidget);
    await t.drag(_key('h-dring'), const Offset(0, -300));
    await _pump(t, 300);
    await _turn(t);
  }
}

/// At the pole top: the sling through the lens, then its reason.
Future<void> _tieToSling(WidgetTester t, ClimbRound r, {required bool last}) async {
  await t.tap(_key('spot-sling'));
  await _pump(t, 500);
  expect(_label(FitLines.lensLabel), findsOneWidget);
  await t.tap(find.text(FitLines.clipHere));
  await _pump(t, 2500);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(find.text(FitLines.anchorAsk), findsWidgets);
  await _pickRight(t, FitLines.anchorWhy(r.anchors));
  await _pump(t, last ? 6000 : 3500);
}

/// He comes on his moment (a few seconds after the move that calls him); refuse him.
Future<void> _refuse(WidgetTester t, FitPush push) async {
  await _pump(t, 3500);
  expect(find.byType(CoworkerPeek), findsOneWidget);
  await _pickRight(t, FitLines.coworker(push).right);
  await _pump(t, 2500);
}

/// Up to the pole top of the climb now: fix the fit, "উঠি", its reason.
Future<void> _upThePole(WidgetTester t, ClimbRound r) async {
  await _fixFit(t, r.faults);
  await t.tap(find.text(FitLines.climb));
  await _pump(t, 2500);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _pickRight(t, FitLines.fitWhy(FitLines.reasonFault(r.faults)));
}

void main() {
  group('rules', () {
    test('deals: one clean fit, the D-ring fault once, the sling always, the pin on his pole when he pushes it', () {
      final pushes = <FitPush>{};
      final seen = <String>{};
      final sides = <bool>{};
      for (var s = 0; s < 80; s++) {
        final d = dealClimbs(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds.where((r) => r.faults.isEmpty).length, 1);
        expect(d.rounds.where((r) => r.faults.contains(FitFault.dRingLow)).length, 1);
        expect(d.pushRound, inInclusiveRange(0, 2));
        pushes.add(d.push);
        for (final r in d.rounds) {
          expect(r.anchors.first, AnchorPoint.sling);
          expect(r.anchors.length, inInclusiveRange(3, 4));
          expect(r.anchors.toSet().length, r.anchors.length);
        }
        if (d.push == FitPush.pinClip) expect(d.rounds[d.pushRound].anchors, contains(AnchorPoint.insulatorPin));
        // The sling sits at a different height on each climb.
        expect(d.rounds.map((r) => r.slingAt).toSet(), {0, 1, 2});
        sides.addAll(d.rounds.map((r) => r.slingLeft));
        seen.add('${d.push}${d.pushRound}${d.rounds.map((r) => '${r.faults}${r.anchors}').join()}');
      }
      expect(pushes, FitPush.values.toSet());
      expect(sides, {true, false}, reason: 'the sling ring hangs left or right');
      expect(seen.length, greaterThan(40), reason: 'every play is dealt fresh');
    });

    test('fit with the hands: each fault put right is a clean check; a fault left is a slip', () {
      final s = _seedWhere((d) => d.rounds[0].faults.length == 2);
      final d = dealClimbs(math.Random(s));
      final a = ClimbRun(d);
      for (final f in a.owed) {
        switch (f) {
          case FitFault.twisted:
            expect(a.straighten(), isTrue);
          case FitFault.chestHigh:
            a.setChest(high: false);
          case FitFault.loose:
            expect(a.feelLeg(), isTrue);
            expect(a.tighten(), isTrue);
            expect(a.feelLeg(), isFalse, reason: 'four fingers now');
          case FitFault.dRingLow:
            a.setDRing(low: false);
        }
      }
      expect(a.fixedCount, 2);
      final c = a.checkFit();
      expect(c.clean, isTrue);
      expect(a.slips, 0);
      expect(a.caught, contains(FitLines.caughtFit));
      expect(a.phase, ClimbPhase.fitShown);

      final b = ClimbRun(d);
      final miss = b.checkFit();
      expect(miss.missed.toSet(), d.rounds[0].faults);
      expect(b.slips, 2);
    });

    test('a strap moved from right to wrong is a false mark; tightening or straightening a good strap does nothing', () {
      final s = _seedWhere((d) => d.rounds[0].faults.isEmpty);
      final d = dealClimbs(math.Random(s));
      final a = ClimbRun(d);
      expect(a.tighten(), isFalse);
      expect(a.straighten(), isFalse);
      expect(a.feelLeg(), isFalse);
      a.setChest(high: true);
      final c = a.checkFit();
      expect(c.falseMarks, [FitZone.chest]);
      expect(a.slips, 1);
      final b = ClimbRun(d)..setDRing(low: true);
      expect(b.checkFit().falseMarks, [FitZone.dRing]);
      final e = ClimbRun(d);
      expect(e.checkFit().clean, isTrue, reason: 'a clean harness left as it is');
    });

    test('the back D-ring: caught once put right; listening to "ঢিলে রাখো" is a slip and loosens the leg strap', () {
      final s = _seedWhere((d) => d.rounds[0].faults.contains(FitFault.dRingLow) && !d.rounds[0].faults.contains(FitFault.loose));
      final d = dealClimbs(math.Random(s));
      final a = ClimbRun(d)
        ..lookBack()
        ..fit.fixAll();
      a.checkFit();
      expect(a.caught, contains(FitLines.caughtBack));
      final b = ClimbRun(d)..pushLoose();
      expect(b.slips, 1);
      expect(b.owed, contains(FitFault.loose));
      expect(b.feelLeg(), isTrue);
      expect(b.caught, contains(FitLines.caughtFingers));
      b
        ..fit.fixAll()
        ..tighten();
      expect(b.checkFit().clean, isTrue);
    });

    test('anchor: the sling is right; every weak point is deadly; giving in to "হারনেস লাগে না" is deadly', () {
      final d = dealClimbs(math.Random(4));
      for (final a in AnchorPoint.values.skip(1)) {
        final run = ClimbRun(d)
          ..fit.fixAll()
          ..checkFit()
          ..toAnchor();
        final m = run.tieOff(a);
        expect(m, FitMistakes.anchor(a));
        expect(m!.deadly, isTrue);
        expect(run.ended, isTrue);
      }
      final ok = ClimbRun(d)
        ..fit.fixAll()
        ..checkFit()
        ..toAnchor();
      expect(ok.tieOff(AnchorPoint.sling), isNull);
      expect(ok.phase, ClimbPhase.anchored);
      expect(ok.caught, contains(FitLines.caughtAnchor));
      expect(ClimbRun(d).noTieOff().deadly, isTrue);
    });

    test('his line fits the moment: on his "ঢিলে রাখো" climb the leg strap is never dealt loose', () {
      var seen = 0;
      for (var s = 0; s < 300; s++) {
        final d = dealClimbs(math.Random(s));
        if (d.push != FitPush.looseStraps) continue;
        seen++;
        expect(d.rounds[d.pushRound].faults, isNot(contains(FitFault.loose)), reason: 'seed $s');
      }
      expect(seen, greaterThan(40));
      // The loose fault still shows up on other climbs.
      expect(
        [for (var s = 0; s < 300; s++) dealClimbs(math.Random(s))].any((d) => d.rounds.any((r) => r.faults.contains(FitFault.loose))),
        isTrue,
      );
    });

    test('after a deadly the run stays put (ended guards): no next climb, no second death, no anchor phase', () {
      final d = dealClimbs(math.Random(4));
      final run = ClimbRun(d)
        ..fit.fixAll()
        ..checkFit()
        ..toAnchor();
      final first = run.tieOff(AnchorPoint.crackedArm);
      expect(first!.deadly, isTrue);
      expect(run.noTieOff(), first, reason: 'the first death stands');
      run.next();
      expect(run.round, 0);
      expect(run.done, isFalse);
      final b = ClimbRun(d)..noTieOff();
      b
        ..fit.fixAll()
        ..checkFit()
        ..toAnchor();
      expect(b.phase, ClimbPhase.fit, reason: 'nothing moves after the death');
      expect(b.tieOff(AnchorPoint.sling), isNull);
      expect(b.phase, ClimbPhase.fit);
    });

    test('anchor reasons: the right cards\' key words show up on wrong cards too', () {
      for (final w in ['দুর্বল', 'কখনো']) {
        expect(FitLines.anchorMyths.any((m) => m.contains(w)), isTrue, reason: w);
      }
    });

    test('every mistake has its picture (on disk) and a lesson point (2 = fitting, 3 = anchoring)', () {
      for (final m in FitMistakes.all) {
        expect(m.art, startsWith('assets/game/art/harness/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(2, 3));
      }
      expect(FitMistakes.all.where((m) => m.deadly).length, 4);
    });

    test('reasons: fit what the climb had, same length, big enough; one right per deal', () {
      const faults = [null, ...FitFault.values];
      for (final f in faults) {
        // Each question has its own wrong reasons, on its own strap.
        expectSameLength('fit $f', [...FitLines.fitWhy(f), ...FitLines.fitMyths(f)]);
        expectLibrary('fit $f', FitLines.fitWhy(f), FitLines.fitMyths(f));
        for (var s = 0; s < 12; s++) {
          final deal = dealChoices(FitLines.fitWhy(f), FitLines.fitMyths(f), math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      expect(FitLines.reasonFault({FitFault.twisted, FitFault.dRingLow}), FitFault.dRingLow);
      expect(FitLines.reasonFault({}), isNull);
      const all = [AnchorPoint.sling, AnchorPoint.crackedArm, AnchorPoint.insulatorPin, AnchorPoint.looseBracket];
      expectSameLength('anchor', [...FitLines.anchorWhy(all), ...FitLines.anchorMyths]);
      expectLibrary('anchor', FitLines.anchorWhy(all), FitLines.anchorMyths);
      // The right reasons name only weak points this pole top had.
      expect(FitLines.anchorWhy(const [AnchorPoint.sling, AnchorPoint.looseBracket, AnchorPoint.crackedArm]), isNot(contains(FitLines.anchorWhyPin)));
      expect(FitLines.anchorWhy(const [AnchorPoint.sling, AnchorPoint.insulatorPin, AnchorPoint.looseBracket]), isNot(contains(FitLines.anchorWhyArm)));
    });

    test('his three shortcuts: fair decks, his lines recorded in his voice, no Bangla digits on screen', () {
      for (final c in FitLines.all) {
        expectSameLength('choice ${c.line}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${c.line}', c.right, c.wrong);
        expect(c.asks.length, greaterThanOrEqualTo(2));
        for (final l in c.recordedLines) {
          expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
        }
        for (final x in [c.line, ...c.right, ...c.wrong, ...c.asks]) {
          expect(RegExp('[০-৯]').hasMatch(x), isFalse, reason: x);
        }
      }
      for (final x in [FitLines.intro, FitLines.askFit, FitLines.askAnchor, FitLines.fourFingers, FitLines.wholeHand]) {
        expect(RegExp('[০-৯]').hasMatch(x), isFalse, reason: x);
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
          child: MaterialApp(home: HarnessFitPage(ctx: _ctx, pack: fitPack14, muted: true, seed: 2)),
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
        debugPrint('PERF fit ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: HarnessFitPage(ctx: _ctx, pack: fitPack14, muted: true, seed: 2)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(FitLines.climb), findsNothing);
      await waitIntro(t);
      await _pump(t, 800);
      expect(find.text(FitLines.climb), findsOneWidget);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(FitLines.askFit)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // Two full plays: he pushes at the pole top (refused) / at the fit (refused).
    for (final atTop in [true, false]) {
      testWidgets('flow (${atTop ? 'he pushes at the top' : 'he pushes at the fit'}): fix with the hands, reasons, refuse him, sling → pass', (t) async {
        final seed = _seedWhere((d) => atTop ? d.push == FitPush.pinClip : d.push == FitPush.looseStraps, from: atTop ? 5 : 9);
        final deal = dealClimbs(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          final r = deal.rounds[i];
          final his = i == deal.pushRound;
          if (his && deal.push == FitPush.looseStraps) {
            // A first move calls him in: he pushes loose straps; refuse.
            await _turn(t);
            await _turn(t);
            await _refuse(t, deal.push);
          }
          await _fixFit(t, r.faults, swipe: i.isEven);
          await t.tap(find.text(FitLines.climb));
          await _pump(t, 2500);
          expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'climb $i fit');
          expect(find.text(FitLines.fitAsk(FitLines.reasonFault(r.faults))), findsWidgets);
          await _pickRight(t, FitLines.fitWhy(FitLines.reasonFault(r.faults)));
          await _pump(t, 3000);
          expect(_key('spot-sling'), findsOneWidget, reason: 'climb $i: up the pole by itself');
          if (his && deal.push != FitPush.looseStraps) await _refuse(t, deal.push);
          await _tieToSling(t, r, last: i == 2);
        }
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['1.4/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['1.4/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(FitLines.caughtCall), findsOneWidget);
        expect(find.text(FitLines.caughtBack), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a fault left: the slip card (পাঠে দেখুন), then up the pole by itself', (t) async {
      final seed = _seedWhere((d) => d.rounds[0].faults.isNotEmpty && (d.pushRound != 0 || d.push != FitPush.looseStraps));
      final faults = dealClimbs(math.Random(seed)).rounds[0].faults;
      final c = await _open(t, seed);
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2500);
      expect(_key('spot-sling'), findsOneWidget);
      final s = c.read(gameSaveProvider);
      // One entry per strap left (one card on screen).
      expect(s.mistakes, hasLength(faults.length));
      await _close(t, c);
    });

    testWidgets('listening to "ঢিলে রাখো": the slip, no freeze; the leg strap is loose now', (t) async {
      final seed = _seedWhere((d) => d.push == FitPush.looseStraps && d.pushRound == 0 && !d.rounds[0].faults.contains(FitFault.loose));
      final c = await _open(t, seed);
      await _feelLeg(t);
      expect(find.text(FitLines.fourFingers), findsOneWidget);
      final okLook = _chipColor(t, FitLines.fourFingers);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(FitLines.coworkerLoose.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, FitMistakes.pushedLoose.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _feelLeg(t);
      expect(find.text(FitLines.wholeHand), findsOneWidget);
      // The reading is neutral: the same chip for a good and a loose strap.
      expect(_chipColor(t, FitLines.wholeHand), okLook);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out, one strike per strap left (the lesson card insists)', (t) async {
      // One strap wrong on each of the first two checks (the D-ring climb, with
      // two faults, comes last).
      final seed = _seedWhere((d) => d.push != FitPush.looseStraps && d.rounds.take(2).every((r) => r.faults.length <= 1));
      final deal = dealClimbs(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        if (deal.rounds[i].faults.isEmpty) {
          // A good chest strap pulled up to the neck.
          await t.drag(_key('h-chest'), const Offset(0, -200));
          await _pump(t, 300);
        }
        await t.tap(find.text(FitLines.climb));
        await _pump(t, 1200);
        if (i == 2) break;
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip $i');
        expect(find.byType(StruckOutCard), findsNothing);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 2500);
        if (i == deal.pushRound) await _refuse(t, deal.push);
        await _tieToSling(t, deal.rounds[i], last: false);
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.length, greaterThanOrEqualTo(2));
      expect(s.rungProgress['1.4/do/1'], isNot('cleared'));
      expect(s.bestMarkByRung['1.4/do/1'] ?? 0, lessThanOrEqualTo(55));
      await _close(t, c);
    });

    testWidgets('two straps left at one check are two strikes: the next slip strikes the level out', (t) async {
      final seed = _seedWhere((d) => d.rounds[0].faults.length == 2 && d.pushRound == 2 && d.rounds[1].faults.isNotEmpty);
      final deal = dealClimbs(math.Random(seed));
      final c = await _open(t, seed);
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(StruckOutCard), findsNothing);
      // Both straps reach the mistakes book (one card on screen).
      expect(
        c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(),
        {for (final f in deal.rounds[0].faults) FitMistakes.missed(f).key},
      );
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2500);
      await _tieToSling(t, deal.rounds[0], last: false);
      // Climb 2: one strap left = the third slip (it used to pass at 55 with
      // only two strikes counted).
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 1200);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['1.4/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('a fast play cannot skip him at the fit: "উঠি" with no move waits for "ঢিলে রাখো"', (t) async {
      final seed = _seedWhere((d) => d.push == FitPush.looseStraps && d.pushRound == 0);
      final r = dealClimbs(math.Random(seed)).rounds[0];
      final c = await _open(t, seed);
      // Straight to "উঠি", no touch on the harness: he cuts in now, no check.
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.text(FitLines.fitAsk(FitLines.reasonFault(r.faults))), findsNothing);
      await _pickRight(t, FitLines.coworkerLoose.right);
      await _pump(t, 2500);
      await _fixFit(t, r.faults);
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 2500);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.text(FitLines.fitAsk(FitLines.reasonFault(r.faults))), findsWidgets);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'once a play');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    for (final push in [FitPush.pinClip, FitPush.twentyYears]) {
      testWidgets('a fast play cannot skip him at the pole top (${push.name}): the first look waits for him', (t) async {
        final seed = _seedWhere((d) => d.push == push && d.pushRound == 0);
        final r = dealClimbs(math.Random(seed)).rounds[0];
        final c = await _open(t, seed);
        await _upThePole(t, r);
        // As soon as the pole top is in view (before his 1.2 s+ timer), a tap
        // on the sling: he comes now, no lens.
        await _pump(t, 950);
        expect(find.byType(CoworkerPeek), findsNothing);
        await t.tap(_key('spot-sling'));
        await t.pump();
        expect(_label(FitLines.lensLabel), findsNothing);
        expect(find.byType(CoworkerPeek), findsOneWidget);
        await _pump(t, 200);
        expect(find.byType(CoworkerPeek), findsOneWidget);
        expect(_label(FitLines.lensLabel), findsNothing);
        await _pickRight(t, FitLines.coworker(push).right);
        await _pump(t, 2500);
        await _tieToSling(t, r, last: false);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(c.read(gameSaveProvider).mistakes, isEmpty);
        await _close(t, c);
      });
    }

    testWidgets('gesture hints: a hand at the fit and a sweep over every anchor point, only while the level waits', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.pushRound != 0);
      final r = dealClimbs(math.Random(seed)).rounds[0];
      final c = await _open(t, seed);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      await _pump(t, 9000);
      expect(hand, findsOneWidget, reason: 'idle at the fit');
      final atFit = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(atFit.debugOptions, isEmpty, reason: 'a short drag nudge, not a pick');
      await t.tapAt(const Offset(380, 300));
      await t.pump();
      expect(hand, findsNothing, reason: 'any touch hides it');
      await _upThePole(t, r);
      await _pump(t, 1500);
      expect(hand, findsNothing);
      await _pump(t, 9000);
      expect(hand, findsOneWidget, reason: 'idle at the pole top');
      final atTop = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(atTop.debugOptions, hasLength(r.anchors.length), reason: 'the sweep passes over every point');
      // The lens: a sweep over its two buttons.
      await t.tap(_key('spot-sling'));
      await _pump(t, 500);
      expect(hand, findsNothing);
      await _pump(t, 9000);
      expect(hand, findsOneWidget);
      expect(t.state<IdleHintState>(find.byType(IdleHint).first).debugOptions, hasLength(2));
      await _close(t, c);
    });

    testWidgets('three taps on nothing show the hand at once', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 2);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      for (var i = 0; i < 3; i++) {
        await t.tapAt(const Offset(370, 260));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(hand, findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a weak anchor through the lens: the pole top freezes first, then the card', (t) async {
      final seed = _seedWhere((d) => d.pushRound != 0);
      final deal = dealClimbs(math.Random(seed));
      final r = deal.rounds[0];
      final c = await _open(t, seed);
      await _fixFit(t, r.faults);
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 2500);
      await _pickRight(t, FitLines.fitWhy(FitLines.reasonFault(r.faults)));
      await _pump(t, 3000);
      final weak = r.anchors[1];
      await t.tap(_key('spot-${weak.name}'));
      await _pump(t, 500);
      expect(_label(FitLines.lensLabel), findsOneWidget);
      await t.tap(find.text(FitLines.clipHere));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, FitMistakes.anchor(weak).key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to "হারনেস লাগে না" at the top: deadly, the freeze first', (t) async {
      final seed = _seedWhere((d) => d.push == FitPush.twentyYears && d.pushRound == 0);
      final r = dealClimbs(math.Random(seed)).rounds[0];
      final c = await _open(t, seed);
      await _fixFit(t, r.faults);
      await t.tap(find.text(FitLines.climb));
      await _pump(t, 2500);
      await _pickRight(t, FitLines.fitWhy(FitLines.reasonFault(r.faults)));
      await _pump(t, 3000);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(FitLines.coworkerYears.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, FitMistakes.noTieOff.key);
      await _close(t, c);
    });
  });
}
