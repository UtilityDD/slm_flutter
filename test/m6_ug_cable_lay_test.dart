// Lesson 6.5 (আন্ডারগ্রাউন্ড কেবিল), কাজ 1 "বাঁক বুঝে কেবিল পাতা": the rules
// (a bend placed tighter than the docket's ring = a slip, its own card when a
// wide start was tightened; the wall stops the bend; armour earthed at one end
// = a slip, at neither end at sign-off = DEADLY (ruling M6-1, N6); the kit
// fitted himself = a slip; every coworker push slip-class (X2/B1), the bend
// push bends it tight), the deal, the libraries, the rival lines, the
// geometry, and the level in the shell: the guide first, tap-to-repeat, the
// docket's ring under the finger, a full clean play (a reason pick at each
// reason station, the coworker refused) for each push, a slip card with the
// ghost ring, three slips, the deadly freeze, listening to him, the decisive
// control waiting for him, and the gesture hand (how, never what).
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
import 'package:slm_flutter/features/game/m6_ug_cable_lay.dart';
import 'package:slm_flutter/features/game/m6_ug_cable_lay_world.dart';
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
  rungId: '6.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6UgCablePacks['do_6_5_a']!;
typedef L = M6UgCableLines;
typedef Mk = M6UgCableMistakes;

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
M6UgGeo get _geo => M6UgGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

/// Drags bend [b]'s belly handle from radius [from] to [to] (along the
/// inward diagonal); returns the radius the run now has (clamped).
Future<double> _bendTo(WidgetTester t, M6BendDeal b, double from, double to) async {
  final start = _geo.belly(b.kind, from);
  final along = M6UgGeo.inward(b.kind) * ((to - from) * kM6Belly);
  await t.dragFrom(start * _k, along * _k);
  await _pump(t, 300);
  return to.clamp(kM6RLow, b.rMax).toDouble();
}

Future<void> _place(WidgetTester t) async {
  await t.tap(_label(L.place));
  await _pump(t, 400);
}

Future<void> _bond(WidgetTester t, int i) async {
  final g = _geo;
  await t.dragFrom(g.lugRest(i) * _k, (g.earthPoint(i) - g.lugRest(i)) * _k);
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6UgCablePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 300);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M6UgDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6UgDeal(math.Random(s))));

/// He comes (his station's start): refuse him.
Future<void> _refuse(WidgetTester t, M6UgPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// One station played right (the coworker refused if he is dealt on it).
Future<void> _playStation(WidgetTester t, M6UgDeal d, int i) async {
  if (d.coworkerStation == i) await _refuse(t, d.push);
  if (i < 3) {
    final b = d.bends[i];
    if (!b.wide) await _bendTo(t, b, b.r0, b.rMin + 10);
    await _place(t);
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'bend $i (${b.kind})');
    if (i == d.whyBend) {
      await _pickRight(t, L.whyRight[M6UgWhy.bend]!);
      await _pump(t, 2000);
    } else {
      await _pump(t, 2000);
    }
    return;
  }
  if (i == 3) {
    await _bond(t, 1);
    await _bond(t, 0);
    await t.tap(_label(L.signOff));
    await _pump(t, 400);
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'armour');
    await _pickRight(t, L.whyRight[M6UgWhy.armour]!);
    await _pump(t, 2000);
    return;
  }
  await t.tapAt(_geo.slot(1 - d.kitSlot).center * _k);
  await _pump(t, 400);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'termination');
  await _pickRight(t, L.whyRight[M6UgWhy.termination]!);
  await _pump(t, 2000);
}

M6UgDeal _deal({M6UgPush push = M6UgPush.armour, int pushBend = 0, bool wideFirst = false}) {
  const rMin = 96.0;
  return M6UgDeal(
    size: M6CableSize.big,
    bends: [
      M6BendDeal(kind: M6Bend.plinth, rMin: rMin, rMax: 140, r0: wideFirst ? 120 : 64),
      const M6BendDeal(kind: M6Bend.corner, rMin: rMin, rMax: 150, r0: 110),
      const M6BendDeal(kind: M6Bend.riser, rMin: rMin, rMax: 130, r0: 70),
    ],
    push: push,
    pushBend: pushBend,
    whyBend: 1,
    kitSlot: 0,
  );
}

/// A run at the armour station (three bends placed right).
M6UgRun _atArmour() {
  final r = M6UgRun(_deal());
  for (var i = 0; i < 3; i++) {
    r.setRadius(r.bend.rMin + 5);
    expect(r.place(), isNull);
    r.next();
  }
  expect(r.stage, M6UgStage.armour);
  return r;
}

void main() {
  group('rules', () {
    test('deals: three different bends, both start curves every play, two ring sizes; his push and station; plays differ', () {
      final seen = <String>{};
      final pushes = <M6UgPush>{};
      final stations = <int>{};
      final kinds = <M6Bend>{};
      final whys = <int>{};
      final sizes = <M6CableSize>{};
      final firsts = <M6Bend>{};
      for (var s = 0; s < 200; s++) {
        final d = m6UgDeal(math.Random(s));
        expect(d.bends, hasLength(3));
        expect(d.bends.map((b) => b.kind).toSet(), hasLength(3));
        expect(d.bends.where((b) => b.wide), isNotEmpty, reason: 'one start already wide');
        expect(d.bends.where((b) => !b.wide), isNotEmpty, reason: 'one start tight');
        for (final b in d.bends) {
          expect(b.rMin, d.ring);
          expect(b.rMax, greaterThanOrEqualTo(b.rMin + 24), reason: 'room for a right bend');
          expect(b.rMax, lessThanOrEqualTo(150));
          expect(b.r0, inInclusiveRange(kM6RLow, b.rMax));
          if (b.wide) expect(b.r0, greaterThanOrEqualTo(b.rMin + kM6WideMargin), reason: 'clearly wide: one hint nudge cannot cross the ring');
          if (b.wide) expect(b.r0, lessThanOrEqualTo(b.rMax - 4), reason: 'short of the wall');
          if (!b.wide) expect(b.r0, lessThanOrEqualTo(b.rMin - 18), reason: 'clearly tight');
        }
        expect(d.pushBend, inInclusiveRange(0, 2));
        expect(d.whyBend, inInclusiveRange(0, 2));
        expect(d.kitSlot, inInclusiveRange(0, 1));
        pushes.add(d.push);
        stations.add(d.coworkerStation);
        kinds.addAll(d.bends.map((b) => b.kind));
        firsts.add(d.bends.first.kind);
        whys.add(d.whyBend);
        sizes.add(d.size);
        seen.add('${d.size.name}|${d.bends.map((b) => '${b.kind.index}${b.r0.round()}${b.rMax.round()}').join()}|${d.push.name}${d.pushBend}|${d.whyBend}${d.kitSlot}');
      }
      expect(seen.length, greaterThan(190));
      expect(pushes, M6UgPush.values.toSet());
      expect(stations, {0, 1, 2, 3, 4}, reason: 'he comes on any bend, the armour or the termination');
      expect(kinds, M6Bend.values.toSet());
      expect(firsts, M6Bend.values.toSet(), reason: 'any bend first');
      expect(whys, {0, 1, 2});
      expect(sizes, M6CableSize.values.toSet());
      expect(m6UgRing[M6CableSize.big]!, greaterThan(m6UgRing[M6CableSize.small]!));
    });

    test('a bend: tighter than the ring is a slip and ghosts the ring; at or over the ring is right', () {
      final r = M6UgRun(_deal());
      expect(r.r, 64);
      expect(r.place(), Mk.bendTight, reason: 'the start was tight');
      expect(r.ghost, isTrue);
      expect(r.creaseAt, 64);
      expect(r.slips, 1);
      expect(r.roundDone, isFalse, reason: 'the same bend again');
      r.setRadius(80);
      expect(r.creaseAt, isNull, reason: 'the crease goes once the curve moves');
      expect(r.ghost, isTrue, reason: 'the ghost ring stays for the retry');
      r.setRadius(96);
      expect(r.place(), isNull, reason: 'equal to the ring is fine');
      expect(r.roundDone, isTrue);
      expect(r.thorough, isFalse);
      r.next();
      expect(r.ghost, isFalse);
      expect(r.r, 110, reason: 'the next bend starts at its dealt curve');
      expect(r.place(), isNull, reason: 'already wide: placing it as it is is right');
    });

    test('a wide start tightened below the ring has its own card', () {
      final r = M6UgRun(_deal(wideFirst: true));
      expect(r.bend.wide, isTrue);
      r.setRadius(70);
      expect(r.place(), Mk.bendTightened);
      r.setRadius(60);
      expect(r.place(), Mk.bendTightened);
      expect(r.slips, 2);
    });

    test('the wall stops the bend; the handle never pulls tighter than the floor', () {
      final r = M6UgRun(_deal());
      expect(r.setRadius(400), isTrue);
      expect(r.r, 140, reason: 'the room the wall leaves');
      expect(r.setRadius(120), isFalse);
      expect(r.r, 120);
      r.setRadius(5);
      expect(r.r, kM6RLow);
      // Nothing moves off the bend stations.
      final a = _atArmour();
      expect(a.setRadius(80), isFalse);
      expect(a.place(), isNull);
      expect(a.slips, 0);
    });

    test("the bend hint nudge: along the bend's own diagonal, wider and tighter by turns, never across the ring from a wide start", () {
      for (final k in M6Bend.values) {
        final i = M6UgGeo.inward(k);
        final dr = <double>[];
        for (var n = 0; n < 4; n++) {
          final v = m6UgHandleNudge(k, n);
          // Parallel to the only way the handle moves.
          expect((v.dx * i.dy - v.dy * i.dx).abs(), lessThan(1e-9), reason: '$k: along its diagonal');
          expect(v.distance, closeTo(kM6HintTravel, 1e-9));
          // The radius change copying it would make (as radiusFor reads a drag).
          final r = _geo.radiusFor(k, r0: 100, from: _geo.belly(k, 100), p: _geo.belly(k, 100) + v) - 100;
          expect(r.abs(), lessThan(kM6WideMargin), reason: '$k: a copied nudge stays on its side of the ring');
          dr.add(r);
        }
        expect(dr[0], greaterThan(0), reason: '$k: the first nudge widens');
        for (var n = 1; n < 4; n++) {
          expect(dr[n].sign, -dr[n - 1].sign, reason: '$k: the direction alternates');
        }
      }
    });

    test('armour: neither end earthed at sign-off = DEADLY (M6-1, N6); one end = a slip; both = right', () {
      final none = _atArmour();
      final m = none.signOff();
      expect(m, Mk.armourNone);
      expect(m!.deadly, isTrue);
      expect(none.ended, isTrue);
      expect(none.slips, 0, reason: 'deadly, not a slip');
      final one = _atArmour()..bond(1);
      final s = one.signOff();
      expect(s, Mk.armourOne);
      expect(s!.deadly, isFalse);
      expect(one.slips, 1);
      expect(one.roundDone, isFalse);
      one.bond(0);
      expect(one.signOff(), isNull);
      expect(one.roundDone, isTrue);
      expect(one.caught, contains(L.caughtArmour));
      // A lug bonds only at the armour station.
      final b = M6UgRun(_deal())..bond(0);
      expect(b.bonded, isEmpty);
    });

    test('termination: the kit fitted himself = a slip; the phone (certified jointer) = right', () {
      final r = _atArmour()
        ..bond(0)
        ..bond(1)
        ..signOff()
        ..next();
      expect(r.stage, M6UgStage.termination);
      expect(r.fitKit(), Mk.selfFit);
      expect(r.slips, 1);
      expect(r.callJointer(), isTrue);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtJointer));
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 85);
    });

    test('the coworker: one station per push; listening is always a slip (X2/B1); the bend push bends it tight', () {
      expect(_deal(push: M6UgPush.bend, pushBend: 2).coworkerStation, 2);
      expect(_deal(push: M6UgPush.armour).coworkerStation, 3);
      expect(_deal(push: M6UgPush.myth).coworkerStation, 4);
      for (final p in M6UgPush.values) {
        expect(Mk.push(p).deadly, isFalse, reason: '$p pushes a slip-class act');
      }
      final r = M6UgRun(_deal(push: M6UgPush.bend, wideFirst: true));
      r.setRadius(130);
      expect(r.listened(M6UgPush.bend), Mk.pushBend);
      expect(r.r, lessThan(r.bend.rMin), reason: 'he bent it tight');
      expect(r.ghost, isTrue);
      expect(r.place(), Mk.bendTight, reason: 'his tight bend, not a tightened wide start');
      expect(r.slips, 2);
      final a = _atArmour();
      expect(a.listened(M6UgPush.armour), Mk.pushArmour);
      expect(a.bonded, isEmpty);
      expect(a.slips, 1);
      // The termination push quotes lesson myth 2 word for word.
      expect(L.coworkerMyth.line, startsWith('ওভারহেড লাইনের জয়েন্টিং আর ইউজি কেবিলের জয়েন্টিং একই।'));
    });

    test('three slips and the mark is 55; a fourth fails the play', () {
      final r = M6UgRun(_deal());
      for (var i = 0; i < 3; i++) {
        r.place();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.place();
      expect(r.percent, 40);
    });

    test('English digits only; jol not pani; locked words; every mistake has its picture; the deadly set; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        L.rule,
        ...L.tasks,
        ...L.tapWhy,
        L.place,
        L.signOff,
        L.docketTitle,
        L.docketCable,
        for (final s in M6CableSize.values) L.docketSize(s),
        L.kitLabel,
        L.docketLabel,
        ...L.stations,
        ...L.whyQ.values,
        for (final w in M6UgWhy.values) ...[...L.whyRight[w]!, ...L.whyWrong[w]!],
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6UgPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtBends,
        L.caughtArmour,
        L.caughtJointer,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('গ্লোভস'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.armourNone}, reason: 'the only deadly: armour signed off with no earth (N6)');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.5/m6_ug_cable_lay/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_ug_cable_lay/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6UgCablePacks.keys, ['do_6_5_a']);
    });

    test('libraries: same length per deck, big enough, never a rule marked wrong; one right per deal', () {
      for (final w in M6UgWhy.values) {
        final right = L.whyRight[w]!;
        final wrong = L.whyWrong[w]!;
        expectSameLength('why $w', [...right, ...wrong]);
        expectLibrary('why $w', right, wrong);
        expect(wrong.toSet().intersection(right.toSet()), isEmpty);
        expect(L.whyQ[w], isNotEmpty);
        final hands = <String>{};
        for (var k = 0; k < 20; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          hands.add(deal.map((o) => o.textBn).join('|'));
        }
        expect(hands.length, greaterThan(5), reason: 'hands differ');
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
        expect(cw.exitLine, L.coworkerExit);
      }
    });

    test('rival lines: his exit is recorded; his three new pushes are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'জায়গা কম, এখানে টাইট করে বাঁকিয়ে দাও — মোটা কেবিল, কিছু হবে না!',
        'আর্মার এক দিকে আর্থ করলেই চলবে, চলো ফিরি!',
        'ওভারহেড লাইনের জয়েন্টিং আর ইউজি কেবিলের জয়েন্টিং একই। কিটটা তুমিই লাগিয়ে দাও!',
      ]);
      expect({for (final p in M6UgPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      for (final l in L.newRivalLines) {
        // Not recorded yet (the director records them with tool/rival_clip.py
        // after the owner's wording): until then silent, the caption held.
        debugPrint('RIVAL m6_ug_cable_lay: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
      expect(L.newGuideLines, containsAll([L.intro, L.rule, ...L.tasks, ...L.whyQ.values]));
    });

    test('geometry: the handle stays clear of the docket, the guide, his bubble and the button; the wall stops the belly; targets clear', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6UgGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        // The guide's bubble (up to four lines) over his head.
        final bubble = Rect.fromLTRB(147, h - 290, 360, h - 193);
        final button = Rect.fromLTWH(15, h - 66, 150, 66);
        for (final k in M6Bend.values) {
          for (var r = kM6RLow; r <= 150; r += 6) {
            final hit = g.handleHit(k, r);
            expect(hit.left, greaterThanOrEqualTo(0), reason: '$k $r h $h');
            expect(hit.right, lessThanOrEqualTo(360), reason: '$k $r h $h');
            expect(hit.top, greaterThan(M6UgGeo.docket.bottom), reason: '$k $r h $h: under the docket');
            // The bubble lets touches through; on the shortest phones a
            // four-line bubble covers most of the work area anyway.
            for (final no in [guide, if (h >= 640) bubble, button]) {
              expect(hit.overlaps(no), isFalse, reason: '$k r $r h $h: $hit vs $no');
            }
          }
          // The belly at the wall's room never passes the wall's corner.
          for (final rMax in [124.0, 150.0]) {
            final apex = g.wallApex(k, rMax);
            final corner = g.corner(k);
            expect((g.belly(k, rMax) - corner).distance, lessThan((apex - corner).distance));
          }
        }
        final targets = [for (var i = 0; i < 2; i++) ...[g.lugHit(i), g.earthHit(i), g.slot(i)]];
        for (final r in targets) {
          expect(r.top, greaterThan(M6UgGeo.docket.bottom), reason: 'h $h $r');
          for (final no in [guide, if (h >= 640) bubble, button]) {
            expect(r.overlaps(no), isFalse, reason: 'h $h: $r vs $no');
          }
        }
        for (var i = 0; i < 2; i++) {
          expect(g.lugHit(i).overlaps(g.earthHit(i)), isFalse, reason: 'the lug must be carried to its point');
          expect(g.lugHit(i).overlaps(g.earthHit(1 - i)), isFalse);
        }
        expect(g.slot(0).overlaps(g.slot(1)), isFalse);
        expect(g.slot(0).size, g.slot(1).size, reason: 'the kit and the phone the same size');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket, the handle and বসান', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6UgCablePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.text(L.docketTitle), findsOneWidget);
      expect(find.text(L.docketCable), findsOneWidget);
      expect(_label(L.place), findsOneWidget);
      expect(find.byKey(const ValueKey('handle-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('ring')), findsNothing, reason: 'no ring until the docket is held');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    final calm = _seedWhere((d) => d.coworkerStation > 2);
    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, calm);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askBend)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('hold the docket: the ring floats under the finger, follows it, and goes on release', (t) async {
      final c = await _open(t, calm);
      final g = await t.startGesture(M6UgGeo.docket.center * _k);
      await t.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('ring')), findsOneWidget);
      final at = t.getCenter(find.byKey(const ValueKey('ring')));
      await g.moveBy(const Offset(60, 180));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.getCenter(find.byKey(const ValueKey('ring'))), isNot(at), reason: 'it follows the finger');
      await g.up();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('ring')), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    // One clean play for each push (refused).
    for (final p in M6UgPush.values) {
      final seed = _seedWhere((d) => d.push == p && (p != M6UgPush.bend || d.pushBend != d.whyBend));
      testWidgets('flow (${p.name}, seed $seed): three bends, the armour, the termination, reasons; he is refused → pass', (t) async {
        final d = m6UgDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < m6UgStations; i++) {
          await _playStation(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.5/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.5/do/0'], greaterThan(0), reason: 'stars recorded (the league)');
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtBends), findsOneWidget);
        expect(find.text(L.caughtArmour), findsOneWidget);
        expect(find.text(L.caughtJointer), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final tightFirst = _seedWhere((d) => !d.bends.first.wide && d.coworkerStation != 0);
    testWidgets('a bend placed tight: the slip card, then the ghost ring; widened, it places', (t) async {
      final d = m6UgDeal(math.Random(tightFirst));
      final c = await _open(t, tightFirst);
      await _place(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.bendTight.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      final b = d.bends.first;
      await _bendTo(t, b, b.r0, b.rMin + 12);
      await _place(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.bendTight.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final wideFirst = _seedWhere((d) => d.bends.first.wide && d.coworkerStation != 0);
    testWidgets('a wide start tightened below the ring: its own slip card', (t) async {
      final d = m6UgDeal(math.Random(wideFirst));
      final c = await _open(t, wideFirst);
      final b = d.bends.first;
      await _bendTo(t, b, b.r0, b.rMin - 30);
      await _place(t);
      expect(find.text(Mk.bendTightened.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.bendTightened.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final d = m6UgDeal(math.Random(tightFirst));
      final c = await _open(t, tightFirst);
      expect(d.bends.first.wide, isFalse);
      for (var i = 0; i < 3; i++) {
        await _place(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final noArmourPush = _seedWhere((d) => d.coworkerStation == 4);
    testWidgets('the armour signed off with no end earthed: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final d = m6UgDeal(math.Random(noArmourPush));
      final c = await _open(t, noArmourPush);
      for (var i = 0; i < 3; i++) {
        await _playStation(t, d, i);
      }
      expect(_label(L.signOff), findsOneWidget, reason: 'the chip is live from the start');
      await t.tap(_label(L.signOff));
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.armourNone.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('one end earthed at sign-off: a slip card; the second lug then signs off', (t) async {
      final d = m6UgDeal(math.Random(noArmourPush));
      final c = await _open(t, noArmourPush);
      for (var i = 0; i < 3; i++) {
        await _playStation(t, d, i);
      }
      await _bond(t, 0);
      await t.tap(_label(L.signOff));
      await _pump(t, 500);
      expect(find.text(Mk.armourOne.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _bond(t, 1);
      await t.tap(_label(L.signOff));
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M6UgWhy.armour]!);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.armourOne.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final mythPush = _seedWhere((d) => d.push == M6UgPush.myth);
    testWidgets('listening to his termination push (myth 2) is a slip; the kit fitted himself too; the phone then', (t) async {
      final d = m6UgDeal(math.Random(mythPush));
      final c = await _open(t, mythPush);
      for (var i = 0; i < 4; i++) {
        await _playStation(t, d, i);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerMyth.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      expect(find.text(Mk.pushMyth.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tapAt(_geo.slot(d.kitSlot).center * _k);
      await _pump(t, 400);
      expect(find.text(Mk.selfFit.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tapAt(_geo.slot(1 - d.kitSlot).center * _k);
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M6UgWhy.termination]!);
      await _pump(t, 3000);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.pushMyth.key, Mk.selfFit.key]);
      expect(c.read(gameSaveProvider).rungProgress['6.5/do/0'], 'cleared', reason: '70 %: passed');
      await _close(t, c);
    });

    final bendPushFirst = _seedWhere((d) => d.push == M6UgPush.bend && d.pushBend == 0 && d.whyBend != 0);
    testWidgets('a fast play: বসান waits for him; he cuts in at once; listening bends it tight', (t) async {
      final c = await _open(t, bendPushFirst);
      // At once, well inside his 1.2–2.4 s timer.
      await t.tap(_label(L.place));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.byType(MistakeCard), findsNothing, reason: 'the place waited: nothing judged');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerBend.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.text(Mk.pushBend.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He bent it tight: placing it now is the tight-bend slip.
      await _place(t);
      expect(find.text(Mk.bendTight.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.pushBend.key, Mk.bendTight.key]);
      await _close(t, c);
    });

    testWidgets('gesture hand: at a bend the docket hold / a drag nudge; after a drag a sweep over handle and বসান; none while a card is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m6UgDeal(math.Random(tightFirst));
      final c = await _open(t, tightFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the bend');
      expect(scene().debugOptions, isEmpty, reason: 'a hold or a drag, not a pick');
      final b = d.bends.first;
      await _bendTo(t, b, b.r0, b.r0 + 6);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, hasLength(2), reason: 'the handle and বসান alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _place(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'no hand over a card');
      await _close(t, c);
    });
  });
}
