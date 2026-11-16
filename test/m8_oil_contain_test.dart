// Lesson 8.9 কাজ 2 "এক ফোঁটাও মাটিতে নয়" (m8_oil_contain): the rules (গ্লাভস and
// the mask before the valve, the sheet over the drip zone, the oil into the
// drum, the cap twisted shut, the sealed drum to the disposal truck only; the
// puddle covered with sand or sawdust, never the hose or the broom, and not
// left to reach the floor drain; each battery to the recycler's van, not the
// scrap cart; the rake, the offcuts into the bag, 'সাফ' with one left; listening
// to him = a slip, never deadly: no deadly in 8.9, M8-1), the deal, the
// libraries, the coworker, and the level in the shell: the guide first, full
// clean plays with every reason and the coworker refused (at the drum and at the
// first handful), the slips, three slips, listening, his control waits for him
// on a fast play, the praise window takes no touch, and the gesture hand shows
// how (never what).
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
import 'package:slm_flutter/features/game/m8_oil_contain.dart';
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
  rungId: '8.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8OilContainPacks['do_8_9_b']!;
typedef L = M8OilContainLines;
typedef Mk = M8OilContainMistakes;
typedef St = M8Station;

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

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 10000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
}

bool _has(Finder f) => f.evaluate().isNotEmpty;
Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
const _sceneH = 360 * 850 / 392;
M8OilRun get _live => M8OilContainProbe.run!;

M8Geo _geoOf(M8Deal d, St s) => M8Geo.forScene(
      _sceneH.clamp(560.0, 900.0),
      0,
      flip: switch (s) {
        St.oil => d.valveFlip,
        St.store => d.storeFlip,
        _ => false,
      },
      fx: d.fx,
      fw: d.fw,
    );
M8Geo get _geo => _geoOf(_live.deal, _live.station);

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// The reason deck of the step just done: pick its right card.
Future<void> _reason(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _has(find.byType(ChoiceDeck))), isTrue, reason: 'the reason deck');
  await _pump(t, 400);
  await _pickRight(t, L.allWhyRight);
  await _pump(t, 1800);
}

/// Drag from a design point to another; the finger moves in ten steps.
Future<void> _drag(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Future<void> _tap(WidgetTester t, Offset p) async {
  await t.tapAt(p * _k);
  await _pump(t, 300);
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8OilContainPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8OilDeal(math.Random(s))));

// --- the plays ---------------------------------------------------------------------

/// The four sheet corners dragged out to cover the drip zone with a margin.
Future<void> _spread(WidgetTester t) async {
  final g = _geo;
  final z = g.zone.inflate(14);
  final targets = [z.topLeft, z.topRight, z.bottomRight, z.bottomLeft];
  for (var i = 0; i < 4; i++) {
    await _drag(t, g.sheetHome[i], targets[i]);
  }
}

Future<void> _wear(WidgetTester t, M8Kit k) async {
  final g = _geo;
  await _drag(t, g.kitHome(k), g.traineeRect.center);
}

/// The oil yard up to the valve open (kit with its reason, sheet, valve with its reason).
Future<void> _prepYard(WidgetTester t) async {
  await _wear(t, M8Kit.gloves);
  await _wear(t, M8Kit.mask);
  await _reason(t);
  await _spread(t);
  await _tap(t, _geo.valvePt);
  await _reason(t);
  expect(await _pumpUntil(t, () => _live.full, maxMs: 12000), isTrue, reason: 'the drum fills');
  await _pump(t, 300);
}

/// A finger round the cap, more than the dealt turns.
Future<void> _twist(WidgetTester t) async {
  final c = _geo.capCentre;
  const r = 20.0;
  final g = await t.startGesture((c + const Offset(r, 0)) * _k);
  final steps = (_live.deal.capTurns + 1) * 28;
  for (var i = 1; i <= steps && !_live.sealed; i++) {
    final a = i / 28 * 2 * math.pi;
    await g.moveTo((c + Offset(math.cos(a), math.sin(a)) * r) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

/// He comes (wait for him), the deck is up: refuse him.
Future<void> _refuse(WidgetTester t, M8Push p) async {
  expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 8000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

Future<void> _routeDrum(WidgetTester t, {M8Dest to = M8Dest.truck}) async {
  final g = _geo;
  final i = _live.deal.dests.indexOf(to);
  await _drag(t, g.drum.center, g.destSlot(i).center);
}

Future<void> _yard(WidgetTester t, {required bool refuse}) async {
  await _prepYard(t);
  await _twist(t);
  expect(_live.sealed, isTrue);
  if (refuse && !_live.deal.cwAtStore) await _refuse(t, _live.deal.push);
  await _routeDrum(t);
  expect(_live.routed, isTrue);
  await _reason(t);
}

Future<void> _flicks(WidgetTester t, {M8Mat? mat}) async {
  final g = _geo;
  final m = mat ?? _live.deal.mats.firstWhere((x) => x == M8Mat.sand || x == M8Mat.sawdust);
  await _tap(t, g.matSlot(_live.deal.mats.indexOf(m)).center);
  final c = g.puddleRect(_live.puddleS).center;
  await t.flingFrom((c + const Offset(0, -60)) * _k, const Offset(0, 60) * _k, 1200);
  await _pump(t, 500);
}

Future<void> _store(WidgetTester t, {required bool refuse}) async {
  if (refuse && _live.deal.cwAtStore) await _refuse(t, M8Push.hose);
  var guard = 0;
  while (!_live.covered && guard++ < 12) {
    await _flicks(t);
  }
  expect(_live.covered, isTrue);
  await _reason(t);
}

Future<void> _batteries(WidgetTester t) async {
  final g = _geo;
  for (var i = 0; i < _live.loaded.length; i++) {
    await _drag(t, g.batteryHome(i), g.vehicle(_live.deal.vanSlot).center);
  }
  expect(_live.batteriesDone, isTrue);
  await _reason(t);
}

Future<void> _grass(WidgetTester t) async {
  final g = _geo;
  final d = _live.deal;
  for (final o in d.offcuts) {
    final p = g.offcutAt(o.dx, o.dy);
    await _drag(t, p + const Offset(-30, 0), p + const Offset(30, 0));
  }
  expect(_live.revealed.every((x) => x), isTrue);
  for (var i = 0; i < d.offcuts.length; i++) {
    await _tap(t, g.offcutAt(d.offcuts[i].dx, d.offcuts[i].dy));
  }
  expect(_live.bagged.every((x) => x), isTrue);
  await _tap(t, g.sweepBtn.center);
  await _reason(t);
}

/// A whole clean play: every station, every reason, the coworker refused.
Future<void> _playAll(WidgetTester t, {bool refuse = true}) async {
  var guard = 0;
  while (!_live.finished && guard++ < 6) {
    final at = _live.ix;
    switch (_live.station) {
      case St.oil:
        await _yard(t, refuse: refuse);
      case St.store:
        await _store(t, refuse: refuse);
      case St.battery:
        await _batteries(t);
      case St.grass:
        await _grass(t);
    }
    if (_live.finished) break;
    expect(await _pumpUntil(t, () => _live.ix > at, maxMs: 4000), isTrue, reason: 'the next station');
    await _pump(t, 500);
  }
}

void _cover(M8OilRun r, M8Geo g) {
  final z = g.zone.inflate(14);
  final t = [z.topLeft, z.topRight, z.bottomRight, z.bottomLeft];
  for (var i = 0; i < 4; i++) {
    r.moveCorner(i, t[i], g);
  }
}

M8Deal _dealWith({List<St>? order, bool cwAtStore = false, int capTurns = 2, int flicks = 3, int band = 1, int batteries = 2, int offcuts = 3}) => M8Deal(
      order: order ?? const [St.oil, St.store, St.battery],
      valveFlip: false,
      fx: 0,
      fw: 0,
      capTurns: capTurns,
      fillSecs: 3,
      dests: const [M8Dest.drain, M8Dest.truck, M8Dest.field, M8Dest.store],
      mats: const [M8Mat.hose, M8Mat.sand, M8Mat.broom, M8Mat.sawdust],
      storeFlip: false,
      band: band,
      flicks: flicks,
      vanSlot: 1,
      batteries: batteries,
      offcuts: [for (var i = 0; i < offcuts; i++) Offset(0.1 + 0.25 * i, i.isEven ? 0.25 : 0.7)],
      cwAtStore: cwAtStore,
      push: cwAtStore ? M8Push.hose : M8Push.weed,
      dusk: false,
      whyRoll: 0,
      hintIx: 1,
    );

M8Geo _g0([bool flip = false]) => M8Geo.forScene(780, 0, flip: flip);

void main() {
  group('rules', () {
    test('deals: the oil yard and two of the other three, in dealt order; the coworker at the drum or (store dealt) the first handful; plays differ', () {
      final seen = <String>{};
      final orders = <String>{};
      var oilFirst = 0;
      var atStore = 0;
      var storeDealt = 0;
      final pairs = <String>{};
      for (var s = 0; s < 400; s++) {
        final d = m8OilDeal(math.Random(s));
        expect(d.order, hasLength(3));
        expect(d.order.toSet(), hasLength(3));
        expect(d.order, contains(St.oil));
        expect(d.order.indexOf(St.oil), anyOf(0, 1), reason: 'the yard first or second');
        if (d.order.first == St.oil) oilFirst++;
        if (d.has(St.store)) storeDealt++;
        if (d.cwAtStore) {
          atStore++;
          expect(d.has(St.store), isTrue, reason: 'store not dealt: he comes at the drum');
          expect(d.push, M8Push.hose);
        } else {
          expect(d.push, M8Push.weed);
        }
        expect(d.dests.toSet(), M8Dest.values.toSet());
        expect(d.mats.toSet(), M8Mat.values.toSet());
        expect(d.capTurns, inInclusiveRange(2, 3));
        expect(d.flicks, inInclusiveRange(3, 5));
        expect(d.batteries, inInclusiveRange(2, 3));
        expect(d.offcuts.length, inInclusiveRange(3, 5));
        for (var i = 0; i < d.offcuts.length; i++) {
          for (var j = i + 1; j < d.offcuts.length; j++) {
            final a = d.offcuts[i];
            final b = d.offcuts[j];
            expect(Offset((a.dx - b.dx) * 292, (a.dy - b.dy) * 110).distance, greaterThanOrEqualTo(56));
          }
        }
        orders.add(d.order.map((e) => e.index).join());
        pairs.add(d.order.where((x) => x != St.oil).map((e) => e.index).join());
        seen.add('${d.order.map((e) => e.index).join()}/${d.dests.map((e) => e.index).join()}/${d.mats.map((e) => e.index).join()}/${d.valveFlip}/${d.fx}/${d.capTurns}/${d.flicks}/${d.offcuts.length}');
      }
      expect(oilFirst, inInclusiveRange(150, 250));
      expect(atStore, inInclusiveRange(40, 160));
      expect(storeDealt, inInclusiveRange(220, 300));
      expect(orders.length, greaterThanOrEqualTo(8));
      expect(pairs.length, 6, reason: 'every pair of side stations, either order');
      expect(seen.length, greaterThan(380));
    });

    test('places: kit, sheet, valve, drum, cap, the four places, wall things, batteries, vehicles, grass, bag and button on the scene and clear of the guide corner', () {
      for (final h in [560.0, 640.0, 780.0, 900.0]) {
        for (final flip in [false, true]) {
          for (final (fx, fw) in [(0.0, 0.0), (12.0, 14.0)]) {
            final g = M8Geo.forScene(h, 0, flip: flip, fx: fx, fw: fw);
            final guide = Rect.fromLTRB(244, h - 8 - 168, 360, h);
            final scene = Rect.fromLTWH(0, 0, 360, h);
            final rects = <String, Rect>{
              'transformer': g.transformer,
              'valve': g.valveHit,
              'zone': g.zone,
              'van': g.van,
              'gloves': g.kitHit(g.glovesHome),
              'mask': g.kitHit(g.maskHome),
              'trainee': g.traineeRect,
              'stack': g.sheetStack,
              'drum': g.drumHit,
              'cap': g.capHit,
              for (var i = 0; i < 4; i++) 'dest$i': g.destSlot(i),
              for (var i = 0; i < 4; i++) 'mat$i': g.matSlot(i),
              'leak': g.leakDrum,
              'drain': g.floorDrain,
              'trolley': g.trolley,
              'veh0': g.vehicle(0),
              'veh1': g.vehicle(1),
              'grass': g.grass,
              'bag': g.bag,
              'sweep': g.sweepBtn,
            };
            rects.forEach((name, r) {
              expect(scene.contains(r.topLeft) && scene.contains(r.bottomRight), isTrue, reason: '$name $r on the scene at $h');
              expect(r.overlaps(guide), isFalse, reason: '$name $r clear of the guide corner at $h');
            });
            // The puddle's whole run stays on the floor and ends at the drain.
            final end = g.puddleRect(g.reachS);
            expect(g.floorDrain.inflate(8).overlaps(end), isTrue, reason: 'the front ends at the drain');
            // The drip zone's sample points are inside the sheet's reach.
            for (final p in g.zoneSamples) {
              expect(g.sheetBounds.contains(p), isTrue);
            }
            // Four destinations are distinct places.
            final slots = [for (var i = 0; i < 4; i++) g.destSlot(i)];
            for (var i = 0; i < 4; i++) {
              for (var j = i + 1; j < 4; j++) {
                expect(slots[i].overlaps(slots[j]), isFalse);
              }
              expect(g.destAt(slots[i].center), i);
            }
            // Batteries sit on the trolley; the vehicles are apart.
            for (var i = 0; i < 3; i++) {
              expect(g.trolley.contains(g.batteryHome(i)), isTrue);
            }
            expect(g.vehicle(0).overlaps(g.vehicle(1)), isFalse);
            expect(g.vehicleAt(g.vehicle(0).center), 0);
            expect(g.vehicleAt(g.vehicle(1).center), 1);
          }
        }
      }
    });

    test('hull: a sheet covers the drip zone only when every sample point is inside; a bow-tie order still judges by the hull', () {
      final g = _g0();
      final r = M8OilRun(_dealWith());
      expect(r.sheetCovers(g), isFalse, reason: 'folded at home');
      _cover(r, g);
      expect(r.sheetCovers(g), isTrue);
      // Swapped corners (a bow-tie) still cover.
      final c = r.corners!;
      final swap = c[1];
      c[1] = c[2];
      c[2] = swap;
      expect(r.sheetCovers(g), isTrue);
      // A small sheet misses a sample.
      final z = g.zone;
      final small = M8OilRun(_dealWith());
      small.moveCorner(0, z.topLeft, g);
      small.moveCorner(1, z.topCenter, g);
      small.moveCorner(2, z.center, g);
      small.moveCorner(3, z.centerLeft, g);
      expect(small.sheetCovers(g), isFalse);
      // One corner short of the far side.
      final short = M8OilRun(_dealWith());
      _cover(short, g);
      short.moveCorner(1, Offset(g.zone.left + 20, g.zone.top), g);
      short.moveCorner(2, Offset(g.zone.left + 20, g.zone.bottom), g);
      expect(short.sheetCovers(g), isFalse);
      // Corners stay on the ground.
      final k = M8OilRun(_dealWith());
      k.moveCorner(0, const Offset(-50, -50), g);
      expect(g.sheetBounds.contains(k.corners![0]), isTrue);
    });

    test('the valve: before গ্লাভস and the mask = the PCB slip and it stays shut; kit on but the sheet short = a slip (a stain), it stays shut; both right = the oil runs', () {
      final g = _g0();
      final r = M8OilRun(_dealWith());
      expect(r.tapValve(g), Mk.pcb);
      expect(r.valveOpen, isFalse);
      r.wear(M8Kit.gloves);
      expect(r.tapValve(g), Mk.pcb, reason: 'the mask too');
      expect((r.slips, r.valveWasOpen), (2, false));
      expect(r.wear(M8Kit.gloves), isFalse, reason: 'already on');
      r.wear(M8Kit.mask);
      expect(r.tapValve(g), Mk.sheet);
      expect((r.stain, r.valveWasOpen, r.slips), (true, false, 3));
      _cover(r, g);
      expect(r.tapValve(g), isNull);
      expect((r.valveOpen, r.valveWasOpen), (true, true));
      expect(r.caught, containsAll([L.caughtKit, L.caughtSheet]));
      // Locked now.
      expect(r.moveCorner(0, const Offset(100, 100), g), isFalse);
      expect(r.tapValve(g), isNull);
    });

    test('the oil runs into the drum and stops when it is full; the cap clicks after the dealt turns (back and forth cancels); a loose drum moved on = a slip', () {
      final g = _g0();
      for (final turns in [2, 3]) {
        final r = M8OilRun(_dealWith(capTurns: turns));
        r.wear(M8Kit.gloves);
        r.wear(M8Kit.mask);
        _cover(r, g);
        r.tapValve(g);
        var ticks = 0;
        while (!r.full && ticks++ < 100) {
          r.tickFill(0.1);
        }
        expect(ticks, inInclusiveRange(29, 32));
        expect((r.fill, r.valveOpen, r.stage), (1.0, false, M8Stage.seal));
        expect(r.tickFill(0.1), isFalse);
        expect(r.moveLoose(), Mk.loose);
        // A wobble does not seal.
        for (var i = 0; i < 20; i++) {
          r.turnCap(i.isEven ? 3.0 : -3.0);
        }
        expect(r.sealed, isFalse);
        r.capAngle = 0;
        var done = false;
        var n = 0;
        while (!done && n++ < 1000) {
          done = r.turnCap(0.1);
        }
        expect(n * 0.1, closeTo(turns * 2 * math.pi, 0.2));
        expect((r.sealed, r.stage), (true, M8Stage.route));
        expect(r.moveLoose(), isNull, reason: 'sealed: nothing sloshes');
      }
      // Nothing to turn before it is full.
      final e = M8OilRun(_dealWith());
      expect(e.turnCap(10), isFalse);
      expect(e.moveLoose(), isNull);
    });

    test('routing: the truck is right; the drain, the field and the back of the store are slips (the drum stays, still sealed); nothing before it is sealed', () {
      final r = M8OilRun(_dealWith());
      expect(r.routeTo(M8Dest.truck), isNull);
      expect(r.routed, isFalse);
      r.full = true;
      expect(r.routeTo(M8Dest.truck), isNull, reason: 'loose');
      r.sealed = true;
      for (final d in [M8Dest.drain, M8Dest.field, M8Dest.store]) {
        expect(r.routeTo(d), Mk.route);
      }
      expect((r.slips, r.routed, r.sealed), (3, false, true));
      expect(r.routeTo(M8Dest.truck), isNull);
      expect((r.routed, r.stationDone), (true, true));
      expect(r.caught, contains(L.caughtRoute));
      expect(M8OilRun(_dealWith(order: const [St.oil, St.store, St.battery])).lastStation, isFalse);
    });

    test('the store: sand or sawdust then handfuls cover it; the hose is a slip (the sheen runs, one more handful); the broom pushes it toward the drain = a slip; the first handful stops the spread', () {
      final g = _g0();
      final r = M8OilRun(_dealWith(order: const [St.store, St.oil, St.battery], flicks: 3));
      r.storeLive = true;
      expect(r.flick().landed, isFalse, reason: 'nothing in hand');
      expect(r.tapMat(M8Mat.hose), Mk.hose);
      expect((r.flicksNeeded, r.sheen), (4, true));
      expect(r.selected, isNull);
      expect(r.tapMat(M8Mat.broom), isNull);
      final before = r.puddleS;
      final f = r.flick();
      expect(f.slip, Mk.broom);
      expect(r.puddleS, greaterThan(before));
      expect(r.puddleS, lessThan(g.reachS), reason: 'the broom alone never reaches the drain');
      expect(r.selected, isNull);
      expect(r.tapMat(M8Mat.sawdust), isNull);
      r.tickPuddle(1, g);
      final s0 = r.puddleS;
      for (var i = 0; i < 4; i++) {
        final x = r.flick();
        expect(x.landed, isTrue);
        expect(x.covered, i == 3);
        if (i == 0) {
          r.tickPuddle(5, g);
          expect(r.puddleS, s0, reason: 'the first handful stops the spread');
        }
      }
      expect((r.covered, r.stationDone), (true, true));
      expect(r.caught, contains(L.caughtSand));
      expect(r.flick().landed, isFalse);
      expect(r.tapMat(M8Mat.hose), isNull, reason: 'done');
    });

    test('the puddle reaches the floor drain if left: one slip, then it stops there and can still be covered', () {
      final g = _g0();
      for (var band = 0; band < 3; band++) {
        final r = M8OilRun(_dealWith(band: band));
        r.storeLive = true;
        DoMistake? slip;
        var t = 0.0;
        while (slip == null && t < 40) {
          slip = r.tickPuddle(0.1, g).slip;
          t += 0.1;
        }
        expect(slip, Mk.drain);
        expect(t, inInclusiveRange(9, 18), reason: 'band $band: a dawdling player, not a fast one');
        expect((r.atDrain, r.slips), (true, 1));
        expect(r.tickPuddle(1, g).slip, isNull, reason: 'once');
        r.tapMat(M8Mat.sand);
        for (var i = 0; i < 3; i++) {
          r.flick();
        }
        expect(r.covered, isTrue);
      }
    });

    test('the battery room: the van takes each battery; the scrap cart is a slip and it stays; all in the van ends it', () {
      final r = M8OilRun(_dealWith(order: const [St.battery, St.oil, St.store], batteries: 3));
      expect(r.dropBattery(0, M8Veh.cart), Mk.cart);
      expect(r.loaded, [false, false, false]);
      expect(r.dropBattery(0, M8Veh.van), isNull);
      expect(r.dropBattery(0, M8Veh.van), isNull, reason: 'already gone');
      expect(r.batteriesDone, isFalse);
      r.dropBattery(1, M8Veh.van);
      r.dropBattery(2, M8Veh.van);
      expect((r.batteriesDone, r.stationDone), (true, true));
      expect(r.caught, contains(L.caughtBattery));
    });

    test('the grass: a rake pass uncovers what it passes; tap each into the bag; "সাফ" with one left = a slip (found or not); cows come a step closer with each step', () {
      final g = _g0();
      final r = M8OilRun(_dealWith(order: const [St.grass, St.oil, St.store], offcuts: 4));
      expect(r.cow, 0);
      expect(r.sweep(), Mk.offcut, reason: 'none found yet');
      final p0 = g.offcutAt(r.deal.offcuts[0].dx, r.deal.offcuts[0].dy);
      expect(r.rake(p0 + const Offset(m8RakeReach + 6, 0), g), 0, reason: 'a near miss');
      expect(r.rake(p0 + const Offset(m8RakeReach - 4, 0), g), 1);
      expect(r.rake(p0, g), 0, reason: 'already up');
      expect(r.cow, greaterThan(0));
      expect(r.bag(1), isFalse, reason: 'still hidden');
      expect(r.bag(0), isTrue);
      expect(r.bag(0), isFalse);
      for (var i = 1; i < 4; i++) {
        final p = g.offcutAt(r.deal.offcuts[i].dx, r.deal.offcuts[i].dy);
        r.rake(p, g);
      }
      expect(r.sweep(), Mk.offcut, reason: 'found but not in the bag');
      for (var i = 1; i < 4; i++) {
        r.bag(i);
      }
      expect(r.cow, 1.0);
      expect(r.sweep(), isNull);
      expect((r.clean, r.stationDone), (true, true));
      expect(r.caught, contains(L.caughtOffcut));
    });

    test('listening to him (X2/B1) is a slip — never deadly; the hose line also makes the spill bigger', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'no deadly in lesson 8.9 (M8-1, M8-6)');
      final r = M8OilRun(_dealWith());
      expect(r.listen(M8Push.weed), Mk.listenWeed);
      expect((r.slips, r.flicksNeeded), (1, 3));
      expect(r.listen(M8Push.hose), Mk.listenHose);
      expect((r.slips, r.flicksNeeded, r.sheen), (2, 4, true));
      expect(Mk.push(M8Push.weed).deadly, isFalse);
      expect(Mk.push(M8Push.hose).deadly, isFalse);
    });

    test('three slips: 55 and still a pass; four: 40', () {
      final g = _g0();
      final r = M8OilRun(_dealWith());
      for (var i = 0; i < 3; i++) {
        r.tapValve(g);
      }
      expect(r.percent, 55);
      r.finished = true;
      expect(r.passed, isTrue);
      r.tapValve(g);
      expect(r.percent, 40);
      expect(r.passed, isFalse);
    });

    test('the cow comes closer and the stages follow the play (every stage has a task line)', () {
      final r = M8OilRun(_dealWith());
      expect(r.stage, M8Stage.prep);
      for (final s in M8Stage.values) {
        expect(L.ask(s), isNotEmpty);
        expect(L.tasks, contains(L.ask(s)));
      }
      expect(L.lead(St.oil), '');
      for (final s in [St.store, St.battery, St.grass]) {
        expect(L.newGuideLines, contains(L.lead(s)));
      }
    });

    test('English digits only; jol not pani; no mrito; AB not closed; nukta as base + ়; every mistake has its picture and every picture is used; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.sceneLabel,
        L.truckPlate,
        L.vanPlate,
        L.sweepLabel,
        ...L.stationNames.values,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtKit,
        L.caughtSheet,
        L.caughtRoute,
        L.caughtSand,
        L.caughtBattery,
        L.caughtOffcut,
        L.caughtCall,
        L.leadStore,
        L.leadBattery,
        L.leadGrass,
      ];
      for (final l in all) {
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: 'nukta as base + ় : $l');
        expect(RegExp('(অন|অফ)(?![া-ৌ])').hasMatch(l.replaceAll('অনুর্বর', '').replaceAll('অনুমোদিত', '')), isFalse, reason: 'ON/OFF, not অন/অফ: $l');
        expect(RegExp('(এলটি|এইচটি|কেভি)').hasMatch(l), isFalse, reason: l);
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.9/m8_oil_contain/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: 'the reader has four 8.9 points');
        expect(m.deadly, isFalse);
      }
      const dir = 'assets/game/art/m8_oil_contain/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8OilContainPacks.keys, ['do_8_9_b']);
    });

    test('lesson text: the myth word for word; the plates, the sheet, the drum, PCBs, gloves and mask, sand and sawdust, the offcuts are in today\'s lesson 8.9', () {
      final raw = File('tool/all_training_chapters_bn.json').readAsStringSync().replaceAll('\u09DF', '\u09AF\u09BC').replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC');
      expect(raw.contains(L.coworkerWeed.line), isTrue);
      for (final q in [
        'ডিসপোজাল সেন্টারে পাঠাতে হয়',
        'প্লাস্টিক শিট বিছিয়ে নিন, যাতে এক ফোঁটা তেলও মাটিতে না পড়ে',
        'অথরাইজড রিসাইক্লার',
        'ড্রেনে বা মাঠে ফেলা আইনত দণ্ডনীয়',
        'গ্লাভস ও মাস্ক পরা বাধ্যতামূলক',
        'বালু বা কাঠের গুঁড়ো',
        'জল দিয়ে ধুবেন না, তাতে তেল আরও ছড়িয়ে পড়ে',
        'গরু-ছাগল এগুলো খেয়ে মারা যেতে পারে',
        'সীসা (Lead) এবং এসিড পরিবেশের জন্য মারাত্মক ক্ষতিকর',
        'মাটি চিরতরে অনুর্বর হয়ে যায় এবং ভূগর্ভস্থ জল দূষিত হয়',
        'PCBs',
      ]) {
        expect(raw.contains(q), isTrue, reason: q);
      }
      expect(L.truckPlate, 'ডিসপোজাল সেন্টার');
      expect(L.vanPlate, 'অথরাইজড রিসাইক্লার');
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M8Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final s in St.values) {
        expect(L.whyQ[m8StationWhy(s)], isNotEmpty);
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his two lines and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworkerWeed.line, L.coworkerHose.line]);
      expect(L.coworkerHose.line, 'জল দিয়ে ধুয়ে দাও, এক মিনিটে সাফ!');
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.tapWhy, ...L.whyQ.values, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      for (final p in M8Push.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
      }
      for (final c in L.allCoworkers) {
        for (final a in c.asks.where((a) => a != 'কী করবেন?' && a != 'ওর কথা শুনবেন, না নিয়ম?')) {
          expect(L.newGuideLines, contains(a));
        }
      }
      expect(LearnVoice.resolve(L.quick), isNotNull, reason: 'the quick line is already recorded');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_oil_contain: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the yard; the plates are not on screen before they are earned', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8OilContainPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 300);
      expect(_live.stage, anyOf(M8Stage.prep, M8Stage.store, M8Stage.battery, M8Stage.grass));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(_label(L.truckPlate), findsNothing, reason: 'the truck is not there before the drum is sealed');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, _seedWhere((d) => d.order.first == St.oil));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 300);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askPrep)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // Oil first, the store dealt with him at the first handful, grass third.
    final seedA = _seedWhere((d) => d.order[0] == St.oil && d.order[1] == St.store && d.order[2] == St.grass && d.cwAtStore);
    testWidgets('flow (seed $seedA): yard, store (he is refused at the first handful), grass → pass; every reason; stars saved', (t) async {
      final c = await _open(t, seedA);
      await _playAll(t);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['8.9/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['8.9/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtKit), findsOneWidget);
      expect(find.text(L.caughtRoute), findsOneWidget);
      expect(find.text(L.caughtSand), findsOneWidget);
      expect(find.text(L.caughtOffcut), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    // Battery first, the yard second (he comes at the sealed drum), grass third.
    final seedB = _seedWhere((d) => d.order[0] == St.battery && d.order[1] == St.oil && d.order[2] == St.grass);
    testWidgets('flow (seed $seedB): batteries, then the yard (he is refused at the sealed drum), then grass → pass', (t) async {
      final c = await _open(t, seedB);
      await _playAll(t);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['8.9/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtBattery), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      await _close(t, c);
    });

    // The store dealt, but he comes at the drum (store before the yard).
    final seedC = _seedWhere((d) => d.order[0] == St.store && d.order[1] == St.oil && !d.cwAtStore);
    testWidgets('flow (seed $seedC): the store first (no coworker there), then the yard with him at the drum, then the third → pass', (t) async {
      final c = await _open(t, seedC);
      await _playAll(t);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['8.9/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      await _close(t, c);
    });

    final yardFirst = _seedWhere((d) => d.order.first == St.oil);
    testWidgets('the valve before the kit: a PCB slip card (no freeze, not deadly), the valve stays shut', (t) async {
      final c = await _open(t, yardFirst);
      await _tap(t, _geo.valvePt);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.pcb.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.valveWasOpen, isFalse);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.pcb.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _gotIt(t);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('the kit on but the sheet short of the drip zone: a slip card, a stain, the valve stays shut; spread right, it runs', (t) async {
      final c = await _open(t, yardFirst);
      await _wear(t, M8Kit.gloves);
      await _wear(t, M8Kit.mask);
      await _reason(t);
      await _tap(t, _geo.valvePt);
      await _pump(t, 600);
      expect(find.text(Mk.sheet.textBn), findsOneWidget);
      expect(_live.stain, isTrue);
      expect(_live.valveWasOpen, isFalse);
      await _gotIt(t);
      await _spread(t);
      await _tap(t, _geo.valvePt);
      expect(_live.valveWasOpen, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.sheet.key);
      await _close(t, c);
    });

    testWidgets('a sheet corner dragged again moves it (re-drag any time before the oil); the oil locks the sheet', (t) async {
      final c = await _open(t, yardFirst);
      final g = _geo;
      await _drag(t, g.sheetHome[1], const Offset(200, 480));
      final first = _live.corners![1];
      await _drag(t, first, const Offset(220, 500));
      expect(_live.corners![1], isNot(first));
      expect(_live.corners![0], g.sheetHome[0], reason: 'the others stayed');
      await _close(t, c);
    });

    testWidgets('the drum moved on with the cap loose: a slip card and the drum stays; the cap turned shut by a circle, then it can go', (t) async {
      final c = await _open(t, yardFirst);
      await _prepYard(t);
      expect(_live.stage, M8Stage.seal);
      await _drag(t, _geo.drum.center + const Offset(0, 14), _geo.drum.center + const Offset(0, 90));
      expect(find.text(Mk.loose.textBn), findsOneWidget);
      expect(_live.sealed, isFalse);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.loose.key);
      await _gotIt(t);
      await _twist(t);
      expect(_live.sealed, isTrue);
      expect(_label(L.truckPlate), findsOneWidget, reason: 'the four places and the truck\'s plate come up');
      await _close(t, c);
    });

    final atDrum = _seedWhere((d) => d.order.first == St.oil && !d.cwAtStore);
    testWidgets('the sealed drum let go on the drain, the field or the store: a slip card, it comes back sealed; the truck is right', (t) async {
      final c = await _open(t, atDrum);
      await _prepYard(t);
      await _twist(t);
      await _refuse(t, M8Push.weed);
      await _routeDrum(t, to: M8Dest.field);
      expect(find.text(Mk.route.textBn), findsOneWidget);
      expect((_live.routed, _live.sealed), (false, true));
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.route.key);
      await _gotIt(t);
      await _routeDrum(t, to: M8Dest.truck);
      expect(_live.routed, isTrue);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, yardFirst);
      for (var i = 0; i < 2; i++) {
        await _tap(t, _geo.valvePt);
        await _gotIt(t);
      }
      await _tap(t, _geo.valvePt);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final storeLate = _seedWhere((d) => d.order[0] == St.store && !d.cwAtStore);
    testWidgets('the store (no coworker there): the hose is a slip card, leaving it reaches the drain (a second); then sand covers it', (t) async {
      final c = await _open(t, storeLate);
      final g = _geo;
      final d = _live.deal;
      await _tap(t, g.matSlot(d.mats.indexOf(M8Mat.hose)).center);
      expect(find.text(Mk.hose.textBn), findsOneWidget);
      expect(_live.flicksNeeded, d.flicks + 1);
      await _gotIt(t);
      // Left alone: the oil reaches the drain.
      expect(await _pumpUntil(t, () => _live.atDrain, maxMs: 40000), isTrue);
      await _pump(t, 600);
      expect(find.text(Mk.drain.textBn), findsOneWidget);
      await _gotIt(t);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).toSet(), {Mk.hose.key, Mk.drain.key});
      await _store(t, refuse: false);
      expect(_live.covered, isTrue);
      await _close(t, c);
    });

    testWidgets('the broom, then a flick at the puddle: a slip card and the oil is pushed toward the drain', (t) async {
      final c = await _open(t, storeLate);
      final before = _live.puddleS;
      await _flicks(t, mat: M8Mat.broom);
      expect(find.text(Mk.broom.textBn), findsOneWidget);
      expect(_live.puddleS, greaterThan(before));
      expect(_live.flicksDone, 0);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.broom.key);
      await _close(t, c);
    });

    testWidgets('a flick that misses the puddle, or a slow wave, throws nothing away and costs nothing', (t) async {
      final c = await _open(t, storeLate);
      final g = _geo;
      final d = _live.deal;
      await _tap(t, g.matSlot(d.mats.indexOf(M8Mat.sand == d.mats[0] ? M8Mat.sand : M8Mat.sawdust)).center);
      expect(_live.selected, isNotNull);
      // A fast flick far from the puddle.
      await t.flingFrom(Offset(180, g.gy - 10) * _k, const Offset(0, -80) * _k, 1200);
      await _pump(t, 400);
      expect(_live.flicksDone, 0);
      // A slow drag onto the puddle.
      final p = g.puddleRect(_live.puddleS).center;
      await _drag(t, p + const Offset(0, -40), p);
      expect(_live.flicksDone, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    final batSeed = _seedWhere((d) => d.order[0] == St.battery);
    testWidgets('the scrap cart: a slip card and the battery comes back; the recycler\'s van (its plate on it) takes it', (t) async {
      final c = await _open(t, batSeed);
      final g = _geo;
      final d = _live.deal;
      expect(_label(L.vanPlate), findsOneWidget);
      await _drag(t, g.batteryHome(0), g.vehicle(1 - d.vanSlot).center);
      expect(find.text(Mk.cart.textBn), findsOneWidget);
      expect(_live.loaded[0], isFalse);
      await _gotIt(t);
      await _drag(t, g.batteryHome(0), g.vehicle(d.vanSlot).center);
      expect(_live.loaded[0], isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.cart.key);
      await _close(t, c);
    });

    final grassSeed = _seedWhere((d) => d.order[0] == St.grass);
    testWidgets('the grass: "সাফ" with the offcuts still hidden is a slip card; raked up and bagged, it is right', (t) async {
      final c = await _open(t, grassSeed);
      final g = _geo;
      expect(_label(L.sweepLabel), findsOneWidget);
      await _tap(t, g.sweepBtn.center);
      expect(find.text(Mk.offcut.textBn), findsOneWidget);
      expect(_live.clean, isFalse);
      await _gotIt(t);
      final d = _live.deal;
      final o0 = g.offcutAt(d.offcuts[0].dx, d.offcuts[0].dy);
      await _drag(t, o0 + const Offset(-30, 0), o0 + const Offset(30, 0));
      expect(_live.revealed[0], isTrue);
      expect(_live.cow, greaterThan(0));
      await _tap(t, o0);
      expect(_live.bagged[0], isTrue);
      await _close(t, c);
    });

    final cwDrum = _seedWhere((d) => d.order.first == St.oil && !d.cwAtStore);
    testWidgets('listening to him at the drum (the myth): a slip with the pour picture — no freeze, not deadly; the drum is still there', (t) async {
      final c = await _open(t, cwDrum);
      await _prepYard(t);
      await _twist(t);
      expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 8000), isTrue);
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerWeed.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 700);
      expect(find.byKey(const ValueKey('act')), findsOneWidget, reason: 'the pour picture');
      await _pump(t, 2000);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listenWeed.key);
      expect(s.mistakes.single.deadly, isFalse);
      expect(_live.sealed && !_live.routed, isTrue);
      await _close(t, c);
    });

    final cwStore = _seedWhere((d) => d.order[0] == St.store && d.cwAtStore);
    testWidgets('listening to him at the first handful (the hose line): a slip with the hose picture; one more handful is needed', (t) async {
      final c = await _open(t, cwStore);
      final before = _live.flicksNeeded;
      expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 8000), isTrue);
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      await t.tap(_onScreen(L.coworkerHose.wrong).first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 2800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.listenHose.textBn), findsOneWidget);
      expect(_live.flicksNeeded, before + 1);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a fast play at the store: the first handful waits for him; he cuts in at once and the flick did nothing', (t) async {
      final c = await _open(t, cwStore);
      final g = _geo;
      final d = _live.deal;
      // Wait out his first arrival timer? No: be quick — pick the sand and flick now.
      await _tap(t, g.matSlot(d.mats.indexOf(d.mats.firstWhere((x) => x == M8Mat.sand || x == M8Mat.sawdust))).center);
      final p = g.puddleRect(_live.puddleS).center;
      await t.flingFrom((p + const Offset(0, -60)) * _k, const Offset(0, 60) * _k, 1200);
      await _pump(t, 300);
      expect(_has(find.byType(CoworkerPeek)), isTrue, reason: 'he cuts in');
      expect(_live.flicksDone, 0, reason: 'the flick did nothing');
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pickRight(t, L.coworkerHose.right);
      await _pump(t, 2600);
      await _flicks(t);
      expect(_live.flicksDone, greaterThan(0), reason: 'after him the flick works');
      await _close(t, c);
    });

    testWidgets('a fast play at the drum: dragging the sealed drum at once waits for him; he cuts in and the drum did not move', (t) async {
      final c = await _open(t, cwDrum);
      await _prepYard(t);
      await _twist(t);
      // The cap clicked; be quick before his timer: drag at once.
      await _routeDrum(t);
      expect(_has(find.byType(CoworkerPeek)), isTrue, reason: 'he cuts in');
      expect(_live.routed, isFalse, reason: 'the drag did nothing');
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pickRight(t, L.coworkerWeed.right);
      await _pump(t, 2600);
      await _routeDrum(t);
      expect(_live.routed, isTrue, reason: 'after him the drag works');
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch: the valve tapped over the open "কেন?" deck is no slip', (t) async {
      final c = await _open(t, yardFirst);
      await _wear(t, M8Kit.gloves);
      await _wear(t, M8Kit.mask);
      expect(_has(find.byType(ChoiceDeck)) || _live.kitReasoned, isTrue);
      await _tap(t, _geo.valvePt);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _reason(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle in the yard, a sweep over the kit, the valve and the folded sheet that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, yardFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the yard');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(scene().debugOptions, hasLength(4), reason: 'gloves, mask, valve and sheet alike');
      await _close(t, c);
    });

    testWidgets('gesture hand: the sealed drum gets a plain upward nudge (a drag hand, no sweep over the places)', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, cwDrum);
      await _prepYard(t);
      await _twist(t);
      await _refuse(t, M8Push.weed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, isEmpty, reason: 'one nudge on the drum, never toward a place');
      await _close(t, c);
    });

    testWidgets('gesture hand: the store waits with a sweep over the four wall things', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, storeLate);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, hasLength(4));
      await _close(t, c);
    });
  });
}
