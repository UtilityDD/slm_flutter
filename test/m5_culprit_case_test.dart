// Lesson 5.3 (সাধারণ ফল্ট: অপরাধীদের প্যারেড), কাজ 1 "অপরাধী কে? সূত্রের
// সুতো": the deal (the bird spot every play, a chain spot in half, collateral
// at half the bird spots, real clues and same-kind decoys on free anchors,
// four cards with the truth), the phone (blurry from far, one pin per item,
// scenery pinned too), the case board (two threads charge, slots by the pick,
// the first wrong element is one slip, a "charge it" plan is deadly), the
// libraries, and the level in the shell: the guide first, tap-to-repeat, a
// full clean play over three spots with the coworker refused and every
// reason picked, a blurry shot, the coworker holding the board and his
// listen slip, three slips, the deadly freeze, the gesture hands.
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
import 'package:slm_flutter/features/game/m5_culprit_case.dart';
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
  rungId: '5.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5CulpritPacks['do_5_3_a']!;

/// Coworker lines with no recorded clip yet (the director records them with
/// tool/rival_clip.py): his push, lesson 5.3 myth 2 word for word.
const rivalLinesMissing = [
  'একটা পাখি মরে পড়ে আছে, ওটাকে সরিয়ে দিলেই লাইন চালু করা যাবে।',
];

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
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

/// Which culprit a real clue of [s] points at.
M5Culprit _owner(M5Spot s, M5Clue c) {
  if (c == M5Clue.birdFlash) return M5Culprit.bird;
  if (s.chain) return m5RealClues[M5Culprit.insulator]!.contains(c) ? M5Culprit.insulator : M5Culprit.tree;
  return s.culprit;
}

int _seedWhere(bool Function(M5CulpritDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m5CulpritDeal(math.Random(s))));

const _geoH = 360 * 850 / 392;
M5CulpritGeo get _geo => M5CulpritGeo.forScene(_geoH.clamp(560.0, 900.0), 0);

Future<ProviderContainer> _open(WidgetTester t, int seed, M5CulpritProbe probe) async {
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5CulpritCasePage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe)),
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

Future<void> _tapLabel(WidgetTester t, String l, {int ms = 300}) async {
  await t.tap(_label(l), warnIfMissed: false);
  await _pump(t, ms);
}

/// Raises the phone, zooms in, drags the view onto item [i] and shoots.
Future<void> _shootItem(WidgetTester t, M5CulpritProbe p, int i) async {
  if (p.phase == 'scene') await _tapLabel(t, M5CulpritLines.phone);
  expect(p.phase, 'aim');
  while (p.zoom < 2.5) {
    await _tapLabel(t, M5CulpritLines.zoomIn, ms: 150);
  }
  for (var k = 0; k < 4; k++) {
    final d = p.aim - p.itemDesign(i)!;
    if (d.distance < 1.5) break;
    await t.dragFrom(const Offset(196, 330), d * p.zoom * (392 / 360));
    await _pump(t, 100);
  }
  expect((p.aim - p.itemDesign(i)!).distance, lessThan(3), reason: 'aimed at item $i');
  await _tapLabel(t, M5CulpritLines.shutter);
}

Future<void> _openBoard(WidgetTester t, M5CulpritProbe p) async {
  if (p.phase == 'aim') await _tapLabel(t, M5CulpritLines.lower);
  await _tapLabel(t, M5CulpritLines.board, ms: 500);
}

Future<void> _thread(WidgetTester t, M5CulpritProbe p, String pin, M5Culprit card) async {
  final a = p.pinGlobal(pin)!;
  final b = p.cardGlobal(card)!;
  await t.dragFrom(a, b - a);
  await _pump(t, 250);
}

/// Opens a slot and picks the option [want] chooses.
Future<void> _slot(WidgetTester t, M5CulpritProbe p, String label, bool Function(ChoiceOption o) want) async {
  await _tapLabel(t, label, ms: 200);
  await waitChoiceDeck(t);
  final o = p.slotOptions.firstWhere(want);
  await t.tap(_label(o.textBn), warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 400);
}

Future<void> _refuseCoworker(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes as the board opens');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pickRight(t, M5CulpritLines.coworker.right);
  await _pump(t, 2600);
}

/// One spot played right: every real clue shot, threads to the truth, the
/// chain linked, the slots right, the case closed, the reason picked.
Future<void> _playSpot(WidgetTester t, M5CulpritProbe p) async {
  final run = p.run!;
  final s = run.spot;
  for (var i = 0; i < s.items.length; i++) {
    if (s.real[i]) await _shootItem(t, p, i);
  }
  expect(run.pins.where((x) => !x.sound), hasLength(s.real.where((r) => r).length));
  await _openBoard(t, p);
  expect(p.phase, 'board');
  if (run.index == run.deal.birdIndex) await _refuseCoworker(t);
  for (final pin in [...run.pins]) {
    await _thread(t, p, pin.id, _owner(s, s.items[pin.item!].clue));
  }
  expect(run.charged, s.truth);
  if (s.chain) {
    await t.tapAt(p.knobGlobal(M5Culprit.insulator)!);
    await _pump(t, 200);
    await t.tapAt(p.cardGlobal(M5Culprit.tree)!);
    await _pump(t, 250);
    expect(run.pick, const M5Pick.chain(M5Culprit.insulator, M5Culprit.tree));
  }
  if (run.needsType) await _slot(t, p, M5CulpritLines.typeSlot, (o) => o.correct);
  if (run.needsRemedy) await _slot(t, p, M5CulpritLines.remedySlot, (o) => o.correct);
  expect(run.canClose, isTrue);
  await _tapLabel(t, M5CulpritLines.close, ms: 600);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(run.spotDone, isTrue);
  expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue);
  await _pump(t, 600);
  await _pickRight(t, run.whyRight());
  await _pump(t, 2500);
}

M5Spot _spot({
  required M5Culprit culprit,
  required List<M5Placed> items,
  required List<bool> real,
  List<M5Culprit> cards = const [M5Culprit.tree, M5Culprit.insulator, M5Culprit.jumper, M5Culprit.bird],
  bool chain = false,
  bool toGround = false,
  bool collateral = false,
  bool bait = false,
  M5Why why = M5Why.culprit,
}) =>
    M5Spot(
      culprit: culprit,
      chain: chain,
      view: M5View(items: items, treeToGround: toGround, light: M5Light.sun, villager: false),
      real: real,
      cards: cards,
      why: why,
      collateral: collateral,
      chargeBait: bait,
    );

M5CulpritRun _runOf(M5Spot s) => M5CulpritRun(M5CulpritDeal(spots: [s, s, s], feeder: 4));

/// Pins every item of the spot (sharp shots on their anchors).
void _pinAll(M5CulpritRun r) {
  for (final p in r.spot.items) {
    expect(r.shoot(_geo.anchor(p.at, sagged: r.spot.view.has(M5Clue.sag)), 2.5, _geo), M5Shot.pinned);
  }
}

String _pinOf(M5CulpritRun r, int item) => r.pins.firstWhere((p) => p.item == item).id;

void main() {
  group('rules', () {
    test('deal: the bird spot every play, a chain spot in about half, collateral in about half; anchors free; four cards with the truth; plays differ', () {
      final seen = <String>{};
      var chains = 0;
      var birds = 0;
      var collateral = 0;
      var villagers = 0;
      final villagerAt = <String>{};
      for (var s = 0; s < 300; s++) {
        final d = m5CulpritDeal(math.Random(s));
        expect(d.spots, hasLength(3));
        expect(d.feeder, inInclusiveRange(1, 9));
        expect(d.spots.where((x) => x.culprit == M5Culprit.bird && !x.chain), hasLength(1));
        expect(d.birdIndex, inInclusiveRange(0, 2));
        final kinds = {for (final x in d.spots) x.chain ? 'chain' : x.culprit.name};
        expect(kinds, hasLength(3), reason: 'three different spots');
        if (d.spots.any((x) => x.chain)) chains++;
        for (final x in d.spots) {
          final nReal = x.real.where((r) => r).length;
          final nDecoy = x.real.where((r) => !r).length;
          expect(nReal, inInclusiveRange(2, 4), reason: '${x.culprit}');
          expect(nDecoy, inInclusiveRange(2, 3));
          expect(x.items.length, lessThanOrEqualTo(m5MaxPhotos));
          expect(x.items.map((p) => p.at).toSet(), hasLength(x.items.length), reason: 'one item per anchor');
          expect(x.items.map((p) => p.clue).toSet(), hasLength(x.items.length));
          expect(x.cards.toSet(), hasLength(4));
          expect(x.cards.toSet().containsAll(x.truth), isTrue);
          for (final (i, p) in x.items.indexed) {
            expect(m5AnchorsOf[p.clue], contains(p.at));
            if (x.real[i]) {
              expect(_owner(x, p.clue), isIn(x.truth), reason: '${p.clue}');
            } else {
              expect(m5Decoys.values.expand((l) => l), contains(p.clue));
            }
          }
          if (x.chain) {
            expect(x.truth, {M5Culprit.insulator, M5Culprit.tree});
            expect(x.why, M5Why.chain);
            expect(x.faultType, isNull);
            for (final c in x.truth) {
              expect([for (final (i, p) in x.items.indexed) if (x.real[i] && _owner(x, p.clue) == c) p].length, greaterThanOrEqualTo(2), reason: 'two clues each');
            }
          }
          if (x.culprit == M5Culprit.bird && !x.chain) {
            birds++;
            expect(x.why, M5Why.bird);
            if (x.collateral) {
              collateral++;
              expect(x.view.has(M5Clue.birdFlash), isTrue);
            }
          }
          if (x.villager) {
            villagers++;
            villagerAt.add(x.culprit == M5Culprit.tree ? 'tree-phase' : x.culprit.name);
            expect(x.chain, isFalse);
            expect(m5Loud(x), isTrue, reason: 'a blast fits ${x.culprit}');
            expect(x.culprit, isNot(M5Culprit.jumper));
            if (x.culprit == M5Culprit.tree) expect(x.view.treeToGround, isFalse, reason: 'across two wires only');
          }
          expect(x.faultAt, x.items[x.real.indexOf(true)].at);
        }
        expect(d.spots.where((x) => x.villager).length, lessThanOrEqualTo(1));
        seen.add([for (final x in d.spots) '${x.chain ? 'chain' : x.culprit.name}:${x.items.map((p) => '${p.clue.name}@${p.at.name}').join(',')}'].join('|'));
      }
      expect(chains, inInclusiveRange(100, 200));
      expect(collateral / birds, inInclusiveRange(0.3, 0.7));
      expect(villagers, inInclusiveRange(90, 210));
      expect(villagerAt, containsAll(['bird', 'la', 'kite', 'insulator', 'tree-phase']), reason: 'his blast is not a tell for one kind');
      expect(seen.length, greaterThan(280));
    });

    test('the phone: too far is blurry and pins nothing; a sharp shot pins its item once; plain scenery is pinned too; the board holds seven photos', () {
      final s = _spot(
        culprit: M5Culprit.insulator,
        items: const [M5Placed(M5Clue.carbon, M5Anchor.ins0), M5Placed(M5Clue.chips, M5Anchor.g0), M5Placed(M5Clue.dewInsulator, M5Anchor.ins2)],
        real: const [true, true, false],
      );
      final r = _runOf(s);
      final at = _geo.anchor(M5Anchor.ins0);
      expect(r.shoot(at, 1.5, _geo), M5Shot.blurry);
      expect(r.pins, isEmpty);
      expect(r.shoot(at.translate(6, 4), 2.5, _geo), M5Shot.pinned);
      expect(r.pins.single.item, 0);
      expect(r.shoot(at, 3, _geo), M5Shot.again, reason: 'the same item');
      final sky = Offset(300, _geo.topY - 40);
      expect(r.itemAt(sky, 2.5, _geo), isNull);
      expect(r.shoot(sky, 2.5, _geo), M5Shot.pinned);
      expect(r.pins.last.item, isNull);
      expect(r.isReal(r.pins.last), isFalse, reason: 'scenery is no clue');
      expect(r.shoot(sky.translate(10, 0), 2.5, _geo), M5Shot.again, reason: 'the same patch of sky');
      for (var k = 0; k < 10; k++) {
        r.shoot(Offset(20.0 + k * 34, _geo.groundY - 60), 2.5, _geo);
      }
      expect(r.photoCount, m5MaxPhotos);
      expect(r.shoot(Offset(20, _geo.topY), 2.5, _geo), M5Shot.full);
      expect(r.addSound(), isFalse, reason: 'no villager here');
    });

    test('the board: two threads charge a card; slots follow the pick; a thread moved off changes the pick and clears the slots', () {
      final s = _spot(
        culprit: M5Culprit.tree,
        toGround: true,
        items: const [M5Placed(M5Clue.branch, M5Anchor.wireA), M5Placed(M5Clue.armScar, M5Anchor.armL), M5Placed(M5Clue.wireCoil, M5Anchor.g2)],
        real: const [true, true, false],
      );
      final r = _runOf(s);
      _pinAll(r);
      r.thread(_pinOf(r, 0), M5Culprit.jumper);
      expect(r.charged, isEmpty);
      expect(r.canClose, isFalse);
      r.thread(_pinOf(r, 1), M5Culprit.jumper);
      expect(r.charged, {M5Culprit.jumper});
      expect(r.needsType, isFalse, reason: 'keyed to the pick (jumper), not the truth');
      expect(r.needsRemedy, isTrue);
      r.answerRemedy(r.remedyOptions(math.Random(1)).first);
      expect(r.canClose, isTrue);
      r.thread(_pinOf(r, 0), M5Culprit.tree);
      r.thread(_pinOf(r, 1), M5Culprit.tree);
      expect(r.pick, const M5Pick.single(M5Culprit.tree));
      expect(r.remedyAnswer, isNull, reason: 'a new pick clears the slots');
      expect(r.needsType, isTrue);
      expect(r.typeOptions(math.Random(2)).map((o) => o.textBn).toSet(), {for (final t in M5FaultType.values) M5CulpritLines.faultType(t)});
      expect(r.typeOptions(math.Random(2)).singleWhere((o) => o.correct).textBn, M5CulpritLines.faultType(M5FaultType.phaseEarth));
      r.thread(_pinOf(r, 1), null);
      expect(r.charged, isEmpty);
    });

    test('closing: a decoy thread, then the culprit, the type, the remedy — the first wrong one is one slip; right closes the case', () {
      final s = _spot(
        culprit: M5Culprit.tree,
        items: const [M5Placed(M5Clue.branch, M5Anchor.wireA), M5Placed(M5Clue.sag, M5Anchor.wireB), M5Placed(M5Clue.prunedPile, M5Anchor.g2)],
        real: const [true, true, false],
        why: M5Why.type,
      );
      expect(s.faultType, M5FaultType.phasePhase, reason: 'across two wires');
      final r = _runOf(s);
      _pinAll(r);
      // A decoy as evidence, on top of a right board.
      r.thread(_pinOf(r, 0), M5Culprit.tree);
      r.thread(_pinOf(r, 1), M5Culprit.tree);
      r.thread(_pinOf(r, 2), M5Culprit.tree);
      r.answerType(M5CulpritLines.faultType(M5FaultType.phasePhase));
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.tree]!.first, true));
      expect(r.close(), M5CulpritMistakes.decoy);
      expect(r.slips, 1, reason: 'one slip per close');
      r.thread(_pinOf(r, 2), null);
      // The wrong type.
      r.answerType(M5CulpritLines.faultType(M5FaultType.phaseEarth));
      expect(r.close(), M5CulpritMistakes.typeTree);
      r.answerType(M5CulpritLines.faultType(M5FaultType.phasePhase));
      // A wrong remedy.
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyWrong[M5Remedy.tree]!.first, false));
      expect(r.close(), M5CulpritMistakes.remedyTree);
      expect(r.slips, 3);
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.tree]!.last, true));
      expect(r.close(), isNull);
      expect(r.spotDone, isTrue);
      expect(r.caught, contains(M5CulpritLines.caughtCulprit));
      expect(r.whyQuestion(), M5CulpritLines.whyTypePhaseQ);
      expect(r.whyRight(), M5CulpritLines.whyTreePhase);
      r.next();
      expect(r.pins, isEmpty);
      expect(r.threads, isEmpty);
      expect(r.spotSlips, 0);
    });

    test('closing: the wrong culprit names the true one; a "charge it and see" plan is deadly before anything else', () {
      final s = _spot(
        culprit: M5Culprit.jumper,
        items: const [M5Placed(M5Clue.pgMelt, M5Anchor.wireC), M5Placed(M5Clue.sleeveHot, M5Anchor.wireA), M5Placed(M5Clue.newClamp, M5Anchor.wireD)],
        real: const [true, true, false],
        bait: true,
      );
      final r = _runOf(s);
      _pinAll(r);
      r.thread(_pinOf(r, 0), M5Culprit.insulator);
      r.thread(_pinOf(r, 1), M5Culprit.insulator);
      r.answerType(M5CulpritLines.faultType(M5FaultType.phaseEarth));
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.insulator]!.first, false));
      expect(r.close(), M5CulpritMistakes.culpritJumper);
      expect(M5CulpritMistakes.culpritJumper.lessonPoint, 2);
      r.thread(_pinOf(r, 0), M5Culprit.jumper);
      r.thread(_pinOf(r, 1), M5Culprit.jumper);
      final deck = r.remedyOptions(math.Random(3));
      expect(deck.map((o) => o.textBn), contains(M5CulpritLines.charge), reason: 'a bait spot');
      expect(deck.where((o) => o.correct), hasLength(1));
      r.answerRemedy(deck.firstWhere((o) => o.textBn == M5CulpritLines.charge));
      final m = r.close();
      expect(m, M5CulpritMistakes.chargeTest);
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.slips, 1);
    });

    test('a chain spot: only the branch is a slip; the insulator, then the branch, linked, closes it; the deck is the chain\'s', () {
      final s = _spot(
        culprit: M5Culprit.tree,
        chain: true,
        items: const [
          M5Placed(M5Clue.pinCrack, M5Anchor.ins0),
          M5Placed(M5Clue.chips, M5Anchor.g0),
          M5Placed(M5Clue.sag, M5Anchor.wireB),
          M5Placed(M5Clue.branch, M5Anchor.wireA),
          M5Placed(M5Clue.liveCrow, M5Anchor.armR),
        ],
        real: const [true, true, true, true, false],
        why: M5Why.chain,
      );
      final r = _runOf(s);
      _pinAll(r);
      // Only the insulator: half the chain (the branch is missing) — the chain card.
      r.thread(_pinOf(r, 0), M5Culprit.insulator);
      r.thread(_pinOf(r, 1), M5Culprit.insulator);
      r.answerType(M5CulpritLines.faultType(M5FaultType.phaseEarth));
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.insulator]!.first, true));
      expect(r.close(), M5CulpritMistakes.chain, reason: 'only the insulator');
      r.thread(_pinOf(r, 0), null);
      r.thread(_pinOf(r, 1), null);
      // Neither end: the insulator (where it starts) was missed.
      r.thread(_pinOf(r, 0), M5Culprit.jumper);
      r.thread(_pinOf(r, 1), M5Culprit.jumper);
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.jumper]!.first, true));
      expect(r.close(), M5CulpritMistakes.culpritInsulator, reason: 'neither end');
      r.thread(_pinOf(r, 0), null);
      r.thread(_pinOf(r, 1), null);
      r.thread(_pinOf(r, 2), M5Culprit.tree);
      r.thread(_pinOf(r, 3), M5Culprit.tree);
      r.answerType(M5CulpritLines.faultType(M5FaultType.phaseEarth));
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.tree]!.first, true));
      expect(r.close(), M5CulpritMistakes.chain, reason: 'only the branch');
      r.thread(_pinOf(r, 0), M5Culprit.insulator);
      r.thread(_pinOf(r, 1), M5Culprit.insulator);
      expect(r.pick, isNull, reason: 'two charged, no chain yet');
      expect(r.canClose, isTrue);
      expect(r.close(), M5CulpritMistakes.chain);
      r.link(M5Culprit.tree, M5Culprit.insulator);
      expect(r.remedyFor(r.pick), M5Remedy.chain);
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.chain]!.first, true));
      expect(r.close(), M5CulpritMistakes.chain, reason: 'the branch first');
      r.link(M5Culprit.insulator, M5Culprit.tree);
      expect(r.needsType, isFalse);
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.chain]!.last, true));
      expect(r.close(), isNull);
      expect(r.caught, contains(M5CulpritLines.caughtChain));
      expect(r.whyRight(), M5CulpritLines.whyChain);
    });

    test('the bird spot: "no damage" when the bird left a flash mark is its own slip; the coworker\'s listen is a slip', () {
      final s = _spot(
        culprit: M5Culprit.bird,
        collateral: true,
        items: const [
          M5Placed(M5Clue.birdBody, M5Anchor.g1),
          M5Placed(M5Clue.blood, M5Anchor.wireC),
          M5Placed(M5Clue.birdFlash, M5Anchor.ins1),
          M5Placed(M5Clue.liveCrow, M5Anchor.wireA),
        ],
        real: const [true, true, true, false],
        why: M5Why.bird,
      );
      final r = _runOf(s);
      _pinAll(r);
      r.thread(_pinOf(r, 0), M5Culprit.bird);
      r.thread(_pinOf(r, 2), M5Culprit.bird);
      expect(r.remedyFor(r.pick), M5Remedy.birdHurt);
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.birdClean]!.first, false));
      expect(r.close(), M5CulpritMistakes.birdDamage);
      expect(r.listened(), M5CulpritMistakes.listen);
      expect(r.slips, 2);
      r.answerRemedy(ChoiceOption(M5CulpritLines.remedyRight[M5Remedy.birdHurt]!.first, true));
      expect(r.close(), isNull);
      expect(r.whyQuestion(), M5CulpritLines.whyBirdQ);
      // No collateral: "no damage" is the right one.
      final clean = _runOf(_spot(
        culprit: M5Culprit.bird,
        items: const [M5Placed(M5Clue.birdBody, M5Anchor.g1), M5Placed(M5Clue.blood, M5Anchor.wireC), M5Placed(M5Clue.dewInsulator, M5Anchor.ins1)],
        real: const [true, true, false],
      ));
      _pinAll(clean);
      clean.thread(_pinOf(clean, 0), M5Culprit.bird);
      clean.thread(_pinOf(clean, 1), M5Culprit.bird);
      expect(clean.remedyFor(clean.pick), M5Remedy.birdClean);
    });

    test('the LA and the kite have no type and no remedy slot (the lesson gives none); the sound card is a real clue', () {
      final s = M5Spot(
        culprit: M5Culprit.la,
        chain: false,
        view: const M5View(
          items: [M5Placed(M5Clue.laBlown, M5Anchor.la), M5Placed(M5Clue.earthPit, M5Anchor.g1), M5Placed(M5Clue.flagStall, M5Anchor.stall)],
          treeToGround: false,
          light: M5Light.haze,
          villager: true,
        ),
        real: const [true, false, false],
        cards: const [M5Culprit.la, M5Culprit.kite, M5Culprit.bird, M5Culprit.tree],
        why: M5Why.culprit,
      );
      final r = _runOf(s);
      _pinAll(r);
      expect(r.addSound(), isTrue);
      expect(r.addSound(), isFalse, reason: 'once');
      r.thread(_pinOf(r, 0), M5Culprit.la);
      r.thread('snd', M5Culprit.la);
      expect(r.needsType, isFalse);
      expect(r.needsRemedy, isFalse);
      expect(r.canClose, isTrue);
      expect(r.close(), isNull);
    });

    test('English digits only; every mistake has its picture; one deadly; keys unique; lesson points in range', () {
      final all = <String>[
        M5CulpritLines.intro,
        ...M5CulpritLines.tasks,
        M5CulpritLines.blurry,
        M5CulpritLines.villager,
        ...M5CulpritLines.allWhyRight,
        ...M5CulpritLines.myths,
        ...M5CulpritLines.allRemedy,
        ...M5CulpritLines.coworker.recordedLines,
        ...M5CulpritLines.coworker.right,
        ...M5CulpritLines.coworker.wrong,
        ...M5CulpritLines.coworker.asks,
        for (final m in M5CulpritMistakes.all) m.textBn,
        M5CulpritLines.allSet,
        M5CulpritLines.fail,
        for (var f = 1; f <= 9; f++) M5CulpritLines.docket(f),
        ...M5CulpritLines.spots,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5CulpritMistakes.all.where((m) => m.deadly), [M5CulpritMistakes.chargeTest]);
      expect(M5CulpritMistakes.all.map((m) => m.key).toSet(), hasLength(M5CulpritMistakes.all.length));
      for (final m in M5CulpritMistakes.all) {
        expect(m.key, startsWith('5.3/m5_culprit_case/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(m5CulpritPacks.keys, ['do_5_3_a']);
      expect(M5CulpritLines.coworker.line, rivalLinesMissing.single, reason: 'lesson 5.3 myth 2, word for word');
    });

    test('libraries: same length, big enough, one right per deal, never a rule marked wrong; his exit line is recorded', () {
      expectSameLength('why', [...M5CulpritLines.allWhyRight, ...M5CulpritLines.myths]);
      expect(M5CulpritLines.myths.toSet().intersection(M5CulpritLines.allWhyRight.toSet()), isEmpty);
      final whyLibs = [
        ...M5CulpritLines.whyCulprit.values,
        M5CulpritLines.whyTreeEarth,
        M5CulpritLines.whyTreePhase,
        M5CulpritLines.whyInsulatorEarth,
        ...M5CulpritLines.whyRemedy.values,
        M5CulpritLines.whyChain,
        M5CulpritLines.whyBird,
      ];
      for (final right in whyLibs) {
        expectLibrary('why ${right.first}', right, M5CulpritLines.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M5CulpritLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('remedy', M5CulpritLines.allRemedy);
      for (final r in M5Remedy.values) {
        final right = M5CulpritLines.remedyRight[r]!;
        final wrong = M5CulpritLines.remedyWrong[r]!;
        expectLibrary('remedy $r', right, wrong);
        expect(wrong.toSet().intersection(right.toSet()), isEmpty);
        expect(wrong, isNot(contains(M5CulpritLines.charge)));
      }
      // Dealt remedy decks: one right, three different, the charge plan only at a bait spot.
      for (var seed = 0; seed < 40; seed++) {
        final d = m5CulpritDeal(math.Random(seed));
        for (final s in d.spots) {
          final r = M5CulpritRun(M5CulpritDeal(spots: [s], feeder: 1));
          for (final c in s.truth) {
            final pin = [for (final (i, p) in s.items.indexed) if (s.real[i] && _owner(s, p.clue) == c) i];
            for (final i in pin) {
              r.shoot(_geo.anchor(s.items[i].at, sagged: s.view.has(M5Clue.sag)), 2.5, _geo);
              r.thread(r.pins.last.id, c);
            }
          }
          if (s.chain) r.link(M5Culprit.insulator, M5Culprit.tree);
          expect(r.charged, s.truth, reason: 'seed $seed ${s.culprit}');
          final deck = r.remedyOptions(math.Random(seed));
          if (!r.needsRemedy) {
            expect(deck, isEmpty);
            continue;
          }
          expect(deck, hasLength(3));
          expect(deck.where((o) => o.correct), hasLength(1));
          expect(deck.map((o) => o.textBn).toSet(), hasLength(3));
          expect(deck.any((o) => o.textBn == M5CulpritLines.charge), s.chargeBait);
        }
      }
      final cw = M5CulpritLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('the bird deck never tells the damage: one "no damage", one "replace", one other — at clean and hurt spots alike', () {
      final clean = M5CulpritLines.remedyRight[M5Remedy.birdClean]!;
      final hurt = M5CulpritLines.remedyRight[M5Remedy.birdHurt]!;
      String kind(String t) => clean.contains(t)
          ? 'clean'
          : hurt.contains(t)
              ? 'hurt'
              : t == M5CulpritLines.charge
                  ? 'charge'
                  : 'other';
      final kindsBy = {true: <String>{}, false: <String>{}};
      final textsBy = {true: <String>{}, false: <String>{}};
      var n = 0;
      for (var seed = 0; seed < 400; seed++) {
        final d = m5CulpritDeal(math.Random(seed));
        final s = d.spots[d.birdIndex];
        final r = M5CulpritRun(M5CulpritDeal(spots: [s], feeder: 1));
        for (final (i, p) in s.items.indexed) {
          if (!s.real[i]) continue;
          r.shoot(_geo.anchor(p.at, sagged: s.view.has(M5Clue.sag)), 2.5, _geo);
          r.thread(r.pins.last.id, M5Culprit.bird);
        }
        expect(r.pick, const M5Pick.single(M5Culprit.bird));
        final deck = r.remedyOptions(math.Random(seed * 7 + 1));
        expect(deck, hasLength(3));
        final kinds = [for (final o in deck) kind(o.textBn)]..sort();
        expect(kinds, s.chargeBait ? ['charge', 'clean', 'hurt'] : ['clean', 'hurt', 'other'], reason: 'seed $seed');
        expect(deck.singleWhere((o) => o.correct).textBn, isIn(s.collateral ? hurt : clean));
        kindsBy[s.collateral]!.add(kinds.join(','));
        textsBy[s.collateral]!.addAll(deck.map((o) => o.textBn));
        n++;
      }
      expect(n, 400);
      expect(kindsBy[true], kindsBy[false], reason: 'the same mix with and without damage');
      expect(textsBy[true], textsBy[false], reason: 'no card only in one kind of deck');
    });

    test('a re-opened remedy slot shows the same cards; a new spot deals afresh', () {
      final s = _spot(
        culprit: M5Culprit.jumper,
        items: const [M5Placed(M5Clue.pgMelt, M5Anchor.wireC), M5Placed(M5Clue.sleeveHot, M5Anchor.wireA), M5Placed(M5Clue.newClamp, M5Anchor.wireD)],
        real: const [true, true, false],
      );
      final r = _runOf(s);
      _pinAll(r);
      r.thread(_pinOf(r, 0), M5Culprit.jumper);
      r.thread(_pinOf(r, 1), M5Culprit.jumper);
      final rng = math.Random(9);
      final first = [for (final o in r.remedyOptions(rng)) o.textBn];
      r.answerRemedy(r.remedyOptions(rng).firstWhere((o) => !o.correct));
      for (var k = 0; k < 6; k++) {
        expect([for (final o in r.remedyOptions(rng)) o.textBn], first, reason: 'open $k');
      }
      // Thread off and on again (the pick goes and comes back): still the same deck.
      r.thread(_pinOf(r, 1), null);
      expect(r.remedyOptions(rng), isEmpty);
      r.thread(_pinOf(r, 1), M5Culprit.jumper);
      expect([for (final o in r.remedyOptions(rng)) o.textBn], first);
      // Another pick deals its own deck once, too.
      r.thread(_pinOf(r, 0), M5Culprit.insulator);
      r.thread(_pinOf(r, 1), M5Culprit.insulator);
      final ins = [for (final o in r.remedyOptions(rng)) o.textBn];
      expect(ins.toSet().intersection(M5CulpritLines.remedyRight[M5Remedy.insulator]!.toSet()), hasLength(1));
      expect([for (final o in r.remedyOptions(rng)) o.textBn], ins);
      // The next spot deals afresh (with the rng it is given now).
      r.next();
      _pinAll(r);
      r.thread(_pinOf(r, 0), M5Culprit.jumper);
      r.thread(_pinOf(r, 1), M5Culprit.jumper);
      final fresh = _runOf(s);
      _pinAll(fresh);
      fresh.thread(_pinOf(fresh, 0), M5Culprit.jumper);
      fresh.thread(_pinOf(fresh, 1), M5Culprit.jumper);
      final again = [for (final o in r.remedyOptions(math.Random(100))) o.textBn];
      expect(again, [for (final o in fresh.remedyOptions(math.Random(100))) o.textBn]);
      expect(again, isNot(first), reason: 'not the deck of the spot before');
    });

    test('the board drag hint ends in the gap above the cards, never on a pin', () {
      for (final size in const [Size(360, 700), Size(392, 850), Size(430, 932)]) {
        final l = M5BoardLayout.of(size, const EdgeInsets.only(top: 24, bottom: 16));
        for (var n = 1; n <= m5MaxPhotos + 1; n++) {
          final (from, travel) = l.pinDragHint(n);
          expect(l.pins.take(n).any((r) => r.contains(from)), isTrue, reason: 'starts on a pin ($n)');
          final end = from + Offset(0, travel);
          for (final r in l.pins.take(n)) {
            expect(r.contains(end), isFalse, reason: '$size, $n pins');
          }
          expect(end.dy, lessThan(l.cards.first.top), reason: 'above the cards');
          expect(travel, lessThanOrEqualTo(HintSpec.maxDragTravel));
        }
      }
    });

    test('one act, one class: only the deadly plan re-energizes the line; no slip card or coworker answer does', () {
      final energize = RegExp('চালু|চার্জ');
      final slipTexts = [
        for (final l in M5CulpritLines.remedyRight.values) ...l,
        for (final l in M5CulpritLines.remedyWrong.values) ...l,
        ...M5CulpritLines.coworker.right,
        ...M5CulpritLines.coworker.wrong,
      ];
      for (final t in slipTexts) {
        expect(energize.hasMatch(t), isFalse, reason: t);
      }
      expect(energize.hasMatch(M5CulpritLines.charge), isTrue);
    });

    test('anchors: on the 360-wide world, apart enough for a sharp shot, clear of the trainee', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5CulpritGeo.forScene(h, 0);
        final pts = {for (final a in M5Anchor.values) a: g.anchor(a)};
        for (final p in pts.values) {
          expect(p.dx, inInclusiveRange(0, 360));
          expect(p.dy, greaterThan(100), reason: 'below the header');
          expect(g.trainee.contains(p), isFalse);
        }
        final list = pts.entries.toList();
        for (var i = 0; i < list.length; i++) {
          for (var j = i + 1; j < list.length; j++) {
            expect((list[i].value - list[j].value).distance, greaterThan(m5ShotReach(2.5)), reason: 'h $h: ${list[i].key}/${list[j].key}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the phone', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5CulpritCasePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5CulpritLines.phone), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5CulpritLines.phone), findsOneWidget);
      expect(find.text(M5CulpritLines.docket(m5CulpritDeal(math.Random(3)).feeder)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final p = M5CulpritProbe();
      final c = await _open(t, 5, p);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5CulpritLines.askShoot)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final chain in [true, false]) {
      testWidgets('flow (${chain ? 'with' : 'no'} chain): shoot the clues, thread, refuse him, slots, close, reasons → pass', (t) async {
        final seed = _seedWhere((d) => d.spots.any((s) => s.chain) == chain && d.spots.every((s) => !s.villager));
        final p = M5CulpritProbe();
        final c = await _open(t, seed, p);
        for (var k = 0; k < 3; k++) {
          expect(p.run!.index, k);
          await _playSpot(t, p);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.3/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.3/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5CulpritLines.caughtCall), findsOneWidget);
        if (chain) expect(find.text(M5CulpritLines.caughtChain), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a shot from too far is blurry: no pin, and only then the guide says so', (t) async {
      final p = M5CulpritProbe();
      final c = await _open(t, 8, p);
      await _tapLabel(t, M5CulpritLines.phone);
      expect(c.read(guideDirectorProvider).line, isNot(M5CulpritLines.blurry));
      await _tapLabel(t, M5CulpritLines.shutter, ms: 600);
      expect(p.run!.pins, isEmpty);
      expect(c.read(guideDirectorProvider).line, M5CulpritLines.blurry);
      expect(find.byType(MistakeCard), findsNothing, reason: 'not a mistake');
      await _close(t, c);
    });

    testWidgets('the villager: a tap gives the sound card (his line on the device voice)', (t) async {
      final seed = _seedWhere((d) => d.spots.first.villager);
      final p = M5CulpritProbe();
      final c = await _open(t, seed, p);
      final g = p.sceneGlobal(M5CulpritGeo.forScene(_geoH, 0).villager.center)!;
      await t.tapAt(g);
      await _pump(t, 400);
      expect(p.run!.soundPinned, isTrue);
      expect(find.text(M5CulpritLines.villager), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the bird spot: the board waits for him (a fast thread brings him in); listening is a slip', (t) async {
      final seed = _seedWhere((d) => d.birdIndex == 0 && !d.spots.first.villager);
      final p = M5CulpritProbe();
      final c = await _open(t, seed, p);
      final s = p.run!.spot;
      final reals = [for (var i = 0; i < s.items.length; i++) if (s.real[i]) i];
      await _shootItem(t, p, reals[0]);
      await _shootItem(t, p, reals[1]);
      await _openBoard(t, p);
      // At once: well inside his 1.2–2.4 s timer.
      final a = p.pinGlobal(p.run!.pins.first.id)!;
      final b = p.cardGlobal(M5Culprit.bird)!;
      await t.dragFrom(a, b - a);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(p.run!.threads, isEmpty, reason: 'the thread waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5CulpritLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5CulpritMistakes.listen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CulpritMistakes.listen.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(p.phase, 'board', reason: 'the same spot goes on');
      await _thread(t, p, p.run!.pins.first.id, M5Culprit.bird);
      expect(p.run!.threads, hasLength(1));
      await _close(t, c);
    });

    testWidgets('three slips (decoys threaded as evidence) strike the level out', (t) async {
      final seed = _seedWhere((d) => d.birdIndex != 0 && !d.spots.first.villager);
      final p = M5CulpritProbe();
      final c = await _open(t, seed, p);
      final s = p.run!.spot;
      final decoys = [for (var i = 0; i < s.items.length; i++) if (!s.real[i]) i];
      await _shootItem(t, p, decoys[0]);
      await _shootItem(t, p, decoys[1]);
      await _openBoard(t, p);
      final card = s.cards.firstWhere((x) => x == M5Culprit.la || x == M5Culprit.kite, orElse: () => s.cards.first);
      for (final pin in [...p.run!.pins]) {
        await _thread(t, p, pin.id, card);
      }
      if (p.run!.needsType) await _slot(t, p, M5CulpritLines.typeSlot, (_) => true);
      if (p.run!.needsRemedy) await _slot(t, p, M5CulpritLines.remedySlot, (o) => o.textBn != M5CulpritLines.charge);
      for (var i = 0; i < 3; i++) {
        await _tapLabel(t, M5CulpritLines.close, ms: 700);
        if (i < 2) {
          expect(find.text(M5CulpritMistakes.decoy.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a "charge it and see" plan: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) {
        final s = d.spots.first;
        return d.birdIndex != 0 && !s.villager && s.chargeBait && !s.chain && const {M5Culprit.tree, M5Culprit.insulator, M5Culprit.jumper}.contains(s.culprit);
      });
      final p = M5CulpritProbe();
      final c = await _open(t, seed, p);
      final s = p.run!.spot;
      for (var i = 0; i < s.items.length; i++) {
        if (s.real[i]) await _shootItem(t, p, i);
      }
      await _openBoard(t, p);
      for (final pin in [...p.run!.pins]) {
        await _thread(t, p, pin.id, s.culprit);
      }
      if (p.run!.needsType) await _slot(t, p, M5CulpritLines.typeSlot, (o) => o.correct);
      await _slot(t, p, M5CulpritLines.remedySlot, (o) => o.textBn == M5CulpritLines.charge);
      await _tapLabel(t, M5CulpritLines.close, ms: 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.mistakes.single.key, M5CulpritMistakes.chargeTest.key);
      expect(save.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('gesture hands: the phone (tap), zoom-in (tap), a drag on the sky, a drag from the first pin; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.birdIndex != 0 && !d.spots.first.villager);
      final p = M5CulpritProbe();
      final c = await _open(t, seed, p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the scene');
      expect(scene().debugFrame?.trailFrom, isNull);
      await _tapLabel(t, M5CulpritLines.phone);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the phone, too far');
      await _tapLabel(t, M5CulpritLines.zoomIn);
      await _tapLabel(t, M5CulpritLines.zoomIn);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the phone, close');
      final s = p.run!.spot;
      final reals = [for (var i = 0; i < s.items.length; i++) if (s.real[i]) i];
      await _shootItem(t, p, reals[0]);
      await _shootItem(t, p, reals[1]);
      await _openBoard(t, p);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the board');
      // A charged card with a slot: the slot deck has its own sweep; the scene's hand stays away.
      final card = s.culprit;
      for (final pin in [...p.run!.pins]) {
        await _thread(t, p, pin.id, card);
      }
      if (p.run!.needsType || p.run!.needsRemedy) {
        await _tapLabel(t, p.run!.needsType ? M5CulpritLines.typeSlot : M5CulpritLines.remedySlot);
        await waitChoiceDeck(t);
        await _pump(t, 9000);
        expect(scene().showing, isFalse, reason: 'a deck is up');
      }
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
