// Lesson 6.9 (এলটি ডিস্ট্রিবিউশন পিলার), কাজ 2 "নতুন লাইন জুড়ুন": the rules
// (X4: a hand inside with the DTR's LT ON = deadly; the LT OFF but no lock
// and tag, not proved dead, not proved again, a 0 V on an unproved tester,
// no PPE = slips; the LT or the SFU ON with the door open = slip; a phase on
// a fuse unit fed from another bar, N or the armour off its terminal, the
// armour hanging at the door, a loose lug at switch-on, the door left open or
// unlocked = slips; a core landed with the SFU still ON = slip), the deal,
// the libraries, the coworker's pushes (both deadly to listen to), the drawn
// places, and the level in the shell: the guide first, a full clean play (the
// coworker refused, the isolation, three plucks, five lugs landed by drag and
// held tight, the door, the switch-on, the padlock, four reasons), a slip
// card that keeps the play, three slips, the deadly freeze (own act;
// listening), the LT handle waits for him on a fast play, a loose lug found
// at switch-on, the praise window takes no touch, and the gesture hand shows
// how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m6_pillar_newway.dart';
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
  rungId: '6.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6PillarNewwayPacks['do_6_9_b']!;
typedef L = M6PillarNewwayLines;
typedef Mk = M6PillarNewwayMistakes;

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
M6NwGeo get _geo => M6NwGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M6NwRun get _live => M6PillarNewwayProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _dragAt(WidgetTester t, Offset design, Offset by) async {
  await t.dragFrom(design * _k, by * _k);
  await _pump(t, 300);
}

Future<void> _holdAt(WidgetTester t, Offset design, {int ms = 1200}) async {
  final g = await t.startGesture(design * _k);
  await _pump(t, ms);
  await g.up();
  await _pump(t, 250);
}

Future<void> _lt(WidgetTester t, bool on) => _dragAt(t, _geo.ltHandle, Offset(0, on ? -48 : 48));
Future<void> _sfu(WidgetTester t, bool on) => _dragAt(t, _geo.sfu, Offset(0, on ? -48 : 48));

/// A lug from its rest slot onto terminal [term].
Future<void> _land(WidgetTester t, M6NwCore c, int term) async {
  final d = _live.deal;
  final slot = d.slots.indexOf(c);
  await _dragAt(t, _geo.lugHome(slot), _geo.term(term, d.nLeft) - _geo.lugHome(slot));
}

int _termOf(M6NwDeal d, M6NwCore c) => switch (c) {
      M6NwCore.n => kM6NwNLink,
      M6NwCore.armour => kM6NwEarth,
      _ => d.fuseOf(c.index),
    };

Future<ProviderContainer> _open(WidgetTester t, int seed, {int settle = 1200}) async {
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6PillarNewwayPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  if (settle > 0) await _pump(t, settle);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M6NwDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m6NwDeal(math.Random(s))));

/// He comes by himself (his timer): refuse him.
Future<void> _refuse(WidgetTester t, M6NwPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
  expect(find.byType(CoworkerPeek), findsNothing);
}

Future<void> _reason(WidgetTester t, M6NwWhy w) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($w)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1800);
}

/// PPE, SFU OFF, LT OFF, lock and tag, the tester live-dead-live.
Future<void> _isolate(WidgetTester t) async {
  await _tapAt(t, _geo.ppe.center);
  expect(_live.ppe, isTrue);
  await _sfu(t, false);
  expect(_live.sfuOn, isFalse);
  await _lt(t, false);
  expect(_live.ltOn, isFalse);
  await _tapAt(t, _geo.ltLockHit.center);
  expect(_live.lockTag, isTrue);
  await _tapAt(t, _geo.testerHit.center);
  expect(_live.tester, isTrue);
  await _tapAt(t, _geo.ltSupply.center);
  await _tapAt(t, _geo.barsHit.center);
  expect(_live.deadSeen, isTrue);
  await _tapAt(t, _geo.ltSupply.center);
  expect(_live.provenDead, isTrue);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _reason(t, M6NwWhy.isolate);
}

/// Pluck all three, land and tighten all five (with the two reasons);
/// [loose]: leave that one's nut as landed.
Future<void> _wire(WidgetTester t, {M6NwCore? loose}) async {
  final d = _live.deal;
  for (var i = 0; i < 3; i++) {
    await _tapAt(t, _geo.pluckHit(i).center);
    expect(_live.plucked, i);
  }
  for (final c in M6NwCore.values) {
    await _land(t, c, _termOf(d, c));
    expect(_live.landed[c], _termOf(d, c), reason: '$c landed');
    if (c == M6NwCore.b) await _reason(t, M6NwWhy.order);
    if (c == M6NwCore.armour) await _reason(t, M6NwWhy.neutral);
    if (c != loose) {
      await _holdAt(t, _geo.term(_termOf(d, c), d.nLeft));
      expect(_live.tight, contains(c), reason: '$c tight');
    }
  }
  expect(find.text(MistakeLines.slipHead), findsNothing);
}

/// Door shut, lock and tag off, LT ON, SFU ON.
Future<void> _switchOn(WidgetTester t) async {
  await _dragAt(t, _geo.doorOpenHit.center, const Offset(90, 0));
  expect(_live.doorOpen, isFalse);
  await _tapAt(t, _geo.ltLockHit.center);
  expect(_live.lockTag, isFalse);
  await _lt(t, true);
  expect(_live.ltOn, isTrue);
  await _sfu(t, true);
}

M6NwDeal _dealOf({M6NwPush push = M6NwPush.myth, List<int> perm = const [2, 0, 1], bool nLeft = true}) => M6NwDeal(
      perm: perm,
      sigma: const [1, 2, 0],
      slots: M6NwCore.values,
      nLeft: nLeft,
      entryLeft: true,
      lane: 4,
      push: push,
    );

/// A run proved dead (PPE on, SFU OFF) unless told otherwise.
M6NwRun _proven({bool ppe = true, bool sfuOff = true}) {
  final r = M6NwRun(_dealOf());
  if (ppe) r.wearPpe();
  if (sfuOff) r.switchSfu(false);
  r.switchLt(false);
  r.toggleLockTag();
  r.holdTester();
  r.testLive();
  r.testBars();
  r.testLive();
  return r;
}

void main() {
  group('rules', () {
    test('deals: every dropper order, the shroud columns never straight, slots, sides, and pushes vary', () {
      final perms = <String>{};
      final sigmas = <String>{};
      final slots = <String>{};
      final pushes = <M6NwPush>{};
      final lanes = <int>{};
      var nLeft = 0, entryLeft = 0;
      final seen = <String>{};
      for (var s = 0; s < 200; s++) {
        final d = m6NwDeal(math.Random(s));
        expect(d.perm.toSet(), {0, 1, 2});
        expect(d.sigma.toSet(), {0, 1, 2});
        expect(d.sigma.join(), isNot('012'), reason: 'never a straight run over the shroud');
        expect(d.slots.toSet(), M6NwCore.values.toSet());
        for (var ph = 0; ph < 3; ph++) {
          expect(d.perm[d.fuseOf(ph)], ph);
        }
        perms.add(d.perm.join());
        sigmas.add(d.sigma.join());
        slots.add(d.slots.map((c) => c.index).join());
        pushes.add(d.push);
        lanes.add(d.lane);
        if (d.nLeft) nLeft++;
        if (d.entryLeft) entryLeft++;
        seen.add('${d.perm.join()}${d.sigma.join()}${d.slots.map((c) => c.index).join()}${d.nLeft}${d.entryLeft}${d.push.index}');
      }
      expect(perms, hasLength(6));
      expect(sigmas, hasLength(5));
      expect(slots.length, greaterThan(60));
      expect(pushes, M6NwPush.values.toSet());
      expect(lanes, everyElement(inInclusiveRange(2, 9)));
      expect(nLeft, inInclusiveRange(60, 140));
      expect(entryLeft, inInclusiveRange(60, 140));
      expect(seen.length, greaterThan(190));
    });

    test('X4: a hand inside with the LT ON is deadly, whatever the PPE and the SFU', () {
      for (final ppe in [false, true]) {
        final r = M6NwRun(_dealOf());
        if (ppe) r.wearPpe();
        r.switchSfu(false);
        final m = r.pluck(0);
        expect(m, Mk.liveHands);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
        expect(r.slips, 0);
      }
      final land = M6NwRun(_dealOf());
      expect(land.land(M6NwCore.n, kM6NwNLink), Mk.liveHands, reason: 'landing with the DTR LT on');
      final nut = M6NwRun(_dealOf())..landed[M6NwCore.n] = kM6NwNLink;
      expect(nut.spanner(M6NwCore.n), Mk.liveHands);
    });

    test('N4/N9/A5: no lock and tag, not proved, not proved again, an unproved 0 V, no PPE — slips; nothing happens', () {
      final r = M6NwRun(_dealOf())..wearPpe();
      r.switchSfu(false);
      expect(r.switchLt(false), (true, null));
      expect(r.pluck(1), Mk.noLockTag);
      expect(r.plucked, isNull);
      expect(r.toggleLockTag(), isTrue);
      expect(r.switchLt(true), (false, null), reason: 'locked and tagged: the handle does not move');
      expect(r.pluck(1), Mk.noTest);
      expect(r.testBars(), (false, null), reason: 'no tester in hand');
      r.holdTester();
      expect(r.testBars(), (false, Mk.testFirst));
      expect(r.deadSeen, isFalse);
      r.testLive();
      expect(r.testBars(), (false, null));
      expect(r.deadSeen, isTrue);
      expect(r.pluck(1), Mk.noReprove);
      r.testLive();
      expect(r.provenDead, isTrue);
      expect(r.pluck(1), isNull);
      expect(r.plucked, 1);
      expect(r.slips, 4);
      final bare = _proven(ppe: false);
      expect(bare.pluck(0), Mk.noPpe, reason: 'after a proven isolation no PPE is a slip (A5)');
      expect(bare.deadly, isNull);
      // A live reading costs nothing (A9).
      final live = M6NwRun(_dealOf())..holdTester();
      expect(live.testBars(), (true, null));
      expect(live.slips, 0);
      // ...and the live bars prove the tester: LT OFF, lock, 0 V is no N9.
      expect(live.provedBefore, isTrue, reason: 'the live bars are a known live source');
      live
        ..switchSfu(false)
        ..switchLt(false)
        ..toggleLockTag();
      expect(live.testBars(), (false, null));
      expect(live.deadSeen, isTrue);
      expect(live.slips, 0);
    });

    test('landing: the SFU ON a slip; a phase only on the fuse unit fed from its bar; N on the link; the armour on the earth', () {
      final s = _proven(sfuOff: false);
      expect(s.land(M6NwCore.r, 1), Mk.sfuOn);
      expect(s.landed, isEmpty);
      final r = _proven()..pay(M6NwStage.isolate);
      // perm [2, 0, 1]: fuse 0 ← B, fuse 1 ← R, fuse 2 ← Y.
      expect(r.land(M6NwCore.r, 0), Mk.wrongPhase);
      expect(r.land(M6NwCore.r, kM6NwNLink), Mk.wrongPhase);
      expect(r.land(M6NwCore.n, 2), Mk.neutralWrong);
      expect(r.land(M6NwCore.n, kM6NwEarth), Mk.neutralWrong);
      expect(r.land(M6NwCore.armour, kM6NwNLink), Mk.armourWrong);
      expect(r.land(M6NwCore.armour, 0), Mk.armourWrong);
      expect(r.slips, 6);
      expect(r.landed, isEmpty, reason: 'a wrong lug springs back');
      expect(r.land(M6NwCore.r, 1), isNull);
      expect(r.land(M6NwCore.y, 2), isNull);
      expect(r.land(M6NwCore.b, 1), isNull, reason: 'a taken terminal: nothing');
      expect(r.landed.containsKey(M6NwCore.b), isFalse);
      expect(r.land(M6NwCore.b, 0), isNull);
      expect(r.phasesLanded, isTrue);
      expect(r.due, M6NwStage.phases);
      expect(r.caught, contains(L.caughtPhases));
      expect(r.land(M6NwCore.n, kM6NwNLink), isNull);
      expect(r.land(M6NwCore.armour, kM6NwEarth), isNull);
      expect(r.allLanded, isTrue);
      expect(r.caught, contains(L.caughtNeutral));
      expect(r.slips, 6);
    });

    test('the door: shut only with the four cores on; the armour hanging a slip (M6-1); ON with it open a slip (N5)', () {
      final r = _proven();
      expect(r.shutDoor(), (false, null));
      for (final (c, t) in [(M6NwCore.r, 1), (M6NwCore.y, 2), (M6NwCore.b, 0), (M6NwCore.n, kM6NwNLink)]) {
        r.land(c, t);
      }
      expect(r.shutDoor(), (false, Mk.armourMissing));
      expect(r.doorOpen, isTrue);
      r.land(M6NwCore.armour, kM6NwEarth);
      r.toggleLockTag();
      expect(r.switchLt(true), (false, Mk.onDoorOpen));
      expect(r.switchSfu(true), (false, Mk.onDoorOpen));
      expect(r.ltOn, isFalse);
      expect(r.sfuOn, isFalse);
      expect(r.shutDoor(), (true, null));
      expect(r.slips, 3);
      expect(r.openDoor(), isTrue, reason: 'unlocked: it opens again');
      expect(r.shutDoor(), (true, null));
    });

    test('switch-on: a loose lug glows (a slip), the crew isolates again and the proof is void; all tight → lit, then lock, then the door is paid', () {
      final r = _proven();
      for (final (c, t) in [(M6NwCore.r, 1), (M6NwCore.y, 2), (M6NwCore.b, 0), (M6NwCore.n, kM6NwNLink), (M6NwCore.armour, kM6NwEarth)]) {
        r.land(c, t);
        if (c != M6NwCore.y) r.seat(c);
      }
      r.shutDoor();
      r.toggleLockTag();
      expect(r.switchLt(true), (true, null));
      expect(r.lit, isFalse);
      final (moved, m) = r.switchSfu(true);
      expect(moved, isTrue);
      expect(m, Mk.looseLug);
      expect(r.hot, [M6NwCore.y]);
      expect(r.refit, isTrue);
      expect(r.lit, isFalse);
      expect(r.pluck(0), isNull, reason: 'nothing while it glows');
      r.crewIsolate();
      expect((r.sfuOn, r.ltOn, r.lockTag, r.doorOpen, r.locked), (false, false, true, true, false));
      expect((r.provedBefore, r.deadSeen, r.provedAfter), (false, false, false));
      expect(r.spanner(M6NwCore.y), Mk.noTest, reason: 'prove dead again before the spanner');
      r
        ..testLive()
        ..testBars()
        ..testLive();
      expect(r.spanner(M6NwCore.y), isNull);
      r.seat(M6NwCore.y);
      expect(r.allTight, isTrue);
      r.shutDoor();
      r.toggleLockTag();
      r.switchLt(true);
      expect(r.leave(), isNull, reason: 'not lit yet: nothing');
      expect(r.switchSfu(true), (true, null));
      expect(r.lit, isTrue);
      r.paid.addAll([M6NwStage.isolate, M6NwStage.phases, M6NwStage.neutral]);
      expect(r.due, M6NwStage.lit, reason: 'the lane lit: the tightening is paid');
      expect(r.why(M6NwStage.lit), M6NwWhy.tighten);
      expect(r.pay(M6NwStage.lit), isTrue);
      expect(r.due, isNull);
      expect(r.refit, isFalse);
      expect(r.caught, contains(L.caughtTight));
      expect(r.openDoor(), isTrue);
      expect(r.leave(), Mk.doorOpen);
      expect(r.canLock, isFalse, reason: 'the door is open');
      r.shutDoor();
      expect(r.leave(), Mk.noLock);
      expect(r.lock(), isTrue);
      expect(r.openDoor(), isFalse, reason: 'locked');
      expect(r.due, M6NwStage.door);
      expect(r.why(M6NwStage.door), M6NwWhy.door);
      expect(r.pay(M6NwStage.door), isTrue);
      expect(r.pay(M6NwStage.door), isFalse, reason: 'once');
      r.finish();
      expect(r.finished, isTrue);
      expect(r.slips, 4, reason: 'the loose lug, the spanner before the proof, the door open, unlocked');
      expect(r.passed, isFalse, reason: '40 %');
    });

    test('the right moves come due in turn, each once; reasons fit; three slips and the play fails', () {
      final r = _proven();
      expect(r.due, M6NwStage.isolate);
      expect(r.pay(M6NwStage.isolate), isTrue);
      expect(r.caught, contains(L.caughtIsolate));
      expect(r.due, isNull);
      expect(r.why(M6NwStage.isolate), M6NwWhy.isolate);
      expect(r.why(M6NwStage.phases), M6NwWhy.order);
      expect(r.why(M6NwStage.neutral), M6NwWhy.neutral);
      final f = _proven();
      for (var i = 0; i < 3; i++) {
        f.land(M6NwCore.n, 0);
      }
      expect(f.percent, 55);
      expect(f.thorough, isFalse);
      f.nextStage();
      expect(f.thorough, isTrue);
      f.land(M6NwCore.n, 0);
      expect(f.percent, 40);
    });

    test('listening to him is the act he pushes (X2/B1): both pushes deadly', () {
      expect(Mk.push(M6NwPush.myth), Mk.mythHands);
      expect(Mk.push(M6NwPush.sfuOnly), Mk.sfuOnly);
      for (final p in M6NwPush.values) {
        expect(Mk.push(p).deadly, isTrue);
      }
    });

    test('English digits; জল not পানি; ডেড not মৃত; ON/OFF; য়/ড়/ঢ় with the nukta; the deadly set; keys; pictures; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.landFirst,
        L.notLit,
        L.sceneLabel,
        for (var n = 2; n <= 9; n++) L.laneTag(n),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6NwPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtIsolate,
        L.caughtPhases,
        L.caughtNeutral,
        L.caughtTight,
        L.caughtLock,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$)').hasMatch(l), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
      }
      // LT in English letters, the myth too (one clip with board 6.9's myth, M6-8).
      for (final l in all) {
        expect(l.contains('এলটি'), isFalse, reason: l);
      }
      expect(L.coworkerMyth.line, 'LT বক্সের ভেতরে তো শুধু 415 ভোল্ট থাকে, এটা তেমন বিপজ্জনক নয়।');
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.liveHands, Mk.mythHands, Mk.sfuOnly});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.9/m6_pillar_newway/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      for (final s in M6NwStage.values) {
        expect(m6NwLessonPoint(s), inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m6_pillar_newway/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used (no .gitkeep left)');
      expect(m6PillarNewwayPacks.keys, ['do_6_9_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6NwWhy.values) {
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

    test('every spoken line is listed: his exit is recorded; his two pushes and the guide\'s new lines for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'LT বক্সের ভেতরে তো শুধু 415 ভোল্ট থাকে, এটা তেমন বিপজ্জনক নয়।',
        'DTR-এর LT বন্ধের দরকার নেই, SFU নামালেই হবে — 415 ভোল্টই তো।',
      ]);
      expect({for (final p in M6NwPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([
        L.intro,
        ...L.tasks,
        L.landFirst,
        L.notLit,
        ...L.whyQ.values,
        'ও বলছে এখনই হাত দিতে। কী করবেন?',
        'ও বলছে শুধু SFU নামাতে। কী করবেন?',
        for (final p in M6NwPush.values) L.callHeld(p),
        L.allSet,
        L.fail,
        for (final m in Mk.all) m.textBn,
      ]));
      // The kit's old lines the level also speaks are recorded already.
      for (final l in [L.quick, L.deadlyWord, L.nearMissWord, 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', L.tapWhy.first]) {
        expect(LearnVoice.resolve(l), isNotNull, reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_pillar_newway: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas stay on the scene, clear of the header, the guide and its bubble; no two live at once overlap', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6NwGeo.forScene(h, 0);
        for (final nLeft in [true, false]) {
          final terms = [for (var k = 0; k < kM6NwTerms; k++) g.termHit(k, nLeft)];
          final lugs = [for (var k = 0; k < 5; k++) g.lugHit(k)];
          final pluck = [for (var i = 0; i < 3; i++) g.pluckHit(i)];
          final outside = [g.ltSupply, g.ltLockHit, g.ltHandleHit, g.ppe, g.testerHit, g.van, g.sfuHit];
          // Door open: all of these at once; door shut: the outside ones and the hasp.
          final open = [...outside, g.doorOpenHit, g.barsHit, ...pluck, ...terms, ...lugs];
          final shut = [...outside, g.haspHit];
          final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
          for (final r in {...open, ...shut}) {
            expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
            expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
            expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
            expect(r.bottom, lessThan(g.floorY), reason: 'h $h: $r above the pavement');
            expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
            if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81)), isFalse, reason: 'h $h: $r under the bubble');
          }
          for (final set in [open, shut]) {
            for (var i = 0; i < set.length; i++) {
              for (var j = i + 1; j < set.length; j++) {
                expect(set[i].overlaps(set[j]), isFalse, reason: 'h $h nLeft $nLeft: ${set[i]} / ${set[j]}');
              }
            }
          }
          // Every terminal is far from every other (a drop snaps to one only).
          for (var i = 0; i < kM6NwTerms; i++) {
            for (var j = i + 1; j < kM6NwTerms; j++) {
              expect((g.term(i, nLeft) - g.term(j, nLeft)).distance, greaterThan(40), reason: 'h $h: $i/$j');
            }
          }
        }
        // The droppers: each meets its bar above the shroud, under it at its fuse.
        for (final p in [
          [0, 1, 2],
          [2, 0, 1],
        ]) {
          for (var i = 0; i < 3; i++) {
            final path = g.dropper(i, p, const [2, 0, 1]);
            expect(path.first.dx, M6NwGeo.fuseX[i]);
            expect(path.last.dy, g.barY(p[i]));
            expect(path[1].dy, greaterThan(g.shroudBot), reason: 'its bend is hidden');
            expect(path[2].dy, lessThan(g.shroudTop));
          }
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

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6PillarNewwayPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsNothing);
      expect(_label(L.sceneLabel), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = _seedWhere((d) => d.push == M6NwPush.sfuOnly);
      final c = await _open(t, seed);
      await _refuse(t, M6NwPush.sfuOnly);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askReady)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in M6NwPush.values) {
      final seed = _seedWhere((d) => d.push == push);
      testWidgets('flow (${push.name}, seed $seed): refuse him, isolate, pluck, land, tighten, switch on, padlock, five reasons → pass', (t) async {
        final c = await _open(t, seed);
        await _refuse(t, push);
        await _isolate(t);
        await _wire(t);
        await _switchOn(t);
        expect(_live.lit, isTrue);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _reason(t, M6NwWhy.tighten);
        expect(c.read(guideDirectorProvider).line, contains(L.askFinish));
        await _holdAt(t, _geo.hasp);
        expect(_live.locked, isTrue);
        await _reason(t, M6NwWhy.door);
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.9/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.9/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final mythSeed = _seedWhere((d) => d.push == M6NwPush.myth);
    final sfuSeed = _seedWhere((d) => d.push == M6NwPush.sfuOnly);

    testWidgets('a slip (inside with no lock and tag) shows its card; nothing happened; the play goes on', (t) async {
      final c = await _open(t, sfuSeed);
      await _refuse(t, M6NwPush.sfuOnly);
      await _tapAt(t, _geo.ppe.center);
      await _lt(t, false);
      expect(_live.ltOn, isFalse);
      await _tapAt(t, _geo.pluckHit(0).center);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.noLockTag.textBn), findsOneWidget);
      expect(_live.plucked, isNull);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _tapAt(t, _geo.ltLockHit.center);
      expect(_live.lockTag, isTrue, reason: 'the play goes on');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noLockTag.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, sfuSeed);
      await _refuse(t, M6NwPush.sfuOnly);
      await _lt(t, false);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.pluckHit(i).center);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a hand inside the live pillar: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, sfuSeed);
      await _refuse(t, M6NwPush.sfuOnly);
      await _tapAt(t, _geo.ppe.center);
      await _tapAt(t, _geo.pluckHit(1).center);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.liveHands.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    for (final push in M6NwPush.values) {
      testWidgets('listening to his ${push.name} push = deadly: freeze, then the card', (t) async {
        final c = await _open(t, push == M6NwPush.myth ? mythSeed : sfuSeed);
        expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
        await _pumpUntil(t, find.byType(ChoiceDeck));
        await _pump(t, 600);
        await waitChoiceDeck(t);
        final wrong = _onScreen(L.coworker(push).wrong);
        expect(wrong, isNotEmpty);
        await t.tap(wrong.first, warnIfMissed: false);
        await confirmChoice(t);
        await _pump(t, 800);
        expect(find.byType(FreezeFrame), findsOneWidget);
        await _pump(t, 3500);
        expect(find.byType(MistakeCard), findsOneWidget);
        final s = c.read(gameSaveProvider);
        expect(s.mistakes.single.key, Mk.push(push).key);
        expect(s.mistakes.single.deadly, isTrue);
        await _close(t, c);
      });
    }

    testWidgets('a fast play: the LT handle waits for him; he cuts in at once; after him it moves', (t) async {
      final c = await _open(t, sfuSeed, settle: 0);
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his timer has not run out yet');
      await _lt(t, false);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.ltOn, isTrue, reason: 'the handle did not move');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, L.coworkerSfu.right);
      await _pump(t, 2600);
      await _lt(t, false);
      expect(_live.ltOn, isFalse, reason: 'after him the handle moves');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a loose lug at switch-on: a glance at its glow, the slip; the crew isolates again; prove, tighten, switch on', (t) async {
      final d = m6NwDeal(math.Random(mythSeed));
      final c = await _open(t, mythSeed);
      await _refuse(t, M6NwPush.myth);
      await _isolate(t);
      await _wire(t, loose: M6NwCore.n);
      await _switchOn(t);
      await _pump(t, 1800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.looseLug.textBn), findsOneWidget);
      expect(_live.lit, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect((_live.ltOn, _live.lockTag, _live.doorOpen, _live.provenDead), (false, true, true, false));
      expect(c.read(guideDirectorProvider).line, contains(L.askFix));
      await _tapAt(t, _geo.ltSupply.center);
      await _tapAt(t, _geo.barsHit.center);
      await _tapAt(t, _geo.ltSupply.center);
      expect(_live.provenDead, isTrue);
      await _holdAt(t, _geo.term(kM6NwNLink, d.nLeft));
      expect(_live.tight, contains(M6NwCore.n));
      await _switchOn(t);
      expect(_live.lit, isTrue);
      await _reason(t, M6NwWhy.tighten);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.looseLug.key);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, sfuSeed);
      await _refuse(t, M6NwPush.sfuOnly);
      await _tapAt(t, _geo.ppe.center);
      await _sfu(t, false);
      await _lt(t, false);
      await _tapAt(t, _geo.ltLockHit.center);
      await _tapAt(t, _geo.testerHit.center);
      await _tapAt(t, _geo.ltSupply.center);
      await _tapAt(t, _geo.barsHit.center);
      await t.tapAt(_geo.ltSupply.center * _k);
      await t.pump(const Duration(milliseconds: 100));
      // The ◆ on the table, the deck opening: the scene takes nothing.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.pluckHit(k).center * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.tapAt(_geo.ltLockHit.center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.plucked, isNull);
      expect(_live.lockTag, isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M6NwWhy.isolate);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle, a sweep that presses nothing; three taps on nothing bring it back', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, sfuSeed);
      await _refuse(t, M6NwPush.sfuOnly);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while getting ready');
      expect(scene().debugOptions.length, greaterThan(3), reason: 'a sweep over the stand, the box, the SFU, the tester and the cores');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _tapAt(t, _geo.ppe.center);
      expect(scene().showing, isFalse);
      final empty = Offset(225, _geo.y(0.78)) * _k;
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
