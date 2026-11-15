// Lesson 6.5 (আন্ডারগ্রাউন্ড কেবিল), কাজ 2 "খোঁড়ার আগে কেবিলের পথ"
// (m6_ug_dig_guard, do_6_5_b): the rules (peg the true route — the pole foot,
// the joints in order, the DTR entry, either way round; a joint missed,
// straight across or through the drain = a slip and the route revealed; the
// red flag held over the route = right, on a clear circle a needless stop
// (slip); the bucket on the live cable = deadly; listening to myth 1 over
// the route = deadly, on a clear circle a slip — ruling X2/B1), the deal and
// the street layout on every screen height, the libraries, his line (lesson
// myth 1 word for word), and the level in the shell: the guide first, a full
// clean play (a reason pick for the peg and each stop, the coworker refused),
// the coworker holds the descent, a wrong peg's card and the revealed route,
// three slips, the deadly freeze (no flag; listening over the route), and the
// gesture hand (how, never what) only in the peg stage.
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
import 'package:slm_flutter/features/game/m6_ug_dig_guard.dart';
import 'package:slm_flutter/features/game/m6_ug_dig_guard_world.dart' show m6ChalkPath, m6SegDist, m6Turn;
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
  rungId: '6.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6UgDigGuardPacks['do_6_5_b']!;
typedef L = M6DigLines;
typedef Mk = M6DigMistakes;

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

Future<bool> _waitFor(WidgetTester t, bool Function() ok, {int maxMs = 10000}) async {
  for (var ms = 0; ms < maxMs; ms += 50) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 50));
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M6DigGeo get _geo => M6DigGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Offset _at(int id, M6DigLayout lay) => switch (id) {
      kM6Pole => _geo.poleFoot,
      kM6Dtr => _geo.dtrEntry,
      _ => lay.covers[id],
    };

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 250);
}

/// Taps [chain] (anchor ids) and 'পথ আঁকা শেষ'.
Future<void> _peg(WidgetTester t, M6DigDeal d, List<int> chain) async {
  final lay = d.layoutOn(_geo);
  for (final id in chain) {
    await _tapAt(t, _at(id, lay));
  }
  await t.tap(_label(L.pegDone));
  await _pump(t, 500);
}

/// The true route pegged, then its reason.
Future<void> _pegRight(WidgetTester t, M6DigDeal d) async {
  await _peg(t, d, d.trueRoute);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'the true route');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the peg reason');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[M6DigWhy.peg]!);
  await _pump(t, 400);
}

Future<void> _holdFlag(WidgetTester t, {int ms = 1250}) async {
  final g = await t.startGesture(t.getCenter(_label(L.flag)));
  await _pump(t, ms);
  await g.up();
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 400);
}

/// One dig circle played right (the coworker refused if he comes here).
Future<void> _playSpot(WidgetTester t, M6DigDeal d, int i) async {
  expect(await _waitFor(t, () => M6DigProbe.run?.spot == i), isTrue, reason: 'circle $i');
  if (d.coworkerSpot == i) await _refuse(t);
  expect(await _waitFor(t, () => M6DigProbe.descending), isTrue, reason: 'the bucket comes down at $i');
  if (d.onRoute[i]) {
    await _pump(t, 300);
    await _holdFlag(t);
    expect(find.text(MistakeLines.slipHead), findsNothing);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the flag reason');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[M6DigWhy.flag]!);
  }
  expect(await _waitFor(t, () => (M6DigProbe.run?.spot ?? 3) > i || (M6DigProbe.run?.done ?? true), maxMs: 12000), isTrue, reason: 'past circle $i');
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6UgDigGuardPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M6DigDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6DigDeal(math.Random(s))));

M6DigDeal _deal({int drain = 2, List<int> joints = const [1, 0], List<bool> onRoute = const [true, false, false], int coworker = 1}) =>
    M6DigDeal(drain: drain, jointRoute: joints, onRoute: onRoute, descentMs: const [6000, 6000, 6000], coworkerSpot: coworker, layoutSeed: 11);

void main() {
  group('rules', () {
    test('deals: 2–3 covers (one drain), 1–2 circles over the route, 5–7 s descents, the coworker at any circle; plays differ', () {
      final seen = <String>{};
      final at = <int>{};
      final kinds = <bool>{};
      final covers = <int>{};
      final nOn = <int>{};
      for (var s = 0; s < 150; s++) {
        final d = m6DigDeal(math.Random(s));
        expect(d.covers, inInclusiveRange(2, 3));
        expect(d.drain, inInclusiveRange(0, d.covers - 1));
        expect({...d.jointRoute, d.drain}, {for (var i = 0; i < d.covers; i++) i});
        expect(d.jointRoute, isNot(contains(d.drain)));
        expect(d.onRoute, hasLength(3));
        final on = d.onRoute.where((x) => x).length;
        expect(on, inInclusiveRange(1, 2));
        for (final ms in d.descentMs) {
          expect(ms, inInclusiveRange(5000, 7000));
        }
        expect(d.trueRoute.first, kM6Pole);
        expect(d.trueRoute.last, kM6Dtr);
        at.add(d.coworkerSpot);
        kinds.add(d.onRoute[d.coworkerSpot]);
        covers.add(d.covers);
        nOn.add(on);
        seen.add('${d.drain}${d.jointRoute}${d.onRoute}${d.descentMs}${d.coworkerSpot}');
      }
      expect(seen.length, greaterThan(120));
      expect(at, {0, 1, 2});
      expect(kinds, {true, false}, reason: 'he comes at circles of either kind');
      expect(covers, {2, 3});
      expect(nOn, {1, 2});
    });

    test('the street on every screen height: gentle bends, the drain off the route, circles clearly on or off, all clear of the guide', () {
      for (final h in [560.0, 620.0, 700.0, 781.0, 850.0, 900.0]) {
        final g = M6DigGeo.forScene(h, 0);
        for (var s = 0; s < 160; s++) {
          final d = m6DigDeal(math.Random(s));
          final l = d.layoutOn(g);
          final why = 'h $h seed $s';
          expect(l.fallback, isFalse, reason: why);
          expect(l.route.first, g.poleFoot);
          expect(l.route.last, g.dtrEntry);
          expect(l.route.sublist(1, l.route.length - 1), [for (final j in d.jointRoute) l.covers[j]], reason: why);
          for (var i = 1; i + 1 < l.route.length; i++) {
            expect(m6Turn(l.route[i - 1], l.route[i], l.route[i + 1]), lessThanOrEqualTo(75), reason: '$why: a gentle bend');
          }
          final off = [for (final j in d.jointRoute) m6SegDist(l.covers[j], g.poleFoot, g.dtrEntry)].reduce(math.max);
          expect(off, greaterThanOrEqualTo(42), reason: '$why: never straight across');
          expect(m6PolyDist(l.covers[d.drain], l.route), greaterThanOrEqualTo(46), reason: '$why: the drain off the route');
          for (final (i, s) in l.spots.indexed) {
            final dist = m6PolyDist(s, l.route);
            if (d.onRoute[i]) {
              expect(dist, lessThan(0.5), reason: '$why: circle $i on the route');
            } else {
              expect(dist, greaterThanOrEqualTo(56), reason: '$why: circle $i clearly off');
            }
          }
          final things = [...l.covers, ...l.spots];
          for (final p in things) {
            expect(g.free(p, 16), isTrue, reason: '$why: $p');
            expect(p.dy - 18, greaterThan(125), reason: '$why: below the header');
            expect(p.dy + 18, lessThan(h - 95), reason: '$why: above the buttons');
          }
          for (var i = 0; i < things.length; i++) {
            for (var k = i + 1; k < things.length; k++) {
              expect((things[i] - things[k]).distance, greaterThanOrEqualTo(39), reason: '$why: $i/$k apart');
            }
          }
          for (final c in l.covers) {
            for (final r in [g.riserHit, g.poleFootHit, g.dtrEntryHit, g.dtrBox]) {
              expect(g.coverHit(c).overlaps(r), isFalse, reason: '$why: cover on $r');
            }
          }
        }
        // The fixed anchors: below the header, clear of each other.
        expect(g.riserHit.top, greaterThan(125));
        expect(g.riserHit.overlaps(g.poleFootHit), isFalse);
        expect(g.dtrEntryHit.overlaps(g.dtrBox), isFalse);
        expect(g.dtrEntryHit.right, lessThan(245), reason: 'clear of the guide');
      }
    });

    test('the chalk turns are rounded (never a sharp corner)', () {
      const pts = [Offset(300, 100), Offset(200, 150), Offset(194, 260)];
      final path = m6ChalkPath(pts);
      var nearest = double.infinity;
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 0.5) {
          nearest = math.min(nearest, (m.getTangentForOffset(d)!.position - pts[1]).distance);
        }
      }
      expect(nearest, greaterThan(3), reason: 'the path passes inside the corner');
    });

    test('peg: the true route either way round; a chain starts at an end; a closed chain takes no more', () {
      final d = _deal();
      final r = M6DigRun(d);
      expect(r.tapAnchor(0), isFalse, reason: 'a cover cannot start the chain');
      expect(r.finishPeg(), isNull, reason: 'no leg yet: nothing');
      expect(r.slips, 0);
      expect(r.tapAnchor(kM6Pole), isTrue);
      expect(r.tapAnchor(kM6Pole), isFalse);
      expect(r.tapAnchor(1), isTrue);
      expect(r.tapAnchor(0), isTrue);
      expect(r.tapAnchor(kM6Dtr), isTrue);
      expect(r.chainClosed, isTrue);
      expect(r.tapAnchor(2), isFalse, reason: 'closed');
      expect(r.finishPeg(), isNull);
      expect(r.pegRight, isTrue);
      expect(r.caught, contains(L.caughtRoute));
      final b = M6DigRun(d)
        ..tapAnchor(kM6Dtr)
        ..tapAnchor(0)
        ..tapAnchor(1)
        ..tapAnchor(kM6Pole);
      expect(b.finishPeg(), isNull, reason: 'from the DTR end');
      final c = M6DigRun(d)
        ..tapAnchor(kM6Pole)
        ..tapAnchor(1)
        ..clearChain();
      expect(c.chain, isEmpty);
    });

    test('peg: straight across, a joint missed, joints out of order, half a route or the drain — a slip, the route revealed', () {
      final d = _deal();
      DoMistake? play(List<int> chain) {
        final r = M6DigRun(d);
        for (final id in chain) {
          r.tapAnchor(id);
        }
        final m = r.finishPeg();
        expect(r.revealed, isTrue, reason: '$chain');
        expect(r.slips, 1);
        expect(r.finishPeg(), isNull, reason: 'judged once');
        return m;
      }

      expect(play(const [kM6Pole, kM6Dtr]), Mk.pegMissed);
      expect(play(const [kM6Pole, 1, kM6Dtr]), Mk.pegMissed);
      expect(play(const [kM6Pole, 0, 1, kM6Dtr]), Mk.pegMissed);
      expect(play(const [kM6Pole, 1, 0]), Mk.pegMissed);
      expect(play(const [kM6Pole, 1, 2, 0, kM6Dtr]), Mk.pegDrain);
      expect(play(const [kM6Pole, 2, kM6Dtr]), Mk.pegDrain);
    });

    test('dig: the flag over the route is right; on a clear circle a needless stop; the bucket on the live cable is deadly', () {
      final r = M6DigRun(_deal(onRoute: const [true, false, false]))
        ..tapAnchor(kM6Pole)
        ..tapAnchor(1)
        ..tapAnchor(0)
        ..tapAnchor(kM6Dtr)
        ..finishPeg();
      expect(r.flag(), isNull, reason: 'still the peg stage');
      r.toDig();
      expect(r.stage, M6DigStage.dig);
      expect(r.flag(), isNull);
      expect(r.slips, 0);
      expect(r.caught, contains(L.caughtStop));
      expect(r.touch(), isNull, reason: 'the circle is over');
      r.nextSpot();
      expect(r.spot, 1);
      expect(r.touch(), isNull, reason: 'a clear circle dug');
      expect(r.dug, {1});
      r.nextSpot();
      expect(r.flag(), Mk.needlessStop);
      expect(r.slips, 1);
      expect(r.dug, {1, 2}, reason: 'then it is dug');
      r.nextSpot();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 85);
      expect(r.caught, isNot(contains(L.caughtClear)), reason: 'a needless stop');
      // No flag over the route.
      final s = M6DigRun(_deal(onRoute: const [false, true, false]))..toDig();
      expect(s.touch(), isNull);
      s.nextSpot();
      final m = s.touch();
      expect(m, Mk.digStrike);
      expect(m!.deadly, isTrue);
      expect(s.ended, isTrue);
      expect(s.slips, 0);
      // Clean: the clear circles left to dig.
      final c = M6DigRun(_deal(onRoute: const [false, true, true]))..toDig();
      c.touch();
      c.nextSpot();
      c.flag();
      c.nextSpot();
      c.flag();
      c.nextSpot();
      expect(c.passed, isTrue);
      expect(c.percent, 100);
      expect(c.caught, containsAll([L.caughtStop, L.caughtClear]));
    });

    test('the coworker (B1): listening over the route is deadly (the bucket strikes); on a clear circle a slip', () {
      final a = M6DigRun(_deal(onRoute: const [true, false, false]))..toDig();
      final m = a.listen();
      expect(m, Mk.pushStrike);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = M6DigRun(_deal(onRoute: const [false, true, false]))..toDig();
      expect(b.listen(), Mk.pushClear);
      expect(b.slips, 1);
      expect(b.ended, isFalse);
      expect(b.dug, {0});
      expect(b.flag(), isNull, reason: 'the circle is over');
      final c = M6DigRun(_deal())..refused();
      expect(c.caught, contains(L.caughtCall));
    });

    test('three slips: mark 55 (pass line); a fourth fails', () {
      final r = M6DigRun(_deal(onRoute: const [false, false, true]))
        ..tapAnchor(kM6Pole)
        ..tapAnchor(kM6Dtr)
        ..finishPeg()
        ..toDig();
      r.flag();
      r.nextSpot();
      r.flag();
      expect(r.slips, 3);
      expect(r.percent, 55);
      final s = M6DigRun(_deal())..slips = 4;
      expect(s.percent, 40);
    });

    test('English digits only; jol not pani; mistakes: the deadly set, keys, pictures, lesson points; the art folder all used', () {
      final all = <String>[
        L.title,
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.clear,
        L.pegDone,
        L.flag,
        L.stepPeg,
        for (var i = 0; i < 3; i++) L.stepDig(i),
        ...L.whyQ.values,
        for (final w in M6DigWhy.values) ...[...L.whyRight[w]!, ...L.whyWrong[w]!],
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.caughtRoute,
        L.caughtStop,
        L.caughtClear,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(L.stepDig(1), 'গর্ত 2');
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.digStrike, Mk.pushStrike});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.5/m6_ug_dig_guard/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m6_ug_dig_guard/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file used, no .gitkeep');
      expect(m6UgDigGuardPacks.keys, ['do_6_5_b']);
      expect(_pack.titleBn, 'খোঁড়ার আগে কেবিলের পথ');
    });

    test('libraries: same length, big enough; his cards reject or accept the myth and never tell the circle', () {
      for (final w in M6DigWhy.values) {
        final right = L.whyRight[w]!;
        final wrong = L.whyWrong[w]!;
        expectLibrary('why $w', right, wrong);
        expectSameLength('why $w', [...right, ...wrong]);
        expect(right.toSet().intersection(wrong.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expect(cw.asks, contains('কী করবেন?'));
      for (final card in [...cw.right, ...cw.wrong, L.callHeld]) {
        expect(card.contains('থাম'), isFalse, reason: '$card: says nothing about stopping here');
      }
      expect(L.whyQ[M6DigWhy.peg], 'পথটা এভাবে আঁকলেন কেন?');
      expect(L.whyQ[M6DigWhy.flag], 'কেন মেশিন থামালেন?');
      // No answer giveaway by shape: no wrong card ends in a tail the right
      // ones never have.
      for (final w in M6DigWhy.values) {
        for (final card in [...L.whyRight[w]!, ...L.whyWrong[w]!]) {
          expect(card.contains('তাই'), isFalse, reason: card);
        }
      }
      // The reused nudges are recorded lines.
      for (final line in [...L.tapWhy, cw.asks[0], cw.asks[2]]) {
        expect(LearnVoice.resolve(line), isNotNull, reason: '$line: a recorded clip');
      }
    });

    test('rival lines: his push is lesson 6.5 myth 1 word for word; his exit is recorded; the new lines are listed', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l65 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '6.5');
      final myths = ((l65['content'] as Map<String, dynamic>)['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>;
      // The lesson file writes য় as one code point; the app uses য + nukta.
      expect(((myths.first as Map<String, dynamic>)['myth'] as String).replaceAll('য়', 'য়'), L.myth1);
      expect(L.coworker.line, L.myth1);
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.myth1]);
      expect(L.newGuideLines, containsAll([L.intro, L.askPeg, L.flagTeach, L.askDig, L.callHeld, L.allSet, L.fail, ...L.whyQ.values]));
      expect(L.newGuideLines, hasLength(10 + Mk.all.length));
      expect(L.intro, 'রাস্তা খোঁড়া হবে — নিচে লাইভ ইউজি কেবিল! আগে ওর পথ বুঝুন।');
      expect(L.flagTeach, 'লাল পতাকা চেপে ধরে রাখলে মেশিন থামে।');
      for (final line in L.newRivalLines) {
        // Not recorded yet (the director records it with tool/rival_clip.py,
        // shared with board 6.5's myth): silent with the caption held.
        debugPrint('RIVAL m6_ug_dig_guard: $line ${LearnVoice.resolve(line, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the chalk buttons, no circles, no flag', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M6UgDigGuardPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 800);
      expect(_label(L.pegDone), findsOneWidget);
      expect(_label(L.clear), findsOneWidget);
      expect(_label(L.flag), findsNothing, reason: 'the flag only in the dig stage');
      expect(M6DigProbe.run!.stage, M6DigStage.peg);
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
      expect(lines.every((l) => l.contains(L.askPeg)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('look and lift: the pole top shows a close look; a cover lifts with a drag up and closes with a drag down — unscored', (t) async {
      final seed = _seedWhere((d) => d.coworkerSpot != 0);
      final d = m6DigDeal(math.Random(seed));
      final lay = d.layoutOn(_geo);
      final c = await _open(t, seed);
      await _tapAt(t, _geo.riserTop);
      expect(find.byKey(const ValueKey('look-1')), findsOneWidget);
      await t.dragFrom(lay.covers[0] * _k, const Offset(0, -60));
      await _pump(t, 300);
      await t.dragFrom(lay.covers[0] * _k, const Offset(0, 60));
      await _pump(t, 300);
      // A cover tapped before the chain begins lays nothing.
      await _tapAt(t, lay.covers[0]);
      expect(M6DigProbe.run!.chain, isEmpty);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(M6DigProbe.run!.slips, 0);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    // One play where he comes at a circle over the route, one at a clear one.
    final flowSeeds = [
      _seedWhere((d) => d.onRoute[d.coworkerSpot] && d.covers == 3),
      _seedWhere((d) => !d.onRoute[d.coworkerSpot] && d.covers == 2),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): lift, peg, reason; three circles, the flag over the route, a reason each; he is refused → pass', (t) async {
        final d = m6DigDeal(math.Random(seed));
        final lay = d.layoutOn(_geo);
        final c = await _open(t, seed);
        for (final cv in lay.covers) {
          await t.dragFrom(cv * _k, const Offset(0, -60));
          await _pump(t, 250);
        }
        await _pegRight(t, d);
        for (var i = 0; i < 3; i++) {
          await _playSpot(t, d, i);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.5/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.5/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtRoute), findsOneWidget);
        expect(find.text(L.caughtStop), findsOneWidget);
        expect(find.text(L.caughtClear), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final cwFirst = _seedWhere((d) => d.coworkerSpot == 0 && !d.onRoute[0]);
    testWidgets('the coworker holds the descent: the bucket stays up until his deck closes; refusing does not stop the machine', (t) async {
      final d = m6DigDeal(math.Random(cwFirst));
      final c = await _open(t, cwFirst);
      await _pegRight(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      for (var k = 0; k < 20; k++) {
        await t.pump(const Duration(milliseconds: 150));
        expect(M6DigProbe.descending, isFalse, reason: 'held while he is on');
      }
      await _pickRight(t, L.coworker.right);
      expect(await _waitFor(t, () => M6DigProbe.descending), isTrue, reason: 'the bucket comes down after him');
      // A clear circle: let it dig.
      expect(await _waitFor(t, () => M6DigProbe.run!.spot == 1, maxMs: 10000), isTrue);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final plain = _seedWhere((d) => d.coworkerSpot != 0 && d.covers == 3);
    testWidgets('a wrong peg through the drain: its card, then the true route is chalked in and the dig begins', (t) async {
      final d = m6DigDeal(math.Random(plain));
      final c = await _open(t, plain);
      await _peg(t, d, [kM6Pole, d.drain, ...d.jointRoute, kM6Dtr]);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.pegDrain.textBn), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no reason for a wrong peg');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(M6DigProbe.run!.revealed, isTrue);
      expect(M6DigProbe.run!.stage, M6DigStage.dig);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.pegDrain.key);
      expect(await _waitFor(t, () => M6DigProbe.descending), isTrue);
      expect(_label(L.flag), findsOneWidget);
      await _close(t, c);
    });

    final twoClear = _seedWhere((d) => !d.onRoute[0] && !d.onRoute[1]);
    testWidgets('three slips strike the level out (a wrong peg, then needless stops or his myth on clear circles)', (t) async {
      final d = m6DigDeal(math.Random(twoClear));
      final c = await _open(t, twoClear);
      await _peg(t, d, const [kM6Pole, kM6Dtr]);
      expect(find.text(Mk.pegMissed.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      for (var i = 0; i < 2; i++) {
        expect(await _waitFor(t, () => M6DigProbe.run!.spot == i), isTrue);
        if (d.coworkerSpot == i) {
          expect(await _pumpUntil(t, find.byType(CoworkerPeek)), isTrue);
          await _pickWrong(t, L.coworker.wrong);
          await _pump(t, 800);
        } else {
          expect(await _waitFor(t, () => M6DigProbe.descending), isTrue);
          await _holdFlag(t);
          await _pump(t, 300);
        }
        if (i == 0) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), contains(Mk.pegMissed.key));
      await _close(t, c);
    });

    final routeFirst = _seedWhere((d) => d.onRoute[0] && d.coworkerSpot != 0);
    testWidgets('no flag over the route: the bucket strikes — the scene freezes first, then the card (near-miss)', (t) async {
      final d = m6DigDeal(math.Random(routeFirst));
      final c = await _open(t, routeFirst);
      await _pegRight(t, d);
      expect(await _waitFor(t, () => M6DigProbe.descending), isTrue);
      expect(await _pumpUntil(t, find.byType(FreezeFrame), maxMs: 8000), isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.digStrike.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the app hidden mid-descent: the bucket waits there; back, it comes on down', (t) async {
      final d = m6DigDeal(math.Random(routeFirst));
      final c = await _open(t, routeFirst);
      await _pegRight(t, d);
      expect(await _waitFor(t, () => M6DigProbe.descending), isTrue);
      await _pump(t, 500);
      for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
      await _pump(t, 9000);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no strike while away');
      expect(M6DigProbe.run!.spotDone, isFalse);
      for (final s in [AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
      await t.pump(const Duration(milliseconds: 100));
      expect(M6DigProbe.descending, isTrue, reason: 'on down again');
      await _holdFlag(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a flag let go before its ring is full stops nothing', (t) async {
      final d = m6DigDeal(math.Random(routeFirst));
      final c = await _open(t, routeFirst);
      await _pegRight(t, d);
      expect(await _waitFor(t, () => M6DigProbe.descending), isTrue);
      await _holdFlag(t, ms: 400);
      expect(M6DigProbe.descending, isTrue, reason: 'the machine goes on');
      expect(M6DigProbe.run!.spotDone, isFalse);
      // Held in time now: right.
      await _holdFlag(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    /// Holds the flag from now (the bucket not yet coming down) until the
    /// flag's reason deck comes up; the scene must never freeze.
    Future<void> holdEarlyThrough(WidgetTester t) async {
      expect(await _pumpUntil(t, _label(L.flag)), isTrue, reason: 'the flag is shown');
      expect(M6DigProbe.descending, isFalse, reason: 'pressed before the descent');
      final g = await t.startGesture(t.getCenter(_label(L.flag)));
      var deck = false;
      for (var ms = 0; ms < 12000 && !deck; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
        expect(find.byType(FreezeFrame), findsNothing, reason: 'a steady early hold never lets the bucket strike');
        deck = find.byType(ChoiceDeck).evaluate().isNotEmpty;
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
      expect(deck, isTrue, reason: 'the flag reason');
    }

    testWidgets('a flag held from the drive on: its ring starts with the descent and stops the bucket (right)', (t) async {
      final d = m6DigDeal(math.Random(routeFirst));
      final c = await _open(t, routeFirst);
      await _pegRight(t, d);
      expect(await _waitFor(t, () => M6DigProbe.run!.stage == M6DigStage.dig), isTrue);
      await holdEarlyThrough(t);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M6DigWhy.flag]!);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty);
      expect(M6DigProbe.run!.slips, 0);
      await _close(t, c);
    });

    final cwRoute = _seedWhere((d) => d.onRoute[0] && d.coworkerSpot == 0);
    testWidgets('he is refused over the route and the flag is pressed at once and held: the bucket stops (right, never deadly)', (t) async {
      final d = m6DigDeal(math.Random(cwRoute));
      final c = await _open(t, cwRoute);
      await _pegRight(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final r = _onScreen(L.coworker.right);
      expect(r, hasLength(1));
      await t.tap(r.single, warnIfMissed: false);
      await tapReasonProceed(t);
      await holdEarlyThrough(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final listenRoute = cwRoute;
    testWidgets('listening to myth 1 over the route = deadly: freeze, then the card', (t) async {
      final d = m6DigDeal(math.Random(listenRoute));
      final c = await _open(t, listenRoute);
      await _pegRight(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pickWrong(t, L.coworker.wrong);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.pushStrike.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the pole top, the ends and every cover alike; a drag on a tapped cover; none in the dig stage', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m6DigDeal(math.Random(plain));
      final lay = d.layoutOn(_geo);
      final c = await _open(t, plain);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the peg stage');
      expect(scene().debugOptions, hasLength(d.covers + 3), reason: 'pole top, pole foot, DTR entry and every cover');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // A cover tapped three times with no chain: the upward drag on it.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(lay.covers[0] * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a sweep');
      expect(find.byType(MistakeCard), findsNothing);
      await _pegRight(t, d);
      expect(await _waitFor(t, () => M6DigProbe.run!.stage == M6DigStage.dig), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the dig stage and the flag get no hand');
      await _close(t, c);
    });
  });
}
