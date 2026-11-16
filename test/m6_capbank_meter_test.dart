// Lesson 6.7 (ক্যাপাসিটর ব্যাংক), কাজ 2 "মিটারে ব্যাংকের নাড়ি": the rules (the
// pencil keeps a mark only near the needle and a misread costs nothing; ON
// once, the needles swing, the after-readings; a sound bank stays ON, a weak
// one OFF + tag; a blown fuse tagged, never refitted; a swollen can never in
// service; a sound bank tagged, a bank tagged unmeasured, a re-switch, a weak
// or blown bank left ON = slips), the deal, the libraries, the coworker's
// pushes (listening = the act he pushes: the swollen-can press is deadly),
// the drawn places, and the level in the shell: the guide first, the yard
// zoom, a full clean play (the pencil dragged, a reason pick each bank, the
// coworker refused), three slips, the deadly freeze, his bank's controls wait
// for him on a fast play, and the gesture hand while the level waits.
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
import 'package:slm_flutter/features/game/m6_capbank_meter.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '6.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6CapbankMeterPacks['do_6_7_b']!;
typedef L = M6CapbankMeterLines;
typedef Mk = M6CapbankMeterMistakes;

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
M6CbmGeo get _geo => M6CbmGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M6CbmRun get _live => M6CapbankMeterProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design, {int ms = 300}) async {
  await t.tapAt(design * _k);
  await _pump(t, ms);
}

Future<void> _toPanel(WidgetTester t) async {
  await t.tap(_label(L.toPanel));
  await _pump(t, 400);
  expect(_label(L.sign), findsOneWidget, reason: 'on the panel');
}

/// The pencil dragged from its rest to where [m]'s needle stands now.
Future<void> _logDrag(WidgetTester t, M6CbmMeter m) async {
  final g = _geo;
  final from = g.pencilRest * _k;
  final to = Offset(g.stripXOf(m, _live.value(m)), g.strip(m).center.dy) * _k;
  final gesture = await t.startGesture(from);
  for (var i = 1; i <= 10; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _pump(t, 300);
}

/// A tap on [m]'s strip at [v] (the true reading when null).
Future<void> _logTap(WidgetTester t, M6CbmMeter m, [double? v]) =>
    _tapAt(t, Offset(_geo.stripXOf(m, v ?? _live.value(m)), _geo.strip(m).center.dy));

Future<void> _lever(WidgetTester t) async {
  await _tapAt(t, _geo.leverHit(_live.index).center, ms: 200);
  await _pump(t, 1800); // the swing
}

Future<void> _tag(WidgetTester t) => _tapAt(t, _geo.tagHit(_live.index).center);

Future<void> _sign(WidgetTester t) async {
  await t.tap(_label(L.sign));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6CapbankMeterPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6CbmDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m6CbmDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t, M6CbmPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
  expect(find.byType(CoworkerPeek), findsNothing);
}

/// One bank played right (the coworker refused if he is dealt on it).
Future<void> _playBank(WidgetTester t, M6CbmDeal d, int i, {bool drag = false}) async {
  final b = d.banks[i];
  final his = d.coworkerBank == i;
  Future<void> log(M6CbmMeter m) => drag ? _logDrag(t, m) : _logTap(t, m);
  switch (b.state) {
    case M6CbmState.healthy || M6CbmState.weak:
      await log(M6CbmMeter.amps);
      await log(M6CbmMeter.pf);
      expect(_live.beforeDone, isTrue, reason: 'bank $i: both marks kept');
      await _lever(t);
      expect(_live.on[i], isTrue);
      expect(_live.needAfter, isTrue);
      await log(M6CbmMeter.amps);
      await log(M6CbmMeter.pf);
      expect(_live.afterDone, isTrue);
      if (his) await _refuse(t, d.push);
      if (b.state == M6CbmState.weak) {
        await _lever(t);
        expect(_live.on[i], isFalse);
        await _tag(t);
        expect(_live.tagged[i], isTrue);
      }
    case M6CbmState.blown || M6CbmState.swollen:
      if (his) await _refuse(t, d.push);
      if (b.inService) await _lever(t);
      expect(_live.on[i], isFalse);
      await _tag(t);
      expect(_live.tagged[i], isTrue);
  }
  final why = _live.why;
  await _sign(t);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${b.state}');
  expect(_live.roundDone, isTrue, reason: 'bank $i (${b.state}) signed');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${b.state})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[why]!);
  await _pump(t, 3000);
}

M6CbmBank _bank(M6CbmState s, {bool inService = false}) {
  final (lo, hi) = m6CbmReliefRange(s);
  return M6CbmBank(state: s, defect: 1, relief: (lo + hi) / 2, inService: inService);
}

/// A run whose banks are [states] (the coworker on the third).
M6CbmRun _runOf(List<M6CbmState> states, {bool swollenOn = false, List<M6CbmWhy>? why}) => M6CbmRun(M6CbmDeal(
      banks: [for (final s in states) _bank(s, inService: swollenOn && s == M6CbmState.swollen)],
      amps0: 280,
      pf0: 0.8,
      sky: M6CbmSky.dusk,
      coworkerBank: 2,
      why: why ??
          [
            for (final s in states)
              switch (s) {
                M6CbmState.healthy => M6CbmWhy.keepOn,
                M6CbmState.weak => M6CbmWhy.tagOff,
                M6CbmState.blown => M6CbmWhy.noRefit,
                M6CbmState.swollen => M6CbmWhy.swollen,
              },
          ],
    ));

void _logBoth(M6CbmRun r) {
  for (final m in M6CbmMeter.values) {
    expect(r.log(m, r.value(m)), isTrue, reason: '$m');
  }
}

void main() {
  group('rules', () {
    test('deals: at most one swollen, at least one sound, never three sound; reliefs by state; his push fits his bank; plays differ', () {
      final seen = <String>{};
      final pushes = <M6CbmPush>{};
      final whys = <M6CbmWhy>{};
      final skies = <M6CbmSky>{};
      final hisBank = <int>{};
      var inService = 0, swollenDeals = 0;
      for (var s = 0; s < 300; s++) {
        final d = m6CbmDeal(math.Random(s));
        final states = [for (final b in d.banks) b.state];
        expect(d.banks, hasLength(3));
        expect(states.where((x) => x == M6CbmState.swollen).length, lessThanOrEqualTo(1));
        expect(states, contains(M6CbmState.healthy));
        expect(states.every((x) => x == M6CbmState.healthy), isFalse);
        for (final (i, b) in d.banks.indexed) {
          final (lo, hi) = m6CbmReliefRange(b.state);
          expect(b.relief, inInclusiveRange(lo, hi));
          expect(b.defect, inInclusiveRange(0, 2));
          if (b.inService) expect(b.state, M6CbmState.swollen, reason: 'only a swollen bank is found in service');
          final fits = switch (b.state) {
            M6CbmState.healthy => {M6CbmWhy.keepOn},
            M6CbmState.weak => {M6CbmWhy.tagOff, M6CbmWhy.noRetest},
            M6CbmState.blown => {M6CbmWhy.noRefit},
            M6CbmState.swollen => {M6CbmWhy.swollen},
          };
          expect(fits, contains(d.why[i]));
          if (b.inService) inService++;
        }
        if (states.contains(M6CbmState.swollen)) swollenDeals++;
        expect(d.push, m6CbmPushFor(d.banks[d.coworkerBank].state));
        expect(d.amps0, inInclusiveRange(250, 330));
        expect(d.pf0, inInclusiveRange(0.75, 0.85), reason: 'around the lesson\'s 0.8');
        pushes.add(d.push);
        whys.addAll(d.why);
        skies.add(d.sky);
        hisBank.add(d.coworkerBank);
        seen.add('${states.map((x) => x.index).join()}|${d.banks.map((b) => '${b.defect}${b.inService}').join()}|${d.coworkerBank}');
      }
      expect(seen.length, greaterThan(100));
      expect(pushes, M6CbmPush.values.toSet());
      expect(whys, M6CbmWhy.values.toSet());
      expect(skies, M6CbmSky.values.toSet());
      expect(hisBank, {0, 1, 2});
      expect(swollenDeals, inInclusiveRange(60, 260));
      expect(inService, inInclusiveRange(20, swollenDeals - 20), reason: 'a swollen bank is sometimes found ON');
    });

    test('the meters: a sound bank drops the amps clearly and lifts PF toward 1.0; a weak or blown one barely moves them', () {
      for (final s in M6CbmState.values) {
        final r = _runOf([s, M6CbmState.healthy, M6CbmState.weak]);
        final a0 = r.amps, pf0 = r.pf;
        expect(pf0, closeTo(0.8, 1e-9));
        expect(a0, closeTo(280, 1e-9));
        _logBoth(r);
        r.lever();
        expect(r.on[0], isTrue);
        final drop = a0 - r.amps;
        expect(r.pf, greaterThan(pf0));
        expect(r.pf, lessThan(1.0));
        switch (s) {
          case M6CbmState.healthy:
            expect(drop, greaterThan(15), reason: 'a clear swing');
            expect(r.pf - pf0, greaterThan(0.05));
          case M6CbmState.weak || M6CbmState.blown:
            expect(drop, lessThan(6), reason: 'little change');
            expect(r.pf - pf0, lessThan(0.02));
          case M6CbmState.swollen:
            break;
        }
      }
      // Two sound banks and a swollen one in at their most (the most a deal
      // can have in at once) still leave a lagging PF.
      final all = M6CbmRun(M6CbmDeal(
        banks: [
          for (final s in [M6CbmState.healthy, M6CbmState.healthy, M6CbmState.swollen]) M6CbmBank(state: s, defect: 0, relief: m6CbmReliefRange(s).$2),
        ],
        amps0: 250,
        pf0: 0.84,
        sky: M6CbmSky.dusk,
        coworkerBank: 0,
        why: const [M6CbmWhy.keepOn, M6CbmWhy.keepOn, M6CbmWhy.keepOn],
      ));
      all.on.setAll(0, [true, true, true]);
      expect(all.pf, lessThan(1.0));
      expect(all.amps, greaterThan(0));
    });

    test('the swings, any deal and play order: the smallest sound swing is more than 2x the largest weak or blown one, in amps and PF, and beyond the pencil tolerance', () {
      var soundA = double.infinity, soundPf = double.infinity, littleA = 0.0, littlePf = 0.0;
      void swingOf(M6CbmRun r, M6CbmState s) {
        final a0 = r.amps, pf0 = r.pf;
        _logBoth(r);
        expect(r.lever(), isNull);
        final da = a0 - r.amps, dp = r.pf - pf0;
        if (s == M6CbmState.healthy) {
          soundA = math.min(soundA, da);
          soundPf = math.min(soundPf, dp);
        } else {
          littleA = math.max(littleA, da);
          littlePf = math.max(littlePf, dp);
        }
        _logBoth(r);
      }

      // Every bank played right, in order.
      void play(M6CbmDeal d) {
        final r = M6CbmRun(d);
        for (var i = 0; i < 3; i++) {
          final b = d.banks[i];
          switch (b.state) {
            case M6CbmState.healthy:
              swingOf(r, b.state);
            case M6CbmState.weak:
              swingOf(r, b.state);
              expect(r.lever(), isNull);
              expect(r.tag(), isNull);
            case M6CbmState.blown || M6CbmState.swollen:
              if (b.inService) expect(r.lever(), isNull);
              expect(r.tag(), isNull);
          }
          expect(r.sign(), isNull, reason: '${b.state}');
          expect(r.pf, lessThan(1.0));
          r.next();
        }
        expect(r.slips, 0);
      }

      M6CbmWhy whyOf(M6CbmState st) => switch (st) {
            M6CbmState.healthy => M6CbmWhy.keepOn,
            M6CbmState.weak => M6CbmWhy.tagOff,
            M6CbmState.blown => M6CbmWhy.noRefit,
            M6CbmState.swollen => M6CbmWhy.swollen,
          };

      for (var s = 0; s < 300; s++) {
        play(m6CbmDeal(math.Random(s)));
      }
      // The corners of the dealt ranges (amps0, pf0, relief lo/hi, and the
      // hard mix: sound at its lowest, weak/blown/swollen at their highest),
      // with banks already in before the one switched.
      const orders = [
        [M6CbmState.weak, M6CbmState.blown, M6CbmState.healthy],
        [M6CbmState.healthy, M6CbmState.swollen, M6CbmState.healthy],
        [M6CbmState.healthy, M6CbmState.healthy, M6CbmState.blown],
        [M6CbmState.swollen, M6CbmState.healthy, M6CbmState.weak],
      ];
      for (final a0 in [250.0, 329.0]) {
        for (final p0 in [0.76, 0.84]) {
          for (final mode in [0, 1, 2]) {
            for (final order in orders) {
              double reliefOf(M6CbmState st) {
                final (lo, hi) = m6CbmReliefRange(st);
                return switch (mode) {
                  0 => lo,
                  1 => hi,
                  _ => st == M6CbmState.healthy ? lo : hi,
                };
              }

              play(M6CbmDeal(
                banks: [for (final st in order) M6CbmBank(state: st, defect: 0, relief: reliefOf(st), inService: st == M6CbmState.swollen)],
                amps0: a0,
                pf0: p0,
                sky: M6CbmSky.dusk,
                coworkerBank: 0,
                why: [for (final st in order) whyOf(st)],
              ));
            }
          }
        }
      }
      expect(littleA, greaterThan(0));
      expect(soundA, greaterThan(2 * littleA), reason: 'amps: sound $soundA vs little $littleA');
      expect(soundPf, greaterThan(2 * littlePf), reason: 'PF: sound $soundPf vs little $littlePf');
      expect(soundA, greaterThan(m6CbmTolerance(M6CbmMeter.amps)), reason: 'a sound swing is never inside the pencil tolerance');
      expect(soundPf, greaterThan(m6CbmTolerance(M6CbmMeter.pf)));
      expect(soundPf, greaterThanOrEqualTo(0.04));
      expect(littleA, lessThanOrEqualTo(5));
      expect(littlePf, lessThanOrEqualTo(0.015));
    });

    test('the pencil: a misread is not kept and costs nothing; a close mark keeps the true reading; no log once ON with both after-readings', () {
      final r = _runOf([M6CbmState.healthy, M6CbmState.weak, M6CbmState.blown]);
      expect(r.log(M6CbmMeter.amps, r.amps + 40), isFalse);
      expect(r.note, M6CbmNote.misread);
      expect(r.before, isEmpty);
      expect(r.slips, 0);
      expect(r.log(M6CbmMeter.amps, r.amps + 10), isTrue);
      expect(r.before[M6CbmMeter.amps], r.amps, reason: 'the true reading, not the mark');
      expect(r.log(M6CbmMeter.pf, r.pf - 0.05), isFalse);
      expect(r.log(M6CbmMeter.pf, r.pf - 0.01), isTrue);
      expect(r.beforeDone, isTrue);
      r.lever();
      expect(r.canLog, isTrue);
      _logBoth(r);
      expect(r.after[M6CbmMeter.amps], lessThan(r.before[M6CbmMeter.amps]!));
      expect(r.canLog, isFalse);
      expect(r.log(M6CbmMeter.amps, r.amps), isFalse);
    });

    test('a sound bank: ON only after both marks; the after-readings before anything else; stays ON and signed (no slip)', () {
      final r = _runOf([M6CbmState.healthy, M6CbmState.weak, M6CbmState.blown]);
      expect(r.lever(), isNull);
      expect(r.note, M6CbmNote.logFirst);
      expect(r.on[0], isFalse);
      expect(r.sign(), isNull);
      expect(r.note, M6CbmNote.decideFirst);
      _logBoth(r);
      expect(r.lever(), isNull);
      expect(r.on[0], isTrue);
      expect(r.needAfter, isTrue);
      expect(r.coworkerMoment, isFalse, reason: 'his "again" only once both after-readings are in');
      expect(r.sign(), isNull);
      expect(r.note, M6CbmNote.afterFirst);
      expect(r.lever(), isNull);
      expect(r.note, M6CbmNote.afterFirst);
      expect(r.on[0], isTrue);
      expect(r.tag(), isNull);
      expect(r.note, M6CbmNote.offFirst);
      _logBoth(r);
      expect(r.coworkerMoment, isTrue);
      expect(r.sign(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.slips, 0);
      expect(r.caught, [L.caughtKeepOn]);
      expect(r.why, M6CbmWhy.keepOn);
    });

    test('a sound bank tagged: unmeasured = isolation without cause (R32); measured, OFF and tagged = a needless tag at the sign', () {
      final u = _runOf([M6CbmState.healthy, M6CbmState.weak, M6CbmState.blown]);
      expect(u.tag(), Mk.untestedTag);
      expect(u.tagged[0], isFalse);
      expect(u.roundDone, isFalse);
      final w = _runOf([M6CbmState.weak, M6CbmState.healthy, M6CbmState.blown]);
      expect(w.tag(), Mk.untestedTag, reason: 'a weak bank looks sound until measured');
      final r = _runOf([M6CbmState.healthy, M6CbmState.weak, M6CbmState.blown]);
      _logBoth(r);
      r.lever();
      _logBoth(r);
      expect(r.lever(), isNull);
      expect(r.on[0], isFalse);
      expect(r.tag(), isNull);
      expect(r.tagged[0], isTrue);
      expect(r.sign(), Mk.needlessTag);
      expect(r.closedWrong, isTrue);
      expect(r.roundDone, isTrue);
      expect(r.slips, 1);
    });

    test('a weak bank: left ON = a slip that closes the row; OFF + tag = right; ON again after OFF = a re-switch slip (pro tip 2)', () {
      final a = _runOf([M6CbmState.weak, M6CbmState.healthy, M6CbmState.blown]);
      _logBoth(a);
      a.lever();
      _logBoth(a);
      expect(a.sign(), Mk.weakLeft);
      expect(a.closedWrong, isTrue);
      final b = _runOf([M6CbmState.weak, M6CbmState.healthy, M6CbmState.blown], why: const [M6CbmWhy.noRetest, M6CbmWhy.keepOn, M6CbmWhy.noRefit]);
      _logBoth(b);
      b.lever();
      _logBoth(b);
      expect(b.lever(), isNull);
      expect(b.switchedOff, isTrue);
      expect(b.why, M6CbmWhy.noRetest);
      expect(b.lever(), Mk.reSwitch);
      expect(b.on[0], isTrue, reason: 'the re-switch happens (the needles swing) and the slip card shows');
      expect(b.why, M6CbmWhy.tagOff, reason: '"why not again?" would not fit after a re-switch');
      expect(b.lever(), isNull);
      expect(b.on[0], isFalse);
      expect(b.lever(), isNull, reason: 'a second re-switch in the round costs nothing more');
      expect(b.on[0], isTrue);
      expect(b.lever(), isNull);
      expect(b.slips, 1);
      expect(b.tag(), isNull);
      expect(b.sign(), isNull);
      expect(b.roundDone, isTrue);
      expect(b.closedWrong, isFalse);
      expect(b.caught, [L.caughtWeak]);
      expect(b.slips, 1);
      expect(b.thorough, isFalse);
    });

    test('a sound bank switched OFF by mistake after measuring: ON again = one re-switch slip, and it can still be signed ON', () {
      final r = _runOf([M6CbmState.healthy, M6CbmState.weak, M6CbmState.blown]);
      _logBoth(r);
      r.lever();
      _logBoth(r);
      final full = r.amps;
      expect(r.lever(), isNull);
      expect(r.on[0], isFalse);
      expect(r.lever(), Mk.reSwitch);
      expect(r.on[0], isTrue);
      expect(r.amps, closeTo(full, 1e-9), reason: 'the bank back in');
      expect(r.needAfter, isFalse, reason: 'the after-readings are already in');
      expect(r.sign(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.closedWrong, isFalse);
      expect(r.slips, 1);
      expect(r.caught, [L.caughtKeepOn]);
    });

    test('a blown fuse: tag and sign at once is right; switched in and left ON a slip; his "fit a new one" heard = refit slip (R33)', () {
      final r = _runOf([M6CbmState.blown, M6CbmState.healthy, M6CbmState.weak]);
      expect(r.coworkerMoment, isTrue, reason: 'his refit push from the start of the row');
      expect(r.tag(), isNull);
      expect(r.tagged[0], isTrue);
      expect(r.tag(), isNull);
      expect(r.tagged[0], isFalse, reason: 'the tag comes back off');
      r.tag();
      expect(r.lever(), isNull);
      expect(r.note, M6CbmNote.tagHangs);
      expect(r.whyQuestion, L.whyQ[M6CbmWhy.noRefit]);
      expect(r.pushSlip(Mk.push(M6CbmPush.refit)), Mk.refit);
      expect(r.refitHeard, isTrue);
      expect(r.whyQuestion, L.whyQBlownTag, reason: 'he was heard: "why no new fuse?" would not fit');
      expect(r.sign(), isNull);
      expect(r.caught, [L.caughtBlown]);
      final on = _runOf([M6CbmState.blown, M6CbmState.healthy, M6CbmState.weak]);
      _logBoth(on);
      on.lever();
      _logBoth(on);
      expect(on.sign(), Mk.blownLeft);
    });

    test('a swollen can: switched in = a slip at once (M6-5); found ON and signed = a slip; OFF + tag = right; no after-readings owed', () {
      final a = _runOf([M6CbmState.swollen, M6CbmState.healthy, M6CbmState.weak]);
      _logBoth(a);
      expect(a.lever(), Mk.swollenIn);
      expect(a.on[0], isTrue);
      expect(a.needAfter, isFalse);
      expect(a.sign(), isNull, reason: 'R11 counts once a bank: no second card, the row waits for OFF + tag');
      expect(a.note, M6CbmNote.offFirst);
      expect(a.roundDone, isFalse);
      expect(a.slips, 1);
      expect(a.lever(), isNull);
      expect(a.on[0], isFalse);
      expect(a.tag(), isNull);
      expect(a.sign(), isNull);
      expect(a.roundDone, isTrue);
      expect(a.slips, 1);
      final b = _runOf([M6CbmState.swollen, M6CbmState.healthy, M6CbmState.weak], swollenOn: true);
      expect(b.on[0], isTrue);
      expect(b.tag(), isNull);
      expect(b.note, M6CbmNote.offFirst);
      expect(b.sign(), Mk.swollenIn);
      expect(b.closedWrong, isTrue);
      final c = _runOf([M6CbmState.swollen, M6CbmState.healthy, M6CbmState.weak], swollenOn: true);
      final a0 = c.amps;
      expect(c.lever(), isNull);
      expect(c.amps, greaterThan(a0), reason: 'the bank out: the line takes its current back');
      expect(c.tag(), isNull);
      expect(c.sign(), isNull);
      expect(c.slips, 0);
      expect(c.caught, [L.caughtSwollen]);
    });

    test('listening to him is the act he pushes (X2/B1): the swollen-can press deadly (R8), again and refit slips', () {
      expect(m6CbmPushFor(M6CbmState.healthy), M6CbmPush.reSwitch);
      expect(m6CbmPushFor(M6CbmState.weak), M6CbmPush.reSwitch);
      expect(m6CbmPushFor(M6CbmState.blown), M6CbmPush.refit);
      expect(m6CbmPushFor(M6CbmState.swollen), M6CbmPush.touch);
      expect(Mk.push(M6CbmPush.touch), Mk.touch);
      expect(Mk.touch.deadly, isTrue);
      // His push comes whether or not the swollen bank was found ON: the card
      // must be true either way (it never says the bank was not OFF).
      expect(Mk.touch.textBn.contains('ব্যাংক OFF হয়নি'), isFalse);
      expect(Mk.touch.textBn, contains('OFF করে অপেক্ষা হয়নি'));
      expect(Mk.push(M6CbmPush.reSwitch).deadly, isFalse);
      expect(Mk.push(M6CbmPush.refit).deadly, isFalse);
      final r = _runOf([M6CbmState.weak, M6CbmState.healthy, M6CbmState.blown], why: const [M6CbmWhy.noRetest, M6CbmWhy.keepOn, M6CbmWhy.noRefit]);
      r.pushSlip(Mk.reSwitch);
      expect(r.reSwitched, isTrue);
      expect(r.why, M6CbmWhy.tagOff);
      expect(r.slips, 1);
      r.failDeadly(Mk.touch);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
    });

    test('three slips and the play fails; each bank counts its own slips; next bank starts clean', () {
      final r = _runOf([M6CbmState.healthy, M6CbmState.weak, M6CbmState.blown]);
      for (var i = 0; i < 3; i++) {
        expect(r.tag(), Mk.untestedTag);
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      r.tag();
      expect(r.percent, 40);
      _logBoth(r);
      r.lever();
      _logBoth(r);
      r
        ..sign()
        ..next();
      expect(r.index, 1);
      expect(r.thorough, isTrue);
      expect(r.before, isEmpty);
      expect(r.switchedOn, isFalse);
      expect(r.on[0], isTrue, reason: 'bank 1 stays in service');
    });

    test('English digits only; jol not pani; owner terms; nukta form; every mistake has its picture; the deadly set; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        for (final n in M6CbmNote.values) L.note(n),
        L.toPanel,
        L.toYard,
        L.sign,
        L.zoomClose,
        L.yardLabel,
        L.panelLabel,
        for (var n = 1; n <= 3; n++) L.bankLabel(n),
        ...L.whyQ.values,
        L.whyQBlownTag,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6CbmPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtKeepOn,
        L.caughtWeak,
        L.caughtBlown,
        L.caughtSwollen,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|অন-|-অন').hasMatch(l), isFalse, reason: 'ON / OFF in English: $l');
        expect(l.contains('বন্ধ'), isFalse, reason: 'বন্ধ on a switch reads as OFF: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'য় ড় ঢ় as base + nukta: $l');
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.touch});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.7/m6_capbank_meter/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(m6CbmLessonPoint, inInclusiveRange(0, 3));
      const dir = 'assets/game/art/m6_capbank_meter/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m6CapbankMeterPacks.keys, ['do_6_7_b']);
      expect(_pack.titleBn, L.title);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(L.myths.length, greaterThanOrEqualTo(5));
      for (final w in M6CbmWhy.values) {
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

    test('rival lines: his exit is recorded; his three new pushes and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'আরেকবার OFF-ON করে দেখো, ঠিক চালু হয়ে যাবে।',
        'ফিউজ উড়েছে? নতুন একটা লাগিয়ে চালিয়ে দাও।',
        'ফোলা ক্যানটা হাত দিয়ে টিপে দেখো তো কতটা ফুলেছে।',
      ]);
      expect({for (final p in M6CbmPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      // Every line the guide speaks in this level: new ones listed, the rest
      // already recorded (shared kit lines).
      final spoken = <String>[
        L.intro,
        ...L.tasks,
        for (final n in M6CbmNote.values) L.note(n),
        ...L.whyQ.values,
        L.whyQBlownTag,
        for (final cw in L.allCoworkers) ...cw.asks,
        for (final p in M6CbmPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.quick,
        ...L.tapWhy,
        L.deadlyWord,
        L.nearMissWord,
      ];
      for (final l in spoken) {
        expect(L.newGuideLines.contains(l) || LearnVoice.resolve(l) != null, isTrue, reason: 'unlisted spoken line: $l');
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_capbank_meter: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, clear of the header, the guide and the button row', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6CbmGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final bubble = Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81);
        final panel = <Rect>[
          for (final m in M6CbmMeter.values) g.stripHit(m),
          for (var i = 0; i < 3; i++) ...[g.leverHit(i), g.tagHit(i)],
        ];
        final yard = [for (var i = 0; i < 3; i++) g.bank(i)];
        for (final r in [...panel, ...yard]) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the button row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          if (h >= 700) expect(r.overlaps(bubble), isFalse, reason: 'h $h: $r under the bubble');
        }
        for (final (i, a) in panel.indexed) {
          for (final b in panel.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        for (final (i, a) in yard.indexed) {
          for (final b in yard.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: banks');
          }
        }
        expect(g.log.contains(g.pencilRest), isTrue, reason: 'the pencil picks up on the log');
        for (final m in M6CbmMeter.values) {
          for (final v in [m6CbmValue(m, 0), m6CbmValue(m, 0.5), m6CbmValue(m, 1)]) {
            expect(g.valueAtX(m, g.stripXOf(m, v)), closeTo(v, 1e-9));
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

    testWidgets('the guide comes first: a tap does not skip him; then the yard, a bank zooms and comes back', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M6CapbankMeterPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.toPanel), findsOneWidget);
      expect(_label(L.sign), findsNothing, reason: 'the yard first');
      await _tapAt(t, _geo.bank(1).center);
      expect(find.byKey(const ValueKey('zoom-1')), findsOneWidget, reason: 'bank 2 close up');
      expect(_label(L.toPanel), findsNothing);
      await t.tap(_label(L.zoomClose));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('zoom-1')), findsNothing);
      expect(_label(L.toPanel), findsOneWidget);
      expect(_live.slips, 0);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    // One play with the swollen-can press (refused, a swollen bank found ON),
    // one with "again" on a weak bank, one with "fit a new one".
    final flowSeeds = [
      _seedWhere((d) => d.push == M6CbmPush.touch && d.banks[d.coworkerBank].inService),
      _seedWhere((d) => d.push == M6CbmPush.reSwitch && d.banks[d.coworkerBank].state == M6CbmState.weak),
      _seedWhere((d) => d.push == M6CbmPush.refit && d.coworkerBank > 0),
    ];
    for (final (k, seed) in flowSeeds.indexed) {
      testWidgets('flow (seed $seed): three banks — marks, one switch, the swing, the decision, reasons; he is refused → pass', (t) async {
        final d = m6CbmDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _toPanel(t);
        for (var i = 0; i < 3; i++) {
          await _playBank(t, d, i, drag: k == 0);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.7/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.7/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final soundFirstAlone = _seedWhere((d) => d.banks[0].state == M6CbmState.healthy && d.coworkerBank != 0);
    testWidgets('a misread asks again for free; a slip card keeps the bank; three slips strike the level out', (t) async {
      final c = await _open(t, soundFirstAlone);
      await _toPanel(t);
      await _logTap(t, M6CbmMeter.amps, _live.amps + 60);
      expect(_live.before, isEmpty);
      expect(find.byType(MistakeCard), findsNothing);
      await _logTap(t, M6CbmMeter.amps);
      expect(_live.before, hasLength(1));
      for (var i = 0; i < 3; i++) {
        await _tag(t);
        expect(_live.tagged[0], isFalse);
        if (i < 2) {
          expect(find.text(Mk.untestedTag.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.index, 0, reason: 'the same bank');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.first.key, Mk.untestedTag.key);
      await _close(t, c);
    });

    final swollenFirst = _seedWhere((d) => d.coworkerBank == 0 && d.push == M6CbmPush.touch && !d.banks[0].inService);
    testWidgets('listening to "press the swollen can" = deadly: the scene freezes first, then the card', (t) async {
      final c = await _open(t, swollenFirst);
      await _toPanel(t);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerTouch.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.touch.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: his bank\'s tag waits for the coworker; he cuts in at once', (t) async {
      final c = await _open(t, swollenFirst);
      await _toPanel(t);
      await _tag(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.tagged[0], isFalse, reason: 'the tag did not hang');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerTouch.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _tag(t);
      expect(_live.tagged[0], isTrue, reason: 'after him the tag hangs');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the swing locks the panel; the reason deck takes no touch', (t) async {
      final c = await _open(t, soundFirstAlone);
      await _toPanel(t);
      await _logTap(t, M6CbmMeter.amps);
      await _logTap(t, M6CbmMeter.pf);
      await _tapAt(t, _geo.leverHit(0).center, ms: 100);
      expect(_live.on[0], isTrue);
      // Mid-swing: a mark does nothing.
      await _logTap(t, M6CbmMeter.amps);
      expect(_live.after, isEmpty, reason: 'locked while the needles swing');
      await _pump(t, 1800);
      await _logTap(t, M6CbmMeter.amps);
      await _logTap(t, M6CbmMeter.pf);
      await _sign(t);
      expect(_label(L.sign), findsNothing, reason: 'the button row is gone');
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.leverHit(0).center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.on[0], isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M6CbmWhy.keepOn]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle in the yard shows a hand that presses nothing; on the panel too', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, soundFirstAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the yard');
      // The sweep glides over all three banks alike (or the tap on the panel
      // button): never one bank picked out.
      expect(scene().debugOptions.length, anyOf(0, 3), reason: 'never a pick');
      expect(scene().debugFrame?.ripple, isNull, reason: 'the sweep presses nothing');
      await _toPanel(t);
      expect(scene().showing, isFalse);
      // Three taps on nothing (between the meters' faces and the log edge).
      final empty = Offset(355, _geo.bandTop + 40) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge or a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
