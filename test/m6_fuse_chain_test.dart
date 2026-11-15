// Lesson 6.3 (ফিউজ: নীরব প্রহরী), কাজ 2 "কোন প্রহরী পড়ল?": the rules (the
// chain falls from the bottom up — chalk every guard that should have fallen
// first, or 'ক্রম ঠিক'; a fuse drawn with its supply on = deadly (R14); the
// meter-board kit-kat without gloves and goggles = deadly (R15); an HRC only
// on a dead, locked, tagged, proved board (X4) with the puller (R16 slip);
// the HG only after LT OFF → AB in one firm stroke → blades → tester
// live-dead-live → earth (M6-2, X1, X3); the supply back on only once every
// suspect is fixed (R33)), the deal, the libraries, the coworker's pushes,
// and the level in the shell: the guide first, full clean plays (reasons and
// the coworker refused), a wrong verdict's card, three slips, the deadly
// freeze (a live draw; listening to him), the next control waits for him,
// and the gesture hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m6_fuse_chain.dart';
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
  rungId: '6.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6FuseChainPacks['do_6_3_b']!;
typedef L = M6ChainLines;
typedef Mk = M6ChainMistakes;

M6Call _house({int phase = 0}) => M6Call(house: 2, phase: phase, fallen: M6Tier.house, kitkat: M6Content.melted, why: M6Why.chainOk);
M6Call _lt({int phase = 1, M6Content kitkat = M6Content.gi}) =>
    M6Call(house: 3, phase: phase, fallen: M6Tier.lt, kitkat: kitkat, hrc: M6Content.blownHrc, why: M6Why.chalk);
M6Call _hg({int phase = 2, int hgPhase = 0}) =>
    M6Call(house: 5, phase: phase, fallen: M6Tier.hg, kitkat: M6Content.aluminium, hrc: M6Content.strip, hgPhase: hgPhase, why: M6Why.hgIsolate);

/// A run whose first call is [first]; PPE on unless [ppe] is false; the
/// reads done and the right verdict given unless [verdict] is false.
M6ChainRun _runOf(M6Call first, {bool ppe = true, bool verdict = true, int kva = 63}) {
  final r = M6ChainRun(M6ChainDeal(calls: [first, _lt(), _house()], kva: kva, coworkerCall: 1, push: M6Push.noBother));
  if (ppe) {
    r.wear(0);
    r.wear(1);
  }
  if (verdict) {
    r.lookHg();
    r.openDoor();
    if (first.chalkSet.isEmpty) {
      r.toggleChainOk();
    } else {
      for (final t in first.chalkSet) {
        r.chalk(t);
      }
    }
    expect(r.commit().ok, isTrue);
  }
  return r;
}

/// The LT made dead the right way: OFF, lock-tag, live-dead-live (the tester
/// proved on the LT box's own supply bar, the same voltage).
void _isolateLt(M6ChainRun r) {
  expect(r.ltLever(false).ok, isTrue);
  expect(r.toggleLockTag(), isTrue);
  expect(r.testLive(M6Point.ltSupply).live, isTrue);
  expect(r.testOn(M6Target.lt).live, isFalse);
  expect(r.testLive(M6Point.ltSupply).live, isTrue);
}

void _fixKitkat(M6ChainRun r) {
  expect(r.mainSwitch(false), isTrue);
  expect(r.drawKitkat().ok, isTrue);
  expect(r.spare(M6Spare.scrap, null).ok, isTrue);
  expect(r.spare(M6Spare.mm050, null).ok, isTrue);
}

void _fixHrc(M6ChainRun r) {
  expect(r.hrcTap(r.call.phase, M6Tool.puller).ok, isTrue);
  expect(r.spare(M6Spare.scrap, M6Tool.puller).ok, isTrue);
  expect(r.spare(M6Spare.hrc, M6Tool.puller).ok, isTrue);
}

/// The HG made dead and earthed the right way (the LT already OFF).
void _isolateHg(M6ChainRun r) {
  expect(r.abStroke(1).ok, isTrue);
  expect(r.lookBlades(), isTrue);
  expect(r.testLive(M6Point.abLine).live, isTrue);
  expect(r.testOn(M6Target.hg).live, isFalse);
  expect(r.testLive(M6Point.abLine).live, isTrue);
  expect(r.earthTap().ok, isTrue);
}

int _seedWhere(bool Function(M6ChainDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6ChainDeal(math.Random(s))));

// --- the page --------------------------------------------------------------------

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
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
M6ChainGeo get _geo => M6ChainGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _dragAt(WidgetTester t, Offset design, Offset by) async {
  await t.dragFrom(design * _k, by * _k);
  await _pump(t, 350);
}

Future<void> _tool(WidgetTester t, M6Tool tool) async {
  await t.tap(_label(L.tool(tool)));
  await _pump(t, 300);
}

Future<void> _spare(WidgetTester t, M6Spare s) async {
  await t.tap(_label(L.spare(s)));
  await _pump(t, 350);
}

Future<void> _ppe(WidgetTester t) async {
  final g = _geo;
  for (var i = 0; i < 2; i++) {
    await _dragAt(t, g.ppeAt(i), g.worker.center - g.ppeAt(i));
  }
}

Future<void> _reads(WidgetTester t) async {
  await _tapAt(t, _geo.hgHit.center);
  await _tapAt(t, _geo.ltBox.center);
}

Future<void> _chalk(WidgetTester t, M6Tier tier) async {
  final from = t.getCenter(find.byKey(const ValueKey('docket-chalk')));
  final to = t.getCenter(find.byKey(ValueKey('tier-${tier.name}')));
  await t.dragFrom(from, to - from);
  await _pump(t, 350);
}

Future<void> _verdict(WidgetTester t, M6Call c) async {
  if (c.chalkSet.isEmpty) {
    await t.tap(_label(L.chainOk));
    await _pump(t, 300);
  } else {
    for (final tier in c.chalkSet) {
      await _chalk(t, tier);
    }
  }
  await t.tap(_label(L.goLook));
  await _pump(t, 500);
}

/// The coworker comes (the held control did nothing): refuse him.
Future<void> _refuse(WidgetTester t, M6Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

Future<void> _mainSwitch(WidgetTester t, bool on) => _dragAt(t, _geo.mainHit.center, Offset(0, on ? -40 : 40));
Future<void> _ltLever(WidgetTester t, bool on) => _dragAt(t, _geo.ltLeverHit.center, Offset(0, on ? -50 : 50));
Future<void> _abStroke(WidgetTester t, bool open) {
  final g = _geo;
  return _dragAt(t, g.knob(open), Offset(0, (open ? 1 : -1) * (g.abTravel + 8)));
}

/// One call played right (the coworker refused if he is dealt on it).
Future<void> _playCall(WidgetTester t, M6ChainDeal d, int i) async {
  final c = d.calls[i];
  final g = _geo;
  await _reads(t);
  await _verdict(t, c);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'verdict ${c.fallen}');
  if (m6WhyAtVerdict(c.why)) {
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
    await _pump(t, 600);
    await _pickRight(t, L.whyRight[c.why]!);
    await _pump(t, 2000);
  }
  // The house's kit-kat (his call: the first touch waits for him).
  await _mainSwitch(t, false);
  if (d.coworkerCall == i) {
    await _refuse(t, d.push);
    await _mainSwitch(t, false);
  }
  await _tapAt(t, g.kitkatHit.center);
  await _spare(t, M6Spare.scrap);
  await _spare(t, M6Spare.mm050);
  if (c.needsLt) {
    await _ltLever(t, false);
    await _tool(t, M6Tool.lockTag);
    await _tapAt(t, g.ltLeverHit.center);
    await _tool(t, M6Tool.tester);
    await _tapAt(t, g.ltSupplyHit.center);
    await _tapAt(t, g.hrcHit(c.phase).center);
    expect(find.text(L.testerDead), findsOneWidget);
    await _tapAt(t, g.ltSupplyHit.center);
    await _tool(t, M6Tool.tester);
    await _tool(t, M6Tool.puller);
    await _tapAt(t, g.hrcHit(c.phase).center);
    await _spare(t, M6Spare.scrap);
    await _spare(t, M6Spare.hrc);
    await _tool(t, M6Tool.puller);
  }
  if (c.needsHg) {
    await _abStroke(t, true);
    await _tapAt(t, g.abBladesHit.center);
    await _tool(t, M6Tool.tester);
    await _tapAt(t, g.abLineHit.center);
    await _tapAt(t, g.hgHit.center);
    await _tapAt(t, g.abLineHit.center);
    await _tool(t, M6Tool.tester);
    await _tool(t, M6Tool.earth);
    await _tapAt(t, g.hgHit.center);
    await _tapAt(t, g.hgHit.center);
    await _spare(t, m6HgSpareFor(d.kva));
    await _tool(t, M6Tool.earth);
    await _tapAt(t, g.hgHit.center);
    await _abStroke(t, false);
  }
  // The LT box door shut before the supply goes back (X4 / M5 N5).
  await _tapAt(t, g.doorHit.center);
  expect(M6FuseChainProbe.run?.doorOpen, isFalse, reason: 'the door shut');
  if (c.needsLt) {
    await _tool(t, M6Tool.lockTag);
    await _tapAt(t, g.ltLeverHit.center);
    await _ltLever(t, true);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'work ${c.fallen}');
  await _mainSwitch(t, true);
  expect(M6FuseChainProbe.run?.stage, M6Stage.done, reason: 'the light back (${c.fallen})');
  if (!m6WhyAtVerdict(c.why)) {
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck at the end');
    await _pump(t, 600);
    await _pickRight(t, L.whyRight[c.why]!);
  }
  await _pump(t, 3000);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6FuseChainPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

void main() {
  group('rules', () {
    test('the deal: three calls, the house and the HG at most once each, contents fit the fallen guard; plays differ', () {
      final seen = <String>{};
      final calls = <int>{};
      final kvas = <int>{};
      final whys = <M6Why>{};
      for (var s = 0; s < 300; s++) {
        final d = m6ChainDeal(math.Random(s));
        expect(d.calls, hasLength(3));
        expect(d.calls.where((c) => c.fallen == M6Tier.house).length, lessThanOrEqualTo(1));
        expect(d.calls.where((c) => c.fallen == M6Tier.hg).length, lessThanOrEqualTo(1));
        expect(d.calls.where((c) => c.chalkSet.isNotEmpty).length, greaterThanOrEqualTo(2), reason: 'broken chains');
        expect(d.calls.map((c) => c.house).toSet(), hasLength(3));
        for (final c in d.calls) {
          expect(c.house, inInclusiveRange(1, 6));
          expect(m6WhysFor(c.fallen), contains(c.why));
          switch (c.fallen) {
            case M6Tier.house:
              expect(c.kitkat, M6Content.melted);
              expect(c.hrc, isNull);
            case M6Tier.lt:
              expect(c.kitkat, isNot(M6Content.melted));
              expect(c.hrc, M6Content.blownHrc);
            case M6Tier.hg:
              expect(c.kitkat, isNot(M6Content.melted));
              expect(c.hrc, anyOf(M6Content.strip, M6Content.thickCopper));
          }
          whys.add(c.why);
        }
        calls.add(d.coworkerCall);
        kvas.add(d.kva);
        seen.add([for (final c in d.calls) '${c.house}${c.phase}${c.fallen.name}${c.kitkat.name}${c.hgPhase}'].join('|'));
      }
      expect(seen.length, greaterThan(250));
      expect(calls, {0, 1, 2});
      expect(kvas, {25, 63, 100});
      expect(whys, M6Why.values.toSet());
    });

    test('the verdict: the right chalk per fallen guard; reads first; a wrong one is a slip and the docket shows the right chalk', () {
      for (final c in [_house(), _lt(), _hg()]) {
        expect(_runOf(c).verdictRight, isTrue, reason: '${c.fallen}');
      }
      // Reads first, a mark first: nudges, no cost.
      final r = _runOf(_lt(), verdict: false);
      expect(r.commit().say, L.readFirst);
      r.lookHg();
      r.openDoor();
      expect(r.commit().say, L.markFirst);
      expect(r.slips, 0);
      // 'ক্রম ঠিক' on a broken chain.
      r.toggleChainOk();
      expect(r.commit().m, Mk.chainWrong);
      expect(r.slips, 1);
      expect(r.stage, M6Stage.work);
      expect(r.marks, {M6Tier.house});
      expect(r.chainOk, isFalse);
      // A needless chalk (the HG; the LT box on a house fall).
      final h = _runOf(_hg(), verdict: false)
        ..lookHg()
        ..openDoor()
        ..chalk(M6Tier.house)
        ..chalk(M6Tier.lt)
        ..chalk(M6Tier.hg);
      expect(h.commit().m, Mk.needlessChalk);
      expect(h.marks, {M6Tier.house, M6Tier.lt});
      final o = _runOf(_house(), verdict: false)
        ..lookHg()
        ..openDoor()
        ..chalk(M6Tier.lt);
      expect(o.commit().m, Mk.needlessChalk);
      // A chalk missed on an HG fall.
      final m = _runOf(_hg(), verdict: false)
        ..lookHg()
        ..openDoor()
        ..chalk(M6Tier.house);
      expect(m.commit().m, Mk.chainWrong);
      // A chalk rubbed out; 'ক্রম ঠিক' clears the chalk.
      final e = _runOf(_lt(), verdict: false)..chalk(M6Tier.lt);
      e.chalk(M6Tier.lt);
      expect(e.marks, isEmpty);
      e.chalk(M6Tier.house);
      e.toggleChainOk();
      expect(e.marks, isEmpty);
      expect(e.chainOk, isTrue);
    });

    test('nothing works before the verdict', () {
      final r = _runOf(_lt(), verdict: false);
      expect(r.mainSwitch(false), isFalse);
      expect(r.drawKitkat(), M6Step.none);
      expect(r.ltLever(false), M6Step.none);
      expect(r.abStroke(1), M6Step.none);
      expect(r.slips, 0);
      expect(r.deadly, isNull);
    });

    test('the kit-kat: drawn live = deadly; without gloves and goggles = deadly; scrap first; 0.50 mm only', () {
      expect(_runOf(_house()).drawKitkat().m, Mk.liveDraw);
      final noPpe = _runOf(_house(), ppe: false)..mainSwitch(false);
      expect(noPpe.drawKitkat().m, Mk.noPpe);
      expect(noPpe.deadly, Mk.noPpe);
      final half = _runOf(_house(), ppe: false)
        ..wear(0)
        ..mainSwitch(false);
      expect(half.drawKitkat().m, Mk.noPpe, reason: 'gloves without goggles');
      final r = _runOf(_house())..mainSwitch(false);
      expect(r.drawKitkat().ok, isTrue);
      expect(r.tray, M6Tray.kitkat);
      expect(r.mainSwitch(true), isFalse, reason: 'not with the carrier out');
      expect(r.spare(M6Spare.mm050, null).say, L.scrapFirst);
      expect(r.spare(M6Spare.scrap, null).ok, isTrue);
      for (final w in [M6Spare.mm085, M6Spare.mm150, M6Spare.mm200]) {
        expect(r.spare(w, null).m, Mk.wrongReel);
      }
      expect(r.spare(M6Spare.mm050, null).ok, isTrue);
      expect(r.kitkatFixed, isTrue);
      expect(r.tray, M6Tray.none);
      expect(r.mainSwitch(true), isTrue);
      expect(r.lightBack, isTrue, reason: 'a house fall: only the kit-kat');
      expect(r.caught, contains(L.caughtReel));
    });

    test('an HRC: LT on = deadly; lock-tag, 0 V, re-proof, PPE, the puller, the right way — then a new HRC with the puller', () {
      M6ChainRun lt() => _runOf(_lt());
      expect(lt().hrcTap(1, M6Tool.puller).m, Mk.liveDraw);
      expect(lt().hrcTap(1, null).m, Mk.liveDraw, reason: 'a bare hand too');
      final a = lt()..ltLever(false);
      expect(a.hrcTap(1, M6Tool.puller).m, Mk.noLockTag);
      a.toggleLockTag();
      expect(a.hrcTap(1, M6Tool.puller).m, Mk.noTest);
      expect(a.testOn(M6Target.lt).m, Mk.testFirst, reason: 'a 0 V on an unproved tester');
      a.testLive(M6Point.ltSupply);
      expect(a.testOn(M6Target.lt).live, isFalse);
      expect(a.hrcTap(1, M6Tool.puller).m, Mk.noReprove);
      expect(a.slips, 4);
      final b = lt();
      expect(b.testOn(M6Target.lt).live, isTrue, reason: 'live is read, never punished');
      _isolateLt(b);
      expect(b.hrcTap(1, M6Tool.pliers).m, Mk.noPuller);
      expect(b.hrcTap(1, null).m, Mk.noPuller);
      expect(b.hrcTap(0, M6Tool.puller).m, Mk.needlessOpen);
      expect(b.deadly, isNull);
      expect(b.hrcTap(1, M6Tool.puller).ok, isTrue);
      expect(b.tray, M6Tray.hrc);
      expect(b.spare(M6Spare.hrc, M6Tool.puller).say, L.scrapFirst);
      b.spare(M6Spare.scrap, M6Tool.puller);
      // Fuse wire across the HRC base (pro tip 3): a slip, never a free pick.
      for (final w in [M6Spare.mm050, M6Spare.mm200]) {
        expect(b.spare(w, M6Tool.puller).m, Mk.hrcWired);
        expect(b.spare(w, null).m, Mk.hrcWired);
      }
      expect(b.hrcFixed, isFalse);
      expect(b.spare(M6Spare.hrc, null).m, Mk.noPuller);
      expect(b.spare(M6Spare.hrc, M6Tool.puller).ok, isTrue);
      expect(b.hrcFixed, isTrue);
      expect(b.caught, containsAll([L.caughtIsolate, L.caughtPuller]));
      // No PPE after a proven isolation: a slip (A5), not deadly.
      final c = _runOf(_lt(), ppe: false);
      _isolateLt(c);
      expect(c.hrcTap(1, M6Tool.puller).m, Mk.noPpeProven);
      expect(c.deadly, isNull);
      // The LT switch's supply bar proves the tester only while the AB is closed.
      final d = _runOf(_hg())..ltLever(false);
      d.abStroke(1);
      expect(d.testLive(M6Point.ltSupply).live, isFalse);
      expect(d.proved, isEmpty);
      // A proof counts for its own voltage only (X1, A9): the 11 kV AB line
      // side never proves the tester for an HRC.
      final v = lt()
        ..ltLever(false)
        ..toggleLockTag();
      v.testLive(M6Point.abLine);
      expect(v.proved, {M6Target.hg});
      expect(v.testOn(M6Target.lt).m, Mk.testFirst);
      v.testLive(M6Point.ltSupply);
      expect(v.testOn(M6Target.lt).live, isFalse);
      v.testLive(M6Point.abLine);
      expect(v.hrcTap(1, M6Tool.puller).m, Mk.noReprove, reason: 'the re-proof on 11 kV does not count');
      v.testLive(M6Point.ltSupply);
      expect(v.hrcTap(1, M6Tool.puller).ok, isTrue);
    });

    test('the supply back: LT on with a suspect left = slip; locked lever and empty slot = nudges; then the light', () {
      final r = _runOf(_lt());
      _isolateLt(r);
      _fixHrc(r);
      r.toggleLockTag();
      expect(r.ltLever(true).m, Mk.refuseEarly, reason: 'the kit-kat jugaad still in');
      _fixKitkat(r);
      r.toggleLockTag();
      expect(r.ltLever(true).say, L.lockedLever);
      r.toggleLockTag();
      expect(r.closeDoor(), isTrue);
      expect(r.ltLever(true).ok, isTrue);
      expect(r.lightBack, isFalse, reason: 'the main switch still off');
      r.mainSwitch(true);
      expect(r.lightBack, isTrue);
      final e = _runOf(_lt());
      _isolateLt(e);
      e.hrcTap(1, M6Tool.puller);
      e.toggleLockTag();
      expect(e.ltLever(true).say, L.slotEmpty);
      // Back on, the proof is void.
      final f = _runOf(_lt());
      _fixKitkat(f);
      f.ltLever(false);
      f.testLive(M6Point.ltSupply);
      expect(f.proved, contains(M6Target.lt));
      f.closeDoor();
      expect(f.ltLever(true).ok, isTrue);
      expect(f.proved, isNot(contains(M6Target.lt)));
    });

    test('the LT box door (X4, M5 N5): LT back on with it open = slip, the lever stays; the light back with it open = slip once; shut, the call ends', () {
      // An LT call: the door still open at the LT switch.
      final r = _runOf(_lt());
      _fixKitkat(r);
      _isolateLt(r);
      _fixHrc(r);
      r.toggleLockTag();
      expect(r.ltLever(true).m, Mk.doorOpen);
      expect(r.ltOn, isFalse, reason: 'the lever stays down');
      expect(r.slips, 1);
      expect(r.closeDoor(), isTrue);
      expect(r.ltLever(true).ok, isTrue);
      r.mainSwitch(true);
      expect(r.lightCheck(), M6Step.done);
      expect(r.stage, M6Stage.done);
      expect(r.slips, 1);
      // A house call: the door left open after the reading; the light back =
      // a slip, once a call; the call ends once it is shut.
      final h = _runOf(_house());
      _fixKitkat(h);
      h.mainSwitch(true);
      expect(h.lightBack, isTrue);
      expect(h.lightCheck().m, Mk.doorOpen);
      expect(h.lightCheck(), M6Step.none, reason: 'once a call');
      expect(h.stage, M6Stage.work);
      expect(h.slips, 1);
      expect(h.closeDoor(), isTrue);
      expect(h.lightCheck().ok, isTrue);
      expect(h.stage, M6Stage.done);
      // Shut right after the reading: the read still counts; no slip.
      final c = _runOf(_house(), verdict: false)
        ..lookHg()
        ..openDoor();
      expect(c.closeDoor(), isTrue);
      expect(c.doorOpen, isFalse);
      c.toggleChainOk();
      expect(c.commit().ok, isTrue);
      _fixKitkat(c);
      c.mainSwitch(true);
      expect(c.lightCheck().ok, isTrue);
      expect(c.slips, 0);
      // Not while an HRC is out of its base; reopened for the work.
      final o = _runOf(_lt());
      _isolateLt(o);
      expect(o.hrcTap(1, M6Tool.puller).ok, isTrue);
      expect(o.closeDoor(), isFalse);
      expect(o.doorOpen, isTrue);
      // The door is shut and unread again on the next call.
      h.next();
      expect(h.doorOpen, isFalse);
      expect(h.doorRead, isFalse);
      expect(h.doorSlipped, isFalse);
      expect(Mk.doorOpen.deadly, isFalse);
    });

    test('a needless outage (R32): the LT off on a house call, the AB opened on a call with no HG — a slip, the switch stays', () {
      final h = _runOf(_house());
      expect(h.ltLever(false).m, Mk.needlessOutage);
      expect(h.ltOn, isTrue);
      expect(h.slips, 1);
      final l = _runOf(_lt())..ltLever(false);
      expect(l.ltOn, isFalse, reason: 'an LT call needs the LT off');
      expect(l.abStroke(1).m, Mk.needlessOutage);
      expect(l.abClosed, isTrue);
      expect(l.slips, 1);
      expect(_runOf(_lt()).abStroke(1).m, Mk.abOnLoad, reason: 'on load it is deadly first');
      final g = _runOf(_hg())..ltLever(false);
      expect(g.abStroke(1).ok, isTrue);
      expect(g.slips, 0);
    });

    test('the HG: AB on load = deadly; a stall = slip; blades, live-dead-live, earth (on live deadly, early slip); the wire', () {
      final a = _runOf(_hg());
      expect(a.abStroke(1).m, Mk.abOnLoad);
      final b = _runOf(_hg())..ltLever(false);
      expect(b.abStroke(0.5).m, Mk.abStall);
      expect(b.abStroke(1, stalled: true).m, Mk.abStall);
      expect(b.abStroke(0.1), M6Step.none, reason: 'a nudge of the handle is no stroke');
      expect(b.abClosed, isTrue);
      expect(b.earthTap().m, Mk.earthLive, reason: 'earth with the AB closed');
      expect(b.deadly, Mk.earthLive);
      final c = _runOf(_hg())..ltLever(false);
      expect(c.abStroke(1).ok, isTrue);
      expect(c.testOn(M6Target.hg).say, L.bladesFirst);
      c.lookBlades();
      expect(c.earthTap().m, Mk.earthFirst);
      c.testLive(M6Point.abLine);
      expect(c.testOn(M6Target.hg).live, isFalse);
      expect(c.earthTap().m, Mk.noReprove);
      c.testLive(M6Point.abLine);
      expect(c.earthTap().ok, isTrue);
      expect(c.deadly, isNull);
      // Hands on the HG wire: AB closed / before 0 V / without the earth = deadly.
      M6ChainRun hgTray(void Function(M6ChainRun r) prep) {
        final r = _runOf(_hg())..ltLever(false);
        prep(r);
        r.hgTap();
        expect(r.tray, M6Tray.hg);
        return r;
      }

      expect(hgTray((_) {}).spare(M6Spare.hg5, null).m, Mk.hgLive);
      expect(hgTray((r) => r.abStroke(1)).spare(M6Spare.hg5, null).m, Mk.hgUntested);
      expect(
          hgTray((r) {
            r.abStroke(1);
            r.lookBlades();
            r.testLive(M6Point.abLine);
            r.testOn(M6Target.hg);
          }).spare(M6Spare.hg5, null).m,
          Mk.hgNoEarth);
      final w = hgTray(_isolateHg);
      expect(w.spare(M6Spare.hg10, null).m, Mk.wrongHgWire, reason: '63 kVA → 5 A');
      expect(w.spare(M6Spare.hg5, null).ok, isTrue);
      expect(w.hgRenewed, isTrue);
      expect(m6HgSpareFor(25), M6Spare.hg3);
      expect(m6HgSpareFor(100), M6Spare.hg10);
    });

    test('an HG call end to end: AB closed only with the earth off, the LT off and every suspect fixed', () {
      final r = _runOf(_hg());
      _fixKitkat(r);
      _isolateLt(r);
      _fixHrc(r);
      _isolateHg(r);
      r.hgTap();
      r.spare(M6Spare.hg5, null);
      r.earthTap();
      expect(r.earthed, isFalse);
      expect(r.abStroke(1).ok, isTrue);
      expect(r.abClosed, isTrue);
      expect(r.proved, isNot(contains(M6Target.hg)));
      r.toggleLockTag();
      r.closeDoor();
      r.ltLever(true);
      expect(r.lightBack, isFalse, reason: 'the main switch still off');
      r.mainSwitch(true);
      expect(r.lightBack, isTrue);
      expect(r.slips, 0);
      expect(r.caught, containsAll([L.caughtChain, L.caughtHg, L.caughtJugaad, L.caughtReel]));
      // Closing with the earth still on = charging an earthed HG: deadly
      // (m5_gate_case precedent), never a free nudge.
      final e = _runOf(_hg());
      _isolateLt(e);
      _isolateHg(e);
      e.hgTap();
      e.spare(M6Spare.hg5, null);
      expect(e.abStroke(1).m, Mk.closeEarthed);
      expect(e.deadly, Mk.closeEarthed);
      // A suspect left: the AB may close (the LT is off, nothing reaches it);
      // the LT switch then refuses with R33, and the HRC is done with the
      // tester proved on the supply bar, live again.
      final s = _runOf(_hg());
      s.ltLever(false);
      s.toggleLockTag();
      _isolateHg(s);
      s.hgTap();
      s.spare(M6Spare.hg5, null);
      s.earthTap();
      expect(s.abStroke(1).ok, isTrue);
      s.toggleLockTag();
      expect(s.ltLever(true).m, Mk.refuseEarly);
      expect(s.ltOn, isFalse);
      s.toggleLockTag();
      s.testLive(M6Point.ltSupply);
      expect(s.testOn(M6Target.lt).live, isFalse);
      s.testLive(M6Point.ltSupply);
      _fixHrc(s);
      _fixKitkat(s);
      s.toggleLockTag();
      s.closeDoor();
      expect(s.ltLever(true).ok, isTrue);
      s.mainSwitch(true);
      expect(s.lightBack, isTrue);
      expect(s.slips, 1);
      expect(s.deadly, isNull);
    });

    test('the belt is never in its working order; the tray keeps the scrap pile first', () {
      final rows = <String>{};
      for (var s = 0; s < 80; s++) {
        final b = m6BeltRow(math.Random(s));
        expect(b.toSet(), M6Tool.values.toSet());
        expect(m6BeltInWorkOrder(b), isFalse);
        rows.add(b.map((t) => t.name).join(','));
        final k = m6TrayRow(M6Tray.kitkat, math.Random(s));
        expect(k.first, M6Spare.scrap);
        expect(k.toSet(), {M6Spare.scrap, M6Spare.mm050, M6Spare.mm085, M6Spare.mm150, M6Spare.mm200});
        expect(m6TrayRow(M6Tray.hg, math.Random(s)).toSet(), {M6Spare.hg3, M6Spare.hg5, M6Spare.hg10});
        expect(m6TrayRow(M6Tray.hrc, math.Random(s)).first, M6Spare.scrap);
      }
      expect(rows.length, greaterThan(15));
    });

    test('English digits only; jol not pani; every mistake has its picture; the deadly set; keys; lesson points; the art folder', () {
      final all = <String>[
        L.intro,
        ...L.allCalls,
        ...L.tasks,
        ...L.tapWhy,
        L.readFirst,
        L.markFirst,
        L.workLater,
        L.scrapFirst,
        L.bladesFirst,
        L.lockedLever,
        L.slotEmpty,
        L.callHeld,
        for (final t in M6Tier.values) L.tier(t),
        for (final t in M6Tool.values) L.tool(t),
        for (final s in M6Spare.values) L.spare(s),
        for (var n = 1; n <= 6; n++) L.docketHouse(n),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(L.call(3), startsWith('3 নম্বর'));
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.liveDraw, Mk.noPpe, Mk.hgLive, Mk.hgUntested, Mk.hgNoEarth, Mk.earthLive, Mk.closeEarthed, Mk.abOnLoad});
      expect(Mk.deadlyKeys, [for (final m in Mk.all) if (m.deadly) m.key]);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.3/m6_fuse_chain/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 5));
      }
      // The HG reject is lesson 6.3 point 6 word for word (ruling M6-2).
      expect(Mk.hgLive.textBn, contains('হর্ন গ্যাপ ফিউজের তার বদলানোর আগে AB সুইচ খুলে তিনটি ব্লেডই খুলেছে কি না দেখুন, টেস্টারে ডেড প্রমাণ করুন এবং আর্থিং দিন।'));
      const dir = 'assets/game/art/m6_fuse_chain/';
      final used = {for (final m in Mk.all) if (m.art.startsWith(dir)) m.art.split('/').last};
      final files = Directory('assets/game/art/m6_fuse_chain').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6FuseChainPacks.keys, ['do_6_3_b']);
      // No mat, no rod, no DO anywhere (ruling M6-2).
      for (final l in all) {
        expect(l.contains('ম্যাট'), isFalse, reason: l);
        expect(l.contains('DO'), isFalse, reason: l);
      }
    });

    test('the reason fits the call: no jugaad topic on a house fall (its wire was right and melted)', () {
      expect(m6WhysFor(M6Tier.house), isNot(contains(M6Why.jugaad)));
      for (final t in M6Tier.values) {
        for (final w in m6WhysFor(t)) {
          final c = M6Call(
            house: 1,
            phase: 0,
            fallen: t,
            kitkat: t == M6Tier.house ? M6Content.melted : M6Content.gi,
            hrc: switch (t) { M6Tier.house => null, M6Tier.lt => M6Content.blownHrc, M6Tier.hg => M6Content.strip },
            why: w,
          );
          if (w == M6Why.jugaad) expect(c.kitkatJugaad, isTrue, reason: '$t: a jugaad was there to throw out');
          if (w == M6Why.chalk) expect(c.chalkSet, isNotEmpty);
          if (w == M6Why.chainOk) expect(c.chalkSet, isEmpty);
          if (w == M6Why.dot) expect(c.hrc, M6Content.blownHrc);
          if (w == M6Why.puller) expect(c.needsLt, isTrue);
          if (w == M6Why.hgIsolate) expect(c.needsHg, isTrue);
        }
      }
    });

    test("his push fits the moment: 'হাতে গ্লাভস তো আছে' only once the gloves are on", () {
      expect(L.pushNow(M6Push.glovesOn, gloves: false), M6Push.noBother);
      expect(L.pushNow(M6Push.glovesOn, gloves: true), M6Push.glovesOn);
      expect(L.pushNow(M6Push.noBother, gloves: false), M6Push.noBother);
      expect(L.pushNow(M6Push.noBother, gloves: true), M6Push.noBother);
      expect(L.coworkerGlovesOn.line, contains('গ্লাভস তো আছে'));
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his two new pushes and the new guide lines are listed for the owner', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, {
        'মেইন সুইচ নামানোর ঝামেলা কেন? এক টানে খুলে নাও!',
        'লোড থাকলে কী, হাতে গ্লাভস তো আছে — চটপট টেনে নাও!',
      });
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_fuse_chain: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
      expect(L.newGuideLines.toSet().length, L.newGuideLines.length, reason: 'no line twice');
      for (final l in L.newGuideLines) {
        // Not recorded yet: the owner gives the wording, then the director records.
        debugPrint('GUIDE m6_fuse_chain: $l');
      }
      expect(L.newGuideLines, containsAll([L.intro, ...L.allCalls, ...L.whyQ.values]));
      expect(L.newGuideLines, contains(Mk.doorOpen.textBn), reason: 'the new DRAFT slip text, for the owner');
    });

    test('tap areas do not overlap, stay on the scene, clear of the docket, the card, the guide and the belt', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6ChainGeo.forScene(h, 0);
        final rects = <Rect>[
          g.abLineHit,
          g.abBladesHit,
          g.hgHit,
          g.ltSupplyHit,
          for (var i = 0; i < 3; i++) g.hrcHit(i),
          g.ltLeverHit,
          g.doorHit,
          g.abHandle,
          g.mainHit,
          g.kitkatHit,
          g.ppeHit(0),
          g.ppeHit(1),
        ];
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the belt');
          expect(r.overlaps(M6ChainGeo.docket), isFalse, reason: 'h $h: $r');
          expect(r.overlaps(M6ChainGeo.card), isFalse, reason: 'h $h: $r');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, g.groundY - 129, 360, g.groundY - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        // The supply bar and the HRCs share the LT box by design; the rest
        // never overlap.
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse, reason: 'h $h: $i/$j ${rects[i]} ${rects[j]}');
          }
        }
        expect(g.ltBox.contains(g.ltSupplyHit.center), isTrue);
        expect(M6ChainGeo.card.top, greaterThanOrEqualTo(M6ChainGeo.docket.bottom));
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket; the belt only after the verdict', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6FuseChainPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m6ChainDeal(math.Random(3));
      for (final tier in M6Tier.values) {
        expect(_label(L.tier(tier)), findsOneWidget);
      }
      expect(_label(L.chainOk), findsOneWidget);
      expect(_label(L.goLook), findsOneWidget);
      expect(find.textContaining(L.docketHouse(d.calls.first.house)), findsOneWidget);
      expect(_label(L.tool(M6Tool.puller)), findsNothing, reason: 'no belt before the verdict');
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
      expect(lines.every((l) => l.contains(L.askRead)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // A day with all three kinds, and one with two HRC falls and the HG.
    final flowSeeds = [
      _seedWhere((d) => d.calls.map((c) => c.fallen).toSet().length == 3),
      _seedWhere((d) => d.calls.where((c) => c.fallen == M6Tier.lt).length == 2 && d.calls.any((c) => c.fallen == M6Tier.hg)),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): PPE, three calls read, chalked, fixed, the light back; reasons; he is refused → pass', (t) async {
        final d = m6ChainDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _ppe(t);
        expect(M6FuseChainProbe.run!.ppe, isTrue);
        for (var i = 0; i < 3; i++) {
          await _playCall(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.3/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.3/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtChain), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final ltFirst = _seedWhere((d) => d.calls.first.fallen == M6Tier.lt && d.coworkerCall != 0);
    testWidgets("a wrong verdict ('ক্রম ঠিক' on a broken chain): its card, then the docket shows the chalk and the belt comes", (t) async {
      final c = await _open(t, ltFirst);
      await _reads(t);
      await t.tap(_label(L.goLook));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing, reason: 'no mark yet: a nudge');
      expect(c.read(guideDirectorProvider).line, L.markFirst);
      await t.tap(_label(L.chainOk));
      await _pump(t, 300);
      await t.tap(_label(L.goLook));
      await _pump(t, 600);
      expect(find.text(Mk.chainWrong.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(M6FuseChainProbe.run!.marks, {M6Tier.house});
      expect(_label(L.tool(M6Tool.puller)), findsOneWidget, reason: 'the work goes on');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.chainWrong.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final houseFirstAlone = _seedWhere((d) => d.calls.first.fallen == M6Tier.house && d.coworkerCall != 0);
    testWidgets('three slips strike the level out (a needless chalk, then two wrong reels)', (t) async {
      final c = await _open(t, houseFirstAlone);
      await _ppe(t);
      await _reads(t);
      await _chalk(t, M6Tier.lt);
      await t.tap(_label(L.goLook));
      await _pump(t, 600);
      expect(find.text(Mk.needlessChalk.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _mainSwitch(t, false);
      await _tapAt(t, _geo.kitkatHit.center);
      await _spare(t, M6Spare.scrap);
      await _spare(t, M6Spare.mm200);
      expect(find.text(Mk.wrongReel.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _spare(t, M6Spare.mm150);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the light back with the LT box door open: a slip card (X4, M5 N5); shut, the call ends', (t) async {
      final c = await _open(t, houseFirstAlone);
      await _ppe(t);
      await _reads(t);
      await t.tap(_label(L.chainOk));
      await _pump(t, 300);
      await t.tap(_label(L.goLook));
      await _pump(t, 600);
      if (find.byType(ChoiceDeck).evaluate().isNotEmpty) {
        await _pickRight(t, L.whyRight[m6ChainDeal(math.Random(houseFirstAlone)).calls.first.why]!);
        await _pump(t, 2000);
      }
      await _mainSwitch(t, false);
      await _tapAt(t, _geo.kitkatHit.center);
      await _spare(t, M6Spare.scrap);
      await _spare(t, M6Spare.mm050);
      await _mainSwitch(t, true);
      await _pump(t, 600);
      expect(find.text(Mk.doorOpen.textBn), findsOneWidget);
      expect(M6FuseChainProbe.run!.stage, M6Stage.work);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapAt(t, _geo.doorHit.center);
      expect(M6FuseChainProbe.run!.stage, M6Stage.done);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.doorOpen.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the kit-kat drawn with the main switch ON: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, houseFirstAlone);
      await _ppe(t);
      await _reads(t);
      await t.tap(_label(L.chainOk));
      await _pump(t, 300);
      await t.tap(_label(L.goLook));
      await _pump(t, 600);
      if (find.byType(ChoiceDeck).evaluate().isNotEmpty) {
        await _pickRight(t, L.whyRight[m6ChainDeal(math.Random(houseFirstAlone)).calls.first.why]!);
        await _pump(t, 2000);
      }
      await _tapAt(t, _geo.kitkatHit.center);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.liveDraw.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final himFirst = _seedWhere((d) => d.calls.first.fallen != M6Tier.house && d.coworkerCall == 0 && !m6WhyAtVerdict(d.calls.first.why));
    testWidgets('his call: the first touch on a guard waits for him and does nothing; listening = a live draw: freeze, then the card', (t) async {
      final d = m6ChainDeal(math.Random(himFirst));
      final c = await _open(t, himFirst);
      await _ppe(t);
      await _reads(t);
      await _verdict(t, d.calls.first);
      // Fast: the main switch at once — he cuts in, the switch stays ON.
      await t.dragFrom(_geo.mainHit.center * _k, const Offset(0, 40) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(M6FuseChainProbe.run!.mainOn, isTrue, reason: 'the held control did nothing');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker(d.push).wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.liveDraw.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets("his push fits the moment: dealt 'গ্লাভস তো আছে' but no gloves on yet → the other wording", (t) async {
      final seed = _seedWhere((d) => d.calls.first.fallen != M6Tier.house && d.coworkerCall == 0 && d.push == M6Push.glovesOn && !m6WhyAtVerdict(d.calls.first.why));
      final d = m6ChainDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _reads(t);
      await _verdict(t, d.calls.first);
      await t.dragFrom(_geo.mainHit.center * _k, const Offset(0, 40) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(t.widget<CoworkerPeek>(find.byType(CoworkerPeek)).lineBn, L.coworkerNoBother.line);
      await _close(t, c);
    });

    testWidgets('the AB opened with the LT load on: deadly freeze (X3)', (t) async {
      final hgFirst = _seedWhere((d) => d.calls.first.fallen == M6Tier.hg && d.coworkerCall != 0 && !m6WhyAtVerdict(d.calls.first.why));
      final d = m6ChainDeal(math.Random(hgFirst));
      final c = await _open(t, hgFirst);
      await _reads(t);
      await _verdict(t, d.calls.first);
      await _abStroke(t, true);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.abOnLoad.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the guards to read while the docket waits; none while a card is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, ltFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while reading');
      expect(scene().debugOptions.length, greaterThanOrEqualTo(3), reason: 'a sweep over the HG, the LT box, the board alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _reads(t);
      await t.tap(_label(L.chainOk));
      await _pump(t, 300);
      await t.tap(_label(L.goLook));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the card is up');
      await _close(t, c);
    });
  });
}
