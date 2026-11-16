// Lesson 8.3 (SoP: সময়ের মূল্য), কাজ 1 "ঘড়ি টিক-টিক": the live limits, the
// deal (5 pins from 7 types: an urban fuse-off, yesterday's... today's rural
// item with most of its limit spent, a long-limit decoy, one delay event; the
// solver clears every deal with an hour of slack and first-come-first-served
// misses a limit), the rules (a limit passes before the docket closes → one
// slip per pin, the work-done-docket-open card; an unfinished docket bounces;
// the burnt DTR told to the JE / station manager; the storm's photos; the store
// delay; the shift's end), the libraries, every spoken line listed, the drawn
// places, and the level in the shell: the guide first, a docket that shows no
// limit, a full clean play (van drags, holds, swipes, a reason pick each time
// and the coworker refused), the two slips that cost a card, three slips, the
// coworker's fallback, the praise window, and the gesture hand.
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
import 'package:slm_flutter/features/game/m8_sop_clock.dart';
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
  rungId: '8.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 0,
  doCount: 2,
);

final _pack = m8SopClockPacks['do_8_3_a']!;
typedef L = M8SopClockLines;
typedef Mk = M8SopClockMistakes;

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

List<String> _textsOnScreen(List<String> texts) => [
      for (final x in texts)
        if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x,
    ];

/// A reason (or the coworker's deck): the one right card, ✓, then proceed.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _textsOnScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await pickChoice(t, r.single);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M8SopGeo get _geo => M8SopGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8SopRun get _live => M8SopClockProbe.run!;

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8SopClockPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// Drag [from] → [to] (design px) in small steps.
Future<void> _drag(WidgetTester t, Offset from, Offset to, {int settle = 300}) async {
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, settle);
}

Future<void> _tapAt(WidgetTester t, Offset design, {int settle = 300}) async {
  await t.tapAt(design * _k);
  await _pump(t, settle);
}

/// Hold at [design] for [ms], then let go.
Future<void> _hold(WidgetTester t, Offset design, int ms) async {
  final g = await t.startGesture(design * _k);
  await _pump(t, ms);
  await g.up();
  await t.pump();
}

M8SopDeal _deal(math.Random r) => m8SopDeal(r);

/// The docket push is his, and the second pin on the map is a plain repair
/// (not a DTR's phone call, not the storm).
bool _repairSecond(M8SopDeal d) => d.push == M8SopPush.docket && d.pins[1].kind != M8SopKind.dtr && d.pins[1].kind != M8SopKind.storm;

int _seedWhere(bool Function(M8SopDeal d) ok, {int from = 0}) => [for (var s = from; s < 4000; s++) s].firstWhere((s) => ok(_deal(math.Random(s))));

// --- a hand-made deal for the rules ------------------------------------------

M8SopPinDeal _pin(M8SopKind k, M8SopZone z, {double reg = 0, Offset at = const Offset(150, 200), int no = 10001}) => M8SopPinDeal(kind: k, zone: z, unit: at, regAt: reg, docketNo: no);

M8SopDeal _hand(List<M8SopPinDeal> pins, {M8SopEvent event = M8SopEvent.store, int month = 3, M8SopPush push = M8SopPush.docket}) => M8SopDeal(
      pins: pins,
      nearIdx: 0,
      event: event,
      push: push,
      month: month,
      day: 9,
      vanStart: kM8SopOffice,
      contactOrder: const [M8SopContact.callCentre, M8SopContact.je, M8SopContact.home, M8SopContact.manager],
    );

/// near (rural fuse), an urban fuse, a meter, a DTR, a town LT wire break.
M8SopDeal _standard({M8SopEvent event = M8SopEvent.store, int month = 3}) => _hand([
      _pin(M8SopKind.ruralFuse, M8SopZone.rural, reg: -200, at: const Offset(280, 100), no: 10001),
      _pin(M8SopKind.urbanFuse, M8SopZone.town, reg: -10, at: const Offset(60, 200), no: 10002),
      _pin(M8SopKind.meter, M8SopZone.town, reg: 25, at: const Offset(150, 120), no: 10003),
      _pin(event == M8SopEvent.store ? M8SopKind.dtr : M8SopKind.storm, M8SopZone.town, reg: 55, at: const Offset(90, 60), no: 10004),
      _pin(M8SopKind.wireBreak, M8SopZone.town, reg: 85, at: const Offset(120, 280), no: 10005),
    ], event: event, month: month);

/// Works pin [i] through the pure run: arrive, work, close.
void _doPin(M8SopRun r, int i, {bool close = true}) {
  expect(r.arrive(i), isTrue, reason: 'pin $i visible');
  expect(r.workDone(), isTrue);
  r.leave();
  if (close) expect(r.closeDocket(i), isNotNull);
}

/// A plan that clears the whole deal with no slip when played through the real
/// rules (visible pins only, photos before the storm's repair, the JE called):
/// the order of the required pins, or null.
List<int>? _plan(M8SopDeal d) {
  final req = M8SopSim.requiredIdx(d);
  List<int>? found;
  bool ok(List<int> order) {
    final r = M8SopRun(d);
    for (final i in order) {
      if (!r.visible(i)) return false;
      final p = d.pins[i];
      if (!r.arrive(i)) return false;
      if (p.kind == M8SopKind.dtr) {
        r.call(M8SopContact.je);
        if (d.event == M8SopEvent.store) r.storeAnswer(right: true);
        r.leave();
        continue;
      }
      if (p.kind == M8SopKind.storm) {
        r.photo(M8SopDamage.pole);
        r.photo(M8SopDamage.tree);
      }
      r.workDone();
      if (p.kind == M8SopKind.storm) r.stormAsk();
      r.leave();
      if (r.closeDocket(i) == null) return false;
      // The map skips to a call when nothing is left.
      r.idleSkip();
      r.takeDrops();
    }
    return r.lateQueue.isEmpty && r.slips == 0 && r.requiredDone;
  }

  void rec(List<int> left, List<int> order) {
    if (found != null) return;
    if (left.isEmpty) {
      if (ok(order)) found = order;
      return;
    }
    for (var k = 0; k < left.length; k++) {
      rec([...left]..removeAt(k), [...order, left[k]]);
    }
  }

  rec(req, const []);
  return found;
}

void main() {
  group('rules', () {
    test('the lesson limits (live text 2026-11-16)', () {
      double? lim(M8SopKind k, M8SopZone z, {bool m = false}) => m8SopLimit(k, z, monsoon: m);
      expect(lim(M8SopKind.urbanFuse, M8SopZone.town), 180, reason: 'শহর 3 ঘন্টা');
      expect(lim(M8SopKind.ruralFuse, M8SopZone.rural), 360, reason: 'গ্রাম 6 ঘন্টা');
      expect(lim(M8SopKind.ruralFuse, M8SopZone.rural, m: true), 480, reason: 'জুন–সেপ্টেম্বর 8 ঘন্টা');
      expect(lim(M8SopKind.wireBreak, M8SopZone.town), 240, reason: 'LT তার, শহরে 4 ঘন্টা');
      expect(lim(M8SopKind.wireBreak, M8SopZone.rural), 600, reason: 'গ্রামে 10 ঘন্টা');
      expect(lim(M8SopKind.wireBreak, M8SopZone.rural, m: true), 960, reason: 'বর্ষায় 16 ঘন্টা');
      expect(lim(M8SopKind.dtr, M8SopZone.town), 720);
      expect(lim(M8SopKind.dtr, M8SopZone.rural), 2880);
      expect(lim(M8SopKind.meter, M8SopZone.town), 7 * 1440, reason: '7 থেকে 15 দিন');
      expect(lim(M8SopKind.loose, M8SopZone.town), 15 * 1440, reason: 'লুজ কন্টাক্ট 15 দিন');
      expect(lim(M8SopKind.storm, M8SopZone.town), isNull, reason: 'force majeure with photos');
      expect([for (final m in [5, 6, 9, 10]) m8SopMonsoon(m)], [false, true, true, false]);
      expect([for (final k in M8SopKind.values) m8SopFailable(k)], [true, true, true, false, false, false, false]);
    });

    test('deals: 5 pins from 7 types, an urban fuse, today\'s rural near item, a decoy, one event; cleared with slack; first-come-first-served misses; plays differ', () {
      final seen = <String>{};
      final kinds = <M8SopKind>{};
      final events = <M8SopEvent>{};
      final pushes = <M8SopPush>{};
      var monsoon = 0, rural = 0, nearWire = 0;
      for (var s = 0; s < 150; s++) {
        final d = _deal(math.Random(s));
        expect(d.pins, hasLength(5));
        expect(d.pins.where((p) => p.kind == M8SopKind.urbanFuse), isNotEmpty);
        final near = d.pins[d.nearIdx];
        expect(near.zone, M8SopZone.rural);
        expect([M8SopKind.ruralFuse, M8SopKind.wireBreak], contains(near.kind));
        expect(near.regAt, lessThan(0), reason: 'registered earlier today');
        // Most of its limit spent: well under half of it left at 08:00.
        final left0 = near.regAt + d.limitOf(d.nearIdx)!;
        expect(left0 / d.limitOf(d.nearIdx)!, lessThan(0.45), reason: 'seed $s');
        expect(left0, greaterThan(100));
        expect(d.pins.where((p) => p.kind == M8SopKind.meter || p.kind == M8SopKind.loose), hasLength(1), reason: 'one long-limit decoy');
        expect(d.event == M8SopEvent.store ? d.dtrIdx : d.stormIdx, isNonNegative, reason: 'the event\'s pin is dealt');
        expect(d.pins.where((p) => p.kind == M8SopKind.dtr).length, lessThanOrEqualTo(1));
        expect(d.pins.where((p) => p.kind == M8SopKind.storm).length, d.event == M8SopEvent.storm ? 1 : 0);
        // Two on the map at the start, three drop at about 25, 55 and 85.
        expect(d.pins.take(2).every((p) => p.regAt <= 0), isTrue);
        final drops = d.pins.skip(2).map((p) => p.regAt).toList();
        expect(drops, orderedEquals([...drops]..sort()));
        for (final (i, want) in [25.0, 55.0, 85.0].indexed) {
          expect(drops[i], inInclusiveRange(want - 9, want + 9));
        }
        for (final p in d.pins) {
          expect(p.zone == M8SopZone.town ? p.unit.dx <= kM8SopTownEdge : p.unit.dx >= kM8SopTownEdge, isTrue);
          expect(p.unit.dx, inInclusiveRange(0, kM8SopMapW));
          expect(p.unit.dy, inInclusiveRange(20, kM8SopMapH - 20));
          kinds.add(p.kind);
          if (p.kind == M8SopKind.urbanFuse) expect(p.zone, M8SopZone.town);
          if (p.kind == M8SopKind.ruralFuse) expect(p.zone, M8SopZone.rural);
        }
        expect(d.pins.map((p) => p.docketNo).toSet(), hasLength(5));
        expect(d.contactOrder.toSet(), M8SopContact.values.toSet());
        expect(M8SopSim.bestSlack(d), greaterThanOrEqualTo(60), reason: 'seed $s clears in limit order with an hour to spare');
        expect(M8SopSim.fcfsMisses(d), greaterThanOrEqualTo(1), reason: 'seed $s: first-come-first-served misses a limit');
        events.add(d.event);
        pushes.add(d.push);
        if (d.monsoon) monsoon++;
        if (near.kind == M8SopKind.wireBreak) nearWire++;
        for (final p in d.pins) {
          if (p.zone == M8SopZone.rural) rural++;
        }
        seen.add([for (final p in d.pins) '${p.kind.index}${p.zone.index}${p.unit.dx.round()}${p.unit.dy.round()}${p.regAt.round()}'].join('|'));
      }
      expect(seen.length, greaterThan(145));
      expect(kinds, M8SopKind.values.toSet());
      expect(events, M8SopEvent.values.toSet());
      expect(pushes, M8SopPush.values.toSet());
      expect(monsoon, inInclusiveRange(30, 90), reason: 'the month decides the village limit');
      expect(nearWire, inInclusiveRange(15, 80));
      expect(rural, greaterThan(150));
    });

    test('a pin passes its limit (from registration) before its docket closes: one slip per pin, found when the clock crosses it', () {
      final r = M8SopRun(_standard());
      expect(r.slips, 0);
      r.advance(100);
      expect(r.lateQueue, isEmpty);
      // The rural near item (reg -200, March: 6 h): 160 left at 08:00.
      r.advance(65);
      expect(r.lateQueue, [Mk.lateRural]);
      expect(r.slips, 1);
      // The urban fuse (reg -10, 3 h): 170.
      r.advance(10);
      expect(r.lateQueue, [Mk.lateRural, Mk.lateUrban]);
      expect(r.slips, 2);
      r.advance(100);
      expect(r.lateQueue, hasLength(2), reason: 'once per pin');
      expect(r.slips, 2);
      expect(r.pins[0].late && r.pins[1].late, isTrue);
      // The decoy and the DTR never fail on time.
      r.advance(5000);
      expect(r.pins[2].late || r.pins[3].late, isFalse);
      // The LT wire break (reg 85, town 4 h) is the third.
      expect(r.lateQueue.last, Mk.lateWire);
      expect(r.slips, 3);
    });

    test('work done and the docket left open: a different card (the daily check); a late close counts no praise', () {
      final r = M8SopRun(_standard());
      expect(r.arrive(1), isTrue);
      expect(r.workDone(), isTrue);
      r.leave();
      r.advance(300);
      expect(r.lateQueue, contains(Mk.lateDocket));
      expect(r.pins[1].worked && !r.pins[1].closed, isTrue);
      final c = r.closeDocket(1)!;
      expect(c.inLimit, isFalse);
      expect(c.order, 0);
      // Late during the work itself: the kind's own card.
      final q = M8SopRun(_hand([_pin(M8SopKind.urbanFuse, M8SopZone.town, reg: -150, at: const Offset(50, 300))]));
      expect(q.arrive(0), isTrue);
      q.workDone();
      expect(q.lateQueue, [Mk.lateUrban]);
      expect(M8SopClockMistakes.late(M8SopKind.ruralFuse, workDone: false), Mk.lateRural);
      expect(M8SopClockMistakes.late(M8SopKind.wireBreak, workDone: false), Mk.lateWire);
      expect(M8SopClockMistakes.late(M8SopKind.wireBreak, workDone: true), Mk.lateDocket);
    });

    test('the van: the drive costs minutes by distance; the work, the call and the close', () {
      final r = M8SopRun(_standard());
      final far = r.travelMinutes(0);
      final near = r.travelMinutes(1);
      expect(far, greaterThan(near));
      expect(far, closeTo(m8SopDistance(kM8SopOffice, const Offset(280, 100)) * kM8SopMinPerUnit, 1e-9));
      expect(r.arrive(2), isFalse, reason: 'not dropped yet');
      expect(r.visible(2), isFalse);
      expect(r.arrive(1), isTrue);
      expect(r.now, closeTo(near, 1e-9));
      expect(r.at, 1);
      expect(r.closeDocket(1), isNull, reason: 'unfinished: the row bounces');
      expect(r.workDone(), isTrue);
      expect(r.now, closeTo(near + 25, 1e-9));
      expect(r.workDone(), isFalse, reason: 'once');
      // The pin that was visited stays open until its docket closes.
      expect(r.pins[1].closed, isFalse);
      final c = r.closeDocket(1)!;
      expect(c.inLimit, isTrue);
      expect(c.order, 1);
      expect(r.closeDocket(1), isNull, reason: 'already closed');
      expect(r.arrive(1), isFalse, reason: 'a closed pin is gone from the map');
      expect(r.caught.single, contains('10002'));
    });

    test('the first two dockets closed in their limit earn a reason, later ones none', () {
      final r = M8SopRun(_standard());
      _doPin(r, 1);
      _doPin(r, 0);
      expect(r.caught, hasLength(2));
      r.advance(30);
      r.takeDrops();
      _doPin(r, 2);
      expect(r.slips, 0);
      final third = M8SopRun(_standard());
      expect(third.arrive(1), isTrue);
      third.workDone();
      expect(third.closeDocket(1)!.order, 1);
      expect(third.arrive(0), isTrue);
      third.workDone();
      expect(third.closeDocket(0)!.order, 2);
      third.advance(40);
      expect(third.arrive(2), isTrue);
      third.workDone();
      expect(third.closeDocket(2)!.order, 0);
    });

    test('the burnt DTR: JE or the station manager at once; the call centre, home or "পরে করব" a slip; the store decision', () {
      final r = M8SopRun(_standard());
      r.advance(60);
      r.takeDrops();
      expect(r.arrive(3), isTrue);
      expect(r.canWork, isFalse, reason: 'a DTR is a phone call, not a repair here');
      expect(r.workDone(), isFalse);
      expect(r.call(M8SopContact.callCentre), Mk.dtrNoInform);
      expect(r.call(M8SopContact.home), Mk.dtrNoInform);
      expect(r.call(null), Mk.dtrNoInform);
      expect(r.slips, 3);
      expect(r.pins[3].informed, isFalse);
      final t0 = r.now;
      expect(r.call(M8SopContact.manager), isNull);
      expect(r.now, t0 + kM8SopCallMin);
      expect(r.pins[3].informed, isTrue);
      expect(r.call(M8SopContact.je), isNull, reason: 'told once');
      expect(r.done(r.pins[3]), isFalse, reason: 'the store delay is still to answer');
      expect(r.storeAnswer(right: false), Mk.storeSilent);
      expect(r.storeAnswer(right: true), isNull);
      expect(r.done(r.pins[3]), isTrue);
      expect(r.closeDocket(3), isNull, reason: 'its own work is beyond this shift');
      expect(r.caught, containsAll([L.caughtInformed('স্টেশন ম্যানেজার'), L.caughtStore]));
      // Without the store event the call is enough.
      final s = M8SopRun(_hand([
        _pin(M8SopKind.ruralFuse, M8SopZone.rural, reg: -200, at: const Offset(280, 100)),
        _pin(M8SopKind.dtr, M8SopZone.rural, reg: 0, at: const Offset(280, 200)),
      ], event: M8SopEvent.storm));
      expect(s.arrive(1), isTrue);
      s.call(M8SopContact.je);
      expect(s.done(s.pins[1]), isTrue);
    });

    test('the storm: photos of the pole and the tree before the repair; the JE asks afterwards', () {
      for (final shots in [<M8SopDamage>[], [M8SopDamage.pole], [M8SopDamage.pole, M8SopDamage.tree]]) {
        final r = M8SopRun(_standard(event: M8SopEvent.storm));
        r.advance(60);
        r.takeDrops();
        expect(r.arrive(3), isTrue);
        r.photo(null);
        for (final s in shots) {
          r.photo(s);
        }
        r.workDone();
        r.photo(M8SopDamage.tree);
        final before = r.slips;
        final m = r.stormAsk();
        if (shots.length == 2) {
          expect(m, isNull);
          expect(r.caught, contains(L.caughtPhotos));
          expect(r.slips, before);
        } else {
          expect(m, Mk.stormNoPhoto);
          expect(r.slips, before + 1);
        }
      }
      // Photos after the repair show nothing broken: they do not count.
      final late = M8SopRun(_standard(event: M8SopEvent.storm));
      late.advance(60);
      late.takeDrops();
      late.arrive(3);
      late.workDone();
      late.photo(M8SopDamage.pole);
      late.photo(M8SopDamage.tree);
      expect(late.stormAsk(), Mk.stormNoPhoto);
      // The storm pin never fails on time (force majeure with photos).
      expect(late.pins[3].deal.failable, isFalse);
    });

    test('the clock skips to the next call only when nothing is left; the shift ends with everything done or at 17:00', () {
      final r = M8SopRun(_hand([
        _pin(M8SopKind.ruralFuse, M8SopZone.rural, reg: -200, at: const Offset(280, 100)),
        _pin(M8SopKind.urbanFuse, M8SopZone.town, reg: 0, at: const Offset(60, 200)),
        _pin(M8SopKind.meter, M8SopZone.town, reg: 40, at: const Offset(150, 120)),
        _pin(M8SopKind.wireBreak, M8SopZone.town, reg: 200, at: const Offset(120, 280)),
      ]));
      expect(r.idleSkip(), isFalse, reason: 'two pins to do');
      _doPin(r, 0);
      _doPin(r, 1);
      expect(r.takeDrops(), [2]);
      expect(r.requiredDone, isFalse);
      // The visible meter is no required job, the wire break has not dropped.
      expect(r.idleSkip(), isTrue);
      expect(r.now, 200, reason: 'the clock skips to the next call');
      expect(r.takeDrops(), [3]);
      expect(r.idleSkip(), isFalse);
      _doPin(r, 3);
      expect(r.requiredDone, isTrue);
      expect(r.shiftOver, isTrue);
      r.finishShift();
      expect(r.shiftEnded, isTrue);
      expect(r.slips, 0);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught.where((c) => c.contains('মিটার')), isEmpty, reason: 'a meter never visited is not listed');
    });

    test('17:00 with a required docket still open is a slip each; a long-limit decoy left open costs nothing', () {
      final r = M8SopRun(_standard());
      expect(r.timeUp, isFalse);
      r.advance(kM8SopShiftEnd);
      expect(r.timeUp, isTrue);
      expect(r.shiftOver, isTrue);
      final before = r.slips;
      expect(before, 3, reason: 'the near item, the urban fuse and the wire break passed their limits');
      r.finishShift();
      expect(r.slips, before + 1, reason: 'the DTR was never told');
      expect(r.lateQueue.last, Mk.dtrNoInform);
      expect(r.shiftEnded, isTrue);
      expect(r.passed, isFalse);
      expect(r.percent, 40);
      final ok = M8SopRun(_standard());
      expect(ok.pins[2].deal.required, isFalse);
      expect(ok.done(ok.pins[2]), isTrue, reason: 'a decoy never keeps the shift open');
    });

    test('yesterday\'s rural item: the myth is due while it waits unvisited with under half its limit left', () {
      final r = M8SopRun(_standard());
      expect(r.remaining(0), 160);
      expect(r.ruralMythDue, isTrue);
      r.advance(10);
      expect(r.ruralMythDue, isTrue);
      expect(r.remaining(2), isNull, reason: 'a decoy has no failable limit');
      final v = M8SopRun(_standard());
      v.arrive(0);
      expect(v.ruralMythDue, isFalse, reason: 'visited');
      // The village's month: 8 h in the rains.
      final rain = M8SopRun(_standard(month: 7));
      expect(rain.remaining(0), 280);
      expect(rain.deal.monsoon, isTrue);
    });

    test('no deadly act (R7/R21: slips only); listening to him is a slip (X2/B1); three slips fail', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'the spec: do_8_3_a has no deadly');
      expect(Mk.push(M8SopPush.rural), Mk.pushRural);
      expect(Mk.push(M8SopPush.docket), Mk.pushDocket);
      final r = M8SopRun(_standard());
      r.pushSlip(Mk.pushRural);
      r.pushSlip(Mk.pushDocket);
      expect(r.percent, 70);
      r.pushSlip(Mk.pushDocket);
      expect(r.percent, 55);
      expect(r.shiftEnded, isFalse);
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.dropRing,
        L.docketBounce,
        L.jeStore,
        L.jeStormAsk,
        L.work,
        L.backMap,
        L.phoneTitle,
        L.later,
        for (final c in M8SopContact.values) L.contactName(c),
        for (final k in M8SopKind.values) L.kindName(k),
        for (final z in M8SopZone.values) L.docketArea(z),
        L.docketNo(48213),
        L.docketAt(9, 7, -200),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.storeRight,
        ...L.storeWrong,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8SopPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        for (final k in M8SopKind.values) L.limitLabel(k, M8SopZone.town, monsoon: false),
        for (final k in M8SopKind.values) L.limitLabel(k, M8SopZone.rural, monsoon: true),
        L.caughtDocket(10002, 'শহরে ফিউজ অফ: 3 ঘন্টা', -10, 120),
        L.caughtInformed('JE'),
        L.caughtOpen('মিটার: 7 থেকে 15 দিন'),
        L.caughtPhotos,
        L.caughtStore,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.replaceAll('কোম্পানি', '').contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        // The complaint's own name 'ফিউজ অফ' stays; no other অফ (OFF in English).
        expect(RegExp('অফ').allMatches(l.replaceAll('ফিউজ অফ', '')).isEmpty, isTrue, reason: 'OFF in English letters: $l');
        expect(RegExp('এলটি|এইচটি|কেভি|সুইচ অন').hasMatch(l), isFalse, reason: 'LT, HT, kV in English letters: $l');
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        // য় ড় ঢ় as base + nukta (the app's form).
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta form: $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.3/m8_sop_clock/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 5));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_sop_clock/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8SopClockPacks.keys, ['do_8_3_a']);
      // The lesson's own words in the cards.
      expect(Mk.lateUrban.textBn, contains('3 ঘন্টা'));
      expect(Mk.lateRural.textBn, allOf(contains('6 ঘন্টা'), contains('8 ঘন্টা')));
      expect(Mk.lateWire.textBn, allOf(contains('4 ঘন্টা'), contains('10 ঘন্টা'), contains('16 ঘন্টা')));
      expect(Mk.lateDocket.textBn, contains('ডকেট ক্লোজ'));
      expect(Mk.storeSilent.textBn, allOf(contains('LT জাম্পারিং'), contains('SMS')));
      expect(L.coworkerRural.line, 'গ্রামে কারেন্ট না থাকলে কেউ দেখার নেই, 24 ঘন্টা কোনো ব্যাপার না।', reason: 'the lesson\'s myth word for word (English digits)');
    });

    test('libraries: same length, big enough, never a rule marked wrong; the decks alike', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M8SopWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('store', [...L.storeRight, ...L.storeWrong]);
      expectLibrary('store', L.storeRight, L.storeWrong);
      expect(L.storeWrong, contains('গ্রাম তো, কেউ কেস করবে না — কিছু জানানোর দরকার নেই'));
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expect(L.coworkerRural.right, contains('না, গ্রামের গ্রাহকও কমপ্লেইন করে, WBERC নজর রাখে'), reason: 'the spec\'s refusal');
      expect(L.coworkerDocket.right, contains('না, আগে ডকেট ক্লোজ — নইলে খাতায় কাজটাই হয়নি'), reason: 'the spec\'s refusal');
      expect(L.coworkerRural.wrong, contains('ঠিক বলেছ, গ্রামেরটা পরে দেখলেই চলবে, আগে অন্যটা'));
      expect(L.coworkerDocket.wrong, contains('ঠিক আছে, সব শেষে একবারেই ডকেট ক্লোজ করব'));
      // The docket card and the rows read the same for every pin: no limit, no time left.
      final d = _deal(math.Random(3));
      for (var i = 0; i < d.pins.length; i++) {
        final txt = [L.docketNo(d.pins[i].docketNo), L.kindName(d.pins[i].kind), L.docketArea(d.pins[i].zone), L.docketAt(d.day, d.month, d.pins[i].regAt)].join(' ');
        expect(txt.contains('ঘন্টা'), isFalse, reason: txt);
        expect(txt.contains('বাকি'), isFalse, reason: txt);
      }
    });

    test('spoken lines: his exit is recorded; his two new pushes and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'গ্রামে কারেন্ট না থাকলে কেউ দেখার নেই, 24 ঘন্টা কোনো ব্যাপার না।',
        'ক্লোজ-টোজ পরে একসাথে করে দেব, আগে পরের কাজে চলো!',
      ]);
      expect({for (final p in M8SopPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            ...L.tapWhy,
            L.dropRing,
            L.docketBounce,
            L.jeStore,
            L.jeStormAsk,
            ...L.whyQ.values,
            for (final p in M8SopPush.values) L.callHeld(p),
            L.allSet,
            L.quick,
            L.fail,
            for (final cw in L.allCoworkers) ...cw.asks,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_sop_clock: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas: on the scene, below the header, above the toolbar, clear of the guide and of each other', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M8SopGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 84 - 116, 360, h - 84);
        final tools = <Rect>[g.phoneBtn, g.camBtn, g.workBtn, for (var i = 0; i < 5; i++) g.contact(i)];
        for (final r in tools) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(M8SopGeo.top), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThanOrEqualTo(h), reason: 'h $h: $r');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
        }
        expect(g.phoneBtn.overlaps(g.camBtn), isFalse);
        expect(g.camBtn.overlaps(g.workBtn), isFalse);
        for (var i = 0; i < 5; i++) {
          for (var j = i + 1; j < 5; j++) {
            expect(g.contact(i).overlaps(g.contact(j)), isFalse, reason: 'contacts $i/$j at $h');
          }
          expect(g.contact(i).bottom, lessThan(g.toolbarTop), reason: 'contacts above the toolbar at $h');
          expect(g.contact(i).width, greaterThanOrEqualTo(48));
          expect(g.contact(i).height, greaterThanOrEqualTo(44));
        }
        // The DTR close-up leaves a picture above its contacts.
        expect(g.closeup(dtr: true).height, greaterThan(120), reason: 'h $h');
        expect(g.closeup().height, greaterThan(150), reason: 'h $h');
        // The map: every pin's tap area inside the map, below the header, above the toolbar.
        expect(g.mapRect.top, greaterThanOrEqualTo(M8SopGeo.top));
        expect(g.mapRect.bottom, lessThan(g.toolbarTop));
        for (final u in [const Offset(18, 40), const Offset(196, 330), const Offset(238, 40), const Offset(304, 330), kM8SopOffice]) {
          final hit = g.pinHit(u);
          expect(hit.top, greaterThan(M8SopGeo.top - 40));
          expect(hit.width, greaterThanOrEqualTo(48));
          expect(hit.height, greaterThanOrEqualTo(48));
        }
        // The storm's two things to photograph are apart and inside the picture.
        final a = g.closeup();
        for (final dm in M8SopDamage.values) {
          expect(a.contains(g.damage(dm).topLeft) && a.contains(g.damage(dm).bottomRight - const Offset(1, 1)), isTrue, reason: '$dm at $h');
        }
        expect(g.damage(M8SopDamage.pole).overlaps(g.damage(M8SopDamage.tree)), isFalse);
        // The camera's hint tiles cover the picture.
        expect(g.tiles, hasLength(4));
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

    Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

    Offset pinAt(int i) => _geo.pinHit(_live.deal.pins[i].unit).center;
    Offset vanAt() => _geo.mapAt(_live.van);

    /// If he has come: refuse him (his deck is the live variant's).
    Future<bool> refuseIfHere(WidgetTester t, {int waitMs = 600}) async {
      if (!await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: waitMs)) return false;
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, L.coworker(M8SopClockProbe.push!).right);
      await _pump(t, 2600);
      return true;
    }

    /// Drag the van onto pin [i]; he may hold the drag (once), then drive on.
    Future<void> driveTo(WidgetTester t, int i) async {
      for (var k = 0; k < 3; k++) {
        await _drag(t, vanAt(), pinAt(i), settle: 200);
        if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          expect(await refuseIfHere(t), isTrue);
          continue;
        }
        await _pump(t, 1500);
        if (_live.at == i) return;
      }
      fail('the van did not arrive at pin $i');
    }

    Future<void> holdWork(WidgetTester t) async {
      expect(find.byKey(const ValueKey('work-pad')), findsOneWidget);
      await _hold(t, _geo.workBtn.center, 1700);
      await _pump(t, 1500);
    }

    Future<void> swipeRow(WidgetTester t, int i) async {
      for (var k = 0; k < 3; k++) {
        if (find.byKey(const ValueKey('phone-sheet')).evaluate().isEmpty) {
          await _tapAt(t, _geo.phoneBtn.center);
        }
        final row = find.byKey(ValueKey('docket-row-$i'));
        expect(row, findsOneWidget);
        await t.drag(row, const Offset(320, 0));
        await _pump(t, 500);
        if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          expect(await refuseIfHere(t), isTrue);
          continue;
        }
        return;
      }
      fail('docket $i did not close');
    }

    /// Plays [plan] right on screen; returns the number of dockets closed.
    Future<void> play(WidgetTester t, M8SopDeal d, List<int> plan) async {
      var closes = 0;
      for (final i in plan) {
        final p = d.pins[i];
        // Dropped by now? Pins appear as the clock passes their registration.
        expect(_live.visible(i), isTrue, reason: 'pin $i has dropped');
        await driveTo(t, i);
        expect(M8SopClockProbe.closeup, isTrue);
        if (p.kind == M8SopKind.dtr) {
          final slot = d.contactOrder.indexOf(M8SopContact.je);
          await _hold(t, _geo.contact(slot).center, 1400);
          await _pump(t, 500);
          expect(_live.pins[i].informed, isTrue);
          await _pickRight(t, L.whyRight[M8SopWhy.dtr]!);
          if (d.event == M8SopEvent.store) {
            expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the store deck');
            await _pump(t, 500);
            await pickChoice(t, _textsOnScreen(L.storeRight).single, proceed: false);
            await _pump(t, 600);
            await _pickRight(t, L.whyRight[M8SopWhy.store]!);
          }
          await _pump(t, 1500);
          expect(M8SopClockProbe.closeup, isFalse);
          continue;
        }
        if (p.kind == M8SopKind.storm) {
          await _tapAt(t, _geo.camBtn.center);
          expect(M8SopClockProbe.camera, isTrue);
          await _tapAt(t, _geo.damage(M8SopDamage.pole).center);
          await _tapAt(t, _geo.damage(M8SopDamage.tree).center);
          expect(_live.pins[i].shots, M8SopDamage.values.toSet());
          await _tapAt(t, _geo.camBtn.center);
        }
        await holdWork(t);
        if (p.kind == M8SopKind.storm) {
          expect(find.text(MistakeLines.slipHead), findsNothing);
          await _pickRight(t, L.whyRight[M8SopWhy.storm]!);
          await _pump(t, 1500);
        }
        expect(M8SopClockProbe.closeup, isFalse);
        expect(_live.pins[i].worked, isTrue);
        // After a repair he may come with the docket push.
        await refuseIfHere(t, waitMs: 3500);
        await swipeRow(t, i);
        expect(_live.pins[i].closed, isTrue);
        closes++;
        if (closes <= 2) {
          expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck for docket $closes');
          await _pump(t, 500);
          await _pickRight(t, L.whyRight[closes == 1 ? M8SopWhy.first : M8SopWhy.docket]!);
        }
        await _pump(t, 1500);
      }
    }

    testWidgets('the guide comes first: a tap does not skip him; then the map, its clock and its toolbar', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8SopClockPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 800);
      expect(label(L.mapLabel), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.byKey(const ValueKey('tool-phone')), findsOneWidget);
      expect(find.byKey(const ValueKey('tool-cam')), findsOneWidget);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
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
      expect(lines.every((l) => l.contains('ভ্যান')), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a tapped pin opens its docket: number, type, area, registered date and time — no limit, no time left; all pins alike', (t) async {
      final c = await _open(t, 11);
      final d = _live.deal;
      for (final i in [0, 1]) {
        await _tapAt(t, pinAt(i));
        expect(find.byKey(ValueKey('docket-card-$i')), findsOneWidget);
        final p = d.pins[i];
        expect(find.text(L.docketNo(p.docketNo)), findsOneWidget);
        expect(find.text(L.kindName(p.kind)), findsOneWidget);
        expect(find.text(L.docketArea(p.zone)), findsOneWidget);
        expect(find.text(L.docketAt(d.day, d.month, p.regAt)), findsOneWidget);
        expect(find.textContaining('ঘন্টা'), findsNothing);
        expect(find.textContaining('বাকি'), findsNothing);
        await t.tap(find.byKey(const ValueKey('docket-close')));
        await _pump(t, 300);
      }
      expect(find.byKey(const ValueKey('docket-card-0')), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(_live.now, 0, reason: 'a docket costs no time');
      await _close(t, c);
    });

    testWidgets('the phone lists the open dockets alike; an unfinished row bounces and costs nothing', (t) async {
      final c = await _open(t, 11);
      await _tapAt(t, _geo.phoneBtn.center);
      expect(find.byKey(const ValueKey('phone-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('docket-row-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('docket-row-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('docket-row-2')), findsNothing, reason: 'not dropped yet');
      await t.drag(find.byKey(const ValueKey('docket-row-1')), const Offset(320, 0));
      await _pump(t, 600);
      expect(_live.pins[1].closed, isFalse);
      expect(find.byKey(const ValueKey('docket-row-1')), findsOneWidget);
      expect(c.read(guideDirectorProvider).line, L.docketBounce);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await t.tap(find.byKey(const ValueKey('phone-close')));
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('phone-sheet')), findsNothing);
      await _close(t, c);
    });

    // Seeds whose deal has a clean plan; one per event / push combination.
    int cleanSeed({M8SopEvent? event, M8SopPush? push, int from = 0}) {
      for (var s = from; s < 4000; s++) {
        final d = _deal(math.Random(s));
        if (event != null && d.event != event) continue;
        if (push != null && d.push != push) continue;
        if (_plan(d) != null) return s;
      }
      fail('no seed');
    }

    for (final (event, push) in [
      (M8SopEvent.store, M8SopPush.rural),
      (M8SopEvent.storm, M8SopPush.docket),
      (M8SopEvent.store, M8SopPush.docket),
      (M8SopEvent.storm, M8SopPush.rural),
    ]) {
      final seed = cleanSeed(event: event, push: push, from: 3);
      testWidgets('flow (${event.name}, ${push.name} push, seed $seed): van, hold, swipe, a reason each, the coworker refused → pass', (t) async {
        final d = _deal(math.Random(seed));
        final plan = _plan(d)!;
        final c = await _open(t, seed);
        expect(M8SopClockProbe.push, push);
        await play(t, d, plan);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.3/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.3/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget, reason: 'he was refused once');
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(_live.slips, 0);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final lateSeed = _seedWhere((d) => {for (final p in d.pins) if (p.failable) Mk.late(p.kind, workDone: false).key}.length >= 3);
    testWidgets('a limit passes: its card, one slip per pin; the clock moved by the drive; three slips strike the level out', (t) async {
      final c = await _open(t, lateSeed);
      // A long way later: every limit the game fails on has passed.
      _live.advance(1200);
      expect(_live.lateQueue.length, greaterThanOrEqualTo(3));
      final keys = _live.lateQueue.map((m) => m.key).toList();
      final mistakes = List.of(_live.lateQueue);
      // The map at rest settles it as soon as the player moves (a drive).
      await _drag(t, vanAt(), pinAt(1), settle: 1800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(mistakes.first.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(find.byType(MistakeCard), findsOneWidget, reason: 'the second pin that passed its limit');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget, reason: 'the third slip');
      final saved = c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet();
      expect(saved, keys.take(3).toSet());
      expect(saved.length, 3, reason: 'a card per pin');
      await _close(t, c);
    });

    testWidgets('the work button needs a hold: a tap does nothing, a half hold cancels, a full hold lights the houses; the pin stays on the map until its docket closes', (t) async {
      final seed = _seedWhere(_repairSecond);
      final c = await _open(t, seed);
      await driveTo(t, 1);
      expect(_live.pins[1].worked, isFalse);
      await _tapAt(t, _geo.workBtn.center);
      expect(_live.pins[1].worked, isFalse, reason: 'a tap is not a hold');
      final g = await t.startGesture(_geo.workBtn.center * _k);
      await _pump(t, 500);
      final mid = _live.now;
      await g.up();
      await _pump(t, 300);
      expect(_live.pins[1].worked, isFalse, reason: 'a half hold cancels');
      expect(_live.now, mid, reason: 'the clock only moves when the work is done');
      await _hold(t, _geo.workBtn.center, 1700);
      expect(_live.pins[1].worked, isTrue);
      await _pump(t, 1500);
      expect(M8SopClockProbe.closeup, isFalse);
      expect(_live.pins[1].closed, isFalse, reason: 'the docket is still open: the pin stays');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; then the next', (t) async {
      final seed = _seedWhere(_repairSecond);
      final c = await _open(t, seed);
      await driveTo(t, 1);
      await holdWork(t);
      await refuseIfHere(t, waitMs: 3500);
      await swipeRow(t, 1);
      // The ◆ on the table, the deck open at once: the scene and the toolbar take nothing.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(60, 128));
        await t.pump(const Duration(milliseconds: 150));
        // The map above the deck: no docket card opens.
        await t.tapAt(const Offset(180, 300) * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.textContaining('কমপ্লেইন নং'), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8SopWhy.first]!);
      await _pump(t, 1800);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final dtrSeed = _seedWhere((d) => d.event == M8SopEvent.store && d.push == M8SopPush.docket && d.dtrIdx < 2);
    testWidgets('DTR: contacts are hold targets; the call centre and "পরে করব" are slips and the phone stays; the JE ends it', (t) async {
      final d = _deal(math.Random(dtrSeed));
      final c = await _open(t, dtrSeed);
      await driveTo(t, d.dtrIdx);
      expect(find.byKey(const ValueKey('contact-0')), findsOneWidget);
      expect(find.text(L.later), findsOneWidget);
      // A tap on a contact is not a call.
      await _tapAt(t, _geo.contact(0).center);
      expect(_live.slips, 0);
      final wrong = d.contactOrder.indexOf(M8SopContact.callCentre);
      await _hold(t, _geo.contact(wrong).center, 1400);
      await _pump(t, 600);
      expect(find.text(Mk.dtrNoInform.textBn), findsOneWidget);
      expect(_live.pins[d.dtrIdx].informed, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _hold(t, _geo.contact(4).center, 1400);
      await _pump(t, 600);
      expect(find.text(Mk.dtrNoInform.textBn), findsOneWidget, reason: '"পরে করব" is not telling the JE');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.dtrNoInform.key});
      // A half hold does not call.
      final je = d.contactOrder.indexOf(M8SopContact.je);
      final half = await t.startGesture(_geo.contact(je).center * _k);
      await _pump(t, 400);
      await half.up();
      await _pump(t, 300);
      expect(_live.pins[d.dtrIdx].informed, isFalse);
      await _hold(t, _geo.contact(je).center, 1400);
      await _pump(t, 500);
      expect(_live.pins[d.dtrIdx].informed, isTrue);
      await _pickRight(t, L.whyRight[M8SopWhy.dtr]!);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the JE: the store delay');
      await waitChoiceDeck(t);
      await pickChoice(t, _textsOnScreen(L.storeRight).single, proceed: false);
      await _pump(t, 700);
      await _pickRight(t, L.whyRight[M8SopWhy.store]!);
      await _pump(t, 1800);
      expect(_live.storeDone, isTrue);
      expect(M8SopClockProbe.closeup, isFalse);
      expect(_live.slips, 2);
      await _close(t, c);
    });

    testWidgets('the store delay: waiting silently or "কেউ কেস করবে না" is a slip and the deck stays; the right card then pays', (t) async {
      final d = _deal(math.Random(dtrSeed));
      final c = await _open(t, dtrSeed);
      await driveTo(t, d.dtrIdx);
      await _hold(t, _geo.contact(d.contactOrder.indexOf(M8SopContact.manager)).center, 1400);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8SopWhy.dtr]!);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await waitChoiceDeck(t);
      final wrongCard = _textsOnScreen(L.storeWrong);
      expect(wrongCard, isNotEmpty);
      await pickChoice(t, wrongCard.first, proceed: false);
      await _pump(t, 700);
      expect(find.text(Mk.storeSilent.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.storeSilent.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(_live.storeDone, isFalse);
      await waitChoiceDeck(t);
      await pickChoice(t, _textsOnScreen(L.storeRight).single, proceed: false);
      await _pump(t, 700);
      await _pickRight(t, L.whyRight[M8SopWhy.store]!);
      await _pump(t, 1800);
      expect(_live.storeDone, isTrue);
      expect(_live.slips, 1);
      await _close(t, c);
    });

    final stormSeed = _seedWhere((d) => d.event == M8SopEvent.storm && d.push == M8SopPush.docket && d.stormIdx < 2);
    testWidgets('the storm: the camera is in the toolbar everywhere; no photos → the JE asks and it is a slip; the photos count only before the repair', (t) async {
      final d = _deal(math.Random(stormSeed));
      final c = await _open(t, stormSeed);
      // The camera is up on the map as well: a shot there does nothing.
      await _tapAt(t, _geo.camBtn.center);
      expect(M8SopClockProbe.camera, isTrue);
      await _tapAt(t, const Offset(180, 300));
      await _tapAt(t, _geo.camBtn.center);
      expect(M8SopClockProbe.camera, isFalse);
      await driveTo(t, d.stormIdx);
      await holdWork(t);
      expect(find.text(Mk.stormNoPhoto.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.stormNoPhoto.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(M8SopClockProbe.closeup, isFalse, reason: 'back on the map after the card');
      await _close(t, c);
    });

    testWidgets('listening to the coworker is a slip and goes on; the myth falls back to the docket push when the rural item is visited first', (t) async {
      final seed = _seedWhere((d) => d.push == M8SopPush.rural);
      final d = _deal(math.Random(seed));
      final c = await _open(t, seed);
      expect(M8SopClockProbe.push, M8SopPush.rural);
      // Straight to yesterday's rural item: the myth has nothing to push.
      await _drag(t, vanAt(), pinAt(d.nearIdx), settle: 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_live.at, d.nearIdx);
      await holdWork(t);
      expect(M8SopClockProbe.push, M8SopPush.docket, reason: 'the fallback: the docket push on this finished repair');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he always comes');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworkerDocket.wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 900);
      expect(find.text(Mk.pushDocket.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.pushDocket.key});
      await _close(t, c);
    });

    testWidgets('the rural myth holds the van drag; the swipe and the van wait for the docket push', (t) async {
      final seed = _seedWhere((d) => d.push == M8SopPush.rural);
      final d = _deal(math.Random(seed));
      final c = await _open(t, seed);
      // A pin that is not yesterday's rural item.
      final other = [for (var i = 0; i < 2; i++) if (i != d.nearIdx) i].first;
      await _drag(t, vanAt(), pinAt(other), settle: 200);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the van drag is held for him');
      expect(_live.at, isNull, reason: 'the van did not move');
      expect(_live.now, 0);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      await pickChoice(t, _textsOnScreen(L.coworkerRural.right).first, proceed: false);
      await _pump(t, 2800);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _drag(t, vanAt(), pinAt(other), settle: 1600);
      expect(_live.at, other, reason: 'after him the van goes');
      await _close(t, c);
    });

    testWidgets('gesture hand: idle on the map shows a hand that presses nothing; a hold ring on the work button; any touch hides it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere(_repairSecond);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the map');
      await _tapAt(t, const Offset(300, 420));
      expect(scene().showing, isFalse);
      await driveTo(t, 1);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the work button');
      await _tapAt(t, const Offset(200, 220));
      expect(scene().showing, isFalse);
      await _hold(t, _geo.workBtn.center, 1700);
      await _pump(t, 1500);
      await refuseIfHere(t, waitMs: 3500);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'a finished repair: a sweep over the phone and the van');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
