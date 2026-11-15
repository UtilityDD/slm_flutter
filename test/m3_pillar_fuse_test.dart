// Lesson 3.7 (এলটি ফিডার পিলার), কাজ 1 "ফিউজ বদলাও ঠিকঠাক": the rules (owner
// ruling A5, 2026-11-15: the DTR's LT switch OFF, locked and tagged, proved
// dead live-dead-live before any fuse — a fuse touched with the LT on is
// deadly, no PPE after a proven isolation is a slip, the LT on with the door
// open is a slip; the fuse puller, only the docket's fuse, the cause found
// before the new fuse, only an HRC fuse — a copper strip or a thick wire is
// deadly — the door shut and locked before signing off), the deal, the reason
// libraries, and the level in the shell: idle perf, the guide first, a full
// clean play with the coworker refused, a slip card that keeps the pillar,
// three slips, the deadly freeze (a live fuse; listening to him).
// Kit 2026-11-11: he comes even on a fast fit (holdForCoworker); a sound spot
// called the cause is a slip (once per spot); the tool row is never in the
// job's order; each reason deck carries a myth with the question's key word;
// a tap in the praise window does nothing; the gesture hint sweeps over every
// control (never presses one).
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
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_pillar_fuse.dart';
import 'package:slm_flutter/features/game/m3_pillar_fuse_world.dart';
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
  rungId: '3.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m3PillarFusePacks['do_3_7_a']!;
typedef _L = M3PillarFuseLines;
typedef _M = M3PillarFuseMistakes;

/// The new art is not in pubspec yet (the director adds the folder): tests
/// read it from disk when the bundle does not have it.
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
M3PillarFuseGeo get _geo => M3PillarFuseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M3PillarFusePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// The LT off, locked and tagged; PPE on, the door open; the tester proved,
/// 0 V across the docket's fuse, proved again; the cause spotted, the blown
/// fuse pulled.
Future<void> _toTray(WidgetTester t, M3PillarFuseRound r) async {
  await _tapAt(t, _geo.ltHit.center); // LT OFF
  await _tool(t, _L.lockTag);
  await _tool(t, _L.ppe);
  await _tapAt(t, _geo.body.center);
  await _tool(t, _L.tester);
  await _tapAt(t, _geo.ltHit.center); // proved on the live side
  await _tapAt(t, _geo.fuse(r.feeder, r.phase)); // 0 V
  await _tapAt(t, _geo.ltHit.center); // proved again
  await _tapAt(t, _geo.causeHits(r.cause, r.feeder).first.center);
  await _pump(t, 1800);
  await _tool(t, _L.puller);
  await _tapAt(t, _geo.fuse(r.feeder, r.phase));
}

/// After the fit: the door shut, the lock and tag off, the LT on (the lights).
Future<void> _restore(WidgetTester t) async {
  await _tapAt(t, _geo.openDoorHit.center); // shut
  await _tool(t, _L.lockTag);
  await _tapAt(t, _geo.ltHit.center); // LT ON
}

/// Plays pillar [i] right (the coworker refused on his pillar).
Future<void> _playRight(WidgetTester t, M3PillarFuseDeal deal, int i) async {
  final r = deal.rounds[i];
  await _toTray(t, r);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on pillar $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2600);
  }
  expect(await _pumpUntil(t, _label(_L.itemBn(M3PillarFuseItem.hrc)), maxMs: 3000), isTrue, reason: 'the tray on pillar $i');
  await _tool(t, _L.itemBn(M3PillarFuseItem.hrc));
  await _pump(t, 600);
  await _restore(t);
  await _tool(t, _L.lock);
  await _tool(t, _L.signOff);
  await _pump(t, 1200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pillar $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(r));
  await _pump(t, 6000);
}

int _seedWhere(bool Function(M3PillarFuseDeal d) ok) {
  for (var s = 1; s < 500; s++) {
    if (ok(m3PillarFuseDeal(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

void main() {
  group('rules', () {
    test('deals: three pillars, three causes, three reasons; he comes once; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m3PillarFuseDeal(math.Random(s));
        expect(d.rounds, hasLength(3));
        expect(d.rounds.map((r) => r.cause).toSet(), hasLength(3));
        expect(d.rounds.map((r) => r.why).toSet(), hasLength(3));
        expect(d.callAt, inInclusiveRange(0, 2));
        for (final r in d.rounds) {
          expect(r.feeder, inInclusiveRange(0, 2));
          expect(r.phase, inInclusiveRange(0, 2));
          expect(r.tray.toSet(), M3PillarFuseItem.values.toSet());
          expect(r.tools.toSet(), M3PillarFuseTool.values.toSet());
          expect(r.tools, isNot(orderedEquals(M3PillarFuseTool.values)), reason: "the tool row is never the job's order");
        }
        seen.add(d.rounds.map((r) => '${r.feeder}${r.phase}${r.cause.name}${r.why.name}${r.tray.first.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(60));
      final rows = {
        for (var s = 0; s < 40; s++)
          for (final r in m3PillarFuseDeal(math.Random(s)).rounds) r.tools.map((t) => t.name).join(','),
      };
      expect(rows.length, greaterThan(8), reason: 'tool rows vary');
    });

    M3PillarFuseRun run1({int feeder = 1, int phase = 2}) => M3PillarFuseRun(M3PillarFuseDeal(rounds: [
          M3PillarFuseRound(id: 'x', feeder: feeder, phase: phase, cause: M3PillarFuseCause.water, why: M3PillarFuseWhy.hrc, tray: M3PillarFuseItem.values),
        ], callAt: 0));

    /// The LT off, locked and tagged, the door open, proved dead live-dead-live.
    M3PillarFuseRun isolated({bool ppe = true}) {
      final r = run1()..toggleLt();
      r.toggleLockTag();
      if (ppe) r.putPpe();
      r
        ..toggleDoor()
        ..holdTester()
        ..testLive()
        ..testPillar()
        ..testLive()
        ..holdTester();
      return r;
    }

    test('a fuse touched with the LT on is deadly (A5): bare or puller, any fuse, PPE or not; the door shut, nothing happens', () {
      final shut = run1();
      expect(shut.tapFuse(1, 2), isNull);
      final bare = run1()..toggleDoor();
      final m = bare.tapFuse(1, 2);
      expect(m, _M.liveFuse);
      expect(m!.deadly, isTrue);
      expect(bare.ended, isTrue);
      final dressed = run1()
        ..putPpe()
        ..toggleDoor()
        ..holdPuller();
      expect(dressed.tapFuse(0, 0), _M.liveFuse, reason: 'a healthy fuse, PPE and puller: still live');
      expect(dressed.ended, isTrue);
    });

    test('LT off: no lock and tag, no 0 V reading, no proof after are slips, in that order; then the fuse comes out', () {
      final r = run1()
        ..toggleLt()
        ..putPpe()
        ..toggleDoor()
        ..holdPuller();
      expect(r.tapFuse(1, 2), _M.noLockTag);
      expect(r.toggleLockTag(), isTrue);
      expect(r.tapFuse(1, 2), _M.noTest);
      r
        ..holdTester()
        ..testLive();
      expect(r.testPillar(), (false, null));
      expect(r.deadSeen, isTrue);
      r.holdPuller();
      expect(r.tapFuse(1, 2), _M.noReprove);
      r
        ..holdTester()
        ..testLive()
        ..holdPuller();
      expect(r.provenDead, isTrue);
      expect(r.tapFuse(1, 2), isNull);
      expect(r.slotEmpty, isTrue);
      expect(r.slips, 3);
      expect(r.deadly, isNull);
      expect(r.caught, contains(_L.caughtIsolate));
      for (final m in [_M.noLockTag, _M.noTest, _M.noReprove, _M.testFirst, _M.onDoorOpen]) {
        expect(m.deadly, isFalse, reason: m.key);
      }
    });

    test('after a proven isolation no PPE is a slip, not deadly (A5)', () {
      final r = isolated(ppe: false)..holdPuller();
      final m = r.tapFuse(1, 2);
      expect(m, _M.noPpe);
      expect(m!.deadly, isFalse);
      expect(r.ended, isFalse);
      expect(r.slips, 1);
      r.putPpe();
      expect(r.tapFuse(1, 2), isNull);
    });

    test('the tester: a 0 V before it is proved is a slip; a live reading is never punished; proving needs it in hand', () {
      final r = run1()..toggleDoor();
      expect(r.testLive(), isFalse, reason: 'no tester in hand');
      r.holdTester();
      expect(r.testPillar(), (true, null), reason: 'LT on: voltage, no cost');
      expect(r.slips, 0);
      expect(r.deadly, isNull);
      r.toggleLt();
      expect(r.ltOn, isFalse, reason: 'OFF with the door open is fine');
      expect(r.testPillar(), (false, _M.testFirst));
      expect(r.deadSeen, isFalse);
      expect(r.slips, 1);
      expect(r.testLive(), isTrue);
      expect(r.provedBefore, isTrue);
      expect(r.testPillar(), (false, null));
      expect(r.deadSeen, isTrue);
      expect(r.provedAfter, isFalse);
      expect(r.testLive(), isTrue);
      expect(r.provedAfter, isTrue);
      r.holdPuller();
      expect(r.tester, isFalse, reason: 'one tool in hand');
    });

    test('the LT switch: lock and tag only when OFF, a locked handle does not move; ON with the door open is a slip; ON voids the proof', () {
      final r = run1();
      expect(r.toggleLockTag(), isFalse, reason: 'the LT is on');
      expect(r.toggleLt(), (true, null));
      expect(r.ltOn, isFalse);
      expect(r.toggleLockTag(), isTrue);
      expect(r.toggleLt(), (false, null), reason: 'locked and tagged');
      expect(r.ltOn, isFalse);
      r
        ..toggleDoor()
        ..holdTester()
        ..testLive()
        ..testPillar();
      expect(r.deadSeen, isTrue);
      expect(r.toggleLockTag(), isTrue, reason: 'off again');
      expect(r.toggleLt(), (false, _M.onDoorOpen));
      expect(r.ltOn, isFalse, reason: 'it did not go on');
      expect(r.slips, 1);
      r.toggleDoor();
      expect(r.toggleLt(), (true, null));
      expect(r.ltOn, isTrue);
      expect(r.deadSeen, isFalse, reason: 'back on: the proof is void');
      expect(r.provedBefore, isFalse);
    });

    test('with PPE: a hand is a slip; a healthy fuse is a slip; the docket\'s fuse comes out', () {
      final r = isolated();
      expect(r.tapFuse(1, 2), _M.noPuller);
      r.holdPuller();
      expect(r.tapFuse(1, 1), _M.wrongFuse);
      expect(r.tapFuse(0, 2), _M.wrongFuse);
      expect(r.slotEmpty, isFalse);
      expect(r.tapFuse(1, 2), isNull);
      expect(r.slotEmpty, isTrue);
      expect(r.trayUp, isTrue);
      expect(r.slips, 3);
      expect(r.caught, containsAll([_L.caughtPpe, _L.caughtFuse]));
    });

    test('the tray: a strip or a wire is deadly; HRC before the cause is a slip; after it, in; the LT back on first is deadly', () {
      M3PillarFuseRun pulled() => isolated()
        ..holdPuller()
        ..tapFuse(1, 2);
      final live = pulled()
        ..toggleDoor()
        ..toggleLockTag()
        ..toggleLt();
      expect(live.ltOn, isTrue);
      expect(live.trayUp, isTrue);
      expect(live.fit(M3PillarFuseItem.hrc), _M.liveFuse, reason: 'a new fuse into a live slot');
      expect(live.ended, isTrue);
      final s = pulled();
      expect(s.fit(M3PillarFuseItem.strip), _M.bodgeStrip);
      expect(s.ended, isTrue);
      expect(pulled().fit(M3PillarFuseItem.wire), _M.bodgeWire);
      final h = pulled();
      expect(h.fit(M3PillarFuseItem.hrc), _M.noCause);
      expect(h.fitted, isFalse);
      expect(h.spot(false), isFalse);
      expect(h.spot(true), isTrue);
      expect(h.spot(true), isFalse, reason: 'once');
      expect(h.fit(M3PillarFuseItem.hrc), isNull);
      expect(h.fitted, isTrue);
      expect(h.trayUp, isFalse);
      expect(h.caught, containsAll([_L.caughtCause, _L.caughtHrc]));
    });

    test('a sound spot called the cause is a slip, once per spot; none once the cause is found', () {
      final r = run1();
      expect(r.flagSound(0), isNull, reason: 'the door is shut');
      r.toggleDoor();
      expect(r.flagSound(0), _M.wrongSpot);
      expect(r.flagSound(0), isNull, reason: 'the same spot again');
      expect(r.flagSound(4), _M.wrongSpot);
      expect(r.slips, 2);
      expect(r.spot(true), isTrue);
      expect(r.flagSound(1), isNull, reason: 'the cause is found');
      expect(r.slips, 2);
      expect(_M.wrongSpot.deadly, isFalse);
    });

    test('cause zones: each cause sits in its own spot; spots never overlap', () {
      final g = _geo;
      final zones = g.causeZones;
      expect(zones, hasLength(5));
      for (final c in M3PillarFuseCause.values) {
        for (var f = 0; f < 3; f++) {
          expect(zones[M3PillarFuseGeo.causeZone(c, f)], g.causeHits(c, f));
        }
      }
      for (var a = 0; a < zones.length; a++) {
        for (var b = a + 1; b < zones.length; b++) {
          for (final x in zones[a]) {
            for (final y in zones[b]) {
              expect(x.overlaps(y), isFalse, reason: '$a/$b');
            }
          }
        }
      }
    });

    test('sign off: not before the fuse is in and the LT on; door open and unlocked are slips; locked = done', () {
      final r = isolated();
      expect(r.signOff(), isNull);
      expect(r.signedOff, isFalse);
      r
        ..spot(true)
        ..holdPuller()
        ..tapFuse(1, 2)
        ..fit(M3PillarFuseItem.hrc);
      expect(r.fitted, isTrue);
      expect(r.lightsOn, isFalse, reason: 'the LT is still off');
      expect(r.signOff(), isNull, reason: 'the feeder is still dead');
      expect(r.toggleLock(), isFalse, reason: 'no lock on an open door');
      expect(r.toggleDoor(), isTrue);
      expect(r.toggleLockTag(), isTrue);
      expect(r.toggleLt(), (true, null));
      expect(r.lightsOn, isTrue);
      expect(r.toggleDoor(), isTrue, reason: 'opened again');
      expect(r.signOff(), _M.doorOpen);
      expect(r.toggleDoor(), isTrue);
      expect(r.signOff(), _M.noLock);
      expect(r.toggleLock(), isTrue);
      expect(r.toggleDoor(), isFalse, reason: 'locked');
      expect(r.signOff(), isNull);
      expect(r.signedOff, isTrue);
      expect(r.caught, contains(_L.caughtLock));
      expect(r.slips, 2);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
    });

    test('English digits only; every mistake has its picture; the deadly ones', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final c in M3PillarFuseCause.values) _L.causeSeen(c),
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly).toSet(), {_M.liveFuse, _M.bodgeStrip, _M.bodgeWire});
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('3.7/m3_pillar_fuse/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m3PillarFusePacks.keys, ['do_3_7_a']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      for (final w in M3PillarFuseWhy.values) {
        final r = M3PillarFuseRound(id: 'x', feeder: 0, phase: 0, cause: M3PillarFuseCause.hotspot, why: w, tray: M3PillarFuseItem.values);
        final right = _L.whyRight(r);
        expectLibrary('$w', right, _L.myths);
        expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, _L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(_L.myths.toSet(), hasLength(_L.myths.length));
      const key = {M3PillarFuseWhy.hrc: 'HRC', M3PillarFuseWhy.cause: 'কারণ', M3PillarFuseWhy.ppe: 'পিপিই', M3PillarFuseWhy.lock: 'দরজা'};
      for (final w in M3PillarFuseWhy.values) {
        final r = M3PillarFuseRound(id: 'x', feeder: 0, phase: 0, cause: M3PillarFuseCause.hotspot, why: w, tray: M3PillarFuseItem.values);
        expect(_L.myths, containsAll(_L.whyEcho(r)));
        for (final e in _L.whyEcho(r)) {
          expect(e, contains(key[w]!), reason: e);
        }
        final seen = <String>{};
        for (var k = 0; k < 40; k++) {
          final deal = _L.dealWhy(r, math.Random(k));
          expect(deal, hasLength(3));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(_L.whyRight(r), contains(deal.firstWhere((o) => o.correct).textBn));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          final wrong = deal.where((o) => !o.correct).map((o) => o.textBn).toList();
          expect(wrong.every(_L.myths.contains), isTrue);
          expect(wrong.any((t) => t.contains(key[w]!)), isTrue, reason: 'the key word is not on the right card alone: $wrong');
          seen.addAll(wrong);
        }
        expect(seen.length, greaterThan(5), reason: 'the myths vary');
      }
      final cw = _L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('the scene: no tap zone overlaps another', () {
      final g = _geo;
      final fuses = [
        for (var f = 0; f < 3; f++)
          for (var p = 0; p < 3; p++) g.fuseHit(f, p),
      ];
      for (var i = 0; i < fuses.length; i++) {
        for (var j = i + 1; j < fuses.length; j++) {
          expect(fuses[i].overlaps(fuses[j]), isFalse, reason: '$i/$j');
        }
        expect(fuses[i].overlaps(g.openDoorHit), isFalse);
        expect(fuses[i].overlaps(g.ltHit), isFalse);
      }
      expect(g.ltHit.overlaps(g.openDoorHit), isFalse, reason: 'the LT switch and the open door');
      expect(g.ltHit.overlaps(g.body), isFalse);
      expect(g.ltHit.contains(g.ltBox.center), isTrue);
      for (final c in M3PillarFuseCause.values) {
        for (var f = 0; f < 3; f++) {
          for (final h in g.causeHits(c, f)) {
            expect(g.body.contains(h.center), isTrue);
            expect(fuses.any((x) => x.contains(h.center)), isFalse, reason: '$c F$f');
            expect(fuses.any((x) => x.overlaps(h)), isFalse, reason: 'cause hit $c F$f touches a fuse hit');
            expect(h.overlaps(g.openDoorHit), isFalse, reason: '$c F$f');
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
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3PillarFusePage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m3_pillar_fuse ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3PillarFusePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.puller), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.puller), findsOneWidget);
      expect(find.text(_L.docketBn(m3PillarFuseDeal(math.Random(3)).rounds[0])), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askOpen)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: LT off + lock and tag, PPE, live-dead-live, cause, the docket\'s fuse, HRC, shut, LT on, lock; refuse him; right reasons → pass', (t) async {
      final deal = m3PillarFuseDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.7/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.7/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtCause), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the LT off, no lock and tag) shows its card; the same pillar goes on after it', (t) async {
      final deal = m3PillarFuseDeal(math.Random(2));
      final r = deal.rounds[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.ltHit.center); // LT OFF
      await _tool(t, _L.ppe);
      await _tapAt(t, _geo.body.center);
      await _tapAt(t, _geo.fuse(r.feeder, r.phase));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.noLockTag.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.puller), findsOneWidget, reason: 'the same pillar');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.noLockTag.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the tester shows its reading by the tap; a 0 V before proving it is a slip card', (t) async {
      final r = m3PillarFuseDeal(math.Random(2)).rounds[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.body.center);
      await _tool(t, _L.tester);
      await _tapAt(t, _geo.fuse(r.feeder, r.phase));
      expect(find.text(_L.testerLive), findsOneWidget, reason: 'the LT is on: voltage');
      expect(find.byType(MistakeCard), findsNothing, reason: 'a live reading is never punished');
      await _pump(t, 2400);
      await _tapAt(t, _geo.openDoorHit.center); // shut
      await _tool(t, _L.tester); // put down
      await _tapAt(t, _geo.ltHit.center); // LT OFF
      await _tapAt(t, _geo.body.center);
      await _tool(t, _L.tester);
      await _tapAt(t, _geo.fuse(r.feeder, r.phase));
      expect(find.text(_L.testerDead), findsOneWidget);
      await _pump(t, 600);
      expect(find.text(_M.testFirst.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.testFirst.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the LT on with the pillar door open: a slip card; the LT stays off', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.ltHit.center); // LT OFF
      await _tapAt(t, _geo.body.center); // open
      await _tapAt(t, _geo.ltHit.center); // LT ON?
      await _pump(t, 600);
      expect(find.text(_M.onDoorOpen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.onDoorOpen.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('no PPE at the fuse after a proven isolation: a slip card, not the freeze (A5)', (t) async {
      final r = m3PillarFuseDeal(math.Random(2)).rounds[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.ltHit.center);
      await _tool(t, _L.lockTag);
      await _tapAt(t, _geo.body.center);
      await _tool(t, _L.tester);
      await _tapAt(t, _geo.ltHit.center);
      await _tapAt(t, _geo.fuse(r.feeder, r.phase));
      await _tapAt(t, _geo.ltHit.center);
      await _tool(t, _L.puller);
      await _tapAt(t, _geo.fuse(r.feeder, r.phase));
      await _pump(t, 600);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(_M.noPpe.textBn), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final r = m3PillarFuseDeal(math.Random(2)).rounds[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.ltHit.center); // LT OFF, no lock and tag
      await _tool(t, _L.ppe);
      await _tapAt(t, _geo.body.center);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.fuse(r.feeder, r.phase));
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('he comes even on a fast fit: the tray waits for him, then the HRC fuse goes in', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = m3PillarFuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _toTray(t, deal.rounds[0]);
      // At once (well before his 1.2 s): the decisive fit.
      await _tool(t, _L.itemBn(M3PillarFuseItem.hrc));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'a fast fit cannot skip him');
      expect(find.text(_L.stampLights), findsNothing, reason: 'the fuse did not go in yet');
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      expect(await _pumpUntil(t, _label(_L.itemBn(M3PillarFuseItem.hrc)), maxMs: 3000), isTrue);
      await _tool(t, _L.itemBn(M3PillarFuseItem.hrc));
      await _pump(t, 300);
      expect(find.text(_L.stampLights), findsNothing, reason: 'the LT is still off');
      await _restore(t);
      expect(find.text(_L.stampLights), findsOneWidget);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'once a play');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a sound spot called the cause: a slip card (once per spot); the cause is still to find', (t) async {
      final deal = m3PillarFuseDeal(math.Random(2));
      final r = deal.rounds[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.body.center); // open
      final real = M3PillarFuseGeo.causeZone(r.cause, r.feeder);
      final sound = _geo.causeZones[(real + 1) % 5].first.center;
      await _tapAt(t, sound);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.wrongSpot.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.wrongSpot.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapAt(t, sound);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the same spot costs once');
      await _tapAt(t, _geo.causeHits(r.cause, r.feeder).first.center);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the cause itself');
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the praise window: taps on the scene and the tool row do nothing until the reason deck', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final r = m3PillarFuseDeal(math.Random(seed)).rounds[0];
      final c = await _open(t, seed);
      await _toTray(t, r);
      await _tool(t, _L.itemBn(M3PillarFuseItem.hrc));
      await _pump(t, 600);
      await _restore(t);
      await _tool(t, _L.lock);
      final lock = t.getCenter(_label(_L.lock));
      final signOff = t.getCenter(_label(_L.signOff));
      await t.tap(_label(_L.signOff));
      await t.pump(const Duration(milliseconds: 50));
      for (final at in [signOff, lock, _geo.body.center * _k, _geo.fuse(r.feeder, r.phase) * _k]) {
        await t.tapAt(at);
        await t.pump(const Duration(milliseconds: 50));
      }
      await waitChoiceDeck(t);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep over every tool and the pillar while waiting (never presses one); the tray too', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.callAt != 0);
      final r = m3PillarFuseDeal(math.Random(seed)).rounds[0];
      final c = await _open(t, seed);
      IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      expect(hint().showing, isFalse);
      await _pump(t, 9000);
      expect(hint().showing, isTrue, reason: 'stuck at the shut pillar: the hand shows');
      expect(hint().debugOptions, hasLength(8), reason: 'all six tools, the pillar and the LT switch');
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 120));
        final f = hint().debugFrame;
        if (f != null) expect(f.press, 0, reason: 'a sweep never presses');
      }
      await _toTray(t, r);
      expect(hint().showing, isFalse, reason: 'a touch hides it');
      await _pump(t, 9000);
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(6), reason: 'the three tray items, the pillar, its door and the LT switch');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a fuse touched with the LT on (A5): the street freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.ppe);
      await _tapAt(t, _geo.body.center);
      await _tool(t, _L.puller);
      await _tapAt(t, _geo.fuse(0, 0));
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.liveFuse.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = the copper strip: freeze, then the card', (t) async {
      final deal = m3PillarFuseDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _toTray(t, deal.rounds[deal.callAt]);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.bodgeStrip.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
