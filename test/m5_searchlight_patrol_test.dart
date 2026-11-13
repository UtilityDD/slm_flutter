// Lesson 5.7 (রাতের বেলা ফল্ট খোঁজার কৌশল), কাজ 1 "সার্চলাইটের টহল": the
// rules (depot: read every charge, swap a low one, reflective jacket, the
// docket, two in the van; the fork; the patrol: marks, faults passing, the
// coworker's headlight myth; the step-out: depot choices bite, binoculars then
// phone, climbing = deadly), the deal, the libraries, the rival lines, and the
// level in the shell: the guide first, a full clean play (reasons + the
// coworker refused), a slip card that keeps the station, three slips, the
// deadly freeze, listening to him, the van waiting for him, the idle patrol
// (zero frames) and the gesture hand (how, never what).
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
import 'package:slm_flutter/features/game/m5_searchlight_patrol.dart';
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
  rungId: '5.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5SearchlightPacks['do_5_7_a']!;
typedef _L = M5SearchlightLines;
typedef _M = M5SearchlightMistakes;

/// Reads art from disk when the bundle does not have it yet.
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 2400);
}

Future<(ProviderContainer, M5SearchlightProbe)> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final p = M5SearchlightProbe();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5SearchlightPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: p)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return (c, p);
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
}

Offset _g(M5SearchlightProbe p, Offset design) => p.toGlobal!(design)!;

/// Drags [f] so its centre lands on the design point [to].
Future<void> _dragTo(WidgetTester t, M5SearchlightProbe p, Finder f, Offset to) async {
  await t.drag(f, _g(p, to) - t.getCenter(f));
  await _pump(t, 300);
}

/// The depot done right: every charge read, a low one swapped, the reflective
/// jacket, the docket, two in the van, রওনা, the depot reason.
Future<void> _depot(WidgetTester t, M5SearchlightProbe p, {bool reason = true}) async {
  final run = p.run!;
  for (final d in M5SlDevice.values) {
    await t.longPress(find.byKey(ValueKey('dev-${d.name}')));
    await _pump(t, 200);
  }
  expect(run.read, hasLength(3));
  final low = run.deal.lowDevice;
  if (low != null) {
    await _dragTo(t, p, find.byKey(ValueKey('dev-${low.name}')), p.geo!.dock.center);
    expect(run.swapped, {low});
  }
  await t.tap(find.byKey(const ValueKey('peg-reflective')));
  await _pump(t, 200);
  await t.tap(find.byKey(const ValueKey('docket')));
  await _pump(t, 200);
  await _dragTo(t, p, find.byKey(const ValueKey('fig-trainee')), p.geo!.seat(M5SlSeat.light).center);
  await _dragTo(t, p, find.byKey(const ValueKey('fig-partner')), p.geo!.seat(M5SlSeat.driver).center);
  expect(run.seats, {M5SlSeat.light: M5SlWho.trainee, M5SlSeat.driver: M5SlWho.partner});
  await t.tap(_label(_L.go));
  await _pump(t, 800);
  expect(run.departed, isTrue);
  if (reason) await _reason(t, _L.whyRight[run.depotWhy!]!);
  expect(run.station, M5SlStation.fork);
}

Future<void> _fork(WidgetTester t, M5SearchlightProbe p) async {
  await t.tap(_label(_L.road));
  await _pump(t, 2400);
  expect(p.run!.station, M5SlStation.patrol);
}

/// The patrol at ধীরে: each fault stopped at, lit and marked (its reason);
/// the coworker refused (or listened to, [listen]); the slow reason at the end.
Future<void> _patrol(WidgetTester t, M5SearchlightProbe p, {bool listen = false}) async {
  final run = p.run!;
  await t.tap(_label(_L.slow));
  await _pump(t, 100);
  var cw = false;
  for (var ms = 0; ms < 240000 && run.station == M5SlStation.patrol && !run.patrolDone; ms += 50) {
    if (!cw && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      expect(p.halted, isTrue, reason: 'the van waits for him');
      await waitChoiceDeck(t);
      if (listen) return;
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      cw = true;
      continue;
    }
    final next = [for (final i in run.deal.faults) if (!run.pinned.contains(i)) i];
    if (next.isNotEmpty) {
      final i = next.first;
      final top = p.geo!.poleTop(run.deal.poles[i], i, p.view!.x);
      if (top.dx < 290 && top.dx > 120 && find.byType(CoworkerPeek).evaluate().isEmpty) {
        await t.tap(_label(_L.stop));
        await _pump(t, 100);
        final at = p.geo!.poleTop(run.deal.poles[i], i, p.view!.x);
        await t.tapAt(_g(p, at));
        await _pump(t, 700);
        expect(p.view!.lit, i);
        expect(p.view!.resolved, isTrue);
        await t.longPressAt(_g(p, p.view!.aim));
        await _pump(t, 300);
        expect(run.pinned, contains(i));
        final why = run.deal.poles[i].fault == M5SlFault.insulator ? M5SlWhy.insulator : M5SlWhy.branch;
        await _reason(t, _L.whyRight[why]!);
        await t.tap(_label(_L.slow));
        await _pump(t, 100);
        continue;
      }
    }
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(cw, isTrue, reason: 'he came');
  expect(run.patrolDone, isTrue);
  await _reason(t, _L.whyRight[M5SlWhy.slow]!);
  await _pump(t, 1200);
  expect(run.station, M5SlStation.stepOut);
}

/// The report: the binoculars held, then the phone.
Future<void> _report(WidgetTester t) async {
  await _pumpUntil(t, _label(_L.binoculars));
  await t.longPress(_label(_L.binoculars));
  await _pump(t, 2400);
  await t.tap(_label(_L.phone));
  await _pump(t, 2400);
}

int _seedWhere(bool Function(M5SlDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5SlDeal(math.Random(s))));

void main() {
  group('rules', () {
    test('deals: a low device in ~3/4 of plays, both jackets, 8 poles on both sides, 1–2 faults never on pole 2; plays differ', () {
      final seen = <String>{};
      var noLow = 0;
      for (var s = 0; s < 200; s++) {
        final d = m5SlDeal(math.Random(s));
        if (d.lowDevice == null) {
          noLow++;
          expect(d.charge.values.every((c) => c >= m5SlLowCharge), isTrue);
        } else {
          expect(d.charge[d.lowDevice], lessThan(m5SlLowCharge));
          expect(d.charge.entries.where((e) => e.value < m5SlLowCharge), hasLength(1));
        }
        expect(d.pegs.toSet(), M5SlJacket.values.toSet());
        expect(d.poles, hasLength(8));
        expect(d.poles.where((p) => p.side == M5SlSide.far).length, greaterThanOrEqualTo(2));
        expect(d.poles.where((p) => p.side == M5SlSide.near).length, greaterThanOrEqualTo(2));
        expect(d.faults.length, inInclusiveRange(1, 2));
        expect(d.faults, isNot(contains(m5SlCoworkerPole)), reason: 'his halt must not land on a fault');
        expect({for (var i = 1; i < 8; i++) d.poles[i].plate - d.poles[i - 1].plate}, {1});
        expect(d.depotWhy.toSet(), {M5SlWhy.battery, M5SlWhy.jacket, M5SlWhy.two});
        expect(m5SlInWorkOrder(d.tools), isFalse, reason: '${d.tools}');
        seen.add('${d.lowDevice}|${d.pegs.first}|${d.fieldLeft}|${d.faults}|${d.poles.map((p) => p.side.index).join()}|${d.tools}');
      }
      expect(noLow, inInclusiveRange(25, 80));
      expect(seen.length, greaterThan(150));
    });

    M5SlDeal deal({M5SlDevice? low = M5SlDevice.torch, List<int> faults = const [3]}) {
      final d = m5SlDeal(math.Random(1));
      return M5SlDeal(
        lowDevice: low,
        charge: {for (final x in M5SlDevice.values) x: x == low ? 12 : 95},
        pegs: const [M5SlJacket.dark, M5SlJacket.reflective],
        fieldLeft: true,
        poles: [
          for (var i = 0; i < 8; i++)
            M5SlPole(side: i.isEven ? M5SlSide.far : M5SlSide.near, fault: faults.contains(i) ? M5SlFault.insulator : M5SlFault.none, porcelain: true, plate: 40 + i),
        ],
        feeder: 4,
        docketNo: 472,
        depotWhy: const [M5SlWhy.jacket, M5SlWhy.battery, M5SlWhy.two],
        tools: d.tools,
      );
    }

    test('ডিপো: the dock takes only a device read low; no docket = a slip and the van stays; one person = a slip, the partner jumps in', () {
      final r = M5SlRun(deal());
      expect(r.dock(M5SlDevice.torch), isFalse, reason: 'not read yet');
      r.readDevice(M5SlDevice.torch);
      r.readDevice(M5SlDevice.phone);
      expect(r.dock(M5SlDevice.phone), isFalse, reason: 'full');
      expect(r.dock(M5SlDevice.torch), isTrue);
      expect(r.charge(M5SlDevice.torch), 100);
      expect(r.batteryRight, isFalse, reason: 'the headlamp is unread');
      r.readDevice(M5SlDevice.headlamp);
      expect(r.batteryRight, isTrue);
      expect(r.depart(), isNull, reason: 'nobody drives');
      expect(r.seat(M5SlWho.trainee, M5SlSeat.driver), isTrue);
      expect(r.seat(M5SlWho.partner, M5SlSeat.driver), isFalse, reason: 'taken');
      expect(r.depart(), _M.noDocket);
      expect(r.departed, isFalse);
      r.takeDocket();
      expect(r.depart(), _M.alone);
      expect(r.departed, isTrue);
      expect(r.seats, hasLength(2));
      expect(r.slips, 2);
      expect(r.caught, contains(_L.caughtDocket));
      expect(r.caught, isNot(contains(_L.caughtTwo)));
    });

    test('ডিপো: the reason asks the first of the dealt order that was done right; bites follow the depot choices', () {
      final r = M5SlRun(deal())
        ..wear(M5SlJacket.dark)
        ..takeDocket()
        ..seat(M5SlWho.trainee, M5SlSeat.light)
        ..seat(M5SlWho.partner, M5SlSeat.driver);
      expect(r.depart(), isNull);
      expect(r.depotWhy, M5SlWhy.two, reason: 'jacket dark, battery unread');
      expect(r.stepBites, [_M.darkJacket, _M.lowBattery]);
      final ok = M5SlRun(deal())
        ..wear(M5SlJacket.reflective)
        ..takeDocket()
        ..seat(M5SlWho.trainee, M5SlSeat.light)
        ..seat(M5SlWho.partner, M5SlSeat.driver);
      for (final d in M5SlDevice.values) {
        ok.readDevice(d);
      }
      ok.dock(M5SlDevice.torch);
      ok.depart();
      expect(ok.depotWhy, M5SlWhy.jacket);
      expect(ok.stepBites, isEmpty);
      expect(ok.caught, containsAll([_L.caughtJacket, _L.caughtBattery, _L.caughtTwo]));
      // A low phone does not bite at the step-out: it dies when used.
      expect((M5SlRun(deal(low: M5SlDevice.phone))..wear(M5SlJacket.reflective)).stepBites, isEmpty);
    });

    M5SlRun onPatrol(M5SlDeal d) {
      final r = M5SlRun(d)
        ..takeDocket()
        ..seat(M5SlWho.trainee, M5SlSeat.light)
        ..seat(M5SlWho.partner, M5SlSeat.driver);
      r.depart();
      r.next();
      expect(r.chooseFork(field: false), isNull);
      r.next();
      return r;
    }

    test('পথ: the field track is a slip', () {
      final r = M5SlRun(deal())..next();
      expect(r.station, M5SlStation.fork);
      expect(r.chooseFork(field: true), _M.fieldTrack);
      expect(r.chooseFork(field: false), isNull, reason: 'once only');
      expect(r.slips, 1);
    });

    test('টহল: a mark on a sound pole is a slip; a fault marked is fine; an unmarked fault passing is a slip (at speed: its own card)', () {
      final r = onPatrol(deal(faults: [3, 6]));
      expect(r.station, M5SlStation.patrol);
      expect(r.pin(2), _M.soundPin);
      expect(r.pin(3), isNull);
      expect(r.pinned, {3});
      expect(r.caught, contains(_L.caughtFault));
      for (var i = 0; i < 6; i++) {
        expect(r.pass(i, fast: false), isNull, reason: 'pole $i');
      }
      expect(r.pass(6, fast: true), _M.fastMissed);
      expect(r.pass(7, fast: false), isNull);
      expect(r.patrolDone, isTrue);
      expect(r.slips, 2);
      expect(r.stepPole, 3);
      final s = onPatrol(deal(faults: [5]));
      for (var i = 0; i < 5; i++) {
        s.pass(i, fast: false);
      }
      expect(s.pass(5, fast: false), _M.missed);
      expect(s.stepPole, 7, reason: 'no mark: the end of the stretch');
    });

    test('টহল: listening to him is one slip; the dark poles are not booked again', () {
      final r = onPatrol(deal(faults: [2]));
      expect(r.listen(), _M.headlights);
      expect(r.dark, {0, 1, 2, 3});
      expect(r.pass(2, fast: false), isNull, reason: 'it passed in the dark');
      expect(r.slips, 1);
      // A fault on pole 0, still on screen behind the van at his halt (not
      // yet gone), passes in the dark too: still one slip.
      final b = onPatrol(deal(faults: [0]));
      expect(b.listen(), _M.headlights);
      expect(b.pass(0, fast: false), isNull, reason: 'behind the van, light off');
      expect(b.slips, 1);
      // A pole already gone or marked is not darkened; poles after the dark ones are booked as usual.
      final c = onPatrol(deal(faults: [0, 5]));
      expect(c.pin(0), isNull);
      expect(c.listen(), _M.headlights);
      expect(c.dark, {1, 2, 3});
      for (var i = 0; i < 5; i++) {
        expect(c.pass(i, fast: false), isNull);
      }
      expect(c.pass(5, fast: false), _M.missed);
      expect(c.slips, 2);
    });

    test('রিপোর্ট: no pole marked = nothing to report (no plate read, no phone)', () {
      final r = onPatrol(deal(faults: [5]));
      for (var i = 0; i < 8; i++) {
        r.pass(i, fast: false);
      }
      expect(r.nothingToReport, isTrue);
      r.next();
      r.binoculars();
      expect(r.plateRead, isFalse);
      expect(r.phone(), isNull);
      expect(r.sent, isFalse);
      final m = onPatrol(deal(faults: [5]));
      m.pin(5);
      expect(m.nothingToReport, isFalse);
    });

    test('রিপোর্ট: the phone waits for the plate; a low phone dies (a slip) and the report still goes; climbing is deadly', () {
      final r = onPatrol(deal(low: M5SlDevice.phone));
      expect(r.pin(3), isNull, reason: 'a fault marked: there is a report to send');
      r.next();
      expect(r.station, M5SlStation.stepOut);
      expect(r.phone(), isNull);
      expect(r.sent, isFalse);
      r.binoculars();
      expect(r.phone(), _M.lowBattery);
      expect(r.sent, isTrue);
      expect(r.phoneDied, isTrue);
      final c = onPatrol(deal());
      c.next();
      final m = c.climb();
      expect(m.deadly, isTrue);
      expect(c.ended, isTrue);
    });

    test('tool rows: every tool, never binoculars-then-phone from the left; rows differ', () {
      expect(m5SlInWorkOrder(const [M5SlTool.binoculars, M5SlTool.phone, M5SlTool.climb]), isTrue);
      expect(m5SlInWorkOrder(const [M5SlTool.climb, M5SlTool.binoculars, M5SlTool.phone]), isFalse);
      final rows = {for (var s = 0; s < 60; s++) m5SlDeal(math.Random(s)).tools.map((t) => t.name).join()};
      expect(rows.length, greaterThanOrEqualTo(4));
    });

    test('English digits only; every mistake has its picture; one deadly; keys unique; lesson points in range', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allWhyRight,
        ..._L.allWhyWrong,
        _L.noMark,
        ..._L.whyQ.values,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
        _L.callHeld,
        _L.docket(4, 472),
        _L.plate(47),
        _L.charge(18),
        _L.report(4, 47),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.climb]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      final dir = Directory('assets/game/art/m5_searchlight_patrol');
      final files = dir.listSync().whereType<File>().map((f) => f.path.replaceAll(r'\', '/').split('/').last).toSet();
      for (final m in _M.all) {
        expect(m.key, startsWith('5.7/m5_searchlight_patrol/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(files, {for (final m in _M.all) m.art.split('/').last}, reason: 'no unused art');
      expect(m5SearchlightPacks.keys, ['do_5_7_a']);
      // Ruling M5-3: the docket card, word for word; never a PTW as the patrol's must.
      expect(_M.noDocket.textBn, contains('টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে PTW বাধ্যতামূলক'));
      expect(_L.docket(4, 472), isNot(contains('PTW')));
    });

    test('libraries: same length, big enough, never a rule marked wrong; the coworker says myth 2 word for word', () {
      expectSameLength('why', [..._L.allWhyRight, ..._L.allWhyWrong]);
      expect(_L.allWhyWrong.toSet().intersection(_L.allWhyRight.toSet()), isEmpty);
      for (final w in M5SlWhy.values) {
        final right = _L.whyRight[w]!;
        final wrong = _L.wrongFor(w);
        expectLibrary('$w', right, wrong);
        expectSameLength('$w', [...right, ...wrong]);
        expect(_L.whyQ[w], isNotEmpty);
        final seen = <String>{};
        for (var k = 0; k < 40; k++) {
          final deal = m5SlReasonDeal(w, math.Random(k));
          expect(deal, hasLength(3));
          expect(deal.where((o) => o.correct).single.textBn, isIn(right));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          final bad = [for (final o in deal) if (!o.correct) o.textBn];
          expect(bad.every(wrong.contains), isTrue, reason: '$w: wrong cards on its own topic');
          seen.addAll(bad);
          // A mark's reason always deals the other fault kind: the player must know which one was there.
          if (w == M5SlWhy.insulator) expect(bad.where(_L.sawBranch.contains), hasLength(1));
          if (w == M5SlWhy.branch) expect(bad.where(_L.sawInsulator.contains), hasLength(1));
        }
        expect(seen.length, greaterThanOrEqualTo(4), reason: '$w: the wrong cards vary');
      }
      // The depot questions never share wrong cards about another topic.
      expect(_L.batteryMyths.toSet().intersection(_L.jacketMyths.toSet()), isEmpty);
      expect(_L.twoMyths.toSet().intersection(_L.slowMyths.toSet()), isEmpty);
      final cw = _L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.line, 'আমার গাড়ির হেডলাইটই যথেষ্ট, আলাদা টর্চের দরকার নেই।');
    });

    test('rival lines: every recorded line has a clip or is listed for the director', () {
      for (final l in _L.coworker.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true) != null || _L.rivalMissing.contains(l), isTrue, reason: l);
      }
      expect(LearnVoice.resolve(_L.coworkerExit, rival: true), isNotNull);
      for (final l in _L.rivalMissing) {
        expect(_L.coworker.recordedLines, contains(l));
      }
    });

    test('scene geometry: depot targets on the 360-wide scene, apart, above the floor; pole tops below the header', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5SlGeo.forScene(h, 0);
        final rects = [
          for (final d in M5SlDevice.values) g.deviceHome(d),
          g.dock,
          g.docket,
          g.peg(0),
          g.peg(1),
          for (final s in M5SlSeat.values) g.seat(s),
        ];
        for (final r in [...rects, for (final w in M5SlWho.values) g.figureHome(w)]) {
          final z = r.intersect(g.guideZone);
          expect(z.width <= 0 || z.height <= 0, isTrue, reason: 'h $h: in the guide corner $r');
        }
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h $r');
          expect(r.top, greaterThanOrEqualTo(120), reason: 'h $h: below the header $r');
          expect(r.bottom, lessThan(g.floorY), reason: 'h $h: above the floor $r');
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final x = rects[i].intersect(rects[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
        expect(g.farTopY, greaterThanOrEqualTo(150));
        expect(g.nearTopY, greaterThanOrEqualTo(150));
        expect(g.nearTopY, lessThan(g.roadTop));
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

    testWidgets('the guide comes first: a tap does not skip him; then the depot', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5SearchlightPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.go), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.go), findsOneWidget);
      for (final d in M5SlDevice.values) {
        expect(find.byKey(ValueKey('dev-${d.name}')), findsOneWidget);
        expect(find.byKey(ValueKey('charge-${d.name}')), findsNothing, reason: 'no charge shows until held');
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final (c, _) = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(_L.askDepot)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [_seedWhere((d) => d.lowDevice != null && d.faults.length == 2), _seedWhere((d) => d.lowDevice == null && d.faults.length == 1)]) {
      testWidgets('flow (seed $seed): ready at the depot, the paved road, slow patrol with marks, refuse him, report → pass', (t) async {
        final (c, p) = await _open(t, seed);
        await _depot(t, p);
        await _fork(t, p);
        await _patrol(t, p);
        await _report(t);
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.7/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.7/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        for (final x in [_L.caughtCall, _L.caughtFault, _L.caughtSlow, _L.caughtReport, _L.caughtJacket]) {
          expect(find.text(x), findsOneWidget, reason: x);
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (রওনা without the docket) shows its card; the depot goes on after it', (t) async {
      final (c, p) = await _open(t, 2);
      await _dragTo(t, p, find.byKey(const ValueKey('fig-partner')), p.geo!.seat(M5SlSeat.driver).center);
      await t.tap(_label(_L.go));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.noDocket.textBn), findsOneWidget);
      await _gotIt(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byKey(const ValueKey('docket')), findsOneWidget, reason: 'the same station');
      expect(p.run!.station, M5SlStation.depot);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.noDocket.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final (c, p) = await _open(t, 2);
      await _dragTo(t, p, find.byKey(const ValueKey('fig-partner')), p.geo!.seat(M5SlSeat.driver).center);
      for (var i = 0; i < 3; i++) {
        await t.tap(_label(_L.go));
        await _pump(t, 600);
        if (i < 2) await _gotIt(t);
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a depot choice bites later: a dark jacket — a truck rushes past at the step-out (a slip)', (t) async {
      final seed = _seedWhere((d) => d.lowDevice == M5SlDevice.phone && d.faults.length == 1);
      final (c, p) = await _open(t, seed);
      final run = p.run!;
      await t.tap(find.byKey(const ValueKey('peg-dark')));
      await t.tap(find.byKey(const ValueKey('docket')));
      await _dragTo(t, p, find.byKey(const ValueKey('fig-trainee')), p.geo!.seat(M5SlSeat.light).center);
      await _dragTo(t, p, find.byKey(const ValueKey('fig-partner')), p.geo!.seat(M5SlSeat.driver).center);
      await t.tap(_label(_L.go));
      await _pump(t, 800);
      // The reason asks about the two in the van (the only one done right).
      expect(run.depotWhy, M5SlWhy.two);
      expect(find.byType(MistakeCard), findsNothing, reason: 'nothing booked yet');
      await _reason(t, _L.whyRight[M5SlWhy.two]!);
      await _fork(t, p);
      await _patrol(t, p);
      await _pump(t, 1200);
      expect(find.text(_M.darkJacket.textBn), findsOneWidget);
      await _gotIt(t);
      // The phone was low: it dies on the report (a slip) and the partner sends it.
      await _report(t);
      expect(find.text(_M.lowBattery.textBn), findsOneWidget);
      await _gotIt(t);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key).toSet(), {_M.darkJacket.key, _M.lowBattery.key});
      expect(find.byType(LevelPassPanel), findsOneWidget, reason: '2 slips = 70 %');
      await _close(t, c);
    });

    testWidgets('climbing the pole at the step-out: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.faults.length == 1);
      final (c, p) = await _open(t, seed);
      await _depot(t, p);
      await _fork(t, p);
      await _patrol(t, p);
      await _pumpUntil(t, _label(_L.climb));
      await t.tap(_label(_L.climb));
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      final dead = s.mistakes.where((m) => m.deadly).toList();
      expect(dead.single.key, _M.climb.key);
      await _close(t, c);
    });

    testWidgets('fast all the way: the fault flies past (its card); no pole marked = no report, the level ends', (t) async {
      final seed = _seedWhere((d) => d.faults.length == 1 && d.lowDevice != M5SlDevice.phone);
      final (c, p) = await _open(t, seed);
      await _depot(t, p);
      await _fork(t, p);
      // Fast all the way: he comes (refused), the fault flies past (a slip).
      await t.tap(_label(_L.fast));
      for (var ms = 0; ms < 60000 && p.run!.station == M5SlStation.patrol; ms += 50) {
        if (find.byType(CoworkerPeek).evaluate().isNotEmpty && !p.run!.caught.contains(_L.caughtCall) && find.byType(ChoiceDeck).evaluate().isNotEmpty) {
          await _pickRight(t, _L.coworker.right);
          await _pump(t, 2600);
        }
        if (find.byType(MistakeCard).evaluate().isNotEmpty) {
          expect(find.text(_M.fastMissed.textBn), findsOneWidget);
          await _gotIt(t);
        }
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(p.run!.pinned, isEmpty);
      expect(p.run!.nothingToReport, isTrue);
      for (var ms = 0; ms < 4000 && !p.run!.done; ms += 100) {
        expect(_label(_L.binoculars), findsNothing, reason: 'no sound pole is reported');
        expect(_label(_L.phone), findsNothing);
        await t.pump(const Duration(milliseconds: 100));
      }
      await _pump(t, 2500);
      expect(p.run!.done, isTrue);
      expect(p.run!.sent, isFalse);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key), [_M.fastMissed.key]);
      expect(find.byType(LevelPassPanel), findsOneWidget, reason: '1 slip = 85 %');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('listening to him: a slip, the searchlight goes off for the next poles', (t) async {
      final seed = _seedWhere((d) => !d.faults.contains(0));
      final (c, p) = await _open(t, seed);
      await _depot(t, p);
      await _fork(t, p);
      await _patrol(t, p, listen: true);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.text(_M.headlights.textBn), findsOneWidget);
      expect(p.view!.lightOn, isFalse);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.headlights.key);
      await _close(t, c);
    });

    testWidgets('the van stops = an idle scene: no frames, few rebuilds', (t) async {
      var rebuilds = 0;
      final seed = _seedWhere((d) => d.faults.length == 1);
      final (c, p) = await _open(t, seed);
      await _depot(t, p);
      await _fork(t, p);
      await t.tap(_label(_L.slow));
      await _pump(t, 1500);
      await t.tap(_label(_L.stop));
      await _pump(t, 14000);
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
      addTearDown(() => debugOnRebuildDirtyWidget = null);
      for (var i = 0; i < 125; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      final perSec = rebuilds / 2.0;
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      debugPrint('PERF m5_searchlight_patrol stopped: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
      expect(perSec, lessThan(20));
      expect(frames, lessThan(12));
      await _close(t, c);
    });

    testWidgets('gesture hand: idle in the depot → a hold on a device (each in turn); the fork → a sweep over both signs, never one', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.lowDevice != null);
      final (c, p) = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the depot');
      final f = scene().debugFrame;
      expect(f, isNotNull);
      final homes = [for (final d in M5SlDevice.values) _g(p, p.geo!.deviceHome(d).center)];
      final first = homes.indexWhere((h) => (h - (f!.tip)).distance < 60);
      expect(first, isNot(-1), reason: 'the hold is on a device');
      // Any touch hides it.
      await t.tapAt(const Offset(380, 300));
      await t.pump(const Duration(milliseconds: 100));
      expect(scene().showing, isFalse);
      await _depot(t, p);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the fork');
      expect(scene().debugOptions, hasLength(2), reason: 'both signs');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand on the patrol: the van stopped and idle → a lever swipe or a sky sweep that never stops on a pole top', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.faults.length == 1);
      final (c, p) = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _depot(t, p);
      await _fork(t, p);
      final run = p.run!;
      var sweeps = 0;
      for (var round = 0; round < 3; round++) {
        await _pump(t, 9000);
        expect(scene().showing, isTrue, reason: 'idle on the patrol ($round)');
        final opts = scene().debugOptions;
        if (opts.isNotEmpty) {
          sweeps++;
          expect(opts.length, greaterThanOrEqualTo(2));
          expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
          for (var i = 0; i < run.deal.poles.length; i++) {
            final top = _g(p, p.geo!.poleTop(run.deal.poles[i], i, p.view!.x));
            for (final o in opts) {
              expect((o.center - top).distance, greaterThan(42), reason: 'a stop on pole $i');
            }
          }
        }
        await t.tapAt(const Offset(380, 300));
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(sweeps, greaterThanOrEqualTo(1), reason: 'the sky sweep shows');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
