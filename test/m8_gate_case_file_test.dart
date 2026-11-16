// The Module 8 rank gate "আইনের ডকেট: আলো ফেরান, প্রমাণ রাখুন"
// (m8_gate_case_file): the deal (two of three complications, 0–2 solar houses
// with clue mixes, times that leave slack and make "everything everywhere"
// overrun), the engine's rules (every deadly and slip row of the module table
// after the rulings, one slip per move, the climb judged on PTW + tester 0 V +
// both earths + every solar fuse), the hearing, the option libraries (lengths
// within 1.3×), English digits and the owner's term rules, the coworker's lines
// (recorded or listed) and every spoken line listed, the mistakes, and the
// page: the guide first, idle = zero frames (with and without reduced motion),
// a full clean play to the rank-up (incl. reason picks, the phone's coworker
// held and refused, the hearing), listening to him (deadly / slip), a deadly
// move (freeze → near-miss), three slips (strike-out), a roof hold and the
// gesture hint (presses nothing).
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
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_gate_case_file.dart';
import 'package:slm_flutter/features/game/m8_gate_case_file_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: 'm8/gate',
  kind: CatalogRungKind.gate,
  lessonId: '8.10',
  lessonTitleBn: '',
  ladderStep: 210,
);

final _pack = m8GatePacks['gate_m8']!;

int _seedWhere(bool Function(M8GDeal d) ok) {
  for (var s = 1; s < 60000; s++) {
    if (ok(dealM8G(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

M8GRun _runWhere(bool Function(M8GDeal d) ok) => M8GRun(dealM8G(math.Random(_seedWhere(ok))));

// --- the engine ------------------------------------------------------------------
void _ok(M8GOut o, String why) {
  expect(o.mistake, isNull, reason: why);
  expect(o.bounce, isFalse, reason: why);
}

const _van = M8GTgt.van;

/// A lawful run up to just before the climb: PTW, tester, both rods, every
/// solar fuse, and (when [hook]) the pole video of the hooking wire.
M8GRun _ready(M8GDeal d, {bool hook = true}) {
  final r = M8GRun(d);
  _ok(r.drop(M8GTok.permit, _van), 'permit');
  _ok(r.drop(M8GTok.tester, M8GTgt.pole(0)), 'tester');
  _ok(r.drop(M8GTok.rod, M8GTgt.pole(0)), 'rod 1');
  _ok(r.drop(M8GTok.rod, M8GTgt.pole(3)), 'rod 4');
  for (final h in d.solarHouses) {
    _ok(r.drop(M8GTok.fuse, M8GTgt.house(h)), 'fuse $h');
  }
  if (d.c1 && hook) _ok(r.drop(M8GTok.camera, M8GTgt.wire(d.hookHouse)), 'video');
  return r;
}

/// A full lawful play to the hearing's door.
M8GRun _clean(M8GDeal d) {
  final r = _ready(d);
  if (d.c2) {
    final o = r.drop(M8GTok.trim, M8GTgt.branch(d.touching));
    _ok(o, 'trim');
    expect(o.pay, 10);
  }
  if (d.c1) {
    final o = r.drop(M8GTok.hook, M8GTgt.wire(d.hookHouse));
    _ok(o, 'hook');
    expect(o.reason, M8GReason.video);
  }
  final c = r.drop(M8GTok.climb, M8GTgt.pole(1));
  _ok(c, 'climb');
  expect(c.reason, M8GReason.climb);
  expect(r.restored, isTrue);
  if (d.c3) _ok(r.drop(M8GTok.camera, M8GTgt.house(d.c3House)), 'lit photo');
  if (d.c1) {
    _ok(r.drop(M8GTok.seize, M8GTgt.house(d.hookHouse)), 'seizure');
    _ok(r.drop(M8GTok.police, _van), 'police');
  }
  _ok(r.drop(M8GTok.report, _van), 'report');
  return r;
}

// --- the page ----------------------------------------------------------------------
Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

Future<void> _until(WidgetTester t, bool Function() ok, {int maxMs = 30000, String? reason}) async {
  for (var ms = 0; ms < maxMs && !ok(); ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(ok(), isTrue, reason: reason);
}

Future<void> _waitDeckUp(WidgetTester t) async {
  final cards = find.descendant(of: find.byType(ChoiceDeck), matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.button ?? false)));
  await _until(t, () => cards.hitTestable().evaluate().length == 3, maxMs: 10000, reason: 'deck up');
}

/// Picks the right card of the deck now up and its এগিয়ে যান.
Future<void> _pickDeckRight(WidgetTester t, M8GateProbe p) async {
  await _waitDeckUp(t);
  final right = p.rightNow;
  final r = [for (final x in right) if (_label(x).evaluate().isNotEmpty) _label(x)];
  expect(r, hasLength(1), reason: 'one right card of ${right.join(' | ')}');
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  await t.pump();
  for (var i = 0; i < 60 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty && find.byType(ChoiceDeck).evaluate().isNotEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
  await _pump(t, 500);
}

Future<void> _tapKey(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await t.tap(f, warnIfMissed: false);
  await t.pump();
  await _pump(t, 150);
}

/// A belt token onto a place (the lane panned to it first).
Future<void> _use(WidgetTester t, M8GateProbe p, M8GTok tok, M8GTgt g) async {
  p.panTo(g);
  await t.pump();
  await _tapKey(t, 'm8g-tok-${tok.name}');
  expect(p.phase, 'lifted');
  await _tapKey(t, 'm8g-tgt-${g.key}');
}

Future<void> _idle(WidgetTester t, M8GateProbe p) async => _until(t, () => p.phase == 'idle', maxMs: 8000, reason: 'back to the lane');

Future<ProviderContainer> _openPage(WidgetTester t, int seed, M8GateProbe probe) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M8GateCaseFilePage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
  )));
  await _pump(t, 600);
  await waitIntro(t);
  return c;
}

Future<void> _closePage(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

String _nk(String s) => s
    .replaceAll(String.fromCharCode(0x09DF), String.fromCharCodes([0x09AF, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DC), String.fromCharCodes([0x09A1, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DD), String.fromCharCodes([0x09A2, 0x09BC]));

void main() {
  group('rules', () {
    test('the deal: two of three complications, solar mixes, clues, times with slack, variety', () {
      final solarN = <int, int>{};
      final combos = <int>{};
      var mirrors = 0;
      var nonRoofClue = 0;
      var solarPlays = 0;
      for (var s = 0; s < 600; s++) {
        final d = dealM8G(math.Random(s));
        solarN[d.solarCount] = (solarN[d.solarCount] ?? 0) + 1;
        combos.add(d.combo);
        if (d.mirror) mirrors++;
        expect([d.c1, d.c2, d.c3].where((x) => x), hasLength(2), reason: 'two of three ($s)');
        expect(d.houses, hasLength(6));
        expect(d.hookHouse, d.c1 ? anyOf(0, 1) : -1);
        expect(d.touching, d.c2 ? inInclusiveRange(0, 2) : -1);
        if (d.c3) {
          expect(d.houses[d.c3House].solar, isFalse, reason: 'the complaining house is not solar');
          expect(d.c3House, isNot(d.hookHouse));
        }
        if (d.c1) expect(d.houses[d.hookHouse].solar, isFalse);
        for (final h in d.solarHouses) {
          final a = d.houses[h].art;
          expect(a.panel || a.parapet || a.sticker || a.net, isTrue, reason: 'every solar house has a clue ($s)');
          expect(a.panel && a.flat, isFalse, reason: 'panels show on a pitched roof');
        }
        if (d.solarCount > 0) {
          solarPlays++;
          if (d.solarHouses.any((h) => d.houses[h].art.sticker || d.houses[h].art.net)) nonRoofClue++;
        }
        for (var i = 0; i < 6; i++) {
          if (!d.houses[i].solar) {
            final a = d.houses[i].art;
            expect(a.panel || a.parapet || a.sticker || a.net, isFalse, reason: 'no false clue on a plain house');
          }
        }
        // Times: registration 17:00–18:30, arrival 20–60 min later, the phone at 2–6.
        expect(d.regMin, inInclusiveRange(17 * 60, 18 * 60 + 30));
        expect(d.arriveOff, inInclusiveRange(20, 60));
        expect(d.permitTrip, inInclusiveRange(20, 35));
        expect(d.repairMin, inInclusiveRange(50, 75));
        expect(d.phoneAt, inInclusiveRange(2, 6));
        expect(d.remaining - d.minimalToReport, greaterThanOrEqualTo(30), reason: 'slack of the shortest lawful plan ($s)');
        expect(d.everythingMin, greaterThan(d.remaining), reason: 'everything everywhere overruns ($s)');
      }
      expect(solarN.keys.toSet(), {0, 1, 2});
      expect(solarN[0]! / 600, inInclusiveRange(0.12, 0.40), reason: 'no solar in about one play in four');
      expect(combos, {0, 1, 2});
      expect(mirrors, inInclusiveRange(200, 400));
      expect(nonRoofClue, solarPlays, reason: 'every solar play has at least one non-roof clue');
      // Never the same pair of complications twice in a row.
      for (var s = 0; s < 80; s++) {
        final a = dealM8G(math.Random(s));
        final b = dealM8G(math.Random(s + 1000), avoidCombo: a.combo);
        expect(b.combo, isNot(a.combo));
      }
    });

    test('a drop where the act cannot happen slides back: no cost, no verdict', () {
      final r = _runWhere((d) => true);
      for (final t in M8GTok.values) {
        for (final g in M8GTgt.all) {
          if (r.fits(t, g)) continue;
          final o = r.drop(t, g);
          expect(o.bounce, isTrue, reason: '$t on $g');
          expect(o.mistake, isNull);
        }
      }
      expect(r.minutes, 0);
      expect(r.slips, 0);
      expect(r.records, isEmpty);
      // ছাঁটা on a house, রড on a house, ক্যামেরা on anything.
      expect(r.fits(M8GTok.trim, M8GTgt.house(0)), isFalse);
      expect(r.fits(M8GTok.rod, M8GTgt.house(0)), isFalse);
      expect(r.fits(M8GTok.camera, M8GTgt.dtr), isTrue);
      expect(r.fits(M8GTok.climb, M8GTgt.pole(0)), isFalse, reason: 'the work poles are 2 and 3');
      expect(r.fits(M8GTok.climb, M8GTgt.pole(2)), isTrue);
    });

    test('rod before the permit = deadly (B8, M8-7); after the permit before 0 V = slip (N2); in order = fine', () {
      var r = _runWhere((d) => true);
      var o = r.drop(M8GTok.rod, M8GTgt.pole(0));
      expect(o.mistake, M8GMistakes.rodLive.m);
      expect(o.deadly, isTrue);
      expect(M8GMistakes.rodLive.m.deadly, isTrue);
      r = _runWhere((d) => true);
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      o = r.drop(M8GTok.rod, M8GTgt.pole(0));
      expect(o.mistake, M8GMistakes.rodNoTester.m);
      expect(o.deadly, isFalse);
      expect(M8GMistakes.rodNoTester.m.textBn, 'আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।');
      expect(r.slips, 1);
      expect(r.rods, contains(0), reason: 'the rod stays (as the Module 6 earth did)');
      r = _runWhere((d) => true);
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      expect(r.drop(M8GTok.tester, M8GTgt.pole(0)).note, M8GateLines.testerDead);
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(0)), 'rod');
      expect(r.slips, 0);
    });

    test('the tester: live before the permit, 0 V after it; a rod on pole 2 or 3 never counts', () {
      final r = _runWhere((d) => true);
      expect(r.drop(M8GTok.tester, M8GTgt.pole(0)).note, M8GateLines.testerLive);
      expect(r.tested, isFalse);
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      expect(r.drop(M8GTok.tester, M8GTgt.pole(3)).note, M8GateLines.testerDead);
      expect(r.tested, isTrue);
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(1)), 'rod 2');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(2)), 'rod 3');
      expect(r.bothEarths, isFalse, reason: 'rods on poles 2 and 3 do not count');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(0)), 'rod 1');
      expect(r.bothEarths, isFalse);
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(3)), 'rod 4');
      expect(r.bothEarths, isTrue);
    });

    test('the climb: PTW, tester 0 V, earths at pole 1 and 4, every solar fuse out — any missing is deadly, in that order', () {
      final base = _seedWhere((d) => d.solarCount == 1);
      M8GRun fresh() => M8GRun(dealM8G(math.Random(base)));
      // No permit (also after a restore, the permit is closed).
      var r = fresh();
      var o = r.drop(M8GTok.climb, M8GTgt.pole(1));
      expect(o.mistake, M8GMistakes.noPtw.m);
      expect(o.deadly, isTrue);
      // Permit, no tester.
      r = fresh();
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      o = r.drop(M8GTok.climb, M8GTgt.pole(2));
      expect(o.mistake, M8GMistakes.noTester.m);
      // Tester, one end only.
      r = fresh();
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      _ok(r.drop(M8GTok.tester, M8GTgt.pole(0)), 'tester');
      expect(r.drop(M8GTok.rod, M8GTgt.pole(0)).mistake, isNull);
      expect(r.drop(M8GTok.climb, M8GTgt.pole(1)).mistake, M8GMistakes.noEarth.m);
      // The wrong ends (poles 2 and 3) are no earth.
      r = fresh();
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      _ok(r.drop(M8GTok.tester, M8GTgt.pole(0)), 'tester');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(1)), 'rod');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(2)), 'rod');
      expect(r.drop(M8GTok.climb, M8GTgt.pole(1)).mistake, M8GMistakes.noEarth.m);
      // Everything but the solar fuse: deadly every time (M8-2).
      r = fresh();
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      _ok(r.drop(M8GTok.tester, M8GTgt.pole(0)), 'tester');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(0)), 'rod');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(3)), 'rod');
      o = r.drop(M8GTok.climb, M8GTgt.pole(1));
      expect(o.mistake, M8GMistakes.solarIn.m);
      expect(o.deadly, isTrue);
      // All of it: the crew climbs, repairs, comes down; earths off; line back.
      final d = dealM8G(math.Random(base));
      r = _ready(d, hook: false);
      final before = r.minutes;
      o = r.drop(M8GTok.climb, M8GTgt.pole(1));
      expect(o.mistake, isNull);
      expect(o.reason, M8GReason.climb);
      expect(o.restored, isTrue);
      expect(o.cut, M8GateLines.repairCut);
      expect(r.repaired, isTrue);
      expect(r.restored, isTrue);
      expect(r.rods, isEmpty);
      expect(r.minutes - before, d.repairMin);
      expect(r.permitActive, isFalse);
      // The line is live again: a second climb or a rod now is deadly.
      expect(r.drop(M8GTok.climb, M8GTgt.pole(1)).mistake, M8GMistakes.noPtw.m);
    });

    test('solar fuses: the first right one asks why, later ones pay 10; a non-solar fuse is a slip', () {
      final d = dealM8G(math.Random(_seedWhere((d) => d.solarCount == 2)));
      final r = M8GRun(d);
      final s = d.solarHouses;
      var o = r.drop(M8GTok.fuse, M8GTgt.house(s[0]));
      expect(o.reason, M8GReason.solar);
      expect(o.mistake, isNull);
      o = r.drop(M8GTok.fuse, M8GTgt.house(s[1]));
      expect(o.pay, 10);
      expect(o.reason, isNull);
      expect(r.drop(M8GTok.fuse, M8GTgt.house(s[1])).note, M8GateLines.fuseAgain);
      final plain = [for (var i = 0; i < 6; i++) if (!d.houses[i].solar) i].first;
      o = r.drop(M8GTok.fuse, M8GTgt.house(plain));
      expect(o.mistake, M8GMistakes.needlessFuse.m);
      expect(o.deadly, isFalse);
      expect(r.slips, 1);
    });

    test('the hook (C1): a climb with the checks, a normal cable = slip, no pole video = slip, with video = ◆', () {
      final seed = _seedWhere((d) => d.c1 && d.solarCount == 0);
      final d = dealM8G(math.Random(seed));
      // The camera on the hook point makes the pole video; on the house end a wall only.
      var r = _ready(d, hook: false);
      var o = r.drop(M8GTok.camera, M8GTgt.house(d.hookHouse));
      expect(r.records.last.kind, M8GRecKind.hookWall);
      expect(r.hookVideo, isFalse);
      // The hook before the video: a slip (and gone).
      o = r.drop(M8GTok.hook, M8GTgt.wire(d.hookHouse));
      expect(o.mistake, M8GMistakes.removeNoVideo.m);
      expect(o.deadly, isFalse);
      expect(r.hookRemovedNoVideo, isTrue);
      // A normal service cable: a slip.
      r = _ready(d, hook: false);
      final plain = [for (var i = 0; i < 6; i++) if (i != d.hookHouse) i].first;
      o = r.drop(M8GTok.hook, M8GTgt.wire(plain));
      expect(o.mistake, M8GMistakes.badCable.m);
      expect(o.deadly, isFalse);
      // A video of another cable is no pole-hook video.
      r.drop(M8GTok.camera, M8GTgt.wire(plain));
      expect(r.hookVideo, isFalse);
      expect(r.records.last.kind, M8GRecKind.photo);
      // The right order.
      r = _ready(d);
      expect(r.hookVideo, isTrue);
      o = r.drop(M8GTok.hook, M8GTgt.wire(d.hookHouse));
      expect(o.mistake, isNull);
      expect(o.reason, M8GReason.video);
      // The hook is a climb: without the checks it is deadly.
      r = M8GRun(d);
      r.drop(M8GTok.camera, M8GTgt.wire(d.hookHouse));
      o = r.drop(M8GTok.hook, M8GTgt.wire(d.hookHouse));
      expect(o.mistake, M8GMistakes.noPtw.m);
      expect(o.deadly, isTrue);
      r = M8GRun(d);
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      _ok(r.drop(M8GTok.tester, M8GTgt.pole(0)), 'tester');
      _ok(r.drop(M8GTok.rod, M8GTgt.pole(0)), 'rod');
      o = r.drop(M8GTok.hook, M8GTgt.wire(d.hookHouse));
      expect(o.mistake, M8GMistakes.noEarth.m);
      // After the line is back the hook is a live-line climb.
      r = _clean(d);
      expect(r.drop(M8GTok.hook, M8GTgt.wire(d.hookHouse)).deadly, isTrue);
    });

    test('the branch (C2): before the permit = deadly (M8-3), after = right (+10), harmless or the trunk = slip', () {
      final seed = _seedWhere((d) => d.c2);
      final d = dealM8G(math.Random(seed));
      var r = M8GRun(d);
      var o = r.drop(M8GTok.trim, M8GTgt.branch(d.touching));
      expect(o.mistake, M8GMistakes.liveTrim.m);
      expect(o.deadly, isTrue);
      r = M8GRun(d);
      final harmless = [for (var j = 0; j < 3; j++) if (j != d.touching) j].first;
      o = r.drop(M8GTok.trim, M8GTgt.branch(harmless));
      expect(o.mistake, M8GMistakes.trimHarmless.m);
      expect(o.deadly, isFalse, reason: 'a harmless branch before the permit is a slip, not a death');
      o = r.drop(M8GTok.trim, M8GTgt.trunk);
      expect(o.mistake, M8GMistakes.trimHarmless.m);
      expect(r.slips, 2);
      r = M8GRun(d);
      _ok(r.drop(M8GTok.permit, _van), 'permit');
      o = r.drop(M8GTok.trim, M8GTgt.branch(d.touching));
      expect(o.mistake, isNull);
      expect(o.pay, 10);
      expect(r.branchCut, isTrue);
      // Without C2 every branch is harmless.
      final none = _runWhere((x) => !x.c2);
      _ok(none.drop(M8GTok.permit, _van), 'permit');
      for (var j = 0; j < 3; j++) {
        expect(none.drop(M8GTok.trim, M8GTgt.branch(j)).mistake, M8GMistakes.trimHarmless.m);
      }
    });

    test('paper acts leave records and are never judged in the field; the hearing judges them', () {
      final d = dealM8G(math.Random(_seedWhere((d) => d.c1 && d.c3)));
      final r = M8GRun(d);
      var o = r.drop(M8GTok.permit, _van);
      expect(o.paper, isTrue);
      expect(o.mistake, isNull);
      expect(o.cut, M8GateLines.permitCut);
      expect(r.minutes, d.permitTrip);
      expect(r.records.single.kind, M8GRecKind.ptw);
      expect(r.drop(M8GTok.permit, _van).note, M8GateLines.permitAgain);
      o = r.drop(M8GTok.camera, M8GTgt.pole(1));
      expect(o.paper, isTrue);
      expect(r.records.last.labelBn, startsWith('ছবি · '));
      // A seizure list on a house with no hooking: a record, a consequence at the hearing.
      final plain = [for (var i = 0; i < 6; i++) if (i != d.hookHouse) i].first;
      o = r.drop(M8GTok.seize, M8GTgt.house(plain));
      expect(o.mistake, isNull, reason: 'judged at the hearing');
      expect(r.needlessSeize, isTrue);
      expect(r.slips, 0);
      // A report before the repair: a false close.
      o = r.drop(M8GTok.report, _van);
      expect(o.mistake, isNull);
      expect(r.reportFalse, isTrue);
      expect(r.drop(M8GTok.report, _van).note, M8GateLines.alreadyReported);
      // Police once.
      _ok(r.drop(M8GTok.police, _van), 'police');
      expect(r.drop(M8GTok.police, _van).note, M8GateLines.policeAgain);
      // Every act costs game minutes: seizure 10, police 5, report 5, camera 2.
      final c = M8GRun(d);
      c.drop(M8GTok.camera, M8GTgt.van);
      c.drop(M8GTok.seize, M8GTgt.house(0));
      c.drop(M8GTok.police, _van);
      c.drop(M8GTok.report, _van);
      expect(c.minutes, 2 + 10 + 5 + 5);
    });

    test('the clock: the docket slip is on time within 4 h of the registration (live 8.3: an LT wire in a town)', () {
      final d = dealM8G(math.Random(_seedWhere((d) => d.c3 && d.solarCount == 0 && !d.c1)));
      final r = _clean(d);
      final rec = r.records.lastWhere((x) => x.kind == M8GRecKind.docket);
      expect(rec.ok, isTrue, reason: 'a lawful play reports in time');
      expect(r.clock - d.regMin, lessThanOrEqualTo(kM8GLimitMin));
      // Slow it down past the limit.
      final late = _ready(d, hook: false);
      late.minutes += 200;
      late.drop(M8GTok.climb, M8GTgt.pole(1));
      late.drop(M8GTok.report, _van);
      final lr = late.records.lastWhere((x) => x.kind == M8GRecKind.docket);
      expect(lr.ok, isFalse);
      expect(late.reportOnTime, isFalse);
      // The shortest lawful plan fits with slack; everything everywhere does not.
      final everything = M8GRun(d);
      var spent = 0;
      for (final t in M8GTok.values) {
        for (final g in M8GTgt.all) {
          if (!everything.fits(t, g)) continue;
          spent++;
        }
      }
      expect(spent, greaterThan(40));
    });

    test('the coworker: M1 on a touch once the phone has spoken and the PTW is not in the file, M2 at the report or the way home', () {
      final d = dealM8G(math.Random(_seedWhere((d) => d.phoneAt == 2)));
      final r = M8GRun(d);
      expect(r.phoneUp, isFalse);
      expect(r.pushFor(M8GTok.camera, M8GTgt.pole(0)), isNull, reason: 'nothing before the phone speaks');
      r.drop(M8GTok.camera, M8GTgt.pole(0));
      expect(r.phoneUp, isTrue);
      expect(r.pushFor(M8GTok.tester, M8GTgt.pole(0)), M8GPush.phone);
      expect(r.pushFor(M8GTok.trim, M8GTgt.house(0)), isNull, reason: 'a bounce is no touch');
      expect(r.pushFor(M8GTok.permit, _van), M8GPush.phone, reason: 'even the permit waits for him');
      r.drop(M8GTok.permit, _van);
      expect(r.pushFor(M8GTok.tester, M8GTgt.pole(0)), isNull, reason: 'the PTW is in the file: M1 cannot happen');
      expect(r.pushFor(M8GTok.report, _van), M8GPush.report);
      expect(r.pushFor(null, null, home: true), M8GPush.report);
      // Listening to M1: the climb at once without the PTW = deadly (B1).
      final m1 = M8GRun(d)..push = M8GPush.phone;
      final o1 = m1.listened();
      expect(o1.mistake, M8GMistakes.noPtw.m);
      expect(o1.deadly, isTrue);
      // Listening to M2: a slip, the docket stays open.
      final m2 = M8GRun(d)..push = M8GPush.report;
      final o2 = m2.listened();
      expect(o2.mistake, M8GMistakes.listenReport.m);
      expect(o2.deadly, isFalse);
      expect(m2.docketLeft, isTrue);
      expect(m2.slips, 1);
      // In the hearing the docket question is then a consequence with no second slip.
      final qs = m2.buildHearing(math.Random(1));
      final delay = qs.firstWhere((q) => q.kind == M8GQKind.delay);
      expect(delay.consequence, isTrue);
      expect(delay.free, isTrue);
      final c = m2.consequence(delay);
      expect(c.mistake, isNull);
      expect(m2.slips, 1);
    });

    test('the hearing: the right record, a wrong one once, a missing proof, consequences', () {
      final d = dealM8G(math.Random(_seedWhere((d) => d.c1 && d.c3 && d.solarCount == 0)));
      final r = _clean(d);
      expect(r.slips, 0);
      final qs = r.buildHearing(math.Random(3));
      expect(qs.length, inInclusiveRange(1, 4));
      expect(qs.any((q) => q.kind == M8GQKind.delay), isTrue);
      for (final q in qs) {
        expect(q.consequence, isFalse, reason: 'a clean play has no consequence question');
        expect(r.hasRight(q.kind), isTrue, reason: '${q.kind}');
        final right = r.records.firstWhere((x) => r.isRight(q.kind, x));
        // A wrong record, once: a slip with the right one still in the file.
        final wrong = r.records.firstWhere((x) => !r.isRight(q.kind, x));
        final w1 = r.answer(q, wrong);
        expect(w1.mistake, M8GMistakes.wrongRecord.m);
        final slips = r.slips;
        final w2 = r.answer(q, wrong);
        expect(w2.mistake, isNull, reason: 'max one slip per question');
        expect(r.answer(q, null).mistake, isNull, reason: 'the blank card again: no second slip');
        expect(r.slips, slips);
        final ok = r.answer(q, right);
        expect(ok.mistake, isNull);
        expect(ok.reason, M8GRun.reasonOf(q.kind));
        expect(ok.endsQ, isTrue);
        r.slips = 0;
      }
      // The docket's right record is the on-time slip only.
      final docket = r.records.firstWhere((x) => x.kind == M8GRecKind.docket);
      expect(r.isRight(M8GQKind.delay, docket), isTrue);
      expect(r.isRight(M8GQKind.delay, r.records.firstWhere((x) => x.kind == M8GRecKind.ptw)), isFalse, reason: 'the PTW copy is a decoy with times');
      // The video of the hook and not the house end.
      expect(r.isRight(M8GQKind.noCause, r.records.firstWhere((x) => x.kind == M8GRecKind.hookVideo)), isTrue);
      expect(r.records.any((x) => x.kind == M8GRecKind.hookWall), isFalse);

      // A missing proof: any drop gets one slip and the question ends.
      final bare = M8GRun(d);
      bare.drop(M8GTok.camera, M8GTgt.wire(d.hookHouse));
      bare.drop(M8GTok.permit, _van);
      final q = M8GQ(M8GQKind.seizure);
      final o = bare.answer(q, bare.records.first);
      expect(o.mistake, M8GMistakes.noSeizure.m);
      expect(o.endsQ, isTrue);
      expect(bare.answer(M8GQ(M8GQKind.police), null).mistake, M8GMistakes.noPolice.m);
      expect(bare.answer(M8GQ(M8GQKind.claim), null).mistake, M8GMistakes.noPhoto.m);
      expect(bare.answer(M8GQ(M8GQKind.delay), null).mistake, M8GMistakes.docketOpen.m);
      // Late: reported, but past the limit.
      bare.reported = true;
      expect(bare.answer(M8GQ(M8GQKind.delay), null).mistake, M8GMistakes.docketLate.m);
      // The consequences of a needless or false act.
      final cons = M8GRun(d)
        ..needlessSeize = true
        ..reportFalse = true;
      final built = cons.buildHearing(math.Random(5));
      expect(built.where((q) => q.consequence).map((q) => q.kind).toSet(), {M8GQKind.needlessSeize, M8GQKind.falseClose});
      expect(cons.consequence(built.firstWhere((q) => q.kind == M8GQKind.needlessSeize)).mistake, M8GMistakes.needlessSeize.m);
      expect(cons.consequence(built.firstWhere((q) => q.kind == M8GQKind.falseClose)).mistake, M8GMistakes.reportEarly.m);
    });

    test('marks: 100 − 15 × slips, pass at 55; the quick bonus needs no slip', () {
      final r = _runWhere((d) => true);
      expect(r.percent, 100);
      expect(r.passed, isTrue);
      expect(r.quick, isTrue);
      r.slips = 1;
      expect(r.percent, 85);
      expect(r.quick, isFalse);
      r.slips = 2;
      expect(r.percent, 70);
      expect(r.passed, isTrue);
      r.slips = 3;
      expect(r.percent, 55);
      r.slips = 4;
      expect(r.percent, 40);
      expect(r.passed, isFalse);
    });

    test('option libraries: reasons 1 right of ≥ 2, wrong of ≥ 5, every set within 1.3×; the coworker decks too', () {
      for (final r in M8GReason.values) {
        final right = M8GateLines.whyRight(r);
        final wrong = M8GateLines.whyWrong(r);
        expectLibrary(r.name, right, wrong);
        expectSameLength(r.name, [...right, ...wrong]);
      }
      for (final cw in M8GateLines.coworkers) {
        expectLibrary('coworker', cw.right, cw.wrong);
        expectSameLength('coworker ${cw.line}', [...cw.right, ...cw.wrong]);
      }
      expect(M8GateLines.pushPhone.right, isNot(M8GateLines.pushReport.right));
    });

    test('English digits on screen; owner term rules in the new text', () {
      final bnDigit = RegExp('[০-৯]');
      final lines = <String>[
        ...M8GateLines.newGuideLines,
        ...M8GateLines.newRivalLines,
        for (final r in M8GReason.values) ...[...M8GateLines.whyRight(r), ...M8GateLines.whyWrong(r), M8GateLines.caught(r), M8GateLines.question(r)],
        for (final cw in M8GateLines.coworkers) ...[...cw.right, ...cw.wrong],
        for (final t in M8GTok.values) M8GateLines.tok(t),
        for (final g in M8GTgt.all) M8GateLines.tgt(g),
        for (final k in M8GQKind.values) ...[M8GateLines.ask(k), M8GateLines.who(k)],
        M8GateLines.title, M8GateLines.badge, M8GateLines.phoneMsg, M8GateLines.consumerSays, M8GateLines.permitDone,
        M8GateLines.testerLive, M8GateLines.testerDead, M8GateLines.noProof, M8GateLines.docketHeld, M8GateLines.caughtPush, M8GateLines.caughtTrim,
        M8GateLines.roofPanel, M8GateLines.roofParapet, M8GateLines.roofTarp, M8GateLines.roofTank, M8GateLines.roofNone,
        for (var i = 0; i < 6; i++) ...[M8GateLines.rodOn(i), M8GateLines.fuseOut(i)],
      ];
      for (var s = 0; s < 80; s++) {
        final d = dealM8G(math.Random(s));
        lines.add(M8GateLines.docketLine(d.regMin));
        lines.add(M8GateLines.clockLine(d.startMin));
        final r = _clean(d);
        for (final rec in r.records) {
          lines.add(rec.labelBn);
        }
        for (final n in r.caught) {
          lines.add(n);
        }
      }
      for (final l in lines) {
        expect(l, isNotEmpty);
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
      for (final l in lines) {
        expect(RegExp('মৃত(?!্যু)').hasMatch(l), isFalse, reason: 'ডেড, not মৃত: $l');
        expect(l, isNot(contains('এলটি')), reason: l);
        expect(l, isNot(contains('কেভি')), reason: l);
        expect(l, isNot(contains('কেভিএ')), reason: l);
        expect(l, isNot(contains('অফ ')), reason: 'OFF, not অফ: $l');
        expect(l, isNot(contains('অন ')), reason: 'ON, not অন: $l');
        expect(l, isNot(contains('AB বন্ধ')), reason: l);
        expect(l, isNot(contains('DO ')), reason: 'no DO fuse in Module 8: $l');
        expect([0x09DF, 0x09DC, 0x09DD].any((c) => l.contains(String.fromCharCode(c))), isFalse, reason: 'base + nukta: $l');
      }
    });

    test('lesson sources: every quoted lesson fact is in the live 8.x text; the coworker lines and every spoken line are listed', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List;
      String text(String id) {
        final c = lessons.firstWhere((x) => (x as Map)['id'] == id) as Map;
        return _nk(jsonEncode(c['content']));
      }

      final all = {for (final id in ['8.2', '8.3', '8.5', '8.6', '8.8', '8.9', '8.10']) id: text(id)};
      expect(all['8.10'], contains(_nk('লিখিত পারমিট হাতে না পাওয়া এবং নিজের হাতে আর্থিং না করা পর্যন্ত পোল-এ উঠবেন না')));
      expect(all['8.5'], contains(_nk('কাজের জায়গার আগে ও পরে (দুই প্রান্তে) অস্থায়ী আর্থিং বাধ্যতামূলক')));
      expect(all['8.8'], contains(_nk('পোল থেকে ওই বাড়ির ফিউজও খুলে দিন')));
      expect(all['8.8'], contains(_nk('সবুজ স্টিকার')));
      expect(all['8.3'], contains(_nk('এলটি তার ছিঁড়লে শহরে ৪ ঘন্টা')), reason: 'the live 8.3 limit the gate uses (4 h)');
      expect(kM8GLimitMin, 4 * 60);
      expect(all['8.6'], contains(_nk('কাজ শেষ করে অফিসে রিপোর্ট না করা পর্যন্ত ডকেট ক্লোজ হয় না')));
      expect(all['8.6'], contains(_nk('ভিডিও বা ছবি তুলে রাখুন')));
      expect(all['8.2'], contains(_nk('জব্দ তালিকা')));
      expect(all['8.2'], contains(_nk('২৪ ঘন্টার মধ্যে থানায়')));
      expect(all['8.2'], contains(_nk('প্রথম কাজ প্রমাণ জোগাড় করা')));
      expect(all['8.2'], contains(_nk('১৫ দিনের লিখিত নোটিশ')));
      expect(all['8.9'], contains(_nk('শাটডাউন নিয়ে ডাল কাটার সময়')));
      expect(all['8.9'], contains(_nk('পুরো গাছ')));
      expect(all['8.10'], contains(_nk('লেখা নেই = প্রমাণ নেই')));
      expect(all['8.10'], contains(_nk(M8GateLines.badge)), reason: 'the 8.x badge name');
      for (final m in M8GMistakes.values) {
        expect(m.lessonId, startsWith('8.'));
      }

      for (final cw in M8GateLines.coworkers) {
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: cw.exitLine);
        expect(M8GateLines.newRivalLines, contains(cw.line));
      }
      final unrecorded = [for (final cw in M8GateLines.coworkers) if (LearnVoice.resolve(cw.line, rival: true) == null) cw.line];
      // ignore: avoid_print
      print('M8 gate rival lines with no clip yet: ${unrecorded.length}\n${unrecorded.join('\n')}');
      // ignore: avoid_print
      print('M8 gate guide lines (all new, DRAFT):\n${M8GateLines.newGuideLines.join('\n')}');
      final guide = M8GateLines.newGuideLines;
      for (final l in [
        M8GateLines.intro, M8GateLines.hearIntro, ...M8GateLines.tasks, ...M8GateLines.tapWhy, M8GateLines.lit, M8GateLines.refused,
        M8GateLines.fixRight, M8GateLines.fail, M8GateLines.deadlyWord, M8GateLines.nearMissWord,
        M8GateLines.question(M8GReason.solar), M8GateLines.question(M8GReason.climb), M8GateLines.question(M8GReason.video), M8GateLines.question(M8GReason.docket),
        for (final cw in M8GateLines.coworkers) ...cw.asks,
        M8GateLines.promoted(M8GateLines.rankTo),
        for (final m in M8GMistakes.all) m.textBn,
      ]) {
        expect(guide, contains(l), reason: 'listed for the voice pass: $l');
      }
      // The silent figures' captions are never spoken (M8-10).
      for (final k in M8GQKind.values) {
        expect(guide, isNot(contains(M8GateLines.ask(k))));
      }
      expect(M8GateLines.badge, 'জরুরী রেগুলেশন (WBERC ফোকাস)');
      expect(M8GateLines.promoted('স্পেশালিস্ট'), contains(M8GateLines.badge));
      expect(M8GateLines.rankTo, 'স্পেশালিস্ট');
      expect(M8GateLines.pushPhone.line, contains('ফোনে লাইন OFF বলেছে, উঠে পড়'));
      expect(M8GateLines.pushReport.line, contains('রিপোর্ট-টিপোর্ট কাল হবে, চলো বাড়ি'));
    });

    test('the mistakes: unique keys, pictures, 8.x lesson points, the module table after the rulings', () {
      final keys = <String>{};
      for (final x in M8GMistakes.values) {
        expect(keys.add(x.m.key), isTrue, reason: x.m.key);
        expect(x.m.key, startsWith('m8/gate/'));
        expect(File(x.m.art).existsSync(), isTrue, reason: x.m.art);
        expect(x.m.lessonPoint, isNotNull);
        expect(x.lessonId, startsWith('8.'));
        expect(M8GMistakes.lessonOf(x.m), x.lessonId);
      }
      final deadly = {M8GMistakes.noPtw, M8GMistakes.noTester, M8GMistakes.noEarth, M8GMistakes.solarIn, M8GMistakes.rodLive, M8GMistakes.liveTrim};
      for (final x in M8GMistakes.values) {
        expect(x.m.deadly, deadly.contains(x), reason: x.m.key);
      }
      final used = {for (final x in M8GMistakes.values) x.m.art.split('/').last};
      final files = {for (final f in Directory('assets/game/art/m8_gate_case_file').listSync()) f.uri.pathSegments.last};
      expect(files, used, reason: 'every picture in the folder is used');
    });

    test('the lane: places never overlap, every place reachable by pan, the belt on screen (also mirrored)', () {
      for (final mirror in [false, true]) {
        for (final h in [560.0, 700.0, 900.0]) {
          final g = M8GGeo(h, 0, mirror: mirror);
          final all = M8GTgt.all;
          expect(all, hasLength(22));
          for (var i = 0; i < all.length; i++) {
            final r = g.world(all[i]);
            expect(r.width, greaterThanOrEqualTo(44), reason: '${all[i]}');
            expect(r.height, greaterThanOrEqualTo(44), reason: '${all[i]}');
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(M8GGeo.worldW));
            for (var j = i + 1; j < all.length; j++) {
              expect(r.overlaps(g.world(all[j])), isFalse, reason: '${all[i]} / ${all[j]} at $h mirror $mirror');
            }
            final s = g.at(all[i], g.panFor(all[i]));
            expect(s.center.dx, inInclusiveRange(0, 360), reason: '${all[i]} reachable');
            expect(g.pano.contains(Offset(s.center.dx.clamp(1, 359), s.center.dy)), isTrue, reason: '${all[i]} in the strip at $h');
          }
          // The van is in view on the opening pan.
          final v = g.at(M8GTgt.van, g.startPan);
          expect(v.center.dx, inInclusiveRange(0, 360));
          // Eleven tokens, none off screen, all alike, none overlapping.
          expect(g.tokens, hasLength(11));
          for (var i = 0; i < 11; i++) {
            final t = g.tok(i);
            expect(t.left, greaterThanOrEqualTo(0));
            expect(t.right, lessThanOrEqualTo(360));
            expect(t.bottom, lessThanOrEqualTo(g.h));
            expect(t.width, greaterThanOrEqualTo(44));
            expect(t.width, g.tok(0).width);
            expect(t.height, g.tok(0).height);
            for (var j = i + 1; j < 11; j++) {
              expect(t.overlaps(g.tok(j)), isFalse);
            }
          }
          expect(g.tokens.first.top, lessThan(g.tokens.last.top), reason: 'two rows');
          expect(g.home.bottom, lessThan(g.beltTop));
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

    testWidgets('the guide comes first: no start button, a tap does not skip', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final p = M8GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8GateCaseFilePage(ctx: _ctx, pack: _pack, muted: true, seed: 4, probe: p))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      expect(p.phase, 'intro');
      await t.tapAt(const Offset(200, 500));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      expect(p.phase, 'idle');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    for (final reduce in [false, true]) {
      testWidgets('idle on the lane draws zero frames (reduce motion: $reduce)', (t) async {
        if (reduce) {
          t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = M8GateProbe();
        final c = await _openPage(t, 7, p);
        expect(p.phase, 'idle');
        await _pump(t, 14000);
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(frames, lessThan(12), reason: 'idle lane');
        expect(t.takeException(), isNull);
        await _closePage(t, c);
      });
    }

    testWidgets('a full clean play: the phone, the coworker (M1) held and refused, PTW, tester, rods, solar ◆, hook ◆, climb ◆, paper, the hearing ◆ → rank-up', (t) async {
      final seed = _seedWhere((d) => d.c1 && d.phoneAt == 2 && d.solarCount == 1);
      final p = M8GateProbe();
      final c = await _openPage(t, seed, p);
      final d = p.deal!;
      final run = p.run!;
      // The pole video first: the phone speaks at 2 game minutes.
      await _use(t, p, M8GTok.camera, M8GTgt.wire(d.hookHouse));
      await _idle(t, p);
      expect(run.hookVideo, isTrue);
      expect(run.phoneUp, isTrue);
      expect(find.byKey(const ValueKey('phone')), findsOneWidget, reason: 'the phone says "line OFF"');
      // The next token: he comes first and the drop waits for him.
      await _use(t, p, M8GTok.permit, _van);
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he comes on the next touch');
      expect(run.permit, isFalse, reason: 'the permit drop waited for him');
      expect(find.text(M8GateLines.pushPhone.line), findsWidgets);
      await _pickDeckRight(t, p);
      await _pump(t, 1500);
      expect(run.ended, isFalse);
      expect(run.slips, 0);
      // Now the permit goes: the van leaves and returns.
      await _use(t, p, M8GTok.permit, _van);
      await _until(t, () => run.permit, maxMs: 3000);
      await _idle(t, p);
      await _use(t, p, M8GTok.tester, M8GTgt.pole(0));
      await _idle(t, p);
      expect(run.tested, isTrue);
      await _use(t, p, M8GTok.rod, M8GTgt.pole(0));
      await _idle(t, p);
      await _use(t, p, M8GTok.rod, M8GTgt.pole(3));
      await _idle(t, p);
      expect(run.bothEarths, isTrue);
      expect(run.slips, 0);
      // The solar house's fuse: ◆ and why.
      await _use(t, p, M8GTok.fuse, M8GTgt.house(d.solarHouses.single));
      await _until(t, () => p.busy, maxMs: 3000, reason: 'the solar fuse ◆');
      await _pickDeckRight(t, p);
      await _idle(t, p);
      if (d.c2) {
        await _use(t, p, M8GTok.trim, M8GTgt.branch(d.touching));
        await _idle(t, p);
        expect(run.branchCut, isTrue);
      }
      // The hook: video first, then the climb.
      await _use(t, p, M8GTok.hook, M8GTgt.wire(d.hookHouse));
      await _until(t, () => p.busy, maxMs: 4000, reason: 'the video ◆');
      await _pickDeckRight(t, p);
      await _idle(t, p);
      expect(run.hookRemoved, isTrue);
      await _use(t, p, M8GTok.climb, M8GTgt.pole(1));
      await _until(t, () => run.restored && p.busy, maxMs: 5000, reason: 'the climb ◆');
      await _pickDeckRight(t, p);
      await _idle(t, p);
      expect(run.repaired, isTrue);
      if (d.c3) {
        expect(find.byKey(const ValueKey('consumer')), findsOneWidget, reason: 'the silent consumer caption');
        await _use(t, p, M8GTok.camera, M8GTgt.house(d.c3House));
        await _idle(t, p);
      }
      await _use(t, p, M8GTok.seize, M8GTgt.house(d.hookHouse));
      await _idle(t, p);
      await _use(t, p, M8GTok.police, _van);
      await _idle(t, p);
      await _use(t, p, M8GTok.report, _van);
      await _idle(t, p);
      expect(run.reportedProper, isTrue);
      // ACT 2: home, then each question gets its record.
      await _tapKey(t, 'm8g-home');
      await _until(t, () => p.stage == 'hearing' && p.question != null, maxMs: 15000, reason: 'the bench');
      expect(p.questions.every((q) => !q.consequence), isTrue);
      var guard = 0;
      while (p.question != null && guard++ < 6) {
        final q = p.question!;
        final rec = run.records.firstWhere((r) => run.isRight(q.kind, r));
        final fan = find.descendant(of: find.byKey(const ValueKey('m8g-fan')), matching: find.byType(Scrollable));
        final card = find.byKey(ValueKey('m8g-rec-${rec.id}'));
        for (var i = 0; i < 20 && card.hitTestable().evaluate().isEmpty; i++) {
          await t.drag(fan.first, const Offset(-150, 0));
          await t.pump();
        }
        await _until(t, () => card.hitTestable().evaluate().isNotEmpty, maxMs: 3000, reason: 'the record card in view');
        await t.tap(card, warnIfMissed: false);
        await t.pump();
        await _pump(t, 200);
        expect(p.phase, 'hearLifted');
        await _tapKey(t, 'm8g-bench');
        await _until(t, () => p.busy, maxMs: 3000, reason: 'the record ◆');
        final asked = p.questions.indexOf(q);
        await _pickDeckRight(t, p);
        await _until(t, () => p.question != q || find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 5000);
        expect(asked, greaterThanOrEqualTo(0));
      }
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 10000);
      expect(find.text(M8GateLines.rankTo), findsOneWidget);
      expect(find.text(M8GateLines.badge), findsWidgets);
      expect(find.text(M8GateLines.caughtPush), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['m8/gate'], 'cleared');
      expect(save.rankIndex, 8, reason: 'সুপারভাইজার → স্পেশালিস্ট');
      expect(save.mistakes, isEmpty);
      expect(save.starsByRung['m8/gate'] ?? 0, greaterThanOrEqualTo(2));
      expect(run.slips, 0);
      // The pass panel waits quietly.
      await _pump(t, 14000);
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12), reason: 'idle on the pass panel');
      expect(t.takeException(), isNull);
      await _closePage(t, c);
    });

    testWidgets('a deadly move plays out: a rod before the permit freezes the lane, then the near-miss card', (t) async {
      final p = M8GateProbe();
      final c = await _openPage(t, 21, p);
      await _use(t, p, M8GTok.rod, M8GTgt.pole(0));
      await _until(t, () => p.phase == 'freeze', maxMs: 3000, reason: 'an earth on a live line');
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('harm')), findsOneWidget);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M8GMistakes.rodLive.m.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['m8/gate'], isNot('cleared'));
      await _closePage(t, c);
    });

    testWidgets('listening to M1 (the phone said line OFF) is deadly: the climb at once without the PTW', (t) async {
      final seed = _seedWhere((d) => d.phoneAt == 2);
      final p = M8GateProbe();
      final c = await _openPage(t, seed, p);
      await _use(t, p, M8GTok.camera, M8GTgt.pole(0));
      await _idle(t, p);
      await _use(t, p, M8GTok.permit, _van);
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he comes on the next touch');
      await _waitDeckUp(t);
      final wrong = [for (final x in M8GateLines.pushPhone.wrong) if (_label(x).evaluate().isNotEmpty) _label(x)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      await _until(t, () => p.phase == 'freeze', maxMs: 4000);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M8GMistakes.noPtw.m.textBn), findsOneWidget);
      await _closePage(t, c);
    });

    testWidgets('listening to M2 (report tomorrow) is a slip: the docket stays open, ACT 2 starts, no second slip for the docket', (t) async {
      final p = M8GateProbe();
      final c = await _openPage(t, 33, p);
      await _tapKey(t, 'm8g-home');
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he comes at the way home');
      expect(p.stage, 'field', reason: 'the way home waited for him');
      await _waitDeckUp(t);
      final wrong = [for (final x in M8GateLines.pushReport.wrong) if (_label(x).evaluate().isNotEmpty) _label(x)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M8GMistakes.listenReport.m.textBn), findsOneWidget);
      expect(p.run!.docketLeft, isTrue);
      await t.tap(find.text(MistakeLines.gotIt));
      await t.pump();
      await _until(t, () => p.stage == 'hearing', maxMs: 8000);
      await _until(t, () => p.phase == 'hear', maxMs: 8000);
      expect(p.run!.slips, 1);
      await _closePage(t, c);
    });

    testWidgets('three slips strike the gate out (a slip shows its card first)', (t) async {
      final p = M8GateProbe();
      final c = await _openPage(t, 14, p);
      for (var n = 1; n <= 3; n++) {
        await _use(t, p, M8GTok.trim, M8GTgt.trunk);
        if (n < 3) {
          await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
          expect(find.text(M8GMistakes.trimHarmless.m.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await t.pump();
          await _idle(t, p);
        }
      }
      await _until(t, () => find.byType(StruckOutCard).evaluate().isNotEmpty, maxMs: 4000);
      expect(p.run!.slips, 3);
      expect(c.read(gameSaveProvider).rungProgress['m8/gate'], isNot('cleared'));
      await _closePage(t, c);
    });

    testWidgets('a drop where the act cannot happen slides back with no cost; the lane pans by swipe; a roof hold shows the roof', (t) async {
      final p = M8GateProbe();
      final c = await _openPage(t, 11, p);
      final start = p.pan;
      await t.drag(find.byKey(const ValueKey('m8g-pano')), Offset(p.deal!.mirror ? 300 : -300, 0));
      await _pump(t, 200);
      expect((p.pan - start).abs(), greaterThan(100), reason: 'a swipe pans');
      await _use(t, p, M8GTok.trim, M8GTgt.house(0));
      await _idle(t, p);
      expect(p.run!.slips, 0);
      expect(p.run!.minutes, 0);
      expect(find.text(M8GateLines.nothingThere), findsOneWidget);
      // A long press on a house shows the roof (honest, from the deal).
      p.panTo(M8GTgt.house(1));
      await t.pump();
      await t.longPress(find.byKey(const ValueKey('m8g-tgt-house1')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.phase, 'roof');
      final art = p.deal!.houses[1].art;
      final want = art.panel
          ? M8GateLines.roofPanel
          : art.parapet
              ? M8GateLines.roofParapet
              : switch (art.deco) { 1 => M8GateLines.roofTarp, 2 => M8GateLines.roofTank, _ => M8GateLines.roofNone };
      expect(find.text(want), findsOneWidget);
      await _tapKey(t, 'm8g-roof-close');
      await _idle(t, p);
      expect(p.run!.slips, 0);
      await _closePage(t, c);
    });

    testWidgets('gesture hint on the lane: shown while it waits, pressing nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M8GateProbe();
      final c = await _openPage(t, 11, p);
      expect(p.phase, 'idle');
      await _pump(t, 9500);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget, reason: 'idle on the lane');
      expect(p.phase, 'idle', reason: 'a hint presses nothing');
      expect(p.run!.slips, 0);
      expect(p.run!.minutes, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _closePage(t, c);
    });
  });
}
