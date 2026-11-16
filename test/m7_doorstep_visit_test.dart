// Lesson 7.9 (গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব), কাজ 1 "দরজা থেকে মিটার
// বক্স": the rules (the ID card first when someone answers, consent AND
// notice-or-জরুরি to go in, a woman alone needs the colleague as witness,
// nobody home / over the wall = trespass, a needless refusal, only the meter
// place or the conduit run, offcuts swept before 'কাজ শেষ', no deadly), the
// deal, the libraries, the coworker (gate beat and lesson myth 1, listening =
// the slip of what he pushes), every spoken line listed, the drawn places,
// and the level in the shell: the guide first, the docket close-up, a full
// clean play (three visits, a reason pick each, the coworker refused), the
// slip cards, three slips strike out, the tray and the first room drag wait
// for him, the praise window takes no touch, and the gesture hand shows how
// (never what) only while the level waits.
import 'dart:async';
import 'dart:convert';
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
import 'package:slm_flutter/features/game/m7_doorstep_visit.dart';
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
  rungId: '7.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7DoorstepVisitPacks['do_7_9_a']!;
typedef L = M7DoorstepVisitLines;
typedef Mk = M7DoorstepVisitMistakes;

/// The new art is read from disk when the bundle (pubspec) does not have it.
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

/// The app's form of য় ড় ঢ় (base + nukta), for comparing with the lesson file.
String _nukta(String s) => s.replaceAll('\u09dc', '\u09a1\u09bc').replaceAll('\u09dd', '\u09a2\u09bc').replaceAll('\u09df', '\u09af\u09bc');

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
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
M7DvGeo get _geo => M7DvGeo.forScene(360 * 850 / 392, 0);
M7DvRun get _live => M7DoorstepVisitProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

/// A drag from [from] to [to] (design px).
Future<void> _dragFrom(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Offset get _traineeNow => switch (_live.phase) {
      M7DvPhase.lane || M7DvPhase.done => _geo.traineeStart.center,
      M7DvPhase.door => _geo.traineeGate.center,
      _ => _geo.traineeIn(_live.room).center,
    };

Future<void> _walkTo(WidgetTester t, Offset to) => _dragFrom(t, _traineeNow, to);

Future<void> _giveItem(WidgetTester t, M7DvItem it, Offset to) async {
  final i = _live.visit.trayOrder.indexOf(it);
  await _dragFrom(t, _geo.trayItem(i).center, to);
}

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7DoorstepVisitPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7DvDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m7DvDeal(math.Random(s))));

/// The coworker comes (a timer, or a held control): refuse him.
Future<void> _refuseHim(WidgetTester t) async {
  expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 12000), isTrue, reason: 'he comes');
  await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
  await _pump(t, 600);
  await _pickRight(t, L.script(_live.deal.cwBeat).right);
  await _pump(t, 2600);
}

Future<void> _why(WidgetTester t, M7DvWhy w) async {
  expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'the reason deck for $w');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1800);
}

/// One visit played right (the coworker refused where he is dealt).
Future<void> _playVisit(WidgetTester t, M7DvDeal d, int i, {bool giveNotice = false}) async {
  expect(_live.index, i);
  final v = d.visits[i];
  final cwHere = d.cwVisit == i;
  await _walkTo(t, _geo.gateFront.center);
  expect(_live.phase, M7DvPhase.door);
  if (cwHere && d.cwBeat == M7DvBeat.gate) await _refuseHim(t);
  if (v.someone) {
    await _giveItem(t, M7DvItem.id, _geo.cust.center);
    expect(_live.idShown, isTrue);
    expect(find.byType(MistakeCard), findsNothing);
    if (v.why == M7DvWhy.id) await _why(t, M7DvWhy.id);
  }
  if (giveNotice) {
    await _giveItem(t, M7DvItem.notice, v.someone ? _geo.cust.center : _geo.letterbox.center);
    expect(_live.noticeHanded, isTrue);
  }
  if (!v.entryRight) {
    await _walkTo(t, _geo.vanZone.center);
    expect(_live.visitDone, isTrue, reason: '${v.kind}');
    expect(find.byType(MistakeCard), findsNothing);
    if (v.why != M7DvWhy.id) await _why(t, v.why);
    await _pump(t, 2200);
    return;
  }
  if (v.woman) {
    await _tapAt(t, _geo.colleagueBase.center);
    expect(_live.colleague, isTrue);
    if (v.why == M7DvWhy.witness) await _why(t, M7DvWhy.witness);
  }
  await _walkTo(t, _geo.gate.center);
  expect(_live.phase, anyOf(M7DvPhase.inside, M7DvPhase.work), reason: 'in (${v.kind}, ${v.notice})');
  await _pump(t, 700);
  if (cwHere && d.cwBeat == M7DvBeat.inside) await _refuseHim(t);
  var asked = false;
  for (final r in v.workRooms) {
    if (r == M7DvRoom.veranda) continue;
    await _walkTo(t, _geo.room(r).center);
    expect(find.byType(MistakeCard), findsNothing, reason: 'room $r is on the work');
    if (!asked && v.why == M7DvWhy.zone) {
      asked = true;
      await _why(t, M7DvWhy.zone);
    }
  }
  expect(await _pumpUntil(t, () => _live.phase == M7DvPhase.tidy, maxMs: 6000), isTrue, reason: 'the work beat ends');
  await _pump(t, 600);
  // The broom: take it, sweep the floor strip end to end, 'কাজ শেষ'.
  await _tapAt(t, _geo.broom.center);
  final f = _geo.floor(_live.room);
  final g = await t.startGesture(Offset(f.left + 1, f.center.dy) * _k);
  for (var s = 1; s <= 30; s++) {
    await g.moveTo(Offset(f.left + 1 + (f.width - 2) * s / 30, f.center.dy) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
  expect(_live.debris, isEmpty);
  await _tapAt(t, _geo.doneBtn.center);
  expect(find.byType(MistakeCard), findsNothing);
  expect(_live.phase, M7DvPhase.leave);
  if (v.why == M7DvWhy.clean) await _why(t, M7DvWhy.clean);
  await _walkTo(t, _geo.exitDoor.center);
  expect(_live.visitDone, isTrue);
  await _pump(t, 2400);
}

/// A hand-built visit.
M7DvVisit _vis({
  M7DvKind kind = M7DvKind.entryPlain,
  M7DvJob job = M7DvJob.read,
  M7DvNotice notice = M7DvNotice.given,
  M7DvCust cust = M7DvCust.man,
  M7DvConsent consent = M7DvConsent.yes,
  M7DvCase caseOf = M7DvCase.hall,
}) =>
    M7DvVisit(
      house: 0,
      kind: kind,
      job: job,
      notice: notice,
      cust: cust,
      consent: consent,
      caseOf: caseOf,
      trayOrder: M7DvItem.values,
      debris: const [0.3, 0.7],
      why: M7DvWhy.id,
      custLook: 0,
      tone: 0,
    );

M7DvRun _runOf(M7DvVisit v) => M7DvRun(M7DvDeal(visits: [v, v, v], cwVisit: 1, cwBeat: M7DvBeat.gate));

extension on Rect {
  bool containsRect(Rect o) => o.left >= left - 0.01 && o.top >= top - 0.01 && o.right <= right + 0.01 && o.bottom <= bottom + 0.01;
}

void main() {
  group('rules', () {
    test('the ID card first when someone answers: anything else first is a slip; then the notice slip goes to the customer or the letterbox', () {
      final r = _runOf(_vis())..arrive();
      expect(r.giveItem(M7DvItem.docket, M7DvTarget.customer), Mk.firstAct);
      expect(r.giveItem(M7DvItem.notice, M7DvTarget.letterbox), Mk.firstAct);
      expect(r.giveItem(M7DvItem.id, M7DvTarget.letterbox), Mk.firstAct, reason: 'the ID goes to him, not the box');
      expect(r.giveItem(M7DvItem.id, M7DvTarget.none), isNull, reason: 'dropped on nothing: nothing');
      expect(r.slips, 3);
      expect(r.giveItem(M7DvItem.id, M7DvTarget.customer), isNull);
      expect(r.idShown, isTrue);
      expect(r.giveItem(M7DvItem.docket, M7DvTarget.customer), isNull);
      expect(r.noticeHanded, isFalse);
      expect(r.giveItem(M7DvItem.notice, M7DvTarget.letterbox), isNull);
      expect(r.noticeHanded, isTrue);
      expect(r.caught, containsAll([L.caughtId, L.caughtNotice]));
    });

    test('going through the gate: ID first, consent, then notice or জরুরি, then the witness for a woman alone', () {
      var r = _runOf(_vis())..arrive();
      expect(r.enterGate(), Mk.firstAct, reason: 'no ID shown yet');
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.enterGate(), isNull);
      expect(r.phase, M7DvPhase.inside);

      r = _runOf(_vis(consent: M7DvConsent.no, kind: M7DvKind.noEntryRefused))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.enterGate(), Mk.noConsent);

      r = _runOf(_vis(notice: M7DvNotice.notGiven, kind: M7DvKind.noEntryNoNotice))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.enterGate(), Mk.noNotice);
      // Handing a notice slip now does not make the entry lawful.
      r.giveItem(M7DvItem.notice, M7DvTarget.customer);
      expect(r.enterGate(), Mk.noNotice);

      r = _runOf(_vis(notice: M7DvNotice.urgent, kind: M7DvKind.entryUrgent))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.enterGate(), isNull, reason: 'জরুরি: no notice needed, consent given');

      r = _runOf(_vis(cust: M7DvCust.woman, kind: M7DvKind.entryWoman))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.enterGate(), Mk.womanAlone);
      expect(r.callColleague(), isTrue);
      expect(r.enterGate(), isNull);
      expect(r.caught, contains(L.caughtWitness));
    });

    test('nobody home: the gate and the wall are trespass; the ID has nobody to see; back to the van is right', () {
      var r = _runOf(_vis(cust: M7DvCust.none, consent: M7DvConsent.none, kind: M7DvKind.noEntryEmpty))..arrive();
      expect(r.giveItem(M7DvItem.id, M7DvTarget.door), isNull);
      expect(r.idShown, isFalse);
      expect(r.enterGate(), Mk.trespass);
      expect(r.climbWall(), Mk.trespass);
      expect(r.goHome(), isNull);
      expect(r.visitDone, isTrue);
      expect(r.caught, contains(L.caughtEmpty));

      // Someone at the door and not yet shown the ID: the wall is still trespass.
      r = _runOf(_vis())..arrive();
      expect(r.climbWall(), Mk.trespass);
      // Back to the van before the ID is shown does nothing yet.
      expect(r.goHome(), isNull);
      expect(r.visitDone, isFalse);
    });

    test('a refusal is right when he said no or notice was not given; a needless refusal is a slip', () {
      var r = _runOf(_vis(consent: M7DvConsent.no, kind: M7DvKind.noEntryRefused))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.goHome(), isNull);
      expect(r.visitDone, isTrue);
      expect(r.caught, contains(L.caughtNoConsent));

      r = _runOf(_vis(notice: M7DvNotice.notGiven, kind: M7DvKind.noEntryNoNotice))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.goHome(), isNull);
      expect(r.caught, contains(L.caughtNoNotice));

      r = _runOf(_vis())..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.goHome(), Mk.needlessRefusal);
      expect(r.visitDone, isFalse);
      expect(r.slips, 1);

      // A woman alone who agrees, with notice given: staying out is needless too.
      r = _runOf(_vis(cust: M7DvCust.woman, kind: M7DvKind.entryWoman))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      expect(r.goHome(), Mk.needlessRefusal);
    });

    test('inside: a reading stays at the meter; an inspection follows the conduit; any other room is a private-room slip', () {
      var r = _runOf(_vis(job: M7DvJob.read, caseOf: M7DvCase.storeKitchen))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      r.enterGate();
      expect(r.phase, M7DvPhase.inside);
      expect(r.goRoom(M7DvRoom.bedroom), Mk.privateRoom);
      expect(r.goRoom(M7DvRoom.puja), Mk.privateRoom);
      expect(r.goRoom(M7DvRoom.kitchen), Mk.privateRoom, reason: 'the switchboard room is not the work of a reading');
      expect(r.goRoom(M7DvRoom.veranda), isNull, reason: 'the room he stands in');
      expect(r.phase, M7DvPhase.inside);
      expect(r.goRoom(M7DvRoom.store), isNull);
      expect(r.phase, M7DvPhase.work);
      expect(r.slips, 3);
      expect(r.zoneSlip, isTrue);

      r = _runOf(_vis(job: M7DvJob.inspect, caseOf: M7DvCase.storeKitchen))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      r.enterGate();
      expect(r.goRoom(M7DvRoom.kitchen), isNull);
      expect(r.phase, M7DvPhase.inside, reason: 'the meter room is still to see');
      expect(r.goRoom(M7DvRoom.stairs), Mk.privateRoom);
      expect(r.goRoom(M7DvRoom.store), isNull);
      expect(r.phase, M7DvPhase.work);

      r = _runOf(_vis(job: M7DvJob.test, caseOf: M7DvCase.verandaHall))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      r.enterGate();
      expect(r.goRoom(M7DvRoom.hall), isNull);
      expect(r.phase, M7DvPhase.work, reason: 'the veranda was already seen');

      // A veranda meter and a reading: he works at once.
      r = _runOf(_vis(job: M7DvJob.read, caseOf: M7DvCase.verandaHall))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      r.enterGate();
      expect(r.phase, M7DvPhase.work);
    });

    test('the work beat, the offcuts, the broom: কাজ শেষ with debris is a slip; clean, then out; every visit counts its own slips', () {
      final r = _runOf(_vis(job: M7DvJob.read, caseOf: M7DvCase.hall))..arrive();
      r.giveItem(M7DvItem.id, M7DvTarget.customer);
      r.enterGate();
      r.goRoom(M7DvRoom.hall);
      expect(r.phase, M7DvPhase.work);
      expect(r.finishWork(), isNull, reason: 'not finished before the work beat ends');
      r.workFinished();
      expect(r.phase, M7DvPhase.tidy);
      expect(r.debris, [0.3, 0.7]);
      expect(r.finishWork(), Mk.debris);
      expect(r.thorough, isFalse);
      r.sweepPiece(1);
      expect(r.finishWork(), Mk.debris, reason: 'one piece is left');
      r.sweepPiece(0);
      expect(r.debris, isEmpty);
      expect(r.finishWork(), isNull);
      expect(r.phase, M7DvPhase.leave);
      expect(r.caught, containsAll([L.caughtClean, L.caughtZone, L.caughtEntry]));
      r.leaveHouse();
      expect(r.visitDone, isTrue);
      expect(r.percent, 70);
      r.next();
      expect(r.index, 1);
      expect(r.thorough, isTrue, reason: 'a new visit counts afresh');
      expect((r.phase, r.idShown, r.colleague, r.visitDone), (M7DvPhase.lane, false, false, false));
    });

    test('three slips fail the play (mark 55 is the last pass; 40 fails); listening takes the slip of what he pushes', () {
      final r = _runOf(_vis())..arrive();
      for (var i = 0; i < 3; i++) {
        r.climbWall();
      }
      expect(r.percent, 55);
      r.pushSlip(Mk.listenGate);
      expect(r.percent, 40);
      expect(Mk.listen(M7DvBeat.gate), Mk.listenGate);
      expect(Mk.listen(M7DvBeat.inside), Mk.listenZone);
      expect(r.lastSlip, Mk.listenGate);
    });

    test('the deal: three different houses, at least one visit goes in and one stays out, dealt orders vary, the coworker is dealt on an eligible visit', () {
      final kinds = <M7DvKind>{};
      final cases = <M7DvCase>{};
      final jobs = <M7DvJob>{};
      final orders = <String>{};
      final cwBeats = <String>{};
      final whys = <M7DvWhy>{};
      final houses = <int>{};
      var woman = 0;
      var urgent = 0;
      for (var s = 0; s < 400; s++) {
        final d = m7DvDeal(math.Random(s));
        expect(d.visits.map((v) => v.house).toSet(), hasLength(3), reason: 'seed $s');
        expect(d.visits.where((v) => v.entryRight).length, inInclusiveRange(1, 2), reason: 'seed $s');
        expect(d.visits.where((v) => !v.entryRight).length, inInclusiveRange(1, 2), reason: 'seed $s');
        expect(d.visits.map((v) => v.kind).toSet(), hasLength(3), reason: 'three different kinds');
        for (final v in d.visits) {
          kinds.add(v.kind);
          cases.add(v.caseOf);
          jobs.add(v.job);
          whys.add(v.why);
          houses.add(v.house);
          orders.add(v.trayOrder.join());
          expect(v.trayOrder.toSet(), hasLength(3));
          expect(v.debris.length, inInclusiveRange(2, 3));
          expect(v.debris.toSet(), hasLength(v.debris.length));
          // Every kind is consistent with its words.
          switch (v.kind) {
            case M7DvKind.entryPlain || M7DvKind.entryUrgent || M7DvKind.entryWoman:
              expect(v.entryRight, isTrue);
              expect(v.cust, v.kind == M7DvKind.entryWoman ? M7DvCust.woman : M7DvCust.man);
              if (v.kind == M7DvKind.entryWoman) woman++;
              if (v.notice == M7DvNotice.urgent) urgent++;
              expect(v.workRooms.every((r) => r != M7DvRoom.bedroom && r != M7DvRoom.puja && r != M7DvRoom.stairs), isTrue);
              if (!v.routeJob) expect(v.meterRoom, isNot(M7DvRoom.veranda), reason: 'a reading always needs a room move');
            case M7DvKind.noEntryEmpty:
              expect((v.cust, v.consent), (M7DvCust.none, M7DvConsent.none));
              expect(v.why, M7DvWhy.refuseEmpty);
            case M7DvKind.noEntryRefused:
              expect(v.consent, M7DvConsent.no);
              expect(v.someone, isTrue);
            case M7DvKind.noEntryNoNotice:
              expect((v.notice, v.consent), (M7DvNotice.notGiven, M7DvConsent.yes));
          }
          if (!v.woman) expect(v.why, isNot(M7DvWhy.witness));
          if (!v.someone) expect(v.why, isNot(M7DvWhy.id));
        }
        // He comes on a dealt visit; inside only where the visit goes in.
        if (d.cwBeat == M7DvBeat.inside) expect(d.visits[d.cwVisit].entryRight, isTrue);
        cwBeats.add('${d.cwBeat}');
      }
      expect(kinds, M7DvKind.values.toSet());
      expect(cases, M7DvCase.values.toSet());
      expect(jobs, M7DvJob.values.toSet());
      expect(whys, M7DvWhy.values.toSet());
      expect(houses, {0, 1, 2});
      expect(orders.length, 6);
      expect(cwBeats, hasLength(2));
      expect(woman, greaterThan(0));
      expect(urgent, greaterThan(0));
      // The route's rooms: a meter box and a switchboard drawn in them.
      for (final c in M7DvCase.values) {
        final v = _vis(job: M7DvJob.inspect, caseOf: c);
        expect(v.route, contains(v.meterRoom));
        expect(v.route, contains(v.boardRoom));
      }
    });

    test('English digits only; jol not pani; term rules; no deadly anywhere (ruling M7-6); every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        ...L.newGuideLines,
        ...L.tasks,
        L.docket,
        L.noticeWord,
        L.idCard,
        L.workDone,
        L.sceneLabel,
        L.insideLabel,
        L.broomLabel,
        L.closeLabel,
        for (var n = 1; n <= 3; n++) L.round(n),
        for (final j in M7DvJob.values) L.jobLine(j),
        for (final n in M7DvNotice.values) L.noticeLine(n),
        for (final i in M7DvItem.values) L.itemLabel(i),
        L.womanAlone,
        L.welcome,
        L.notNow,
        for (final r in M7DvRoom.values) L.meterSays(r),
        ...L.allWhyRight,
        ...L.myths,
        ...L.gateScript.recordedLines,
        ...L.insideScript.recordedLines,
        ...L.gateScript.right,
        ...L.gateScript.wrong,
        ...L.insideScript.right,
        ...L.insideScript.wrong,
        L.caughtId,
        L.caughtEntry,
        L.caughtNoNotice,
        L.caughtNoConsent,
        L.caughtEmpty,
        L.caughtWitness,
        L.caughtZone,
        L.caughtClean,
        L.caughtNotice,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.replaceAll('কোম্পানি', '').contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অন|অফ').hasMatch(l.replaceAll('অন্ধকার', '').replaceAll('অন্য', '').replaceAll('অনুমতি', '')), isFalse, reason: 'ON/OFF in English: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[\u09dc\u09dd\u09df]').hasMatch(l), isFalse, reason: 'nukta letters as base + nukta: $l');
      }
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'no deadly in 7.9');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.9/m7_doorstep_visit/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      for (final w in M7DvWhy.values) {
        expect(m7DvLessonPoint(w), inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m7_doorstep_visit/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n != '.gitkeep').toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m7DoorstepVisitPacks.keys, ['do_7_9_a']);
      expect(m7DoorstepVisitQuickMs, greaterThan(60000));
    });

    test('lesson words: the inside push is myth 1 word for word; the zone cards are its reality; the other cards quote the rights and duties', () {
      final data = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync());
      Map<String, dynamic>? find79(Object? o) {
        if (o is Map<String, dynamic>) {
          if (o['id'] == '7.9' && o['content'] is Map) return o;
          for (final v in o.values) {
            final x = find79(v);
            if (x != null) return x;
          }
        } else if (o is List) {
          for (final v in o) {
            final x = find79(v);
            if (x != null) return x;
          }
        }
        return null;
      }

      final lesson = find79(data)!;
      final content = lesson['content'] as Map;
      final myth = ((content['myth_buster'] as Map)['myths'] as List).first as Map;
      expect(L.insideScript.line, _nukta(myth['myth'] as String));
      final reality = _nukta(myth['reality'] as String);
      expect(Mk.privateRoom.textBn, reality, reason: 'the zone card is the lesson reality, word for word');
      expect(reality, contains(Mk.listenZone.textBn.replaceFirst('ওর কথা শুনলে ভুল হতো। ', '')));
      final points = (content['sections'] as List)[0]['points'] as List;
      expect(points, hasLength(3), reason: 'lesson points 0–2');
      final duties = _nukta(points[2]['specifications'] as String);
      expect(duties, contains('গ্রাহক চাওয়ার আগেই আপনার কোম্পানির পরিচয়পত্র দেখান'));
      expect(duties, contains('কাজ শেষে আপনার কাজের জায়গাটি পরিষ্কার করে দিন'));
      final entry = _nukta(points[1]['specifications'] as String);
      expect(entry, contains('যুক্তিসঙ্গত নোটিশ'));
      expect(entry, contains('জোর করে বা গ্রাহকের অনুমতি ছাড়া তার বাড়িতে প্রবেশ করতে পারেন না'));
      final tip = _nukta(((content['pro_tip'] as Map)['content'] as List)[2] as String);
      expect(tip, contains('সাক্ষী'));
    });

    test('libraries: same length, big enough, never a rule marked wrong; the three tray items alike; both coworker scripts', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7DvWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final b in M7DvBeat.values) {
        final cw = L.script(b);
        expectSameLength('coworker choice $b', [...cw.right, ...cw.wrong]);
        expectLibrary('coworker choice $b', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expect(L.gateScript.line, isNot(L.insideScript.line));
      expect(L.myths.where((m) => m.contains('জরুরি')), isNotEmpty, reason: 'জরুরি still needs consent: a myth that says otherwise');
    });

    test('every spoken line is listed: both pushes (rival) and every guide line, why-question, ask and mistake text', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull, reason: 'his exit line is recorded');
      expect(L.newRivalLines, [L.gateScript.line, L.insideScript.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([
        L.intro,
        ...L.tasks,
        L.emptyDoor,
        ...L.whyQ.values,
        L.gateScript.asks[1],
        L.callHeldGate,
        L.callHeldInside,
        L.allSet,
        L.quick,
        L.fail,
        for (final m in Mk.all) m.textBn,
      ]));
      for (final l in [...L.newRivalLines, ...L.newGuideLines]) {
        debugPrint('LINE m7_doorstep_visit: $l');
      }
    });

    test('tap areas: on the scene, below the header, clear of the guide and its bubble; the tray, the zones and the rooms apart', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M7DvGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 12 - 107, 360, h);
        final bubble = Rect.fromLTRB(147, h - 12 - 107 - 52, 360, h - 12 - 107);
        final lane = <Rect>[
          g.docket,
          g.gate,
          g.letterbox,
          g.cust,
          g.gateFront,
          g.traineeGate,
          g.traineeStart,
          g.colleagueBase,
          g.colleagueGate,
          g.vanZone,
          g.tray,
          for (var i = 0; i < 3; i++) g.trayItem(i),
          g.speechA,
          g.speechB,
          g.speechNone,
        ];
        final inside = <Rect>[
          g.cut,
          for (final r in M7DvRoom.values) g.room(r),
          g.exitDoor,
          g.broom,
          g.doneBtn,
          for (final r in M7DvRoom.values) g.traineeIn(r),
          for (final r in M7DvRoom.values) g.floor(r),
        ];
        for (final r in [...lane, ...inside]) {
          expect(r.left, greaterThanOrEqualTo(-0.01), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360.01), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          expect(r.overlaps(bubble), isFalse, reason: 'h $h: $r under the bubble');
        }
        // The tray's items and the trainee at the gate never overlap; nor the van zone and the arrival zone.
        for (var i = 0; i < 3; i++) {
          expect(g.traineeGate.overlaps(g.trayItem(i)), isFalse, reason: 'h $h');
          for (var j = i + 1; j < 3; j++) {
            expect(g.trayItem(i).overlaps(g.trayItem(j)), isFalse);
          }
        }
        expect(g.vanZone.overlaps(g.gateFront), isFalse);
        expect(g.vanZone.contains(g.traineeStart.center), isTrue);
        expect(g.vanZone.contains(g.colleagueBase.center), isTrue);
        expect(g.gateFront.contains(g.traineeGate.center), isTrue);
        expect(g.wall.contains(g.gate.center) && g.wall.contains(g.letterbox.center), isTrue);
        expect(g.gate.overlaps(g.letterbox), isFalse);
        // The rooms tile the cut without gaps or overlaps.
        var area = 0.0;
        for (final a in M7DvRoom.values) {
          area += g.room(a).width * g.room(a).height;
          expect(g.cut.contains(g.room(a).topLeft) && g.cut.inflate(0.01).contains(g.room(a).bottomRight), isTrue, reason: '$a in the cut');
          for (final b in M7DvRoom.values) {
            if (a.index < b.index) {
              final ov = g.room(a).intersect(g.room(b));
              expect(ov.width <= 0.01 || ov.height <= 0.01, isTrue, reason: '$a / $b overlap');
            }
          }
        }
        expect(area, closeTo(g.cut.width * g.cut.height, 0.5));
        expect(g.exitDoor.overlaps(g.room(M7DvRoom.veranda)), isTrue);
        // Meter box and switchboard sit inside their rooms; the floor strips under the debris.
        for (final c in M7DvCase.values) {
          final v = _vis(job: M7DvJob.inspect, caseOf: c);
          expect(g.room(v.meterRoom).containsRect(g.meterBox(v.meterRoom)), isTrue);
          expect(g.room(v.boardRoom).containsRect(g.switchBoard(v.boardRoom)), isTrue);
        }
        for (final r in M7DvRoom.values) {
          expect(g.room(r).containsRect(g.floor(r)), isTrue);
          expect(g.room(r).containsRect(g.traineeIn(r)), isTrue, reason: '$r');
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

    testWidgets('the guide comes first: a tap does not skip him; then the lane, the van with its docket, and the colleague', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M7DoorstepVisitPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.docket), findsOneWidget);
      final v = m7DvDeal(math.Random(3)).visits.first;
      expect(find.text(L.jobLine(v.job)), findsOneWidget, reason: 'the docket shows the job');
      expect(find.text(L.noticeLine(v.notice)), findsOneWidget, reason: 'and its one notice line');
      expect(_live.phase, M7DvPhase.lane);
      for (final i in [M7DvItem.id, M7DvItem.notice]) {
        expect(_label(L.itemLabel(i)), findsNothing, reason: 'no tray before the gate');
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time; the docket opens close and closes by a tap', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askGate)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      final v = m7DvDeal(math.Random(5)).visits.first;
      expect(find.text(L.jobLine(v.job)), findsOneWidget);
      await _tapAt(t, _geo.docket.center);
      expect(find.byKey(const ValueKey('closeup')), findsOneWidget);
      expect(find.text(L.jobLine(v.job)), findsNWidgets(2), reason: 'the close-up shows it big');
      await _tapAt(t, const Offset(180, 600));
      expect(find.byKey(const ValueKey('closeup')), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    // One play with him at the gate (a visit where someone answers), one with
    // him inside (lesson myth 1), one with a woman alone and a reading.
    final flowSeeds = [
      _seedWhere((d) => d.cwBeat == M7DvBeat.gate && d.visits[d.cwVisit].someone && d.visits.any((v) => v.woman && v.entryRight)),
      _seedWhere((d) => d.cwBeat == M7DvBeat.inside && d.visits.any((v) => v.kind == M7DvKind.noEntryEmpty) && d.visits.any((v) => v.routeJob && v.entryRight)),
      _seedWhere((d) => d.visits.any((v) => v.kind == M7DvKind.noEntryNoNotice) && d.visits.any((v) => v.kind == M7DvKind.entryUrgent && !v.routeJob)),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three visits, a reason each, the coworker refused → pass', (t) async {
        final d = m7DvDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playVisit(t, d, i, giveNotice: i == 1);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.9/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.9/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtId), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final someoneFirst = _seedWhere((d) => d.visits[0].someone && d.cwVisit != 0 && d.visits[0].entryRight);
    testWidgets('a slip (the docket first) shows its card; the same visit goes on; the tray still has all three items; the right ID then works', (t) async {
      final c = await _open(t, someoneFirst);
      await _walkTo(t, _geo.gateFront.center);
      expect(find.byKey(ValueKey('tray-0-${0}')), findsOneWidget);
      await _giveItem(t, M7DvItem.docket, _geo.cust.center);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.firstAct.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0);
      expect(_live.phase, M7DvPhase.door);
      for (final i in [M7DvItem.id, M7DvItem.notice]) {
        expect(_label(L.itemLabel(i)), findsOneWidget, reason: 'the item is back in the tray');
      }
      await _giveItem(t, M7DvItem.id, _geo.cust.center);
      expect(_live.idShown, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.firstAct.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the gate before the ID and the wall: each its card; nothing is deadly; the trainee stays at the gate', (t) async {
      final seed = _seedWhere((d) => d.visits[0].someone && d.cwVisit != 0 && d.visits[0].entryRight && !d.visits[0].woman);
      final c = await _open(t, seed);
      await _walkTo(t, _geo.gateFront.center);
      await _walkTo(t, _geo.gate.center);
      expect(find.text(Mk.firstAct.textBn), findsOneWidget, reason: 'the gate before the ID');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.phase, M7DvPhase.door);
      await _walkTo(t, _geo.wall.centerLeft + const Offset(20, 10));
      expect(find.text(Mk.trespass.textBn), findsOneWidget, reason: 'over the wall');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.phase, M7DvPhase.door);
      expect(_live.slips, 2);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 7.9');
      expect(c.read(gameSaveProvider).mistakes, hasLength(2));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a private room off the meter place is a slip card; he does not go in; the work room is then his', (t) async {
      final seed = _seedWhere((d) => d.visits[0].entryRight && !d.visits[0].woman && d.cwVisit != 0);
      final d = m7DvDeal(math.Random(seed));
      final v = d.visits[0];
      final c = await _open(t, seed);
      await _walkTo(t, _geo.gateFront.center);
      await _giveItem(t, M7DvItem.id, _geo.cust.center);
      if (v.why == M7DvWhy.id) await _why(t, M7DvWhy.id);
      await _walkTo(t, _geo.gate.center);
      await _pump(t, 700);
      expect(_live.phase, M7DvPhase.inside);
      for (final off in [M7DvRoom.bedroom, M7DvRoom.puja]) {
        expect(v.workRooms.contains(off), isFalse);
      }
      await _walkTo(t, _geo.room(M7DvRoom.bedroom).center);
      expect(find.text(Mk.privateRoom.textBn), findsOneWidget);
      expect(_live.room, M7DvRoom.veranda, reason: 'he does not go in');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 7.9');
      final room = v.workRooms.firstWhere((r) => r != M7DvRoom.veranda);
      await _walkTo(t, _geo.room(room).center);
      expect(_live.room, room);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.privateRoom.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, someoneFirst);
      await _walkTo(t, _geo.gateFront.center);
      for (var i = 0; i < 3; i++) {
        await _giveItem(t, M7DvItem.notice, _geo.cust.center);
        if (i < 2) {
          expect(find.text(Mk.firstAct.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final gateSeed = _seedWhere((d) => d.cwVisit == 0 && d.cwBeat == M7DvBeat.gate && d.visits[0].someone);
    testWidgets('listening to him at the gate = the no-ID slip (not deadly): a card, no freeze; the visit goes on', (t) async {
      final c = await _open(t, gateSeed);
      await _walkTo(t, _geo.gateFront.center);
      expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 12000), isTrue);
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await _pump(t, 600);
      await waitChoiceDeck(t);
      expect(find.text(L.gateScript.line), findsWidgets);
      final wrong = _onScreen(L.gateScript.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.listenGate.textBn), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsNothing);
      expect(find.text(MistakeLines.deadlyHead), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 1);
      expect(_live.phase, M7DvPhase.door);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listenGate.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _giveItem(t, M7DvItem.id, _geo.cust.center);
      expect(_live.idShown, isTrue, reason: 'he came once; the visit is in the player\'s hands again');
      await _close(t, c);
    });

    testWidgets('at the gate the tray waits for him: an item brings him in at once and decides nothing', (t) async {
      final c = await _open(t, gateSeed);
      await _walkTo(t, _geo.gateFront.center);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet: his 1.2–2.4 s timer');
      await _giveItem(t, M7DvItem.id, _geo.cust.center);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.idShown, isFalse, reason: 'the drop decided nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await _pickRight(t, L.gateScript.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _giveItem(t, M7DvItem.id, _geo.cust.center);
      expect(_live.idShown, isTrue, reason: 'after him the ID works');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final insideSeed = _seedWhere((d) => d.cwVisit == 0 && d.cwBeat == M7DvBeat.inside && d.visits[0].entryRight && !d.visits[0].woman);
    testWidgets('inside, the first room drag waits for him (lesson myth 1); listening = the zone slip; refused, the way is free', (t) async {
      final d = m7DvDeal(math.Random(insideSeed));
      final v = d.visits[0];
      final c = await _open(t, insideSeed);
      await _walkTo(t, _geo.gateFront.center);
      await _giveItem(t, M7DvItem.id, _geo.cust.center);
      if (v.why == M7DvWhy.id) await _why(t, M7DvWhy.id);
      await _walkTo(t, _geo.gate.center);
      await _pump(t, 700);
      expect(_live.phase, M7DvPhase.inside);
      final room = v.workRooms.firstWhere((r) => r != M7DvRoom.veranda);
      await _walkTo(t, _geo.room(room).center);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the drag brings him in; nothing is decided');
      expect(_live.moved, isFalse);
      expect(_live.room, M7DvRoom.veranda);
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.insideScript.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.text(Mk.listenZone.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _walkTo(t, _geo.room(room).center);
      expect(_live.room, room, reason: 'now the right room is his');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listenZone.key);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final seed = _seedWhere((d) => d.visits[0].kind == M7DvKind.noEntryEmpty && d.cwVisit != 0);
      final c = await _open(t, seed);
      await _walkTo(t, _geo.gateFront.center);
      await _walkTo(t, _geo.vanZone.center);
      expect(_live.visitDone, isTrue);
      // The deck is up at once; the scene above it takes nothing.
      expect(find.byType(ChoiceDeck), findsOneWidget);
      final slips = _live.slips;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.docket.center * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(_geo.traineeStart.center * _k, const Offset(80, -20));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byKey(const ValueKey('closeup')), findsNothing, reason: 'the docket did not open');
      expect(_live.slips, slips);
      expect(_live.index, 0);
      expect(find.byKey(const ValueKey('choice-confirm')), findsNothing, reason: 'no card opened by a scene touch');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M7DvWhy.refuseEmpty]!);
      await _pump(t, 3000);
      expect(_live.index, 1, reason: 'on to the next house');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a drag nudge in the lane; a sweep over the three equal items; a hand that points at nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, someoneFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the lane');
      expect(scene().debugOptions, isEmpty, reason: 'a drag nudge from the trainee, not a pick');
      await _walkTo(t, _geo.gateFront.center);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      if (scene().showing) {
        expect(scene().debugOptions, hasLength(3), reason: 'a sweep over the three equal items');
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.idShown, isFalse, reason: 'the hand pressed nothing');
      await _close(t, c);
    });
  });
}
