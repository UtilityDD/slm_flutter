// Lesson 8.7 (ট্যারিফ অর্ডার), কাজ "বিলের সিঁড়ি": the rules (fixed charge on
// the floor; a block on step 1 while room remains; a block that would pass 102
// is cut where step 1 fills to exactly 102, the lower piece stays, the upper
// goes to step 2; once step 1 is full blocks go to step 2; MVCA on top; slips
// for step 2 early, a whole straddling block, a wrong or needless cut, the PF
// tile on the bill; the push: hold the part that explains, wrong part or the
// bin = slips; no deadly, ruling M8-1), the deal (three kinds, never twice in
// a row, a slab at least once, blocks that add up with the cut always 5 units
// from either end, PF on 1-2 doorsteps, the coworker on doorstep 2 or 3), the
// libraries, every spoken line listed, the drawn places, and the level in the
// shell: the guide first, a full clean play (tiles dragged, the cut, the hold,
// a reason pick, the coworker refused), slip cards, three slips, listening = a
// slip (no freeze), the hold and the bin wait for him, the praise window takes
// no touch, and the gesture hand shows how (never what) only while it waits.
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
import 'package:slm_flutter/features/game/m8_slab_stairs.dart';
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
  rungId: '8.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8SlabStairsPacks['do_8_7_a']!;
typedef L = M8SlabStairsLines;
typedef Mk = M8SlabStairsMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

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
M8StairsGeo get _geo => M8StairsGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8StairsRun get _live => M8SlabStairsProbe.run!;

Offset _zone(M8Zone z) => switch (z) {
      M8Zone.floor => _geo.floor.center,
      M8Zone.step1 => _geo.step1Col.center,
      M8Zone.step2 => _geo.step2Col.center,
      M8Zone.top => _geo.topBand.center,
      M8Zone.bin => _geo.bin.center,
      M8Zone.cutter => _geo.cutterPad.center,
      M8Zone.none => const Offset(300, 150),
    };

/// Drag a finger from [from] to [to] (design px).
Future<void> _drag(WidgetTester t, Offset from, Offset to, {bool settle = true, int steps = 8}) async {
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= steps; i++) {
    await g.moveTo(Offset.lerp(from, to, i / steps)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, settle ? 400 : 60);
}

/// Drag the tile in [slot] so that it ends over [zone].
Future<void> _dropTile(WidgetTester t, int slot, M8Zone zone, {bool settle = true}) =>
    _drag(t, _geo.slot(slot).center, _zone(zone).translate(0, M8StairsGeo.lift), settle: settle);

/// Drag the cutter's handle so [lower] units are on the lower piece.
Future<void> _cutAt(WidgetTester t, int lower) {
  final u = _live.cutter!.units;
  final x = _geo.ruler.left + lower / u * _geo.ruler.width;
  return _drag(t, Offset(_geo.ruler.left, _geo.ruler.center.dy), Offset(x, _geo.ruler.center.dy));
}

/// Press and hold a part of the tower.
Future<void> _hold(WidgetTester t, M8Part p) async {
  final g = await t.startGesture(_geo.partRect(p).center * _k);
  await _pump(t, 900);
  await g.up();
  await _pump(t, 300);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8SlabStairsPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8StairsDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8StairsDeal(math.Random(s))));

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// The next tile a clean player would take, and where it goes.
(int, M8Zone) _next(M8StairsRun r) {
  final up = r.upperSlot;
  if (up >= 0) return (up, M8Zone.step2);
  for (final i in r.trayIndexes) {
    final t = r.tray[i]!;
    if (t.kind == M8TileKind.fixed) return (i, M8Zone.floor);
    if (t.kind == M8TileKind.mvca) return (i, M8Zone.top);
  }
  for (final i in r.trayIndexes) {
    final t = r.tray[i]!;
    if (t.kind != M8TileKind.block) continue;
    if (r.fill1 + t.units <= kM8Step1Cap) return (i, M8Zone.step1);
    return (i, r.fill1 < kM8Step1Cap ? M8Zone.cutter : M8Zone.step2);
  }
  throw StateError('nothing left to place');
}

/// Build the tower of the doorstep on screen (clean), cutting where needed.
Future<void> _build(WidgetTester t) async {
  var guard = 0;
  while (!_live.pushing && guard++ < 30) {
    final (slot, zone) = _next(_live);
    final tile = _live.tray[slot]!;
    await _dropTile(t, slot, zone);
    if (zone == M8Zone.cutter) {
      expect(_live.cutter, tile, reason: 'the block is on the cutter');
      await _cutAt(t, kM8Step1Cap - _live.fill1);
      expect(_live.cutter, isNull);
      expect(_live.fill1, kM8Step1Cap, reason: 'the cut filled step 1');
    }
  }
  expect(_live.pushing, isTrue);
  expect(find.byType(MistakeCard), findsNothing);
}

/// One doorstep played clean: the tower, (him), the hold, the reason.
Future<void> _playDoor(WidgetTester t, {M8Kind? expectKind}) async {
  final i = _live.index;
  final kind = _live.door.kind;
  if (expectKind != null) expect(kind, expectKind);
  await _build(t);
  await _pump(t, 400);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
  await _hold(t, _live.door.answer);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.answered, isFalse, reason: 'the hold waited for him');
    await _refuse(t);
    await _hold(t, _live.door.answer);
  }
  expect(_live.answered, isTrue);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight(kind));
  await _pump(t, 2600);
  expect(_live.index, i + 1);
}

M8Doorstep _doorOf(M8Kind kind, List<M8Tile> tiles, {int units = 0, int? last}) {
  final slots = List<M8Tile?>.filled(8, null);
  for (var i = 0; i < tiles.length; i++) {
    slots[i] = tiles[i];
  }
  return M8Doorstep(kind: kind, units: units, last: last, tiles: slots, look: const M8Look(skin: 0, shirt: 0, hair: 0, elder: false, light: 0));
}

/// A run whose first doorstep is [first] (two more dealt after it).
M8StairsRun _runOf(M8Doorstep first) => M8StairsRun(M8StairsDeal(
      doorsteps: [first, m8DealDoorstep(M8Kind.closed, pf: false, rng: math.Random(1)), m8DealDoorstep(M8Kind.slab, pf: false, rng: math.Random(2))],
      coworkerStep: 1,
    ));

const _fixed = M8Tile(M8TileKind.fixed);
const _mvca = M8Tile(M8TileKind.mvca);
const _pf = M8Tile(M8TileKind.pf);
M8Tile _b(int u) => M8Tile(M8TileKind.block, units: u);

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.7');
}

void main() {
  group('rules', () {
    test('deals: three kinds, never twice in a row, a slab at least once; blocks add up; no subset near 102; PF on 1-2; him on 2 or 3; plays differ', () {
      final seen = <String>{};
      final kindsSeen = <M8Kind>{};
      var mvcaLow = 0, mvcaHigh = 0, slabs = 0;
      final lasts = <int>{};
      final blockCounts = <int>{};
      final pfCounts = <int>{};
      final him = <int>{};
      final cuts = <int>{};
      final firstKinds = <M8Kind>{};
      for (var s = 0; s < 400; s++) {
        final d = m8StairsDeal(math.Random(s));
        expect(d.doorsteps, hasLength(3));
        expect(d.coworkerStep, inInclusiveRange(1, 2));
        him.add(d.coworkerStep);
        firstKinds.add(d.doorsteps.first.kind);
        for (var i = 1; i < 3; i++) {
          expect(d.doorsteps[i].kind, isNot(d.doorsteps[i - 1].kind), reason: 'never the same kind twice in a row');
        }
        expect(d.doorsteps.any((x) => x.kind == M8Kind.slab), isTrue, reason: 'at least one slab');
        final pf = d.doorsteps.where((x) => x.hasPf).length;
        expect(pf, inInclusiveRange(1, 2));
        pfCounts.add(pf);
        for (final x in d.doorsteps) {
          kindsSeen.add(x.kind);
          expect(x.tiles, hasLength(8));
          expect(x.tiles.where((t) => t?.kind == M8TileKind.fixed), hasLength(1), reason: 'the fixed charge is always there');
          final blocks = x.blocks.map((b) => b.units).toList();
          expect(blocks.fold(0, (a, b) => a + b), x.units, reason: 'the blocks add up to this month');
          expect(x.hasMvca, x.kind == M8Kind.mvca);
          switch (x.kind) {
            case M8Kind.closed:
              expect(x.units, 0);
              expect(blocks, isEmpty);
              expect(x.last, isNull);
            case M8Kind.slab:
              slabs++;
              expect(x.last, isIn([80, 90, 100]));
              lasts.add(x.last!);
              expect(x.units, inInclusiveRange(136, 240));
              expect(blocks.length, inInclusiveRange(3, 4));
              expect(x.units, greaterThan(kM8Step1Cap));
              expect(m8ClearOf102(blocks), isTrue);
              // The one straddling block in any order: its cut sits 5+ from both ends.
              for (var mask = 1; mask < (1 << blocks.length); mask++) {
                var sum = 0;
                for (var j = 0; j < blocks.length; j++) {
                  if (mask & (1 << j) != 0) sum += blocks[j];
                }
                expect((sum - kM8Step1Cap).abs(), greaterThanOrEqualTo(5));
              }
              final r = M8StairsRun(M8StairsDeal(doorsteps: [x, x, x], coworkerStep: 1));
              var fill = 0;
              for (final b in blocks) {
                if (fill + b <= kM8Step1Cap) {
                  fill += b;
                } else {
                  cuts.add(kM8Step1Cap - fill);
                  break;
                }
              }
              expect(blocks.every((b) => b <= 110), isTrue, reason: 'block size is capped for the ruler');
              expect(r.tray, isNotEmpty);
            case M8Kind.mvca:
              expect(x.last, isNull);
              if (x.units <= kM8Step1Cap) {
                mvcaLow++;
                expect(blocks.length, inInclusiveRange(2, 3));
              } else {
                mvcaHigh++;
                expect(m8ClearOf102(blocks), isTrue);
              }
          }
          blockCounts.add(blocks.length);
          for (final b in blocks) {
            expect(b, greaterThanOrEqualTo(14));
          }
        }
        expect(d.doorsteps[d.coworkerStep].kind, isNot(M8Kind.closed), reason: 'his line is about the meter');
        seen.add('${d.coworkerStep}|${d.doorsteps.map((x) => '${x.kind.index}${x.units}${x.look.skin}${x.tiles.map((t) => t == null ? '-' : '${t.kind.index}${t.units}').join()}').join('|')}');
      }
      expect(seen.length, greaterThan(390));
      expect(kindsSeen, M8Kind.values.toSet());
      expect(firstKinds.length, greaterThan(1));
      expect(mvcaLow, greaterThan(40));
      expect(mvcaHigh, greaterThan(40));
      expect(slabs, greaterThan(400));
      expect(lasts, {80, 90, 100});
      expect(blockCounts, containsAll([0, 2, 3, 4]));
      expect(pfCounts, {1, 2});
      expect(him, {1, 2});
      expect(cuts.length, greaterThan(10), reason: 'a different cut each play');
      expect(m8KindOrders(), hasLength(m8KindOrders().toSet().length));
    });

    test('the fixed charge goes on the floor (0 units too); everywhere else it springs back at no cost', () {
      final r = _runOf(_doorOf(M8Kind.closed, [_fixed]));
      expect(r.dropTile(0, M8Zone.step1), (M8Drop.sprang, null));
      expect(r.dropTile(0, M8Zone.top), (M8Drop.sprang, null));
      expect(r.dropTile(0, M8Zone.none), (M8Drop.sprang, null));
      expect(r.slips, 0);
      expect(r.dropTile(0, M8Zone.bin), (M8Drop.slip, Mk.fixedToBin), reason: 'the bin is not a free probe');
      expect(r.slips, 1);
      expect(r.buildDone, isFalse);
      expect(r.dropTile(0, M8Zone.floor), (M8Drop.placed, null));
      expect(r.floorOn, isTrue);
      expect(r.buildDone, isTrue, reason: 'a closed house needs only its floor');
      r.startPush();
      expect(r.parts, [M8Part.floor]);
    });

    test('blocks: step 1 while room remains; whole straddler = slip; step 2 early = slip; cut at 102; then step 2', () {
      final r = _runOf(_doorOf(M8Kind.slab, [_b(70), _b(50), _b(45), _fixed], units: 165, last: 90));
      expect(r.dropTile(0, M8Zone.floor), (M8Drop.sprang, null), reason: 'a block is not the fixed charge');
      expect(r.dropTile(0, M8Zone.step2), (M8Drop.slip, Mk.step2Early), reason: 'step 1 has room');
      expect(r.dropTile(0, M8Zone.step1), (M8Drop.placed, null));
      expect(r.fill1, 70);
      expect(r.dropTile(1, M8Zone.step1), (M8Drop.slip, Mk.wholeOnStep1), reason: '70 + 50 passes 102');
      expect(r.dropTile(1, M8Zone.step2), (M8Drop.slip, Mk.step2Early), reason: 'step 1 still has room');
      expect(r.slips, 3);
      expect(r.tray[1], _b(50), reason: 'the block sprang back whole');
      // A wrong cut (off by 2) is a slip; the block goes back whole.
      expect(r.dropTile(1, M8Zone.cutter), (M8Drop.loaded, null));
      expect(r.cutter, _b(50));
      expect(r.dropTile(2, M8Zone.step1).$1, M8Drop.sprang, reason: 'the cutter holds the hand');
      expect(r.cut(30), (M8Cut.slip, Mk.wrongCut));
      expect(r.cutter, isNull);
      expect(r.tray[1], _b(50));
      expect(r.fill1, 70);
      expect(r.slips, 4);
      // Right: need 32; one unit off is still the cut.
      r.dropTile(1, M8Zone.cutter);
      expect(r.cut(0), (M8Cut.none, null), reason: 'let go at the end: nothing cut');
      expect(r.cut(50), (M8Cut.none, null));
      expect(r.cutter, _b(50), reason: 'still on the cutter');
      expect(r.cut(33), (M8Cut.cut, null));
      expect(r.step1, [70, 32]);
      expect(r.fill1, kM8Step1Cap, reason: 'exactly 102');
      expect(r.tray[1], const M8Tile(M8TileKind.block, units: 18, upper: true));
      expect(r.upperSlot, 1);
      expect(r.dropTile(1, M8Zone.step1), (M8Drop.slip, Mk.step1Full), reason: 'step 1 is full');
      expect(r.dropTile(1, M8Zone.step2), (M8Drop.placed, null));
      expect(r.step2, [18]);
      // Step 1 full: the last block goes to step 2; to step 1 it is a slip.
      expect(r.dropTile(2, M8Zone.step1), (M8Drop.slip, Mk.wholeOnStep1));
      expect(r.dropTile(2, M8Zone.cutter), (M8Drop.loaded, null));
      expect(r.cut(20), (M8Cut.slip, Mk.cutNotNeeded), reason: 'it fits a step whole');
      expect(r.dropTile(2, M8Zone.step2), (M8Drop.placed, null));
      expect(r.units2, 63);
      expect(r.fill1 + r.units2, 165);
      expect(r.buildDone, isFalse, reason: 'the fixed charge is still in the tray');
      expect(r.dropTile(3, M8Zone.floor), (M8Drop.placed, null));
      expect(r.buildDone, isTrue);
    });

    test('a block that fits needs no cut: cutting it is a slip, in any step state; blocks that fit go on step 1 in any order', () {
      final r = _runOf(_doorOf(M8Kind.mvca, [_b(30), _b(40), _fixed, _mvca], units: 70));
      r.dropTile(0, M8Zone.cutter);
      expect(r.cut(10), (M8Cut.slip, Mk.cutNotNeeded));
      expect(r.dropTile(1, M8Zone.step1), (M8Drop.placed, null));
      expect(r.dropTile(0, M8Zone.step1), (M8Drop.placed, null));
      expect(r.fill1, 70);
      expect(r.dropTile(2, M8Zone.floor).$1, M8Drop.placed);
      expect(r.buildDone, isFalse, reason: 'MVCA not on top yet');
      expect(r.dropTile(3, M8Zone.floor), (M8Drop.sprang, null));
      expect(r.dropTile(3, M8Zone.step1), (M8Drop.sprang, null));
      expect(r.dropTile(3, M8Zone.top), (M8Drop.placed, null));
      expect(r.topOn, isTrue);
      expect(r.buildDone, isTrue);
      expect(r.slips, 1);
      // Back off the cutter costs nothing.
      final c = _runOf(_doorOf(M8Kind.mvca, [_b(30), _fixed], units: 30));
      c.dropTile(0, M8Zone.cutter);
      c.cutBack();
      expect(c.tray[0], _b(30));
      expect(c.slips, 0);
    });

    test('during the build the bin costs: MVCA, a unit block and the fixed charge to the bin are slips; a full step 1 has its own card', () {
      final m = _runOf(_doorOf(M8Kind.mvca, [_b(40), _fixed, _mvca], units: 40));
      expect(m.dropTile(2, M8Zone.bin), (M8Drop.slip, Mk.mvcaToBin));
      expect(m.dropTile(0, M8Zone.bin), (M8Drop.slip, Mk.unitsToBin));
      expect(m.slips, 2);
      expect(m.tray[2], isNotNull, reason: 'it springs back');
      final f = _runOf(_doorOf(M8Kind.slab, [_b(60), _b(42), _b(50), _b(40), _fixed], units: 192, last: 90));
      f.dropTile(0, M8Zone.step1);
      f.dropTile(1, M8Zone.step1);
      expect(f.fill1, kM8Step1Cap);
      expect(f.dropTile(2, M8Zone.step1), (M8Drop.slip, Mk.step1Full));
    });

    test('the PF tile: on the bill = a slip (it bounces to the bin); in the bin or left in the tray costs nothing', () {
      final r = _runOf(_doorOf(M8Kind.closed, [_fixed, _pf]));
      expect(r.dropTile(1, M8Zone.none), (M8Drop.sprang, null));
      expect(r.dropTile(1, M8Zone.floor), (M8Drop.slip, Mk.pfOnBill));
      expect(r.tray[1], isNull, reason: 'bounced to the bin');
      expect(r.slips, 1);
      for (final z in [M8Zone.step1, M8Zone.step2, M8Zone.top, M8Zone.cutter]) {
        final x = _runOf(_doorOf(M8Kind.closed, [_fixed, _pf]));
        expect(x.dropTile(1, z), (M8Drop.slip, Mk.pfOnBill), reason: '$z');
      }
      final b = _runOf(_doorOf(M8Kind.closed, [_fixed, _pf]));
      expect(b.dropTile(1, M8Zone.bin), (M8Drop.discarded, null));
      expect(b.slips, 0);
      // Left in the tray: the build is done and the push clears it.
      final l = _runOf(_doorOf(M8Kind.closed, [_fixed, _pf]));
      l.dropTile(0, M8Zone.floor);
      expect(l.buildDone, isTrue);
      l.startPush();
      expect(l.tray.every((t) => t == null), isTrue);
    });

    test('the push: hold the part that explains; the wrong part, or any part to the bin = a slip; the answer is floor / step 2 / the MVCA band', () {
      // Slab: step 2 explains.
      final s = _runOf(_doorOf(M8Kind.slab, [_b(80), _b(70)], units: 150, last: 100));
      expect(s.door.answer, M8Part.step2);
      expect(s.hold(M8Part.step2), (M8Push.none, null), reason: 'no push yet');
      s.dropTile(0, M8Zone.step1);
      s.dropTile(1, M8Zone.cutter);
      s.cut(22);
      s.dropTile(1, M8Zone.step2);
      s.floorOn = true;
      expect(s.buildDone, isTrue);
      s.startPush();
      expect(s.parts, [M8Part.floor, M8Part.step1, M8Part.step2]);
      expect(s.hold(M8Part.top), (M8Push.none, null), reason: 'no such part');
      expect(s.hold(M8Part.floor), (M8Push.slip, Mk.wrongPartSlab));
      expect(s.hold(M8Part.step1), (M8Push.slip, Mk.wrongPartSlab));
      expect(s.toBin(M8Part.floor), (M8Push.slip, Mk.fixedToBin));
      expect(s.toBin(M8Part.step1), (M8Push.slip, Mk.unitsToBin));
      expect(s.toBin(M8Part.step2), (M8Push.slip, Mk.unitsToBin));
      expect(s.slips, 5);
      expect(s.hold(M8Part.step2), (M8Push.right, null));
      expect(s.answered, isTrue);
      expect(s.caught.single, L.caught(M8Kind.slab));
      // Closed: the floor. MVCA: the band.
      final c = _runOf(_doorOf(M8Kind.closed, [_fixed]));
      c.dropTile(0, M8Zone.floor);
      c.startPush();
      expect(c.toBin(M8Part.floor), (M8Push.slip, Mk.fixedToBin));
      expect(c.hold(M8Part.floor), (M8Push.right, null));
      final m = _runOf(_doorOf(M8Kind.mvca, [_b(40), _fixed, _mvca], units: 40));
      m.dropTile(0, M8Zone.step1);
      m.dropTile(1, M8Zone.floor);
      m.dropTile(2, M8Zone.top);
      m.startPush();
      expect(m.hold(M8Part.floor), (M8Push.slip, Mk.wrongPartMvca));
      expect(m.hold(M8Part.step1), (M8Push.slip, Mk.wrongPartMvca));
      expect(m.toBin(M8Part.top), (M8Push.slip, Mk.mvcaToBin));
      expect(m.hold(M8Part.top), (M8Push.right, null));
      expect(m.percent, 100 - 15 * 3);
    });

    test('no deadly in 8.7 (M8-1): every mistake a slip; keys, pictures, lesson points; listening = a slip; the art folder is all used', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      final r = _runOf(_doorOf(M8Kind.closed, [_fixed]));
      expect(r.pushSlip(), Mk.pushListen);
      expect(r.slips, 1);
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.7/m8_slab_stairs/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3), reason: 'lesson 8.7 has four numbered points');
      }
      expect(Mk.pushListen.lessonPoint, isNull, reason: 'a myth, not a numbered point');
      expect(Mk.fixedToBin.lessonPoint, 0, reason: 'the fixed charge is point 1');
      expect(Mk.step2Early.lessonPoint, 1, reason: 'the energy charge by slab is point 2');
      for (final p in M8Part.values) {
        expect(Mk.toBin(p).deadly, isFalse);
      }
      for (final k in M8Kind.values) {
        expect(Mk.wrongPart(k).deadly, isFalse);
      }
      const dir = 'assets/game/art/m8_slab_stairs/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8SlabStairsPacks.keys, ['do_8_7_a']);
      expect(Mk.all.length, 12);
    });

    test('the live lesson (X3): 102, the fixed charge, MVCA, PF and the myth quoted from the text', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      expect(kM8Step1Cap, 102);
      expect(text, contains(_nk('প্রথম ১০২ ইউনিট সস্তা')));
      expect(text, contains(_nk('এমনকি বাড়ি বন্ধ থাকলেও')));
      expect(text, contains(_nk('লোড বরাদ্দ রাখার জন্য এই টাকা দিতে হয়')));
      expect(text, contains(_nk('এটা মিটার রিডারের কারচুপি নয়, এটা সরকারি নিয়ম')));
      expect(text, contains(_nk('পাওয়ার ফ্যাক্টর (PF) কম হলে বিলে পেনাল্টি লাগে')));
      expect(text, contains(_nk('উপরের দিকের ইউনিটগুলোর দাম বেশি (Telescopic Tariff)')));
      expect(text, contains(_nk('সঠিক মাপাটা অপরাধ নয়')));
      expect(text, contains(_nk('ডিজিটাল মিটার বেশি ঘোরে, তাই বিল বেশি আসে')));
      expect(text, contains(_nk('পুরনো ইলেকট্রো-মেকানিক্যাল মিটার বয়সের ভারে স্লো হয়ে যেত')));
      expect(text, contains(_nk('মোবাইলে চার্জ দিলেও সেটা রেকর্ড করে')));
      // The explanation captions quote it.
      expect(L.explain(M8Kind.closed), contains('লোড বরাদ্দ রাখার জন্য এই টাকা দিতে হয়'));
      expect(L.explain(M8Kind.slab), allOf(contains('102'), contains('সস্তা'), contains('দামী')));
      expect(L.explain(M8Kind.mvca), allOf(contains('কয়লার দাম বাড়লে'), contains('সরকারি নিয়ম')));
      expect(text, contains(_nk('কয়লার দাম বাড়লে')));
      // The tile word follows the term rule (kVA in English letters).
      expect(L.fixedUnit, 'টাকা/kVA/মাস');
      expect(L.fixedUnit, isNot(contains('কেভিএ')));
      // The coworker's push carries myth 1.
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(_nk(L.coworker.line), contains(_nk('ডিজিটাল মিটার বেশি ঘোরে, তাই বিল বেশি আসে')));
      expect(_nk((myths[0] as Map)['myth'] as String), contains(_nk('ডিজিটাল মিটার বেশি ঘোরে')));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('সঠিক মাপাটা অপরাধ নয়')));
      expect(_nk(L.coworker.right.first), contains(_nk('সঠিক মাপাটা অপরাধ নয়')));
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ", LT/HT/kVA in English; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.fixedTile,
        L.fixedUnit,
        L.blockTile(137),
        L.pfTile,
        L.thisMonth(150),
        L.lastMonth(90),
        L.step1Label,
        L.step2Label,
        L.readout(32, 18),
        L.cutBack,
        for (final k in M8Kind.values) ...[L.doorName(k), L.complaint(k, 90, 170), L.push(k), L.explain(k), L.whyQ(k), ...L.whyRight(k), ...L.whyWrong(k), L.caught(k)],
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l); // the word, not কোম্পানি
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('(এলটি|এইচটি|কেভিএ|কেভি)').hasMatch(l), isFalse, reason: 'LT/HT/kVA in English letters: $l');
        expect(RegExp('(অন|অফ)(\\s|\$)').hasMatch(l), isFalse, reason: 'ON/OFF: $l');
        expect(RegExp('[\u09dc\u09dd\u09df]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expectSameLength('why', [...L.allWhyRight, ...L.allWhyWrong]);
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final k in M8Kind.values) {
        expectLibrary('why $k', L.whyRight(k), L.whyWrong(k));
        for (var i = 0; i < 12; i++) {
          final deal = dealChoices(L.whyRight(k), L.whyWrong(k), math.Random(i));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      // The tile and the block text show English digits.
      expect(L.blockTile(137), '137 ইউনিট');
      expect(L.step1Label, 'প্রথম 102 ইউনিট');
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['বলে দাও ডিজিটাল মিটার বেশি ঘোরে, তাই বিল বেশি আসে — ঝামেলা মিটে যাবে।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, for (final k in M8Kind.values) L.whyQ(k), L.askHim, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      expect(L.reused, containsAll(['ওকে কী বলবেন?', 'কী করবেন?']), reason: 'they already have a clip');
      expect(L.newGuideLines, isNot(contains('ওকে কী বলবেন?')));
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      // Every line the page speaks is in one of the lists.
      final spoken = L.spokenLines.toSet();
      for (final l in [
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.coworker.line,
        L.coworkerExit,
        ...L.coworker.asks,
        for (final k in M8Kind.values) L.whyQ(k),
        for (final m in Mk.all) m.textBn,
      ]) {
        expect(spoken, contains(l), reason: l);
      }
      // The customer's words and the lineman's note are silent captions (M8-10).
      for (final k in M8Kind.values) {
        expect(spoken, isNot(contains(L.push(k))));
        expect(spoken, isNot(contains(L.complaint(k, 90, 170))));
        expect(spoken, isNot(contains(L.explain(k))));
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_slab_stairs: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: tray slots and ruler stay in the tray; zones do not overlap; the board stays clear of the guide, the bin sits on the board', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M8StairsGeo.forScene(h, inset);
          expect(g.tray.bottom, lessThanOrEqualTo(h));
          for (var i = 0; i < 8; i++) {
            expect(g.tray.contains(g.slot(i).topLeft) && g.tray.contains(g.slot(i).bottomRight - const Offset(1, 1)), isTrue, reason: 'slot $i at $h');
            for (var j = i + 1; j < 8; j++) {
              expect(g.slot(i).overlaps(g.slot(j)), isFalse);
            }
            expect(g.slot(i).width, greaterThanOrEqualTo(80));
          }
          expect(g.ruler.left, greaterThanOrEqualTo(g.tray.left));
          expect(g.ruler.right, lessThanOrEqualTo(g.tray.right));
          expect(g.back.bottom, lessThanOrEqualTo(g.tray.bottom));
          expect(g.back.overlaps(g.ruler), isFalse);
          expect(g.readout.overlaps(g.ruler), isFalse);
          // The guide's corner square: x 244..360, 116 above the tray.
          final guide = Rect.fromLTRB(244, g.trayTop - 118, 360, g.trayTop);
          for (final r in [g.board, g.cutterPad, g.trainee, g.meterBox]) {
            expect(r.overlaps(guide), isFalse, reason: '$r at $h/$inset');
          }
          for (final r in [g.bill, g.caption, g.customer, g.board]) {
            expect(r.top, greaterThanOrEqualTo(140), reason: 'below the header');
            expect(r.right, lessThanOrEqualTo(360));
            expect(r.left, greaterThanOrEqualTo(0));
          }
          expect(g.customer.overlaps(g.bill), isFalse);
          expect(g.bill.overlaps(g.caption), isFalse);
          expect(g.caption.bottom, lessThan(g.board.top));
          expect(g.cutterPad.overlaps(g.trainee), isFalse);
          expect(g.trainee.overlaps(g.meterBox), isFalse);
          expect(g.board.bottom, lessThanOrEqualTo(g.cutterPad.top));
          // The zones inside the board, apart from each other.
          final zones = [g.topBand, g.floor, g.step1Col, g.step2Col, g.bin];
          for (final (i, a) in zones.indexed) {
            expect(g.board.contains(a.topLeft) && g.board.contains(a.bottomRight), isTrue, reason: 'zone $i');
            for (final b in zones.skip(i + 1)) {
              expect(a.inflate(2).overlaps(b.inflate(2)), isFalse, reason: 'zone $i / $b');
            }
          }
          expect(g.stackH, greaterThanOrEqualTo(90), reason: 'a readable staircase at $h');
          // Height shows cost: a step-2 unit is 2.2 times a step-1 unit.
          expect(g.u2 / g.u1, closeTo(2.2, 0.001));
          expect(g.step1Box.height, lessThan(g.step2Box.height));
          expect(g.step2Box.height * 150 / 160, greaterThan(150 * g.u2 - 0.01));
          // Every zone centre falls in its own zone.
          expect(g.zoneAt(g.floor.center), M8Zone.floor);
          expect(g.zoneAt(g.topBand.center), M8Zone.top);
          expect(g.zoneAt(g.step1Col.center), M8Zone.step1);
          expect(g.zoneAt(g.step2Col.center), M8Zone.step2);
          expect(g.zoneAt(g.bin.center), M8Zone.bin);
          expect(g.zoneAt(g.cutterPad.center), M8Zone.cutter);
          expect(g.zoneAt(const Offset(300, 150)), M8Zone.none);
          // The handle starts at the strip's left end; the strip is not on a tile.
          expect(g.handle(g.ruler.left).center.dx, g.ruler.left);
          expect(g.handle(0).center.dx, g.ruler.left, reason: 'clamped');
          // Resolution: a unit on the ruler is at least 2.5 dp for any block.
          expect(g.ruler.width / 120, greaterThan(2.5));
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

    testWidgets('the guide comes first: a tap does not skip him; then the tiles and the board', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8SlabStairsPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.boardLabel), findsOneWidget);
      expect(_label('${L.fixedTile} · ${L.fixedUnit}'), findsOneWidget);
      for (final tile in _live.tray.whereType<M8Tile>().where((x) => x.kind == M8TileKind.block)) {
        expect(_label(L.blockTile(tile.units)), findsWidgets);
      }
      expect(find.textContaining(L.complaint(_live.door.kind, _live.door.last ?? 0, _live.door.units)), findsOneWidget);
      expect(find.textContaining(RegExp('বাকি|ভুল')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the build tasks in turn, then the push tasks; never a part or a number', (t) async {
      final c = await _open(t, 5);
      expect(c.read(guideDirectorProvider).line, contains(L.askBuild));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.tapBuild1, L.tapBuild2]);
      for (final l in lines) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: 'no number named: $l');
      }
      await _close(t, c);
    });

    // His doorstep 2 and doorstep 3; every kind of doorstep gets played.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerStep == 1 && d.doorsteps.map((x) => x.kind).toSet().length == 3),
      _seedWhere((d) => d.coworkerStep == 2 && d.doorsteps.any((x) => x.kind == M8Kind.mvca && x.units > kM8Step1Cap) && d.doorsteps.any((x) => x.hasPf)),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three doorsteps, tiles dragged, the cut, the hold, reasons, he is refused → pass', (t) async {
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playDoor(t);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.7/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.7/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final slabFirst = _seedWhere((d) => d.doorsteps.first.kind == M8Kind.slab && d.doorsteps.first.hasPf);
    testWidgets('slips with their cards: step 2 early, a whole straddler, a wrong cut, the PF tile; the doorstep goes on; empty ground costs nothing', (t) async {
      final c = await _open(t, slabFirst);
      final blocks = [for (var i = 0; i < 8; i++) if (_live.tray[i]?.kind == M8TileKind.block) i];
      final pfSlot = _live.tray.indexWhere((x) => x?.kind == M8TileKind.pf);
      final big = blocks.firstWhere((i) => _live.tray[i]!.units > 30);
      // Empty ground: the tile springs back.
      await _dropTile(t, blocks.first, M8Zone.none);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await t.tapAt(_geo.slot(blocks.first).center * _k);
      await _pump(t, 200);
      expect(_live.slips, 0, reason: 'a tap is a miss, not an answer');
      // A block on step 2 while step 1 has room.
      await _dropTile(t, blocks.first, M8Zone.step2);
      expect(find.text(Mk.step2Early.textBn), findsOneWidget);
      expect(_live.step2, isEmpty);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // PF on the bill.
      await _dropTile(t, pfSlot, M8Zone.step1);
      expect(find.text(Mk.pfOnBill.textBn), findsOneWidget);
      expect(_live.tray[pfSlot], isNull);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 2);
      expect(_live.index, 0, reason: 'the same doorstep');
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).take(2), [Mk.step2Early.key, Mk.pfOnBill.key]);
      expect(big, isNonNegative);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('slips with their cards (second play): a whole straddler, then a wrong cut', (t) async {
      final c = await _open(t, slabFirst);
      final blocks = [for (var i = 0; i < 8; i++) if (_live.tray[i]?.kind == M8TileKind.block) i];
      for (final i in blocks) {
        if (_live.fill1 + _live.tray[i]!.units > kM8Step1Cap) {
          await _dropTile(t, i, M8Zone.step1);
          expect(find.text(Mk.wholeOnStep1.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          final u = _live.tray[i]!.units;
          final need = kM8Step1Cap - _live.fill1;
          await _dropTile(t, i, M8Zone.cutter);
          await _cutAt(t, need + 10 < u ? need + 10 : need - 10);
          expect(find.text(Mk.wrongCut.textBn), findsOneWidget);
          expect(_live.tray[i]?.units, u, reason: 'whole again');
          break;
        }
        await _dropTile(t, i, M8Zone.step1);
      }
      expect(_live.slips, 2);
      await _close(t, c);
    });

    testWidgets('press, pause 700 ms, then drag: the tile still lifts and lands (a slow hand)', (t) async {
      final c = await _open(t, slabFirst);
      final blocks = [for (var i = 0; i < 8; i++) if (_live.tray[i]?.kind == M8TileKind.block) i];
      final i = blocks.firstWhere((x) => _live.tray[x]!.units <= kM8Step1Cap);
      final from = _geo.slot(i).center;
      final to = _zone(M8Zone.step1).translate(0, M8StairsGeo.lift);
      final g = await t.startGesture(from * _k);
      await _pump(t, 700);
      for (var n = 1; n <= 8; n++) {
        await g.moveTo(Offset.lerp(from, to, n / 8)! * _k);
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 400);
      expect(_live.step1, isNotEmpty, reason: 'the slow drag was not eaten by a long press');
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (step 2 early); no deadly freeze', (t) async {
      final c = await _open(t, slabFirst);
      final blocks = [for (var i = 0; i < 8; i++) if (_live.tray[i]?.kind == M8TileKind.block) i];
      for (var i = 0; i < 3; i++) {
        await _dropTile(t, blocks[0], M8Zone.step2);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.7');
      expect(c.read(gameSaveProvider).mistakes.where((x) => x.deadly), isEmpty);
      await _close(t, c);
    });

    testWidgets('the push: the wrong part held, a part dragged to the bin = slips with their cards; the right part holds → note, ghost on a slab, reason', (t) async {
      final seed = _seedWhere((d) => d.coworkerStep == 2 && d.doorsteps.first.kind == M8Kind.slab);
      final c = await _open(t, seed);
      await _build(t);
      expect(_live.door.kind, M8Kind.slab);
      expect(find.text(L.pushSlab), findsOneWidget, reason: 'the customer pushes');
      // The wrong part held.
      await _hold(t, M8Part.floor);
      expect(find.text(Mk.wrongPartSlab.textBn), findsOneWidget);
      expect(_live.answered, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // The named part to the bin.
      await _drag(t, _geo.partRect(M8Part.step2).center, _geo.bin.center);
      expect(find.text(Mk.unitsToBin.textBn), findsOneWidget);
      expect(_live.step2, isNotEmpty, reason: 'the part stays');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // The right part: the note, last month's ghost, the reason.
      await _hold(t, M8Part.step2);
      expect(_live.answered, isTrue);
      expect(find.text(L.explain(M8Kind.slab)), findsOneWidget);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight(M8Kind.slab));
      await _pump(t, 2600);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.wrongPartSlab.key, Mk.unitsToBin.key]);
      await _close(t, c);
    });

    final hisSecond = _seedWhere((d) => d.coworkerStep == 1);
    testWidgets('listening to him = a slip (no freeze); the hold waited for him', (t) async {
      final c = await _open(t, hisSecond);
      await _playDoor(t);
      await _build(t);
      await _pump(t, 300);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
        // He came by himself before the hold: that is the same beat.
      } else {
        await _hold(t, _live.door.answer);
      }
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the hold waits for him');
      expect(_live.answered, isFalse);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushListen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushListen.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: the hold works now.
      await _hold(t, _live.door.answer);
      expect(_live.answered, isTrue);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _close(t, c);
    });

    testWidgets('the bin waits for him too: a part dragged there on his doorstep calls him in, nothing is binned', (t) async {
      final c = await _open(t, hisSecond);
      await _playDoor(t);
      await _build(t);
      if (find.byType(CoworkerPeek).evaluate().isEmpty) {
        await _drag(t, _geo.partRect(_live.door.answer).center, _geo.bin.center);
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(_live.slips, 0, reason: 'not binned yet');
      expect(find.byType(MistakeCard), findsNothing);
      await _refuse(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the next doorstep comes', (t) async {
      final seed = _seedWhere((d) => d.doorsteps.first.kind == M8Kind.closed);
      final c = await _open(t, seed);
      await _build(t);
      await _hold(t, M8Part.floor);
      expect(_live.answered, isTrue);
      // At once: a hold or a drag on the scene does nothing (shielded, then the deck).
      await _hold(t, M8Part.floor);
      await _drag(t, _geo.partRect(M8Part.floor).center, _geo.bin.center, settle: false);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight(M8Kind.closed));
      await _pump(t, 2600);
      expect(_live.index, 1);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the cutter: a block on it shows its ruler and a readout; back costs nothing; the cut line is never marked', (t) async {
      final seed = _seedWhere((d) => d.doorsteps.first.kind == M8Kind.slab);
      final c = await _open(t, seed);
      // Fill step 1 as far as a clean player goes; stop at the block to cut.
      var guard = 0;
      while (_next(_live).$2 != M8Zone.cutter && guard++ < 10) {
        final (slot, zone) = _next(_live);
        await _dropTile(t, slot, zone);
      }
      final (slot, _) = _next(_live);
      await _dropTile(t, slot, M8Zone.cutter);
      final u = _live.cutter!.units;
      expect(_live.cutter, isNotNull);
      expect(find.textContaining(L.readout(0, u)).evaluate().length + find.textContaining(L.readout(1, u - 1)).evaluate().length, greaterThan(0));
      expect(_label('কাটার কাঁচি'), findsOneWidget);
      // Back: the block returns, no slip.
      await t.tapAt(_geo.back.center * _k);
      await _pump(t, 400);
      expect(_live.cutter, isNull);
      expect(_live.tray[slot], isNotNull);
      expect(_live.slips, 0);
      // The handle dragged to mid-ruler shows the lower piece's units; let go at the very end: nothing.
      await _dropTile(t, slot, M8Zone.cutter);
      await _drag(t, Offset(_geo.ruler.left, _geo.ruler.center.dy), Offset(_geo.ruler.right + 20, _geo.ruler.center.dy));
      expect(_live.cutter, isNotNull, reason: 'let go at the end: nothing is cut');
      expect(_live.slips, 0);
      await _cutAt(t, kM8Step1Cap - _live.fill1);
      expect(_live.cutter, isNull);
      expect(_live.fill1, kM8Step1Cap);
      expect(_live.upperSlot, slot);
      await _close(t, c);
    });

    testWidgets('gesture hand: build idle → a sweep over all tiles, then a lift nudge; cutter → a nudge from the left end; upper piece → a lift nudge; the push → a sweep over parts and bin', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.doorsteps.first.kind == M8Kind.slab);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the tray full');
      expect(scene().debugOptions, hasLength(_live.trayIndexes.length), reason: 'every tile alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // A tile held hides the hand.
      final g = await t.startGesture(_geo.slot(_live.trayIndexes.first).center * _k);
      await _pump(t, 300);
      await g.moveBy(const Offset(0, -40));
      await _pump(t, 600);
      expect(scene().showing, isFalse);
      await g.up();
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      // Cutter loaded: a nudge, not a sweep.
      var guard = 0;
      while (_next(_live).$2 != M8Zone.cutter && guard++ < 10) {
        final (s, z) = _next(_live);
        await _dropTile(t, s, z);
      }
      final (cs, _) = _next(_live);
      await _dropTile(t, cs, M8Zone.cutter);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the cutter');
      expect(scene().debugOptions, isEmpty, reason: 'a drag nudge, no options');
      await _cutAt(t, kM8Step1Cap - _live.fill1);
      expect(_live.upperSlot, cs);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the upper piece waiting');
      expect(scene().debugOptions, isEmpty, reason: 'the same lift nudge');
      await _close(t, c);
    });

    testWidgets('gesture hand in the push: a sweep over every part of the tower and the bin, never a hold ring', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.doorsteps.first.kind == M8Kind.mvca && d.doorsteps.first.units > kM8Step1Cap);
      final c = await _open(t, seed);
      await _build(t);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the push');
      expect(scene().debugOptions, hasLength(_live.parts.length + 1), reason: 'every part and the bin');
      expect(scene().debugFrame?.ripple, isNull);
      await _close(t, c);
    });
  });
}
