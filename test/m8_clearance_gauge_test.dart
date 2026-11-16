// Lesson 8.5 (সেফটি কোড), কাজ 1 "ঝুলে পড়া তার — মেপে দেখুন": the rules (the
// span as a function — an 11 kV road span measured from the LOCAL ground, an LT
// house span measured as the horizontal gap; sound and low bands, never the
// grey zone; a low span low over at least 30 % of its length so spread-out
// probes always find it; up to four probes, a tap on one lifts it; a stamp
// needs a reading; a wrong stamp is a slip and reveals the worst point), the
// deal (3+2 or 2+3, 2–3 breaches, the myth script only on a covered span), the
// libraries, the coworker (myth 2 word for word from the live lesson; listening
// = a slip, the level has no deadly act), and the level in the shell: the guide
// first, a full clean patrol (probes, held stamps, reasons, the coworker
// refused), a wrong stamp and its card, three slips, the stamp and the probe
// waiting for him, and the gesture hand.
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
import 'package:slm_flutter/features/game/m8_clearance_gauge.dart';
import 'package:slm_flutter/features/game/m8_clearance_gauge_world.dart';
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
  rungId: '8.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8ClearanceGaugePacks['do_8_5_a']!;
typedef L = M8ClearanceGaugeLines;
typedef Mk = M8ClearanceGaugeMistakes;

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
M8GaugeGeo get _geo => M8GaugeGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8GaugeRun get _live => M8ClearanceGaugeProbe.run!;

/// The four well-spread probe spots (a low span is always caught by these).
const _spread = [0.12, 0.38, 0.62, 0.88];

Future<void> _probe(WidgetTester t, double at) async {
  await t.tapAt(Offset(_geo.x(at), M8GaugeGeo.top + 90) * _k);
  await _pump(t, 250);
}

Future<void> _layProbes(WidgetTester t, [List<double> spots = _spread]) async {
  for (final s in spots) {
    await _probe(t, s);
  }
}

Finder _stampFinder(bool breach) => find.byKey(ValueKey('gauge-stamp-${breach ? 'breach' : 'ok'}'));

/// Press and hold a stamp, then let go.
Future<void> _stamp(WidgetTester t, {required bool breach, int ms = 950}) async {
  final g = await t.startGesture(t.getCenter(_stampFinder(breach)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {bool settle = true}) async {
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8ClearanceGaugePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  if (settle) await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8GaugeDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8GaugeDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2600);
}

/// One span played right (the coworker refused if he is dealt on it).
Future<void> _playSpan(WidgetTester t, M8GaugeDeal d, int i) async {
  final s = d.spans[i];
  expect(_live.index, i);
  final cw = d.coworkerSpan == i;
  final script = L.script(d.script);
  var refused = false;
  Future<void> maybeRefuse() async {
    if (!refused && cw && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      await _refuse(t, script);
      refused = true;
    }
  }

  if (cw && d.script == M8GaugeScript.shortcut) {
    // The first probe touch waits for him.
    await _probe(t, _spread.first);
    await _refuse(t, script);
    refused = true;
  }
  // Two passes: a probe tapped while he talks is not laid.
  for (var pass = 0; pass < 2; pass++) {
    for (final p in _spread) {
      if (!_live.probes.contains(p)) {
        await _probe(t, p);
        await maybeRefuse();
      }
    }
  }
  expect(_live.probes, hasLength(kM8GaugeProbes));
  expect(find.byKey(const ValueKey('gauge-logbook')), findsOneWidget);
  if (cw && d.script == M8GaugeScript.myth && !refused) {
    // The first stamp touch waits for him.
    final g = await t.startGesture(t.getCenter(_stampFinder(s.breach)));
    await _pump(t, 500);
    await g.up();
    await _refuse(t, script);
  }
  await _stamp(t, breach: s.breach);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'span $i ${s.kind} breach ${s.breach}');
  expect(_live.roundDone || _live.index > i, isTrue, reason: 'span $i');
  if (s.breach || d.okReasonSpan == i) {
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (span $i)');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[m8GaugeWhy(s)]!);
    await _pump(t, 3000);
  } else {
    await _pump(t, 2200);
  }
}

/// য় ড় ঢ় as base + nukta (the owner's rule); the live JSON may hold the one-code-point forms.
String _nfd(String x) => x.replaceAll('\u09dc', '\u09a1\u09bc').replaceAll('\u09dd', '\u09a2\u09bc').replaceAll('\u09df', '\u09af\u09bc');

String _lessonMyth() {
  final raw = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync());
  Map<String, dynamic>? find(Object? o) {
    if (o is Map<String, dynamic>) {
      if (o['id'] == '8.5') return o;
      for (final v in o.values) {
        final r = find(v);
        if (r != null) return r;
      }
    } else if (o is List) {
      for (final v in o) {
        final r = find(v);
        if (r != null) return r;
      }
    }
    return null;
  }

  final lesson = find(raw)!;
  final myths = (lesson['content'] as Map<String, dynamic>)['myth_buster']['myths'] as List;
  return (myths[1] as Map<String, dynamic>)['myth'] as String;
}

void main() {
  group('rules', () {
    test('deals: 3+2 or 2+3 spans, 2–3 breaches; the bands; never the grey zone; broad low stretch; the myth only on a covered span; plays differ', () {
      final seen = <String>{};
      var roads3 = 0, swapped = 0, myth = 0, shortcut = 0, offMid = 0, roads = 0;
      final profiles = <M8GaugeProfile>{};
      final breachCounts = <int>{};
      var fallbacks = 0;
      for (var seed = 0; seed < 300; seed++) {
        final d = m8GaugeDeal(math.Random(seed));
        expect(d.spans, hasLength(5));
        final nRoad = d.spans.where((s) => s.isRoad).length;
        expect(nRoad, inInclusiveRange(2, 3));
        if (nRoad == 3) roads3++;
        final nB = d.spans.where((s) => s.breach).length;
        expect(nB, inInclusiveRange(2, 3), reason: 'never 0 or 5');
        breachCounts.add(nB);
        if (d.stampsSwapped) swapped++;
        final covered = [for (var i = 0; i < 5; i++) if (d.spans[i].covered) i];
        if (covered.isEmpty) {
          expect(d.script, M8GaugeScript.shortcut, reason: 'no covered span: no myth');
          shortcut++;
        } else {
          expect(d.script, M8GaugeScript.myth);
          expect(covered, contains(d.coworkerSpan), reason: 'the myth comes on a covered span');
          myth++;
        }
        expect(d.spans[d.okReasonSpan].breach, isFalse, reason: 'the ok reason is asked on a sound span');
        for (final s in d.spans) {
          if (s.tries < 0) fallbacks++;
          final rounded = s.minValue;
          if (s.isRoad) {
            roads++;
            profiles.add(s.profile);
            expect(s.covered || !s.covered, isTrue);
            if (s.breach) {
              expect(rounded, inInclusiveRange(4.0, 5.6), reason: 'low road span');
              expect(s.zone, greaterThanOrEqualTo(0.30), reason: 'low over a broad stretch');
            } else {
              expect(rounded, inInclusiveRange(6.8, 7.5), reason: 'sound road span');
            }
            expect(rounded < 5.7 || rounded > 6.7, isTrue, reason: 'never 5.7–6.7 m');
            expect(s.valueAt(0), greaterThanOrEqualTo(7.2), reason: 'the ends are well up');
            expect(s.valueAt(1), greaterThanOrEqualTo(7.2));
            if ((s.minT - 0.5).abs() > 0.06) offMid++;
          } else {
            expect(s.covered, isFalse, reason: 'covered conductor is an 11 kV road matter');
            if (s.breach) {
              expect(rounded, inInclusiveRange(0.5, 0.9));
              expect(s.zone, greaterThanOrEqualTo(0.30));
            } else {
              expect(rounded, inInclusiveRange(1.5, 2.2));
            }
          }
          expect(s.traffic, isNotEmpty, reason: 'traffic on every span');
          // The truth is the worst point; every probe reads at least it.
          for (var g = 0; g <= kM8GaugeGrid; g++) {
            expect(s.readingT(g / kM8GaugeGrid), greaterThanOrEqualTo((rounded * 10).round() - 1));
          }
          expect(s.readingT(s.minT), (rounded * 10).round(), reason: 'the worst point reads the minimum');
          if (s.breach) {
            expect(s.readingT(s.minT), lessThan((s.ruleM * 10).round()));
          } else {
            expect(s.readingT(s.minT), greaterThan((s.ruleM * 10).round()));
          }
        }
        seen.add([for (final s in d.spans) '${s.kind.index}${s.profile.index}${s.minValue}${s.covered}${s.mirror}'].join('|'));
      }
      expect(fallbacks, 0, reason: 'the rejection deal always finds a span');
      expect(seen.length, greaterThan(290));
      expect(roads3, inInclusiveRange(100, 200));
      expect(swapped, inInclusiveRange(110, 190));
      expect(myth, greaterThan(150));
      expect(shortcut, greaterThan(20));
      expect(profiles, M8GaugeProfile.values.toSet(), reason: 'every ground profile is dealt');
      expect(breachCounts, {2, 3});
      expect(offMid / roads, greaterThan(0.2), reason: 'the worst point is often off mid-span');
    });

    test('well-spread probes always find a low span (and never call a sound one low); the rule is 6.5 m / 1.2 m', () {
      expect(m8GaugeRuleM(M8GaugeKind.road), 6.5);
      expect(m8GaugeRuleM(M8GaugeKind.lt), 1.2);
      for (var seed = 0; seed < 200; seed++) {
        for (final s in m8GaugeDeal(math.Random(seed)).spans) {
          final reads = [for (final p in _spread) s.readingT(p)];
          final lowest = reads.reduce(math.min);
          if (s.breach) {
            expect(lowest, lessThan((s.ruleM * 10).round()), reason: 'seed $seed ${s.kind}: four spread probes find it');
          } else {
            expect(lowest, greaterThan((s.ruleM * 10).round()), reason: 'seed $seed ${s.kind}: a sound span never reads low');
          }
        }
      }
      // An old 6.1 m span (reading in the grey band) is below today's 6.5 m: a breach.
      final old = M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 3.0);
      expect(old.minValue, closeTo(9.2 - 3.0, 0.05));
      expect(M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 3.1).breach, isTrue, reason: '6.1 m < 6.5 m');
      expect(M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 2.0).breach, isFalse);
      expect(m8GaugeText(65), '6.5 মি');
      expect(m8GaugePlate(M8GaugeKind.road), '11 kV');
      expect(m8GaugePlate(M8GaugeKind.lt), 'LT');
    });

    test('the ground matters: the reading is from the local ground, so a hump or an embankment moves the worst point off mid-span', () {
      final flat = M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 3.0);
      expect(flat.minT, closeTo(0.5, 0.01));
      final hump = M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 3.0, profile: M8GaugeProfile.hump, gAmp: 1.4, gCentre: 0.7, gWidth: 0.12);
      expect(hump.minT, greaterThan(0.58), reason: 'a hump under the right half');
      expect(hump.minValue, lessThan(flat.minValue));
      final mirrored = M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 3.0, profile: M8GaugeProfile.hump, gAmp: 1.4, gCentre: 0.7, gWidth: 0.12, mirror: true);
      expect(mirrored.minT, closeTo(1 - hump.minT, 0.01));
      final unequal = M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 2.0, poleA: 8.2, poleB: 10.2);
      expect(unequal.minT, lessThan(0.5), reason: 'the lower pole side');
      final bank = M8GaugeSpan.raw(kind: M8GaugeKind.road, sag: 2.0, profile: M8GaugeProfile.embankment, gAmp: 1.4);
      expect(bank.minT, closeTo(0.5, 0.02), reason: 'equal poles on a slope read like flat ground');
      // LT: a balcony narrows the gap where it juts.
      final lt = M8GaugeSpan.raw(kind: M8GaugeKind.lt, base: 2.8, bumps: const [(c: 0.3, w: 0.3, d: 1.6)]);
      expect(lt.minT, inInclusiveRange(0.12, 0.47), reason: 'where the balcony juts');
      expect(lt.minValue, closeTo(1.2, 0.05));
      expect(lt.breach, isFalse, reason: 'exactly 1.2 m is not under the rule');
    });

    test('the run: probes lay, snap, lift and stop at four; a stamp needs a reading; the worst point is revealed by a wrong stamp', () {
      final d = m8GaugeDeal(math.Random(1));
      final r = M8GaugeRun(d);
      expect(r.canStamp, isFalse);
      expect(r.stamp(breach: true), isNull, reason: 'nothing to judge yet');
      expect(r.slips, 0);
      expect(r.tap(0.30), isTrue);
      expect(r.probes, [0.30]);
      expect(r.canStamp, isTrue);
      expect(r.tap(0.31), isTrue, reason: 'a tap near a probe lifts it');
      expect(r.probes, isEmpty);
      for (final t in [0.1, 0.3, 0.5, 0.7]) {
        expect(r.tap(t), isTrue);
      }
      expect(r.tap(0.9), isFalse, reason: 'four probes at most');
      expect(r.probes, hasLength(4));
      expect(r.tap(0.50), isTrue);
      expect(r.probes, isNot(contains(0.5)), reason: 'lifted');
      expect(r.tap(0.9), isTrue);
      expect(r.tap(0.0), isFalse, reason: 'full again');
      final span = r.span;
      final wrong = r.stamp(breach: !span.breach);
      expect(wrong, span.breach ? Mk.missed(span.kind) : Mk.falseReport(span.kind));
      expect(r.revealT, span.minT, reason: 'the true worst point is shown');
      expect(r.slips, 1);
      expect(r.roundDone, isFalse, reason: 'the same span goes on');
      expect(r.stamp(breach: span.breach), isNull);
      expect(r.roundDone, isTrue);
      expect(r.booked, span.breach);
      expect(r.caught, contains(span.breach ? (span.isRoad ? L.caughtLow : L.caughtNear) : L.caughtOk));
      expect(r.tap(0.2), isFalse, reason: 'the span is done');
      r.next();
      expect(r.index, 1);
      expect(r.probes, isEmpty);
      expect(r.revealT, isNull);
      expect(r.booked, isFalse);
      expect(r.thorough, isTrue, reason: 'each span counts its own slips');
    });

    test('the four slips: a breach called fine, a sound span reported, listening; no deadly act; three slips fail; the pass mark', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'ground patrol: no deadly row (M8-1/M8-12)');
      final r = M8GaugeRun(m8GaugeDeal(math.Random(2)));
      expect(r.pushSlip(), Mk.listen(r.deal.script));
      expect(r.slips, 1);
      expect(r.percent, 85);
      r
        ..pushSlip()
        ..pushSlip();
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.passed, isFalse, reason: 'not done yet');
      expect(Mk.missed(M8GaugeKind.road), Mk.missedRoad);
      expect(Mk.missed(M8GaugeKind.lt), Mk.missedLt);
      expect(Mk.falseReport(M8GaugeKind.road), Mk.falseRoad);
      expect(Mk.falseReport(M8GaugeKind.lt), Mk.falseLt);
      expect(Mk.listen(M8GaugeScript.myth), Mk.listenMyth);
      expect(Mk.listen(M8GaugeScript.shortcut), Mk.listenShortcut);
      // A clean run to the end passes.
      final c = M8GaugeRun(m8GaugeDeal(math.Random(3)));
      for (var i = 0; i < 5; i++) {
        c.tap(0.2);
        expect(c.stamp(breach: c.span.breach), isNull);
        c.next();
      }
      expect(c.done, isTrue);
      expect(c.passed, isTrue);
      expect(c.percent, 100);
    });

    test('the coworker\'s myth is lesson 8.5 myth 2 word for word (11 kV in letters on screen); the shortcut is his other push', () {
      final live = _lessonMyth();
      expect(_nfd(live), '১১ কেভি লাইন ইনসুলেটেড থাকে, ধরলে কিছু হয় না।', reason: 'the live text');
      expect(L.coworkerMyth.line, _nfd(live).replaceFirst('১১ কেভি', '11 kV'), reason: 'term rule: 11 kV in English letters');
      expect(L.coworkerShortcut.line, 'গাড়ি থেকে দেখেই সব ঠিক লিখে দাও, মাপার দরকার নেই।');
      expect(L.script(M8GaugeScript.myth), L.coworkerMyth);
      expect(L.script(M8GaugeScript.shortcut), L.coworkerShortcut);
    });

    test('English digits only; jol not pani; term rules; every number is the lesson\'s; every mistake has its picture; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.sceneLabel,
        L.logbookLabel,
        L.stampOk,
        L.stampBreach,
        for (var n = 1; n <= 5; n++) L.spanName(n),
        ...L.whyQ.values,
        ...L.allWhyRight,
        for (final l in L.whyWrong.values) ...l,
        ...L.coworkerMyth.recordedLines,
        ...L.coworkerMyth.right,
        ...L.coworkerMyth.wrong,
        ...L.coworkerMyth.asks,
        ...L.coworkerShortcut.recordedLines,
        ...L.coworkerShortcut.right,
        ...L.coworkerShortcut.wrong,
        ...L.coworkerShortcut.asks,
        L.heldMyth,
        L.heldShortcut,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtLow,
        L.caughtNear,
        L.caughtOk,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|সুইচ অন|এলটি|এইচটি|কেভি|ভোল্ট ').hasMatch(l.replaceAll('ভোল্টেজ', '')), isFalse, reason: 'ON/OFF, LT, HT, kV in English letters: $l');
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        expect(RegExp('[\u09dc\u09dd\u09df]').hasMatch(l), isFalse, reason: 'nukta form: $l');
        expect(l.contains('বেআইনি'), isFalse, reason: l);
        expect(RegExp(r'18|19 ?ফুট|ফুট').hasMatch(l), isFalse, reason: 'today\'s rule is in metres (A2/M8-12): $l');
        expect(RegExp(r'\d').hasMatch(l) ? RegExp(r'(?<![\d.])(\d+\.\d|\d+)(?![\d.])').allMatches(l).map((x) => x.group(0)!).every((n) => const {'6.5', '1.2', '11'}.contains(n)) : true, isTrue,
            reason: 'only the lesson\'s numbers (6.5 m, 1.2 m, 11 kV): $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.5/m8_clearance_gauge/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, anyOf(2, 3), reason: 'the ground / building clearance points of lesson 8.5');
      }
      const dir = 'assets/game/art/m8_clearance_gauge/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m8ClearanceGaugePacks.keys, ['do_8_5_a']);
      expect(Mk.missedRoad.textBn, contains('6.5'));
      expect(Mk.missedLt.textBn, contains('1.2'));
      expect(Mk.listenMyth.textBn, contains('পিন-হোল'));
    });

    test('libraries: same length, big enough, one right per deal; the stamps alike', () {
      expectSameLength('stamps', [L.stampOk, L.stampBreach]);
      for (final w in M8GaugeWhy.values) {
        expect(L.whyQ[w], isNotEmpty);
        expectSameLength('why $w', [...L.whyRight[w]!, ...L.whyWrong[w]!]);
        expectLibrary('why $w', L.whyRight[w]!, L.whyWrong[w]!);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.whyWrong[w]!, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in [L.coworkerMyth, L.coworkerShortcut]) {
        expectSameLength('coworker ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expect(L.coworkerMyth.right, containsAll(['ঢাকা তারকেও খোলা তার ধরব—মাপের আইন একই।', 'পিন-হোল বা ফাটল থাকতে পারে, তাই মাপব।']), reason: 'the spec\'s refusals');
      expect(L.coworkerMyth.wrong, containsAll(['ঠিক, ইনসুলেটেড তার—নিচু হলেও চলবে।', 'ঢাকা তার, তাই খাতায় ঠিক লিখে দিই।']), reason: 'the spec\'s listens');
      expect(L.coworkerShortcut.right, contains('না, তার ঝুলেছে কি না দেখা আমার কাজ।'));
      expect(L.coworkerShortcut.wrong, contains('ঠিক আছে, না মেপেই ঠিক লিখে দিই।'));
      expect(L.whyRight[M8GaugeWhy.roadBreach], contains('ঝুলে পড়া তার টাইট করানো আমার আইনি দায়িত্ব।'));
      expect(L.whyRight[M8GaugeWhy.ltBreach], contains('কাপড় মেলতে গিয়ে কেউ যেন তারে না লেগে যায়।'));
    });

    test('spoken lines: his exit is recorded; his two pushes and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworkerMyth.line, L.coworkerShortcut.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            ...L.tapWhy,
            ...L.whyQ.values,
            ...L.coworkerMyth.asks,
            ...L.coworkerShortcut.asks,
            L.heldMyth,
            L.heldShortcut,
            L.allSet,
            L.quick,
            L.fail,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_clearance_gauge: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the drawing: every probe on the scene, under the header, over the ground, clear of the stamps\' card; the wire above the ground everywhere', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M8GaugeGeo.forScene(h, 0);
        for (var seed = 0; seed < 40; seed++) {
          for (final s in m8GaugeDeal(math.Random(seed)).spans) {
            for (var i = 0; i <= 100; i += 4) {
              final t = i / 100;
              final (a, b) = g.probeEnds(s, t);
              final tag = 'h $h seed $seed ${s.kind} t $t';
              expect(a.dx, inInclusiveRange(40, 320), reason: tag);
              expect(a.dy, greaterThan(M8GaugeGeo.top - 2), reason: '$tag under the header');
              expect(b.dy, lessThanOrEqualTo(h - 190), reason: '$tag above the stamps\' card');
              expect(b.dy, greaterThan(a.dy), reason: '$tag the probe has length');
            }
            // The tap lands on the span.
            expect(g.onSpan(Offset(g.x(0.5), M8GaugeGeo.top + 90)), isTrue);
            expect(g.tOf(g.x(0.37)), closeTo(0.37, 1e-9));
          }
        }
        expect(g.onSpan(const Offset(4, 200)), isFalse);
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

    testWidgets('the guide comes first: a tap does not skip him; then the patrol, no stamps until a probe is down', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8ClearanceGaugePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.byKey(const ValueKey('gauge-logbook')), findsNothing);
      expect(_stampFinder(true), findsNothing);
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
      expect(lines.every((l) => l.contains(L.askSpan)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('probes: a tap lays one with its reading, a tap on it lifts it, four at most; the stamps come with the first reading and take no tap', (t) async {
      final seed = _seedWhere((d) => d.coworkerSpan != 0 && d.stampsSwapped);
      final c = await _open(t, seed);
      expect(_live.probes, isEmpty);
      await _probe(t, 0.3);
      expect(_live.probes, [0.3]);
      expect(find.byKey(const ValueKey('gauge-logbook')), findsOneWidget);
      expect(find.byKey(const ValueKey('probe-dot-0')), findsOneWidget);
      // The two stamps are alike and their sides are dealt.
      final left = t.getCenter(_stampFinder(true)).dx < t.getCenter(_stampFinder(false)).dx;
      expect(left, isTrue, reason: 'swapped: the breach stamp stands left');
      // A plain tap on a stamp books nothing.
      await t.tap(_stampFinder(true));
      await _pump(t, 300);
      expect(_live.roundDone, isFalse);
      expect(_live.slips, 0);
      // A short press books nothing either.
      await _stamp(t, breach: true, ms: 300);
      expect(_live.slips, 0);
      expect(_live.roundDone, isFalse);
      await _probe(t, 0.3);
      expect(_live.probes, isEmpty, reason: 'lifted');
      await _layProbes(t);
      await _probe(t, 0.5);
      expect(_live.probes, hasLength(4), reason: 'a fifth cannot be laid');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final flowSeeds = [
      _seedWhere((d) => d.script == M8GaugeScript.myth && d.stampsSwapped && d.spans.where((s) => s.breach).length == 3),
      _seedWhere((d) => d.script == M8GaugeScript.shortcut && !d.stampsSwapped),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): five spans, probes, held stamps, reasons; he is refused → pass', (t) async {
        final d = m8GaugeDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 5; i++) {
          await _playSpan(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.5/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.5/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final slipSeed = _seedWhere((d) => d.coworkerSpan != 0 && !d.spans.first.breach);
    testWidgets('a wrong stamp is a slip: the probe glides to the worst point and reads it, the card follows, the same span goes on; three slips strike out', (t) async {
      final d = m8GaugeDeal(math.Random(slipSeed));
      final span = d.spans.first;
      final c = await _open(t, slipSeed);
      await _layProbes(t, [0.2, 0.7]);
      // A needless report on a sound span.
      await _stamp(t, breach: true);
      expect(find.text(Mk.falseReport(span.kind).textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.revealT, span.minT);
      expect(_live.index, 0);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(_live.index, 0, reason: 'the same span');
      expect(_live.probes, hasLength(2), reason: 'the probes stay');
      // Twice more: three slips fail the level.
      await _stamp(t, breach: true);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await _stamp(t, breach: true);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).toSet(), {Mk.falseReport(span.kind).key});
      await _close(t, c);
    });

    final breachSeed = _seedWhere((d) => d.coworkerSpan != 0 && d.spans.first.breach);
    testWidgets('calling a low span fine is a slip with its card; then the right stamp ties the tag and asks why', (t) async {
      final d = m8GaugeDeal(math.Random(breachSeed));
      final span = d.spans.first;
      final c = await _open(t, breachSeed);
      await _layProbes(t);
      await _stamp(t, breach: false);
      expect(find.text(Mk.missed(span.kind).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await _stamp(t, breach: true);
      expect(_live.booked, isTrue);
      // The praise window and the reason deck take no touch on the scene.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(60, 300));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[m8GaugeWhy(span)]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(_live.probes, isEmpty);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).toSet(), {Mk.missed(span.kind).key});
      await _close(t, c);
    });

    final mythSeed = _seedWhere((d) => d.script == M8GaugeScript.myth && d.coworkerSpan == 0);
    testWidgets('myth script: the first stamp touch waits for him; listening is a slip (not deadly) and the span still has to be judged', (t) async {
      final d = m8GaugeDeal(math.Random(mythSeed));
      final span = d.spans.first;
      final c = await _open(t, mythSeed);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _probe(t, 0.38);
      // At once, well inside his 1.2–2.4 s timer: the stamp.
      final g = await t.startGesture(t.getCenter(_stampFinder(span.breach)));
      await _pump(t, 400);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await g.up();
      await _pump(t, 700);
      expect(_live.roundDone, isFalse, reason: 'the stamp did not book');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworkerMyth.wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.listenMyth.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      expect(_live.index, 0);
      expect(_live.roundDone, isFalse, reason: 'the judgement still has to be made');
      await _layProbes(t, [0.12, 0.62, 0.88]);
      await _stamp(t, breach: span.breach);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).toSet(), {Mk.listenMyth.key});
      await _close(t, c);
    });

    final shortSeed = _seedWhere((d) => d.script == M8GaugeScript.shortcut && d.coworkerSpan == 0);
    testWidgets('shortcut script: the first probe touch waits for him; listening is a slip; then the span goes on', (t) async {
      final c = await _open(t, shortSeed, settle: false);
      // At once, well inside his 1.2–2.4 s timer: the first probe.
      await t.tapAt(Offset(_geo.x(0.4), M8GaugeGeo.top + 90) * _k);
      await _pump(t, 400);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.probes, isEmpty, reason: 'the probe did not land');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworkerShortcut.wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.listenShortcut.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      await _probe(t, 0.4);
      expect(_live.probes, [0.4], reason: 'he has gone: the probe works');
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).toSet(), {Mk.listenShortcut.key});
      await _close(t, c);
    });

    testWidgets('gesture hand: idle with no probe shows a plain tap; with a reading a sweep over both stamps; any touch hides it; none with a card up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerSpan != 0);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle before any probe');
      await t.tapAt(const Offset(60, 400));
      await _pump(t, 300);
      expect(scene().showing, isFalse);
      await _probe(t, 0.3);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'a reading is down and the level waits for a stamp');
      await _stamp(t, breach: !_live.span.breach);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'no hand over a mistake card');
      await _close(t, c);
    });
  });
}
