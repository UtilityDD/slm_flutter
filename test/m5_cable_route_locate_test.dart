// Lesson 5.9 (কেবিল ফল্ট খোঁজা), কাজ 2 "মাটির নিচের সূত্র" (m5_cable_route_locate):
// the rules (map first; the docket's branch; pins on the route only; open and
// judge every joint pit on the route; the team only after the walk and with
// no clue missed; the TDR call (ARM on a blank trace); the wheel within
// ±10 m; the chalk at the thump peak; phone the owners before the peg), the
// deal (variety, one street with nothing on the route, B1 only where the team
// comes), the libraries, and the level in the shell: idle perf, the guide
// first, a full clean play (both coworker pushes, reasons), a slip card that
// keeps the street, three slips, no deadly act (no freeze), the coworker
// hold, listening = a slip, the gesture hand (how, never what).
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
import 'package:slm_flutter/features/game/m5_cable_route_locate.dart';
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
  rungId: '5.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5CrlPacks['do_5_9_b']!;

/// The new art is not in pubspec yet (the director adds the folder): tests
/// read it from disk when the bundle does not have it.
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 800);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, M5CrlProbe probe) async {
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
    builder: (_) => DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: M5CableRouteLocatePage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
    ),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

/// The coworker comes; refuse him.
Future<void> _refuse(WidgetTester t, M5CrlPush push) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($push)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M5CrlLines.coworker(push).right);
  await _pump(t, 2600);
}

bool _pushHere(M5CrlProbe p, M5CrlPush push) => p.run!.deal.push == push && p.run!.deal.pushStreet == p.run!.index && !p.run!.heldCoworker;

/// Opens the map (refusing B2 if he is dealt here) and closes it.
Future<void> _readMap(WidgetTester t, M5CrlProbe p) async {
  final b2 = _pushHere(p, M5CrlPush.map);
  await _tool(t, M5CrlLines.toolMap);
  expect(_label(M5CrlLines.mapClose), findsOneWidget);
  if (b2) await _refuse(t, M5CrlPush.map);
  await t.tap(_label(M5CrlLines.mapClose));
  await _pump(t, 400);
  expect(_label(M5CrlLines.mapClose), findsNothing);
}

/// A drag along [path] (design px) on the scene.
Future<void> _dragAlong(WidgetTester t, M5CrlProbe p, List<Offset> path, {int holdMs = 0}) async {
  final g = await t.startGesture(p.toScreen(path.first)!);
  await t.pump(const Duration(milliseconds: 30));
  for (final q in path.skip(1)) {
    await g.moveTo(p.toScreen(q)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  if (holdMs > 0) await _pump(t, holdMs);
  await g.up();
  await _pump(t, 200);
}

/// Points along the docket's route from [a] to [b] (fractions), ~6 px apart.
List<Offset> _route(M5CrlGeo g, double a, double b) {
  final n = math.max(2, ((b - a) * g.ownLength / 6).ceil());
  return [for (var i = 0; i <= n; i++) g.ownAt(a + (b - a) * i / n)];
}

Future<void> _walkTo(WidgetTester t, M5CrlProbe p, double to) async {
  await _dragAlong(t, p, _route(p.geo!, p.run!.walked, to));
}

/// Opens pit [i] (the trainee is at it): cover off, torch across, the call.
Future<void> _pit(WidgetTester t, M5CrlProbe p, int i, {bool? pin}) async {
  final pit = p.run!.street.pits[i];
  await t.tapAt(p.toScreen(p.geo!.pitAt(pit.path, pit.t))!);
  await _pump(t, 400);
  expect(p.run!.pitOpen, i, reason: 'pit $i opens');
  var r = p.pitRect!;
  var g = await t.startGesture(r.center);
  for (var k = 0; k < 12; k++) {
    await g.moveBy(const Offset(0, -14));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
  expect(p.run!.pitStage, M5CrlPitStage.torch);
  r = p.pitRect!;
  g = await t.startGesture(Offset(r.left + 16, r.center.dy));
  for (var x = r.left + 16; x < r.right - 16; x += 12) {
    await g.moveTo(Offset(x, r.center.dy + 4));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
  expect(p.run!.pitStage, M5CrlPitStage.decide);
  await t.tap(_label((pin ?? pit.burnt) ? M5CrlLines.pitPin : M5CrlLines.pitClose));
  await _pump(t, 500);
}

Future<void> _phoneAll(WidgetTester t) async {
  await _tool(t, M5CrlLines.toolPhone);
  expect(find.byKey(const ValueKey('hud-guide')), findsNothing, reason: 'the phone rows are never under the guide');
  for (final c in M5CrlContact.values) {
    await t.tap(_label(M5CrlLines.contactName(c)));
    await _pump(t, 200);
  }
  expect(find.text(M5CrlLines.reply(M5CrlContact.gas, 0)).evaluate().isNotEmpty || find.text(M5CrlLines.reply(M5CrlContact.gas, 1)).evaluate().isNotEmpty, isTrue);
  await t.tap(_label(M5CrlLines.phoneHang));
  await _pump(t, 300);
}

/// Walk to [to] in the widget, opening (and judging right) every closed pit on
/// the route before it.
Future<void> _walkOpening(WidgetTester t, M5CrlProbe p, double to) async {
  final st = p.run!.street;
  for (final i in st.ownPits) {
    final pit = st.pits[i];
    if (pit.t + m5CrlPitMargin < to && !p.run!.resolvedPits.contains(i)) {
      await _walkTo(t, p, pit.t - 0.01);
      await _pit(t, p, i);
    }
  }
  await _walkTo(t, p, to);
}

/// Walk to the clue mark (opening the pits on the way) and pin it.
Future<void> _pinClue(WidgetTester t, M5CrlProbe p) async {
  final st = p.run!.street;
  final m = st.marks[st.clueMark!];
  await _walkOpening(t, p, m.t);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await t.tapAt(p.toScreen(p.geo!.markAt(m.path, m.t))!);
  await _pump(t, 400);
  expect(p.run!.spotKind, M5CrlSpotKind.mark);
}

/// Walk the route right: every pit on it opened and judged right; stop at a
/// burnt one (a clue) unless [toEnd].
Future<void> _walkRoute(WidgetTester t, M5CrlProbe p) async {
  final st = p.run!.street;
  for (final i in st.ownPits) {
    await _walkTo(t, p, st.pits[i].t - 0.01);
    await _pit(t, p, i);
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pit $i');
    if (st.pits[i].burnt) return;
  }
  await _walkTo(t, p, 1);
  expect(p.run!.stage, M5CrlStage.walkDone);
}

/// The team's path, right: team (B1 refused if dealt), TDR call, wheel,
/// thump sweep and chalk.
Future<void> _teamPath(WidgetTester t, M5CrlProbe p) async {
  final b1 = _pushHere(p, M5CrlPush.team);
  await _tool(t, M5CrlLines.toolTeam);
  expect(p.run!.stage, M5CrlStage.tdr);
  if (b1) await _refuse(t, M5CrlPush.team);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 400);
  await _pickRight(t, M5CrlLines.tdrRight(p.run!.street.tdrBlank));
  await _pump(t, 800);
  expect(p.run!.stage, M5CrlStage.measure);
  final st = p.run!.street;
  await _dragAlong(t, p, _route(p.geo!, 0, st.tdrMetres / st.routeMetres));
  expect(p.run!.stage, M5CrlStage.sweep, reason: 'the wheel stops at the TDR distance');
  final peak = p.peak!;
  await _dragAlong(t, p, [for (var k = 0; k <= 8; k++) peak + Offset(48.0 - 6 * k, 0)], holdMs: 2000);
  expect(p.run!.stage, M5CrlStage.dig, reason: 'chalked at the peak');
}

/// One street, right (the coworker refused where dealt); its reason.
Future<void> _street(WidgetTester t, M5CrlProbe p) async {
  final st = p.run!.street;
  await _readMap(t, p);
  if (st.evidence == M5CrlEvidence.mark) {
    await _pinClue(t, p);
  } else {
    await _walkRoute(t, p);
    if (st.evidence == M5CrlEvidence.none) await _teamPath(t, p);
  }
  expect(p.run!.spotKnown, isTrue);
  await _phoneAll(t);
  final right = M5CrlLines.whyRight(p.run!.why, p.run!.spotKind!);
  await _tool(t, M5CrlLines.toolPeg);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _reason(t, right);
}

/// Logic only: walk [r] to [t], judging every closed pit on the way right.
void _walkRun(M5CrlRun r, double t) {
  for (final i in r.street.ownPits) {
    final p = r.street.pits[i];
    if (p.t + m5CrlPitMargin < t && !r.resolvedPits.contains(i)) {
      r.traceTo(p.t - 0.01);
      r
        ..openPit(i)
        ..liftCover()
        ..torchDone()
        ..decidePit(p.burnt);
    }
  }
  r.traceTo(t);
}

int _seedWhere(bool Function(M5CrlDeal d) ok) => [for (var s = 0; s < 2000; s++) s].firstWhere((s) => ok(m5CrlDeal(math.Random(s))));

void main() {
  group('rules', () {
    test('deals: two streets of different shapes and feeders; one with nothing on the route; B1 only where the team comes; plays differ', () {
      final seen = <String>{};
      final evid = <M5CrlEvidence>{};
      var blank = 0;
      var b1 = 0;
      for (var s = 0; s < 200; s++) {
        final d = m5CrlDeal(math.Random(s));
        expect(d.streets, hasLength(2));
        expect(d.streets[0].plan.layout, isNot(d.streets[1].plan.layout));
        final labels = [for (final st in d.streets) ...[st.ownFeeder, st.otherFeeder]];
        expect(labels.toSet(), hasLength(4));
        expect(d.streets.where((st) => st.evidence == M5CrlEvidence.none), isNotEmpty);
        if (d.push == M5CrlPush.team) {
          b1++;
          expect(d.streets[d.pushStreet].evidence, M5CrlEvidence.none);
        }
        for (final st in d.streets) {
          evid.add(st.evidence);
          if (st.tdrBlank) blank++;
          expect(st.ownPits, isNotEmpty);
          expect(st.pits.where((p) => !p.onRoute), hasLength(1));
          expect(st.pits.where((p) => p.burnt).length, st.evidence == M5CrlEvidence.pit ? 1 : 0);
          expect(st.marks.where((m) => m.onRoute).length, st.evidence == M5CrlEvidence.mark ? 1 : 0);
          expect(st.marks.where((m) => !m.onRoute), isNotEmpty, reason: 'decoys every street');
          expect(st.peakOffsetM.abs(), inInclusiveRange(m5CrlPeakMinM, m5CrlPeakMaxM));
          expect(st.peakOffsetM.abs(), greaterThan(m5CrlChalkM), reason: 'a chalk at the TDR distance never hits the peak');
          expect(st.contacts.toSet(), M5CrlContact.values.toSet());
          if (st.tdrBlank) expect(st.evidence, M5CrlEvidence.none);
        }
        expect(d.streets[0].why, isNot(d.streets[1].why));
        seen.add('${d.streets.map((st) => '${st.plan.layout}${st.plan.mirror}${st.plan.ownA}${st.evidence.name}${st.tdrBlank}${st.contacts.first.name}').join('|')}|${d.push.name}${d.pushStreet}');
      }
      expect(evid, M5CrlEvidence.values.toSet());
      expect(blank, greaterThan(30));
      expect(b1, inInclusiveRange(60, 140));
      expect(seen.length, greaterThan(150));
    });

    M5CrlRun runFor(bool Function(M5CrlStreet st) ok) {
      final s = _seedWhere((d) => ok(d.streets[0]));
      return M5CrlRun(m5CrlDeal(math.Random(s)));
    }

    test('map first: walking or pinning before the map is a slip; the map opens the walk', () {
      final r = runFor((st) => true);
      expect(r.startWalk(), M5CrlMistakes.walkNoMap);
      expect(r.tapMark(0), M5CrlMistakes.walkNoMap);
      expect(r.stage, M5CrlStage.map);
      r.use(M5CrlTool.map);
      expect(r.mapRead, isTrue);
      expect(r.stage, M5CrlStage.walk);
      expect(r.startWalk(), isNull);
      expect(r.slips, 2);
    });

    test('the walk: the other branch is a slip; a closed pit on the route cannot be passed; pins on the route only', () {
      final r = runFor((st) => st.evidence == M5CrlEvidence.mark)..use(M5CrlTool.map);
      final st = r.street;
      expect(r.traceOther(), M5CrlMistakes.wrongRoute);
      final pit = st.pits[st.ownPits.first];
      expect(r.traceTo(pit.t + 0.1), M5CrlMistakes.pitPassed);
      expect(r.walked, closeTo(pit.t, 1e-9), reason: 'held at the pit');
      final decoy = st.marks.indexWhere((m) => !m.onRoute);
      expect(r.tapMark(decoy), M5CrlMistakes.offRoute, reason: 'a decoy costs at any time');
      final clue = st.clueMark!;
      if (st.marks[clue].t - m5CrlReach > r.walked) {
        expect(r.markInReach(clue), isFalse);
        expect(r.tapMark(clue), isNull);
        expect(r.spotKind, isNull, reason: 'a clue ahead of the trainee is not pinned yet');
      }
      _walkRun(r, st.marks[clue].t);
      expect(r.markInReach(clue), isTrue);
      expect(r.tapMark(clue), isNull);
      expect(r.spotKind, M5CrlSpotKind.mark);
      expect(r.caught, contains(M5CrlLines.caughtClue));
      expect(r.slips, 3);
    });

    test('a joint pit: cover, torch, then the call — clean pinned / burnt closed are slips and the pit stays', () {
      final r = runFor((st) => st.evidence == M5CrlEvidence.pit)..use(M5CrlTool.map);
      final st = r.street;
      for (final i in st.ownPits) {
        final p = st.pits[i];
        expect(r.canOpenPit(i), isFalse, reason: 'not there yet');
        r.traceTo(p.t - 0.01);
        expect(r.canOpenPit(i), isTrue);
        r.openPit(i);
        expect(r.decidePit(true), isNull, reason: 'no call before the torch');
        r.liftCover();
        r.torchDone();
        if (p.burnt) {
          expect(r.decidePit(false), M5CrlMistakes.closeBurnt);
          expect(r.pitOpen, i);
          expect(r.decidePit(true), isNull);
          expect(r.spotKind, M5CrlSpotKind.pit);
          break;
        }
        expect(r.decidePit(true), M5CrlMistakes.pinClean);
        expect(r.decidePit(false), isNull);
        expect(r.pitOpen, isNull);
      }
      expect(r.caught, contains(M5CrlLines.caughtPit));
    });

    test('the team: not before the walk ends; not with a clue on the route missed; then TDR → wheel → chalk', () {
      final r = runFor((st) => st.evidence == M5CrlEvidence.none && st.tdrBlank)..use(M5CrlTool.map);
      final st = r.street;
      expect(r.use(M5CrlTool.team), M5CrlMistakes.teamEarly);
      for (final i in st.ownPits) {
        r.traceTo(st.pits[i].t - 0.01);
        r
          ..openPit(i)
          ..liftCover()
          ..torchDone()
          ..decidePit(false);
      }
      expect(r.traceTo(1), isNull);
      expect(r.stage, M5CrlStage.walkDone);
      expect(r.use(M5CrlTool.team), isNull);
      expect(r.stage, M5CrlStage.tdr);
      expect(r.tdrPick(false), M5CrlMistakes.notArm, reason: 'a blank trace needs ARM');
      expect(r.tdrPick(true), isNull);
      expect(r.armDone, isTrue);
      expect(r.why == M5CrlWhy.arm || r.why == st.why, isTrue);
      expect(r.measure(st.tdrMetres + m5CrlWheelTolM + 1), M5CrlMistakes.traceOff);
      expect(r.measure(st.tdrMetres - m5CrlWheelTolM + 1), isNull);
      expect(r.stage, M5CrlStage.sweep);
      expect(r.chalk(m5CrlChalkM + 0.5), M5CrlMistakes.chalkOff);
      expect(r.chalk(m5CrlChalkM - 0.5), isNull);
      expect(r.spotKind, M5CrlSpotKind.chalk);
      expect(r.caught, containsAll([M5CrlLines.caughtArm, M5CrlLines.caughtThump]));
      expect(r.slips, 4);
      final m = runFor((st) => st.evidence == M5CrlEvidence.mark)..use(M5CrlTool.map);
      m.traceTo(m.street.pits[m.street.ownPits.first].t - 0.01);
      for (final i in m.street.ownPits) {
        m.traceTo(m.street.pits[i].t - 0.01);
        m
          ..openPit(i)
          ..liftCover()
          ..torchDone()
          ..decidePit(false);
      }
      m.traceTo(1);
      expect(m.use(M5CrlTool.team), M5CrlMistakes.teamWithMark);
      final d = runFor((st) => st.evidence == M5CrlEvidence.none && !st.tdrBlank)..use(M5CrlTool.map);
      for (final i in d.street.ownPits) {
        d.traceTo(d.street.pits[i].t - 0.01);
        d
          ..openPit(i)
          ..liftCover()
          ..torchDone()
          ..decidePit(false);
      }
      d.traceTo(1);
      d.use(M5CrlTool.team);
      expect(d.tdrPick(false), M5CrlMistakes.tdrIgnored);
    });

    test('the peg: no spot = a slip; before every owner is phoned = a slip (R33); then the street is done', () {
      final r = runFor((st) => st.evidence == M5CrlEvidence.mark)..use(M5CrlTool.map);
      expect(r.use(M5CrlTool.peg), M5CrlMistakes.pegGuess);
      _walkRun(r, r.street.marks[r.street.clueMark!].t);
      r.tapMark(r.street.clueMark!);
      expect(r.spotKnown, isTrue);
      r.call(M5CrlContact.telephone);
      r.call(M5CrlContact.water);
      expect(r.use(M5CrlTool.peg), M5CrlMistakes.pegBeforeCall);
      r.call(M5CrlContact.gas);
      expect(r.use(M5CrlTool.peg), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5CrlLines.caughtCall));
      expect(r.slips, 2);
      r.next();
      expect(r.index, 1);
      expect(r.stage, M5CrlStage.map);
      expect(r.mapRead, isFalse);
      expect(r.called, isEmpty);
    });

    test('the TDR deck: one right, one card of the other case (must read the trace), one shortcut', () {
      for (final blank in [false, true]) {
        final decoysSeen = <String>{};
        for (var k = 0; k < 200; k++) {
          final deck = m5CrlTdrDeal(blank, math.Random(k));
          expect(deck, hasLength(3));
          expect(deck.map((o) => o.textBn).toSet(), hasLength(3));
          final right = deck.where((o) => o.correct).toList();
          expect(right, hasLength(1));
          expect(M5CrlLines.tdrRight(blank), contains(right.single.textBn));
          final wrong = deck.where((o) => !o.correct).map((o) => o.textBn).toList();
          final decoys = wrong.where(M5CrlLines.tdrDecoys(blank).contains).toList();
          expect(decoys, hasLength(1), reason: 'always one on-topic wrong card');
          expect(wrong.where(M5CrlLines.tdrShortcuts.contains), hasLength(1));
          decoysSeen.addAll(decoys);
        }
        expect(decoysSeen, M5CrlLines.tdrDecoys(blank).toSet());
      }
      // On a blank trace a distance card is wrong; on a distance an ARM card is.
      expect(M5CrlLines.tdrDecoys(true), containsAll(M5CrlLines.tdrRightDistance));
      expect(M5CrlLines.tdrDecoys(false), containsAll(M5CrlLines.tdrRightBlank));
    });

    test('marks: a clue is pinned once walked to; after a pinned clue, walking on past a pit is no slip', () {
      final r = runFor((st) => st.evidence == M5CrlEvidence.mark && st.ownPits.any((i) => st.pits[i].t > st.marks[st.clueMark!].t + 0.05))..use(M5CrlTool.map);
      final st = r.street;
      final clue = st.clueMark!;
      _walkRun(r, st.marks[clue].t);
      expect(r.tapMark(clue), isNull);
      expect(r.spotKind, M5CrlSpotKind.mark);
      expect(r.traceTo(1), isNull, reason: 'the spot is known: the pits further on are no clue');
      expect(r.slips, 0);
    });

    test("the reason: a fallback never repeats the first street's question", () {
      final s = _seedWhere((d) => d.streets[0].evidence == M5CrlEvidence.mark && d.streets[0].why == M5CrlWhy.pit && d.streets[1].why == M5CrlWhy.peg);
      final r = M5CrlRun(m5CrlDeal(math.Random(s)));
      expect(r.why, M5CrlWhy.peg, reason: 'no pit opened: the pit question does not fit');
      r.next();
      expect(r.why, isNot(M5CrlWhy.peg));
    });

    test('kit row: every tool, never in a working order left to right; rows differ', () {
      expect(m5CrlInWorkOrder(const [M5CrlTool.map, M5CrlTool.team, M5CrlTool.phone, M5CrlTool.peg]), isTrue);
      expect(m5CrlInWorkOrder(const [M5CrlTool.team, M5CrlTool.map, M5CrlTool.phone, M5CrlTool.peg]), isTrue);
      final rows = <String>{};
      for (var s = 0; s < 60; s++) {
        final row = m5CrlToolRow(math.Random(s));
        expect(row.toSet(), M5CrlTool.values.toSet());
        expect(m5CrlInWorkOrder(row), isFalse, reason: '$row');
        rows.add(row.map((t) => t.name).join(','));
      }
      expect(rows.length, greaterThan(8));
    });

    test('the thump: loudest at the peak, fading with distance', () {
      expect(m5CrlLoudness(0), 1);
      expect(m5CrlLoudness(10), greaterThan(m5CrlLoudness(20)));
      expect(m5CrlLoudness(40), 0);
    });

    test('English digits only; no deadly act on this rung; every mistake has its picture; keys unique; one pack', () {
      final all = <String>[
        M5CrlLines.intro,
        ...M5CrlLines.tasks,
        ...M5CrlLines.rounds,
        ...M5CrlLines.allWhyRight,
        ...M5CrlLines.myths,
        ...M5CrlLines.whyQ.values,
        ...M5CrlLines.tdrRightBlank,
        ...M5CrlLines.tdrRightDistance,
        ...M5CrlLines.tdrShortcuts,
        M5CrlLines.tdrBlankIsSound,
        ...M5CrlLines.feeders,
        for (final p in M5CrlPush.values) ...[
          ...M5CrlLines.coworker(p).recordedLines,
          ...M5CrlLines.coworker(p).right,
          ...M5CrlLines.coworker(p).wrong,
          ...M5CrlLines.coworker(p).asks,
        ],
        for (final c in M5CrlContact.values) ...[M5CrlLines.contactName(c), M5CrlLines.reply(c, 0), M5CrlLines.reply(c, 1)],
        for (final m in M5CrlMistakes.all) m.textBn,
        M5CrlLines.allSet,
        M5CrlLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5CrlMistakes.all.where((m) => m.deadly), isEmpty);
      expect(M5CrlMistakes.all.map((m) => m.key).toSet(), hasLength(M5CrlMistakes.all.length));
      final arts = <String>{};
      for (final m in M5CrlMistakes.all) {
        expect(m.key, startsWith('5.9/m5_cable_route_locate/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        arts.add(m.art.split('/').last);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every picture in the folder is used (no stray assets).
      final dir = Directory('assets/game/art/m5_cable_route_locate').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(dir, arts);
      expect(m5CrlPacks.keys, ['do_5_9_b']);
      // Ruling M5-7: the R33 card names the owners of the other lines.
      expect(M5CrlMistakes.pegBeforeCall.textBn, 'খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান।');
    });

    test('libraries: same length, big enough, never a rule marked wrong; the deal is one right of three', () {
      expectSameLength('why', [...M5CrlLines.allWhyRight, ...M5CrlLines.myths]);
      expect(M5CrlLines.myths.toSet().intersection(M5CrlLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5CrlWhy.values) {
        expect(M5CrlLines.whyQ[w], isNotEmpty);
        for (final s in M5CrlSpotKind.values) {
          final right = M5CrlLines.whyRight(w, s);
          expectLibrary('$w $s', right, M5CrlLines.myths);
          for (var k = 0; k < 10; k++) {
            final deal = dealChoices(right, M5CrlLines.myths, math.Random(k));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      for (final blank in [false, true]) {
        expectLibrary('tdr $blank', M5CrlLines.tdrRight(blank), M5CrlLines.tdrWrong(blank));
      }
      expectSameLength('tdr', [...M5CrlLines.tdrRightBlank, ...M5CrlLines.tdrRightDistance, ...M5CrlLines.tdrShortcuts, M5CrlLines.tdrBlankIsSound]);
      for (final p in M5CrlPush.values) {
        final cw = M5CrlLines.coworker(p);
        expectSameLength('choice $p', [...cw.right, ...cw.wrong]);
        expectLibrary('choice $p', cw.right, cw.wrong);
        expect(cw.exitLine, M5CrlLines.coworkerExit);
      }
      // His exit line is his existing clip; the two pushes are new (listed for the director).
      expect(LearnVoice.resolve(M5CrlLines.coworkerExit, rival: true), isNotNull);
      expect(M5CrlLines.coworkerMap.line, 'ম্যাপ দেখার সময় নেই — আন্দাজে এখানেই খুঁড়ে ফেলো!');
      expect(M5CrlLines.coworkerTeam.line, contains('ওভারহেড লাইনের জ্ঞান থাকলেই ইউজি কেবিলে কাজ করা যায়'));
    });

    test('the street plans: tap areas apart, all on the 360-wide scene, between the header and the kit row', () {
      for (var s = 0; s < 400; s++) {
        final d = m5CrlDeal(math.Random(s));
        for (final st in d.streets) {
          for (final h in [560.0, 700.0, 780.0, 900.0]) {
            final g = M5CrlGeo.forScene(h, 0, st.plan);
            final rects = [
              for (final m in st.marks) g.markHit(g.markAt(m.path, m.t)),
              for (final p in st.pits) g.pitHit(g.pitAt(p.path, p.t)),
            ];
            for (final r in rects) {
              expect(r.center.dx, inInclusiveRange(0, 360));
              expect(r.center.dy, greaterThan(120), reason: 'below the header');
              expect(r.center.dy, lessThan(g.gateY + 4), reason: 'above the kit row');
              expect(g.guideZone.contains(r.center), isFalse, reason: 'never under the guide or his bubble: seed $s h $h ${r.center} plan ${st.plan.layout}/${st.plan.mirror}/${st.plan.ownA} marks ${st.marks.map((m) => '${m.path.name}:${m.t.toStringAsFixed(2)}')} pits ${st.pits.map((m) => '${m.path.name}:${m.t.toStringAsFixed(2)}')}');
            }
            for (var i = 0; i < rects.length; i++) {
              for (var j = i + 1; j < rects.length; j++) {
                final x = rects[i].intersect(rects[j]);
                expect(x.width <= 6 || x.height <= 6, isTrue, reason: 'seed $s h $h: $i/$j ${rects[i].center} ${rects[j].center} plan ${st.plan.layout}/${st.plan.mirror}/${st.plan.ownA} marks ${st.marks.map((m) => '${m.path.name}:${m.t.toStringAsFixed(2)}')} pits ${st.pits.map((m) => '${m.path.name}:${m.t.toStringAsFixed(2)}')}');
              }
            }
            // The other branch never hugs the docket's route after the junction.
            for (var t = g.junctionT + 0.12; t < 1; t += 0.05) {
              expect(g.nearOther(g.ownAt(t)).d, greaterThan(30), reason: 'seed $s h $h t $t');
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

    testWidgets('the guide comes first: a tap does not skip him; then the kit row (never in a working order)', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M5CableRouteLocatePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5CrlLines.toolMap), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      final row = [...M5CrlTool.values]..sort((a, b) => t.getCenter(_label(M5CrlLines.toolLabel(a))).dx.compareTo(t.getCenter(_label(M5CrlLines.toolLabel(b))).dx));
      expect(m5CrlInWorkOrder(row), isFalse, reason: 'the row on screen: $row');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final p = M5CrlProbe();
      final c = await _open(t, 5, p);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5CrlLines.askStart)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in M5CrlPush.values) {
      testWidgets('flow (${push.name} push): both streets right, the coworker refused, right reasons → pass, nothing frozen', (t) async {
        final seed = _seedWhere((d) =>
            d.push == push &&
            d.streets.any((st) => st.evidence == M5CrlEvidence.none && st.tdrBlank) &&
            d.streets.any((st) => st.evidence == (push == M5CrlPush.team ? M5CrlEvidence.pit : M5CrlEvidence.mark)));
        final p = M5CrlProbe();
        final c = await _open(t, seed, p);
        await _street(t, p);
        expect(p.run!.index, 1);
        await _street(t, p);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.9/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.9/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5CrlLines.caughtCoworker), findsOneWidget);
        expect(find.text(M5CrlLines.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (walking before the map) shows its card; the same street goes on after it; no freeze', (t) async {
      final p = M5CrlProbe();
      final c = await _open(t, 2, p);
      final g = p.geo!;
      await _dragAlong(t, p, _route(g, 0, 0.1));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(M5CrlMistakes.walkNoMap.textBn), findsOneWidget);
      await _gotIt(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(p.run!.index, 0);
      expect(_label(M5CrlLines.toolMap), findsOneWidget, reason: 'the same street');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CrlMistakes.walkNoMap.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the other branch at the junction is a slip; a decoy mark pinned is a slip', (t) async {
      final seed = _seedWhere((d) => d.push == M5CrlPush.team);
      final p = M5CrlProbe();
      final c = await _open(t, seed, p);
      await _readMap(t, p);
      final g = p.geo!;
      final st = p.run!.street;
      // Up the trunk to the junction, then into the other branch.
      final firstPit = st.pits[st.ownPits.first].t;
      expect(firstPit, greaterThan(g.junctionT));
      final path = [..._route(g, 0, g.junctionT), for (var k = 1; k <= 10; k++) g.pathAt(M5CrlPath.other, k * 0.02)];
      await _dragAlong(t, p, path);
      expect(find.text(M5CrlMistakes.wrongRoute.textBn), findsOneWidget);
      await _gotIt(t);
      final decoy = st.marks.indexWhere((m) => !m.onRoute);
      await t.tapAt(p.toScreen(g.markAt(st.marks[decoy].path, st.marks[decoy].t))!);
      await _pump(t, 500);
      expect(find.text(M5CrlMistakes.offRoute.textBn), findsOneWidget);
      await _gotIt(t);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {M5CrlMistakes.wrongRoute.key, M5CrlMistakes.offRoute.key});
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (pegging with no spot)', (t) async {
      final p = M5CrlProbe();
      final c = await _open(t, 2, p);
      for (var i = 0; i < 3; i++) {
        await _tool(t, M5CrlLines.toolPeg);
        await _pump(t, 600);
        if (i < 2) await _gotIt(t);
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('no deadly act: driving the peg before the calls is a slip card (R33), never a freeze', (t) async {
      final seed = _seedWhere((d) => d.streets[0].evidence == M5CrlEvidence.mark && d.push == M5CrlPush.team);
      final p = M5CrlProbe();
      final c = await _open(t, seed, p);
      await _readMap(t, p);
      await _pinClue(t, p);
      await _tool(t, M5CrlLines.toolPeg);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(M5CrlMistakes.pegBeforeCall.textBn), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('the wheel: after a slip a small nudge to the distance is a stop; a hold on the wheel stop without listening never chalks', (t) async {
      final seed = _seedWhere((d) => d.streets[0].evidence == M5CrlEvidence.none && d.pushStreet == 1);
      final p = M5CrlProbe();
      final c = await _open(t, seed, p);
      await _readMap(t, p);
      await _walkRoute(t, p);
      await _tool(t, M5CrlLines.toolTeam);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 400);
      await _pickRight(t, M5CrlLines.tdrRight(p.run!.street.tdrBlank));
      await _pump(t, 800);
      expect(p.run!.stage, M5CrlStage.measure);
      final st = p.run!.street;
      final g = p.geo!;
      final over = (st.tdrMetres + 12) / st.routeMetres;
      await _dragAlong(t, p, _route(g, 0, over));
      expect(find.text(M5CrlMistakes.traceOff.textBn), findsOneWidget, reason: '12 m past the distance');
      await _gotIt(t);
      // A touch with no push is no stop.
      await t.tapAt(p.toScreen(g.ownAt(over))!);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(p.run!.stage, M5CrlStage.measure);
      // Back 12 m: a stop at the distance.
      await _dragAlong(t, p, _route(g, over, st.tdrMetres / st.routeMetres));
      expect(p.run!.stage, M5CrlStage.sweep, reason: 'a small nudge counts');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toList(), [M5CrlMistakes.traceOff.key]);
      // Press and hold on the wheel's stop: no listening, no chalk.
      final stop = g.ownAt(p.run!.wheelM! / st.routeMetres);
      final hold = await t.startGesture(p.toScreen(stop)!);
      await _pump(t, 4000);
      await hold.up();
      await _pump(t, 300);
      expect(p.run!.stage, M5CrlStage.sweep, reason: 'a hold without moving the mic never chalks');
      expect(find.byType(MistakeCard), findsNothing);
      // Listening, then a hold at the peak.
      final peak = p.peak!;
      await _dragAlong(t, p, [for (var k = 0; k <= 8; k++) peak + Offset(48.0 - 6 * k, 0)], holdMs: 2000);
      expect(p.run!.stage, M5CrlStage.dig);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      await _close(t, c);
    });

    testWidgets('B2: closing the map waits for him (a fast play cannot skip him); listening is a slip', (t) async {
      final seed = _seedWhere((d) => d.push == M5CrlPush.map && d.pushStreet == 0);
      final p = M5CrlProbe();
      final c = await _open(t, seed, p);
      await _tool(t, M5CrlLines.toolMap);
      // At once: well inside his 1.2–2.4 s timer.
      await t.tap(_label(M5CrlLines.mapClose));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickWrong(t, M5CrlLines.coworkerMap.wrong);
      expect(find.text(M5CrlMistakes.listenMap.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await _gotIt(t);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CrlMistakes.listenMap.key);
      expect(_label(M5CrlLines.mapClose), findsOneWidget, reason: 'the map is still up');
      await _close(t, c);
    });

    testWidgets('B1: the TDR call waits for him; a pit judged wrong is a slip and the pit stays for the right call', (t) async {
      final seed = _seedWhere((d) => d.push == M5CrlPush.team && d.pushStreet == 0);
      final p = M5CrlProbe();
      final c = await _open(t, seed, p);
      await _readMap(t, p);
      final st = p.run!.street;
      final first = st.ownPits.first;
      await _walkTo(t, p, st.pits[first].t - 0.01);
      await _pit(t, p, first, pin: true);
      expect(find.text(M5CrlMistakes.pinClean.textBn), findsOneWidget);
      await _gotIt(t);
      expect(p.run!.pitOpen, first);
      await t.tap(_label(M5CrlLines.pitClose));
      await _pump(t, 500);
      expect(p.run!.pitOpen, isNull);
      for (final i in st.ownPits.skip(1)) {
        await _walkTo(t, p, st.pits[i].t - 0.01);
        await _pit(t, p, i);
      }
      await _walkTo(t, p, 1);
      await _tool(t, M5CrlLines.toolTeam);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, M5CrlLines.coworkerTeam.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('tdr-deck-0'))), isTrue, reason: 'the TDR deck after him');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CrlMistakes.pinClean.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the whole kit row; the map card\'s one button; a drag on the walk and on a pit cover', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.push == M5CrlPush.team);
      final p = M5CrlProbe();
      final c = await _open(t, seed, p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle before the map');
      expect(scene().debugOptions, hasLength(M5CrlTool.values.length), reason: 'every kit button alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _tool(t, M5CrlLines.toolMap);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the map card');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on its one button');
      await t.tap(_label(M5CrlLines.mapClose));
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the walk');
      expect(scene().debugOptions, isEmpty, reason: 'a drag of the walker, no target');
      // Three taps on nothing show the hand at once.
      final empty = p.toScreen(const Offset(6, 158))!;
      await t.tapAt(empty);
      await t.pump(const Duration(milliseconds: 50));
      expect(scene().showing, isFalse, reason: 'a touch hides it');
      await _pump(t, 4500);
      expect(scene().showing, isFalse);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      // A pit opened: a drag up on its cover; at the call, a sweep over both buttons alike.
      final st = p.run!.street;
      final i = st.ownPits.first;
      await _walkTo(t, p, st.pits[i].t - 0.01);
      await t.tapAt(p.toScreen(p.geo!.pitAt(st.pits[i].path, st.pits[i].t))!);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the cover');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a pick');
      expect(p.run!.pitStage, M5CrlPitStage.cover, reason: 'the hand moves nothing');
      await _close(t, c);
    });
  });
}
