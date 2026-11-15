// Lesson 6.4 (AB সুইচ ও আইসোলেটর), কাজ 2 "জ্যাম ছাড়াও, লাইন জোড়ো": the rules
// (an unoiled jam never frees; oil + 3–5 rocks free it; oiling other points
// is free; the cloth clears the arcing marks and the dirty insulators; down
// with dirt left = a slip; a stalled stroke = a slip; breaker ON asked with the
// AB open then the stroke = deadly (closing on load), cancelled = a slip;
// breaker ON with a part-seated phase = a slip; listening takes his push's
// class: 'আগে ব্রেকার' deadly, 'একটু আলগা' a slip), the deal, the libraries,
// the coworker's place from the player's work, and the level in the shell:
// the guide first, a clean play (two reasons, the handle coworker refused), a
// play with the jam left (part-seated → the phone coworker refused → open,
// back up, oil, down, close → pass), a slip card, three slips, the deadly
// freezes, the stall, the ask-then-cancel, the handle waits for him on a fast
// play, and the gesture hand only while the level waits.
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
import 'package:slm_flutter/features/game/m6_ab_unjam.dart';
import 'package:slm_flutter/features/game/m6_ab_unjam_world.dart';
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
  rungId: '6.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6AbUnjamPacks['do_6_4_b']!;
typedef L = M6AbUnjamLines;
typedef Mk = M6AbUnjamMistakes;

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
M6UnjamGeo get _geo => M6UnjamGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6AbUnjamPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6UnjamDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m6UnjamDeal(math.Random(s))));

// --- hands on ----------------------------------------------------------------
Future<void> _rock(WidgetTester t) async {
  await t.dragFrom((_geo.leverGrip - const Offset(14, 0)) * _k, const Offset(44 * _k, 0));
  await _pump(t, 800);
}

Future<void> _tool(WidgetTester t, M6UnjamTool tool) async {
  await t.tap(_label(L.tool(tool)));
  await _pump(t, 300);
}

Future<void> _oil(WidgetTester t, int i) async {
  await t.longPressAt(_geo.pivot(i) * _k);
  await _pump(t, 300);
}

/// Back and forth inside [r] (design px): [moves] strokes of [len].
Future<void> _rub(WidgetTester t, Rect r, {bool vertical = false, int moves = 8}) async {
  final from = vertical ? Offset(r.center.dx, r.top + 8) : Offset(r.left + 8, r.center.dy);
  final len = vertical ? r.height - 16 : r.width - 16;
  final g = await t.startGesture(from * _k);
  for (var i = 0; i < moves; i++) {
    final s = i.isEven ? len : -len;
    await g.moveBy((vertical ? Offset(0, s) : Offset(s, 0)) * _k);
    await t.pump(const Duration(milliseconds: 30));
  }
  await g.up();
  await _pump(t, 200);
}

/// The cloth over every jaw and insulator alike (a clean one costs nothing).
Future<void> _cleanAll(WidgetTester t) async {
  await _tool(t, M6UnjamTool.cloth);
  for (var i = 0; i < 3; i++) {
    await _rub(t, _geo.jawHit(i));
    await _rub(t, _geo.insHit(i), vertical: true, moves: 6);
  }
}

/// The head put right: feel, oil (every point, or all but the jam), rock,
/// clean.
Future<void> _fixHead(WidgetTester t, M6UnjamDeal d, {bool oilJam = true}) async {
  await _rock(t);
  await _tool(t, M6UnjamTool.can);
  for (var i = 0; i < 4; i++) {
    if (oilJam || i != d.jam) await _oil(t, i);
  }
  for (var r = 0; r < d.rocks; r++) {
    await _rock(t);
  }
  await _cleanAll(t);
}

Future<void> _down(WidgetTester t) async {
  await t.longPress(_label(L.tool(M6UnjamTool.lanyard)));
  await _pump(t, 700);
}

/// Down the first time: the reason, then the line clear.
Future<void> _downFirst(WidgetTester t, M6UnjamDeal d, {required bool freed}) async {
  await _down(t);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'clean descent');
  await _pickRight(t, L.whyRight[m6UnjamMaintWhy(d, freed: freed)]!);
  await _pump(t, 3200);
}

Future<void> _refuse(WidgetTester t, M6UnjamPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

Future<void> _stroke(WidgetTester t, {required bool closing}) async {
  final a = _geo.knob(closing ? 0 : 1);
  final b = _geo.knob(closing ? 1 : 0);
  await t.dragFrom(a * _k, (b - a) * _k);
  await _pump(t, 500);
}

Future<void> _look(WidgetTester t) async {
  await t.dragFrom(_geo.swipeFrom * _k, const Offset(0, -110));
  await _pump(t, 500);
}

Future<void> _phoneAsk(WidgetTester t) async {
  await t.tapAt(_geo.phone * _k);
  await _pump(t, 300);
  expect(find.byKey(const ValueKey('phone-ask')), findsOneWidget);
  await t.tap(find.byKey(const ValueKey('phone-ask')));
  await _pump(t, 400);
}

// --- pure helpers --------------------------------------------------------------
M6UnjamDeal _deal({int jam = 1, int stuck = 1, int rocks = 3, Set<int> arcs = const {0}, Set<int> ins = const {}}) => M6UnjamDeal(
      type: M6UnjamType.tilting,
      jam: jam,
      stuck: stuck,
      rocks: rocks,
      arcs: arcs,
      dirtyIns: ins,
      pouch: const [M6UnjamTool.lanyard, M6UnjamTool.cloth, M6UnjamTool.can],
      whyRoll: 1,
    );

/// A run with the head put right (or the jam left) and on the ground after
/// the line clear.
M6UnjamRun _onGround({bool freed = true}) {
  final r = M6UnjamRun(_deal());
  if (freed) {
    r.oil(1);
    for (var i = 0; i < 3; i++) {
      r.rock();
    }
  }
  r.rub(M6UnjamRub.jaw, 0, m6UnjamRubPath);
  expect(r.comeDown(), isNull);
  r.lineClear();
  return r;
}

void main() {
  group('rules', () {
    test('deals: every jam place, 3–5 rocks, 1–3 arcing phases, 0–2 dirty insulators, both switch types; plays differ', () {
      final seen = <String>{};
      final jams = <int>{};
      final arcs = <int>{};
      final ins = <int>{};
      final rocks = <int>{};
      final types = <M6UnjamType>{};
      final pouches = <String>{};
      for (var s = 0; s < 200; s++) {
        final d = m6UnjamDeal(math.Random(s));
        expect(d.jam, inInclusiveRange(0, 3));
        if (d.jam < 3) expect(d.stuck, d.jam, reason: 'a pivot jam lags its own phase');
        expect(d.stuck, inInclusiveRange(0, 2));
        expect(d.rocks, inInclusiveRange(3, 5));
        expect(d.arcs.length, inInclusiveRange(1, 3));
        expect(d.dirtyIns.length, inInclusiveRange(0, 2));
        expect(d.pouch.toSet(), M6UnjamTool.values.toSet());
        jams.add(d.jam);
        arcs.add(d.arcs.length);
        ins.add(d.dirtyIns.length);
        rocks.add(d.rocks);
        types.add(d.type);
        pouches.add(d.pouch.map((p) => p.name).join());
        seen.add('${d.type.name}${d.jam}${d.stuck}${d.rocks}|${(d.arcs.toList()..sort()).join()}|${(d.dirtyIns.toList()..sort()).join()}|${d.pouch.map((p) => p.index).join()}');
      }
      expect(jams, {0, 1, 2, 3});
      expect(arcs, {1, 2, 3});
      expect(ins, {0, 1, 2});
      expect(rocks, {3, 4, 5});
      expect(types, M6UnjamType.values.toSet());
      expect(pouches, hasLength(6));
      expect(seen.length, greaterThan(150));
    });

    test('feel and oil: an unoiled jam never frees; other points cost nothing; oil + the dealt rocks free it', () {
      final r = M6UnjamRun(_deal(jam: 3, stuck: 2, rocks: 4));
      for (var i = 0; i < 10; i++) {
        expect(r.rock(), M6UnjamRock.jammed);
      }
      expect(r.freed, isFalse);
      expect(r.oil(0), isTrue);
      expect(r.oil(1), isTrue);
      expect(r.oil(0), isFalse, reason: 'oiled already');
      expect(r.rock(), M6UnjamRock.jammed, reason: 'the bearing has no oil yet');
      expect(r.lag, 1);
      expect(r.slips, 0, reason: 'oiling extra points is free');
      r.oil(3);
      expect(r.rock(), M6UnjamRock.easing);
      expect(r.lag, lessThan(1));
      expect(r.rock(), M6UnjamRock.easing);
      expect(r.rock(), M6UnjamRock.easing);
      expect(r.rock(), M6UnjamRock.freed);
      expect(r.freed, isTrue);
      expect(r.lag, 0);
      expect(r.rock(), M6UnjamRock.together);
      expect(r.caught, contains(L.caughtOil));
      expect(m6UnjamBladeAngles(jam: 3, stuck: 2, lag: 0, t: 0.5).toSet(), hasLength(1), reason: 'free: all swing together');
      final lagging = m6UnjamBladeAngles(jam: 1, stuck: 1, lag: 1, t: 0.5);
      expect(lagging[0], lagging[2]);
      expect(lagging[1], isNot(lagging[0]), reason: 'the jammed blade lags');
    });

    test('clean: the cloth fades the marks; down with dirt left is a slip and he stays up; clean → ground', () {
      final r = M6UnjamRun(_deal(arcs: {0, 2}, ins: {1}));
      expect(r.dirtLeft, isTrue);
      expect(r.comeDown(), Mk.dirtLeft);
      expect(r.stage, M6UnjamStage.head);
      expect(r.slips, 1);
      expect(r.rub(M6UnjamRub.jaw, 1, 500), isFalse, reason: 'a clean jaw: nothing to clear');
      expect(r.rub(M6UnjamRub.jaw, 0, m6UnjamRubPath / 2), isFalse);
      expect(r.jawDirt[0], closeTo(0.5, 0.01));
      expect(r.rub(M6UnjamRub.jaw, 0, m6UnjamRubPath / 2), isTrue);
      expect(r.rub(M6UnjamRub.jaw, 2, m6UnjamRubPath), isTrue);
      expect(r.comeDown(), Mk.dirtLeft, reason: 'the insulator is still dirty');
      expect(r.rub(M6UnjamRub.insulator, 1, m6UnjamRubPath), isTrue);
      expect(r.comeDown(), isNull);
      expect(r.stage, M6UnjamStage.ground);
      expect(r.earths, isTrue, reason: 'the crew takes them off at the line clear');
      expect(r.caught, isNot(contains(L.caughtClean)), reason: 'a dirt slip first');
      expect(r.stroke(), isNull, reason: 'no stroke under the earths');
      r.lineClear();
      expect(r.earths, isFalse);
      // A jam left is no slip at the descent.
      final j = M6UnjamRun(_deal())..rub(M6UnjamRub.jaw, 0, m6UnjamRubPath);
      expect(j.comeDown(), isNull);
      expect(j.freed, isFalse);
      expect(j.caught, contains(L.caughtClean));
    });

    test('restore: AB first, then the breaker → restored; the stall is a slip and moves nothing', () {
      final r = _onGround();
      expect(r.stroke(stalled: true), Mk.stall);
      expect(r.abClosed, isFalse);
      expect(r.stroke(), isNull);
      expect(r.abClosed, isTrue);
      expect(r.partSeated, isFalse);
      r.look();
      expect(r.refusedPartSeat, isFalse);
      expect(r.askBreaker(), isNull);
      expect(r.restored, isTrue);
      expect(r.passed, isTrue, reason: 'one slip: 85, still a pass mark');
      expect(r.percent, 85);
      expect(r.caught, contains(L.caughtOrder));
      expect(m6UnjamFinalWhy(r.deal, refusedPartSeat: r.refusedPartSeat), M6UnjamWhy.order);
    });

    test('breaker ON asked with the AB open, then a stroke that stalls mid-arc = still deadly (operated on load, X3)', () {
      final r = _onGround();
      expect(r.askBreaker(), isNull);
      final m = r.stroke(stalled: true);
      expect(m, Mk.closeOnLoad);
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.slips, 0, reason: 'not scored as a stall');
    });

    test('breaker ON asked with the AB open, then the stroke = deadly (closing on load); a cancel first = a slip', () {
      final a = _onGround();
      expect(a.askBreaker(), isNull, reason: 'no slip yet');
      expect(a.breakerOn, isTrue);
      final m = a.stroke();
      expect(m, Mk.closeOnLoad);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = _onGround();
      b.askBreaker();
      expect(b.cancelBreaker(), Mk.askCancel);
      expect(b.breakerOn, isFalse);
      expect(b.slips, 1);
      expect(b.stroke(), isNull, reason: 'off again: the stroke is off-load');
      b.look();
      expect(b.askBreaker(), isNull);
      expect(b.restored, isTrue);
      expect(b.caught, isNot(contains(L.caughtOrder)));
    });

    test('breaker ON asked with all three seated but not looked at since the close = a slip (pro tips 2, 4); put off again; look, then ask → restored', () {
      final r = _onGround();
      r.look();
      expect(r.stroke(), isNull);
      expect(r.abClosed, isTrue);
      expect(r.partSeated, isFalse);
      expect(r.looked, isFalse, reason: 'a look before the close does not count');
      final m = r.askBreaker();
      expect(m, Mk.uncheckedAsk);
      expect(m!.deadly, isFalse);
      expect(r.breakerOn, isFalse, reason: 'put off again');
      expect(r.restored, isFalse);
      expect(r.slips, 1);
      r.look();
      expect(r.askBreaker(), isNull);
      expect(r.restored, isTrue);
      expect(r.slips, 1);
      // A part-seated phase asked unchecked stays the part-seated slip.
      final p = _onGround(freed: false)..stroke();
      expect(p.askBreaker(), Mk.partSeatedOn);
    });

    test('a jam left: the close part-seats; breaker ON asked = a slip; open, back up (re-earthed), oil, down, close → restored (the order reason, no "caught" line)', () {
      final r = _onGround(freed: false);
      expect(r.canClimb, isFalse, reason: 'not before a stroke');
      expect(r.stroke(), isNull);
      expect(r.partSeated, isTrue);
      expect(m6UnjamPushFits(M6UnjamPush.loose, r), isTrue);
      expect(m6UnjamPushFits(M6UnjamPush.breakerFirst, r), isFalse);
      expect(r.askBreaker(), Mk.partSeatedOn);
      expect(r.breakerOn, isFalse, reason: 'put off again');
      expect(r.seatSlip, isTrue);
      expect(r.canClimb, isFalse, reason: 'the AB is closed');
      expect(r.climbUp(), isFalse);
      expect(r.stroke(), isNull);
      expect(r.abClosed, isFalse);
      expect(r.canClimb, isTrue);
      expect(r.climbUp(), isTrue);
      expect(r.stage, M6UnjamStage.head);
      expect(r.earths, isTrue, reason: 'the crew isolates and earths again');
      r.oil(1);
      for (var i = 0; i < 3; i++) {
        r.rock();
      }
      expect(r.comeDown(), isNull);
      expect(r.descents, 2);
      r.lineClear();
      expect(r.stroke(), isNull);
      expect(r.partSeated, isFalse);
      r.look();
      expect(r.askBreaker(), isNull);
      expect(r.restored, isTrue);
      expect(r.caught, contains(L.caughtOrder));
      expect(r.caught, isNot(contains(L.caughtSeat)), reason: 'he did ask for the line on the loose phase');
      expect(r.refusedPartSeat, isFalse);
      expect(m6UnjamFinalWhy(r.deal, refusedPartSeat: r.refusedPartSeat), M6UnjamWhy.order, reason: 'never "why did you not"');
      expect(r.slips, 1);
      // The same after listening to "একটু আলগা" at the phone.
      final l = _onGround(freed: false)..stroke();
      expect(l.listen(M6UnjamPush.loose), Mk.pushLoose);
      l.stroke();
      expect(l.reopenedAfterSeat, isTrue);
      expect(l.refusedPartSeat, isFalse);
    });

    test('a part-seated close caught and reopened with no slip: the part-seat reason fits and "caught" is earned', () {
      final r = _onGround(freed: false);
      expect(r.stroke(), isNull);
      expect(r.partSeated, isTrue);
      r.look();
      expect(r.refusedPartSeat, isFalse, reason: 'not reopened yet');
      expect(r.stroke(), isNull, reason: 'opened again');
      expect(r.refusedPartSeat, isTrue);
      expect(r.climbUp(), isTrue);
      r.oil(1);
      for (var i = 0; i < 3; i++) {
        r.rock();
      }
      expect(r.comeDown(), isNull);
      r.lineClear();
      expect(r.stroke(), isNull);
      r.look();
      expect(r.askBreaker(), isNull);
      expect(r.restored, isTrue);
      expect(r.slips, 0);
      expect(r.caught, containsAll([L.caughtSeat, L.caughtOrder]));
      final even = M6UnjamDeal(type: r.deal.type, jam: 1, stuck: 1, rocks: 3, arcs: const {0}, dirtyIns: const {}, pouch: r.deal.pouch, whyRoll: 2);
      expect(m6UnjamFinalWhy(even, refusedPartSeat: true), M6UnjamWhy.partSeat);
      expect(m6UnjamFinalWhy(even, refusedPartSeat: false), M6UnjamWhy.order);
    });

    test('listening takes his push\'s class (B1): "আগে ব্রেকার" deadly, "একটু আলগা" a slip; his place from the player\'s work', () {
      final a = _onGround();
      expect(m6UnjamPushFits(M6UnjamPush.breakerFirst, a), isTrue);
      final m = a.listen(M6UnjamPush.breakerFirst);
      expect(m, Mk.listenBreakerFirst);
      expect(m.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = _onGround(freed: false);
      expect(m6UnjamPushFits(M6UnjamPush.breakerFirst, b), isFalse, reason: 'the jam left: not at the handle');
      b.stroke();
      final s = b.listen(M6UnjamPush.loose);
      expect(s, Mk.pushLoose);
      expect(s.deadly, isFalse);
      expect(b.slips, 1);
      expect(b.ended, isFalse);
      // On the head, under the earths, or with the AB closed and seated: no moment.
      final h = M6UnjamRun(_deal());
      expect(m6UnjamPushFits(M6UnjamPush.breakerFirst, h), isFalse);
      final c = _onGround()..stroke();
      expect(m6UnjamPushFits(M6UnjamPush.breakerFirst, c), isFalse);
      expect(m6UnjamPushFits(M6UnjamPush.loose, c), isFalse);
    });

    test('the reasons fit what was done', () {
      for (var s = 0; s < 60; s++) {
        final d = m6UnjamDeal(math.Random(s));
        final f = m6UnjamMaintWhy(d, freed: true);
        final n = m6UnjamMaintWhy(d, freed: false);
        expect(n, isNot(M6UnjamWhy.oil), reason: 'no oil reason with the jam left');
        if (d.dirtyIns.isEmpty) expect({f, n}.contains(M6UnjamWhy.insulators), isFalse);
        expect([M6UnjamWhy.clean, M6UnjamWhy.oil, M6UnjamWhy.insulators], contains(f));
        expect(m6UnjamFinalWhy(d, refusedPartSeat: false), M6UnjamWhy.order);
      }
      final topics = {for (var s = 0; s < 80; s++) ...[m6UnjamMaintWhy(m6UnjamDeal(math.Random(s)), freed: true), m6UnjamFinalWhy(m6UnjamDeal(math.Random(s)), refusedPartSeat: true)]};
      expect(topics, M6UnjamWhy.values.toSet());
    });

    test('three slips: the mark falls to 55, then 40', () {
      final r = M6UnjamRun(_deal());
      for (var i = 0; i < 3; i++) {
        r.comeDown();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.comeDown();
      expect(r.percent, 40);
    });

    test('English digits only; jol not pani; every mistake has its picture; the deadly set; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.docketShutdown,
        L.docketClear,
        L.docketLive,
        L.cutClear,
        L.cutUp,
        L.phoneTitle,
        L.phoneIdle,
        L.phoneOn,
        L.phoneOffAgain,
        L.phoneAsk,
        L.phoneCancel,
        ...L.stages,
        for (final t in M6UnjamTool.values) L.tool(t),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6UnjamPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtOil,
        L.caughtClean,
        L.caughtOrder,
        L.caughtSeat,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(L.docketShutdown, contains('শাটডাউন'));
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.closeOnLoad, Mk.listenBreakerFirst});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.4/m6_ab_unjam/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
      expect(Mk.push(M6UnjamPush.breakerFirst), Mk.listenBreakerFirst);
      expect(Mk.push(M6UnjamPush.loose), Mk.pushLoose);
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_ab_unjam/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m6_ab_unjam').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6AbUnjamPacks.keys, ['do_6_4_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6UnjamWhy.values) {
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

    test('rival lines: his exit is recorded; his two new pushes and the new guide lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect({for (final p in M6UnjamPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newRivalLines, [
        'আইসোলেটর আর ব্রেকার একই জিনিস — আগে ব্রেকার দিতে বলো।',
        'একটু আলগা লেগেছে, ও চলবে — লাইন দিয়ে দাও।',
      ]);
      for (final q in L.whyQ.values) {
        expect(L.newGuideLines, contains(q));
      }
      for (final p in M6UnjamPush.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
      }
      expect(L.newGuideLines, containsAll([L.intro, L.askHead, L.askGround, L.allSet, L.fail]));
      expect(L.newGuideLines, contains(Mk.uncheckedAsk.textBn), reason: 'the new DRAFT slip text, for the owner');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_ab_unjam: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, below the header, above the pouch row and clear of the guide', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M6UnjamGeo.forScene(h, 0);
        final head = <Rect>[for (var i = 0; i < 4; i++) g.pivotHit(i), for (var i = 0; i < 3; i++) ...[g.jawHit(i), g.insHit(i)], g.leverHit];
        final ground = <Rect>[g.knobHit(0), g.knobHit(1), g.phoneHit];
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (final set in [head, ground]) {
          for (final r in set) {
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(360));
            expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
            expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the pouch row');
            expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
            if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, g.groundY - 129, 360, g.groundY - 81)), isFalse, reason: 'h $h: $r under the bubble');
          }
        }
        for (var i = 0; i < head.length; i++) {
          for (var j = i + 1; j < head.length; j++) {
            expect(head[i].overlaps(head[j]), isFalse, reason: 'h $h: $i/$j');
          }
        }
        expect(g.knobHit(0).overlaps(g.phoneHit), isFalse);
        expect(g.knobHit(1).overlaps(g.phoneHit), isFalse);
        // The handle's arc: the progress follows the angle round the pivot.
        expect(g.progressAt(g.knob(0)), closeTo(0, 0.01));
        expect(g.progressAt(g.knob(1)), closeTo(1, 0.01));
        expect(g.progressAt(g.knob(0.5)), closeTo(0.5, 0.01));
      }
    });

    test('the can hint shows the real touch (a hold on an oil point) and never points at the jam', () {
      final g = _geo;
      final holds = <Offset>[];
      for (var n = 0; n < 16; n++) {
        final h = m6UnjamCanHint(g, n);
        if (n.isEven) {
          expect(h.kind, HintKind.sweep);
          expect(h.options, [for (var i = 0; i < 4; i++) g.pivotHit(i)]);
        } else {
          expect(h.kind, HintKind.hold, reason: 'oiling is a press-and-hold, never a drag of the can');
          holds.add(h.at);
        }
        expect(h.space, HintSpace.scene);
      }
      expect(holds.toSet(), {for (var i = 0; i < 4; i++) g.pivot(i)}, reason: 'every oil point in turn');
      expect(holds.sublist(0, 4).toSet(), hasLength(4), reason: 'a different one each time');
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

    testWidgets('the guide comes first: a tap does not skip him; then the pouch and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6AbUnjamPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      for (final tool in M6UnjamTool.values) {
        expect(_label(L.tool(tool)), findsOneWidget);
      }
      expect(find.text(L.docketShutdown), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askHead)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a clean play: oil, rock, clean, down (a reason), the handle coworker refused, close, look, breaker → pass', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      expect(find.byType(MistakeCard), findsNothing);
      final r = M6AbUnjamProbe.run!;
      expect(r.oiled, {0, 1, 2, 3});
      expect(r.freed, isTrue, reason: 'rocks ${r.rocksAfterOil}/${d.rocks}');
      expect(r.dirtLeft, isFalse, reason: '${r.jawDirt} ${r.insDirt}');
      await _downFirst(t, d, freed: true);
      expect(find.text(L.docketClear), findsOneWidget);
      await _refuse(t, M6UnjamPush.breakerFirst);
      await _stroke(t, closing: true);
      await _look(t);
      expect(find.byType(MistakeCard), findsNothing);
      await _phoneAsk(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      await _pump(t, 600);
      await _pickRight(t, L.whyRight[M6UnjamWhy.order]!);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['6.4/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['6.4/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      expect(find.text(L.caughtOil), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the jam left: the close part-seats, the phone coworker refused, open, back up, oil, down, close → pass', (t) async {
      // The common rod's bearing jammed (every blade lags), dirty insulators too.
      final seed = _seedWhere((d) => d.jam == 3 && d.dirtyIns.isNotEmpty);
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d, oilJam: false);
      await _downFirst(t, d, freed: false);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not at the handle: the work was not good');
      await _stroke(t, closing: true);
      await _refuse(t, M6UnjamPush.loose);
      await _look(t);
      await _stroke(t, closing: false);
      expect(_label(L.tool(M6UnjamTool.lanyard)), findsOneWidget, reason: 'the lanyard is out after the reopen');
      await t.longPress(_label(L.tool(M6UnjamTool.lanyard)));
      await _pump(t, 3000);
      expect(find.text(L.docketShutdown), findsOneWidget, reason: 're-isolated and earthed');
      await _tool(t, M6UnjamTool.can);
      await _oil(t, d.jam);
      for (var r = 0; r < d.rocks; r++) {
        await _rock(t);
      }
      await _down(t);
      await _pump(t, 3200);
      await _stroke(t, closing: true);
      await _look(t);
      await _phoneAsk(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 600);
      await _pickRight(t, L.whyRight[m6UnjamFinalWhy(d, refusedPartSeat: true)]!);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['6.4/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(L.caughtSeat), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('down with dirt left: the slip card; he stays up', (t) async {
      final c = await _open(t, 2);
      await _down(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.dirtLeft.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(L.tool(M6UnjamTool.cloth)), findsOneWidget, reason: 'still on the platform');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.dirtLeft.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _down(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('breaker ON asked with the AB open, then the stroke: the scene freezes first, then the card (deadly)', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      await _downFirst(t, d, freed: true);
      await _refuse(t, M6UnjamPush.breakerFirst);
      await _phoneAsk(t);
      expect(find.byType(MistakeCard), findsNothing, reason: 'no slip at the ask');
      expect(find.text(L.phoneOn), findsOneWidget);
      await _stroke(t, closing: true);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.closeOnLoad.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('breaker ON asked, then cancelled before the stroke: a slip', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      await _downFirst(t, d, freed: true);
      await _refuse(t, M6UnjamPush.breakerFirst);
      await _phoneAsk(t);
      await t.tap(find.byKey(const ValueKey('phone-cancel')));
      await _pump(t, 500);
      expect(find.text(Mk.askCancel.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.askCancel.key);
      await _close(t, c);
    });

    testWidgets('breaker ON asked after the close without the swipe up: a slip card; put off again; look, ask → restored', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      await _downFirst(t, d, freed: true);
      await _refuse(t, M6UnjamPush.breakerFirst);
      await _stroke(t, closing: true);
      expect(M6AbUnjamProbe.run!.abClosed, isTrue);
      await _phoneAsk(t);
      expect(find.text(Mk.uncheckedAsk.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.uncheckedAsk.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(M6AbUnjamProbe.run!.breakerOn, isFalse);
      await _look(t);
      await _phoneAsk(t);
      expect(M6AbUnjamProbe.run!.restored, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to "আগে ব্রেকার দিতে বলো" = deadly: freeze, then the card', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      await _downFirst(t, d, freed: true);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerBreakerFirst.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listenBreakerFirst.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: the handle waits for the coworker; he cuts in at once; a stall mid-arc is a slip', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      await _down(t);
      await _pickRight(t, L.whyRight[m6UnjamMaintWhy(d, freed: true)]!);
      // Right after the line clear, well inside his 1.2–2.4 s timer.
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      final a = _geo.knob(0) * _k;
      await t.dragFrom(a, (_geo.knob(1) * _k) - a);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerBreakerFirst.right);
      await _pump(t, 2600);
      // The stroke that waited did nothing: a stall now (held still mid-arc).
      final g = await t.startGesture(_geo.knob(0) * _k);
      await g.moveTo(_geo.knob(0.25) * _k);
      await t.pump(const Duration(milliseconds: 50));
      await g.moveTo(_geo.knob(0.5) * _k);
      await _pump(t, 900);
      await g.up();
      await _pump(t, 400);
      expect(find.text(Mk.stall.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.stall.key);
      await _close(t, c);
    });

    testWidgets('the ◆ on the table and its reason deck: the scene takes no touch', (t) async {
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d);
      await _down(t);
      await waitChoiceDeck(t);
      // A swipe up the structure (above the deck) does nothing now.
      await _look(t);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is M6UnjamPhasePainter), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[m6UnjamMaintWhy(d, freed: true)]!);
      await _pump(t, 3000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a finger that rests first still works: hold the can on the jam, press-pause-rock the lever, press-pause-rub with the cloth', (t) async {
      final seed = _seedWhere((d) => d.arcs.isNotEmpty);
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      final r = M6AbUnjamProbe.run!;
      await _tool(t, M6UnjamTool.can);
      await _oil(t, d.jam);
      expect(r.oiled, {d.jam});
      for (var k = 0; k < d.rocks; k++) {
        final g = await t.startGesture((_geo.leverGrip - const Offset(14, 0)) * _k);
        await _pump(t, 700);
        await g.moveBy(const Offset(44 * _k, 0));
        await t.pump(const Duration(milliseconds: 30));
        await g.up();
        await _pump(t, 800);
      }
      expect(r.freed, isTrue, reason: 'rocks ${r.rocksAfterOil}/${d.rocks}');
      await _tool(t, M6UnjamTool.cloth);
      final i = d.arcs.first;
      final box = _geo.jawHit(i);
      final g = await t.startGesture(Offset(box.left + 8, box.center.dy) * _k);
      await _pump(t, 700);
      for (var k = 0; k < 8; k++) {
        await g.moveBy(Offset((k.isEven ? 1 : -1) * (box.width - 16), 0) * _k);
        await t.pump(const Duration(milliseconds: 30));
      }
      await g.up();
      await _pump(t, 300);
      expect(r.jawDirt[i], 0, reason: 'the grime falls');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('hold the knob, then one swing: the AB closes; the phone panel open gets a gesture hand', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _fixHead(t, d);
      await _downFirst(t, d, freed: true);
      await _refuse(t, M6UnjamPush.breakerFirst);
      // The phone panel open and the player stuck: the hand comes.
      await t.tapAt(_geo.phone * _k);
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('phone-ask')), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'the panel waits too');
      await t.tap(find.byKey(const ValueKey('phone-close')));
      await _pump(t, 400);
      final r = M6AbUnjamProbe.run!;
      expect(r.abClosed, isFalse);
      final g = await t.startGesture(_geo.knob(0) * _k);
      await _pump(t, 700);
      for (final p in [0.2, 0.4, 0.6, 0.8, 1.0]) {
        await g.moveTo(_geo.knob(p) * _k);
        await t.pump(const Duration(milliseconds: 30));
      }
      await g.up();
      await _pump(t, 500);
      expect(r.abClosed, isTrue, reason: 'held first, then swung');
      expect(r.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets("the re-isolation cutscene shows the crew's tester", (t) async {
      final seed = _seedWhere((d) => d.jam == 3);
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _fixHead(t, d, oilJam: false);
      await _downFirst(t, d, freed: false);
      await _pump(t, 3000);
      await _stroke(t, closing: true);
      await _refuse(t, M6UnjamPush.loose);
      await _stroke(t, closing: false);
      await t.longPress(_label(L.tool(M6UnjamTool.lanyard)));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(L.cutUp), findsOneWidget);
      expect(find.byKey(const ValueKey('cut-tester')), findsOneWidget);
      await _pump(t, 3000);
      expect(find.byKey(const ValueKey('cut-tester')), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand: shows while the head waits (no press), none while the reason deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 7;
      final d = m6UnjamDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the head');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a swipe or a sweep presses nothing');
      // Three taps on nothing show it at once.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.headEmpty * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      await _fixHead(t, d);
      await _down(t);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _close(t, c);
    });
  });
}
