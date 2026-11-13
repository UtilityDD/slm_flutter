// Lesson 5.2 (লাইন পেট্রোলিং), কাজ 2 "থামুন, দেখুন, শুনুন": the rules (hold
// to walk, let go to stop; tag what the eyes, ear and nose find; a sound part
// tagged is a slip; untagged clues are slips at the section end; the fallen
// wire: into the 10 m zone = deadly, the rope ring under 10 m = a slip; the
// drop: feet-together steps out, a long stride = deadly; looking up while
// walking stumbles), the deal, the libraries, and the level in the shell: the
// guide first, a full clean play (reason picks, the coworker refused), the
// drop variant stepped out, three slips, the deadly freezes (into the zone,
// a stride, listening to him), the look-up push (a slip), the gesture hand.
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
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_sense_walk.dart';
import 'package:slm_flutter/features/game/m5_sense_walk_world.dart';
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
  rungId: '5.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = senseWalkPacks['do_5_2_b']!;

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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
const _sceneH = 360 * 850 / 392;
SenseWalkGeo get _geo => SenseWalkGeo.forScene(_sceneH, 0);
SenseTopGeo get _top => SenseTopGeo.forScene(_sceneH);
SenseWalkRun get _run => SenseWalkProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 400);
}

const _strip = Offset(314, 808);

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
    builder: (_) => SenseWalkPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// Refuses (or obeys) the coworker if he is on screen.
Future<bool> _coworker(WidgetTester t, {bool refuse = true}) async {
  if (find.byType(CoworkerPeek).evaluate().isEmpty) return false;
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  final s = _run.deal.call == SenseCall.wire ? SenseWalkLines.wireCall : SenseWalkLines.lookCall;
  if (refuse) {
    await _pickRight(t, s.right);
    await _pump(t, 2600);
  } else {
    await _pickWrong(t, s.wrong);
    await _pump(t, 800);
  }
  return true;
}

/// Holds the walk strip until he reaches [x] (or something stops him); the
/// coworker is refused if he cuts in on the way.
Future<void> _walkTo(WidgetTester t, double x, {bool stopForHim = true, bool stopAtRope = false}) async {
  for (var tries = 0; tries < 4 && _run.pos < x - 0.05 && !_run.ended && !_run.wireIn; tries++) {
    final g = await t.startGesture(_strip);
    for (var i = 0; i < 2500 && _run.pos < x - 0.05; i++) {
      await t.pump(const Duration(milliseconds: 16));
      if (_run.ended || _run.wireIn || _run.atRope || find.byType(CoworkerPeek).evaluate().isNotEmpty) break;
    }
    await g.up();
    await t.pump(const Duration(milliseconds: 50));
    if (stopAtRope && _run.atRope) return;
    if (!stopForHim) return;
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      await _coworker(t);
    } else if (_run.wireIn || _run.ended) {
      return;
    }
  }
}

/// After a stop: give him time to come if he is due, and refuse him.
Future<void> _settle(WidgetTester t) async {
  await _pump(t, 2800);
  await _coworker(t);
}

Future<void> _lookUp(WidgetTester t) async {
  await t.dragFrom(const Offset(200, 420), const Offset(0, -140));
  await _pump(t, 600);
}

Future<void> _lookDown(WidgetTester t) async {
  await t.dragFrom(const Offset(200, 300), const Offset(0, 140));
  await _pump(t, 600);
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 2500);
}

/// Screen point of an eye-down part of pole [i].
Offset _downAt(int i, SensePart p) => _geo.partRect(p, _geo.sx(sensePoleX(i), _run.pos)).center;

/// Holds a sense chip till it answers.
Future<void> _sense(WidgetTester t, String label) async {
  final g = await t.startGesture(t.getCenter(_label(label)));
  await _pump(t, 1100);
  await g.up();
  await _pump(t, 200);
}

/// Goes to a clue pole and tags its clue (and, for the hidden one, checks the
/// sense first and answers the reason).
Future<void> _doClue(WidgetTester t, SenseClue clue) async {
  final l = _run.layout;
  final pole = switch (clue) {
    SenseClue.up => l.upPole,
    SenseClue.down => l.downPole,
    SenseClue.hidden => l.hiddenPole,
  };
  await _walkTo(t, sensePoleX(pole) - 2);
  await _settle(t);
  expect(_run.nearest, pole);
  switch (clue) {
    case SenseClue.up:
      await _lookUp(t);
      await _tapAt(t, _top.partRect(l.upPart).center);
      await _pump(t, 1500);
      expect(_run.found, contains(SenseClue.up));
      await _lookDown(t);
    case SenseClue.down:
      await _tapAt(t, _downAt(pole, l.downPart));
      await _pump(t, 1500);
      expect(_run.found, contains(SenseClue.down));
    case SenseClue.hidden:
      if (l.hidden == SenseHidden.ear) {
        await _sense(t, SenseWalkLines.earLabel);
        expect(find.text(SenseWalkLines.earYes), findsOneWidget);
        await _lookUp(t);
        await _tapAt(t, _top.partRect(l.hiddenPart).center);
        await _reason(t, SenseWalkLines.whyRight[SenseWhy.hidden]!);
        await _lookDown(t);
      } else {
        await _sense(t, SenseWalkLines.noseLabel);
        expect(find.text(l.noseOil ? SenseWalkLines.noseOil : SenseWalkLines.noseBurnt), findsOneWidget);
        await _tapAt(t, _downAt(pole, SensePart.tank));
        await _reason(t, SenseWalkLines.whyRight[SenseWhy.smell]!);
      }
      expect(_run.found, contains(SenseClue.hidden));
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '$clue');
}

/// Drags the rope reel out to [r] metres from the wire.
Future<void> _rope(WidgetTester t, double r) async {
  final g = _geo;
  final from = g.reel.center * _k;
  final stakeX = _run.wireX! - kSenseWireHalf - r;
  final to = Offset(g.sx(stakeX, _run.pos), g.reel.center.dy) * _k;
  final gesture = await t.startGesture(from);
  // Out a little first (past the touch slop), then to the stake.
  final out = from + const Offset(-30, -40);
  for (var i = 1; i <= 4; i++) {
    await gesture.moveTo(Offset.lerp(from, out, i / 4)!);
    await t.pump(const Duration(milliseconds: 30));
  }
  for (var i = 1; i <= 8; i++) {
    await gesture.moveTo(Offset.lerp(out, to, i / 8)!);
    await t.pump(const Duration(milliseconds: 30));
  }
  await gesture.up();
  await _pump(t, 400);
}

/// The fallen wire, soil / pitch: stop 12 m off, refuse him, rope at 11 m, reason.
Future<void> _wireAhead(WidgetTester t) async {
  final w = _run.wireX!;
  await _walkTo(t, w - kSenseWireHalf - 12);
  expect(_run.wireReady, isTrue);
  await _settle(t);
  await _rope(t, 11);
  expect(_run.cordon, 11);
  await _reason(t, SenseWalkLines.whyRight[_run.deal.wireWhy]!);
  // He walks on to the rope himself; the walk from there goes round it.
  expect(_run.wirePassed, isFalse);
}

int _seedWhere(bool Function(SenseWalkDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(senseWalkDeal(math.Random(s))));

/// A run at the start, its layout fixed for the rule tests.
SenseWalkRun _ruleRun(int seed) => SenseWalkRun(senseWalkDeal(math.Random(seed)));

void main() {
  group('rules', () {
    test('deals: 5–7 poles; three clue poles inside the section; the wire in an inner span; drop ~1/3; he comes at the wire ~2/3; plays differ', () {
      final seen = <String>{};
      var drops = 0;
      var wires = 0;
      var ears = 0;
      final dtrCount = {SenseHidden.ear: 0, SenseHidden.nose: 0};
      final hiddenCount = {SenseHidden.ear: 0, SenseHidden.nose: 0};
      for (var s = 0; s < 300; s++) {
        final d = senseWalkDeal(math.Random(s));
        final l = d.layout;
        expect(l.poles, inInclusiveRange(5, 7));
        final clues = {l.upPole, l.downPole, l.hiddenPole};
        expect(clues, hasLength(3));
        for (final p in clues) {
          expect(p, inInclusiveRange(1, l.poles - 2));
        }
        if (l.upKind == SenseUpKind.crack) {
          expect(senseUpParts.sublist(0, 3), contains(l.upPart));
        } else {
          expect([SensePart.wireL, SensePart.wireR], contains(l.upPart));
        }
        // A DTR on screen tells nothing: every play has one or two, the nose
        // pole's among them only in nose plays.
        expect(l.dtrPoles.length, inInclusiveRange(1, 2));
        expect(l.dtrPoles.contains(l.hiddenPole), l.hidden == SenseHidden.nose);
        dtrCount[l.hidden] = dtrCount[l.hidden]! + l.dtrPoles.length;
        hiddenCount[l.hidden] = hiddenCount[l.hidden]! + 1;
        if (l.downKind == SenseDownKind.anchor) expect(l.stays, contains(l.downPole));
        expect(l.posterPole, isNot(l.downPole));
        expect(l.treePole, isNot(l.upPole));
        for (var i = 1; i < l.potholes.length; i++) {
          expect(l.potholes[i], greaterThan(l.potholes[i - 1]));
        }
        final mid = d.wire == SenseWireKind.drop ? d.wireAt + 6 + kSenseWireHalf : d.wireAt;
        final span = ((mid - kSensePole0) / kSenseSpan).floor();
        expect(span, inInclusiveRange(1, l.poles - 2), reason: 'an inner span');
        expect(mid - sensePoleX(span), inInclusiveRange(11.9, 18.1), reason: 'away from the poles');
        // No kite / bird / branch on the hanging phase's side.
        expect((l.upPole == span && l.upPart == SensePart.wireR) || (l.upPole == span + 1 && l.upPart == SensePart.wireL), isFalse);
        // He never comes at a pole: a span's middle, not the wire's span.
        expect((d.gateX - kSensePole0) % kSenseSpan, closeTo(15, 1e-9));
        expect(((d.gateX - kSensePole0) / kSenseSpan).floor(), isNot(span));
        if (d.wire == SenseWireKind.drop) drops++;
        if (d.call == SenseCall.wire) wires++;
        if (l.hidden == SenseHidden.ear) ears++;
        seen.add('${l.poles}|${l.upPole}${l.upKind.name}|${l.downPole}${l.downKind.name}|${l.hiddenPole}${l.hidden.name}|${d.wire.name}$span|${d.call.name}');
      }
      expect(drops, inInclusiveRange(70, 130));
      expect(wires, inInclusiveRange(170, 230));
      expect(ears, inInclusiveRange(110, 190));
      expect(seen.length, greaterThan(200));
      // As many DTRs a play whichever the hidden clue.
      final earAvg = dtrCount[SenseHidden.ear]! / hiddenCount[SenseHidden.ear]!;
      final noseAvg = dtrCount[SenseHidden.nose]! / hiddenCount[SenseHidden.nose]!;
      expect((earAvg - noseAvg).abs(), lessThan(0.2), reason: '$earAvg vs $noseAvg');
    });

    test('decoy dirt: the ear pole has its dirt layer; about half the other poles carry one too', () {
      var decoys = 0;
      var others = 0;
      for (var s = 0; s < 200; s++) {
        final l = senseWalkDeal(math.Random(s)).layout;
        if (l.hidden == SenseHidden.ear) expect(l.dirtAt(l.hiddenPole), l.dirtyIns);
        for (var p = 0; p < l.poles; p++) {
          if (l.hidden == SenseHidden.ear && p == l.hiddenPole) continue;
          others++;
          final d = l.dirtAt(p);
          if (d != null) {
            decoys++;
            expect(d, inInclusiveRange(0, 2));
          }
        }
      }
      expect(decoys / others, inInclusiveRange(0.35, 0.65));
    });

    test('walking: forward only; into the 10 m zone of the wire = deadly; stopping outside it readies the rope', () {
      final s = _seedWhere((d) => d.wire != SenseWireKind.drop);
      final r = _ruleRun(s);
      final w = r.wireX!;
      expect(r.advance(r.pos - 2, eyesUp: false), SenseEvent.none);
      expect(r.pos, kSenseStart, reason: 'never backwards');
      r.advance(w - kSenseWireHalf - 30, eyesUp: false);
      expect(r.wireReady, isFalse, reason: 'not in view yet');
      r.advance(w - kSenseWireHalf - 10.2, eyesUp: false);
      expect(r.deadly, isNull);
      expect(r.wireReady, isTrue);
      expect(r.wireDist, closeTo(10.2, 1e-9));
      expect(r.advance(w - kSenseWireHalf - 9.5, eyesUp: false), SenseEvent.deadly);
      expect(r.deadly, SenseWalkMistakes.enterZone);
      expect(r.deadly!.deadly, isTrue);
      expect(r.ended, isTrue);
    });

    test('looking up while walking stumbles at the next pothole (a slip); eyes down walks over them', () {
      final s = _seedWhere((d) => d.wire != SenseWireKind.drop && d.layout.potholes.first < d.wireAt - 14);
      final down = _ruleRun(s);
      final h = down.layout.potholes.first;
      expect(down.advance(h + 0.5, eyesUp: false), isNot(SenseEvent.stumble));
      expect(down.slips, 0);
      final up = _ruleRun(s);
      expect(up.advance(h + 0.5, eyesUp: true), SenseEvent.stumble);
      expect(up.pos, h);
      expect(up.slips, 1);
    });

    test('tags: the clue pays once; a sound part = a slip; the senses answer only at the hidden clue pole', () {
      final r = _ruleRun(3);
      final l = r.layout;
      expect(r.tag(l.upPole, l.upPart), (SenseClue.up, null));
      expect(r.tag(l.upPole, l.upPart), (null, null), reason: 'already tagged');
      expect(r.tag(l.downPole, l.downPart).$1, SenseClue.down);
      expect(r.tag(0, SensePart.body), (null, SenseWalkMistakes.falseTag));
      expect(r.tag(l.hiddenPole, SensePart.base).$2, SenseWalkMistakes.falseTag);
      expect(r.slips, 2);
      final want = l.hidden == SenseHidden.ear ? SenseSense.ear : SenseSense.nose;
      final other = want == SenseSense.ear ? SenseSense.nose : SenseSense.ear;
      for (var p = 0; p < l.poles; p++) {
        r.pos = sensePoleX(p) - 2;
        expect(r.sense(other), isFalse);
        if (p == l.hiddenPole) continue;
        expect(r.sense(want), isFalse, reason: 'pole $p');
      }
      // The hidden clue seen but not heard / smelt: a slip, not a find (M5-10).
      expect(r.tag(l.hiddenPole, l.hiddenPart), (null, SenseWalkMistakes.blindTag));
      expect(r.slips, 3);
      expect(r.found, isNot(contains(SenseClue.hidden)));
      r.pos = sensePoleX(l.hiddenPole) - 2;
      expect(r.sense(want), isTrue);
      expect(r.sensed, {l.hiddenPole});
      expect(r.tag(l.hiddenPole, l.hiddenPart).$1, SenseClue.hidden);
      expect(r.found, SenseClue.values.toSet());
      expect(r.slips, 3);
    });

    test('evidence gate: the wrong sense never counts; the right one at the pole does', () {
      for (final hidden in SenseHidden.values) {
        final r = _ruleRun(_seedWhere((d) => d.layout.hidden == hidden));
        final l = r.layout;
        final want = hidden == SenseHidden.ear ? SenseSense.ear : SenseSense.nose;
        final other = want == SenseSense.ear ? SenseSense.nose : SenseSense.ear;
        r.pos = sensePoleX(l.hiddenPole) - 2;
        r.sense(other);
        expect(r.sensed, isEmpty);
        expect(r.tag(l.hiddenPole, l.hiddenPart).$2, SenseWalkMistakes.blindTag);
        r.sense(want);
        expect(r.tag(l.hiddenPole, l.hiddenPart).$1, SenseClue.hidden);
      }
    });

    test('the rope: under 10 m = a slip; 10 m or more lays it; then he goes round on the far side', () {
      final s = _seedWhere((d) => d.wire != SenseWireKind.drop);
      final r = _ruleRun(s);
      final w = r.wireX!;
      r.advance(w - kSenseWireHalf - 12, eyesUp: false);
      expect(r.lay(9), SenseWalkMistakes.shortRing);
      expect(r.cordon, isNull);
      expect(r.lay(10), isNull);
      expect(r.cordon, 10);
      expect(r.caught, isNot(contains(SenseWalkLines.caughtRing)), reason: 'after a short ring');
      // He walks on to the rope and stops there; it does not move him on.
      expect(r.atRope, isFalse);
      expect(r.advance(w + 5, eyesUp: false), SenseEvent.rope);
      expect(r.pos, closeTo(w - kSenseWireHalf - 10, 1e-9));
      expect(r.atRope, isTrue);
      expect(r.deadly, isNull);
      expect(r.advance(w + 5, eyesUp: false), SenseEvent.rope, reason: 'blocked');
      r.passWire();
      expect(r.wirePassed, isTrue);
      expect(r.atRope, isFalse);
      expect(r.pos, greaterThan(w + kSenseWireHalf + kSenseZone));
      expect(r.pos, lessThanOrEqualTo(sensePoleX(r.brokenSpan! + 1)), reason: 'never past the next pole');
      expect(r.advance(r.pos + 5, eyesUp: false), isNot(SenseEvent.deadly));
    });

    test('roped from far off: the pole before the wire can still be reached and checked', () {
      for (var s = 0; s < 120; s++) {
        final d = senseWalkDeal(math.Random(s));
        if (d.wire == SenseWireKind.drop) continue;
        final r = SenseWalkRun(d);
        final w = r.wireX!;
        final span = r.brokenSpan!;
        // As far off as the rope can go (the whole lying wire on screen).
        r.advance(w - (kSenseSeeAhead - kSenseWireHalf), eyesUp: false);
        expect(r.wireReady, isTrue, reason: 'seed $s');
        expect(r.lay(r.wireDist.floorToDouble()), isNull);
        r.advance(r.endX, eyesUp: false);
        expect(r.atRope, isTrue);
        expect(r.nearest, span, reason: 'seed $s: the pole before the wire is the nearest at the rope');
        expect(r.sense(SenseSense.ear), d.layout.hidden == SenseHidden.ear && d.layout.hiddenPole == span);
      }
    });

    test('wireReady only once the whole lying wire is on screen', () {
      final r = _ruleRun(_seedWhere((d) => d.wire != SenseWireKind.drop));
      final w = r.wireX!;
      r.advance(w - kSenseSeeAhead + kSenseWireHalf - 0.5, eyesUp: false);
      expect(r.wireReady, isFalse);
      r.advance(w - kSenseSeeAhead + kSenseWireHalf + 0.1, eyesUp: false);
      expect(r.wireReady, isTrue);
    });

    test('the hanging phase by the fallen wire: tapping it is no tag and no slip', () {
      final r = _ruleRun(_seedWhere((d) => d.wire != SenseWireKind.drop));
      final b = r.brokenSpan!;
      expect(r.tag(b, SensePart.wireR), (null, null));
      expect(r.tag(b + 1, SensePart.wireL), (null, null));
      expect(r.slips, 0);
    });

    test('the drop: the wire lands 6 m ahead; feet together / hops get out at 10 m; a stride is deadly', () {
      final s = _seedWhere((d) => d.wire == SenseWireKind.drop);
      final r = _ruleRun(s);
      expect(r.wireX, isNull);
      expect(r.advance(r.deal.wireAt + 3, eyesUp: false), SenseEvent.drop);
      expect(r.wireIn, isTrue);
      expect(r.wireDist, closeTo(6, 1e-9));
      expect(r.advance(r.pos + 2, eyesUp: false), SenseEvent.none, reason: 'no walking in the zone');
      for (var i = 0; i < 4; i++) {
        expect(r.stepOut(SenseStep.shuffle), isNull);
        expect(r.wireIn, isTrue);
      }
      expect(r.stepOut(SenseStep.hop), isNull);
      expect(r.wireIn, isFalse);
      expect(r.wireDist, greaterThanOrEqualTo(kSenseZone));
      expect(r.caught, contains(SenseWalkLines.caughtFeet));
      expect(r.wireReady, isTrue);
      final b = _ruleRun(s)..advance(senseWalkDeal(math.Random(s)).wireAt + 1, eyesUp: false);
      expect(b.stepOut(SenseStep.stride), SenseWalkMistakes.longStride);
      expect(b.deadly!.deadly, isTrue);
    });

    test('section end: each untagged clue is a slip (its own card); all found = a clean close', () {
      final a = _ruleRun(5);
      final missed = a.close();
      expect(missed, [
        SenseWalkMistakes.missUp,
        SenseWalkMistakes.missDown,
        a.layout.hidden == SenseHidden.ear ? SenseWalkMistakes.missEar : SenseWalkMistakes.missNose,
      ]);
      expect(a.slips, 3);
      expect(a.percent, 55, reason: 'the page strikes out on the third slip');
      final b = _ruleRun(5);
      final l = b.layout;
      b.tag(l.upPole, l.upPart);
      b.tag(l.downPole, l.downPart);
      b.pos = sensePoleX(l.hiddenPole) - 2;
      b.sense(l.hidden == SenseHidden.ear ? SenseSense.ear : SenseSense.nose);
      b.tag(l.hiddenPole, l.hiddenPart);
      expect(b.close(), isEmpty);
      expect(b.passed, isTrue);
      expect(b.percent, 100);
    });

    test('English digits only; every mistake has its picture and a lesson point; three deadly; keys unique', () {
      final all = <String>[
        SenseWalkLines.intro,
        ...SenseWalkLines.tasks,
        ...SenseWalkLines.allWhyRight,
        ...SenseWalkLines.whyQ.values,
        ...SenseWalkLines.myths,
        for (final s in [SenseWalkLines.wireCall, SenseWalkLines.lookCall]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in SenseWalkMistakes.all) m.textBn,
        SenseWalkLines.allSet,
        SenseWalkLines.fail,
        SenseWalkLines.metres(12),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(SenseWalkLines.metres(12), '12 মি');
      expect(SenseWalkMistakes.all.where((m) => m.deadly).toSet(),
          {SenseWalkMistakes.enterZone, SenseWalkMistakes.touchWire, SenseWalkMistakes.longStride});
      expect(SenseWalkMistakes.all.map((m) => m.key).toSet(), hasLength(SenseWalkMistakes.all.length));
      for (final m in SenseWalkMistakes.all) {
        expect(m.key, startsWith('5.2/m5_sense_walk/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      // Every picture in the folder is used.
      final used = SenseWalkMistakes.all.map((m) => m.art.split('/').last).toSet();
      final files = Directory('assets/game/art/m5_sense_walk').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(senseWalkPacks.keys, ['do_5_2_b']);
    });

    test('libraries: same length, big enough, a rule never marked wrong; his lines: exit recorded, the new pushes listed', () {
      expectSameLength('why', [...SenseWalkLines.allWhyRight, ...SenseWalkLines.myths]);
      expect(SenseWalkLines.myths.toSet().intersection(SenseWalkLines.allWhyRight.toSet()), isEmpty);
      for (final w in SenseWhy.values) {
        final right = SenseWalkLines.whyRight[w]!;
        expectLibrary('$w', right, SenseWalkLines.myths);
        expect(SenseWalkLines.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, SenseWalkLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final s in [SenseWalkLines.wireCall, SenseWalkLines.lookCall]) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
        expect(s.asks, isNotEmpty);
        expect(LearnVoice.resolve(s.exitLine, rival: true), isNotNull, reason: 'his exit line is recorded');
      }
      // The two pushes are new: the director records them (rival_lines_missing).
      expect(SenseWalkLines.newRivalLines, [
        'মাটিতে পড়ে থাকা তারটি স্পার্ক করছে না, তার মানে ওটা ডেড। সরিয়ে দিই, চলো!',
        'হাঁটতে হাঁটতেই ওপরে দেখো, সময় বাঁচবে!',
      ]);
      // The wire push carries the lesson's myth word for word.
      expect(SenseWalkLines.wireCall.line, startsWith('মাটিতে পড়ে থাকা তারটি স্পার্ক করছে না, তার মানে ওটা ডেড।'));
    });

    test('tap areas: the eye-up parts do not overlap; a pole\'s eye-down parts do not overlap; all on the scene', () {
      for (final h in [560.0, 700.0, _sceneH, 900.0]) {
        final top = SenseTopGeo.forScene(h);
        final up = [for (final p in senseUpParts) top.partRect(p)];
        final g = SenseWalkGeo.forScene(h, 0);
        final down = [for (final p in senseDownParts) g.partRect(p, 180)];
        for (final rects in [up, down]) {
          for (final r in rects) {
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(360));
            expect(r.top, greaterThan(80), reason: 'below the header');
            expect(r.bottom, lessThan(h - 100), reason: 'above the walk strip');
          }
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              final x = rects[i].intersect(rects[j]);
              expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
            }
          }
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
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the walk strip and the senses', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: SenseWalkPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(SenseWalkLines.walkLabel), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(SenseWalkLines.walkLabel), findsOneWidget);
      expect(_label(SenseWalkLines.earLabel), findsOneWidget);
      expect(_label(SenseWalkLines.noseLabel), findsOneWidget);
      expect(_label(SenseWalkLines.endLabel), findsNothing, reason: 'only at the far pole');
      // The strip is clear of the corner guide's touch area.
      final guide = t.getRect(find.byKey(const ValueKey('hud-guide')));
      expect(t.getRect(_label(SenseWalkLines.walkLabel)).left, greaterThanOrEqualTo(guide.right));
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
      expect(lines.every((l) => l.contains(SenseWalkLines.askWalk)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('hold to walk, let go to stop; a sense answers "absent" away from its pole; no walking while a card is up', (t) async {
      final c = await _open(t, 8);
      expect(_run.pos, kSenseStart);
      final g = await t.startGesture(_strip);
      await _pump(t, 1000);
      await g.up();
      final p = _run.pos;
      expect(p, inInclusiveRange(kSenseStart + 3, kSenseStart + 5), reason: '4 m a second');
      await _pump(t, 800);
      expect(_run.pos, p, reason: 'stopped');
      // Pole 0 never carries a clue: both senses are quiet there.
      await _sense(t, SenseWalkLines.earLabel);
      expect(find.text(SenseWalkLines.earNo), findsOneWidget);
      await _sense(t, SenseWalkLines.noseLabel);
      expect(find.text(SenseWalkLines.noseNo), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'the senses cost nothing');
      await _close(t, c);
    });

    for (final variant in ['ahead', 'drop']) {
      testWidgets('flow ($variant): every clue tagged, the wire handled, him refused, right reasons → pass', (t) async {
        final seed = _seedWhere((d) =>
            (variant == 'drop') == (d.wire == SenseWireKind.drop) && (variant == 'drop' ? d.call == SenseCall.lookUp : d.call == SenseCall.wire));
        final c = await _open(t, seed);
        final l = _run.layout;
        final mid = _run.deal.wire == SenseWireKind.drop ? _run.deal.wireAt + 6 + kSenseWireHalf : _run.deal.wireAt;
        // The stops in the order they come along the road.
        final stops = <(double, SenseClue?)>[
          (sensePoleX(l.upPole) - 2, SenseClue.up),
          (sensePoleX(l.downPole) - 2, SenseClue.down),
          (sensePoleX(l.hiddenPole) - 2, SenseClue.hidden),
          (mid - 13, null),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        for (final (_, clue) in stops) {
          if (clue != null) {
            await _doClue(t, clue);
            continue;
          }
          if (variant == 'ahead') {
            await _wireAhead(t);
          } else {
            // Walk on until the conductor falls in front of him.
            await _walkTo(t, mid);
            expect(_run.wireIn, isTrue);
            expect(_run.deadly, isNull);
            await _pump(t, 900);
            for (var i = 0; i < 6 && _run.wireIn; i++) {
              await t.tapAt(_geo.feet.center * _k);
              await _pump(t, 400);
            }
            expect(_run.wireIn, isFalse, reason: 'stepped out, feet together');
            await _settle(t);
            await _rope(t, 10);
            await _reason(t, SenseWalkLines.whyRight[SenseWhy.feet]!);
            expect(_run.atRope, isTrue, reason: 'out at 10 m = at the rope');
          }
        }
        await _walkTo(t, _run.endX - 1);
        await _settle(t);
        expect(coworkerSeen(_run), isTrue, reason: 'he came once');
        expect(_label(SenseWalkLines.endLabel), findsOneWidget);
        await t.tap(_label(SenseWalkLines.endLabel));
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.mistakes, isEmpty);
        expect(s.rungProgress['5.2/do/1'], 'cleared');
        expect(s.starsByRung['5.2/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(variant == 'drop' ? SenseWalkLines.caughtFeet : SenseWalkLines.caughtStop), findsOneWidget);
        expect(find.text(variant == 'drop' ? SenseWalkLines.caughtCallLook : SenseWalkLines.caughtCallWire), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('three false tags strike the level out (a slip card each, the walk goes on)', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _downAt(0, SensePart.body));
        await _pump(t, 400);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          expect(find.text(SenseWalkMistakes.falseTag.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_label(SenseWalkLines.walkLabel), findsOneWidget);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('walking on into the fallen wire: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.wire != SenseWireKind.drop && d.call == SenseCall.lookUp);
      final c = await _open(t, seed);
      await _walkTo(t, _run.wireX! - 2);
      expect(_run.deadly, SenseWalkMistakes.enterZone);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, SenseWalkMistakes.enterZone.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the drop: a long stride out of the zone is deadly', (t) async {
      final seed = _seedWhere((d) => d.wire == SenseWireKind.drop);
      final c = await _open(t, seed);
      await _walkTo(t, _run.deal.wireAt + 1);
      expect(_run.wireIn, isTrue);
      await _pump(t, 900);
      await t.timedDragFrom(_geo.feet.center * _k, const Offset(-120, 0), const Duration(milliseconds: 500));
      await _pump(t, 300);
      expect(_run.deadly, SenseWalkMistakes.longStride);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('roped from about 24 m out: the wire-span pole can still be checked by ear and by looking up', (t) async {
      final seed = _seedWhere((d) =>
          d.wire != SenseWireKind.drop &&
          d.call == SenseCall.wire &&
          d.layout.hidden == SenseHidden.ear &&
          d.layout.hiddenPole == ((d.wireAt - kSensePole0) / kSenseSpan).floor());
      final c = await _open(t, seed);
      final w = _run.wireX!;
      final span = _run.brokenSpan!;
      await _walkTo(t, w - kSenseWireHalf - 23);
      expect(_run.wireReady, isTrue);
      await _settle(t);
      await _rope(t, 22);
      expect(_run.cordon, 22);
      await _reason(t, SenseWalkLines.whyRight[_run.deal.wireWhy]!);
      expect(_run.wirePassed, isFalse, reason: 'the ring does not move him on');
      // Walk on: he stops at the rope.
      await _walkTo(t, w, stopAtRope: true);
      expect(_run.atRope, isTrue);
      expect(_run.wirePassed, isFalse);
      expect(_run.nearest, span);
      expect(c.read(guideDirectorProvider).line, SenseWalkLines.askRound);
      await _sense(t, SenseWalkLines.earLabel);
      expect(find.text(SenseWalkLines.earYes), findsOneWidget);
      await _lookUp(t);
      await _tapAt(t, _top.partRect(_run.layout.hiddenPart).center);
      await _reason(t, SenseWalkLines.whyRight[SenseWhy.hidden]!);
      expect(_run.found, contains(SenseClue.hidden));
      await _lookDown(t);
      // The next walk goes round the ring.
      final g = await t.startGesture(_strip);
      await _pump(t, 400);
      await g.up();
      await _pump(t, 800);
      expect(_run.wirePassed, isTrue);
      expect(_run.pos, greaterThan(w + kSenseWireHalf + kSenseZone));
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a hidden clue tagged by sight alone is a slip (evidence first)', (t) async {
      final seed = _seedWhere((d) => d.layout.hidden == SenseHidden.ear && d.call == SenseCall.wire && d.layout.hiddenPole == 1);
      final c = await _open(t, seed);
      await _walkTo(t, sensePoleX(1) - 2);
      await _settle(t);
      await _lookUp(t);
      await _tapAt(t, _top.partRect(_run.layout.hiddenPart).center);
      await _pump(t, 400);
      expect(find.text(SenseWalkMistakes.blindTag.textBn), findsOneWidget);
      expect(_run.found, isNot(contains(SenseClue.hidden)));
      expect(c.read(gameSaveProvider).mistakes.single.key, SenseWalkMistakes.blindTag.key);
      await _close(t, c);
    });

    testWidgets('a rope ring under 10 m is a slip; the rope stays for a right one', (t) async {
      final seed = _seedWhere((d) => d.wire != SenseWireKind.drop && d.call == SenseCall.lookUp);
      final c = await _open(t, seed);
      await _walkTo(t, _run.wireX! - kSenseWireHalf - 12);
      await _settle(t);
      await _rope(t, 6);
      expect(find.text(SenseWalkMistakes.shortRing.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_run.wireReady, isTrue);
      await _rope(t, 11);
      await _reason(t, SenseWalkLines.whyRight[_run.deal.wireWhy]!);
      expect(c.read(gameSaveProvider).mistakes.single.key, SenseWalkMistakes.shortRing.key);
      await _close(t, c);
    });

    testWidgets('the coworker at the wire: the rope waits for him; listening (move the wire) = deadly freeze', (t) async {
      final seed = _seedWhere((d) => d.wire != SenseWireKind.drop && d.call == SenseCall.wire);
      final c = await _open(t, seed);
      await _walkTo(t, _run.wireX! - kSenseWireHalf - 12);
      // At once on the reel: he cuts in first; the rope does not go out.
      await t.startGesture(_geo.reel.center * _k).then((g) async {
        await g.moveBy(const Offset(-30, 0));
        await t.pump(const Duration(milliseconds: 100));
        await g.up();
      });
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_run.cordon, isNull);
      await _coworker(t, refuse: false);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, SenseWalkMistakes.touchWire.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the look-up push: listening = a stumble (a slip card)', (t) async {
      final seed = _seedWhere((d) => d.call == SenseCall.lookUp && d.gateX < (d.wire == SenseWireKind.drop ? d.wireAt - 12 : d.wireAt - 24));
      final c = await _open(t, seed);
      final g = await t.startGesture(_strip);
      for (var i = 0; i < 2500 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _coworker(t, refuse: false);
      await _pump(t, 600);
      expect(find.text(SenseWalkMistakes.lookWalk.textBn), findsOneWidget);
      expect(_run.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, SenseWalkMistakes.lookWalk.key);
      await _close(t, c);
    });

    testWidgets('a second finger swipes up while walking: he stumbles in the next pothole (a slip)', (t) async {
      final seed = _seedWhere((d) => d.call == SenseCall.wire && d.layout.potholes.first > kSenseStart + 3 && d.layout.potholes.first < d.wireAt - 16);
      final c = await _open(t, seed);
      final walk = await t.startGesture(_strip, pointer: 1);
      await _pump(t, 300);
      final look = await t.startGesture(const Offset(200, 420), pointer: 2);
      for (var i = 1; i <= 6; i++) {
        await look.moveBy(const Offset(0, -25));
        await t.pump(const Duration(milliseconds: 16));
      }
      await look.up();
      for (var i = 0; i < 400 && find.byType(MistakeCard).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      await walk.up();
      await _pump(t, 400);
      expect(find.text(SenseWalkMistakes.lookWalk.textBn), findsOneWidget);
      expect(_run.pos, _run.layout.potholes.firstWhere((h) => h > kSenseStart + 1));
      await _close(t, c);
    });

    testWidgets('section end with clues left: a card for each; a third slip strikes out', (t) async {
      final seed = _seedWhere((d) => d.wire != SenseWireKind.drop && d.call == SenseCall.lookUp);
      final c = await _open(t, seed);
      await _wireAhead(t);
      await _walkTo(t, _run.endX - 1);
      await _settle(t);
      await t.tap(_label(SenseWalkLines.endLabel));
      await _pump(t, 800);
      expect(find.text(SenseWalkMistakes.missUp.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.text(SenseWalkMistakes.missDown.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle → a hand (no press on any answer); none while walking; a drag at the rope', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.wire != SenseWireKind.drop && d.call == SenseCall.lookUp);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at a stop');
      // Walking: the hand goes at once and stays away.
      final g = await t.startGesture(_strip);
      await _pump(t, 600);
      expect(scene().showing, isFalse);
      await g.up();
      await _walkTo(t, _run.wireX! - kSenseWireHalf - 12);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'idle at the wire');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a drag, not a press on anything');
      expect(scene().debugFrame?.ring, isNull, reason: 'never the walk hold here');
      await _close(t, c);
    });
  });
}

/// He came this play (refused, in the flow tests).
bool coworkerSeen(SenseWalkRun r) =>
    r.caught.contains(SenseWalkLines.caughtCallWire) || r.caught.contains(SenseWalkLines.caughtCallLook);
