// Lesson 6.6 (এবি কেবিল), কাজ 1 "মেসেঞ্জারে ঝোলাও": the rules (a pull with a
// pole missing its roller = a slip and the cable goes back; the gloves are a
// free bag item; the first jaw closed bare-handed = deadly; an ordinary
// clamp, a suspension clamp at an end or a turn, a tension clamp on a
// straight pole = a slip and back into the pouch; a jaw on a phase core = a
// slip, stay in the lens; listening to the coworker = a slip), the deal, the
// libraries, every spoken line listed, the tap areas, the lens hint, and the
// level in the shell: the guide first, a full clean play (the pull reason,
// every pole with its reason, the coworker refused at the pouch), a scuffed
// pull, three slips, the deadly freeze, a wrong clamp and a phase core, the
// clamp drag waiting for the coworker, listening to him, and the gesture hand
// only while the level waits.
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
import 'package:slm_flutter/features/game/m6_abc_clamp_seat.dart';
import 'package:slm_flutter/features/game/m6_abc_clamp_seat_world.dart';
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
  rungId: '6.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6ClampPacks['do_6_6_a']!;
typedef L = M6ClampLines;
typedef Mk = M6ClampMistakes;

/// The art is read from disk when the test bundle does not have it.
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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
const _h = 360 * 850 / 392;
M6ClampGeo _geoOf(M6ClampDeal d) => M6ClampGeo.forScene(_h, 0, poles: d.poles, bend: d.bend);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6ClampSeatPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6ClampDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6ClampDeal(math.Random(s))));

// --- hands on ----------------------------------------------------------------
/// A bag item dragged out and dropped on [design] (scene px).
Future<void> _dragBag(WidgetTester t, M6ClampBag b, Offset design) async {
  final from = t.getCenter(_label(L.bag(b)));
  await t.dragFrom(from, design * _k - from);
  await _pump(t, 300);
}

Future<void> _rollers(WidgetTester t, M6ClampDeal d, {Set<int> skip = const {}}) async {
  final g = _geoOf(d);
  for (var i = 0; i < d.poles; i++) {
    if (!skip.contains(i)) await _dragBag(t, M6ClampBag.rollers, g.bracket(i));
  }
}

Future<void> _gloves(WidgetTester t, M6ClampDeal d) async {
  await _dragBag(t, M6ClampBag.gloves, _geoOf(d).traineeGround.center);
}

Future<void> _pullHold(WidgetTester t) async {
  await t.longPress(find.byKey(const ValueKey('pull-btn')));
  await _pump(t, 1800);
}

Future<void> _pouch(WidgetTester t) async {
  await t.tap(_label(L.bag(M6ClampBag.pouch)));
  await _pump(t, 300);
}

Future<void> _take(WidgetTester t, M6Clamp c) async {
  await t.drag(find.byKey(ValueKey('clamp-${c.name}')), const Offset(0, -120));
  await _pump(t, 500);
}

Future<void> _roll(WidgetTester t, M6ClampDeal d, {int dir = 1}) async {
  final g = _geoOf(d);
  await t.dragFrom(Offset(g.jawX + 60, g.bundleY + (dir > 0 ? 20 : -20)) * _k, Offset(0, dir > 0 ? -60 : 60));
  await _pump(t, 400);
}

/// Rolls until the messenger is under the jaw.
Future<void> _toMessenger(WidgetTester t, M6ClampDeal d) async {
  final r = M6ClampProbe.run!;
  for (var k = 0; k < 4 && r.coreUnder != 0; k++) {
    await _roll(t, d);
  }
  expect(r.coreUnder, 0);
}

Future<void> _bolt(WidgetTester t, M6ClampDeal d) async {
  await t.longPressAt(_geoOf(d).bolt * _k);
  await _pump(t, 500);
}

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// The pull done clean (rollers, gloves, 'টানুন', the reason).
Future<void> _cleanPull(WidgetTester t, M6ClampDeal d) async {
  await _rollers(t, d);
  await _gloves(t, d);
  final r = M6ClampProbe.run!;
  expect(r.rollers, hasLength(d.poles));
  expect(r.gloves, isTrue);
  await _pullHold(t);
  expect(find.byType(MistakeCard), findsNothing);
  expect(r.pulled, isTrue);
  await _pickRight(t, L.whyRight[M6ClampWhy.rollers]!);
  await _pump(t, 1200);
}

/// One pole done right: pouch, (the coworker), the right clamp, roll to the
/// messenger, the bolt, the reason.
Future<void> _clampPole(WidgetTester t, M6ClampDeal d, int i, {bool coworker = false}) async {
  final r = M6ClampProbe.run!;
  expect(r.pole, i);
  await _pouch(t);
  if (coworker) await _refuse(t);
  await _take(t, m6RightClamp(d.kind(i)));
  expect(r.held, m6RightClamp(d.kind(i)));
  await _toMessenger(t, d);
  await _bolt(t, d);
  expect(find.byType(MistakeCard), findsNothing, reason: 'pole $i');
  expect(r.closed, isTrue);
  await _pickRight(t, m6ClampWhyRight(r.whyNow!, d.messenger));
  await _pump(t, 1200);
}

Future<void> _nextPole(WidgetTester t, M6ClampDeal d, int i) async {
  await t.tapAt(_geoOf(d).poleHit(i).center * _k);
  await _pump(t, 700);
}

// --- pure helpers --------------------------------------------------------------
M6ClampDeal _deal({int poles = 3, int? bend = 1, M6Messenger messenger = M6Messenger.bare, List<int> starts = const [1, 2, 3, 0], int coworkerPole = 1}) => M6ClampDeal(
      poles: poles,
      bend: bend,
      messenger: messenger,
      order: const [0, 1, 2, 3],
      starts: starts.sublist(0, poles),
      bag: const [M6ClampBag.pouch, M6ClampBag.rollers, M6ClampBag.gloves],
      pouches: [for (var i = 0; i < poles; i++) const [M6Clamp.bare, M6Clamp.tension, M6Clamp.suspension]],
      coworkerPole: coworkerPole,
      whyRoll: 3,
    );

/// A run with the cable pulled clean (gloves on unless [gloves] is false) and
/// at pole 1.
M6ClampRun _atPoles({M6ClampDeal? deal, bool gloves = true}) {
  final r = M6ClampRun(deal ?? _deal());
  for (var i = 0; i < r.deal.poles; i++) {
    r.placeRoller(i);
  }
  if (gloves) r.wearGloves();
  expect(r.pull(), isNull);
  r.startPoles();
  return r;
}

/// Seat pole [r.pole] right (the right clamp, rolled to the messenger).
void _seatRight(M6ClampRun r) {
  r.openPouch();
  r.take(m6RightClamp(r.kindNow));
  while (r.coreUnder != 0) {
    r.roll(1);
  }
  expect(r.closeJaw(), isNull);
}

void main() {
  group('rules', () {
    test('deals: 3 or 4 poles, a turn at a middle pole or none, every messenger look, the bag, pouches and twists vary; plays differ', () {
      final seen = <String>{};
      final poles = <int>{};
      final bends = <String>{};
      final msgs = <M6Messenger>{};
      final bags = <String>{};
      final cw = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m6ClampDeal(math.Random(s));
        expect(d.poles, inInclusiveRange(3, 4));
        if (d.bend != null) expect(d.bend, inInclusiveRange(1, d.poles - 2), reason: 'the turn is at a middle pole');
        expect(d.order.toSet(), {0, 1, 2, 3});
        expect(d.starts, hasLength(d.poles));
        for (final st in d.starts) {
          expect(st, inInclusiveRange(0, 3));
        }
        expect(d.bag.toSet(), M6ClampBag.values.toSet());
        expect(d.pouches, hasLength(d.poles));
        for (final p in d.pouches) {
          expect(p.toSet(), M6Clamp.values.toSet());
        }
        expect(d.coworkerPole, inInclusiveRange(1, 2));
        expect(d.coworkerPole, lessThan(d.poles));
        expect(d.kind(0), M6PoleKind.end, reason: 'the run starts here');
        expect(d.kind(d.poles - 1), M6PoleKind.end, reason: 'a dead end');
        poles.add(d.poles);
        bends.add('${d.poles}/${d.bend}');
        msgs.add(d.messenger);
        bags.add(d.bag.map((b) => b.index).join());
        cw.add(d.coworkerPole);
        seen.add('${d.poles}${d.bend}${d.messenger.index}${d.order.join()}${d.starts.join()}${d.bag.map((b) => b.index).join()}${d.coworkerPole}');
      }
      expect(poles, {3, 4});
      expect(bends, containsAll(['3/null', '3/1', '4/null', '4/1', '4/2']));
      expect(msgs, M6Messenger.values.toSet());
      expect(bags, hasLength(6));
      expect(cw, {1, 2});
      expect(seen.length, greaterThan(250));
    });

    test('the right clamp: tension at an end or a turn, suspension on a straight pole', () {
      expect(m6RightClamp(M6PoleKind.end), M6Clamp.tension);
      expect(m6RightClamp(M6PoleKind.bend), M6Clamp.tension);
      expect(m6RightClamp(M6PoleKind.straight), M6Clamp.suspension);
      expect(m6PoleKind(1, 4, 2), M6PoleKind.straight);
      expect(m6PoleKind(2, 4, 2), M6PoleKind.bend);
      expect(m6PoleKind(1, 3, null), M6PoleKind.straight);
    });

    test('the pull: a pole with no roller scuffs (a slip, the cable back); rollers on every pole → pulled; gloves are free', () {
      final r = M6ClampRun(_deal());
      expect(r.placeRoller(0), isTrue);
      expect(r.placeRoller(0), isFalse, reason: 'already there');
      expect(r.placeRoller(2), isTrue);
      expect(r.pull(), Mk.noRoller);
      expect(r.scuffAt, 1);
      expect(r.pulled, isFalse);
      expect(r.slips, 1);
      r.clearScuff();
      expect(r.scuffAt, isNull);
      expect(r.wearGloves(), isTrue);
      expect(r.wearGloves(), isFalse);
      expect(r.slips, 1, reason: 'the gloves cost nothing');
      r.placeRoller(1);
      expect(r.pull(), isNull);
      expect(r.pulled, isTrue);
      expect(r.caught, isNot(contains(L.caughtRollers)), reason: 'a scuff first');
      expect(r.placeRoller(1), isFalse, reason: 'no rollers after the pull');
      r.startPoles();
      expect(r.stage, M6ClampStage.pole);
      expect(r.pole, 0);
      final c = _atPoles();
      expect(c.caught, contains(L.caughtRollers));
    });

    test('the first jaw closed with no gloves = deadly (R23), whatever clamp or core', () {
      final r = _atPoles(gloves: false);
      r.openPouch();
      expect(r.take(M6Clamp.tension), isTrue);
      final m = r.closeJaw();
      expect(m, Mk.bareHands);
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
      final b = _atPoles(gloves: false)..openPouch();
      b.take(M6Clamp.bare);
      expect(b.closeJaw(), Mk.bareHands, reason: 'the bare hand comes first');
      // Gloves on before any touch of the cable: safe.
      final c = _atPoles(gloves: false);
      c.wearGloves();
      _seatRight(c);
      expect(c.deadly, isNull);
    });

    test('the first roll of the bundle with no gloves = deadly too (a hand on the cable); gloves after it are too late', () {
      final r = _atPoles(gloves: false);
      r.openPouch();
      r.take(M6Clamp.suspension);
      final top = r.tops[r.pole];
      expect(r.roll(1), isTrue);
      expect(r.deadly, Mk.bareHands);
      expect(r.ended, isTrue);
      expect(r.tops[r.pole], top, reason: 'the bundle does not turn');
      expect(r.wearGloves(), isFalse, reason: 'too late');
      expect(r.closeJaw(), isNull);
      expect(r.slips, 0);
    });

    test('wrong clamps: ordinary / suspension at an end / tension on a straight = a slip and back into the pouch; a phase core = a slip, stay in the lens', () {
      final r = _atPoles();
      r.openPouch();
      expect(r.take(M6Clamp.bare), isTrue);
      expect(r.pouchOpen, isFalse);
      expect(r.closeJaw(), Mk.ordinaryClamp);
      expect(r.held, isNull);
      expect(r.pouchOpen, isTrue, reason: 'back into the pouch');
      r.take(M6Clamp.suspension);
      expect(r.closeJaw(), Mk.suspensionAtEnd, reason: 'pole 1 is an end');
      r.take(M6Clamp.tension);
      expect(r.coreUnder, isNot(0), reason: 'start 1 → a phase core');
      expect(r.closeJaw(), Mk.phaseCore);
      expect(r.held, M6Clamp.tension, reason: 'still in the lens');
      expect(r.slips, 3);
      while (r.coreUnder != 0) {
        r.roll(-1);
      }
      expect(r.closeJaw(), isNull);
      expect(r.closed, isTrue);
      expect(r.seated[0], M6Clamp.tension);
      r.poleDone();
      expect(r.stage, M6ClampStage.next);
      // A straight pole: tension = a slip.
      final s = _atPoles(deal: _deal(poles: 4, bend: 2));
      _seatRight(s);
      s.poleDone();
      expect(s.goTo(2), isFalse, reason: 'only the next pole');
      expect(s.goTo(1), isTrue);
      expect(s.kindNow, M6PoleKind.straight);
      s.openPouch();
      s.take(M6Clamp.tension);
      expect(s.closeJaw(), Mk.tensionOnStraight);
      s.take(M6Clamp.suspension);
      while (s.coreUnder != 0) {
        s.roll(1);
      }
      expect(s.closeJaw(), isNull);
    });

    test('the roll: up and down step through the four cores round the bundle; put back returns the clamp', () {
      final r = _atPoles(deal: _deal(starts: const [0, 0, 0, 0]));
      r.openPouch();
      r.take(M6Clamp.tension);
      expect(r.coreUnder, 0);
      r.roll(1);
      expect(r.coreUnder, 1);
      r.roll(1);
      r.roll(1);
      expect(r.coreUnder, 3);
      r.roll(1);
      expect(r.coreUnder, 0);
      r.roll(-1);
      expect(r.coreUnder, 3);
      expect(r.putBack(), isTrue);
      expect(r.held, isNull);
      expect(r.pouchOpen, isTrue);
      expect(r.roll(1), isFalse, reason: 'no clamp up');
      expect(r.slips, 0);
    });

    test('a clean run to the end: every pole seated right, the "caught" lines; listening is a slip (B1)', () {
      final r = _atPoles(deal: _deal(poles: 4, bend: 1));
      for (var i = 0; i < 4; i++) {
        if (i > 0) expect(r.goTo(i), isTrue);
        if (i == 1) expect(m6ClampCoworkerFits(r), isTrue);
        _seatRight(r);
        r.poleDone();
      }
      expect(r.finished, isTrue);
      expect(r.passed, isTrue);
      expect(r.seated, {0: M6Clamp.tension, 1: M6Clamp.tension, 2: M6Clamp.suspension, 3: M6Clamp.tension});
      expect(r.caught, containsAll([L.caughtRollers, L.caughtMessenger, L.caughtType, L.caughtGloves]));
      final l = _atPoles();
      _seatRight(l);
      l.poleDone();
      l.goTo(1);
      final m = l.listen();
      expect(m, Mk.listenAnyClamp);
      expect(m.deadly, isFalse);
      expect(l.slips, 1);
      expect(l.ended, isFalse);
      expect(m6ClampCoworkerFits(l), isTrue);
      _seatRight(l);
      expect(m6ClampCoworkerFits(l), isFalse, reason: 'his pole is seated');
    });

    test('three slips: the mark falls to 55, then 40', () {
      final r = M6ClampRun(_deal());
      for (var i = 0; i < 3; i++) {
        r.pull();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.pull();
      expect(r.percent, 40);
    });

    test('the reasons fit: the clamp type for the pole, never a topic twice, identify fits the messenger', () {
      for (var s = 0; s < 80; s++) {
        final d = m6ClampDeal(math.Random(s));
        final used = <M6ClampWhy>{M6ClampWhy.rollers};
        for (var i = 0; i < d.poles; i++) {
          final w = m6ClampPoleWhy(d, i, used);
          if (d.kind(i) == M6PoleKind.straight) {
            expect(w, isNot(M6ClampWhy.tension));
          } else {
            expect(w, isNot(M6ClampWhy.suspension));
          }
          expect(w, isNot(M6ClampWhy.rollers));
          if (used.length < 4) expect(used.contains(w), isFalse, reason: 'no repeat while others fit');
          used.add(w);
        }
      }
      final topics = <M6ClampWhy>{M6ClampWhy.rollers};
      for (var s = 0; s < 80; s++) {
        final d = m6ClampDeal(math.Random(s));
        for (var i = 0; i < d.poles; i++) {
          topics.add(m6ClampPoleWhy(d, i, {}));
        }
      }
      expect(topics, M6ClampWhy.values.toSet());
      expect(m6ClampWhyRight(M6ClampWhy.identify, M6Messenger.bare).first, contains('খোলা'));
    });

    test('English digits only; jol not pani; the owner term rules; every mistake has its picture; the deadly set; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.docket,
        L.pull,
        L.sceneLane,
        L.sceneLens,
        L.backBn,
        L.pouchTitle,
        ...L.stages,
        for (final b in M6ClampBag.values) L.bag(b),
        for (final c in M6Clamp.values) L.clamp(c),
        ...L.whyQ.values,
        ...m6ClampAllWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        L.callHeld,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtRollers,
        L.caughtMessenger,
        L.caughtType,
        L.caughtGloves,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp('এলটি|এইচটি|কেভি|অন |অফ ').hasMatch(l), isFalse, reason: l);
        // য় ড় ঢ় as base + nukta (the app's form).
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: l);
      }
      expect(L.docket, contains('শাটডাউন'));
      expect(L.bag(M6ClampBag.gloves), 'গ্লাভস');
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.bareHands});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.6/m6_abc_clamp_seat/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
      }
      // The lesson's own words, where the cards quote them.
      final lesson = File('tool/all_training_chapters_bn.json')
          .readAsStringSync()
          .replaceAll('\u09DF', '\u09AF\u09BC')
          .replaceAll('\u09DC', '\u09A1\u09BC')
          .replaceAll('\u09DD', '\u09A2\u09BC');
      expect(lesson.contains(L.coworker.line), isTrue, reason: 'myth 2 word for word');
      expect(lesson.contains('মেসেঞ্জার তারের বদলে ফেজ কন্ডাক্টরের ওপর ক্ল্যাম্প লাগালে কেবিলটি মারাত্মকভাবে ক্ষতিগ্রস্ত হবে এবং ছিঁড়ে যেতে পারে'), isTrue);
      expect(Mk.phaseCore.textBn, contains('মেসেঞ্জার তারের বদলে ফেজ কন্ডাক্টরের ওপর ক্ল্যাম্প লাগালে কেবিলটি মারাত্মকভাবে ক্ষতিগ্রস্ত হবে এবং ছিঁড়ে যেতে পারে'));
      expect(lesson.contains('অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট'), isTrue);
      expect(Mk.bareHands.textBn, contains('অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট'));
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_abc_clamp_seat/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m6_abc_clamp_seat').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6ClampPacks.keys, ['do_6_6_a']);
      expect(_pack.quickFor(4), 80000);
      expect(_pack.quickFor(3), 65000);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...m6ClampAllWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(m6ClampAllWhyRight.toSet()), isEmpty);
      for (final w in M6ClampWhy.values) {
        for (final m in M6Messenger.values) {
          final right = m6ClampWhyRight(w, m);
          expectLibrary('why $w $m', right, L.myths);
          for (var k = 0; k < 10; k++) {
            final deal = dealChoices(right, L.myths, math.Random(k));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
        expect(L.whyQ[w], isNotEmpty);
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      // The pouch's three tiles are one option group.
      expectSameLength('clamp names', [for (final c in M6Clamp.values) L.clamp(c)]);
    });

    test('every spoken line is listed: his push (myth 2) and every new guide line, the why questions and the mistake texts', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.newRivalLines, ['যেকোনো ক্ল্যাম্প দিয়েই এবি কেবিল লাগানো যায়।']);
      for (final q in L.whyQ.values) {
        expect(L.newGuideLines, contains(q));
      }
      for (final m in Mk.all) {
        expect(L.newGuideLines, contains(m.textBn), reason: m.key);
      }
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, L.callHeld, L.allSet, L.fail]));
      for (final a in L.coworker.asks) {
        if (a != 'কী করবেন?' && a != 'ওর কথা শুনবেন, না নিয়ম?') expect(L.newGuideLines, contains(a));
      }
      // Every other spoken guide line is recorded already, or listed.
      for (final l in [L.quick, L.deadlyWord, L.nearMissWord, ...L.tapWhy, ...L.coworker.asks]) {
        expect(LearnVoice.resolve(l) != null || L.newGuideLines.contains(l), isTrue, reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_abc_clamp_seat: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas: on the scene, below the header, above the bag row, clear of the guide; the lens parts apart', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        for (final poles in [3, 4]) {
          for (final bend in [null, 1, poles - 2]) {
            final g = M6ClampGeo.forScene(h, 0, poles: poles, bend: bend);
            final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
            final lane = <Rect>[for (var i = 0; i < poles; i++) ...[g.bracketHit(i), g.poleHit(i)]];
            final lens = <Rect>[g.bundleHit, g.boltHit, g.backHit];
            for (final r in [...lane, ...lens]) {
              expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
              expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
              expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
              expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the bag row');
              expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
            }
            for (var i = 0; i < poles - 1; i++) {
              expect(g.poleHit(i).overlaps(g.poleHit(i + 1)), isFalse, reason: 'h $h poles $poles: $i');
            }
            for (var i = 0; i < lens.length; i++) {
              for (var j = i + 1; j < lens.length; j++) {
                expect(lens[i].overlaps(lens[j]), isFalse, reason: 'h $h: lens $i/$j');
              }
              expect(g.lens.contains(lens[i].center), isTrue);
            }
          }
        }
      }
    });

    test('the lens hint shows the real touches (swipe up, swipe down; a hold on the bolt only after three misses) and never points at a core', () {
      final g = M6ClampGeo.forScene(_h, 0, poles: 3, bend: null);
      final dirs = <double>{};
      for (var n = 0; n < 8; n++) {
        final h = m6ClampLensHint(g, n, stuck: false);
        expect(h.kind, HintKind.swipe);
        expect(h.toward.dx, 0);
        dirs.add(h.toward.dy);
        expect(h.space, HintSpace.scene);
      }
      expect(dirs, {-1.0, 1.0});
      final holds = [for (var n = 0; n < 8; n++) m6ClampLensHint(g, n, stuck: true)].where((h) => h.kind == HintKind.hold).toList();
      expect(holds, isNotEmpty);
      for (final h in holds) {
        expect(h.at, g.bolt, reason: 'the bolt, whatever core is under the jaw');
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

    testWidgets('the guide comes first: a tap does not skip him; then the bag, the pull and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6ClampSeatPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      for (final b in M6ClampBag.values) {
        expect(_label(L.bag(b)), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('pull-btn')), findsOneWidget);
      expect(find.text(L.docket), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askPull)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final poles in [3, 4]) {
      testWidgets('a clean play ($poles poles): rollers, gloves, pull (a reason), every pole clamped with its reason, the coworker refused at the pouch → pass', (t) async {
        final seed = _seedWhere((d) => d.poles == poles && d.bend != null);
        final d = m6ClampDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _cleanPull(t, d);
        for (var i = 0; i < d.poles; i++) {
          if (i > 0) await _nextPole(t, d, i);
          await _clampPole(t, d, i, coworker: i == d.coworkerPole);
        }
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.6/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.6/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtType), findsOneWidget);
        expect(M6ClampProbe.run!.seated.length, d.poles);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a pull with a pole missing its roller: the slip card; the cable goes back; roller on, pull again → the reason', (t) async {
      final seed = _seedWhere((d) => d.poles == 3);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _rollers(t, d, skip: {1});
      await _pullHold(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.noRoller.textBn), findsOneWidget);
      expect(M6ClampProbe.run!.scuffAt, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(M6ClampProbe.run!.scuffAt, isNull, reason: 'back on the drum');
      await _dragBag(t, M6ClampBag.rollers, _geoOf(d).bracket(1));
      await _pullHold(t);
      expect(M6ClampProbe.run!.pulled, isTrue);
      await _pickRight(t, L.whyRight[M6ClampWhy.rollers]!);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noRoller.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _pullHold(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the first jaw closed with no gloves: the scene freezes first, then the card (deadly)', (t) async {
      final seed = _seedWhere((d) => d.poles == 3);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _rollers(t, d);
      await _pullHold(t);
      await _pickRight(t, L.whyRight[M6ClampWhy.rollers]!);
      await _pump(t, 1200);
      expect(_label(L.bag(M6ClampBag.gloves)), findsOneWidget, reason: 'never prompted, still in the bag');
      await _pouch(t);
      await _take(t, M6Clamp.tension);
      await _bolt(t, d);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.bareHands.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the first roll of the bundle with no gloves: the scene freezes, then the deadly card', (t) async {
      final seed = _seedWhere((d) => d.poles == 3);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _rollers(t, d);
      await _pullHold(t);
      await _pickRight(t, L.whyRight[M6ClampWhy.rollers]!);
      await _pump(t, 1200);
      await _pouch(t);
      await _take(t, M6Clamp.suspension);
      await _roll(t, d);
      expect(M6ClampProbe.run!.deadly, Mk.bareHands);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.bareHands.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a wrong clamp goes back into the pouch; a phase core keeps the lens; put back works; then right', (t) async {
      final seed = _seedWhere((d) => d.poles == 3 && d.order[d.starts[0]] != 0);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _cleanPull(t, d);
      final r = M6ClampProbe.run!;
      await _pouch(t);
      await _take(t, M6Clamp.suspension);
      expect(r.held, M6Clamp.suspension);
      // Put it back (no cost), then take it again and close: pole 1 is an end.
      await t.tapAt(_geoOf(d).backHit.center * _k);
      await _pump(t, 400);
      expect(r.held, isNull);
      expect(r.pouchOpen, isTrue);
      expect(r.slips, 0);
      await _take(t, M6Clamp.suspension);
      await _bolt(t, d);
      expect(find.text(Mk.suspensionAtEnd.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(r.pouchOpen, isTrue);
      await _take(t, M6Clamp.tension);
      await _bolt(t, d);
      expect(find.text(Mk.phaseCore.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(r.held, M6Clamp.tension, reason: 'still in the lens');
      await _toMessenger(t, d);
      await _bolt(t, d);
      expect(r.closed, isTrue);
      await _pickRight(t, m6ClampWhyRight(r.whyNow!, d.messenger));
      await _pump(t, 800);
      expect(r.stage, M6ClampStage.next);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.suspensionAtEnd.key, Mk.phaseCore.key]);
      await _close(t, c);
    });

    testWidgets('a fast hand at his pole: the clamp drag waits; he cuts in at once; listening = a slip card', (t) async {
      final seed = _seedWhere((d) => d.poles == 3 && d.coworkerPole == 1);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _cleanPull(t, d);
      await _clampPole(t, d, 0);
      await _nextPole(t, d, 1);
      await _pouch(t);
      await t.drag(find.byKey(ValueKey('clamp-${m6RightClamp(d.kind(1)).name}')), const Offset(0, -120));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(M6ClampProbe.run!.held, isNull, reason: 'the drag waited for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.text(Mk.listenAnyClamp.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listenAnyClamp.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byKey(const ValueKey('clamp-tension')), findsOneWidget, reason: 'the pouch is open again');
      await _close(t, c);
    });

    testWidgets('the ◆ on the table and its reason deck: the scene takes no touch', (t) async {
      final seed = _seedWhere((d) => d.poles == 3);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _rollers(t, d);
      await _gloves(t, d);
      await _pullHold(t);
      await waitChoiceDeck(t);
      // A tap on pole 2 now does nothing.
      await t.tapAt(_geoOf(d).poleHit(1).center * _k);
      await _pump(t, 300);
      expect(M6ClampProbe.run!.stage, M6ClampStage.pull);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[M6ClampWhy.rollers]!);
      await _pump(t, 1500);
      expect(M6ClampProbe.run!.stage, M6ClampStage.pole);
      await _close(t, c);
    });

    testWidgets('gesture hand: shows while the pull waits (no press), none while the reason deck is up; the lens gets its own', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.poles == 3);
      final d = m6ClampDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the pull');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep or a drag presses nothing');
      await _rollers(t, d);
      await _gloves(t, d);
      await _pullHold(t);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _pickRight(t, L.whyRight[M6ClampWhy.rollers]!);
      await _pump(t, 1200);
      await _pouch(t);
      await _take(t, M6Clamp.tension);
      // Three taps on nothing in the lens.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geoOf(d).lensEmpty * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses in the lens');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
