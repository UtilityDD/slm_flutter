// Lesson 5.2 (লাইন পেট্রোলিং-এর সঠিক নিয়ম), কাজ 1 "ফল্টের ঠিকানা": the rules
// (read from the source end; stop at every T-off; split a long feeder between
// two teams; the fault lies between the last lit FPI and the next dark one —
// or from the open sectionalizer to the next FPI; a fault history → the root
// cause), the deal, the libraries, the coworker's lines, and the level in the
// shell: the guide first, tap-the-guide, a full clean play (reasons, the
// coworker refused, the history note), listening to him = a slip, the van
// waits for him on a fast play, three slips strike out, a far device can not
// be read, the docket from the control room before the patrol (ruling M5-3),
// the grove T-off gives nothing away, and the gesture hand (how, never what).
// A needless stop costs the clean-call +5. The level has no deadly act (item
// spec): every mistake is a slip, nothing freezes.
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
import 'package:slm_flutter/features/game/m5_fault_address.dart';
import 'package:slm_flutter/features/game/m5_fault_address_world.dart';
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
  rungId: '5.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5FaultAddressPacks['do_5_2_a']!;

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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 900);
}

final _allRight = [...M5FaLines.allWhyRight, ...M5FaLines.coworker.right, ...M5FaLines.historyRight];

/// Pumps until nothing more happens for [calmMs]; any deck that comes up is
/// answered right (reasons, the coworker, the history note). A slip card is a
/// test failure. Returns how many decks were answered.
Future<int> _settle(WidgetTester t, {int calmMs = 2800, int maxMs = 40000}) async {
  var decks = 0;
  var calm = 0;
  for (var ms = 0; ms < maxMs && calm < calmMs; ms += 100) {
    expect(find.byType(MistakeCard), findsNothing, reason: 'no slip in a clean play');
    if (find.byType(ChoiceDeck).evaluate().isNotEmpty) {
      await _pickRight(t, _allRight);
      await _pump(t, 900);
      decks++;
      calm = 0;
      continue;
    }
    await t.pump(const Duration(milliseconds: 100));
    calm += 100;
  }
  return decks;
}

/// Design px → screen px on the 392 × 850 test screen (the scene is 360 wide).
const _k = 392 / 360;
Offset _screen(M5FaultAddressProbe p, Offset world) => Offset((world.dx - p.camera) * _k, world.dy * _k);

/// Drags van [van] so that it ends at path position [s] (van 1 snaps to a
/// device's pole when close).
Future<void> _driveTo(WidgetTester t, M5FaultAddressProbe p, double s, {int van = 1}) async {
  final run = p.run!;
  final geo = p.geo!;
  final from = van == 1 ? run.vanS : run.van2S!;
  final dx = (s - from) / M5FaGeo.dragGain * geo.dir * _k;
  await t.dragFrom(_screen(p, geo.vanAt(from)), Offset(dx, 0));
  await _pump(t, 300);
}

/// Reads device [n]: the van beside it, a tap, the close-up.
Future<void> _read(WidgetTester t, M5FaultAddressProbe p, M5FaNode n) async {
  final run = p.run!;
  if (!run.beside(n)) await _driveTo(t, p, n.s);
  expect(run.beside(n), isTrue, reason: 'van at ${run.vanS}, device at ${n.s}');
  await t.tapAt(_screen(p, p.geo!.nodeAt(n)));
  await t.pump(const Duration(milliseconds: 100));
  expect(p.closeUp, isTrue, reason: 'the close-up opens');
  await _pump(t, 1900);
}

/// Drags a flag from the tray onto device [n].
Future<void> _flag(WidgetTester t, M5FaultAddressProbe p, M5FaNode n) async {
  final tray = t.getCenter(_label(M5FaLines.flags));
  final to = _screen(p, p.geo!.nodeAt(n));
  await t.dragFrom(tray, to - tray);
  await _pump(t, 300);
}

/// The readings that find the fault the right way: from the source end, every
/// T-off's branch FPI before passing it (its second one after a lit first).
List<M5FaNode> _plan(M5FaCall c) {
  final out = <M5FaNode>[];
  final mains = c.mains;
  for (var i = 0; i < mains.length; i++) {
    if (i > 0) {
      for (final (k, b) in c.branches.indexed) {
        if (b.s > mains[i - 1].s && b.s < mains[i].s) {
          final bn = c.branchNodes(k);
          out.add(bn[0]);
          if (c.lit(bn[0])) out.add(bn[1]);
        }
      }
    }
    out.add(mains[i]);
  }
  return out;
}

/// The radio: the control room informed, the docket in.
Future<void> _callControl(WidgetTester t) async {
  await t.tap(_label(M5FaLines.radio));
  await _pump(t, 400);
}

/// Plays the current call right (the coworker refused when he comes).
Future<void> _solveCall(WidgetTester t, M5FaultAddressProbe p) async {
  final run = p.run!;
  final c = run.call;
  final idx = run.index;
  if (run.docketDue) {
    await _callControl(t);
    expect(run.docket, isTrue);
    expect(find.text(M5FaLines.docket(c)), findsOneWidget, reason: 'the chip fills in');
  } else {
    expect(c.inService, isTrue, reason: 'only the in-service call has no docket step');
  }
  if (c.kind == M5FaKind.long) {
    await _driveTo(t, p, run.van2S! + 160, van: 2);
    expect(run.van2Sent, isTrue);
    await _settle(t);
  }
  for (final n in _plan(c)) {
    if (run.reads.containsKey(c.faultAfter) && run.reads.containsKey(c.faultNext)) break;
    if (run.reads.containsKey(n.id)) continue;
    await _read(t, p, n);
    await _settle(t);
  }
  await _flag(t, p, c.nodes[c.faultAfter]);
  await _settle(t, calmMs: 400);
  await _flag(t, p, c.nodes[c.faultNext]);
  await _settle(t, calmMs: 3500);
  expect(run.index, idx + 1, reason: 'the call is done');
}

int _seedWhere(bool Function(M5FaDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5FaDeal(math.Random(s))));

Future<ProviderContainer> _open(WidgetTester t, int seed, M5FaultAddressProbe p) async {
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5FaultAddressPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: p)),
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

/// A run on call [i] of [d] (for the rules), the docket taken unless
/// [docket] is false.
M5FaRun _runAt(M5FaDeal d, int i, {bool docket = true}) {
  final r = M5FaRun(d);
  for (var k = 0; k < i; k++) {
    r.next();
  }
  if (docket) r.takeDocket();
  return r;
}

void main() {
  group('rules', () {
    test('deals: a trip first, then the long and the in-service call; plays differ in route, mirror, start, fault, grove, coworker, history', () {
      final seen = <String>{};
      final starts = <M5FaStart>{};
      final mirrors = <bool>{};
      final templates = <int>{};
      final cw = <int>{};
      var branchFaults = 0;
      var groves = 0;
      var history = 0;
      for (var s = 0; s < 120; s++) {
        final d = m5FaDeal(math.Random(s));
        expect(d.calls, hasLength(3));
        expect(d.calls.first.kind, M5FaKind.trip);
        expect(d.calls.skip(1).map((c) => c.kind).toSet(), {M5FaKind.long, M5FaKind.sectionalizer});
        cw.add(d.coworkerCall);
        if (d.historyCall != null) history++;
        for (final c in d.calls) {
          starts.add(c.start);
          mirrors.add(c.mirrored);
          if (c.template >= 0) templates.add(c.template);
          if (c.faultOnBranch) branchFaults++;
          if (c.branches.any((b) => b.grove)) groves++;
        }
        seen.add([
          for (final c in d.calls) '${c.template}${c.mirrored}${c.start.name}${c.faultAfter}-${c.faultNext}${c.branches.length}',
          d.coworkerCall,
          d.historyCall,
        ].join('|'));
      }
      expect(seen.length, greaterThan(100));
      expect(starts, M5FaStart.values.toSet());
      expect(mirrors, {true, false});
      expect(templates, {0, 1, 2, 3});
      expect(cw, {0, 1, 2});
      expect(branchFaults, greaterThan(10));
      expect(groves, greaterThan(10));
      expect(history, inInclusiveRange(30, 90), reason: 'about half the plays');
    });

    test('every call: devices apart, the van starts beside none, the fault pair is two neighbours on one path', () {
      for (var s = 0; s < 120; s++) {
        for (final c in m5FaDeal(math.Random(s)).calls) {
          final stops = [for (final n in c.mains) n.s, for (final b in c.branches) b.s]..sort();
          for (var i = 1; i < stops.length; i++) {
            expect(stops[i] - stops[i - 1], greaterThan(2 * M5FaGeo.besideRange), reason: 'seed $s ${c.kind}: beside one stop, never beside the next');
          }
          for (final n in c.nodes) {
            expect((c.startS - n.s).abs(), greaterThan(M5FaGeo.besideRange), reason: 'seed $s ${c.kind} ${c.start}');
          }
          final a = c.nodes[c.faultAfter];
          final b = c.nodes[c.faultNext];
          expect(a.branch, b.branch);
          expect(b.order, a.order + 1);
          expect(c.lit(a), isTrue);
          expect(c.lit(b), isFalse);
          if (c.kind == M5FaKind.sectionalizer) {
            expect(a.sectionalizer, isTrue);
            expect(c.nodes.where((n) => n.sectionalizer), hasLength(1));
            expect(c.branches.where((x) => x.grove), isEmpty);
          } else {
            expect(c.nodes.where((n) => n.sectionalizer), isEmpty);
          }
          if (c.kind == M5FaKind.long) expect(c.start, M5FaStart.depot);
          for (final n in c.nodes) {
            expect(RegExp('[০-৯]').hasMatch(n.pole), isFalse);
          }
        }
      }
    });

    test('the FPIs light up to the fault: on the main line, on a branch, at the sectionalizer', () {
      for (var s = 0; s < 80; s++) {
        for (final c in m5FaDeal(math.Random(s)).calls) {
          final a = c.nodes[c.faultAfter];
          for (final n in c.nodes) {
            final lit = c.lit(n);
            if (a.main) {
              expect(lit, n.main && n.s <= a.s, reason: '$s main fault ${n.id}');
            } else {
              final j = c.branches[a.branch!].s;
              expect(lit, n.main ? n.s < j : (n.branch == a.branch && n.order == 1), reason: '$s branch fault ${n.id}');
            }
          }
        }
      }
    });

    test('readings: the first away from the source is a slip; source first → its reason once a play', () {
      final d = m5FaDeal(math.Random(3));
      final r = _runAt(d, 0);
      final c = r.call;
      final away = r.read(c.mains[1].id);
      expect(away.mistake, M5FaMistakes.farStart);
      expect(r.slips, 1);
      expect(r.reads.containsKey(c.mains[1].id), isTrue, reason: 'the reading still counts');
      expect(r.read(c.mains[1].id).again, isTrue);
      expect(r.slips, 1);
      final r2 = _runAt(d, 0);
      final first = r2.read(r2.call.sourceFirst.id);
      expect(first.mistake, isNull);
      expect(first.reason, M5FaReason.source);
      expect(r2.caught, contains(M5FaLines.caughtSource));
      expect(r2.askedSource, isTrue);
    });

    test('T-offs: reading past an unread branch FPI is a slip (once per T-off); its FPI first → the T-off reason', () {
      // A trip call with a T-off between main 0 and main 1.
      final seed = _seedWhere((d) {
        final c = d.calls[0];
        return c.branches.any((b) => b.s < c.mains[1].s);
      });
      final d = m5FaDeal(math.Random(seed));
      final c = d.calls[0];
      final k = c.branches.indexWhere((b) => b.s < c.mains[1].s);
      final b1 = c.branchNodes(k)[0];
      final a = _runAt(d, 0)..read(c.mains[0].id);
      expect(a.read(c.mains[1].id).mistake, M5FaMistakes.skipTee);
      expect(a.slips, 1);
      expect(a.teeSlipped, contains(k), reason: 'that T-off is booked once');
      final b = _runAt(d, 0)..read(c.mains[0].id);
      final rb = b.read(b1.id);
      expect(rb.mistake, isNull);
      expect(rb.reason, M5FaReason.tee);
      expect(b.read(c.mains[1].id).mistake, isNull);
      expect(b.slips, 0);
    });

    test('long feeder: reading or driving before van 2 goes = a slip; van 2 sent → its reason; its team radios from the far end', () {
      final d = m5FaDeal(math.Random(5));
      final li = d.calls.indexWhere((c) => c.kind == M5FaKind.long);
      final r = _runAt(d, li);
      final c = r.call;
      expect(r.van2S, isNotNull);
      expect(r.driveEnd(c.startS + 10), isNull, reason: 'a nudge is fine');
      expect(r.driveEnd(c.startS + 120), M5FaMistakes.alone);
      expect(r.driveEnd(c.startS + 300), isNull, reason: 'once');
      expect(r.sendVan2(), isNull, reason: 'no ◆ after driving off alone');
      final r2 = _runAt(d, li);
      expect(r2.read(r2.call.sourceFirst.id).mistake, M5FaMistakes.alone);
      final r3 = _runAt(d, li);
      expect(r3.sendVan2(), M5FaReason.long);
      expect(r3.caught, contains(M5FaLines.caughtSplit));
      expect(r3.van2S, greaterThan(c.length));
      final first = r3.teamReport();
      expect(first, c.loadLast, reason: 'the team starts at the load end');
      // The team never reports past a lit main-line FPI.
      final told = <M5FaNode>[?first];
      for (var i = 0; i < 20; i++) {
        final n = r3.teamReport();
        if (n == null) break;
        told.add(n);
      }
      final litMain = told.indexWhere((n) => n.main && c.lit(n));
      if (litMain >= 0) expect(litMain, told.length - 1);
      for (final n in told) {
        expect(r3.reads[n.id], c.lit(n));
      }
    });

    test('flags: only on read devices; a wrong pair is a slip (the flags come back); the right pair brackets', () {
      final d = m5FaDeal(math.Random(8));
      final r = _runAt(d, 0);
      final c = r.call;
      final pair = c.faultPair.toList();
      expect(r.placeFlag(pair[0]).placed, isFalse, reason: 'not read yet');
      for (final n in _plan(c)) {
        r.read(n.id);
      }
      final wrong = c.nodes.firstWhere((n) => r.reads.containsKey(n.id) && !c.faultPair.contains(n.id));
      expect(r.placeFlag(wrong.id).placed, isTrue);
      final f = r.placeFlag(pair[0]);
      expect(f.judged, isTrue);
      expect(f.mistake, M5FaMistakes.wrongBracket);
      r.returnFlags();
      expect(r.flags, isEmpty);
      expect(r.placeFlag(pair[1]).placed, isTrue);
      expect(r.placeFlag(pair[0]).right, isTrue);
      expect(r.bracketed, isTrue);
      expect(r.caught, isNot(contains(M5FaLines.caughtBracket)), reason: 'after a wrong pair');
      expect(r.read(pair[0]).again, isTrue, reason: 'nothing more to read');
    });

    test('in-service call: the wrong pair says sectionalizer; the history note: repair only = a slip, then the root cause', () {
      final seed = _seedWhere((d) => d.historyCall != null && d.calls[d.historyCall!].kind == M5FaKind.sectionalizer);
      final d = m5FaDeal(math.Random(seed));
      final r = _runAt(d, d.historyCall!);
      final c = r.call;
      expect(c.inService, isTrue);
      for (final n in _plan(c)) {
        r.read(n.id);
      }
      final s = c.sectionalizerNode!;
      expect(c.faultAfter, s.id);
      r.placeFlag(c.mains.first.id == s.id ? c.mains.last.id : c.mains.first.id);
      expect(r.placeFlag(s.id).mistake, M5FaMistakes.wrongSect);
      r.returnFlags();
      r.placeFlag(c.faultAfter);
      expect(r.placeFlag(c.faultNext).right, isTrue);
      expect(r.historyDue, isTrue);
      expect(r.callDone, isFalse);
      expect(r.pickHistory(false), M5FaMistakes.repairOnly);
      expect(r.pickHistory(true), isNull);
      expect(r.caught, contains(M5FaLines.caughtRoot));
      expect(r.callDone, isTrue);
    });

    test('the docket (ruling M5-3): before it a drive, van 2 or a reading is a slip once a call and goes nowhere; the radio fills it in; the in-service call needs none', () {
      for (var s = 0; s < 40; s++) {
        final d = m5FaDeal(math.Random(s));
        for (var i = 0; i < 3; i++) {
          final r = _runAt(d, i, docket: false);
          final c = r.call;
          if (c.inService) {
            expect(r.docketDue, isFalse, reason: 'ground patrol of a live line: no docket step');
            expect(r.docket, isTrue);
            expect(r.takeDocket(), isFalse);
            expect(r.patrolWithoutDocket(), isNull);
            continue;
          }
          expect(r.docketDue, isTrue, reason: 'seed $s ${c.kind}');
          expect(r.driveEnd(c.startS + 10), isNull, reason: 'a nudge is fine');
          expect(r.blocked, isFalse);
          expect(r.driveEnd(c.startS + 150), M5FaMistakes.noDocket);
          expect(r.blocked, isTrue);
          expect(r.vanS, c.startS, reason: 'the van stays');
          expect(r.slips, 1);
          expect(r.driveEnd(c.startS - 150), isNull, reason: 'once a call');
          expect(r.vanS, c.startS);
          expect(r.slips, 1);
          final rd = r.read(c.sourceFirst.id);
          expect(rd.blocked, isTrue);
          expect(rd.mistake, isNull);
          expect(r.reads, isEmpty, reason: 'nothing read before the docket');
          if (c.kind == M5FaKind.long) {
            expect(r.sendVan2(), isNull);
            expect(r.van2Sent, isFalse);
          }
          expect(r.caught, isNot(contains(M5FaLines.caughtDocket)), reason: 'after the slip');
          expect(r.takeDocket(), isTrue);
          expect(r.docketDue, isFalse);
          expect(r.takeDocket(), isFalse);
          if (c.kind == M5FaKind.long) expect(r.sendVan2(), M5FaReason.long);
          expect(r.driveEnd(c.startS + 150), isNull);
          expect(r.blocked, isFalse);
          expect(r.vanS, c.startS + 150);
          // A reading before the docket on a fresh call: the slip.
          final r2 = _runAt(d, i, docket: false);
          final rd2 = r2.read(c.sourceFirst.id);
          expect(rd2.blocked, isTrue);
          expect(rd2.mistake, M5FaMistakes.noDocket);
          expect(r2.slips, 1);
          // Taken first: the catch.
          final r3 = _runAt(d, i);
          expect(r3.caught, contains(M5FaLines.caughtDocket));
          expect(r3.slips, 0);
        }
      }
      // The next call asks again.
      final r = _runAt(m5FaDeal(math.Random(2)), 0);
      expect(r.docketDue, isFalse);
      r.next();
      expect(r.docket, r.call.inService);
    });

    test('a needless stop (the readings in hand already tell it) costs the clean-call +5, never a T-off slip', () {
      // Past the bracket: a main-line fault with a T-off and a main beyond it.
      final seed = _seedWhere((d) {
        final c = d.calls[0];
        final next = c.nodes[c.faultNext];
        return next.main && c.branches.any((b) => b.s > next.s && c.mains.any((m) => m.s > b.s));
      });
      final d = m5FaDeal(math.Random(seed));
      final r = _runAt(d, 0);
      final c = r.call;
      for (final n in _plan(c)) {
        if (r.pairFound) break;
        final rd = r.read(n.id);
        expect(rd.needless, isFalse);
        expect(rd.mistake, isNull);
      }
      expect(r.pairFound, isTrue);
      expect(r.thorough, isTrue);
      final next = c.nodes[c.faultNext];
      final k = c.branches.indexWhere((b) => b.s > next.s && c.mains.any((m) => m.s > b.s));
      final beyond = c.mains.firstWhere((m) => m.s > c.branches[k].s);
      final rd = r.read(beyond.id);
      expect(rd.needless, isTrue);
      expect(rd.mistake, isNull, reason: 'the T-off is past the bracket: no skip-tee');
      expect(r.teeSlipped, isEmpty);
      expect(r.slips, 0);
      expect(r.needless, isTrue);
      expect(r.thorough, isFalse, reason: 'the clean-call +5 is gone');
      expect(r.reads[beyond.id], isFalse, reason: 'still chalked');
      r.next();
      expect(r.needless, isFalse, reason: 'per call');

      // Before the bracket: a branch's second FPI when its first is dark.
      final s2 = _seedWhere((d) {
        final c = d.calls[0];
        return c.branches.indexed.any((e) => !c.lit(c.branchNodes(e.$1)[0]));
      });
      final d2 = m5FaDeal(math.Random(s2));
      final r2 = _runAt(d2, 0);
      final c2 = r2.call;
      final k2 = c2.branches.indexed.firstWhere((e) => !c2.lit(c2.branchNodes(e.$1)[0])).$1;
      final bn = c2.branchNodes(k2);
      expect(r2.read(c2.sourceFirst.id).needless, isFalse);
      expect(r2.read(bn[0].id).needless, isFalse);
      expect(r2.pairFound, isFalse);
      expect(r2.known(bn[1]), isTrue);
      expect(r2.read(bn[1].id).needless, isTrue);
      expect(r2.slips, 0);
      expect(r2.thorough, isFalse);
    });

    test('the right way never makes a needless stop; whatever is known agrees with the devices', () {
      for (var s = 0; s < 60; s++) {
        final d = m5FaDeal(math.Random(s));
        for (var i = 0; i < 3; i++) {
          final r = _runAt(d, i);
          final c = r.call;
          if (c.kind == M5FaKind.long) r.sendVan2();
          for (final n in _plan(c)) {
            if (r.pairFound) break;
            if (r.reads.containsKey(n.id)) continue;
            expect(r.known(n), isFalse, reason: 'seed $s call $i node ${n.id}');
            r.read(n.id);
            r.teamReport();
          }
          expect(r.needless, isFalse);
          expect(r.pairFound, isTrue);
        }
        // Halfway down the plan: anything known is what the device shows.
        for (var i = 0; i < 3; i++) {
          final r = _runAt(d, i);
          final c = r.call;
          if (c.kind == M5FaKind.long) r.sendVan2();
          final plan = _plan(c);
          for (final n in plan.take(plan.length ~/ 2)) {
            r.read(n.id);
          }
          for (final n in c.nodes) {
            if (r.reads.containsKey(n.id) || r.pairFound || !r.known(n)) continue;
            final upDark = c.mains.any((m) => r.reads[m.id] == false && m.s < (n.main ? n.s : c.branches[n.branch!].s));
            final downLit = c.mains.any((m) => r.reads[m.id] == true && m.s > (n.main ? n.s : c.branches[n.branch!].s));
            if (n.main) {
              if (upDark) expect(c.lit(n), isFalse, reason: 'seed $s ${n.id}');
              if (downLit) expect(c.lit(n), isTrue, reason: 'seed $s ${n.id}');
            } else if (upDark || downLit) {
              expect(c.lit(n), isFalse, reason: 'seed $s ${n.id}: the fault is not on that T-off');
            }
          }
        }
      }
    });

    test('decoy groves reach the road on every call, clear of every device and visible T-off', () {
      for (var s = 0; s < 120; s++) {
        for (final c in m5FaDeal(math.Random(s)).calls) {
          final g = m5FaDecoyGroves(c, s);
          expect(g, isNotEmpty, reason: 'seed $s ${c.kind}: a grove by the road tells nothing');
          for (final x in g) {
            for (final n in c.mains) {
              expect((x - n.s).abs(), greaterThanOrEqualTo(95));
            }
            for (final b in c.branches) {
              expect((x - b.s).abs(), greaterThanOrEqualTo(115));
            }
          }
          expect(m5FaDecoyGroves(c, s), g, reason: 'the same every frame');
        }
      }
    });

    test('three calls; 100 − 15 per slip; pass at 55', () {
      final r = M5FaRun(m5FaDeal(math.Random(1)));
      r.slips = 3;
      for (var i = 0; i < 3; i++) {
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.percent, 55);
      expect(r.passed, isTrue);
      r.slips = 4;
      expect(r.passed, isFalse);
    });

    test('English digits only; no deadly act; every mistake has its picture; keys unique', () {
      final all = <String>[
        M5FaLines.intro,
        M5FaLines.callLong,
        M5FaLines.callSect,
        M5FaLines.callTrip,
        ...M5FaLines.tasks,
        M5FaLines.tooFar,
        M5FaLines.askDocket,
        M5FaLines.needlessDone,
        M5FaLines.needlessKnown,
        M5FaLines.radio,
        M5FaLines.historyNote,
        ...M5FaLines.allWhyRight,
        ...M5FaLines.myths,
        ...M5FaLines.historyRight,
        ...M5FaLines.historyWrong,
        ...M5FaLines.coworker.recordedLines,
        ...M5FaLines.coworker.right,
        ...M5FaLines.coworker.wrong,
        ...M5FaLines.coworker.asks,
        for (final m in M5FaMistakes.all) m.textBn,
        M5FaLines.allSet,
        M5FaLines.quick,
        M5FaLines.fail,
        for (var s = 0; s < 20; s++)
          for (final c in m5FaDeal(math.Random(s)).calls) ...[
            M5FaLines.docket(c),
            M5FaLines.feederOnly(c),
            M5FaLines.control(c),
            for (final n in c.nodes) ...[M5FaLines.pole(n.pole), M5FaLines.team(n, true), M5FaLines.team(n, false)],
          ],
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      // The docket is the control room's (ruling M5-3) — a PTW only in the
      // ruling's card ("before touching or climbing"), never for the ground patrol.
      expect(all.where((l) => l.contains('PTW')), [M5FaMistakes.noDocket.textBn]);
      expect(M5FaMistakes.noDocket.textBn, startsWith('টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে PTW বাধ্যতামূলক'));
      expect(M5FaMistakes.all, contains(M5FaMistakes.noDocket));
      expect(M5FaMistakes.all.where((m) => m.deadly), isEmpty);
      expect(M5FaMistakes.all.map((m) => m.key).toSet(), hasLength(M5FaMistakes.all.length));
      for (final m in M5FaMistakes.all) {
        expect(m.key, startsWith('5.2/m5_fault_address/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      // Every picture in the folder is used.
      final used = M5FaMistakes.all.map((m) => m.art.split('/').last).toSet();
      final files = Directory('assets/game/art/m5_fault_address').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m5FaultAddressPacks.keys, ['do_5_2_a']);
    });

    test('libraries: same length, big enough, one right per deal; the coworker\'s new line is listed for recording, his exit is recorded', () {
      expectSameLength('why', [...M5FaLines.allWhyRight, ...M5FaLines.myths]);
      expect(M5FaLines.myths.toSet().intersection(M5FaLines.allWhyRight.toSet()), isEmpty);
      for (final r in M5FaReason.values) {
        for (final k in M5FaKind.values) {
          final right = M5FaLines.whyRight(r, k);
          expectLibrary('$r $k', right, M5FaLines.myths);
          expect(M5FaLines.whyQuestion(r), isNotEmpty);
          for (var s = 0; s < 10; s++) {
            final deal = dealChoices(right, M5FaLines.myths, math.Random(s));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      expectSameLength('history', [...M5FaLines.historyRight, ...M5FaLines.historyWrong]);
      expectLibrary('history', M5FaLines.historyRight, M5FaLines.historyWrong);
      final cw = M5FaLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.line.startsWith('ফল্ট মানেই তার ছিঁড়ে যাওয়া বা কিছু ভেঙে যাওয়া।'), isTrue, reason: 'the lesson\'s myth 2, word for word');
      expect(M5FaLines.rivalLinesMissing, contains(cw.line));
      for (final l in cw.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true) != null || M5FaLines.rivalLinesMissing.contains(l), isTrue, reason: l);
      }
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('tap areas: devices and the van never overlap and stay below the header, above the dashboard', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        for (var s = 0; s < 30; s++) {
          for (final c in m5FaDeal(math.Random(s)).calls) {
            final g = M5FaGeo.forScene(h, 0, c);
            final rects = [for (final n in c.nodes) g.nodeHit(n)];
            for (final r in rects) {
              expect(r.top, greaterThan(110), reason: 'below the header ($h)');
              expect(r.bottom, lessThan(g.vanY), reason: 'above the road');
            }
            for (var i = 0; i < rects.length; i++) {
              for (var j = i + 1; j < rects.length; j++) {
                final x = rects[i].intersect(rects[j]);
                expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h seed $s: ${c.nodes[i].id}/${c.nodes[j].id}');
              }
            }
            final van = g.vanHit(c.startS);
            expect(van.bottom, lessThan(h - 150), reason: 'clear of the corner guide and the dashboard');
            for (final n in c.nodes) {
              final x = g.vanHit(n.s).intersect(g.nodeHit(n));
              expect(x.width <= 0 || x.height <= 0, isTrue);
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

    testWidgets('the guide comes first: no start button, a tap does not skip him; then the dashboard', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5FaultAddressPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5FaLines.map), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5FaLines.map), findsOneWidget);
      expect(_label(M5FaLines.flags), findsOneWidget);
      final d = m5FaDeal(math.Random(3));
      // A tripped feeder: the docket is not handed over — the radio waits.
      expect(find.text(M5FaLines.feederOnly(d.calls.first)), findsOneWidget);
      expect(find.text(M5FaLines.docket(d.calls.first)), findsNothing);
      expect(_label(M5FaLines.radio), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final p = M5FaultAddressProbe();
      final c = await _open(t, 5, p);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5FaLines.askStart)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a device the van is not beside can not be read; the map opens and closes; nothing is booked', (t) async {
      final p = M5FaultAddressProbe();
      final seed = _seedWhere((d) => d.calls[0].start == M5FaStart.loadEnd);
      final c = await _open(t, seed, p);
      final run = p.run!;
      final far = run.call.sourceFirst;
      await _callControl(t);
      await _driveTo(t, p, run.call.mains[1].s);
      expect(run.beside(far), isFalse);
      final at = _screen(p, p.geo!.nodeAt(far));
      if (at.dx > 0 && at.dx < 392) {
        await t.tapAt(at);
        await t.pump(const Duration(milliseconds: 200));
        expect(p.closeUp, isFalse);
      }
      await t.tap(_label(M5FaLines.map));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('map')), findsOneWidget);
      await t.tapAt(const Offset(196, 200));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('map')), findsNothing);
      expect(run.reads, isEmpty);
      expect(run.slips, 0);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    // One play with the history note, one where he comes on the long or the
    // in-service call.
    final flowSeeds = [
      _seedWhere((d) => d.historyCall != null && d.coworkerCall == 0),
      _seedWhere((d) => d.historyCall == null && d.coworkerCall == 2),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three calls read the right way, the coworker refused, right reasons → pass', (t) async {
        final p = M5FaultAddressProbe();
        final c = await _open(t, seed, p);
        for (var i = 0; i < 3; i++) {
          await _solveCall(t, p);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.2/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.2/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5FaLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
        expect(find.text(M5FaLines.caughtSource), findsOneWidget);
        expect(find.text(M5FaLines.caughtBracket), findsOneWidget);
        expect(find.text(M5FaLines.caughtSplit), findsOneWidget);
        expect(find.text(M5FaLines.caughtDocket), findsOneWidget, reason: 'the control room told first');
        if (m5FaDeal(math.Random(seed)).historyCall != null) expect(find.text(M5FaLines.caughtRoot), findsOneWidget);
        expect(find.byType(CoworkerPeek), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a fast play: after his reading the van waits for the coworker; listening to him = a slip card, the call goes on', (t) async {
      // He comes in call 1 on the 2nd reading, which is main FPI 1 (no T-off before it).
      final seed = _seedWhere((d) {
        final c = d.calls[0];
        return d.coworkerCall == 0 && !c.branches.any((b) => b.s < c.mains[1].s);
      });
      final p = M5FaultAddressProbe();
      final c = await _open(t, seed, p);
      final run = p.run!;
      final call = run.call;
      await _callControl(t);
      await _read(t, p, call.mains[0]);
      await _settle(t);
      await _read(t, p, call.mains[1]);
      // At once: drag the van on — he cuts in, the van stays.
      final before = run.vanS;
      await t.dragFrom(_screen(p, p.geo!.vanAt(run.vanS)), Offset(80 * p.geo!.dir, 0));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(run.vanS, before, reason: 'the van waits for him');
      expect(find.text(M5FaLines.coworker.line), findsOneWidget, reason: 'beat 1: his caption');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickWrong(t, M5FaLines.coworker.wrong);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5FaMistakes.listened.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(run.slips, 1);
      expect(run.index, 0, reason: 'the same call goes on');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5FaMistakes.listened.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the docket first (ruling M5-3): driving off before the radio call = the card, the van stays; the radio fills in the chip; then the van drives', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall != 0);
      final p = M5FaultAddressProbe();
      final c = await _open(t, seed, p);
      final run = p.run!;
      final call = run.call;
      expect(run.docketDue, isTrue);
      final start = run.vanS;
      await _driveTo(t, p, call.mains[1].s);
      expect(find.text(M5FaMistakes.noDocket.textBn), findsOneWidget);
      expect(run.vanS, start, reason: 'the van stays');
      expect(run.slips, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(c.read(guideDirectorProvider).line, M5FaLines.askDocket, reason: 'after the card the guide says it');
      // Again: turned back, no second card.
      await _driveTo(t, p, call.mains[1].s);
      expect(find.byType(MistakeCard), findsNothing);
      expect(run.vanS, start);
      expect(run.slips, 1);
      expect(find.text(M5FaLines.feederOnly(call)), findsOneWidget);
      await _callControl(t);
      expect(run.docket, isTrue);
      expect(find.text(M5FaLines.docket(call)), findsOneWidget, reason: 'the chip fills in');
      expect(_label(M5FaLines.control(call)), findsOneWidget, reason: 'the control room answers on the radio');
      await _driveTo(t, p, call.sourceFirst.s);
      expect(run.beside(call.sourceFirst), isTrue, reason: 'now the van drives');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5FaMistakes.noDocket.key);
      expect(run.caught, isNot(contains(M5FaLines.caughtDocket)));
      await _close(t, c);
    });

    testWidgets('the grove T-off gives nothing away: a far tap on it is a tap on trees, no snap to its junction; parked beside it its boxes show faintly and read', (t) async {
      final seed = _seedWhere((d) {
        final c = d.calls[0];
        return d.coworkerCall != 0 && c.branches.any((b) => b.grove);
      });
      final p = M5FaultAddressProbe();
      final c = await _open(t, seed, p);
      final run = p.run!;
      final call = run.call;
      final k = call.branches.indexWhere((b) => b.grove);
      final hidden = call.branchNodes(k)[0];
      await _callControl(t);
      await _read(t, p, call.sourceFirst);
      await _settle(t);
      M5FaWorldPainter painter() => t.widgetList<CustomPaint>(find.byType(CustomPaint)).map((w) => w.painter).whereType<M5FaWorldPainter>().first;
      expect(painter().peek, isEmpty);
      // A tap where its box hides, the van away: silence, like any grove.
      final at = _screen(p, p.geo!.nodeAt(hidden));
      if (at.dx > 10 && at.dx < 382 && !run.beside(hidden)) {
        await t.tapAt(at);
        await _pump(t, 400);
        expect(p.closeUp, isFalse);
        expect(c.read(guideDirectorProvider).line, isNot(M5FaLines.tooFar), reason: 'no "take the van there" for a hidden box');
      }
      // A drop just outside reach of the junction does not snap onto it.
      final j = call.branches[k].s;
      await _driveTo(t, p, run.vanS < j ? j - (M5FaGeo.besideRange + 6) : j + (M5FaGeo.besideRange + 6));
      expect(run.beside(hidden), isFalse, reason: 'no snap to the grove junction');
      // Parked beside it: the boxes show faintly, and a map reader can read it.
      await _driveTo(t, p, call.branches[k].s);
      expect(run.beside(hidden), isTrue);
      expect(painter().peek, {k});
      await t.tapAt(_screen(p, p.geo!.nodeAt(hidden)));
      await t.pump(const Duration(milliseconds: 100));
      expect(p.closeUp, isTrue);
      await _pump(t, 1900);
      expect(run.reads.containsKey(hidden.id), isTrue);
      await _close(t, c);
    });

    testWidgets('a needless stop: past the bracket the guide says so, no card, no slip', (t) async {
      final seed = _seedWhere((d) {
        final c = d.calls[0];
        final next = c.nodes[c.faultNext];
        return d.coworkerCall != 0 && next.main && c.mains.last.id != next.id && !c.branches.any((b) => b.s > next.s && b.s < c.mains[next.order + 1].s);
      });
      final p = M5FaultAddressProbe();
      final c = await _open(t, seed, p);
      final run = p.run!;
      final call = run.call;
      await _callControl(t);
      for (final n in _plan(call)) {
        if (run.pairFound) break;
        await _read(t, p, n);
        await _settle(t);
      }
      await _read(t, p, call.mains[call.nodes[call.faultNext].order + 1]);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(run.slips, 0);
      expect(run.thorough, isFalse);
      expect(c.read(guideDirectorProvider).line, M5FaLines.needlessDone);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (patrol before the docket, a far first reading, a wrong bracket)', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall != 0);
      final p = M5FaultAddressProbe();
      final c = await _open(t, seed, p);
      final run = p.run!;
      final call = run.call;
      await _driveTo(t, p, call.loadLast.s);
      expect(find.text(M5FaMistakes.noDocket.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _callControl(t);
      await _read(t, p, call.loadLast);
      expect(find.text(M5FaMistakes.farStart.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _read(t, p, call.sourceFirst);
      await _pump(t, 600);
      await _flag(t, p, call.sourceFirst);
      await _flag(t, p, call.loadLast);
      await _pump(t, 2700);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the radio and the van before the docket; then a short van nudge; the tap pulse on the device beside the van, never on the grove\'s; none with the map open', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.calls[0].start != M5FaStart.mid && d.coworkerCall != 0 && d.calls[0].branches.any((b) => b.grove));
      final p = M5FaultAddressProbe();
      final c = await _open(t, seed, p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      Offset origin() => t.getTopLeft(find.byType(IdleHint).first);
      final call = p.run!.call;
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the start');
      // Before the docket: a sweep over the radio and the van — what can be
      // touched, never which first.
      final opts = scene().debugOptions;
      expect(opts, hasLength(2));
      final radio = t.getCenter(_label(M5FaLines.radio)) - origin();
      final van = _screen(p, p.geo!.vanAt(p.run!.vanS)) - origin();
      expect(opts.where((r) => r.contains(radio)), hasLength(1), reason: 'the radio');
      expect(opts.where((r) => r.contains(van)), hasLength(1), reason: 'the van');
      await _callControl(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle after the docket');
      expect(scene().debugOptions, isEmpty, reason: 'beside nothing: a short van nudge');
      final nudge = scene().debugFrame;
      if (nudge != null && nudge.ripple != null) {
        expect((nudge.tip - (_screen(p, p.geo!.vanAt(p.run!.vanS)) - origin())).distance, lessThan(40), reason: 'it presses the van, nothing else');
      }
      // Beside the source FPI: the tap pulse lands on it (the one way forward).
      await _driveTo(t, p, call.sourceFirst.s);
      HintFrame? pressed;
      for (var ms = 0; ms < 14000 && pressed == null; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        final f = scene().debugFrame;
        if (f?.ripple != null) pressed = f;
      }
      expect(pressed, isNotNull, reason: 'a tap pulse beside an unread device');
      final dev = _screen(p, p.geo!.nodeAt(call.sourceFirst)) - origin();
      expect((pressed!.tip - dev).distance, lessThan(6), reason: 'on the device beside the van');
      await t.tapAt(_screen(p, p.geo!.nodeAt(call.sourceFirst)));
      await _pump(t, 1900);
      await _settle(t);
      // Beside only the grove junction: never a tap on the hidden boxes.
      final hidden = call.branchNodes(call.branches.indexWhere((b) => b.grove));
      await _driveTo(t, p, hidden.first.s);
      expect(p.run!.beside(hidden.first), isTrue);
      var shown = false;
      for (var ms = 0; ms < 14000; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        final f = scene().debugFrame;
        if (f == null) continue;
        shown = true;
        expect(scene().debugOptions, isEmpty, reason: 'no sweep over the hidden boxes');
        if (f.ripple == null) continue;
        // Pressed: on the van (its nudge), never on a box under the grove.
        final vanAt = _screen(p, p.geo!.vanAt(p.run!.vanS)) - origin();
        expect((f.tip - vanAt).distance, lessThan(40), reason: 'the press is on the van');
        for (final n in hidden) {
          expect((f.tip - (_screen(p, p.geo!.nodeAt(n)) - origin())).distance, greaterThan(40), reason: 'those boxes show only on the map');
        }
      }
      expect(shown, isTrue, reason: 'the van nudge still shows');
      // The map open: the scene's hand stays away.
      await t.tap(_label(M5FaLines.map));
      await _pump(t, 9500);
      expect(scene().showing, isFalse);
      await t.tapAt(const Offset(196, 200));
      await _pump(t, 300);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
