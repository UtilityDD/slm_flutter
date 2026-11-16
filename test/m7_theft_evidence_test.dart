// Lesson 7.5 (বিদ্যুৎ চুরি), কাজ 2 "দূর থেকে প্রমাণ": the rules (a photo is
// judged only when the report is sent: the hook legible, the wire's entry
// into the stealing house, a wide or soft shot, a neighbour's meter, nothing,
// the same proof twice; the walk up to the thief; phase 2's order → শাটডাউন →
// tester live-dead-live → earth → PPE → hook with the module 7 classes:
// R13/N1/N2 deadly, R14/N3/N4/R15/R16 slips, the গ্লাভস a slip once proven
// dead and earthed per the M7-2 row), the deal, the libraries, the coworker's
// lines, and the level in the shell: the guide first, full clean plays (a
// reason after the report and every phase-2 step, each coworker push
// refused), a wrong-evidence slip that empties the slots, the walk-up slip,
// three slips, the deadly freeze (a hand on the live hook, and listening to
// push (ii)), listening to myth 1 = a slip, real drags (the frame, the zoom
// rail, a photo into a slot, the trainee's walk) and the gesture hand.
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
import 'package:slm_flutter/features/game/m7_theft_evidence.dart';
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
  rungId: '7.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7TheftPacks['do_7_5_b']!;
typedef L = M7TheftLines;
typedef Mk = M7TheftMistakes;

/// The new art is not in the bundle in tests until the director wires it.
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

/// The lesson writes য় ড় ঢ় as single code points; the game as base + nukta.
String _nk(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

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

Future<bool> _pumpUntilTrue(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
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

M7TheftProbe get _probe => M7TheftProbe.current!;

Future<ProviderContainer> _open(WidgetTester t, int seed, {Size size = const Size(392, 850), double top = 0}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2.0;
  t.view.padding = FakeViewPadding(top: top * 2);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7TheftEvidencePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7TheftDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m7TheftDeal(math.Random(s))));

/// He comes: refuse him.
Future<void> _refuse(WidgetTester t, M7Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// He comes: listen to him (a wrong card, ✓).
Future<void> _listen(WidgetTester t, M7Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  final wrong = _onScreen(L.coworker(p).wrong);
  expect(wrong, isNotEmpty);
  await t.tap(wrong.first, warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 800);
}

Future<void> _shoot(WidgetTester t) async {
  await t.tap(_label(L.shutter));
  await _pump(t, 400);
}

/// The two right photos into the slots (not sent).
Future<void> _twoProofs(WidgetTester t, M7TheftDeal d) async {
  final g = _probe.lane!;
  _probe.aimAt(g.hook(d.thief).center, m7HookZoom);
  await _pump(t, 200);
  await _shoot(t);
  _probe.aimAt(g.entry(d.thief).center, m7EntryZoom);
  await _pump(t, 200);
  await _shoot(t);
  final roll = _probe.run.roll;
  _probe.place(roll[roll.length - 2].id, 0);
  _probe.place(roll.last.id, 1);
  await _pump(t, 300);
}

/// Phase 1 played right (myth 1 refused if he is dealt), the report's reason,
/// then the morning.
Future<void> _playEvidence(WidgetTester t, M7TheftDeal d) async {
  await _twoProofs(t, d);
  await t.tap(_label(L.send));
  await _pump(t, 300);
  if (d.push == M7Push.myth) {
    await _refuse(t, M7Push.myth);
    expect(_probe.run.reportSent, isFalse, reason: 'the send waited for him');
    await t.tap(_label(L.send));
    await _pump(t, 300);
  }
  expect(_probe.run.reportSent, isTrue);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the report\'s reason');
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[d.reportWhy]!);
  await _pump(t, 3000);
  expect(_probe.run.phase, M7Phase.removal);
}

Future<void> _why(WidgetTester t, M7Why w) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason $w');
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1500);
}

M7LaneGeo get _geo780 => M7LaneGeo.forScene(360 * 850 / 392, 0);

M7TheftDeal _deal({M7Push push = M7Push.myth, int thief = 2}) => M7TheftDeal(
      lane: M7LaneLook(thief: thief),
      layout: M7Spot.values,
      constable: false,
      push: push,
      reportWhy: M7Why.far,
      hookWhy: M7Why.ppe,
    );

void main() {
  group('rules', () {
    test('deals: the stealing house never beside the trainee; every look, layout, push and reason topic comes; plays differ', () {
      final seen = <String>{};
      final pushes = <M7Push>{}, vantages = <M7Vantage>{}, lines = <M7LineKind>{}, methods = <M7Method>{}, owners = <M7Owner>{}, lights = <M7Light>{};
      final thieves = <int>{}, reportWhys = <M7Why>{}, hookWhys = <M7Why>{}, firstSpots = <M7Spot>{};
      var constables = 0;
      for (var s = 0; s < 400; s++) {
        final d = m7TheftDeal(math.Random(s));
        final v = d.lane.vantage;
        expect((M7LaneGeo.houseCx[d.thief] - M7LaneGeo.vantageX(v)).abs(), greaterThan(M7LaneGeo.zoneR), reason: 'he does not start in the zone');
        expect(m7ThievesFor(v), contains(d.thief));
        expect(d.layout.toSet(), M7Spot.values.toSet());
        expect(d.layout, hasLength(5));
        expect({M7Why.far, M7Why.evidence}, contains(d.reportWhy));
        expect({M7Why.ppe, M7Why.order}, contains(d.hookWhy));
        pushes.add(d.push);
        vantages.add(v);
        lines.add(d.lane.line);
        methods.add(d.lane.method);
        owners.add(d.lane.owner);
        lights.add(d.lane.light);
        thieves.add(d.thief);
        reportWhys.add(d.reportWhy);
        hookWhys.add(d.hookWhy);
        firstSpots.add(d.layout.first);
        if (d.constable) constables++;
        seen.add('${d.thief}${v.name}${d.lane.line.name}${d.lane.method.name}${d.lane.owner.name}${d.lane.light.name}|${d.layout.map((x) => x.index).join()}|${d.constable}${d.push.name}');
      }
      expect(seen.length, greaterThan(350));
      expect(pushes, M7Push.values.toSet());
      expect(vantages, M7Vantage.values.toSet());
      expect(lines, M7LineKind.values.toSet());
      expect(methods, M7Method.values.toSet());
      expect(owners, M7Owner.values.toSet());
      expect(lights, M7Light.values.toSet());
      expect(thieves, {0, 1, 2, 3});
      expect(reportWhys, {M7Why.far, M7Why.evidence});
      expect(hookWhys, {M7Why.ppe, M7Why.order});
      expect(firstSpots, M7Spot.values.toSet(), reason: 'the ground order is dealt');
      expect(constables, inInclusiveRange(120, 280));
      expect(m7ThievesFor(M7Vantage.van), [1, 2, 3]);
      expect(m7ThievesFor(M7Vantage.stall), [0, 1, 3]);
    });

    test('every house: the hook and the entry can each be shot readable; never both in one readable frame; clear of the controls on every phone', () {
      for (var h = 560.0; h <= 900; h += 20) {
        for (final top in [0.0, 24.0]) {
          final g = M7LaneGeo.forScene(h, 0, topInset: top);
          for (var i = 0; i < 4; i++) {
            final hook = g.hook(i), entry = g.entry(i);
            final ch = g.clampCam(M7Cam(hook.center, m7HookZoom));
            expect(m7Classify(ch.frame, ch.zoom, g, i), M7ShotKind.hook, reason: 'h $h top $top house $i hook');
            final ce = g.clampCam(M7Cam(entry.center, m7EntryZoom));
            expect(m7Classify(ce.frame, ce.zoom, g, i), M7ShotKind.entry, reason: 'h $h top $top house $i entry');
            // No readable frame holds both (each photo shows one proof).
            for (final z in [m7EntryZoom, 3.0, 4.0, 5.0]) {
              for (var y = hook.top - 20; y <= entry.bottom + 20; y += 2) {
                final f = M7Cam(Offset(hook.center.dx, y), z).frame;
                expect(m7Coverage(hook, f) >= 0.9 && m7Coverage(entry, f) >= 0.8, isFalse, reason: 'h $h house $i z $z y $y');
              }
            }
            for (final r in [hook, entry, g.meter(i), g.roof(i)]) {
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(310), reason: 'left of the zoom rail');
              expect(r.top, greaterThanOrEqualTo(M7LaneGeo.partsTop + top - 0.01), reason: 'h $h top $top: under the evidence row');
              expect(r.bottom, lessThan(h - 150), reason: 'above the shutter row and the roll');
            }
          }
          for (final v in M7Vantage.values) {
            final tr = g.trainee(M7LaneGeo.vantageX(v));
            expect(tr.bottom, lessThan(h - 150), reason: 'the trainee above the shutter row');
            expect(tr.right, lessThan(244), reason: 'left of the guide');
          }
        }
      }
    });

    test('the judge: a wide shot is unclear; a neighbour\'s meter; the thief\'s own meter and the sky hold no proof', () {
      final g = _geo780;
      const thief = 2;
      final hook = g.hook(thief);
      expect(m7Classify(M7Cam(hook.center, 1).frame, 1, g, thief), M7ShotKind.unclear, reason: 'a wide shot tells nothing');
      expect(m7Classify(M7Cam(hook.center, 2.5).frame, 2.5, g, thief), M7ShotKind.unclear, reason: 'the hook needs 3x');
      expect(m7Classify(M7Cam(g.entry(thief).center, 1.5).frame, 1.5, g, thief), M7ShotKind.unclear);
      expect(m7Classify(M7Cam(g.meter(1).center, 3).frame, 3, g, thief), M7ShotKind.neighbour);
      expect(m7Classify(M7Cam(g.meter(thief).center, 4).frame, 4, g, thief), M7ShotKind.none, reason: 'the theft goes past its meter');
      expect(m7Classify(M7Cam(const Offset(180, 200), 3).frame, 3, g, thief), M7ShotKind.none);
      // The hook half out of the frame is no proof either.
      expect(m7Classify(M7Cam(hook.center.translate(30, 0), 3).frame, 3, g, thief), isNot(M7ShotKind.hook));
    });

    test('phase 1 run: the roll keeps 5; slots; a bad slot is a slip and empties; the same proof twice; the walk-up; then the report', () {
      final g = _geo780;
      final r = M7TheftRun(_deal());
      final wide = r.shoot(M7Cam(g.hook(2).center, 1).frame, 1, g)!;
      final neighbour = r.shoot(M7Cam(g.meter(1).center, 3).frame, 3, g)!;
      expect(wide.kind, M7ShotKind.unclear);
      expect(neighbour.kind, M7ShotKind.neighbour);
      expect(r.send(), isNull, reason: 'nothing to send with the slots empty');
      expect(r.place(wide.id, 0), isTrue);
      expect(r.place(neighbour.id, 1), isTrue);
      expect(r.send(), Mk.shotUnclear, reason: 'the first bad slot');
      expect(r.slips, 1);
      expect(r.slots, [null, null], reason: 'every bad slot empties');
      final hook = r.shoot(M7Cam(g.hook(2).center, 3).frame, 3, g)!;
      final hook2 = r.shoot(M7Cam(g.hook(2).center, 4).frame, 4, g)!;
      r.place(hook.id, 0);
      r.place(hook2.id, 1);
      expect(r.send(), Mk.shotSame);
      expect(r.slots[0]?.id, hook.id);
      expect(r.slots[1], isNull);
      // A photo placed twice moves.
      r.place(hook.id, 1);
      expect(r.slots, [null, isNotNull]);
      expect(r.confront(), Mk.confront);
      expect(r.slips, 3);
      for (var k = 0; k < 4; k++) {
        r.shoot(M7Cam(const Offset(180, 200), 2).frame, 2, g);
      }
      expect(r.roll, hasLength(M7TheftRun.rollMax));
      expect(r.roll.any((s) => s.id == hook.id), isTrue, reason: 'a photo in a slot never drops out');
      final entry = r.shoot(M7Cam(g.entry(2).center, 2.5).frame, 2.5, g)!;
      r.place(entry.id, 0);
      expect(r.send(), isNull);
      expect(r.reportSent, isTrue);
      expect(r.caught, containsAll([L.caughtEvidence, L.caughtFar]));
      expect(r.shoot(M7Cam(g.hook(2).center, 3).frame, 3, g), isNull, reason: 'the camera is done');
      expect(r.confront(), isNull);
    });

    test('phase 2 run: R13 / N1 / N2 deadly; N4, N3, R14 and the গ্লাভস (M7-2 after the proven isolation) slips; the clean order', () {
      final r = M7TheftRun(_deal())
        ..reportSent = true
        ..startRemoval();
      expect(r.phase, M7Phase.removal);
      expect(r.grabHook(), Mk.hookLive);
      expect(r.slips, 0, reason: 'a deadly is no strike');
      expect(r.test(M7TestAt.line).reading, 'LIVE', reason: 'testing the live line is no mistake');
      expect(r.placeEarth(), Mk.earthEarly);
      expect(r.callShutdown(), isTrue);
      expect(r.callShutdown(), isFalse);
      expect(r.grabHook(), Mk.hookUnproven);
      final unproved = r.test(M7TestAt.line);
      expect(unproved.reading, '0 V');
      expect(unproved.mistake, Mk.testerUnproved);
      expect(r.zero, isFalse, reason: 'an unproved tester\'s 0 V does not count');
      expect(r.test(M7TestAt.prover).reading, 'LIVE');
      expect(r.liveBefore, isTrue);
      expect(r.test(M7TestAt.line).mistake, isNull);
      expect(r.zero, isTrue);
      expect(r.placeEarth(), Mk.testerNotRechecked);
      expect(r.grabHook(), Mk.hookNoEarth);
      final again = r.test(M7TestAt.prover);
      expect(again.provenNow, isTrue);
      expect(r.proven, isTrue);
      expect(r.placeEarth(), isNull);
      expect(r.earthed, isTrue);
      expect(r.grabHook(), Mk.hookNoOrder);
      expect(r.takeOrder(), isTrue);
      expect(r.takeOrder(), isFalse);
      expect(r.wear(M7Gear.helmet), isFalse, reason: 'the bag is shut');
      expect(r.openBag(), isTrue);
      expect(r.wear(M7Gear.helmet), isTrue);
      expect(r.grabHook(), Mk.hookNoGloves);
      expect(Mk.hookNoGloves.deadly, isFalse, reason: 'M7-2: a slip once proven dead and earthed');
      r.wear(M7Gear.gloves);
      r.wear(M7Gear.boots);
      expect(r.grabHook(), Mk.hookPpe);
      r.wear(M7Gear.harness);
      expect(r.readyForHook, isTrue);
      expect(r.grabHook(), isNull);
      expect(r.slips, 6);
      expect(r.removeHook(), isTrue);
      expect(r.done, isTrue);
      expect(r.passed, isFalse, reason: 'six slips');
      expect(r.caught, containsAll([L.caughtProof, L.caughtEarth, L.caughtOrder]));
      // A clean run passes.
      final c = M7TheftRun(_deal())
        ..reportSent = true
        ..startRemoval();
      c
        ..takeOrder()
        ..callShutdown()
        ..test(M7TestAt.prover)
        ..test(M7TestAt.line)
        ..test(M7TestAt.prover)
        ..placeEarth()
        ..openBag();
      for (final x in M7Gear.values) {
        c.wear(x);
      }
      expect(c.grabHook(), isNull);
      expect(c.removeHook(), isTrue);
      expect(c.passed, isTrue);
      expect(c.percent, 100);
    });

    test('the coworker: myth 1 a slip, push (ii) deadly (X2/B1); listening fails the run', () {
      expect(Mk.pushMyth.deadly, isFalse);
      expect(Mk.pushHookLive.deadly, isTrue);
      final r = M7TheftRun(_deal(push: M7Push.hook));
      r.failDeadly(Mk.pushHookLive);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
    });

    test('mistakes: the deadly set (= the catalog\'s deadlyRules), keys, pictures, lesson points, the art folder all used', () {
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.hookLive, Mk.pushHookLive, Mk.hookUnproven, Mk.hookNoEarth});
      expect(Mk.deadlyKeys, [
        '7.5/m7_theft_evidence/hook-live',
        '7.5/m7_theft_evidence/push-hook-live',
        '7.5/m7_theft_evidence/hook-unproven',
        '7.5/m7_theft_evidence/hook-no-earth',
      ]);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.5/m7_theft_evidence/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
      }
      const dir = 'assets/game/art/m7_theft_evidence/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m7_theft_evidence').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7TheftPacks.keys, ['do_7_5_b']);
      expect(m7TheftQuickMs, 120000);
    });

    test('Bangla: English digits, জল never পানি, base + nukta, owner terms (ডেড, ON/OFF, no «AB বন্ধ»), গ্লাভস', () {
      final all = <String>[
        L.intro,
        L.introMorning,
        L.taskAim,
        L.taskSlots,
        L.taskSend,
        L.taskRemove,
        L.taskPaper,
        L.taskPhone,
        L.taskGear,
        ...L.tapWhy,
        L.shutter,
        L.zoom,
        L.send,
        L.roll,
        L.slot,
        L.morning,
        L.paperTitle,
        L.paperBody,
        L.paperSign,
        L.paperOk,
        L.phoneWho,
        L.phoneCall,
        L.sceneLabel,
        L.poleLabel,
        ...L.gearName.values,
        for (final w in M7Why.values) L.whyQ(w),
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M7Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtFar,
        L.caughtEvidence,
        L.caughtOrder,
        L.caughtProof,
        L.caughtEarth,
        L.caughtCall,
      ];
      final pani = RegExp(r'(^|[\s,।!?—])পানি');
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(pani.hasMatch(l), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$|।)').hasMatch(l), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(l.contains('গ্লোভস'), isFalse, reason: l);
        expect(l.contains('11 kV গ্লাভস'), isFalse, reason: l);
      }
      // Myth 1 holds «কোম্পানির» (no পানি word inside it).
      expect(L.myth1, contains('কোম্পানির'));
    });

    test('libraries: same length, big enough, no rule marked wrong; the coworker\'s cards alike', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.wrongFor(w));
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.wrongFor(w), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      // Myth 2 of the lesson is a wrong card on "why from afar".
      expect(L.wrongFor(M7Why.far).any((x) => x.contains('পুলিশের কাজ')), isTrue);
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: myth 1 word for word (live lesson 7.5) and the shortcut line; every spoken line listed for recording', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l75 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.5');
      final myths = (((l75['content'] as Map)['myth_buster'] as Map)['myths'] as List).cast<Map>();
      expect(L.myth1, _nk(myths.first['myth'] as String), reason: 'myth 1 word for word');
      expect(L.coworkerMyth.line, startsWith(L.myth1));
      expect(L.coworkerHook.line, 'লাইন বন্ধ করার দরকার নেই, হুকটা টেনে খুলে দাও।');
      // Point 3 of the live lesson backs the far-away photo and the order.
      final spec = _nk(jsonEncode(l75));
      expect(spec, contains('দূর থেকে অবৈধ সংযোগের ছবি'));
      expect(spec, contains('শুধুমাত্র কর্তৃপক্ষের নির্দেশে'));
      expect(spec, contains('টেস্টার দিয়ে ডেড প্রমাণ করা, আর্থ লাগানো'));
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworkerMyth.line, L.coworkerHook.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length));
      // 2 openings + 7 tasks + 7 questions + 2 asks + 2 praises + 2 end lines + 16 mistakes.
      expect(L.newGuideLines, hasLength(38));
      expect(L.newGuideLines, containsAll([for (final m in Mk.all) m.textBn]));
      expect(L.newGuideLines, containsAll([for (final w in M7Why.values) L.whyQ(w)]));
      expect(L.newGuideLines, containsAll([L.intro, L.introMorning, L.askMyth, L.askHook]));
      const shared = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?', 'থামুন!', 'অল্পের জন্য!', 'নিখুঁত আর ঝটপট!'};
      for (final cw in L.allCoworkers) {
        for (final a in cw.asks) {
          expect(L.newGuideLines.contains(a) || shared.contains(a), isTrue, reason: a);
        }
      }
      for (final s in shared) {
        expect(LearnVoice.resolve(s) != null || LearnVoice.resolve(s, rival: true) != null || s == L.quick, isTrue, reason: 'shared line recorded: $s');
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_theft_evidence: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the evidence slots, the roll, the shutter and the zoom rail', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M7TheftEvidencePage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.byKey(const ValueKey('slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('roll')), findsOneWidget);
      expect(_label(L.shutter), findsOneWidget);
      expect(_label(L.zoom), findsOneWidget);
      expect(_label(L.send), findsNothing, reason: 'পাঠান only with both slots full');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.taskAim)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final flowSeeds = [
      _seedWhere((d) => d.push == M7Push.myth && d.reportWhy == M7Why.far && d.hookWhy == M7Why.ppe),
      _seedWhere((d) => d.push == M7Push.hook && d.reportWhy == M7Why.evidence && d.hookWhy == M7Why.order && d.constable),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): two proofs sent, the morning, order → শাটডাউন → live-dead-live → earth → PPE → hook; a reason each step; he is refused → pass', (t) async {
        final d = m7TheftDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _playEvidence(t, d);
        // The order.
        _probe.tapSpot(M7Spot.officer);
        await _pump(t, 300);
        expect(_label(L.paperOk), findsOneWidget);
        expect(find.text(L.paperBody), findsOneWidget);
        await t.tap(_label(L.paperOk));
        await _pump(t, 600);
        expect(_probe.run.orderTaken, isTrue);
        // The call (push (ii) waits for him first).
        _probe.tapSpot(M7Spot.phone);
        await _pump(t, 300);
        if (d.push == M7Push.hook) {
          await t.tap(_label(L.phoneCall));
          await t.pump(const Duration(milliseconds: 100));
          expect(_probe.run.off, isFalse, reason: 'the call waited for him');
          await _refuse(t, M7Push.hook);
        }
        await t.tap(_label(L.phoneCall));
        await _pump(t, 300);
        expect(_probe.run.off, isTrue);
        await _why(t, M7Why.shutdown);
        // The tester: live, the line, live again.
        _probe.test(M7TestAt.prover);
        await _pump(t, 200);
        _probe.test(M7TestAt.line);
        await _pump(t, 200);
        _probe.test(M7TestAt.prover);
        await _pump(t, 200);
        await _why(t, M7Why.tester);
        _probe.earth();
        await _pump(t, 200);
        expect(_probe.run.earthed, isTrue);
        await _why(t, M7Why.earth);
        _probe.tapSpot(M7Spot.bag);
        await _pump(t, 300);
        for (final g in M7Gear.values) {
          _probe.wear(g);
          await _pump(t, 150);
        }
        _probe.pullHook();
        await _pump(t, 300);
        expect(_probe.run.hookOff, isTrue);
        await _why(t, d.hookWhy);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.5/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.5/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtProof), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final mythSeed = _seedWhere((d) => d.push == M7Push.myth);
    final hookSeed = _seedWhere((d) => d.push == M7Push.hook);

    testWidgets('wrong evidence: a neighbour\'s meter and a wide shot sent — a slip card, the slots empty, no report', (t) async {
      final d = m7TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      final g = _probe.lane!;
      final other = [0, 1, 2, 3].firstWhere((i) => i != d.thief);
      _probe.aimAt(g.meter(other).center, 3);
      await _pump(t, 200);
      await _shoot(t);
      _probe.aimAt(g.hook(d.thief).center, 1);
      await _pump(t, 200);
      await _shoot(t);
      expect(find.byType(MistakeCard), findsNothing, reason: 'nothing is judged at the shutter');
      final roll = _probe.run.roll;
      _probe.place(roll[0].id, 0);
      _probe.place(roll[1].id, 1);
      await _pump(t, 300);
      await t.tap(_label(L.send));
      await _pump(t, 600);
      expect(find.text(Mk.shotNeighbour.textBn), findsOneWidget);
      expect(_probe.run.slots, [null, null]);
      expect(_probe.run.reportSent, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.shotNeighbour.key);
      await _close(t, c);
    });

    testWidgets('listening to myth 1 is a slip: its card, no report; then the report goes', (t) async {
      final d = m7TheftDeal(math.Random(mythSeed));
      final c = await _open(t, mythSeed);
      await _twoProofs(t, d);
      await t.tap(_label(L.send));
      await _pump(t, 200);
      await _listen(t, M7Push.myth);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushMyth.textBn), findsOneWidget);
      expect(_probe.run.reportSent, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_label(L.send));
      await _pump(t, 400);
      expect(_probe.run.reportSent, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.pushMyth.key);
      await _close(t, c);
    });

    testWidgets('walking up to the stealing house: the owner comes out, a slip card, the trainee is back at his place; three slips strike out', (t) async {
      final d = m7TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      final home = _probe.traineeX;
      for (var i = 0; i < 3; i++) {
        _probe.walkTo(M7LaneGeo.houseCx[d.thief]);
        await _pump(t, 600);
        if (i < 2) {
          expect(find.text(Mk.confront.textBn), findsOneWidget);
          expect(_probe.traineeX, home);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.first.key, Mk.confront.key);
      await _close(t, c);
    });

    testWidgets('a hand on the hook with the line live = deadly: the scene freezes first, then the card (near-miss)', (t) async {
      final d = m7TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      await _playEvidence(t, d);
      _probe.pullHook();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.hookLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to push (ii) at the শাটডাউন call = deadly (the hook pulled live)', (t) async {
      final d = m7TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      await _playEvidence(t, d);
      _probe.tapSpot(M7Spot.phone);
      await _pump(t, 300);
      await t.tap(_label(L.phoneCall));
      await t.pump(const Duration(milliseconds: 100));
      await _listen(t, M7Push.hook);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.pushHookLive.key);
      await _close(t, c);
    });

    testWidgets('the earth before the 0 V is a slip and comes back; the tester\'s 0 V without a live proof is a slip', (t) async {
      final d = m7TheftDeal(math.Random(mythSeed));
      final c = await _open(t, mythSeed);
      await _playEvidence(t, d);
      _probe.earth();
      await _pump(t, 500);
      expect(find.text(Mk.earthEarly.textBn), findsOneWidget);
      expect(_probe.run.earthed, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      _probe.tapSpot(M7Spot.phone);
      await _pump(t, 300);
      await t.tap(_label(L.phoneCall));
      await _pump(t, 300);
      await _why(t, M7Why.shutdown);
      _probe.test(M7TestAt.line);
      await _pump(t, 500);
      expect(find.text(Mk.testerUnproved.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.earthEarly.key, Mk.testerUnproved.key]);
      await _close(t, c);
    });

    testWidgets('real touches: a scene drag moves the frame; the rail zooms; a photo dragged into a slot; the trainee dragged up the road walks', (t) async {
      final d = m7TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      const k = 392 / 360;
      final before = _probe.cam;
      await t.dragFrom(const Offset(196, 330), const Offset(-40, -30));
      await _pump(t, 200);
      final moved = _probe.cam.center - before.center;
      expect(moved.dx, closeTo(-40 / k, 0.6));
      expect(moved.dy, closeTo(-30 / k, 0.6));
      final z0 = _probe.cam.zoom;
      await t.drag(_label(L.zoom), const Offset(0, -60));
      await _pump(t, 200);
      expect(_probe.cam.zoom, greaterThan(z0 + 0.5));
      await _shoot(t);
      expect(_probe.run.roll, hasLength(1));
      final thumb = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '${L.roll} 1');
      expect(thumb, findsOneWidget);
      final from = t.getCenter(thumb);
      final to = t.getCenter(find.byKey(const ValueKey('slot-1')));
      final gesture = await t.startGesture(from);
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await _pump(t, 300);
      expect(_probe.run.slots[1]?.id, _probe.run.roll.single.id);
      // The walk: drag the trainee toward the stealing house.
      final g = _probe.lane!;
      final s = (392 / 360);
      final tr = g.trainee(_probe.traineeX);
      final sh = 360 * 850 / 392;
      final dy = (850 - sh * s) / 2;
      final start = Offset(tr.center.dx * s, dy + tr.center.dy * s);
      final target = M7LaneGeo.houseCx[d.thief] * s;
      final walk = await t.startGesture(start);
      for (var i = 1; i <= 20; i++) {
        await walk.moveTo(Offset(start.dx + (target - start.dx) * i / 20, start.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await walk.up();
      await _pump(t, 600);
      expect(find.text(Mk.confront.textBn), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle at the camera, a drag nudge (no sweep, no tap); none while a reason deck is up; phase 2 a sweep', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m7TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(await _pumpUntilTrue(t, () => scene().showing, maxMs: 20000), isTrue, reason: 'idle: the frame not moved yet');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a pick');
      expect(scene().debugFrame?.ripple, isNull, reason: 'no tap on anything');
      await _twoProofs(t, d);
      await t.tap(_label(L.send));
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _pickRight(t, L.whyRight[d.reportWhy]!);
      await _pump(t, 3000);
      expect(await _pumpUntilTrue(t, () => scene().showing, maxMs: 20000), isTrue, reason: 'phase 2 idle');
      expect(scene().debugOptions.length, greaterThanOrEqualTo(6), reason: 'a sweep over the five places and the hook alike');
      await _close(t, c);
    });
  });
}
