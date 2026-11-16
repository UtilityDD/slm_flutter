// Lesson 8.5 (সেফটি কোড), কাজ "দুই প্রান্তে কবচ — রড, তারপর চেইন" (rulings
// M8-1, M8-5, M8-17, X1, X2): the rules (the substation: padlock, board, the
// key in the pocket; the tester live → 0 V → live; the rod after its clamp
// and the proof; the chain pulled, discarded or thrown after the rod; the
// flick's strength and aim; the climb; the close with the mate's clearance),
// the deal, the libraries, the coworker's pushes (myth 3 word for word;
// listening = the act he pushes), the drawn places, and the level in the
// shell: the guide first, two full clean plays (myth at his end; the early
// removal in the close), the two-step climb, a slip card that keeps the
// place, three slips, the deadly freezes (own act; listening to the myth),
// his end's first kit touch waits for him, the praise window takes no touch,
// and the gesture hand shows how (never what).
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
import 'package:slm_flutter/features/game/m8_chain_throw.dart';
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
  rungId: '8.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8ChainThrowPacks['do_8_5_b']!;
typedef L = M8ChainLines;
typedef Mk = M8ChainMistakes;

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
final _h = (360 * 850 / 392).clamp(560.0, 900.0);
M8Geo get _geo => M8Geo.forScene(_h, 0);
M8ChainRun get _live => M8ChainThrowProbe.run!;
M8EndGeo _eg(int e) => M8EndGeo(_geo, _live.deal.ends[e].spec);

Future<void> _drag(WidgetTester t, Offset from, Offset by, {int after = 300}) async {
  final g = await t.startGesture(from * _k);
  for (var k = 1; k <= 8; k++) {
    await g.moveTo((from + by * (k / 8)) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, after);
}

Future<void> _dragTo(WidgetTester t, Offset from, Offset to, {int after = 300}) => _drag(t, from, to - from, after: after);

Future<void> _press(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 700);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8ChainThrowPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8ChainDeal(math.Random(s))));

int _slotOf(M8TrayItem it) => _live.tray.indexOf(it);

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t, M8Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

// --- the substation, played right ---------------------------------------------
Future<void> _lock(WidgetTester t, {bool key = true}) async {
  final g = _geo;
  await _dragTo(t, g.slot(_slotOf(M8TrayItem.padlock)).center, g.handle);
  expect(_live.padlock, isTrue);
  await _dragTo(t, g.slot(_slotOf(M8TrayItem.board)).center, g.handle);
  expect(_live.board, isTrue);
  if (key) {
    expect(_live.key, M8Key.popped);
    await _dragTo(t, g.keyAt, g.pocket);
    expect(_live.key, M8Key.pocket);
  }
}

Future<void> _toSpan(WidgetTester t) async {
  await _lock(t);
  await _pickRight(t, L.whyRight[M8Why.key]!);
  await _pump(t, 1500);
  await _press(t, L.leave);
  expect(_live.station, M8Station.work);
}

// --- one end, played right --------------------------------------------------------
Future<void> _prove(WidgetTester t, int e) async {
  final g = _eg(e);
  await _dragTo(t, g.tester, g.prover);
  await _dragTo(t, g.tester, Offset(g.poleX, g.armY));
  await _dragTo(t, g.tester, g.prover);
  expect(_live.proofDone, isTrue);
}

Future<void> _rod(WidgetTester t, int e) async {
  final g = _eg(e);
  await _dragTo(t, g.clampRest, g.spike);
  expect(_live.ends[e].clamped, isTrue);
  final gest = await t.startGesture(g.rodRest * _k);
  final to = Offset(g.poleX, g.armY);
  for (var k = 1; k <= 10; k++) {
    await gest.moveTo((g.rodRest + (to - g.rodRest) * (k / 10)) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  expect(_live.ends[e].hookX, isNotNull, reason: 'the hook is on the line');
  await _pump(t, 2100);
  await gest.up();
  await _pump(t, 300);
  expect(_live.ends[e].drained, isTrue, reason: 'held to the end: drained');
}

Future<void> _pullThree(WidgetTester t, int e) async {
  final g = _eg(e);
  for (var i = 0; i < 3; i++) {
    await _drag(t, g.bag, const Offset(0, -70));
  }
  expect(_live.ends[e].at, M8ChainAt.coil);
}

Future<void> _throwFull(WidgetTester t, int e) async {
  final g = _eg(e);
  await _drag(t, g.coil, m8FlickFor(g), after: 900);
}

/// The end built right: tester (first end), rod, the chain (the bad one
/// into the crate first), the throw; then both reasons.
Future<void> _playEnd(WidgetTester t, int e, {required bool first, required int order, bool reasons = true}) async {
  final d = _live.deal;
  if (d.push == M8Push.myth && d.coworkerEnd == e) await _refuse(t, d.push);
  if (first) {
    await _prove(t, e);
    await _pickRight(t, L.whyRight[M8Why.tester]!);
    await _pump(t, 1500);
  }
  await _rod(t, e);
  await _pullThree(t, e);
  final g = _eg(e);
  if (!m8ChainGood(_live.ends[e].chain)) {
    await _dragTo(t, g.coil, g.crate.center);
    expect(_live.ends[e].swapped, isTrue);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the swap reason');
    await _pump(t, 400);
    await _pickRight(t, L.whyRight[M8Why.swap]!);
    await _pump(t, 1500);
    await _pullThree(t, e);
  }
  await _throwFull(t, e);
  expect(_live.ends[e].chainFull, isTrue, reason: 'draped on all three');
  if (!reasons) return;
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the end reason');
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[order == 1 ? M8Why.order : M8Why.both]!);
  await _pump(t, 1800);
}

Future<void> _goEnd(WidgetTester t, int e) async {
  await _press(t, e == 0 ? L.walkLeft : L.walkRight);
  expect(_live.station, e == 0 ? M8Station.endA : M8Station.endB);
}

Future<void> _back(WidgetTester t) async {
  await _press(t, L.walkBack);
  expect(_live.station, M8Station.work);
}

M8Deal _dealOf({
  M8ChainKind c0 = M8ChainKind.brass,
  M8ChainKind c1 = M8ChainKind.copper,
  M8Push push = M8Push.myth,
  int cw = 0,
  bool mir0 = false,
  bool mir1 = true,
}) =>
    M8Deal(
      ends: [
        M8EndDeal(spec: M8EndSpec(mirrored: mir0, standDx: 60, condF: 0.12, spread: 30, raise: 0), chain: c0, defectSeg: 1),
        M8EndDeal(spec: M8EndSpec(mirrored: mir1, standDx: 70, condF: 0.08, spread: 26, raise: 14), chain: c1, defectSeg: 2),
      ],
      tray: const [M8TrayItem.torch, M8TrayItem.padlock, M8TrayItem.board, M8TrayItem.rag],
      push: push,
      coworkerEnd: cw,
      mateMs: 5000,
      spare: M8ChainKind.brass,
    );

final _g800 = M8Geo.forScene(800, 0);
M8EndGeo _eo(M8ChainRun r, int e) => M8EndGeo(_g800, r.deal.ends[e].spec);

/// The substation done right and the walk to the work pole.
M8ChainRun _field({M8Deal? deal}) {
  final r = M8ChainRun(deal ?? _dealOf());
  r.dropItem(r.tray.indexOf(M8TrayItem.padlock));
  r.dropItem(r.tray.indexOf(M8TrayItem.board));
  r.placeKey(M8Key.pocket);
  r.leave();
  return r;
}

void _proveAll(M8ChainRun r) {
  r.test(M8TestAt.prover);
  r.test(M8TestAt.line);
  r.test(M8TestAt.prover);
}

void _earth(M8ChainRun r, int e) {
  r.setClamp(e);
  r.hookRod(e, _eo(r, e).poleX);
  r.drainDone(e);
}

M8ThrowRes _chainOn(M8ChainRun r, int e, {Offset? flick}) {
  for (var i = 0; i < 3; i++) {
    r.pull(e);
  }
  final g = _eo(r, e);
  return r.throwChain(e, flick ?? m8FlickFor(g), g).res;
}

/// The lesson's text, with the app's nukta form (U+09AF U+09BC …).
String _nukta(String s) => s
    .replaceAll(String.fromCharCode(0x09DF), String.fromCharCodes([0x09AF, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DC), String.fromCharCodes([0x09A1, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DD), String.fromCharCodes([0x09A2, 0x09BC]));

/// The precomposed ড় ঢ় য় (the app writes base + nukta).
final _precomposed = RegExp('[${String.fromCharCodes([0x09DC, 0x09DD, 0x09DF])}]');

void main() {
  group('rules', () {
    test('deals: exactly one bad chain at one end (never only bad pulls); ends mirrored independently; the tray holds the padlock and the board; push 2 in 3 myth; ranges', () {
      final seen = <String>{};
      var myth = 0;
      var mirrored = 0;
      final kinds = <M8ChainKind>{};
      final ends = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m8ChainDeal(math.Random(s));
        final bad = d.ends.where((e) => !m8ChainGood(e.chain)).toList();
        expect(bad, hasLength(1), reason: 'seed $s');
        expect(d.ends.where((e) => m8ChainGood(e.chain)), hasLength(1), reason: 'never only bad pulls');
        expect(m8ChainGood(d.spare), isTrue);
        if (bad.single.chain == M8ChainKind.bentHook) expect(bad.single.defectSeg, 2, reason: 'the hook shows with the last stretch');
        kinds.add(bad.single.chain);
        expect(d.tray, hasLength(4));
        expect(d.tray, containsAll([M8TrayItem.padlock, M8TrayItem.board]));
        expect(d.tray.toSet(), hasLength(4));
        for (final e in d.ends) {
          expect(e.spec.standDx, inInclusiveRange(40, 80));
          expect(e.spec.condF, inInclusiveRange(0.06, 0.18));
          expect(e.spec.reach, inInclusiveRange(150, 210));
          expect(e.spec.spread, inInclusiveRange(24, 36));
          expect([0.0, 14.0], contains(e.spec.raise));
          if (e.spec.mirrored) mirrored++;
        }
        if (d.push == M8Push.myth) myth++;
        ends.add(d.coworkerEnd);
        expect(d.mateMs, inInclusiveRange(5000, 8500));
        seen.add('${d.ends.map((e) => '${e.chain.index}${e.spec.mirrored}${e.spec.standDx}${e.spec.condF}').join('|')}|${d.tray.map((e) => e.index).join()}|${d.push.index}${d.coworkerEnd}');
      }
      expect(seen.length, greaterThan(280));
      expect(myth, inInclusiveRange(170, 230), reason: 'myth ~2 plays in 3');
      expect(mirrored, inInclusiveRange(240, 360), reason: 'about half mirrored');
      expect(kinds, {M8ChainKind.rusty, M8ChainKind.broken, M8ChainKind.bentHook, M8ChainKind.iron});
      expect(ends, {0, 1});
    });

    test('the throw: short falls back, too strong slides off, in the middle aimed over the pole it drapes all three; the edges and a sideways aim lie on one or two phases; far aside misses', () {
      for (var s = 0; s < 80; s++) {
        final d = m8ChainDeal(math.Random(s));
        for (final ed in d.ends) {
          final e = M8EndGeo(_g800, ed.spec);
          expect(m8ThrowOf(m8FlickFor(e, q: 0.6), e).kind, M8ThrowKind.short, reason: 'seed $s');
          expect(m8ThrowOf(m8FlickFor(e, q: 1.7), e).kind, M8ThrowKind.over);
          for (final q in [1.05, 1.15, 1.3]) {
            final t = m8ThrowOf(m8FlickFor(e, q: q), e);
            expect(t.kind, M8ThrowKind.full, reason: 'seed $s q $q');
            expect(t.phases, 3);
          }
          for (final q in [0.85, 0.95, 1.4, 1.48]) {
            final t = m8ThrowOf(m8FlickFor(e, q: q), e);
            expect(t.kind, M8ThrowKind.partial, reason: 'seed $s q $q: edge of the range');
            expect(t.phases, inInclusiveRange(1, 2));
          }
          for (final side in [-1.0, 1.0]) {
            final p = m8ThrowOf(m8FlickFor(e, lateral: 72 * side), e);
            expect(p.kind, M8ThrowKind.partial, reason: 'seed $s: aimed ${72 * side} off');
            expect(p.phases, inInclusiveRange(1, 2));
            expect(m8ThrowOf(m8FlickFor(e, lateral: 150 * side), e).kind, M8ThrowKind.beside);
          }
        }
      }
      // A straight-up flick is not the right angle (the end hint is generic).
      final e = M8EndGeo(_g800, const M8EndSpec(mirrored: false, standDx: 80, condF: 0.12, spread: 24, raise: 0));
      expect(m8ThrowOf(Offset(0, -e.s.reach * 1.15), e).kind, isNot(M8ThrowKind.full));
    });

    test('the substation: the padlock pops the key; a decoy fits nothing; the pocket is right; the hook board or the operator = slip (once); leaving needs the key put away', () {
      final r = M8ChainRun(_dealOf());
      final lock = r.tray.indexOf(M8TrayItem.padlock);
      final board = r.tray.indexOf(M8TrayItem.board);
      expect(r.dropItem(0), M8Drop.needless, reason: 'a torch');
      expect(r.tray[0], M8TrayItem.torch, reason: 'it stays on the tray');
      expect(r.key, M8Key.inLock);
      expect(r.dropItem(lock), M8Drop.padlock);
      expect(r.key, M8Key.popped);
      expect(r.tray[lock], isNull);
      expect(r.dropItem(lock), M8Drop.none);
      expect(r.leave().res, M8Leave.keyFirst, reason: 'the key out of the lock first');
      expect(r.slips, 0);
      final bad = r.placeKey(M8Key.operator);
      expect(bad.slip, Mk.keyNotPocket);
      expect(r.key, M8Key.popped, reason: 'it stays out');
      expect(r.placeKey(M8Key.hook).again, isTrue, reason: 'once: no second slip');
      expect(r.slips, 1);
      expect(r.keyAsk, isFalse, reason: 'slipped first: no reason for the key');
      expect(r.placeKey(M8Key.pocket).ok, isTrue);
      final no = r.leave();
      expect((no.res, no.slip), (M8Leave.slip, Mk.noBoard), reason: 'padlock on, board missing');
      expect(r.leave().res, M8Leave.again);
      expect(r.slips, 2);
      r.dropItem(board);
      expect(r.leave().res, M8Leave.done);
      expect(r.phase, M8Phase.field);
      expect(r.station, M8Station.work);
      final none = M8ChainRun(_dealOf());
      expect(none.leave().slip, Mk.noPadlock, reason: 'no padlock at all');
      final ok = M8ChainRun(_dealOf());
      ok.dropItem(ok.tray.indexOf(M8TrayItem.padlock));
      ok.placeKey(M8Key.pocket);
      expect(ok.keyAsk, isTrue);
    });

    test('the tester: the line read before the proof = slip (once); live → 0 V → live; each step counts once; a proved line stops the tester', () {
      final r = _field();
      final first = r.test(M8TestAt.line);
      expect(first.mistake, Mk.testerUnproved);
      expect(first.reading, '0 V');
      expect(r.zero, isFalse, reason: 'unproved: not 0 V yet');
      expect(r.test(M8TestAt.line).again, isTrue);
      expect(r.slips, 1);
      expect(r.test(M8TestAt.prover).reading, 'LIVE');
      expect(r.test(M8TestAt.line).reading, '0 V');
      expect(r.zero, isTrue);
      expect(r.proofDone, isFalse);
      final last = r.test(M8TestAt.prover);
      expect(last.provenNow, isTrue);
      expect(r.proofDone, isTrue);
      expect(r.caught, contains(L.caughtTester));
      expect(r.test(M8TestAt.line).mistake, isNull);
    });

    test('the rod: the hook before the clamp is DEADLY (R5); before 0 V a slip (N2, once; the rod comes back); before the second proof a slip (N3b); then it hangs on the line and drains', () {
      final d = M8ChainRun(_dealOf());
      final cut = _field();
      final h = cut.hookRod(0, 292);
      expect(h.res, M8Hook.deadly);
      expect(cut.deadly, Mk.hookFirst);
      expect(Mk.hookFirst.deadly, isTrue);
      expect(cut.ended, isTrue);
      expect(d.deadly, isNull);
      final r = _field();
      r.setClamp(0);
      final early = r.hookRod(0, 292);
      expect((early.res, early.mistake), (M8Hook.slip, Mk.rodEarly));
      expect(r.ends[0].hookX, isNull, reason: 'the rod comes back');
      expect(r.hookRod(0, 292).res, M8Hook.again, reason: 'once: no second slip');
      expect(r.slips, 1);
      r.test(M8TestAt.prover);
      r.test(M8TestAt.line);
      final re = r.hookRod(0, 292);
      expect((re.res, re.mistake), (M8Hook.slip, Mk.testerNotRechecked));
      r.test(M8TestAt.prover);
      expect(r.hookRod(0, 300).res, M8Hook.hooked);
      expect(r.ends[0].hookX, 300);
      expect(r.ends[0].drained, isFalse);
      r.unhook(0);
      expect(r.ends[0].hookX, isNull, reason: 'lifted early: it slips off');
      r.hookRod(0, 300);
      r.drainDone(0);
      expect(r.ends[0].drained, isTrue);
      r.unhook(0);
      expect(r.ends[0].hookX, 300, reason: 'drained: stays');
      expect(r.slips, 2);
    });

    test('the chain: three pulls coil it; the bad one in the crate is right (the van\'s good spare comes); a good one is needless (the bonus only)', () {
      final r = _field(deal: _dealOf(c0: M8ChainKind.rusty));
      expect(r.pull(0), isTrue);
      expect(r.ends[0].at, M8ChainAt.bag);
      r.pull(0);
      r.pull(0);
      expect(r.ends[0].at, M8ChainAt.coil);
      expect(r.pull(0), isFalse);
      expect(r.discard(0), M8Discard.right);
      expect(r.ends[0].crate, M8ChainKind.rusty);
      expect(r.ends[0].chain, M8ChainKind.brass);
      expect(r.ends[0].at, M8ChainAt.bag);
      expect(r.ends[0].pulled, 0);
      expect(r.ends[0].swapped, isTrue);
      expect(r.caught, contains(L.caughtSwap));
      expect(r.ends[0].thorough, isTrue, reason: 'the right swap costs nothing');
      for (var i = 0; i < 3; i++) {
        r.pull(0);
      }
      expect(r.discard(0), M8Discard.needless, reason: 'the spare is good');
      expect(r.ends[0].wasted, isTrue);
      expect(r.ends[0].thorough, isFalse);
      expect(r.slips, 0);
      expect(r.discard(0), M8Discard.none, reason: 'nothing coiled');
    });

    test('a chain thrown at an end before its rod has drained = DEADLY (R4), whatever the throw; not a throw (a short or sideways stroke) = nothing', () {
      final r = _field();
      for (var i = 0; i < 3; i++) {
        r.pull(0);
      }
      final g = _eo(r, 0);
      expect(r.throwChain(0, const Offset(0, -20), g).res, M8ThrowRes.none);
      expect(r.throwChain(0, const Offset(0, 80), g).res, M8ThrowRes.none);
      expect(r.throwChain(0, const Offset(200, -40), g).res, M8ThrowRes.none);
      expect(r.deadly, isNull);
      final t = r.throwChain(0, m8FlickFor(g, q: 0.6), g);
      expect(t.res, M8ThrowRes.deadly, reason: 'even one that falls back: the chain was meant as the earth');
      expect(t.mistake, Mk.chainFirst);
      expect(r.deadly, Mk.chainFirst);
      expect(Mk.chainFirst.deadly, isTrue);
      // The rod hooked but not drained yet is still before the rod.
      final h = _field();
      h.setClamp(0);
      _proveAll(h);
      h.hookRod(0, 292);
      for (var i = 0; i < 3; i++) {
        h.pull(0);
      }
      expect(h.throwChain(0, m8FlickFor(_eo(h, 0)), _eo(h, 0)).res, M8ThrowRes.deadly);
    });

    test('after the rod: a bad chain thrown = slip (R13, once; the spare comes); short and over are free retries; a partial lies on 1–2 phases and is tugged down and thrown again; full drapes all three', () {
      for (final bad in [M8ChainKind.rusty, M8ChainKind.broken, M8ChainKind.bentHook, M8ChainKind.iron]) {
        final r = _field(deal: _dealOf(c0: bad));
        _proveAll(r);
        _earth(r, 0);
        expect(_chainOn(r, 0), M8ThrowRes.slip, reason: '$bad');
        expect(r.ends[0].chain, M8ChainKind.brass);
        expect(r.ends[0].at, M8ChainAt.bag);
        expect(r.slips, 1);
        expect(r.ends[0].crate, bad);
      }
      final r = _field();
      _proveAll(r);
      _earth(r, 0);
      for (var i = 0; i < 3; i++) {
        r.pull(0);
      }
      final g = _eo(r, 0);
      expect(r.throwChain(0, m8FlickFor(g, q: 0.6), g).res, M8ThrowRes.short);
      expect(r.throwChain(0, m8FlickFor(g, q: 1.7), g).res, M8ThrowRes.over);
      expect(r.throwChain(0, m8FlickFor(g, lateral: 150), g).res, M8ThrowRes.beside);
      expect(r.ends[0].at, M8ChainAt.coil, reason: 'a free retry');
      expect(r.slips, 0);
      expect(r.throwChain(0, m8FlickFor(g, lateral: 72), g).res, M8ThrowRes.partial);
      expect(r.ends[0].at, M8ChainAt.line);
      expect(r.ends[0].chainFull, isFalse);
      expect(r.ends[0].done, isFalse);
      expect(r.tug(0).res, M8Tug.back, reason: 'before the job: free');
      expect(r.ends[0].at, M8ChainAt.coil);
      expect(r.throwChain(0, m8FlickFor(g), g).res, M8ThrowRes.full);
      expect(r.ends[0].chainFull, isTrue);
      expect(r.finishEnd(0), 1);
      expect(r.finishEnd(0), isNull);
      expect(r.slips, 0);
      expect(r.caught, contains(L.caughtChain));
      // The mirrored end, the raised middle phase: the same.
      _earth(r, 1);
      expect(_chainOn(r, 1), M8ThrowRes.full);
      expect(r.finishEnd(1), 2);
    });

    test('walking on from an end with its chain on one or two phases = slip (R14, once an end); the climb: no 0 V = DEADLY (N1); a rod missing = DEADLY (R3); a chain partial or skipped = slip, once an end; then the job', () {
      final r = _field();
      expect(r.go(M8Station.endA).res, M8Walk.ok);
      expect(r.station, M8Station.endA);
      _proveAll(r);
      _earth(r, 0);
      _chainOn(r, 0, flick: m8FlickFor(_eo(r, 0), lateral: 72));
      expect(r.ends[0].at, M8ChainAt.line);
      final w = r.go(M8Station.work);
      expect((w.res, w.slip), (M8Walk.slip, Mk.chainPartial));
      expect(r.station, M8Station.endA, reason: 'the player stays');
      expect(r.go(M8Station.work).res, M8Walk.again);
      expect(r.slips, 1);
      r.tug(0);
      expect(r.go(M8Station.work).res, M8Walk.ok);
      expect(r.station, M8Station.work);
      // The climb with a rod missing at the far end.
      final rod = r.climb();
      expect((rod.res, rod.mistake), (M8Climb.deadly, Mk.climbNoRod));
      expect(Mk.climbNoRod.deadly, isTrue);
      // The climb with no tester at all.
      final z = _field();
      expect(z.climb().mistake, Mk.climbNoZero);
      expect(Mk.climbNoZero.deadly, isTrue);
      // Both rods on, one chain missing: a slip; again: refused; then the job.
      final c = _field();
      _proveAll(c);
      _earth(c, 0);
      _earth(c, 1);
      expect(c.climb().mistake, Mk.chainSkipped);
      expect(c.ends[0].slips, 1);
      expect(c.climb().res, M8Climb.again);
      expect(c.slips, 1);
      _chainOn(c, 0);
      _chainOn(c, 1, flick: m8FlickFor(_eo(c, 1), lateral: 72));
      expect(c.climb().mistake, Mk.chainPartial);
      expect(c.slips, 2);
      c.tug(1);
      _chainOn(c, 1);
      c.ends[1].lo = 0;
      expect(c.climb().res, M8Climb.ok);
      expect(c.phase, M8Phase.job);
    });

    test('the close: a tail tugged before clearance = slip (R15, once; the chain stays); after the wave it comes down; both down = done', () {
      final c = _field();
      _proveAll(c);
      _earth(c, 0);
      _earth(c, 1);
      _chainOn(c, 0);
      _chainOn(c, 1);
      expect(c.climb().res, M8Climb.ok);
      expect(c.tug(0).res, M8Tug.none, reason: 'in the job');
      c.startClose();
      expect(c.phase, M8Phase.close);
      expect(c.cleared, isFalse);
      final t = c.tug(0);
      expect((t.res, t.slip), (M8Tug.slip, Mk.tugEarly));
      expect(c.ends[0].at, M8ChainAt.line, reason: 'the chain stays');
      expect(c.tug(1).res, M8Tug.again, reason: 'once: no second slip');
      expect(c.slips, 1);
      c.clear();
      expect(c.tug(0).res, M8Tug.down);
      expect(c.phase, M8Phase.close);
      expect(c.tug(1).res, M8Tug.down);
      expect(c.phase, M8Phase.done);
      expect(c.caught, contains(L.caughtWait));
      expect(c.passed, isTrue);
      expect(c.percent, 85);
      expect(c.pushSlip(Mk.tugEarly), isFalse, reason: 'scored already');
    });

    test('three slips fail the play (85, 70, 55); a clean end pays its thorough bonus; each end counts its own', () {
      final r = _field();
      expect(r.slips, 0);
      expect(r.percent, 100);
      r.test(M8TestAt.line);
      r.setClamp(0);
      r.hookRod(0, 292);
      expect(r.slips, 2);
      expect(r.ends[0].thorough, isFalse);
      expect(r.ends[1].thorough, isTrue);
      expect(r.percent, 70);
      r.test(M8TestAt.prover);
      r.test(M8TestAt.line);
      r.hookRod(0, 292);
      expect(r.slips, 3);
      expect(r.percent, 55);
    });

    test('listening to him is the act he pushes (X2/B1): myth 3 (chain as the earth) deadly, the early removal a slip', () {
      expect(Mk.push(M8Push.myth), Mk.pushChain);
      expect(Mk.push(M8Push.myth).deadly, isTrue);
      expect(Mk.push(M8Push.early), Mk.tugEarly);
      expect(Mk.push(M8Push.early).deadly, isFalse);
      expect(Mk.deadlyKeys.toSet(), {Mk.chainFirst.key, Mk.pushChain.key, Mk.climbNoRod.key, Mk.climbNoZero.key, Mk.hookFirst.key});
      final r = _field();
      r.failDeadly(Mk.pushChain);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
    });

    test('English digits; জল not পানি; the owner\'s terms; nukta form; every mistake has its picture; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.decoy,
        L.keyFirst,
        L.fellShort,
        L.slidOff,
        L.beside,
        L.van,
        L.needlessDiscard,
        ...L.allAgain,
        L.sceneLabel,
        L.boardText,
        L.docket,
        L.crate,
        L.feeder,
        L.leave,
        L.walkLeft,
        L.walkRight,
        L.walkBack,
        L.climb,
        ...L.progressLabels,
        ...L.whyQ.values,
        ...L.allWhyRight,
        for (final l in L.whyWrong.values) ...l,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        ...L.caughtAll,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(RegExp('মৃত|মরা|এলটি|এইচটি|কেভি|AB বন্ধ').hasMatch(l), isFalse, reason: 'owner term rules: $l');
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|[,।]|$)').hasMatch(l), isFalse, reason: 'ON / OFF in English letters: $l');
        expect(_precomposed.hasMatch(l), isFalse, reason: 'nukta as base + U+09BC: $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.5/m8_chain_throw/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 5));
      }
      expect(Mk.all.where((m) => m.deadly), hasLength(5));
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_chain_throw/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8ChainThrowPacks.keys, ['do_8_5_b']);
      expect(L.progressLabels, hasLength(4));
    });

    test('libraries: same length within each deck, big enough, never a rule marked wrong; the coworker\'s choices alike', () {
      for (final w in M8Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.whyWrong[w]!);
        expectSameLength('why $w', [...L.whyRight[w]!, ...L.whyWrong[w]!]);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.whyWrong[w]!, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect({for (final w in L.whyWrong.values) ...w}.intersection(L.allWhyRight.toSet()), isEmpty);
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his myth line is lesson 8.5\'s myth 3 word for word; every spoken line is listed', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      final lesson = _nukta(File('tool/all_training_chapters_bn.json').readAsStringSync());
      final myths = <String>[];
      void walk(Object? o) {
        if (o is Map) {
          if (o['myth'] is String) myths.add(o['myth'] as String);
          o.values.forEach(walk);
        } else if (o is List) {
          o.forEach(walk);
        }
      }

      walk(jsonDecode(lesson));
      expect(L.newRivalLines, hasLength(2));
      expect(myths, contains(L.coworkerMyth.line), reason: 'word for word');
      expect({for (final p in M8Push.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            ...L.tapWhy,
            L.decoy,
            L.keyFirst,
            L.fellShort,
            L.slidOff,
            L.beside,
            L.van,
            L.needlessDiscard,
            ...L.allAgain,
            ...L.whyQ.values,
            for (final cw in L.allCoworkers) ...cw.asks,
            for (final p in M8Push.values) L.callHeld(p),
            L.allSet,
            L.quick,
            L.fail,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_chain_throw: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas stay on the scene, clear of the header, the guide and the button row, and do not overlap (both layouts)', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M8Geo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        // The substation.
        final sub = <Rect>[
          for (var i = 0; i < 4; i++) g.slot(i).inflate(4),
          g.handleHit,
          g.keyHit,
          g.pocketHit,
          g.hookBoardHit,
          g.operatorHit,
        ];
        for (final r in sub) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the button row');
        }
        for (final (k, a) in sub.indexed) {
          for (final b in sub.skip(k + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        for (final mir in [false, true]) {
          for (final dx in [40.0, 80.0]) {
            for (final cf in [0.06, 0.18]) {
              final spec = M8EndSpec(mirrored: mir, standDx: dx, condF: cf, spread: 36, raise: 14);
              final e = M8EndGeo(g, spec);
              final taps = <Rect>[e.testerHit, e.proverHit, e.bagHit, e.clampHit, e.rodHit, e.coilHit, e.spikeHit, e.crate, e.tailHit(0, 2), e.tailHit(0, 1), e.tailHit(1, 2)];
              for (final r in taps) {
                expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h mir $mir dx $dx: $r');
                expect(r.right, lessThanOrEqualTo(360), reason: 'h $h mir $mir dx $dx: $r');
                expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
                expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the button row');
                if (!mir) expect(r.overlaps(guide) && r != e.coilHit, isFalse, reason: 'h $h: $r under the guide');
              }
              for (final (k, a) in taps.indexed) {
                for (final b in taps.skip(k + 1)) {
                  // The three tails are one place (never at once).
                  if ({a, b}.every((x) => x == e.tailHit(0, 2) || x == e.tailHit(0, 1) || x == e.tailHit(1, 2))) continue;
                  expect(a.overlaps(b), isFalse, reason: 'h $h mir $mir dx $dx cf $cf: $a / $b');
                }
              }
              // The wires' band is clear of the pins' tester drop and the rod's head box stays on the scene.
              expect(e.lineBand.top, greaterThan(100));
              expect(e.rodHeadHit(e.pins[1].dx).top, greaterThan(100));
              // The kit is on the tarp.
              expect(e.tarp.contains(e.tester), isTrue);
              expect(e.tarp.contains(e.bag), isTrue);
            }
          }
        }
        expect(g.floorY, lessThan(h));
        expect(guide.top, greaterThan(0));
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

    testWidgets('the guide comes first: a tap does not skip him; then the bench, the handle and the leave button', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8ChainThrowPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.leave), findsOneWidget);
      expect(_label(L.feeder), findsOneWidget);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    final quiet = _seedWhere((d) => d.push == M8Push.myth && d.coworkerEnd == 1 && m8ChainGood(d.ends[0].chain));
    testWidgets('tapping the guide repeats the task, a different way each time; the padlock fitted, the task moves on', (t) async {
      final c = await _open(t, quiet);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askLock)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _dragTo(t, _geo.slot(_slotOf(M8TrayItem.padlock)).center, _geo.handle);
      expect(_live.key, M8Key.popped);
      expect(c.read(guideDirectorProvider).line, contains(L.askKey));
      await _close(t, c);
    });

    // One play: the myth at the right end, the first end left; one: the early
    // removal in the close, the bad chain at the left end.
    final flowSeeds = [
      _seedWhere((d) => d.push == M8Push.myth && d.coworkerEnd == 1 && !m8ChainGood(d.ends[0].chain)),
      _seedWhere((d) => d.push == M8Push.early && !m8ChainGood(d.ends[1].chain)),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): lock, key, tester, rod, chain, both ends, the climb, the mate\'s clearance, the tails; he is refused → pass', (t) async {
        final d = m8ChainDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _toSpan(t);
        expect(_live.slips, 0);
        await _goEnd(t, 0);
        await _playEnd(t, 0, first: true, order: 1);
        await _back(t);
        await _goEnd(t, 1);
        await _playEnd(t, 1, first: false, order: 2);
        await _back(t);
        expect(_live.ends.every((e) => e.done), isTrue);
        // The climb: two steps.
        await t.tap(_label(L.climb));
        await _pump(t, 300);
        expect(find.byType(CardPreviewOverlay), findsOneWidget);
        expect(_live.phase, M8Phase.field);
        expect(await confirmChoice(t), isTrue);
        await _pump(t, 600);
        expect(_live.phase, M8Phase.job, reason: 'the cutaway');
        expect(await _pumpUntil(t, find.byKey(const ValueKey('mate-descend-1')), maxMs: 5000), isTrue, reason: 'the mate comes down');
        expect(_live.phase, M8Phase.close);
        if (d.push == M8Push.early) {
          // A first tug waits for him.
          await _goEnd(t, 0);
          final e0 = _live.ends[0];
          final g = _eg(0);
          await _drag(t, Offset(g.tailX(e0.lo, e0.hi), g.armY + 60), const Offset(0, 90), after: 600);
          expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the tail waits for him');
          expect(_live.ends[0].at, M8ChainAt.line);
          await _pumpUntil(t, find.byType(ChoiceDeck));
          await _pump(t, 600);
          await _pickRight(t, L.coworkerEarly.right);
          await _pump(t, 2600);
          await _back(t);
        }
        // The mate's wave.
        await _pump(t, d.mateMs + 500);
        expect(_live.cleared, isTrue);
        for (final e in [0, 1]) {
          await _goEnd(t, e);
          final s = _live.ends[e];
          final g = _eg(e);
          await _drag(t, Offset(g.tailX(s.lo, s.hi), g.armY + 60), const Offset(0, 90), after: 600);
          expect(s.at, M8ChainAt.down, reason: 'end $e: tugged down after the wave');
          if (e == 0) await _back(t);
        }
        expect(await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 6000), isTrue);
        await _pump(t, 1000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.5/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.5/do/1'], greaterThan(0));
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtLock), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the climb is two steps: a tap opens it and answers nothing, ✕ sets it aside, ✓ judges it', (t) async {
      final c = await _open(t, quiet);
      await _toSpan(t);
      await t.tap(_label(L.climb));
      await _pump(t, 300);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      final aside = t.widget<CardAside>(find.ancestor(of: _label(L.climb), matching: find.byType(CardAside)));
      expect(aside.aside, isTrue, reason: 'set aside, dimmed');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a slip (leaving with no board) shows its card; the same place goes on; leaving again is refused, no second slip', (t) async {
      final c = await _open(t, quiet);
      final g = _geo;
      await _dragTo(t, g.slot(_slotOf(M8TrayItem.padlock)).center, g.handle);
      await _dragTo(t, g.keyAt, g.pocket);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M8Why.key]!);
      await _pump(t, 1500);
      await _press(t, L.leave);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.noBoard.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.station, M8Station.sub, reason: 'the same place');
      await _press(t, L.leave);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.again(Mk.noBoard)));
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noBoard.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (the key to the operator, leaving with no board, the line read before the proof)', (t) async {
      final c = await _open(t, quiet);
      final g = _geo;
      // A lock first, then the key to the operator's hand.
      await _dragTo(t, g.slot(_slotOf(M8TrayItem.padlock)).center, g.handle);
      await _dragTo(t, g.keyAt, g.operatorHand);
      expect(find.text(Mk.keyNotPocket.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _dragTo(t, g.keyAt, g.pocket);
      expect(_live.key, M8Key.pocket);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'slipped on the key first: no key reason');
      await _press(t, L.leave);
      expect(find.text(Mk.noBoard.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _dragTo(t, g.slot(_slotOf(M8TrayItem.board)).center, g.handle);
      await _press(t, L.leave);
      await _goEnd(t, 0);
      final e = _eg(0);
      await _dragTo(t, e.tester, Offset(e.poleX, e.armY));
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the hook before the clamp: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, quiet);
      await _toSpan(t);
      await _goEnd(t, 0);
      final e = _eg(0);
      await _dragTo(t, e.rodRest, Offset(e.poleX, e.armY), after: 400);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.hookFirst.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the chain before the rod = deadly: a flick with the rod not on freezes the scene', (t) async {
      final seed = _seedWhere((d) => d.push == M8Push.early);
      final c = await _open(t, seed);
      await _toSpan(t);
      await _goEnd(t, 0);
      await _pullThree(t, 0);
      await _throwFull(t, 0);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.chainFirst.key);
      await _close(t, c);
    });

    testWidgets('the climb with nothing done: deadly (no 0 V)', (t) async {
      final seed = _seedWhere((d) => d.push == M8Push.early);
      final c = await _open(t, seed);
      await _toSpan(t);
      await t.tap(_label(L.climb));
      await _pump(t, 300);
      expect(await confirmChoice(t), isTrue);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.climbNoZero.key);
      await _close(t, c);
    });

    final mythEnd0 = _seedWhere((d) => d.push == M8Push.myth && d.coworkerEnd == 0);
    testWidgets('myth 3: his end\'s first kit touch waits for him; listening (the chain thrown as the earth) = deadly: freeze, then the card', (t) async {
      final c = await _open(t, mythEnd0);
      await _toSpan(t);
      await _goEnd(t, 1);
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'the other end: he is not there');
      await _back(t);
      await _goEnd(t, 0);
      final e = _eg(0);
      // A kit touch at once, inside his 1.2–2.4 s timer: it does nothing and he cuts in.
      await _dragTo(t, e.tester, e.prover, after: 400);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.reading, '- - -', reason: 'the tester did not run');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerMyth.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.pushChain.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final early = _seedWhere((d) => d.push == M8Push.early);
    testWidgets('the early removal: listening is a slip (the chain stays); a tail before his wave = the same slip once', (t) async {
      final c = await _open(t, early);
      final d = _live.deal;
      await _toSpan(t);
      await _goEnd(t, 0);
      await _playEnd(t, 0, first: true, order: 1);
      await _back(t);
      await _goEnd(t, 1);
      await _playEnd(t, 1, first: false, order: 2);
      await _back(t);
      await t.tap(_label(L.climb));
      await _pump(t, 300);
      await confirmChoice(t);
      await _pump(t, 3800);
      expect(_live.phase, M8Phase.close);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes in the close');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerEarly.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.tugEarly.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 1);
      expect(_live.ends.every((e) => e.at == M8ChainAt.line), isTrue, reason: 'the chains stay');
      expect(_live.cleared, isFalse);
      expect(d.mateMs, greaterThan(0));
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, quiet);
      final g = _geo;
      await _dragTo(t, g.slot(_slotOf(M8TrayItem.padlock)).center, g.handle);
      await _dragTo(t, g.slot(_slotOf(M8TrayItem.board)).center, g.handle);
      await _dragTo(t, g.keyAt, g.pocket);
      expect(_live.key, M8Key.pocket);
      // The ◆ on the table, the deck open at once: the scene and the button row take nothing.
      expect(_label(L.leave), findsNothing);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(g.handle * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(g.slot(_slotOf(M8TrayItem.torch)).center * _k, const Offset(0, -60));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8Why.key]!);
      await _pump(t, 2000);
      expect(_label(L.leave), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the tray first (no pick); the key out gets a straight-up nudge; a hand never presses', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, quiet);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the bench');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(scene().debugOptions.length, 4, reason: 'over all four tray items alike');
      final g = _geo;
      await _dragTo(t, g.slot(_slotOf(M8TrayItem.padlock)).center, g.handle);
      expect(scene().showing, isFalse);
      final empty = const Offset(180, 200) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugFrame?.ripple, isNull);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
