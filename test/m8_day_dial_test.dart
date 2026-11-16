// Lesson 8.7 (ট্যারিফ অর্ডার), কাজ "দিনভর নজর" (do_8_7_b, engine m8_day_dial):
// the rules (the stamps unlock only after the sun has passed all four parts
// of the day at every stop; the stamp of what runs is right, the card's
// category on a misuse and a needless note on an honest premises are slips;
// the factory's bracket: night right, evening a slip, morning / noon a free
// bounce; the PF advice deck; no deadly anywhere, ruling M8-1), the deal (four
// stops, the factory once at a dealt place, ≥ 1 honest and ≥ 1 misuse among
// the others, the misuse hour, the honest hours, the coworker's stop), what
// runs at each hour, the live lesson lines (X3), the libraries, every spoken
// line listed, the drawn places, and the level in the shell: the guide first,
// a full clean round (the sun dragged through each day, stamps, the bracket,
// the PF deck, reason picks, the coworker refused), a slip card that keeps
// the stop, 3 slips strike out (no freeze), listening = a slip, the sun waits
// for him, the praise window takes no touch, and the gesture hand shows how
// (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m8_day_dial.dart';
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
  rungId: '8.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8DayDialPacks['do_8_7_b']!;
typedef L = M8DayDialLines;
typedef Mk = M8DayDialMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('\u09dc', 'ড়').replaceAll('\u09dd', 'ঢ়').replaceAll('\u09df', 'য়');

/// Bengali digits → English (the lesson file writes ১২৬).
String _en(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  return s.split('').map((c) => bn.contains(c) ? '${bn.indexOf(c)}' : c).join();
}

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

/// The one of [texts] that is a card on the open deck.
String _cardOf(List<String> texts) {
  final on = [for (final x in texts) if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x];
  expect(on, hasLength(1), reason: texts.first);
  return on.single;
}

Future<void> _pickRight(WidgetTester t, List<String> right, {bool proceed = true}) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  await pickChoice(t, _cardOf(right), proceed: proceed);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M8DayGeo get _geo => M8DayGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8DayRun get _live => M8DayDialProbe.run!;
ValueNotifier<double> get _sun => M8DayDialProbe.sun!;

/// Drag the sun from sun-time [from] to [to] (a finger on the sun all along).
Future<void> _sunDrag(WidgetTester t, double from, double to, {int steps = 24}) async {
  final g = await t.startGesture(_geo.sunAt(from) * _k);
  for (var i = 1; i <= steps; i++) {
    await g.moveTo(_geo.sunAt(from + (to - from) * i / steps) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 200);
}

/// The whole day: dawn to midnight.
Future<void> _watchDay(WidgetTester t) => _sunDrag(t, _sun.value, 1.0);

/// Drag a stamp onto the line (its pin lands at [pin], design px).
Future<void> _dragStamp(WidgetTester t, M8DayUse u, {Offset? pin, bool settle = true}) async {
  final from = _geo.stamp(u.index).center;
  final to = (pin ?? _geo.slot.center).translate(0, M8DayGeo.lift);
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, settle ? 400 : 60);
}

/// Drag the factory's bracket from sun-time [from] to [to].
Future<void> _dragBracket(WidgetTester t, double from, double to) async {
  final g = await t.startGesture(_geo.bracketAt(from) * _k);
  for (var i = 1; i <= 12; i++) {
    await g.moveTo(_geo.sunAt(from + (to - from) * i / 12) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 500);
}

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8DayDialPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8DayDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8DayDeal(math.Random(s))));

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

M8DayWhy _whyOf(M8DayStop s) => switch (s.kind) {
      M8DayKind.fridgeHouse => M8DayWhy.fridge,
      M8DayKind.carPump => M8DayWhy.car,
      _ => M8DayWhy.stamp,
    };

/// One stop played clean: him refused on arrival (his stop), the day watched,
/// the stamp (or the bracket and the PF deck), the reasons, the next stop.
Future<void> _playStop(WidgetTester t) async {
  final i = _live.index;
  final s = _live.stop;
  if (i == _live.deal.coworkerStop) await _refuse(t);
  await _watchDay(t);
  expect(_live.unlocked, isTrue);
  if (s.factory) {
    await _dragBracket(t, m8DayMid(M8DayZone.evening), m8DayMid(M8DayZone.night));
    expect(_live.machine, M8DayZone.night);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the bracket reason');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[M8DayWhy.bracket]!);
    await _pump(t, 1500);
    if (s.pf) {
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the PF advice deck');
      await _pump(t, 500);
      await _pickRight(t, L.adviceRight, proceed: false);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue, reason: 'the capacitor reason');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8DayWhy.capbank]!);
      await _pump(t, 1500);
    }
  } else {
    await _dragStamp(t, s.truth!);
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      await _refuse(t);
      await _dragStamp(t, s.truth!);
    }
    expect(_live.stamped, s.truth);
    expect(find.byType(MistakeCard), findsNothing);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[_whyOf(s)]!);
    await _pump(t, 1500);
  }
  await _pump(t, 2600);
  expect(_live.index, i + 1);
}

M8DayStop _stopOf(M8DayKind k, {int variant = 0, M8DayZone? zone, bool pf = false}) => M8DayStop(kind: k, variant: variant, misuseZone: zone, pf: pf);

M8DayRun _runOf(M8DayStop first) => M8DayRun(M8DayDeal(
      stops: [first, _stopOf(M8DayKind.house), _stopOf(M8DayKind.shop), _stopOf(M8DayKind.factory)],
      coworkerStop: first.factory ? 1 : 0,
    ));

/// The day passed in one sweep (dawn to midnight).
void _day(M8DayRun r) => r.pass(0, 1);

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.7');
}

void main() {
  group('rules', () {
    test('deals: four stops, the factory once at a dealt place; ≥ 1 honest and ≥ 1 misuse; plays differ', () {
      final seen = <String>{};
      final kinds = <M8DayKind>{};
      final factoryAt = <int>{};
      final him = <int>{};
      final zones = <M8DayZone>{};
      final variants = <int>{};
      var pfYes = 0, pfNo = 0, mirrored = 0, bothMisuse = 0;
      for (var s = 0; s < 300; s++) {
        final d = m8DayDeal(math.Random(s));
        expect(d.stops, hasLength(4));
        expect(d.stops.where((x) => x.factory), hasLength(1));
        final others = d.stops.where((x) => !x.factory).toList();
        expect(others.map((x) => x.kind).toSet(), hasLength(3), reason: 'three different premises');
        expect(others.any((x) => !x.misuse), isTrue, reason: 'one honest at least');
        expect(others.any((x) => x.misuse), isTrue, reason: 'one misuse at least');
        if (others.where((x) => x.misuse).length == 2) bothMisuse++;
        expect(d.stops[d.coworkerStop].factory, isFalse, reason: 'his line fits a stop with a code to check');
        factoryAt.add(d.stops.indexWhere((x) => x.factory));
        him.add(d.coworkerStop);
        for (final st in d.stops) {
          kinds.add(st.kind);
          variants.add(st.variant);
          if (st.misuse) {
            expect(st.misuseZone, isNotNull);
            expect(st.misuseZone, isNot(M8DayZone.night), reason: 'the misuse runs in the day');
            zones.add(st.misuseZone!);
          } else {
            expect(st.misuseZone, isNull);
          }
          if (st.factory) st.pf ? pfYes++ : pfNo++;
          if (st.mirror) mirrored++;
          expect(st.card, st.factory ? isNull : isNotNull, reason: 'the factory shows no category card');
          expect(st.truth == st.card, !st.misuse);
        }
        seen.add('${d.coworkerStop}|${d.stops.map((x) => '${x.kind.index}${x.variant}${x.misuseZone?.index}${x.pf}${x.mirror}').join('|')}');
      }
      expect(seen.length, greaterThan(250));
      expect(kinds, M8DayKind.values.toSet());
      expect(factoryAt, {0, 1, 2, 3});
      expect(him.length, greaterThanOrEqualTo(3));
      expect(zones, {M8DayZone.morning, M8DayZone.noon, M8DayZone.evening});
      expect(variants, {0, 1, 2});
      expect(pfYes, inInclusiveRange(90, 210), reason: 'about half the plays show PF');
      expect(pfNo, inInclusiveRange(90, 210));
      expect(mirrored, inInclusiveRange(300, 900));
      expect(bothMisuse, greaterThan(10), reason: 'both misuse kinds in one play happens');
    });

    test('what runs: the misuse lives in one dealt hour; honest premises change by hour too; no ring, no tell in the card', () {
      for (var v = 0; v < 3; v++) {
        for (final z in M8DayZone.values) {
          // The honest house: never a shop, whatever the hour.
          final h = m8DayActs(_stopOf(M8DayKind.house, variant: v), z);
          expect(h, isNot(contains(M8DayAct.shopOpen)));
          expect(h, isNot(contains(M8DayAct.carWash)));
          expect(h.contains(M8DayAct.homeFridge), h.contains(M8DayAct.doorOpen) || false, reason: 'a home fridge shows only with the door open');
        }
        // The honest house varies by hour.
        expect({for (final z in M8DayZone.values) m8DayActs(_stopOf(M8DayKind.house, variant: v), z).join(',')}.length, greaterThan(2));
        // The fridge house: the shop only in its one hour.
        for (final mz in [M8DayZone.morning, M8DayZone.noon, M8DayZone.evening]) {
          final s = _stopOf(M8DayKind.fridgeHouse, variant: v, zone: mz);
          for (final z in M8DayZone.values) {
            final a = m8DayActs(s, z);
            expect(a.contains(M8DayAct.shopOpen), z == mz, reason: '$v $mz $z');
            expect(a.contains(M8DayAct.shopFridge), z == mz);
            if (z == mz) {
              expect(a, contains(M8DayAct.customer));
              expect(a, isNot(contains(M8DayAct.homeFridge)));
            }
          }
          // The car wash only in its one hour; the pump waters a field in another.
          final c = _stopOf(M8DayKind.carPump, variant: v, zone: mz);
          expect([for (final z in M8DayZone.values) if (m8DayActs(c, z).contains(M8DayAct.carWash)) z], [mz]);
          expect([for (final z in M8DayZone.values) if (m8DayActs(c, z).contains(M8DayAct.irrigate)) z], isNotEmpty, reason: 'the pump also does its own job');
          expect(m8DayActs(c, mz), isNot(contains(M8DayAct.irrigate)));
        }
        // The honest pump waters in 2 hours; the honest shop is shut at night.
        final p = _stopOf(M8DayKind.pump, variant: v);
        expect([for (final z in M8DayZone.values) if (m8DayActs(p, z).contains(M8DayAct.irrigate)) z], hasLength(2));
        final sh = _stopOf(M8DayKind.shop, variant: v);
        expect(m8DayActs(sh, M8DayZone.night), isEmpty);
        expect([for (final z in M8DayZone.values) if (m8DayActs(sh, z).contains(M8DayAct.shopFridge)) z].length, inInclusiveRange(2, 3));
      }
      // The factory's machine runs where it is put.
      final f = _stopOf(M8DayKind.factory);
      expect([for (final z in M8DayZone.values) if (m8DayActs(f, z).contains(M8DayAct.machine)) z], [M8DayZone.evening]);
      expect([for (final z in M8DayZone.values) if (m8DayActs(f, z, factoryRun: M8DayZone.night).contains(M8DayAct.machine)) z], [M8DayZone.night]);
    });

    test('the day: zones, the arc, the sky and the dusk', () {
      expect(m8DayZoneOf(0), M8DayZone.morning);
      expect(m8DayZoneOf(0.3), M8DayZone.noon);
      expect(m8DayZoneOf(0.6), M8DayZone.evening);
      expect(m8DayZoneOf(0.9), M8DayZone.night);
      expect(m8DayZoneOf(1.0), M8DayZone.night);
      // The zones tile 0..1 with no gap.
      for (var i = 0; i <= 1000; i++) {
        final z = m8DayZoneOf(i / 1000);
        final (lo, hi) = m8DayRange(z);
        expect(i / 1000, inInclusiveRange(lo, hi));
      }
      // Sun-time ↔ arc position round trip; the sun stands highest at noon.
      final g = M8DayGeo.forScene(780, 0);
      for (var i = 0; i <= 20; i++) {
        final t = i / 20;
        expect(g.tAtX(g.sunAt(t).dx), closeTo(t, 0.01), reason: '$t');
      }
      expect(g.sunAt(0.39).dy, lessThan(g.sunAt(0.1).dy));
      expect(g.sunAt(0.39).dy, lessThan(g.sunAt(0.7).dy));
      expect(g.sunAt(0).dy, closeTo(g.horizonY, 0.5));
      expect(g.sunAt(1).dy, closeTo(g.horizonY, 0.5));
      expect(g.tangentAt(0.2).dx, greaterThan(0), reason: 'forward is to the right');
      // Bright at noon, dark at midnight, dim at dawn.
      expect(m8DayDark(0.4), 0);
      expect(m8DayDark(1.0), greaterThan(0.6));
      expect(m8DayDark(0.0), greaterThan(0.2));
      expect(m8DayDark(0.9), greaterThan(m8DayDark(0.7)));
    });

    test('the unlock: only a sun that has passed all four parts of the day opens the stamps, at every stop', () {
      for (final k in M8DayKind.values) {
        final r = _runOf(_stopOf(k, zone: m8DayIsMisuse(k) ? M8DayZone.noon : null));
        expect(r.stage, M8DayStage.watch);
        // A stamp before the day is watched: nothing happens.
        expect(r.stamp(M8DayUse.commercial), (M8DayStamp.locked, null));
        expect(r.dropBracket(M8DayZone.night, moved: true), (M8DayBracket.notNow, null));
        expect(r.pass(0, 0.5), isFalse);
        expect(r.visited, {M8DayZone.morning, M8DayZone.noon});
        expect(r.pass(0.5, 0.4), isFalse, reason: 'back and forth');
        expect(r.unlocked, isFalse);
        expect(r.pass(0.6, 0.8), isTrue, reason: 'the last parts of the day');
        expect(r.unlocked, isTrue);
        expect(r.stage, k == M8DayKind.factory ? M8DayStage.bracket : M8DayStage.stamp);
      }
      // A flick across the whole day counts every part (nothing is skipped).
      final r = _runOf(_stopOf(M8DayKind.house));
      expect(r.pass(0, 1), isTrue);
      // The next stop starts locked again.
      r.stamp(M8DayUse.domestic);
      r.next();
      expect(r.stage, M8DayStage.watch);
      expect(r.visited, isEmpty);
      expect(r.unlocked, isFalse);
      expect(r.stamp(M8DayUse.domestic), (M8DayStamp.locked, null));
    });

    test('a stamp: what runs is right; the card on a misuse and any other on an honest premises are slips', () {
      // An honest house, shop, pump: the card's category is right.
      for (final (k, u) in [(M8DayKind.house, M8DayUse.domestic), (M8DayKind.shop, M8DayUse.commercial), (M8DayKind.pump, M8DayUse.agri)]) {
        final r = _runOf(_stopOf(k));
        _day(r);
        for (final other in M8DayUse.values.where((x) => x != u)) {
          expect(r.stamp(other), (M8DayStamp.slip, Mk.needless(k)));
          expect(r.stage, M8DayStage.stamp, reason: 'the stamp can be tried again');
        }
        expect(r.slips, 2);
        expect(r.stamp(u), (M8DayStamp.right, null));
        expect(r.remark, L.bookOk, reason: 'the stamp matches the card: reading noted');
        expect(r.stage, M8DayStage.finished);
        expect(r.caught.single, L.caughtStop(r.stop));
        expect(r.stamp(u), (M8DayStamp.locked, null), reason: 'done');
      }
      expect(Mk.needless(M8DayKind.house), Mk.needlessHouse);
      expect(Mk.needless(M8DayKind.shop), Mk.needlessShop);
      expect(Mk.needless(M8DayKind.pump), Mk.needlessPump);
      // The house with a shop fridge: domestic card, commercial runs.
      final f = _runOf(_stopOf(M8DayKind.fridgeHouse, zone: M8DayZone.noon));
      _day(f);
      expect(f.stamp(M8DayUse.domestic), (M8DayStamp.slip, Mk.missedFridge), reason: 'the card\'s category: the misuse missed');
      expect(f.stamp(M8DayUse.agri), (M8DayStamp.slip, Mk.missedFridge));
      expect(f.stamp(M8DayUse.commercial), (M8DayStamp.right, null));
      expect(f.remark, L.bookBad, reason: 'the book writes ক্যাটাগরি ভুল · Sec 126');
      expect(f.slips, 2);
      // The farm pump that washed a car.
      final c = _runOf(_stopOf(M8DayKind.carPump, zone: M8DayZone.evening));
      _day(c);
      expect(c.stamp(M8DayUse.agri), (M8DayStamp.slip, Mk.missedCar));
      expect(c.stamp(M8DayUse.commercial), (M8DayStamp.right, null));
      expect(c.remark, L.bookBad);
      expect(c.percent, 85);
    });

    test('the factory: bracket in the night is right; evening a slip; morning / noon bounce free; PF deck; a stamp does nothing here', () {
      final r = _runOf(_stopOf(M8DayKind.factory, pf: true));
      expect(r.stamp(M8DayUse.commercial), (M8DayStamp.locked, null));
      _day(r);
      expect(r.stage, M8DayStage.bracket);
      expect(r.stamp(M8DayUse.commercial), (M8DayStamp.locked, null), reason: 'no card, no stamp at the factory');
      expect(r.dropBracket(M8DayZone.night, moved: false), (M8DayBracket.notMoved, null));
      expect(r.dropBracket(M8DayZone.morning, moved: true), (M8DayBracket.bounced, null));
      expect(r.dropBracket(M8DayZone.noon, moved: true), (M8DayBracket.bounced, null));
      expect(r.slips, 0, reason: 'morning and noon cost nothing');
      expect(r.dropBracket(M8DayZone.evening, moved: true), (M8DayBracket.slip, Mk.bracketEvening));
      expect(r.slips, 1);
      expect(r.machine, M8DayZone.evening);
      expect(r.dropBracket(M8DayZone.night, moved: true), (M8DayBracket.right, null));
      expect(r.machine, M8DayZone.night);
      // PF on the bill: the advice deck follows.
      expect(r.stage, M8DayStage.advice);
      expect(r.advice(right: false), Mk.pfWrong);
      expect(r.slips, 2);
      expect(r.advice(right: true), isNull);
      expect(r.stage, M8DayStage.finished);
      expect(r.caught, [L.caughtStop(r.stop), L.caughtPf]);
      // No PF: the stop is done with the bracket.
      final q = _runOf(_stopOf(M8DayKind.factory));
      _day(q);
      expect(q.dropBracket(M8DayZone.night, moved: true), (M8DayBracket.right, null));
      expect(q.stage, M8DayStage.finished);
      expect(q.advice(right: false), isNull, reason: 'no deck without a PF penalty');
    });

    test('a round: 3 slips of 100 − 15 each, pass at 55; no deadly; listening = a slip (B1)', () {
      final r = M8DayRun(m8DayDeal(math.Random(5)));
      expect(r.percent, 100);
      expect(r.pushSlip(), Mk.pushListen);
      expect(r.slips, 1);
      expect(r.percent, 85);
      for (var i = 0; i < 2; i++) {
        r.pushSlip();
      }
      expect(r.percent, 55);
      // Finish: every stop done.
      for (var i = 0; i < 4; i++) {
        expect(r.done, isFalse);
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.passed, isTrue, reason: '55 passes');
      r.slips++;
      expect(r.passed, isFalse);
    });

    test('no deadly (M8-1): every mistake a slip; keys, pictures, lesson points; the art folder is all used', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.7/m8_day_dial/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(Mk.needlessHouse.lessonPoint, 2);
      expect(Mk.needlessShop.lessonPoint, 2);
      expect(Mk.missedFridge.lessonPoint, 2);
      expect(Mk.needlessPump.lessonPoint, 3);
      expect(Mk.missedCar.lessonPoint, 3);
      expect(Mk.pushListen.lessonPoint, 2);
      expect(Mk.bracketEvening.lessonPoint, isNull, reason: 'the TOD fact is in the advanced section');
      expect(Mk.pfWrong.lessonPoint, isNull, reason: 'the PF tip is the pro tip');
      const dir = 'assets/game/art/m8_day_dial/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8DayDialPacks.keys, ['do_8_7_b']);
    });

    test('the live lesson (X3): the rules, the categories, the peak and off-peak, the PF tip, the daily check', () {
      final lesson = _lesson();
      final text = _en(_nk(jsonEncode(lesson)));
      for (final q in [
        'একই মিটার থেকে বাড়িতে ফ্যান চালানো আর দোকানে ফ্রিজ চালানো',
        'ভুল ক্যাটাগরিতে বিদ্যুৎ ব্যবহার করলে সেকশন 126 অনুযায়ী জরিমানা হয়',
        'এই জল পাম্প দিয়ে যদি কেউ গাড়ি ধোয়ার গ্যারেজ চালায়, তবে তা বড় অপরাধ',
        'পিক আওয়ারে (সন্ধেবেলা) দাম বেশি',
        'অফ-পিক আওয়ারে (মাঝরাতে) দাম কম',
        'পাওয়ার ফ্যাক্টর (PF) কম হলে বিলে পেনাল্টি লাগে',
        'ক্যাপাসিটর ব্যাংক চেক করতে বলুন',
        "'Type of Consumer' কোড ঠিক আছে কি না",
        'বাড়ির রেট দোকানের রেটের চেয়ে কম',
        'সবচেয়ে কম রেট (ভর্তুকি যুক্ত)',
      ]) {
        expect(text, contains(_nk(q)), reason: q);
      }
      // The three stamps are the lesson's three categories.
      expect(text, contains(_nk('ডোমেস্টিক · কমার্শিয়াল · কৃষি')));
      expect([for (final u in M8DayUse.values) L.useName(u)], ['ডোমেস্টিক', 'কমার্শিয়াল', 'কৃষি']);
      expect(text, contains('Type of Consumer'));
      // The mistake cards quote the lesson's rule (point 3: "জল পাম্প … বড় অপরাধ").
      expect(_nk(Mk.missedFridge.textBn), contains('সেকশন 126 অনুযায়ী জরিমানা হয়'));
      expect(_nk(Mk.missedCar.textBn), contains('গাড়ি ধোয়ার গ্যারেজ'));
      expect(Mk.missedCar.textBn, contains('বড় অপরাধ'));
      expect(Mk.bracketEvening.textBn, contains('পিক আওয়ারে (সন্ধেবেলা) দাম বেশি'));
      expect(Mk.bracketEvening.textBn, contains('অফ-পিক আওয়ারে (মাঝরাতে) কম'));
      expect(Mk.pfWrong.textBn, contains('ক্যাপাসিটর ব্যাংক চেক করতে বলুন'));
      // The lesson's points: 2 = domestic vs commercial, 3 = agriculture.
      final points = [
        for (final s in (lesson['content'] as Map)['sections'] as List) ...(s as Map)['points'] as List,
      ];
      expect(points, hasLength(4));
      expect((points[2] as Map)['item_name'], contains('ডোমেস্টিক'));
      expect((points[3] as Map)['item_name'], contains('চাষের সংযোগ'));
      // No rupee rate, no slab figure, no PF number on screen (the lesson gives none).
      for (final l in [...L.spokenLines, L.billFixed, L.billEnergy, L.billPf]) {
        expect(RegExp(r'₹|টাকা|\d+\s?%|0\.\d').hasMatch(l), isFalse, reason: l);
      }
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, ON/OFF, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        ...L.watchTasks,
        ...L.stampTasks,
        ...L.billTasks,
        ...L.adviceTasks,
        ...L.tapWhy,
        ...L.whyQs,
        for (final w in M8DayWhy.values) ...[L.whyQ(w), ...L.whyWrong(w), ...L.whyRight[w]!],
        ...L.adviceRight,
        ...L.adviceWrong,
        for (final u in M8DayUse.values) ...[L.useName(u), L.stampLabel(u)],
        for (final k in M8DayKind.values) L.stopName(k),
        L.bookTitle,
        L.bookOk,
        L.bookBad,
        L.bracketLabel,
        L.ownerAsks,
        L.billFixed,
        L.billEnergy,
        L.billPf,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.caughtPf,
        L.caughtCall,
        for (final k in M8DayKind.values) L.caughtStop(_stopOf(k)),
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('মরা'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('(অন|অফ)(?![-\\wঀ-৿])').hasMatch(l.replaceAll('অফ-পিক', '')), isFalse, reason: 'ON/OFF in English letters: $l');
        expect(RegExp('[\u09dc\u09dd\u09df]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp('কেভি|এলটি|এইচটি').hasMatch(l), isFalse, reason: 'kV, LT, HT in English letters: $l');
      }
      expectSameLength('why', [...L.allWhyRight, ...L.allWhyWrong]);
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M8DayWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.whyWrong(w));
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.whyWrong(w), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('advice', [...L.adviceRight, ...L.adviceWrong]);
      expectLibrary('advice', L.adviceRight, L.adviceWrong);
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      expect(L.whyQs, hasLength(5), reason: 'the five reason questions of the spec');
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['কোড-টোড দেখার দরকার নেই, রিডিংটা লিখে চলো।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
        L.newGuideLines,
        containsAll([L.intro, ...L.watchTasks, ...L.stampTasks, ...L.billTasks, ...L.adviceTasks, ...L.whyQs, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]),
      );
      expect(L.reused, contains('ওকে কী বলবেন?'), reason: 'it already has a clip');
      expect(L.newGuideLines, isNot(contains('ওকে কী বলবেন?')));
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      // Every line the page speaks is in one of the lists (the owner's caption
      // and the bill are silent figures' words: not spoken, M8-10).
      final spoken = L.spokenLines.toSet();
      for (final l in [L.intro, ...L.watchTasks, ...L.stampTasks, ...L.billTasks, ...L.adviceTasks, ...L.tapWhy, L.callHeld, L.allSet, L.quick, L.fail, L.coworker.line, L.coworkerExit, ...L.coworker.asks, ...L.whyQs, for (final m in Mk.all) m.textBn]) {
        expect(spoken, contains(l), reason: l);
      }
      expect(spoken, isNot(contains(L.ownerAsks)));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_day_dial: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: card, bill and owner stay on the scene, clear of the guide; the book holds the line and the stamps', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M8DayGeo.forScene(h, inset);
          expect(g.book.bottom, lessThanOrEqualTo(h));
          expect(g.slot.overlaps(g.stamp(0)), isFalse);
          for (var i = 0; i < 3; i++) {
            expect(g.book.contains(g.stamp(i).topLeft) && g.book.contains(g.stamp(i).bottomRight - const Offset(1, 1)), isTrue);
            expect(g.stamp(i).contains(g.padGap), isFalse, reason: 'the lift hint never starts on one stamp');
            for (var j = i + 1; j < 3; j++) {
              expect(g.stamp(i).overlaps(g.stamp(j)), isFalse);
            }
          }
          expect(g.book.contains(g.slot.topLeft) && g.book.contains(g.slot.bottomRight - const Offset(1, 1)), isTrue);
          expect(g.onSlot(g.slot.center), isTrue);
          expect(g.onSlot(g.stamp(1).center), isFalse, reason: 'a stamp not moved is not on the line');
          for (final mirror in [false, true]) {
            for (final r in [g.card(mirror: mirror), g.billClip(mirror: mirror)]) {
              expect(r.isEmpty, isFalse);
              expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
              expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
              expect(r.top, greaterThan(140), reason: 'h $h: $r under the header');
              expect(r.overlaps(g.bubble), isFalse, reason: 'h $h: $r under the bubble');
              expect(r.overlaps(g.trainee), isFalse);
              expect(r.overlaps(g.book), isFalse);
            }
          }
          // The sun never stands on the book or the guide's corner.
          for (var i = 0; i <= 20; i++) {
            final o = g.sunAt(i / 20);
            expect(o.dy, lessThan(g.groundY), reason: 'h $h: the sun is in the sky');
            expect(o.dy, greaterThan(140), reason: 'h $h: the sun is under the header');
            expect(o.dx, inInclusiveRange(20, 340));
          }
        }
      }
      // Premises scale never grows past the screen.
      expect(M8DayGeo.forScene(900, 0).s, lessThanOrEqualTo(1.0));
      expect(M8DayGeo.forScene(560, 0).s, greaterThanOrEqualTo(0.55));
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

    testWidgets('the guide comes first: a tap does not skip him; then the sun, the three stamps (locked) and the book', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8DayDialPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
      for (final u in M8DayUse.values) {
        expect(label(L.stampLabel(u)), _live.stop.factory ? findsNothing : findsOneWidget);
      }
      expect(label(L.bookTitle), findsOneWidget);
      expect(find.text(L.bookTitle), findsOneWidget);
      expect(find.textContaining(L.cardHead), _live.stop.factory ? findsNothing : findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), _live.stop.factory ? findsNothing : findsNWidgets(3), reason: 'locked until the day is watched');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the stage\'s task pool in turn, never the answer', (t) async {
      final seed = _seedWhere((d) => !d.stops[0].factory && d.coworkerStop != 0);
      final c = await _open(t, seed);
      expect(c.read(guideDirectorProvider).line, contains(L.watch));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.watchTasks[1], L.watchTasks[2], L.watchTasks[0]]);
      for (final l in lines) {
        for (final u in M8DayUse.values) {
          expect(l, isNot(contains(L.useName(u))), reason: 'no category named: $l');
        }
      }
      await _close(t, c);
    });

    // A play with every kind of stop: one with the factory (PF) first, one with
    // a misuse stop first; his stop at the start and later.
    final flowSeeds = [
      _seedWhere((d) => d.stops[0].factory && d.stops[0].pf && d.coworkerStop == 1),
      _seedWhere((d) => d.stops[0].kind == M8DayKind.fridgeHouse && d.stops.any((s) => s.factory && !s.pf) && d.coworkerStop == 0),
      _seedWhere((d) => d.stops[3].factory && d.stops[3].pf && d.stops.any((s) => s.kind == M8DayKind.carPump) && d.coworkerStop == 2),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): four stops, the sun dragged through each day, stamps, the bracket, reasons, him refused → pass', (t) async {
        final c = await _open(t, seed);
        for (var i = 0; i < 4; i++) {
          await _playStop(t);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.7/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.7/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the stamps stay locked until the whole day is watched; half a day unlocks nothing; a locked stamp costs nothing', (t) async {
      final seed = _seedWhere((d) => !d.stops[0].factory && d.coworkerStop != 0);
      final c = await _open(t, seed);
      // To the evening only.
      await _sunDrag(t, 0, 0.6);
      expect(_live.unlocked, isFalse);
      expect(_live.stage, M8DayStage.watch);
      await _dragStamp(t, _live.stop.truth!);
      expect(_live.stamped, isNull);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      // The rest of the day (the finger lets go and takes the sun again).
      await _sunDrag(t, 0.6, 1.0);
      expect(_live.unlocked, isTrue);
      expect(_live.stage, M8DayStage.stamp);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.stampTasks.first));
      await _close(t, c);
    });

    testWidgets('the sky follows the sun: the dusk and the premises change with the hour; the sun is held where it is let go', (t) async {
      final seed = _seedWhere((d) => !d.stops[0].factory && d.coworkerStop != 0);
      final c = await _open(t, seed);
      expect(_sun.value, 0);
      await _sunDrag(t, 0, 0.39, steps: 10);
      expect(_sun.value, closeTo(0.39, 0.03));
      await _sunDrag(t, _sun.value, 0.85, steps: 10);
      expect(_sun.value, closeTo(0.85, 0.03));
      expect(m8DayZoneOf(_sun.value), M8DayZone.night);
      // Back and forth is allowed; it never costs.
      await _sunDrag(t, _sun.value, 0.2, steps: 10);
      expect(_sun.value, closeTo(0.2, 0.03));
      expect(_live.slips, 0);
      expect(_live.visited, hasLength(4), reason: 'every part passed');
      await _close(t, c);
    });

    final honestFirst = _seedWhere((d) => !d.stops[0].factory && !d.stops[0].misuse && d.coworkerStop != 0);
    testWidgets('a needless note on an honest premises is a slip with its card; the stop goes on; the right stamp then pays', (t) async {
      final c = await _open(t, honestFirst);
      final s = _live.stop;
      await _watchDay(t);
      final wrong = M8DayUse.values.firstWhere((u) => u != s.truth);
      // Off the line: the stamp springs back (no cost).
      await _dragStamp(t, wrong, pin: const Offset(180, 200));
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _dragStamp(t, wrong);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.needless(s.kind).textBn), findsOneWidget);
      expect(_live.stamped, isNull);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 0, reason: 'the same stop');
      await _dragStamp(t, s.truth!);
      expect(_live.stamped, s.truth);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.needless(s.kind).key]);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    final misuseFirst = _seedWhere((d) => d.stops[0].misuse && d.coworkerStop != 0);
    testWidgets('the card\'s category on a misuse stop is a slip; the stamp of what ran pays, the book writes ক্যাটাগরি ভুল · Sec 126', (t) async {
      final c = await _open(t, misuseFirst);
      final s = _live.stop;
      await _watchDay(t);
      await _dragStamp(t, s.card!);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.missed(s.kind).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _dragStamp(t, M8DayUse.commercial);
      expect(_live.stamped, M8DayUse.commercial);
      expect(find.text(L.bookBad), findsOneWidget);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.missed(s.kind).key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (needless notes); no freeze (nothing is deadly in 8.7)', (t) async {
      final c = await _open(t, honestFirst);
      final s = _live.stop;
      await _watchDay(t);
      final wrong = M8DayUse.values.firstWhere((u) => u != s.truth);
      for (var i = 0; i < 3; i++) {
        await _dragStamp(t, wrong);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.7');
      expect(c.read(gameSaveProvider).mistakes.every((m) => !m.deadly), isTrue);
      await _close(t, c);
    });

    final factoryFirstPf = _seedWhere((d) => d.stops[0].factory && d.stops[0].pf && d.coworkerStop != 0);
    testWidgets('the factory: the bracket slides back free in the morning and noon, a slip in the evening, right at night; the PF deck: a wrong card is a slip', (t) async {
      final c = await _open(t, factoryFirstPf);
      expect(find.text(L.billPf), findsOneWidget, reason: 'the bill shows the PF penalty');
      expect(find.textContaining(L.cardHead), findsNothing, reason: 'the factory shows no category card');
      await _watchDay(t);
      expect(_live.stage, M8DayStage.bracket);
      expect(find.text(L.ownerAsks), findsOneWidget);
      expect(find.text(L.bracketLabel), findsOneWidget);
      final mid = m8DayMid(M8DayZone.evening);
      // Morning and noon: no cost, it slides back to where it was.
      await _dragBracket(t, mid, m8DayMid(M8DayZone.morning));
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(M8DayDialProbe.bracket!.value, closeTo(mid, 0.001));
      await _dragBracket(t, mid, m8DayMid(M8DayZone.noon));
      expect(_live.slips, 0);
      // Dropped a little way in the evening: a slip with its card.
      await _dragBracket(t, mid, mid + 0.08);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.bracketEvening.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(M8DayDialProbe.bracket!.value, closeTo(mid, 0.001));
      // The night: right.
      await _dragBracket(t, mid, m8DayMid(M8DayZone.night));
      expect(_live.machine, M8DayZone.night);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8DayWhy.bracket]!);
      await _pump(t, 1500);
      // The PF deck: a wrong advice card is a slip.
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'PF advice deck');
      expect(_live.stage, M8DayStage.advice);
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = L.adviceWrong.firstWhere((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty);
      await pickChoice(t, wrong, proceed: false);
      await _pump(t, 600);
      expect(find.text(Mk.pfWrong.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(_live.stage, M8DayStage.advice, reason: 'the deck stays until the right card');
      await _pickRight(t, L.adviceRight, proceed: false);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8DayWhy.capbank]!);
      await _pump(t, 2600);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.bracketEvening.key, Mk.pfWrong.key]);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    final hisFirst = _seedWhere((d) => d.coworkerStop == 0);
    testWidgets('listening to him = a slip (no freeze); he comes on arrival and the first sun drag waits for him', (t) async {
      final c = await _open(t, hisFirst, settle: 0);
      // At once: a finger on the sun (he is due, not yet there) — he cuts in; the sun does not move.
      final g = await t.startGesture(_geo.sunAt(0) * _k);
      await g.moveTo(_geo.sunAt(0.1) * _k);
      await t.pump(const Duration(milliseconds: 50));
      await g.up();
      expect(_sun.value, 0, reason: 'the drag waited for him');
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = L.coworker.wrong.firstWhere((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty);
      await pickChoice(t, wrong, proceed: false);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushListen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushListen.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: the stop still needs the watch and the stamp.
      expect(_live.unlocked, isFalse);
      await _watchDay(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_live.unlocked, isTrue);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the next stop starts locked', (t) async {
      final seed = _seedWhere((d) => !d.stops[0].factory && d.coworkerStop >= 2);
      final c = await _open(t, seed);
      final s = _live.stop;
      await _watchDay(t);
      await _dragStamp(t, s.truth!);
      expect(_live.stamped, s.truth);
      // At once: a drag on the sun does nothing (shielded, then the deck).
      final before = _sun.value;
      await _sunDrag(t, before, 0.2, steps: 4);
      expect(_sun.value, before);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[_whyOf(s)]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(_live.stage, M8DayStage.watch);
      expect(_live.visited, isEmpty, reason: 'every stop starts locked');
      expect(_sun.value, 0, reason: 'a new day');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a nudge on the sun along the arc; at the stamps a sweep over the three alike; none while a card or the deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => !d.stops[0].factory && d.coworkerStop != 0);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the sun');
      expect(scene().debugOptions, isEmpty, reason: 'a drag nudge, not a sweep: it points at nothing');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a drag presses nothing');
      // A finger on the sun hides it at once.
      final g = await t.startGesture(_geo.sunAt(0) * _k);
      await _pump(t, 900);
      expect(scene().showing, isFalse);
      await g.up();
      await _pump(t, 300);
      // The day watched: the stamps — a sweep over all three, alike.
      await _watchDay(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the stamps');
      expect(scene().debugOptions, hasLength(3), reason: 'every stamp alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // A slip card: no hand over it.
      final wrong = M8DayUse.values.firstWhere((u) => u != _live.stop.truth);
      await _dragStamp(t, wrong);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 300);
      await _close(t, c);
    });
  });
}
