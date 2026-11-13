// Lesson 5.9 (কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা), কাজ 1 "কোর থেকে কোরে: ফল্টের
// ধরন": the rules (isolate both ends → discharge → nine tests → the verdict;
// a lead or the earthed rod on a core with an end ON = deadly; a clip off a
// charged cable = deadly; the evidence-gated verdict; the pit nearest the
// middle, each section discharged before its lead, and the low half), the
// deal, the libraries, and the level in the shell: the guide first, a full
// clean play with each coworker refused, a slip card that keeps the round,
// three slips, the deadly freezes (a live lead; the rod on a live core; a
// charged clip), listening to
// him, a decisive control that waits for him, and the gesture hand (how,
// never what; none after TEST).
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
import 'package:slm_flutter/features/game/m5_cable_fault_type.dart';
import 'package:slm_flutter/features/game/m5_cable_fault_type_world.dart';
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
  rungId: '5.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5CableFaultTypePacks['do_5_9_a']!;

/// The new art is not in the bundle until the director wires the folder:
/// tests read it from disk when the bundle does not have it.
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
M5CableGeo get _geo => M5CableGeo.forScene(360 * 850 / 392, 0);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5CableFaultTypePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, List<String> right, {int after = 6000}) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: right.first);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, after);
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2600);
}

int _seed(bool Function(M5CableDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5CableDeal(math.Random(s))));

/// Drives the cable room: the camera, taps and holds in world px.
class _Room {
  _Room(this.t);
  final WidgetTester t;
  int view = 0;

  Offset _screen(Offset world) => (world - Offset(360.0 * view, 0)) * _k;

  Future<void> tap(Offset world) async {
    await t.tapAt(_screen(world));
    await _pump(t, 300);
  }

  Future<void> pt(M5Pt p) => tap(_geo.hit(p).center);

  Future<void> hold(Offset world, int ms) async {
    final g = await t.startGesture(_screen(world));
    await _pump(t, ms);
    await g.up();
    await _pump(t, 300);
  }

  Future<void> pan(int to) async {
    await t.tap(_label(to == 1 ? M5CableLines.farEnd : M5CableLines.nearEnd));
    await _pump(t, 700);
    view = to;
  }

  Future<void> tool(M5Tool x) async {
    await t.tap(_label(M5CableLines.toolLabel(x)));
    await _pump(t, 300);
  }

  Future<void> test() async {
    final g = await t.startGesture(_geo.testPad.center * _k);
    await _pump(t, 1500);
    await g.up();
    await _pump(t, 300);
  }

  /// Switch OFF (if ON), hold the hasp, hang the tag, at the end in view.
  Future<void> isolateHere(M5End e, M5CableCase c) async {
    if (c.onEnd == e) await tap(_geo.leverHit(e).center);
    await hold(_geo.haspHit(e).center, 1200);
    await tap(_geo.tagHit(e).center);
  }
}

/// A cable round played right (the coworker refused if he is dealt here).
Future<void> _cableRound(WidgetTester t, M5CableDeal d, int idx) async {
  final c = d.cases[idx];
  final room = _Room(t);
  final cwHere = d.cwRound == idx;
  final cw = m5CableCoworker(d);
  var cwDone = false;
  await room.isolateHere(M5End.near, c);
  await room.pan(1);
  await room.isolateHere(M5End.far, c);
  if (idx == 0) await _reason(t, M5CableLines.isoWhy, after: 1200);
  if (cwHere && !d.cwA2) {
    await _refuse(t, cw);
    cwDone = true;
  }
  await room.pan(0);
  await room.tool(M5Tool.rod);
  for (final p in M5Pt.near) {
    await room.pt(p);
  }
  var discharges = 0;
  Future<void> a2(M5Test test) async {
    if (cwHere && d.cwA2 && !cwDone && test.megger && c.low(test)) {
      await _refuse(t, cw);
      cwDone = true;
    }
  }

  await room.tool(M5Tool.megger);
  const megger = [
    (M5Pt.nearR, M5Pt.nearY, M5Test.insRY),
    (M5Pt.nearY, M5Pt.nearB, M5Test.insYB),
    (M5Pt.nearR, M5Pt.nearB, M5Test.insRB),
    (M5Pt.nearR, M5Pt.armour, M5Test.earthR),
    (M5Pt.nearY, M5Pt.armour, M5Test.earthY),
    (M5Pt.nearB, M5Pt.armour, M5Test.earthB),
  ];
  for (final (a, b, test) in megger) {
    await room.pt(a);
    await room.pt(b);
    expect(find.byKey(const ValueKey('m5c-test')), findsOneWidget, reason: '$test');
    await room.test();
    expect(find.textContaining(c.readings[test]!), findsWidgets, reason: '$test reading');
    await a2(test);
    await room.tool(M5Tool.rod);
    await room.pt(a);
    discharges++;
    if (idx == 1 && discharges == 1) await _reason(t, M5CableLines.dischargeWhy, after: 1200);
    await room.pt(a);
    expect(find.byKey(const ValueKey('m5c-test')), findsNothing);
  }
  await room.tool(M5Tool.multi);
  for (var i = 0; i < 3; i++) {
    await room.pt(M5Pt.near[i]);
    await room.pan(1);
    await room.pt(M5Pt.far[i]);
    await a2(M5Test.values[6 + i]);
    await room.pt(M5Pt.far[i]);
    await room.pan(0);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await t.tap(_label(M5CableLines.verdict));
  await _pump(t, 500);
  for (final f in c.faults) {
    await t.tap(_label(M5CableLines.chipLabel(f)));
    await _pump(t, 200);
  }
  await t.tap(_label(M5CableLines.submit));
  await _pump(t, 800);
  await _reason(t, M5CableLines.kindWhy[c.whyFault.kind]!);
}

/// The pit round played right.
Future<void> _pitRound(WidgetTester t, M5CableDeal d) async {
  final room = _Room(t);
  await room.tap(_geo.pitHit(d.pits[d.rightPit], d.length).center);
  for (final left in [true, false]) {
    final core = (left ? M5Pt.pitL : M5Pt.pitR)[d.pitCore.index];
    await room.tool(M5Tool.rod);
    await room.pt(core);
    await room.tool(M5Tool.megger);
    await room.pt(core);
    await room.pt(M5Pt.pitE);
    await room.test();
    await room.tool(M5Tool.rod);
    await room.pt(core);
    await room.pt(core);
  }
  final at = _geo.pitX(d.pits[d.rightPit], d.length);
  await room.tap(_geo.halfHit(d.faultLeft, at).center);
  await _reason(t, M5CableLines.pitWhy);
}

M5CableRun _isolatedRun(M5CableDeal d) {
  final r = M5CableRun(d);
  for (final e in M5End.values) {
    r.switchOff(e);
    r.lock(e);
    r.hangTag(e);
  }
  return r;
}

M5CableDeal _dealWith(Set<M5Fault> faults, {M5End? on}) {
  final base = m5CableDeal(math.Random(1));
  final readings = {
    for (final t in M5Test.values)
      t: faults.any((f) => f.test == t) ? (t.megger ? '0.1 MΩ' : 'OL') : (t.megger ? '1200 MΩ' : '0.4 Ω'),
  };
  final c = M5CableCase(faults: faults, onEnd: on, needle: false, readings: readings, whyFault: faults.first);
  return M5CableDeal(
    cases: [c, c],
    cwRound: 1,
    cwA2: false,
    pits: base.pits,
    length: base.length,
    faultAt: base.faultAt,
    pitCore: base.pitCore,
    pitLow: base.pitLow,
    pitGood: base.pitGood,
    look: base.look,
  );
}

/// Every test of a run, the right way (megger tests discharged before the clip comes off).
void _allTests(M5CableRun r) {
  r.lift(M5Tool.rod);
  for (final p in M5Pt.near) {
    r.rodOn(p);
  }
  for (final (a, b) in [
    (M5Pt.nearR, M5Pt.nearY),
    (M5Pt.nearY, M5Pt.nearB),
    (M5Pt.nearR, M5Pt.nearB),
    (M5Pt.nearR, M5Pt.armour),
    (M5Pt.nearY, M5Pt.armour),
    (M5Pt.nearB, M5Pt.armour),
  ]) {
    r.lift(M5Tool.megger);
    expect(r.clip(a), isNull);
    expect(r.clip(b), isNull);
    expect(r.holdTest(), isNotNull);
    r.lift(M5Tool.rod);
    expect(r.rodOn(a), isNull);
    expect(r.charged, isFalse);
    expect(r.rodOn(a), isNull, reason: 'the clip comes off');
    expect(r.clipsOn, isFalse);
  }
  r.lift(M5Tool.multi);
  for (var i = 0; i < 3; i++) {
    expect(r.clip(M5Pt.near[i]), isNull);
    expect(r.clip(M5Pt.far[i]), isNull);
    expect(r.unclip(), isNull);
  }
}

void main() {
  group('rules', () {
    test('deal: round 1 single, round 2 double in about half (never on one core, never two earths); ON end ~40 %; plays differ', () {
      final seen = <String>{};
      var doubles = 0, ons = 0;
      for (var s = 0; s < 200; s++) {
        final d = m5CableDeal(math.Random(s));
        expect(d.cases, hasLength(2));
        expect(d.cases[0].faults, hasLength(1));
        expect(d.cases[1].faults.length, inInclusiveRange(1, 2));
        if (d.cases[1].faults.length == 2) {
          doubles++;
          final [a, b] = d.cases[1].faults.toList();
          expect(m5DoubleOk(a, b), isTrue, reason: '$a $b');
        }
        for (final c in d.cases) {
          if (c.onEnd != null) ons++;
          expect(c.faults, contains(c.whyFault));
          for (final t in M5Test.values) {
            final low = c.low(t);
            final r = c.readings[t]!;
            if (t.megger) {
              expect((low ? M5CableLines.meggerLow : M5CableLines.meggerGood).contains(r), isTrue, reason: '$t $r');
            } else {
              expect(r == M5CableLines.ohmOpen, low, reason: '$t $r');
            }
          }
        }
        expect(d.cwRound, inInclusiveRange(0, 1));
        seen.add('${d.cases.map((c) => '${c.faults.map((f) => f.name).join('+')}/${c.onEnd}').join('|')}|${d.cwRound}${d.cwA2}');
      }
      expect(doubles, inInclusiveRange(70, 130));
      expect(ons / 400, inInclusiveRange(0.3, 0.5));
      expect(seen.length, greaterThan(150));
      // Every single fault turns up in round 1.
      final singles = {for (var s = 0; s < 400; s++) m5CableDeal(math.Random(s)).cases[0].faults.single};
      expect(singles, M5Fault.values.toSet());
    });

    test('deal: 3 or 5 uneven pits, one clearly nearest the middle, the fault clear of it; chainage varies', () {
      final lengths = <int>{};
      final counts = <int>{};
      for (var s = 0; s < 150; s++) {
        final d = m5CableDeal(math.Random(s));
        counts.add(d.pits.length);
        lengths.add(d.length);
        expect(d.pits, orderedEquals([...d.pits]..sort()));
        for (final p in d.pits) {
          expect(p, inExclusiveRange(0, d.length));
          expect(p % 10, 0);
        }
        final dist = [for (final p in d.pits) (p * 2 - d.length).abs()]..sort();
        expect(dist[1] - dist[0], greaterThanOrEqualTo(d.length * 0.12));
        expect((d.faultAt - d.pits[d.rightPit]).abs(), greaterThanOrEqualTo(d.length * 0.1));
        expect(d.faultLeft, d.faultAt < d.pits[d.rightPit]);
        final gaps = [d.pits.first, for (var i = 1; i < d.pits.length; i++) d.pits[i] - d.pits[i - 1], d.length - d.pits.last]..sort();
        expect(gaps.last - gaps.first, greaterThanOrEqualTo(d.length * 0.06), reason: 'uneven: $gaps');
      }
      expect(counts, {3, 5});
      expect(lengths.length, greaterThan(40));
    });

    test('isolation: OFF → hasp → tag, at both ends; a lead with an end ON is deadly; OFF but not locked/tagged is a slip', () {
      final on = M5CableRun(_dealWith({M5Fault.earthY}, on: M5End.far));
      expect(on.isolated, isFalse);
      on.lift(M5Tool.megger);
      final m = on.clip(M5Pt.nearR);
      expect(m, M5CableMistakes.liveLead);
      expect(m!.deadly, isTrue);
      expect(on.ended, isTrue);

      // The earthed rod on a core with an end ON: a live core shorted to earth.
      final rod = M5CableRun(_dealWith({M5Fault.earthY}, on: M5End.far));
      rod.lift(M5Tool.rod);
      expect(rod.rodOn(M5Pt.armour), M5CableMistakes.isolateFirst, reason: 'the rod on the armour is no short');
      expect(rod.ended, isFalse);
      final rm = rod.rodOn(M5Pt.farB);
      expect(rm, M5CableMistakes.liveRod);
      expect(rm!.deadly, isTrue);
      expect(rod.ended, isTrue);

      final r = M5CableRun(_dealWith({M5Fault.earthY}, on: M5End.near));
      expect(r.lock(M5End.near), isFalse, reason: 'the hasp will not close over ON');
      expect(r.hangTag(M5End.near), isFalse, reason: 'no tag before the lock');
      expect(r.switchOff(M5End.near), isTrue);
      expect(r.switchOff(M5End.far), isFalse, reason: 'already OFF');
      expect(r.lock(M5End.near), isTrue);
      expect(r.hangTag(M5End.near), isTrue);
      r.lift(M5Tool.megger);
      expect(r.clip(M5Pt.nearR), M5CableMistakes.isolateFirst, reason: 'the far end not locked and tagged');
      r.lift(M5Tool.rod);
      expect(r.rodOn(M5Pt.nearR), M5CableMistakes.isolateFirst, reason: 'all OFF, the far end not locked: a slip');
      expect(r.ended, isFalse);
      r.lock(M5End.far);
      r.hangTag(M5End.far);
      expect(r.isolated, isTrue);
      expect(r.caught, contains(M5CableLines.caughtIso));
      expect(r.slips, 2);
    });

    test('discharge before the first lead (R25 = slip); the clip is not placed', () {
      final r = _isolatedRun(_dealWith({M5Fault.openB}));
      r.lift(M5Tool.megger);
      expect(r.clip(M5Pt.nearR), M5CableMistakes.dischargeFirst);
      expect(r.clipsOn, isFalse);
      expect(r.clip(M5Pt.armour), isNull, reason: 'the armour needs no discharge');
      r.unclip();
      r.lift(M5Tool.rod);
      r.rodOn(M5Pt.nearR);
      r.lift(M5Tool.megger);
      expect(r.clip(M5Pt.nearR), isNull);
      expect(r.slips, 1);
    });

    test('wrong pairs are slips: multimeter on insulation, megger across one core, L and E swapped', () {
      final r = _isolatedRun(_dealWith({M5Fault.shortRY}));
      r.lift(M5Tool.rod);
      for (final p in M5Pt.near) {
        r.rodOn(p);
      }
      r.lift(M5Tool.multi);
      r.clip(M5Pt.nearR);
      expect(r.clip(M5Pt.nearY), M5CableMistakes.multiOnIns);
      expect(r.clipsOn, isFalse);
      r.clip(M5Pt.nearR);
      expect(r.clip(M5Pt.armour), M5CableMistakes.multiOnIns);
      r.lift(M5Tool.megger);
      r.clip(M5Pt.nearR);
      expect(r.clip(M5Pt.farR), M5CableMistakes.meggerOneCore);
      r.clip(M5Pt.armour);
      expect(r.clip(M5Pt.nearB), M5CableMistakes.swapped);
      expect(r.slips, 4);
      expect(r.rows, isEmpty);
    });

    test('a clip off a charged cable is deadly (R24); the rod first, then it comes off; another instrument waits', () {
      final r = _isolatedRun(_dealWith({M5Fault.earthR}));
      r.lift(M5Tool.rod);
      r.rodOn(M5Pt.nearR);
      r.lift(M5Tool.megger);
      r.clip(M5Pt.nearR);
      r.clip(M5Pt.armour);
      expect(r.ready, isTrue);
      final read = r.holdTest()!;
      expect(read.low, isTrue);
      expect(read.row.reading, '0.1 MΩ');
      expect(r.rows.single.text, contains('R–E'));
      expect(r.charged, isTrue);
      expect(r.lift(M5Tool.multi), isFalse, reason: 'the megger leads are on');
      expect(r.unclip(), M5CableMistakes.chargedClip);
      expect(r.ended, isTrue);

      final ok = _isolatedRun(_dealWith({M5Fault.earthR}));
      ok.lift(M5Tool.rod);
      ok.rodOn(M5Pt.nearR);
      ok.lift(M5Tool.megger);
      ok.clip(M5Pt.nearR);
      ok.clip(M5Pt.armour);
      ok.holdTest();
      ok.lift(M5Tool.rod);
      expect(ok.rodOn(M5Pt.armour), isNull, reason: 'the rod on the armour takes no charge off');
      expect(ok.charged, isTrue);
      expect(ok.rodOn(M5Pt.nearR), isNull);
      expect(ok.charged, isFalse);
      expect(ok.caught, contains(M5CableLines.caughtDischarge));
      expect(ok.rodOn(M5Pt.nearR), isNull);
      expect(ok.clipsOn, isFalse);
      expect(ok.hand, M5Tool.megger, reason: 'the megger back in hand');
      expect(ok.ended, isFalse);
    });

    test('verdict: evidence-gated (tests missing = slip even when right); wrong or half a double = slip; right ends the round', () {
      final r = _isolatedRun(_dealWith({M5Fault.shortYB, M5Fault.openR}));
      expect(r.verdict({M5Fault.shortYB, M5Fault.openR}), M5CableMistakes.testsMissing);
      _allTests(r);
      expect(r.done, M5Test.values.toSet());
      expect(r.rows, hasLength(9));
      expect(r.rows.where((x) => x.reading == '0.1 MΩ' || x.reading == 'OL'), hasLength(2));
      expect(r.verdict({M5Fault.shortYB}), M5CableMistakes.wrongVerdict, reason: 'half a double fault');
      expect(r.verdict({M5Fault.shortRY, M5Fault.openR}), M5CableMistakes.wrongVerdict);
      expect(r.verdict({M5Fault.shortYB, M5Fault.openR}), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5CableLines.caughtDouble));
      expect(r.caught, isNot(contains(M5CableLines.caughtType)), reason: 'not thorough');
      expect(r.slips, 3);
    });

    test('the coworker A2: a low reading waits for him before its row is written', () {
      final r = _isolatedRun(_dealWith({M5Fault.earthB}));
      r.holdLowRow = true;
      r.lift(M5Tool.rod);
      for (final p in M5Pt.near) {
        r.rodOn(p);
      }
      r.lift(M5Tool.megger);
      r.clip(M5Pt.nearR);
      r.clip(M5Pt.nearY);
      r.holdTest();
      expect(r.rowPending, isNull, reason: 'a good reading is written at once');
      expect(r.rows, hasLength(1));
      r.lift(M5Tool.rod);
      r.rodOn(M5Pt.nearR);
      r.rodOn(M5Pt.nearR);
      r.lift(M5Tool.megger);
      r.clip(M5Pt.nearB);
      r.clip(M5Pt.armour);
      r.holdTest();
      expect(r.rowPending, isNotNull);
      expect(r.rows, hasLength(1));
      r.writePending();
      expect(r.rows, hasLength(2));
      expect(r.rows.last.text, contains('B–E'));
    });

    test('the coworker A2 never waits on a silent multimeter (OL is not "কম"); dealt only where the megger reads low', () {
      final r = _isolatedRun(_dealWith({M5Fault.openY, M5Fault.shortRB}));
      r.holdLowRow = true;
      r.lift(M5Tool.rod);
      r.rodOn(M5Pt.nearY);
      r.lift(M5Tool.multi);
      expect(r.clip(M5Pt.nearY), isNull);
      final read = r.clip(M5Pt.farY);
      expect(read, isNull);
      expect(r.last!.low, isTrue);
      expect(r.last!.row.reading, M5CableLines.ohmOpen);
      expect(r.rowPending, isNull, reason: 'an OL row is written at once');
      expect(r.holdLowRow, isTrue, reason: 'he still waits for a low megger reading');
      expect(r.rows.single.reading, M5CableLines.ohmOpen);
      expect(M5CableLines.coworkerA2.line, contains('কম'));
      var a2 = 0;
      for (var s = 0; s < 400; s++) {
        final d = m5CableDeal(math.Random(s));
        if (!d.cwA2) continue;
        a2++;
        expect(m5MeggerLow(d.cases[d.cwRound]), isTrue, reason: 'seed $s: ${d.cases[d.cwRound].faults}');
      }
      expect(a2, greaterThan(120), reason: 'A2 still comes in about half the plays');
    });

    test('the pit: the one nearest the middle; both sides measured before the half; the low half', () {
      final d = m5CableDeal(math.Random(3));
      final r = M5CableRun(d)
        ..next()
        ..next();
      expect(r.round, M5CableRound.pit);
      expect(r.rows.single.text, contains('${m5CoreName(d.pitCore)}–E'));
      final wrong = [for (var i = 0; i < d.pits.length; i++) i].firstWhere((i) => i != d.rightPit);
      expect(r.openPit(wrong), M5CableMistakes.wrongPit);
      expect(r.openPit(d.rightPit), isNull);
      expect(r.tapHalf(d.faultLeft), M5CableMistakes.halfUntested);
      for (final left in [true, false]) {
        final core = (left ? M5Pt.pitL : M5Pt.pitR)[d.pitCore.index];
        r.lift(M5Tool.rod);
        expect(r.rodOn(core), isNull);
        r.lift(M5Tool.megger);
        expect(r.clip(core), isNull);
        r.clip(M5Pt.pitE);
        final read = r.holdTest()!;
        expect(read.low, left == d.faultLeft);
        r.lift(M5Tool.rod);
        r.rodOn(core);
        r.rodOn(core);
      }
      expect(r.pitSides, {true, false});
      expect(r.tapHalf(!d.faultLeft), M5CableMistakes.wrongHalf);
      expect(r.tapHalf(d.faultLeft), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5CableLines.caughtPit));
      r.next();
      expect(r.done3, isTrue);
      expect(r.slips, 3);
      expect(r.passed, isTrue, reason: '3 slips = 55 %');
    });

    test('the pit: each split section discharged before its first lead (R25, as in the room)', () {
      final d = m5CableDeal(math.Random(4));
      final r = M5CableRun(d)
        ..next()
        ..next();
      r.openPit(d.rightPit);
      final left = M5Pt.pitL[d.pitCore.index], right = M5Pt.pitR[d.pitCore.index];
      r.lift(M5Tool.megger);
      expect(r.clip(left), M5CableMistakes.dischargeFirst);
      expect(r.clipsOn, isFalse);
      r.lift(M5Tool.rod);
      r.rodOn(left);
      r.lift(M5Tool.megger);
      expect(r.clip(left), isNull);
      r.unclip();
      expect(r.clip(right), M5CableMistakes.dischargeFirst, reason: 'the other section has its own charge');
      expect(r.clip(M5Pt.pitE), isNull, reason: 'the earth bond needs no discharge');
      expect(r.slips, 2);
    });

    test('English digits only; every mistake has its picture; three deadly; keys unique', () {
      final all = <String>[
        M5CableLines.intro,
        ...M5CableLines.tasks,
        M5CableLines.cable2,
        M5CableLines.pitIntro,
        ...M5CableLines.rounds,
        ...M5CableLines.allWhyRight,
        ...M5CableLines.myths,
        for (final s in [M5CableLines.coworkerA1, M5CableLines.coworkerA2]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in M5CableMistakes.all) m.textBn,
        for (final f in M5Fault.values) M5CableLines.chipLabel(f),
        M5CableLines.allSet,
        M5CableLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5CableMistakes.all.where((m) => m.deadly).toSet(), {M5CableMistakes.liveLead, M5CableMistakes.liveRod, M5CableMistakes.chargedClip});
      expect(M5CableMistakes.all.map((m) => m.key).toSet(), hasLength(M5CableMistakes.all.length));
      final dir = Directory('assets/game/art/m5_cable_fault_type');
      final used = <String>{};
      for (final m in M5CableMistakes.all) {
        expect(m.key, startsWith('5.9/m5_cable_fault_type/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        used.add(m.art.split('/').last);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(dir.listSync().map((f) => f.path.replaceAll('\\', '/').split('/').last).toSet(), used, reason: 'no unused art');
      expect(m5CableFaultTypePacks.keys, ['do_5_9_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; his exit line is recorded', () {
      expectSameLength('why', [...M5CableLines.allWhyRight, ...M5CableLines.myths]);
      expect(M5CableLines.myths.toSet().intersection(M5CableLines.allWhyRight.toSet()), isEmpty);
      final sets = [M5CableLines.isoWhy, M5CableLines.dischargeWhy, ...M5CableLines.kindWhy.values, M5CableLines.pitWhy];
      for (final right in sets) {
        expectLibrary(right.first, right, M5CableLines.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M5CableLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final k in M5Kind.values) {
        expect(M5CableLines.kindWhyQ[k], isNotEmpty);
      }
      for (final cw in [M5CableLines.coworkerA1, M5CableLines.coworkerA2]) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(cw.asks, isNotEmpty);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: 'his exit line has its clip');
      }
    });

    test('rival lines: the two new pushes (listed for recording), dealt in single and double plays alike', () {
      expect(M5CableLines.coworkerA1.line, 'টাইপ-ফাইপ জেনে কী হবে? চলো, সোজা মাঠে গিয়ে খুঁড়ি!');
      expect(M5CableLines.coworkerA2.line, 'একটাতেই তো কম পেয়েছ — বাকি জোড়া মাপার দরকার নেই, রায় দিয়ে দাও!');
      final a2 = <String>{};
      for (var s = 0; s < 300; s++) {
        final d = m5CableDeal(math.Random(s));
        if (d.cwA2) a2.add('${d.cwRound}/${d.cases[d.cwRound].faults.length}');
        expect(m5CableCoworker(d), d.cwA2 ? M5CableLines.coworkerA2 : M5CableLines.coworkerA1);
      }
      expect(a2, containsAll(['0/1', '1/1', '1/2']));
    });

    test('tap areas: on each screen none overlap, all inside, below the notebook, above the meter', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M5CableGeo.forScene(h, 0);
        final near = [for (final p in M5CableGeo.nearPts) g.hit(p), for (final f in [g.leverHit, g.haspHit, g.tagHit]) f(M5End.near)];
        final far = [for (final p in M5CableGeo.farPts) g.hit(p).shift(const Offset(-360, 0)), for (final f in [g.leverHit, g.haspHit, g.tagHit]) f(M5End.far).shift(const Offset(-360, 0))];
        final pit = [for (final p in M5CableGeo.pitPts) g.hit(p)];
        for (final rects in [near, far, pit]) {
          for (final r in rects) {
            expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h $r');
            expect(r.right, lessThanOrEqualTo(360), reason: 'h $h $r');
            expect(r.top, greaterThan(180), reason: 'h $h: below the notebook');
            expect(r.bottom, lessThan(g.meter.top), reason: 'h $h: above the meter');
          }
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              final x = rects[i].intersect(rects[j]);
              expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
            }
          }
        }
        for (var s = 0; s < 40; s++) {
          final d = m5CableDeal(math.Random(s));
          final hits = [for (final c in d.pits) g.pitHit(c, d.length)];
          for (var i = 1; i < hits.length; i++) {
            expect(hits[i].left, greaterThanOrEqualTo(hits[i - 1].right - 2), reason: 'pits apart: ${d.pits}');
          }
          for (final r in hits) {
            expect(r.top, greaterThan(180));
            expect(r.bottom, lessThan(g.pitPanel.top));
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

    testWidgets('the guide comes first: a tap does not skip him; then the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5CableFaultTypePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5CableLines.megger), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5CableLines.megger), findsOneWidget);
      expect(_label(M5CableLines.verdict), findsOneWidget, reason: 'the verdict is always there');
      expect(_label(M5CableLines.farEnd), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M5CableLines.askIsolate)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final a2 in [false, true]) {
      testWidgets('flow (coworker ${a2 ? 'A2' : 'A1'}): isolate, discharge, nine tests, verdicts, pit; right reasons → pass', (t) async {
        final seed = _seed((d) => d.cwA2 == a2 && d.cases.any((c) => c.onEnd != null) && (!a2 || d.cwRound == 1));
        final deal = m5CableDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _cableRound(t, deal, 0);
        await _cableRound(t, deal, 1);
        await _pitRound(t, deal);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.mistakes, isEmpty);
        expect(s.rungProgress['5.9/do/0'], 'cleared');
        expect(s.starsByRung['5.9/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5CableLines.caughtCall), findsOneWidget);
        expect(find.text(M5CableLines.caughtPit), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (a lead before the discharge) shows its card; the same round goes on after it', (t) async {
      final seed = _seed((d) => d.cases[0].onEnd == null && d.cwRound == 1);
      final c = await _open(t, seed);
      final room = _Room(t);
      final cc = m5CableDeal(math.Random(seed)).cases[0];
      await room.isolateHere(M5End.near, cc);
      await room.pan(1);
      await room.isolateHere(M5End.far, cc);
      await _reason(t, M5CableLines.isoWhy, after: 1200);
      await room.pan(0);
      await room.tool(M5Tool.megger);
      await room.pt(M5Pt.nearR);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5CableMistakes.dischargeFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M5CableLines.rod), findsOneWidget, reason: 'the same round');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CableMistakes.dischargeFirst.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seed((d) => d.cases[0].onEnd == null);
      final c = await _open(t, seed);
      final room = _Room(t);
      await room.tool(M5Tool.megger);
      for (var i = 0; i < 3; i++) {
        await room.pt(M5Pt.nearR);
        await _pump(t, 600);
        if (i < 2) {
          expect(find.text(M5CableMistakes.isolateFirst.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a lead on a core with an end ON: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seed((d) => d.cases[0].onEnd == M5End.far);
      final c = await _open(t, seed);
      final room = _Room(t);
      await room.tool(M5Tool.multi);
      await room.pt(M5Pt.nearY);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5CableMistakes.liveLead.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the earthed rod on a core with an end ON: freeze, then the card (deadly, not a slip)', (t) async {
      final seed = _seed((d) => d.cases[0].onEnd == M5End.near);
      final c = await _open(t, seed);
      final room = _Room(t);
      await room.tool(M5Tool.rod);
      await room.pt(M5Pt.nearR);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5CableMistakes.isolateFirst.textBn), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5CableMistakes.liveRod.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a clip off the charged cable after TEST: freeze, then the card', (t) async {
      final seed = _seed((d) => d.cases[0].onEnd == null && d.cwRound == 1);
      final cc = m5CableDeal(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      final room = _Room(t);
      await room.isolateHere(M5End.near, cc);
      await room.pan(1);
      await room.isolateHere(M5End.far, cc);
      await _reason(t, M5CableLines.isoWhy, after: 1200);
      await room.pan(0);
      await room.tool(M5Tool.rod);
      await room.pt(M5Pt.nearR);
      await room.pt(M5Pt.nearY);
      await room.tool(M5Tool.megger);
      await room.pt(M5Pt.nearR);
      await room.pt(M5Pt.nearY);
      await room.test();
      await room.pt(M5Pt.nearY);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CableMistakes.chargedClip.key);
      await _close(t, c);
    });

    testWidgets('A1: the first control after the isolation waits for him; listening to him is a slip', (t) async {
      final seed = _seed((d) => d.cwRound == 0 && !d.cwA2);
      final cc = m5CableDeal(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      final room = _Room(t);
      await room.isolateHere(M5End.near, cc);
      await room.pan(1);
      await room.isolateHere(M5End.far, cc);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, M5CableLines.isoWhy);
      await t.pump(const Duration(milliseconds: 200));
      // At once, inside his 0.9 s retry: the tool waits, he cuts in.
      await t.tap(_label(M5CableLines.rod));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.byKey(const ValueKey('meter-rod')), findsNothing, reason: 'the rod waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5CableLines.coworkerA1.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.text(M5CableMistakes.listenA1.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CableMistakes.listenA1.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: a swipe to the far end, a sweep over the tools, a lead nudge; none after TEST', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seed((d) => d.cases[0].onEnd == null && d.cwRound == 1);
      final cc = m5CableDeal(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle before the far end was seen');
      expect(scene().debugFrame?.trailFrom, isNotNull, reason: 'a swipe');
      final room = _Room(t);
      await room.isolateHere(M5End.near, cc);
      await room.pan(1);
      await room.isolateHere(M5End.far, cc);
      await _reason(t, M5CableLines.isoWhy, after: 1200);
      await room.pan(0);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'nothing in hand');
      expect(scene().debugOptions, hasLength(4), reason: 'every tool and the verdict alike');
      await room.tool(M5Tool.rod);
      await room.pt(M5Pt.nearR);
      await room.pt(M5Pt.nearB);
      await room.tool(M5Tool.megger);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'the megger up');
      expect(scene().debugFrame?.ripple, isNull);
      await room.pt(M5Pt.nearR);
      await room.pt(M5Pt.nearB);
      await room.test();
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'no hint after TEST: taking the clip off is the test');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
