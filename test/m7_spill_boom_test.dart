// Lesson 7.8 (পরিবেশগত আইন: আমাদের দায়িত্ব), কাজ 1 "এক ফোঁটাও মাটিতে নয়": the
// rules (the ring maths: closed + encloses the valve spot and the pallet; pads
// only inside the pad zone; the valve before the pads and the boom = a slip;
// the hose: the leak-proof drum, or the second drum when sound, is right; the
// drain, soil, bucket or a weeping drum = a slip; the puddle held by a good ring,
// out through a gap = a slip, to the drain = a slip, stopped by a ring ahead of
// its edge; soak only on held oil; red bag right, green bin a slip; listening
// = a slip, one more pad), the deal, the libraries, and the level in the shell:
// the guide first, a clean play (two reasons + the final one, the coworker
// refused), a play through a gap in the ring, the slip cards, three slips, the
// coworker waits for a fast play, listening shows the ground slice, and the
// gesture hand only while the level waits. Lesson 7.8 has no deadly mistake.
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_spill_boom.dart';
import 'package:slm_flutter/features/game/m7_spill_boom_world.dart';
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
  rungId: '7.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7SpillBoomPacks['do_7_8_a']!;
typedef L = M7SpillBoomLines;
typedef Mk = M7SpillBoomMistakes;

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

Future<bool> _pumpWhile(WidgetTester t, bool Function() ok, {int maxMs = 15000}) async {
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
final double _sceneH = (360 * 850 / 392).clamp(560.0, 900.0);

M7SpillGeo _geo(M7SpillRun r) => M7SpillGeo.forScene(_sceneH, 0, drainRight: r.deal.drainRight);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7SpillBoomPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7SpillDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m7SpillDeal(math.Random(s))));

// --- hands on ----------------------------------------------------------------
Future<void> _openKit(WidgetTester t, M7SpillRun r) async {
  await t.tapAt(_geo(r).kitHit.center * _k);
  await _pump(t, 300);
}

Future<void> _dragPad(WidgetTester t, M7SpillRun r, {Offset? to}) async {
  final g = _geo(r);
  final a = g.padStackHit.center;
  final b = to ?? g.padZone.center;
  await t.dragFrom(a * _k, (b - a) * _k);
  await _pump(t, 300);
}

List<Offset> _ringPts(Offset c, double rx, double ry, {double sweep = 2 * math.pi, int n = 28}) => [
      for (var i = 0; i <= n; i++) c + Offset(math.cos(sweep * i / n) * rx, math.sin(sweep * i / n) * ry),
    ];

Future<void> _drawPts(WidgetTester t, List<Offset> pts) async {
  final g = await t.startGesture(pts.first * _k);
  for (final p in pts.skip(1)) {
    await g.moveTo(p * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

/// The set-up ring round the valve spot and the pallet ([gap]: not closed).
Future<void> _drawSetupRing(WidgetTester t, M7SpillRun r, {bool gap = false}) async {
  final g = _geo(r);
  final c = Offset.lerp(g.spill, g.pallet, 0.5)!;
  await _drawPts(t, _ringPts(c, 80, 38, sweep: gap ? 1.6 * math.pi : 2 * math.pi));
}

Future<void> _setup(WidgetTester t, M7SpillRun r, {bool gap = false, bool reason = true}) async {
  await _openKit(t, r);
  await _dragPad(t, r);
  await _dragPad(t, r);
  await _drawSetupRing(t, r, gap: gap);
  expect(r.setupReady, isTrue, reason: 'pads ${r.padsPlaced}, ring ${r.ring1?.length}');
  if (reason) {
    await _pickRight(t, L.whyRight[M7SpillWhy.kit]!);
    await _pump(t, 600);
  }
}

int _rightSlot(M7SpillRun r) => List.generate(3, (i) => i).firstWhere(r.deal.slotRight);
int _wrongSlot(M7SpillRun r) => List.generate(3, (i) => i).firstWhere((i) => !r.deal.slotRight(i));

Future<void> _hoseTo(WidgetTester t, M7SpillRun r, int slot) async {
  final g = _geo(r);
  final a = g.hoseHome;
  final b = g.slot(slot).center;
  await t.dragFrom(a * _k, (b - a) * _k);
  await _pump(t, 400);
}

Future<void> _valve(WidgetTester t, M7SpillRun r, {required bool open}) async {
  final g = _geo(r);
  final a = g.knob(open ? 0 : 1);
  final b = g.knob(open ? 1 : 0);
  await t.dragFrom(a * _k, (b - a) * _k);
  await _pump(t, 500);
}

Future<void> _refuse(WidgetTester t, M7SpillPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

Future<void> _soakAll(WidgetTester t, M7SpillRun r) async {
  final n = r.padsNeeded;
  for (var i = 0; i < n; i++) {
    await t.longPressAt(r.puddleAt * _k);
    await _pump(t, 400);
  }
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
}

/// Bag, reason, close the valve and the bung.
Future<void> _finishUp(WidgetTester t, M7SpillRun r) async {
  final g = _geo(r);
  await t.tapAt(g.redBin.center * _k);
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[m7SpillFinalWhy(r.deal)]!);
  await _pump(t, 600);
  await _valve(t, r, open: false);
  await t.tapAt(g.bungHit(r.hoseSlot!).center * _k);
  await _pump(t, 3000);
}

// --- pure helpers --------------------------------------------------------------
M7SpillDeal _deal({
  bool drainRight = true,
  List<M7SlotKind> slots = const [M7SlotKind.drum, M7SlotKind.drumB, M7SlotKind.bucket],
  bool weeping = false,
  int band = 1,
  double delay = 2,
  M7SpillPush push = M7SpillPush.soil,
}) =>
    M7SpillDeal(
      drainRight: drainRight,
      slots: slots,
      weeping: weeping,
      incident: M7Incident.couplingDrip,
      band: band,
      delay: delay,
      incT: 0.5,
      incDy: 0,
      push: push,
      dusk: false,
      whyRoll: 2,
    );

final _g = M7SpillGeo.forScene(780, 0);

List<Offset> _ringAround(Offset c, double rx, double ry, {bool gap = false}) => _ringPts(c, rx, ry, sweep: gap ? 1.6 * math.pi : 2 * math.pi);

List<Offset> get _goodRing => _ringAround(Offset.lerp(_g.spill, _g.pallet, 0.5)!, 80, 38);

/// A run with the set-up done and the hose in the drum.
M7SpillRun _ready({M7SpillDeal? deal, bool gap = false}) {
  final r = M7SpillRun(deal ?? _deal());
  r.openKit();
  expect(r.placePad(_g.padZone.center, _g), isTrue);
  expect(r.placePad(_g.padZone.center + const Offset(10, 0), _g), isTrue);
  r.drawSetupBoom(gap ? _ringAround(Offset.lerp(_g.spill, _g.pallet, 0.5)!, 80, 38, gap: true) : _goodRing, _g);
  expect(r.hoseTo(M7Target.slot, 0, _g), isNull);
  return r;
}

/// A run with the oil flowing and the puddle on the ground.
M7SpillRun _flowing({bool gap = false, M7SpillDeal? deal}) {
  final r = _ready(gap: gap, deal: deal);
  expect(r.openValve(), isNull);
  expect(r.valveOpen, isTrue);
  while (!r.puddleOn) {
    r.tick(0.1, _g);
  }
  return r;
}

void main() {
  group('rules', () {
    test('ring maths: too short = nothing, ends apart = open, closed but missing a point = misses, else ok', () {
      final c = Offset.lerp(_g.spill, _g.pallet, 0.5)!;
      final must = [_g.spill, _g.pallet];
      expect(m7JudgeRing(const [Offset(10, 10), Offset(30, 10), Offset(10, 30)], must), M7RingJudge.tooShort);
      expect(m7JudgeRing(_ringAround(c, 80, 38), must), M7RingJudge.ok);
      expect(m7JudgeRing(_ringAround(c, 80, 38, gap: true), must), M7RingJudge.open);
      // Closed round the valve spot only (a ring that misses the pallet).
      expect(m7JudgeRing(_ringAround(_g.spill + const Offset(-30, 0), 40, 30), must), M7RingJudge.misses);
      // Ends within 34 px close the ring.
      final almost = _ringPts(c, 80, 38, sweep: 2 * math.pi - 0.2);
      expect((almost.last - almost.first).distance, lessThan(m7RingCloseTol));
      expect(m7JudgeRing(almost, must), M7RingJudge.ok);
      expect(m7Encloses(_goodRing, c), isTrue);
      expect(m7Encloses(_goodRing, const Offset(5, 5)), isFalse);
      expect(m7PathLen(_goodRing), greaterThan(m7RingMinPath));
    });

    test('the geometry mirrors with the drain side; the drain is on the dealt side', () {
      final r = M7SpillGeo.forScene(780, 0);
      final l = M7SpillGeo.forScene(780, 0, drainRight: false);
      expect(r.grating.center.dx, greaterThan(180));
      expect(l.grating.center.dx, lessThan(180));
      expect(l.spill.dx, closeTo(360 - r.spill.dx, 0.01));
      expect(l.progressAt(l.knob(0.5)), closeTo(0.5, 0.01));
      expect(l.progressAt(l.knob(1)), closeTo(1, 0.01));
      expect(r.progressAt(r.knob(0)), closeTo(0, 0.01));
    });

    test('deals: drain side, container places, a weeping or a sound second drum, every incident, growth band, coworker line; plays differ', () {
      final seen = <String>{};
      final sides = <bool>{};
      final weep = <bool>{};
      final inc = <M7Incident>{};
      final bands = <int>{};
      final pushes = <M7SpillPush>{};
      final perms = <String>{};
      for (var s = 0; s < 200; s++) {
        final d = m7SpillDeal(math.Random(s));
        expect(d.slots.toSet(), M7SlotKind.values.toSet());
        expect(d.delay, inInclusiveRange(1.5, 3.5));
        expect(d.incT, inInclusiveRange(0.2, 0.8));
        expect(d.padsNeeded, inInclusiveRange(2, 3));
        expect(List.generate(3, (i) => i).where(d.slotRight).length, d.weeping ? 1 : 2, reason: 'the drum, and the second drum when it is sound');
        sides.add(d.drainRight);
        weep.add(d.weeping);
        inc.add(d.incident);
        bands.add(d.band);
        pushes.add(d.push);
        perms.add(d.slots.map((e) => e.index).join());
        seen.add('${d.drainRight}${d.slots.map((e) => e.index).join()}${d.weeping}${d.incident.index}${d.band}${d.push.index}${d.delay.toStringAsFixed(1)}');
      }
      expect(sides, {true, false});
      expect(weep, {true, false});
      expect(inc, M7Incident.values.toSet());
      expect(bands, {0, 1, 2});
      expect(pushes, M7SpillPush.values.toSet());
      expect(perms, hasLength(6));
      expect(seen.length, greaterThan(150));
    });

    test('the leak-proof drum is always right; the second drum only when it is sound; the bucket never', () {
      final a = _deal(slots: const [M7SlotKind.bucket, M7SlotKind.drumB, M7SlotKind.drum], weeping: true);
      expect(a.slotRight(2), isTrue);
      expect(a.slotRight(1), isFalse);
      expect(a.slotRight(0), isFalse);
      final b = _deal(slots: const [M7SlotKind.bucket, M7SlotKind.drumB, M7SlotKind.drum]);
      expect(b.slotRight(1), isTrue);
      expect(b.slotRight(0), isFalse);
    });

    test('set-up: pads only in the zone and with the kit open; the ring is stored when long enough and replaced only by a closed one', () {
      final r = M7SpillRun(_deal());
      expect(r.placePad(_g.padZone.center, _g), isFalse, reason: 'the kit is closed');
      expect(r.drawSetupBoom(_goodRing, _g), M7RingJudge.tooShort, reason: 'no boom before the kit is open');
      r.openKit();
      expect(r.placePad(const Offset(20, 20), _g), isFalse);
      expect(r.placePad(_g.padZone.center, _g), isTrue);
      expect(r.setupReady, isFalse);
      final gap = _ringAround(Offset.lerp(_g.spill, _g.pallet, 0.5)!, 80, 38, gap: true);
      expect(r.drawSetupBoom(const [Offset(1, 1), Offset(5, 5), Offset(9, 9)], _g), M7RingJudge.tooShort);
      expect(r.ring1, isNull);
      expect(r.drawSetupBoom(gap, _g), M7RingJudge.open);
      expect(r.ring1, same(gap), reason: 'an open ring is stored when it is the first: found when the oil escapes');
      expect(r.held, isFalse);
      expect(r.placePad(_g.padZone.center, _g), isTrue);
      expect(r.setupReady, isTrue);
      final other = _ringAround(Offset.lerp(_g.spill, _g.pallet, 0.5)!, 70, 34, gap: true);
      expect(r.drawSetupBoom(other, _g), M7RingJudge.open);
      expect(r.ring1, same(gap), reason: 'a stray open stroke does not replace a ring');
      final good = _goodRing;
      expect(r.drawSetupBoom(good, _g), M7RingJudge.ok);
      expect(r.ring1, same(good));
      expect(r.held, isTrue);
      expect(r.stage, M7SpillStage.hose);
    });

    test('the valve before the pads and the boom = a slip (and stays shut); set-up done but no hose = nothing', () {
      final r = M7SpillRun(_deal());
      expect(r.openValve(), Mk.openFirst);
      expect(r.valveOpen, isFalse);
      expect(r.slips, 1);
      expect(Mk.openFirst.deadly, isFalse);
      r.openKit();
      r.placePad(_g.padZone.center, _g);
      expect(r.openValve(), Mk.openFirst, reason: 'pads alone are not enough');
      r.placePad(_g.padZone.center, _g);
      r.drawSetupBoom(_goodRing, _g);
      expect(r.stage, M7SpillStage.hose);
      expect(r.openValve(), isNull);
      expect(r.valveOpen, isFalse, reason: 'it would pour on the ground: the hose first');
      expect(r.slips, 2);
      expect(r.hoseTo(M7Target.slot, 0, _g), isNull);
      expect(r.openValve(), isNull);
      expect(r.valveOpen, isTrue);
      expect(r.stage, M7SpillStage.contain);
      expect(r.caught, contains(L.caughtKit));
    });

    test('the hose: drain or soil = a slip; bucket or a weeping drum = a slip; the right drum takes it; a drop on nothing is nothing', () {
      final r = M7SpillRun(_deal(weeping: true));
      expect(r.hoseTo(M7Target.slot, 0, _g), isNull, reason: 'not before the set-up');
      expect(r.hoseSlot, isNull);
      r.openKit();
      r.placePad(_g.padZone.center, _g);
      r.placePad(_g.padZone.center, _g);
      r.drawSetupBoom(_goodRing, _g);
      expect(r.hoseTo(M7Target.drain, -1, _g), Mk.hoseDrain);
      expect(r.hoseTo(M7Target.soil, -1, _g), Mk.hoseDrain);
      expect(r.hoseTo(M7Target.slot, 2, _g), Mk.hoseBucket);
      expect(r.hoseTo(M7Target.slot, 1, _g), Mk.hoseBucket, reason: 'the second drum weeps');
      expect(r.hoseTo(M7Target.none, -1, _g), isNull);
      expect(r.slips, 4);
      expect(r.hoseSlot, isNull);
      expect(r.hoseTo(M7Target.slot, 0, _g), isNull);
      expect(r.hoseSlot, 0);
      expect(r.caught, contains(L.caughtDrum));
      // A sound second drum is as good as the first.
      final s = M7SpillRun(_deal());
      s.openKit();
      s.placePad(_g.padZone.center, _g);
      s.placePad(_g.padZone.center, _g);
      s.drawSetupBoom(_goodRing, _g);
      expect(s.hoseTo(M7Target.slot, 1, _g), isNull);
      expect(s.hoseSlot, 1);
      expect(s.slips, 0);
    });

    test('a good ring holds the puddle: it grows to the cap, stops, and never slips; soak, bag and close finish it', () {
      final r = _flowing();
      expect(r.held, isTrue);
      var slips = 0;
      for (var i = 0; i < 400; i++) {
        final t = r.tick(0.1, _g);
        if (t.slip != null) slips++;
      }
      expect(slips, 0);
      expect(r.r, m7SpillHoldR);
      expect(r.escaped, isFalse);
      expect(r.edge, 0);
      expect(r.sealed, isTrue);
      expect(r.tick(0.1, _g).changed, isFalse, reason: 'idle: nothing changes once it has stopped');
      expect(r.bin(red: true), isNull, reason: 'nothing to bag before the soaking');
      expect(r.bagged, isFalse);
      for (var i = 0; i < r.padsNeeded; i++) {
        expect(r.soakedAll, isFalse);
        expect(r.soak(), isTrue);
      }
      expect(r.soakedAll, isTrue);
      expect(r.soak(), isFalse);
      expect(r.left, 0);
      expect(r.stage, M7SpillStage.bag);
      expect(r.bin(red: false), Mk.padGeneral);
      expect(r.bagged, isFalse);
      expect(r.usedPads, r.padsNeeded);
      expect(r.closeValve(), isFalse, reason: 'the valve and the bung come last');
      expect(r.bin(red: true), isNull);
      expect(r.bagged, isTrue);
      expect(r.usedPads, 0);
      expect(r.stage, M7SpillStage.close);
      expect(r.closeBung(), isTrue);
      expect(r.done, isFalse);
      expect(r.closeValve(), isTrue);
      expect(r.done, isTrue);
      expect(r.slips, 1);
      expect(r.passed, isTrue);
      expect(r.percent, 85);
      expect(r.caught, containsAll([L.caughtKit, L.caughtDrum, L.caughtBag]));
    });

    test('the incident starts after the dealt wait, once the valve is open', () {
      final r = _ready(deal: _deal(delay: 2.0));
      expect(r.tick(1, _g).changed, isFalse, reason: 'valve shut: nothing happens');
      r.openValve();
      var appeared = 0;
      var t = 0.0;
      while (!r.puddleOn && t < 10) {
        if (r.tick(0.1, _g).appeared) appeared++;
        t += 0.1;
      }
      expect(appeared, 1);
      expect(t, closeTo(2.0, 0.15));
      expect(r.puddleAt, _g.incident(0.5, 0));
      expect(r.r, m7SpillStartR);
    });

    test('a gap in the ring: the puddle escapes (one slip), runs to the drain (one more slip), then stops', () {
      final r = _flowing(gap: true);
      final slips = <DoMistake>[];
      var steps = 0;
      while (steps++ < 2000 && !r.atDrain) {
        final t = r.tick(0.1, _g);
        if (t.slip != null) slips.add(t.slip!);
      }
      expect(slips, [Mk.ringGap, Mk.puddleDrain]);
      expect(r.escaped, isTrue);
      expect(r.atDrain, isTrue);
      expect(r.edge, r.drainDist);
      expect(r.slips, 2);
      expect(r.tick(0.1, _g).changed, isFalse, reason: 'the mate stopped the oil at the drain');
      expect(r.sealed, isTrue, reason: 'soakable now');
      // The ring that closed but missed the pallet is the same slip.
      final m = _ready();
      m.ring1Judge = M7RingJudge.misses;
      m.openValve();
      while (!m.puddleOn) {
        m.tick(0.1, _g);
      }
      final got = <DoMistake>[];
      for (var i = 0; i < 100; i++) {
        final t = m.tick(0.1, _g);
        if (t.slip != null) got.add(t.slip!);
      }
      expect(got.first, Mk.ringGap);
    });

    test('a ring drawn ahead of the edge stops the oil; one that misses the front does not; soak only after', () {
      final r = _flowing(gap: true);
      while (!r.escaped) {
        r.tick(0.1, _g);
      }
      expect(r.sealed, isFalse);
      expect(r.soak(), isFalse, reason: 'not on oil that is still running');
      expect(r.drawContain(const [Offset(1, 1), Offset(9, 9), Offset(1, 9)]), M7RingJudge.tooShort);
      for (var i = 0; i < 5; i++) {
        r.tick(0.1, _g);
      }
      // A ring round the puddle but not reaching the front.
      expect(r.drawContain(_ringAround(r.puddleAt, 30, 20)), M7RingJudge.misses);
      expect(r.contained, isFalse);
      expect(r.drawContain(_ringAround(r.puddleAt + r.edgeDir * 40, 100, 50, gap: true)), M7RingJudge.open);
      expect(r.contained, isFalse);
      final ok = _ringAround(r.puddleAt + r.edgeDir * 40, 100, 55);
      expect(r.drawContain(ok), M7RingJudge.ok);
      expect(r.contained, isTrue);
      expect(r.ring2, same(ok));
      final edge = r.edge;
      for (var i = 0; i < 200; i++) {
        expect(r.tick(0.1, _g).slip, isNull);
      }
      expect(r.edge, edge, reason: 'the ring ahead holds it');
      expect(r.atDrain, isFalse);
      expect(r.sealed, isTrue);
      expect(r.soak(), isTrue);
      expect(r.slips, 1, reason: 'only the escape');
    });

    test('a ring drawn while the puddle is still inside the bad ring stops it before it escapes (no ring slip)', () {
      final r = _flowing(gap: true);
      expect(r.escaped, isFalse);
      expect(r.drawContain(_ringAround(r.puddleAt + r.edgeDir * 30, 100, 55)), M7RingJudge.ok);
      for (var i = 0; i < 300; i++) {
        expect(r.tick(0.1, _g).slip, isNull);
      }
      expect(r.escaped, isFalse);
      expect(r.slips, 0);
      expect(r.sealed, isTrue);
    });

    test('no ring is drawn on a held puddle; the faster band reaches the drain sooner; the slower needs two pads, the faster three', () {
      final r = _flowing();
      expect(r.drawContain(_ringAround(r.puddleAt, 90, 50)), M7RingJudge.tooShort);
      expect(r.ring2, isNull);
      int drainSteps(int band) {
        final f = _flowing(gap: true, deal: _deal(band: band));
        var n = 0;
        while (!f.atDrain && n < 5000) {
          f.tick(0.1, _g);
          n++;
        }
        return n;
      }
      expect(drainSteps(2), lessThan(drainSteps(0)));
      expect(_deal(band: 0).padsNeeded, 2);
      expect(_deal(band: 1).padsNeeded, 3);
      expect(_deal(band: 2).padsNeeded, 3);
    });

    test('listening to the coworker is a slip in this lesson (B1/X2: nothing here is deadly) and the bigger puddle needs one more pad', () {
      for (final p in M7SpillPush.values) {
        final r = _flowing();
        final before = r.padsNeeded;
        final m = r.listen(p);
        expect(m, Mk.push(p));
        expect(m.deadly, isFalse);
        expect(r.slips, 1);
        expect(r.padsNeeded, before + 1);
      }
      expect(Mk.push(M7SpillPush.soil), Mk.listenSoil);
      expect(Mk.push(M7SpillPush.wash), Mk.listenWash);
    });

    test('three slips: the mark falls to 55, then 40', () {
      final r = M7SpillRun(_deal());
      r.openValve();
      r.openValve();
      expect(r.percent, 70);
      r.openValve();
      expect(r.percent, 55);
      r.openValve();
      expect(r.percent, 40);
    });

    test('the final reason fits what was done: the soaking or the bagging, never anything unrelated', () {
      for (var s = 0; s < 40; s++) {
        final w = m7SpillFinalWhy(m7SpillDeal(math.Random(s)));
        expect([M7SpillWhy.soak, M7SpillWhy.bag], contains(w));
      }
      expect({for (var s = 0; s < 40; s++) m7SpillFinalWhy(m7SpillDeal(math.Random(s)))}, hasLength(2));
    });

    test('English digits only; jol not pani; every mistake has its picture; no mistake is deadly; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.sceneLabel,
        ...L.stages,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M7SpillPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtKit,
        L.caughtDrum,
        L.caughtBag,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'lesson 7.8 has no deadly (M7-6)');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.8/m7_spill_boom/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 4), reason: m.key);
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m7_spill_boom/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m7_spill_boom').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7SpillBoomPacks.keys, ['do_7_8_a']);
      expect(L.stages, hasLength(4));
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7SpillWhy.values) {
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

    test('rival lines: his exit is recorded; his two pushes (the lesson\'s myth word for word, and the wash shortcut) and the new guide lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect({for (final p in M7SpillPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.coworkerSoil.line, 'একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়।', reason: 'myth 1 of lesson 7.8, word for word');
      expect(L.newRivalLines, hasLength(2));
      for (final q in L.whyQ.values) {
        expect(L.newGuideLines, contains(q));
      }
      for (final p in M7SpillPush.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
      }
      for (final m in Mk.all) {
        expect(L.newGuideLines, contains(m.textBn), reason: 'read aloud the first time: listed for recording');
      }
      for (final cw in L.allCoworkers) {
        expect(L.newGuideLines, contains(cw.asks[1]));
      }
      for (final t in L.tasks) {
        expect(L.newGuideLines, contains(t));
      }
      expect(L.newGuideLines, containsAll([L.intro, L.allSet, L.quick, L.fail]));
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line listed twice');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_spill_boom: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas stay on the scene, below the header, above the bottom row, clear of the guide and of each other', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        for (final right in [true, false]) {
          final g = M7SpillGeo.forScene(h, 0, drainRight: right);
          final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
          final hits = <String, Rect>{
            'kit': g.kitHit,
            'padStack': g.padStackHit,
            'knob0': g.knobHit(0),
            'knob1': g.knobHit(1),
            'hose': g.hoseHit(g.hoseHome),
            'slot0': g.slot(0),
            'slot1': g.slot(1),
            'slot2': g.slot(2),
            'red': g.redBin,
            'green': g.greenBin,
            'drain': g.drainHit,
            'soil': g.soilHit,
            'padZone': g.padZone,
          };
          for (var i = 0; i < 3; i++) {
            hits['bung$i'] = g.bungHit(i);
          }
          for (final e in hits.entries) {
            final r = e.value;
            expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h $right ${e.key}');
            expect(r.right, lessThanOrEqualTo(360), reason: 'h $h $right ${e.key}');
            expect(r.top, greaterThan(125), reason: 'h $h ${e.key} below the header');
            expect(r.bottom, lessThan(h - 95), reason: 'h $h ${e.key} above the bottom row');
            if (!{'padZone', 'soil', 'drain'}.contains(e.key)) expect(r.overlaps(guide), isFalse, reason: 'h $h ${e.key} under the guide');
          }
          // The controls the player presses never overlap one another.
          const pressed = ['kit', 'padStack', 'knob0', 'knob1', 'hose', 'slot0', 'slot1', 'slot2', 'red', 'green', 'drain'];
          for (var i = 0; i < pressed.length; i++) {
            for (var j = i + 1; j < pressed.length; j++) {
              if (pressed[i].startsWith('knob') && pressed[j].startsWith('knob')) continue;
              expect(hits[pressed[i]]!.overlaps(hits[pressed[j]]!), isFalse, reason: 'h $h $right ${pressed[i]}/${pressed[j]}');
            }
          }
          // The pad stack and the kit are apart; the bung sits on its own slot.
          for (var i = 0; i < 3; i++) {
            expect(g.slot(i).overlaps(g.bungHit(i)), isTrue);
          }
          expect(g.padZone.contains(g.spill), isTrue);
          expect(g.padZone.contains(g.pallet), isTrue);
          expect(g.progressAt(g.knob(0.5)), closeTo(0.5, 0.01));
        }
      }
    });

    test('the hand hints: the pad nudge, the boom drag and the valve drag are plain (how, never what)', () {
      final g = _g;
      // The set-up sweep passes over the kit, the valve, the hose and every container alike.
      final sweep = g.setupSweep();
      expect(sweep, hasLength(6));
      expect(sweep.where((r) => r == g.slot(0) || r == g.slot(1) || r == g.slot(2)), hasLength(3));
      // The boom hand starts on neutral ground: away from the valve spot, the pallet and the drain.
      final at = g.boomHintAt;
      expect((at - g.spill).distance, greaterThan(60));
      expect((at - g.pallet).distance, greaterThan(100));
      expect(g.drainHit.contains(at), isFalse);
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

    testWidgets('the guide comes first: a tap does not skip him; then the yard stands there, nothing labelled', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7SpillBoomPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.byKey(const ValueKey('yard')), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askSetup)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a clean play: kit, pads, ring (a reason), hose (a reason), valve, the coworker refused, soak, bag (a reason), close → pass', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      expect(r.kitOpen, isFalse);
      await _setup(t, r);
      expect(r.stage, M7SpillStage.hose);
      expect(r.held, isTrue, reason: 'the ring closes round the valve spot and the pallet');
      expect(find.byType(MistakeCard), findsNothing);
      await _hoseTo(t, r, _rightSlot(r));
      expect(r.hoseSlot, _rightSlot(r));
      await _pickRight(t, L.whyRight[M7SpillWhy.drum]!);
      await _pump(t, 600);
      await _valve(t, r, open: true);
      expect(r.valveOpen, isTrue);
      expect(await _pumpWhile(t, () => r.puddleOn), isTrue, reason: 'the incident');
      await _refuse(t, r.deal.push);
      expect(r.escaped, isFalse, reason: 'held by the ring');
      await _soakAll(t, r);
      expect(r.soakedAll, isTrue);
      await _finishUp(t, r);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.8/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['7.8/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      expect(find.text(L.caughtKit), findsOneWidget);
      expect(find.text(L.caughtBag), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a gap in the ring: the oil escapes (a card), a ring ahead of the edge stops it, soak, bag, close → pass with one slip', (t) async {
      final seed = _seedWhere((d) => d.band == 0);
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      await _setup(t, r, gap: true);
      expect(r.held, isFalse);
      await _hoseTo(t, r, _rightSlot(r));
      await _pickRight(t, L.whyRight[M7SpillWhy.drum]!);
      await _pump(t, 600);
      await _valve(t, r, open: true);
      // The puddle appears, he comes, and the oil breaks out through the gap.
      expect(await _pumpWhile(t, () => r.puddleOn), isTrue);
      var refused = false;
      for (var ms = 0; ms < 12000 && find.byType(MistakeCard).evaluate().isEmpty; ms += 100) {
        if (!refused && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          await _refuse(t, r.deal.push);
          refused = true;
          continue;
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.ringGap.textBn), findsOneWidget);
      expect(r.escaped, isTrue);
      await _gotIt(t);
      if (!refused) await _refuse(t, r.deal.push);
      // A ring round the puddle and ahead of its front.
      final g = _geo(r);
      final centre = r.puddleAt + r.edgeDir * 40;
      expect(g.drainEdge.dx, isNot(centre.dx));
      await _drawPts(t, _ringPts(centre, 100, 55));
      expect(r.contained, isTrue, reason: 'edge ${r.edge} of ${r.drainDist}');
      expect(r.atDrain, isFalse);
      await _soakAll(t, r);
      await _finishUp(t, r);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.8/do/0'], 'cleared');
      expect(s.mistakes.map((e) => e.key), [Mk.ringGap.key]);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the valve before the pads and the boom: the slip card; the lever springs back', (t) async {
      final c = await _open(t, 2);
      final r = M7SpillBoomProbe.run!;
      await _valve(t, r, open: true);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.openFirst.textBn), findsOneWidget);
      expect(r.valveOpen, isFalse);
      await _gotIt(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.openFirst.key);
      await _close(t, c);
    });

    testWidgets('the hose to the drain, to the bucket, to a weeping drum: a slip each; the hose comes back; the right drum takes it', (t) async {
      final seed = _seedWhere((d) => d.weeping);
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      await _setup(t, r);
      final g = _geo(r);
      // The drain.
      final a = g.hoseHome;
      await t.dragFrom(a * _k, (g.grating.center - a) * _k);
      await _pump(t, 400);
      expect(find.text(Mk.hoseDrain.textBn), findsOneWidget);
      await _gotIt(t);
      expect(r.hoseSlot, isNull);
      await _hoseTo(t, r, _wrongSlot(r));
      expect(find.text(Mk.hoseBucket.textBn), findsOneWidget);
      await _gotIt(t);
      expect(r.slips, 2);
      expect(r.hoseSlot, isNull);
      await _hoseTo(t, r, _rightSlot(r));
      expect(r.hoseSlot, _rightSlot(r));
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.map((e) => e.key).toSet(), {Mk.hoseDrain.key, Mk.hoseBucket.key});
      await _close(t, c);
    });

    testWidgets('used pads into the green bin: a slip card; then the red bag is right', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      await _setup(t, r);
      await _hoseTo(t, r, _rightSlot(r));
      await _pickRight(t, L.whyRight[M7SpillWhy.drum]!);
      await _pump(t, 600);
      await _valve(t, r, open: true);
      expect(await _pumpWhile(t, () => r.puddleOn), isTrue);
      await _refuse(t, r.deal.push);
      await _soakAll(t, r);
      final g = _geo(r);
      await t.tapAt(g.greenBin.center * _k);
      await _pump(t, 400);
      expect(find.text(Mk.padGeneral.textBn), findsOneWidget);
      await _gotIt(t);
      expect(r.bagged, isFalse);
      expect(r.usedPads, r.padsNeeded);
      await _finishUp(t, r);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.8/do/0'], 'cleared');
      expect(s.mistakes.single.key, Mk.padGeneral.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      final r = M7SpillBoomProbe.run!;
      for (var i = 0; i < 3; i++) {
        await _valve(t, r, open: true);
        if (i < 2) await _gotIt(t);
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(r.slips, 3);
      await _close(t, c);
    });

    testWidgets('a fast play: the pads and the boom control wait for the coworker; he cuts in at once; the soak that waited did nothing', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      await _setup(t, r);
      await _hoseTo(t, r, _rightSlot(r));
      await _pickRight(t, L.whyRight[M7SpillWhy.drum]!);
      await _pump(t, 600);
      await _valve(t, r, open: true);
      expect(await _pumpWhile(t, () => r.puddleOn), isTrue);
      await t.pump(const Duration(milliseconds: 150));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his timer is 1.2–2.4 s');
      await t.longPressAt(r.puddleAt * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(r.soaked, 0, reason: 'the press that cut him in did nothing');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworker(r.deal.push).right);
      await _pump(t, 2600);
      await t.longPressAt(r.puddleAt * _k);
      await _pump(t, 400);
      expect(r.soaked, 1);
      await _close(t, c);
    });

    testWidgets('listening to the coworker: the ground slice, then a slip card (not deadly); one more pad is needed', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      await _setup(t, r);
      await _hoseTo(t, r, _rightSlot(r));
      await _pickRight(t, L.whyRight[M7SpillWhy.drum]!);
      await _pump(t, 600);
      await _valve(t, r, open: true);
      expect(await _pumpWhile(t, () => r.puddleOn), isTrue);
      final before = r.padsNeeded;
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final cw = L.coworker(r.deal.push);
      final wrongCards = _onScreen(cw.wrong);
      expect(wrongCards, isNotEmpty);
      await t.tap(wrongCards.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('slice')), findsOneWidget, reason: 'the consequence picture first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 2500);
      expect(find.byKey(const ValueKey('slice')), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.push(r.deal.push).textBn), findsOneWidget);
      expect(find.text(MistakeLines.deadlyHead), findsNothing);
      expect(r.padsNeeded, before + 1);
      expect(r.slips, 1);
      await _gotIt(t);
      await _soakAll(t, r);
      expect(r.soakedAll, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.push(r.deal.push).key);
      await _close(t, c);
    });

    testWidgets('the ◆ on the table and its reason deck: the scene takes no touch', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      await _setup(t, r, reason: false);
      await waitChoiceDeck(t);
      // The hose end cannot be dragged while the deck is up.
      final g = _geo(r);
      final a = g.hoseHome;
      await t.dragFrom(a * _k, (g.slot(_rightSlot(r)).center - a) * _k);
      await _pump(t, 300);
      expect(r.hoseSlot, isNull);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[M7SpillWhy.kit]!);
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep while the set-up waits, the pad nudge, the boom drag; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 7;
      final c = await _open(t, seed);
      final r = M7SpillBoomProbe.run!;
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the set-up');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // Three taps on nothing show it at once.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo(r).boomHintAt * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      await _setup(t, r, reason: false);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _close(t, c);
    });
  });
}
