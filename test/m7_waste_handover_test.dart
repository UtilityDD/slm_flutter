// Lesson 7.8 (পরিবেশগত আইন), কাজ 2 "ঠিক হাতে বর্জ্য": the rules (a lamp lifted
// by a hold and put in the padded box, released anywhere else it cracks; the
// oily waste in the red bin, the green bin a slip; each waste only on its own
// vehicle's bed — oil → recycler, battery and board → collection centre, the
// lamp box → disposal agency, the green bin → municipal truck — a wrong one
// comes back as a slip; anything to the unmarked van drives off with it; the
// van waved off with nothing is right; a legit vehicle sent off while its
// waste waits = one slip at the end; listening to him = a slip, never deadly:
// no deadly in 7.8, M7-6), the deal, the libraries, the coworker, the drawn
// places, and the level in the shell: the guide first, full clean plays with
// every reason and the coworker refused, three slips, listening, the unmarked
// van, the drag waits for him on a fast play, the praise window takes no
// touch, and the gesture hand shows how (never what).
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
import 'package:slm_flutter/features/game/m7_waste_handover.dart';
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
  rungId: '7.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7WasteHandoverPacks['do_7_8_b']!;
typedef L = M7WasteHandoverLines;
typedef Mk = M7WasteHandoverMistakes;
typedef W = M7Waste;
typedef V = M7Vehicle;
typedef Pc = M7Piece;
typedef Pl = M7Place;

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
M7HandGeo get _geo => M7HandGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7HandRun get _live => M7WasteHandoverProbe.run!;

/// The reason deck of the step just done: pick its right card.
Future<void> _reason(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _has(find.byType(ChoiceDeck))), isTrue, reason: 'the reason deck');
  final w = _live.why!;
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1800);
}

/// Carry a piece from a design point to another (released with the piece's
/// own centre on it); [hold] first holds a lamp until it lifts.
Future<void> _carry(WidgetTester t, Offset from, Offset to, {bool hold = false}) async {
  final g = await t.startGesture(from * _k);
  if (hold) await _pump(t, kM7LiftMs + 250);
  final target = to.translate(0, kM7HeldLift);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, target, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Offset _slotOf(W w) => _geo.slot(_live.deal.slotOf[w]!).center;

/// Lift a lamp (hold, then drag) and release it on [to].
Future<void> _lamp(WidgetTester t, W w, Offset to) => _carry(t, _slotOf(w), to, hold: true);

Future<void> _item(WidgetTester t, W w, Offset to) => _carry(t, _slotOf(w), to);

Offset _bin(M7BoxKind k) => switch (k) {
      M7BoxKind.lampBox => _geo.lampBox.center,
      M7BoxKind.redBin => _geo.redBin.center,
      M7BoxKind.greenBin => _geo.greenBin.center,
    };

Future<void> _yan(WidgetTester t) async {
  await t.tap(_label(L.yanTab), warnIfMissed: false);
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7WasteHandoverPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7HandDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7HandDeal(math.Random(s))));

/// Sort the trolley: every lamp into the box (its reason), the oily waste
/// into the red bin (its reason).
Future<void> _prep(WidgetTester t) async {
  for (final w in _live.deal.items.where((w) => w.kind == M7Kind.lamp)) {
    await _lamp(t, w, _bin(M7BoxKind.lampBox));
  }
  await _reason(t);
  for (final w in _live.deal.items.where((w) => w.kind == M7Kind.oily)) {
    await _item(t, w, _bin(M7BoxKind.redBin));
  }
  await _reason(t);
}

Future<void> _waitHere(WidgetTester t, {V? v}) async {
  expect(await _pumpUntil(t, () => _live.here && (v == null || _live.vehicle == v), maxMs: 12000), isTrue, reason: 'the vehicle pulls in ($v)');
  await _pump(t, 300);
}

Future<void> _refuse(WidgetTester t, M7HandPush p) async {
  expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// The vehicle at the bay: load what it takes (green bin or loose), send it off.
Future<void> _serve(WidgetTester t, {bool greenBin = true}) async {
  final v = _live.vehicle!;
  final bed = _geo.bed.center;
  switch (v) {
    case V.recycler:
      await _item(t, W.oilDrum, bed);
    case V.collection:
      for (final w in _live.deal.items.where((w) => w.kind == M7Kind.elec)) {
        await _item(t, w, bed);
      }
    case V.disposal:
      await _carry(t, _bin(M7BoxKind.lampBox), bed);
    case V.municipal:
      if (greenBin) {
        await _carry(t, _bin(M7BoxKind.greenBin), bed);
      } else {
        for (final w in _live.deal.items.where((w) => w.kind == M7Kind.general)) {
          await _item(t, w, bed);
        }
      }
    case V.unmarked:
      break;
  }
  await _yan(t);
  await _reason(t);
}

/// Everything up to the vehicle [target] standing at the bay (the others served).
Future<void> _until(WidgetTester t, V target) async {
  await _prep(t);
  for (final w in _live.deal.items.where((w) => w.kind == M7Kind.general)) {
    await _item(t, w, _bin(M7BoxKind.greenBin));
  }
  while (true) {
    await _waitHere(t);
    if (_live.vehicle == target) return;
    await _serve(t);
  }
}

/// A run already sorted: the vehicles may come (dealt as by [_dealOf]).
M7HandDeal _dealOf({List<V>? order, M7HandPush push = M7HandPush.myth}) => M7HandDeal(
      items: const [W.oilDrum, W.battery, W.board, W.tube, W.cfl, W.rags, W.pads, W.cups, W.paper],
      slotOf: {for (final (i, w) in W.values.indexed) w: i},
      order: order ?? const [V.recycler, V.collection, V.disposal, V.municipal, V.unmarked],
      push: push,
    );

M7HandRun _sorted({List<V>? order}) {
  final r = M7HandRun(_dealOf(order: order));
  for (final w in [W.tube, W.cfl]) {
    expect(r.drop(Pc.item(w), Pl.lampBox).kind, M7DropKind.placed);
  }
  r.paid();
  for (final w in [W.rags, W.pads]) {
    expect(r.drop(Pc.item(w), Pl.redBin).kind, M7DropKind.placed);
  }
  r.paid();
  expect(r.prepDone, isTrue);
  return r;
}

/// A sorted run with the first vehicle at the bay.
/// The reason paid and the next vehicle in at the bay.
void _go(M7HandRun r) {
  r.paid();
  r.advance();
  r.arrived();
}

M7HandRun _atBay({List<V>? order}) {
  final r = _sorted(order: order)
    ..startVehicles()
    ..arrived();
  return r;
}

void main() {
  group('rules', () {
    test('deals: always the oil drum, a lamp, a battery or board, an oily and a general item; cells distinct; plays differ', () {
      final seen = <String>{};
      var van = 0;
      final lampTypes = <W>{};
      final firstVehicles = <V>{};
      final pushes = <M7HandPush>{};
      for (var s = 0; s < 300; s++) {
        final d = m7HandDeal(math.Random(s));
        expect(d.items, contains(W.oilDrum));
        expect(d.items.where((w) => w.kind == M7Kind.lamp), isNotEmpty);
        expect(d.items.where((w) => w.kind == M7Kind.elec), isNotEmpty);
        expect(d.items.where((w) => w.kind == M7Kind.oily), isNotEmpty);
        expect(d.items.where((w) => w.kind == M7Kind.general), isNotEmpty);
        expect(d.items.toSet(), hasLength(d.items.length));
        expect(d.items.length, lessThanOrEqualTo(M7HandGeo.slots));
        expect(d.slotOf.values.toSet(), hasLength(d.items.length));
        expect(d.slotOf.values.every((c) => c >= 0 && c < M7HandGeo.slots), isTrue);
        expect(d.order.where((v) => v != V.unmarked).toSet(), {V.recycler, V.collection, V.disposal, V.municipal});
        expect(d.order.length, d.hasVan ? 5 : 4);
        if (d.hasVan) van++;
        lampTypes.addAll(d.items.where((w) => w.kind == M7Kind.lamp));
        firstVehicles.add(d.order.first);
        pushes.add(d.push);
        seen.add('${d.items.map((w) => w.index).join(',')}/${d.order.map((v) => v.index).join(',')}/${d.push.index}');
      }
      expect(van, inInclusiveRange(170, 230), reason: 'the unmarked van in about 2 plays of 3');
      expect(lampTypes, {W.tube, W.cfl, W.vapour});
      expect(firstVehicles.length, greaterThan(3));
      expect(pushes, M7HandPush.values.toSet());
      expect(seen.length, greaterThan(250));
    });

    test('places: every cell, container and the bay on the scene and clear of the guide corner; a release finds its own place', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M7HandGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(244, h - 8 - 168, 360, h);
        for (var i = 0; i < M7HandGeo.slots; i++) {
          final c = g.slot(i);
          expect(g.trolley.contains(c.center), isTrue, reason: 'h $h cell $i on the trolley');
          expect(c.right, lessThanOrEqualTo(g.trolley.right));
          expect(c.overlaps(guide), isFalse, reason: 'h $h cell $i clear of the guide');
          for (var j = i + 1; j < M7HandGeo.slots; j++) {
            expect(c.overlaps(g.slot(j)), isFalse);
          }
        }
        for (final b in [g.lampBox, g.redBin, g.greenBin]) {
          expect(b.overlaps(g.trolley), isFalse);
          expect(b.overlaps(guide), isFalse, reason: 'h $h box clear of the guide');
          expect(b.left >= 0 && b.right <= 360, isTrue);
        }
        expect(g.lampBox.overlaps(g.redBin), isFalse);
        expect(g.redBin.overlaps(g.greenBin), isFalse);
        expect(g.bay.bottom + 46, lessThan(g.rowTop), reason: 'h $h: the "যান" tab above the containers');
        expect(g.bed.top, greaterThan(g.bay.top));
        expect(g.bay.contains(g.bedItem(0).center) && g.bay.contains(g.bedItem(4).center), isTrue);
        expect(g.yan.height, greaterThanOrEqualTo(44));
        expect(g.placeAt(g.bed.center, bedOpen: true), Pl.bed);
        expect(g.placeAt(g.bed.center, bedOpen: false), Pl.none);
        expect(g.placeAt(g.lampBox.center, bedOpen: true), Pl.lampBox);
        expect(g.placeAt(g.redBin.center, bedOpen: true), Pl.redBin);
        expect(g.placeAt(g.greenBin.center, bedOpen: true), Pl.greenBin);
        expect(g.placeAt(g.slot(5).center, bedOpen: true), Pl.trolley);
        expect(g.placeAt(const Offset(350, 10), bedOpen: true), Pl.none);
      }
    });

    test('a lamp: boxed (the last one asks its reason), set back on the trolley safely, released anywhere else it cracks (a slip)', () {
      final r = M7HandRun(_dealOf());
      expect(r.drop(Pc.item(W.tube), Pl.trolley).kind, M7DropKind.back);
      expect(r.spot[W.tube], M7Spot.trolley);
      final first = r.drop(Pc.item(W.tube), Pl.lampBox);
      expect(first.kind, M7DropKind.placed);
      expect(r.why, isNull, reason: 'another lamp still lies loose');
      final crack = r.drop(Pc.item(W.cfl), Pl.none);
      expect((crack.kind, crack.mistake, crack.cracked), (M7DropKind.slip, Mk.lampCrack, true));
      expect(r.spot[W.cfl], M7Spot.cracked);
      expect(r.slips, 1);
      expect(r.why, isNull, reason: 'the last lamp cracked: nothing right to ask about');
      expect(r.prepDone, isFalse, reason: 'the oily waste still lies on the trolley');
      for (final t in [Pl.redBin, Pl.greenBin]) {
        final x = M7HandRun(_dealOf());
        expect(x.drop(Pc.item(W.tube), t).mistake, Mk.lampCrack, reason: '$t');
      }
      final ok = M7HandRun(_dealOf());
      ok.drop(Pc.item(W.tube), Pl.lampBox);
      final last = ok.drop(Pc.item(W.cfl), Pl.lampBox);
      expect(last.kind, M7DropKind.placed);
      expect(ok.why, M7HandWhy.lamps);
      expect(ok.whyDeparture, isFalse);
      expect(ok.caught, contains(L.caughtLamps));
      expect(ok.drop(Pc.item(W.rags), Pl.redBin).kind, M7DropKind.back, reason: 'the reason first');
    });

    test('oily waste: the red bin right (its reason after the last); the green bin a slip and it comes back; the rest goes nowhere', () {
      final r = M7HandRun(_dealOf());
      expect(r.drop(Pc.item(W.rags), Pl.greenBin).mistake, Mk.oilyGreen);
      expect(r.spot[W.rags], M7Spot.trolley, reason: 'it comes back');
      expect(r.drop(Pc.item(W.rags), Pl.redBin).kind, M7DropKind.placed);
      expect(r.why, isNull, reason: 'a second oily item still lies loose');
      expect(r.drop(Pc.item(W.pads), Pl.redBin).kind, M7DropKind.placed);
      expect(r.why, M7HandWhy.oily);
      expect(r.caught, contains(L.caughtOily));
      expect(r.slips, 1);
      final x = M7HandRun(_dealOf());
      expect(x.drop(Pc.item(W.rags), Pl.lampBox).kind, M7DropKind.back);
      expect(x.drop(Pc.item(W.rags), Pl.none).kind, M7DropKind.back);
      expect(x.drop(Pc.item(W.rags), Pl.bed).kind, M7DropKind.back, reason: 'no vehicle yet');
      expect(x.slips, 0);
    });

    test('the green bin: tea cups and paper may go in (nothing scored); oil, battery and board there are a slip', () {
      final r = M7HandRun(_dealOf());
      expect(r.drop(Pc.item(W.cups), Pl.greenBin).kind, M7DropKind.placed);
      expect(r.drop(Pc.item(W.paper), Pl.greenBin).kind, M7DropKind.placed);
      expect(r.why, isNull);
      expect(r.slips, 0);
      expect(r.drop(Pc.item(W.cups), Pl.redBin).kind, M7DropKind.back);
      for (final w in [W.oilDrum, W.battery, W.board]) {
        final x = M7HandRun(_dealOf());
        expect(x.drop(Pc.item(w), Pl.greenBin).mistake, Mk.hazGreen, reason: '$w');
        expect(x.spot[w], M7Spot.trolley);
      }
    });

    test('sorting done: lamps boxed or cracked and the oily waste in the red bin; then the vehicles, one at a time', () {
      final r = _sorted();
      expect(r.stage, M7HandStage.prep);
      expect(r.vehicle, isNull);
      r.startVehicles();
      expect((r.stage, r.vehicle, r.here), (M7HandStage.vehicle, V.recycler, false));
      expect(r.drop(Pc.item(W.oilDrum), Pl.bed).kind, M7DropKind.back, reason: 'still pulling in');
      r.arrived();
      expect(r.here, isTrue);
    });

    test('each waste on its own vehicle: loaded; "যান" with a load is right (its reason); the next vehicle comes', () {
      final cases = <(V, List<Pc>, String, M7HandWhy)>[
        (V.recycler, [const Pc.item(W.oilDrum)], L.caughtOil, M7HandWhy.oil),
        (V.collection, [const Pc.item(W.battery), const Pc.item(W.board)], L.caughtElec, M7HandWhy.elec),
        (V.disposal, [const Pc.box(M7PieceKind.lampBox)], L.caughtBox, M7HandWhy.box),
      ];
      for (final (v, pieces, tag, why) in cases) {
        final r = _atBay(order: [v, V.municipal]);
        for (final p in pieces) {
          expect(r.drop(p, Pl.bed).kind, M7DropKind.loaded, reason: '$v');
        }
        expect(r.bed, isNotEmpty);
        expect(r.slips, 0);
        final d = r.depart()!;
        expect(d.why, why);
        expect((r.why, r.whyDeparture, r.here), (why, true, false));
        expect(r.caught, contains(tag));
        expect(r.paid(), isTrue);
        r.advance();
        expect((r.vehicle, r.bed.length), (V.municipal, 0));
      }
      // The municipal truck takes the green bin, or loose cups and paper.
      for (final loose in [false, true]) {
        final r = _atBay(order: [V.municipal]);
        if (loose) {
          expect(r.drop(const Pc.item(W.cups), Pl.bed).kind, M7DropKind.loaded);
          expect(r.drop(const Pc.item(W.paper), Pl.bed).kind, M7DropKind.loaded);
        } else {
          r.drop(const Pc.item(W.cups), Pl.greenBin);
          r.drop(const Pc.item(W.paper), Pl.greenBin);
          expect(r.drop(const Pc.box(M7PieceKind.greenBin), Pl.bed).kind, M7DropKind.loaded);
          expect(r.at(M7Spot.greenBin), isEmpty);
        }
        expect(r.bed.toSet(), {W.cups, W.paper});
        expect(r.depart()!.why, M7HandWhy.general);
        expect(r.caught, contains(L.caughtGeneral));
      }
    });

    test('a waste on the wrong vehicle: the right slip per waste, it comes back, the vehicle stays; hazardous on the municipal truck', () {
      final byClass = <W, Map<V, DoMistake>>{
        W.oilDrum: {V.collection: Mk.wrongOil, V.disposal: Mk.wrongOil, V.municipal: Mk.hazMunicipal},
        W.battery: {V.recycler: Mk.wrongElec, V.disposal: Mk.wrongElec, V.municipal: Mk.hazMunicipal},
        W.board: {V.recycler: Mk.wrongElec, V.disposal: Mk.wrongElec, V.municipal: Mk.hazMunicipal},
        W.cups: {V.recycler: Mk.wrongGeneral, V.collection: Mk.wrongGeneral, V.disposal: Mk.wrongGeneral},
      };
      for (final e in byClass.entries) {
        for (final f in e.value.entries) {
          final r = _atBay(order: [f.key]);
          final d = r.drop(Pc.item(e.key), Pl.bed);
          expect((d.kind, d.mistake), (M7DropKind.slip, f.value), reason: '${e.key} on ${f.key}');
          expect(r.spot[e.key], M7Spot.trolley, reason: 'it comes back');
          expect((r.here, r.bed.length, r.slips), (true, 0, 1));
        }
      }
      // The lamp box and the bins as whole pieces.
      final box = _atBay(order: [V.recycler]);
      expect(box.drop(const Pc.box(M7PieceKind.lampBox), Pl.bed).mistake, Mk.wrongLamp);
      expect(box.at(M7Spot.lampBox), hasLength(2));
      final red = _atBay(order: [V.collection]);
      expect(red.drop(const Pc.box(M7PieceKind.redBin), Pl.bed).mistake, Mk.wrongRed);
      final redM = _atBay(order: [V.municipal]);
      expect(redM.drop(const Pc.box(M7PieceKind.redBin), Pl.bed).mistake, Mk.hazMunicipal);
      final boxM = _atBay(order: [V.municipal]);
      expect(boxM.drop(const Pc.box(M7PieceKind.lampBox), Pl.bed).mistake, Mk.hazMunicipal);
      // An empty bin goes nowhere and costs nothing.
      final empty = _atBay(order: [V.municipal]);
      expect(empty.drop(const Pc.box(M7PieceKind.greenBin), Pl.bed).kind, M7DropKind.back);
      expect(empty.slips, 0);
      // A loose lamp can never be handed over: it cracks (and is gone).
      final lamp = M7HandRun(_dealOf())..startVehicles();
      lamp.arrived();
      expect(lamp.drop(const Pc.item(W.tube), Pl.bed).mistake, Mk.lampCrack);
    });

    test('the unmarked van: anything given drives off with it (a slip, the waste lost); waved off with nothing is right (its reason)', () {
      final r = _atBay(order: [V.unmarked, V.recycler]);
      final d = r.drop(const Pc.item(W.oilDrum), Pl.bed);
      expect((d.kind, d.mistake), (M7DropKind.vanLeaves, Mk.vanTake));
      expect((r.spot[W.oilDrum], r.here, r.slips), (M7Spot.lost, false, 1));
      r.advance();
      expect(r.vehicle, V.recycler);
      // Waving it off: right.
      final w = _atBay(order: [V.unmarked]);
      final x = w.depart()!;
      expect((x.why, w.why, w.whyDeparture), (M7HandWhy.van, M7HandWhy.van, true));
      expect(w.caught, contains(L.caughtVan));
      expect(w.slips, 0);
      // A whole container too.
      final b = _atBay(order: [V.unmarked]);
      expect(b.drop(const Pc.box(M7PieceKind.lampBox), Pl.bed).mistake, Mk.vanTake);
      expect(b.at(M7Spot.lost), hasLength(2));
    });

    test('a legit vehicle waved off with its waste waiting: nothing now, one slip at the end; a partial load still counts for what it carries', () {
      final r = _atBay(order: [V.recycler, V.collection]);
      final d = r.depart()!;
      expect(d.why, isNull);
      expect((r.why, r.slips), (null, 0));
      expect(r.wavedEmpty, [V.recycler]);
      r.advance();
      r.arrived();
      r.drop(const Pc.item(W.battery), Pl.bed);
      expect(r.depart()!.why, M7HandWhy.elec, reason: 'the battery went: right for what it carries');
      r.paid();
      r.advance();
      expect(r.allGone, isTrue);
      expect(r.pending, [W.oilDrum, W.board, W.tube, W.cfl, W.cups, W.paper]);
      expect(r.finalCheck(), Mk.undelivered);
      expect(r.finalCheck(), isNull, reason: 'one slip in total');
      expect((r.done, r.slips, r.passed), (true, 1, true));
    });

    test('a clean play: nothing pending, no end slip; the green bin may stay empty only when nothing general waits', () {
      final r = _atBay(order: [V.recycler, V.collection, V.disposal, V.municipal]);
      r.drop(const Pc.item(W.cups), Pl.greenBin);
      for (final step in [
        [const Pc.item(W.oilDrum)],
        [const Pc.item(W.battery), const Pc.item(W.board)],
        [const Pc.box(M7PieceKind.lampBox)],
        [const Pc.box(M7PieceKind.greenBin), const Pc.item(W.paper)],
      ]) {
        for (final p in step) {
          expect(r.drop(p, Pl.bed).kind, M7DropKind.loaded);
        }
        expect(r.depart()!.why, isNotNull);
        _go(r);
      }
      expect(r.pending, isEmpty);
      expect(r.finalCheck(), isNull);
      expect((r.slips, r.percent, r.passed), (0, 100, true));
      expect(r.caught, containsAll([L.caughtOil, L.caughtElec, L.caughtBox, L.caughtGeneral, L.caughtLamps, L.caughtOily]));
      // Cups left loose when the municipal truck went: undelivered.
      final m = _atBay(order: [V.municipal]);
      m.depart();
      m.paid();
      m.advance();
      expect(m.pending, containsAll([W.cups, W.paper]));
      expect(m.finalCheck(), Mk.undelivered);
    });

    test('listening to him (X2/B1) is a slip — never deadly; the dealt hazardous item goes onto the municipal truck', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'no deadly in lesson 7.8 (M7-6)');
      // The battery first (still on the trolley).
      final r = _atBay(order: [V.municipal]);
      expect(r.listen(), Mk.listen);
      expect(r.slips, 1);
      expect(r.spot[W.battery], M7Spot.lost);
      expect(r.dumped, [W.battery]);
      // No loose electronics: the lamp box goes.
      final b = _atBay(order: [V.collection, V.municipal]);
      b.drop(const Pc.item(W.battery), Pl.bed);
      b.drop(const Pc.item(W.board), Pl.bed);
      b.depart();
      _go(b);
      b.listen();
      expect(b.dumped.toSet(), {W.tube, W.cfl});
      // Nothing else: the red bin's waste.
      final c = _atBay(order: [V.collection, V.disposal, V.recycler, V.municipal]);
      c.drop(const Pc.item(W.battery), Pl.bed);
      c.drop(const Pc.item(W.board), Pl.bed);
      c.depart();
      _go(c);
      c.drop(const Pc.box(M7PieceKind.lampBox), Pl.bed);
      c.depart();
      _go(c);
      c.drop(const Pc.item(W.oilDrum), Pl.bed);
      c.depart();
      _go(c);
      c.listen();
      expect(c.dumped.toSet(), {W.rags, W.pads});
      // The truck still waits for the green bin afterwards.
      expect(r.drop(const Pc.item(W.cups), Pl.bed).kind, M7DropKind.loaded);
    });

    test('three slips: 55; four: 40', () {
      final r = M7HandRun(_dealOf());
      for (var i = 0; i < 3; i++) {
        r.drop(const Pc.item(W.rags), Pl.greenBin);
      }
      expect(r.percent, 55);
      r.drop(const Pc.item(W.rags), Pl.greenBin);
      expect(r.percent, 40);
    });

    test('English digits only; jol not pani; no mrito; every mistake has its picture and every picture is used; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.liftHow,
        L.sceneLabel,
        L.yanTab,
        for (final w in W.values) L.waste(w),
        for (final v in V.values) L.vehicleLabel(v),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M7HandPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtLamps,
        L.caughtOily,
        L.caughtOil,
        L.caughtElec,
        L.caughtBox,
        L.caughtGeneral,
        L.caughtVan,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp('(?<![ঀ-৿])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta as base + ় : $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.8/m7_waste_handover/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m7_waste_handover/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7WasteHandoverPacks.keys, ['do_7_8_b']);
      expect(M7HandSigns.of(V.unmarked), isNull, reason: 'the unmarked van has no board');
      for (final v in V.values.where((v) => v != V.unmarked)) {
        expect(M7HandSigns.of(v), isNotEmpty);
      }
    });

    test('lesson text: myth 2 word for word; the boards and the quoted rules are in today\'s lesson 7.8', () {
      final raw = File('tool/all_training_chapters_bn.json').readAsStringSync().replaceAll('য়', 'য়').replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');
      expect(raw.contains(L.coworkerMyth.line), isTrue);
      for (final s in [M7HandSigns.recycler, M7HandSigns.disposal]) {
        expect(raw.contains(s.replaceAll('অনুমোদিত ', '')) || raw.contains(s), isTrue, reason: s);
      }
      for (final q in [
        'অনুমোদিত রিসাইক্লিং এজেন্সির কাছে',
        'কোম্পানির নির্ধারিত সংগ্রহ কেন্দ্রে',
        'অনুমোদিত ডিসপোজাল এজেন্সির কাছে',
        'না ভেঙে সাবধানে',
        'সাধারণ ময়লার সাথে ফেলা যাবে না',
        'তেল-মাখা কাপড়',
        'ব্যক্তিগতভাবে এবং কোম্পানি',
      ]) {
        expect(raw.contains(q), isTrue, reason: q);
      }
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7HandWhy.values) {
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

    test('rival lines: his exit is recorded; his two lines and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'পরিবেশের আইন তো শুধু বড় বড় ফ্যাক্টরির জন্য, আমাদের এসব মানার দরকার নেই।',
        'অত ঝামেলা কেন? সব এই ময়লার গাড়িতেই তুলে দাও।',
      ]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, L.liftHow, ...L.whyQ.values, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      for (final p in M7HandPush.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
      }
      for (final c in L.allCoworkers) {
        for (final a in c.asks.where((a) => a != 'কী করবেন?' && a != 'ওর কথা শুনবেন, না নিয়ম?')) {
          expect(L.newGuideLines, contains(a));
        }
      }
      expect(LearnVoice.resolve(L.quick), isNotNull, reason: 'the quick line is already recorded');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_waste_handover: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the yard, the waste unlabelled', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7WasteHandoverPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 300);
      expect(_live.stage, M7HandStage.prep);
      expect(_label(L.waste(W.oilDrum)), findsOneWidget);
      expect(_label(L.lampBoxLabel), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      for (final v in V.values) {
        expect(_label(L.vehicleLabel(v)), findsNothing, reason: 'no vehicle before the sorting');
      }
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
        await _pump(t, 300);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.taskPrep)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final vanSeed = _seedWhere((d) => d.hasVan && d.push == M7HandPush.myth);
    testWidgets('flow (seed $vanSeed): sort, every vehicle served, the van waved off, he is refused at the municipal truck → pass', (t) async {
      final c = await _open(t, vanSeed);
      await _prep(t);
      expect(_live.stage, M7HandStage.vehicle, reason: 'sorted: the vehicles come');
      for (final w in _live.deal.items.where((w) => w.kind == M7Kind.general)) {
        await _item(t, w, _bin(M7BoxKind.greenBin));
      }
      var refused = false;
      while (!_live.done) {
        await _waitHere(t);
        expect(_label(L.vehicleLabel(_live.vehicle!)), findsOneWidget);
        if (_live.vehicle == V.municipal) {
          await _refuse(t, _live.deal.push);
          refused = true;
        }
        await _serve(t);
        await _pump(t, 800);
      }
      expect(refused, isTrue);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      debugPrint('DBG slips=${_live.slips} pending=${_live.pending} stage=${_live.stage} mistakes=${s.mistakes.map((m) => m.key)} card=${find.byType(MistakeCard).evaluate().length} pass=${find.byType(LevelPassPanel).evaluate().length}');
      expect(s.rungProgress['7.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['7.8/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtNo), findsOneWidget);
      expect(find.text(L.caughtVan), findsOneWidget);
      expect(find.text(L.caughtOil), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final noVanSeed = _seedWhere((d) => !d.hasVan && d.push == M7HandPush.shortcut);
    testWidgets('flow (seed $noVanSeed): the shortcut push refused; cups and paper put on the truck loose → pass', (t) async {
      final c = await _open(t, noVanSeed);
      await _prep(t);
      while (!_live.done) {
        await _waitHere(t);
        if (_live.vehicle == V.municipal) await _refuse(t, M7HandPush.shortcut);
        await _serve(t, greenBin: false);
        await _pump(t, 800);
      }
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtGeneral), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a lamp slid before it lifts stays put; held, it lifts, and released off the box it cracks (a slip card, no freeze)', (t) async {
      final c = await _open(t, 7);
      final lamp = _live.deal.items.firstWhere((w) => w.kind == M7Kind.lamp);
      // A drag with no hold: nothing moves.
      await _item(t, lamp, _bin(M7BoxKind.lampBox));
      expect(_live.spot[lamp], M7Spot.trolley);
      expect(find.byType(MistakeCard), findsNothing);
      // Held, then released on the red bin.
      await _lamp(t, lamp, _bin(M7BoxKind.redBin));
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.lampCrack.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.spot[lamp], M7Spot.cracked);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.lampCrack.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _gotIt(t);
      expect(_label(L.waste(lamp)), findsNothing, reason: 'the cracked lamp is gone from the trolley');
      await _close(t, c);
    });

    testWidgets('an oily rag in the green bin: a slip card, and it comes back to the trolley', (t) async {
      final c = await _open(t, 9);
      final w = _live.deal.items.firstWhere((w) => w.kind == M7Kind.oily);
      await _item(t, w, _bin(M7BoxKind.greenBin));
      expect(find.text(Mk.oilyGreen.textBn), findsOneWidget);
      expect(_live.spot[w], M7Spot.trolley);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.oilyGreen.key);
      await _gotIt(t);
      expect(_label(L.waste(w)), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 9);
      final w = _live.deal.items.firstWhere((w) => w.kind == M7Kind.oily);
      for (var i = 0; i < 2; i++) {
        await _item(t, w, _bin(M7BoxKind.greenBin));
        await _gotIt(t);
      }
      await _item(t, w, _bin(M7BoxKind.greenBin));
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final vanFirst = _seedWhere((d) => d.hasVan && d.push == M7HandPush.myth && d.order.first == V.unmarked);
    testWidgets('the unmarked van (seed $vanFirst): a drop drives off with it — a slip card, then the next vehicle pulls in', (t) async {
      final c = await _open(t, vanFirst);
      await _prep(t);
      await _waitHere(t, v: V.unmarked);
      await _item(t, W.oilDrum, _geo.bed.center);
      expect(find.text(Mk.vanTake.textBn), findsOneWidget);
      expect(_live.spot[W.oilDrum], M7Spot.lost);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.vanTake.key);
      await _gotIt(t);
      await _waitHere(t);
      expect(_live.vehicle, isNot(V.unmarked));
      expect(_live.vehicleIx, 1);
      await _close(t, c);
    });

    testWidgets('the unmarked van waved off with nothing: praise, ◆, its reason (no slip), then the next vehicle', (t) async {
      final c = await _open(t, vanFirst);
      await _prep(t);
      await _waitHere(t, v: V.unmarked);
      await _yan(t);
      expect(_live.why, M7HandWhy.van);
      await _reason(t);
      await _waitHere(t);
      expect(_live.vehicleIx, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a wrong waste on a vehicle comes back (a slip card); the vehicle stays', (t) async {
      final c = await _open(t, noVanSeed);
      await _prep(t);
      await _waitHere(t);
      final v = _live.vehicle!;
      final w = _live.deal.items.firstWhere((x) => const [M7Kind.oil, M7Kind.elec, M7Kind.general].contains(x.kind) && m7HandReceiver(x.kind) != v);
      await _item(t, w, _geo.bed.center);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(_live.here, isTrue);
      expect(_live.bed, isEmpty);
      expect(_live.spot[w], M7Spot.trolley);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    final myth = _seedWhere((d) => d.push == M7HandPush.myth);
    testWidgets('listening to him (myth 2) is a slip — no freeze, no deadly (M7-6); the dealt hazardous item goes on the truck', (t) async {
      final c = await _open(t, myth);
      await _until(t, V.municipal);
      expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 6000), isTrue);
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerMyth.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(_live.dumped, isNotEmpty);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listen.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a fast play: the first drag at the municipal truck waits for him; he cuts in at once', (t) async {
      final c = await _open(t, myth);
      await _until(t, V.municipal);
      await _carry(t, _bin(M7BoxKind.greenBin), _geo.bed.center);
      expect(_has(find.byType(CoworkerPeek)), isTrue, reason: 'he cuts in');
      expect(_live.bed, isEmpty, reason: 'the drag did nothing');
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pickRight(t, L.coworkerMyth.right);
      await _pump(t, 2600);
      await _carry(t, _bin(M7BoxKind.greenBin), _geo.bed.center);
      expect(_live.bed, isNotEmpty, reason: 'after him the drag works');
      await _close(t, c);
    });

    testWidgets('the "যান" tap at the municipal truck waits for him too', (t) async {
      final c = await _open(t, myth);
      await _until(t, V.municipal);
      await _yan(t);
      expect(_has(find.byType(CoworkerPeek)), isTrue, reason: 'he cuts in');
      expect(_live.here, isTrue, reason: 'the truck did not leave');
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, myth);
      for (final w in _live.deal.items.where((w) => w.kind == M7Kind.lamp)) {
        await _lamp(t, w, _bin(M7BoxKind.lampBox));
      }
      expect(_live.roundDone, isTrue);
      final oily = _live.deal.items.firstWhere((w) => w.kind == M7Kind.oily);
      await _item(t, oily, _bin(M7BoxKind.greenBin));
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.spot[oily], M7Spot.trolley);
      await _reason(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle in the sorting, a sweep over the waste, the box and both bins that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 7);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the sorting');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(scene().debugOptions, hasLength(_live.at(M7Spot.trolley).length + 3), reason: 'every piece, the box and both bins alike');
      await _close(t, c);
    });

    testWidgets('gesture hand: a touched lamp gets a hold ring on itself (how to lift), nothing else', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 7);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      final lamp = _live.deal.items.firstWhere((w) => w.kind == M7Kind.lamp);
      await t.tapAt(_slotOf(lamp) * _k);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, isEmpty, reason: 'a hold on one control: no sweep');
      await _close(t, c);
    });
  });
}
