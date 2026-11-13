// Lesson 1.8, কাজ 2 (PASS): where to stand (wind, wall, way out) and PASS by
// hand. Rules (the deal, the places, the slips), option libraries without
// giveaways, and the page: the coworker comes even on a fast play, listening
// to him is a slip, three slips strike out, the wall-downwind place, and the
// gesture hints (a sweep over the places; a nudge on the handle only once it
// is the one way forward). Older flows live in fire_test.dart.
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
import 'package:slm_flutter/features/game/fire_choose.dart' show FireKind;
import 'package:slm_flutter/features/game/fire_pass.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '1.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.8',
  lessonTitleBn: '',
  ladderStep: 24,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

/// The option cards (by their texts) that are on screen.
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Set<String> _words(String s) => s.split(RegExp(r'[\s,—\-।?!]+')).where((w) => w.isNotEmpty).toSet();

/// No word sits on two or more right options while no wrong option has it
/// (a player could pick the right card by that word alone).
void _expectNoRightOnlyWord(String name, List<String> right, List<String> wrong) {
  final inWrong = wrong.expand(_words).toSet();
  final counts = <String, int>{};
  for (final r in right) {
    for (final w in _words(r)) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
  }
  final tells = [for (final e in counts.entries) if (e.value >= 2 && !inWrong.contains(e.key)) e.key];
  expect(tells, isEmpty, reason: '$name: words only on the right options');
}

void main() {
  group('PASS rules', () {
    test('the deal: each fire deals its own wind, wall and sock; fire 2 does not follow from fire 1', () {
      final socks = <bool>{};
      final firstWall = <bool>{};
      final kinds = <FireKind>{};
      // How fire 2 relates to fire 1: (same wind?, same wall?). Every pair
      // must turn up, so no "the other side from last time" rule holds.
      final relations = <(bool, bool)>{};
      for (var seed = 0; seed < 80; seed++) {
        final d = dealPass(math.Random(seed));
        expect(d, hasLength(2));
        expect({d[0].kind, d[1].kind}, {FireKind.oil, FireKind.grass});
        socks.addAll([d[0].sockOnLeft, d[1].sockOnLeft]);
        firstWall.add(d[0].wallUpwind);
        kinds.add(d[0].kind);
        relations.add((d[0].windFromLeft == d[1].windFromLeft, d[0].wallUpwind == d[1].wallUpwind));
      }
      expect(socks, {true, false}, reason: 'the windsock is not always on one side');
      expect(firstWall, {true, false});
      expect(kinds, {FireKind.oil, FireKind.grass});
      expect(relations, {(true, true), (true, false), (false, true), (false, false)},
          reason: 'the wind and the wall are not flipped by rule between fires');
      // The right place at fire 2 is not fixed by fire 1's right place.
      final fire2Right = <(double, bool)>{};
      for (var seed = 0; seed < 80; seed++) {
        final d = dealPass(math.Random(seed));
        fire2Right.add((PassStage.spotXIn(StandSpot.upwind, d[1]), PassStage.spotXIn(StandSpot.upwind, d[0]) < PassStage.fireX));
      }
      for (final side in [true, false]) {
        expect(fire2Right.where((e) => e.$2 == side).map((e) => e.$1).toSet().length, greaterThan(1),
            reason: 'fire 1 right on the ${side ? 'left' : 'right'}: fire 2 right place still varies');
      }
    });

    test('the places: upwind is upwind of the fire, downwind in the smoke, the cornered one by the wall', () {
      for (final wind in [true, false]) {
        for (final wall in [true, false]) {
          final r = PassRound(kind: FireKind.oil, windFromLeft: wind, wallUpwind: wall);
          double x(StandSpot s) => PassStage.spotXIn(s, r);
          final upSide = wind ? -1 : 1;
          expect((x(StandSpot.upwind) - PassStage.fireX).sign, upSide, reason: 'wind $wind wall $wall');
          expect((x(StandSpot.downwind) - PassStage.fireX).sign, -upSide);
          // Cornered: the place nearest the wall's edge of the yard.
          final wallX = r.wallOnLeft ? 0.0 : 360.0;
          final nearest = StandSpot.values.reduce((a, b) => (x(a) - wallX).abs() < (x(b) - wallX).abs() ? a : b);
          expect(nearest, StandSpot.cornered);
          expect((x(StandSpot.cornered) - PassStage.fireX).sign, wall ? upSide : -upSide);
          for (final s in StandSpot.values) {
            expect(x(s), inInclusiveRange(24, 336));
          }
          final xs = [for (final s in StandSpot.values) x(s)]..sort();
          expect(xs[1] - xs[0], greaterThanOrEqualTo(60), reason: 'places do not overlap');
          expect(xs[2] - xs[1], greaterThanOrEqualTo(60));
        }
      }
      // The right place is not always "next to the wall", nor always the lone one.
      final a = PassRound(kind: FireKind.oil, windFromLeft: true, wallUpwind: true);
      final b = PassRound(kind: FireKind.oil, windFromLeft: true, wallUpwind: false);
      double gap(PassRound r) => (PassStage.spotXIn(StandSpot.upwind, r) - PassStage.spotXIn(StandSpot.cornered, r)).abs();
      expect(gap(a), lessThan(gap(b)));
    });

    test('a slip for each wrong place: downwind, cornered upwind, cornered in the smoke', () {
      const up = PassRound(kind: FireKind.grass, windFromLeft: true);
      const down = PassRound(kind: FireKind.grass, windFromLeft: true, wallUpwind: false);
      expect(PassMistakes.forSpot(StandSpot.upwind, up), isNull);
      expect(PassMistakes.forSpot(StandSpot.upwind, down), isNull);
      expect(PassMistakes.forSpot(StandSpot.downwind, up), PassMistakes.downwind);
      expect(PassMistakes.forSpot(StandSpot.cornered, up), PassMistakes.cornered);
      expect(PassMistakes.forSpot(StandSpot.cornered, down), PassMistakes.downwindWall);
      expect(PassMistakes.all.map((m) => m.key).toSet(), hasLength(PassMistakes.all.length));
      for (final m in PassMistakes.all) {
        expect(m.deadly, isFalse, reason: '${m.key}: no deadly on this rung (owner list)');
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
    });

    test('libraries: same length, big enough, and no word that only the right cards carry', () {
      final sets = {
        'stand': (PassLines.whyStandRight, PassLines.whyStandWrong),
        'aim': (PassLines.whyAimRight, PassLines.whyAimWrong),
        'refill': (PassLines.refillRight, PassLines.refillWrong),
      };
      for (final e in sets.entries) {
        final (right, wrong) = e.value;
        expectSameLength(e.key, [...right, ...wrong]);
        expectLibrary(e.key, right, wrong);
        _expectNoRightOnlyWord(e.key, right, wrong);
      }
    });

    test('the coworker speaks in his recorded voice; English digits only', () {
      for (final l in PassLines.coworker.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
      final all = [
        PassLines.intro,
        for (final k in FireKind.values) ...[PassLines.alarmFirst(k), PassLines.alarm(k)],
        ...PassLines.tapStand,
        ...PassLines.tapPass,
        ...PassLines.tapSweep,
        ...PassLines.tapWhy,
        ...PassLines.whyStandRight,
        ...PassLines.whyStandWrong,
        ...PassLines.whyAimRight,
        ...PassLines.whyAimWrong,
        ...PassLines.refillRight,
        ...PassLines.refillWrong,
        ...PassLines.refillAsks,
        PassLines.refillLine,
        PassLines.coworkerExit,
        PassLines.refillOk,
        PassLines.allSet,
        PassLines.fail,
        for (final m in PassMistakes.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
    });
  });

  group('PASS page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });
    tearDown(() => GestureHints.debugEnableInTests = false);

    Future<ProviderContainer> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => FirePassPage(ctx: _ctx, pack: passPack18, muted: true, seed: seed),
      )));
      await _pump(t, 1500);
      await waitIntro(t);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    final upwind = find.byKey(const ValueKey('spot-upwind'));

    Future<void> waitSpots(WidgetTester t) async {
      for (var ms = 0; ms < 6000 && upwind.hitTestable().evaluate().isEmpty; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    /// Hold the handle and slide side to side until the fire is out.
    Future<void> sweepOut(WidgetTester t) async {
      final g = await t.startGesture(t.getCenter(_label(PassLines.squeeze)));
      for (var k = 0; k < 70 && _label(PassLines.squeeze).evaluate().isNotEmpty; k++) {
        await g.moveBy(Offset(k.isEven ? 24 : -24, 0));
        await t.pump(const Duration(milliseconds: 30));
      }
      await g.up();
    }

    /// One fire, played fast: stand upwind, pin, base, squeeze-sweep, reason.
    Future<void> playFire(WidgetTester t, int i) async {
      await waitSpots(t);
      await t.tap(upwind, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      await t.drag(_label(PassLines.pin), const Offset(80, 0));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(_label(PassLines.base), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      await sweepOut(t);
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'fire $i');
      await waitChoiceDeck(t);
      final right = _onScreen(i == 0 ? PassLines.whyStandRight : PassLines.whyAimRight);
      expect(right, hasLength(1), reason: 'one right reason dealt, fire $i');
      await t.tap(right.single, warnIfMissed: false);
      await tapReasonProceed(t);
    }

    Future<void> gotIt(WidgetTester t) async {
      await t.tap(find.text(MistakeLines.gotIt).first);
      await _pump(t, 400);
    }

    testWidgets('three slips strike out: the level fails and the lesson card insists', (t) async {
      final c = await open(t, 3);
      await waitSpots(t);
      await t.tap(find.byKey(const ValueKey('spot-downwind')), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(PassMistakes.downwind.textBn), findsWidgets);
      await gotIt(t);
      await t.tap(find.byKey(const ValueKey('spot-cornered')), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await gotIt(t);
      await t.tap(find.byKey(const ValueKey('spot-downwind')), warnIfMissed: false);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/1'], isNot('cleared'));
      expect(s.bestMarkByRung['1.8/do/1'] ?? 55, lessThan(56), reason: '3 slips = 55 at most, never a pass here');
      expect(s.mistakes.map((e) => e.key), contains(PassMistakes.downwind.key));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('fast play: the coworker still comes before the result; refusing him clears the rung', (t) async {
      final c = await open(t, 6);
      for (var i = 0; i < 2; i++) {
        await playFire(t, i);
      }
      // No result before him: the refill is his item.
      expect(find.byType(LevelPassPanel), findsNothing);
      await waitChoiceDeck(t);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(LevelPassPanel), findsNothing);
      final refill = _onScreen(PassLines.refillRight);
      expect(refill, hasLength(1));
      await t.tap(refill.single, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 4000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.bestMarkByRung['1.8/do/1'], 100);
      expect(find.text(PassLines.caughtRefill), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('listening to the coworker (keep the half-used cylinder) is a slip, not a death', (t) async {
      final c = await open(t, 7);
      for (var i = 0; i < 2; i++) {
        await playFire(t, i);
      }
      await waitChoiceDeck(t);
      final keep = _onScreen(PassLines.refillWrong);
      expect(keep, hasLength(2));
      await t.tap(keep.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 800);
      expect(find.text(PassMistakes.keep.textBn), findsWidgets);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await gotIt(t);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((e) => e.key), contains(PassMistakes.keep.key));
      expect(s.deaths, 0);
      expect(s.bestMarkByRung['1.8/do/1'], 85);
      expect(s.rungProgress['1.8/do/1'], 'cleared');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('wall downwind: the place by the wall is in the smoke — its own slip', (t) async {
      var seed = 0;
      while (dealPass(math.Random(seed))[0].wallUpwind) {
        seed++;
      }
      final c = await open(t, seed);
      await waitSpots(t);
      await t.tap(find.byKey(const ValueKey('spot-cornered')), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(PassMistakes.downwindWall.textBn), findsWidgets);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('tapping the bare yard costs nothing; no slip, no points', (t) async {
      final c = await open(t, 5);
      await waitSpots(t);
      final size = t.view.physicalSize / t.view.devicePixelRatio;
      for (var i = 0; i < 3; i++) {
        await t.tapAt(Offset(size.width * 0.5, size.height * 0.3));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    IdleHintState? showingHint(WidgetTester t) {
      for (final e in find.byType(IdleHint).evaluate()) {
        final s = (e as StatefulElement).state as IdleHintState;
        if (s.showing) return s;
      }
      return null;
    }

    testWidgets('gesture hints: a sweep over all three places; on the handle only once it is the one way forward', (t) async {
      GestureHints.debugEnableInTests = true;
      final c = await open(t, 6);
      await waitSpots(t);
      expect(showingHint(t), isNull, reason: 'not at once');
      await _pump(t, 9000);
      final where = showingHint(t);
      expect(where, isNotNull, reason: 'stuck where to stand: the hand shows');
      expect(where!.debugOptions, hasLength(3), reason: 'it passes over every place, pressing none');
      // Stand upwind, pull the pin, aim at the base: only the handle is left.
      await t.tap(upwind, warnIfMissed: false);
      await _pump(t, 300);
      expect(showingHint(t), isNull, reason: 'a touch hides it');
      await t.drag(_label(PassLines.pin), const Offset(80, 0));
      await _pump(t, 200);
      await _pump(t, 9000);
      final pass = showingHint(t);
      expect(pass, isNotNull);
      expect(pass!.debugOptions, hasLength(3), reason: 'pin out: a sweep over the flames, the base and the handle alike');
      await t.tap(_label(PassLines.base), warnIfMissed: false);
      await _pump(t, 200);
      await _pump(t, 9000);
      final handle = showingHint(t);
      expect(handle, isNotNull);
      expect(handle!.debugOptions, isEmpty, reason: 'a drag nudge, not a sweep');
      expect(t.takeException(), isNull);
      GestureHints.debugEnableInTests = false;
      await close(t, c);
    });

    testWidgets('no hint while the reason deck owns the screen or the coworker talks', (t) async {
      GestureHints.debugEnableInTests = true;
      final c = await open(t, 6);
      await waitSpots(t);
      await t.tap(upwind, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      await t.drag(_label(PassLines.pin), const Offset(80, 0));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(_label(PassLines.base), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      await sweepOut(t);
      // The praise window and the deck: the scene's own hint stays away (the
      // deck's built-in sweep is the only hand allowed).
      await waitChoiceDeck(t);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      await _pump(t, 9000);
      final s = showingHint(t);
      if (s != null) {
        expect(s.debugOptions.length, greaterThanOrEqualTo(2), reason: 'only the deck sweep, over its open cards');
      }
      expect(t.takeException(), isNull);
      GestureHints.debugEnableInTests = false;
      await close(t, c);
    });
  });
}
