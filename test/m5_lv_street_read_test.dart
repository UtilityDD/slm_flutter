// Lesson 5.5 ('লো-ভোল্টেজ' সমস্যার সমাধান), কাজ 1 "ড্রপ কোথায়?": the rules
// (ask the neighbours before the scope chip; one house → the service docket;
// many → the transformer's LT side first, all three phases before "fine"; a
// live tap change = deadly; the line's voltage pattern, evidence-gated; the
// docket), the deal (three kinds easy → hard, numbers dealt), the option
// libraries, the coworker's lines, and the level in the shell: the guide
// first, a full clean play with a reason pick and the coworker refused, a slip
// card that keeps the complaint, three slips, the deadly freeze, listening to
// him (a slip), the probes waiting for him, and the gesture hand (how, never
// what) only while the level waits.
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
import 'package:slm_flutter/features/game/m5_lv_street_read.dart';
import 'package:slm_flutter/features/game/m5_lv_street_read_world.dart';
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
  rungId: '5.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5LvStreetReadPacks['do_5_5_a']!;

/// The art may not be in the test bundle yet: read it from disk then.
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

/// The test screen (logical px); [_open] sets it (392 × 850 unless asked).
var _screen = const Size(392, 850);

/// The scene's design height and its cover-fit scale and offset on [_screen]
/// (as [FullSceneFrame] lays it out).
double get _sh => (360 * _screen.height / _screen.width).clamp(560.0, 900.0);
double get _k => math.max(_screen.width / 360, _screen.height / _sh);
Offset get _d => Offset((_screen.width - 360 * _k) / 2, (_screen.height - _sh * _k) / 2);
M5LvGeo get _geo => M5LvGeo.forScene(_sh, 0);

/// Design px → screen px.
Offset _toScreen(Offset p) => _d + p * _k;
Rect _rectToScreen(Rect r) => Rect.fromPoints(_toScreen(r.topLeft), _toScreen(r.bottomRight));

Future<void> _tapHouse(WidgetTester t, int h) async {
  await t.tapAt(_toScreen(_geo.house(h).center));
  await _pump(t, 300);
}

Future<void> _button(WidgetTester t, String label) async {
  await t.tap(_label(label), warnIfMissed: false);
  await _pump(t, 300);
}

/// A scope chip: its tap only opens it big; ✓ (key `choice-confirm`) answers.
Future<void> _scope(WidgetTester t, String label) async {
  await t.tap(_label(label), warnIfMissed: false);
  expect(await confirmChoice(t), isTrue, reason: label);
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {Size screen = const Size(392, 850), double padTop = 0}) async {
  _screen = screen;
  t.view.physicalSize = screen * 2;
  t.view.devicePixelRatio = 2.0;
  t.view.padding = FakeViewPadding(top: padTop * 2);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5LvStreetReadPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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
  _screen = const Size(392, 850);
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

Future<void> _refuseCoworker(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M5LvLines.coworker.right);
  await _pump(t, 2600);
}

int _seedWhere(bool Function(M5LvDeal d) ok) => [for (var s = 0; s < 2000; s++) s].firstWhere((s) => ok(m5LvDeal(math.Random(s))));

/// Ask one neighbour, then the right scope chip.
Future<void> _askAndScope(WidgetTester t, M5LvComplaint c) async {
  await _tapHouse(t, (c.caller + 1) % M5LvGeo.houses);
  await _scope(t, c.area ? M5LvLines.scopeMany : M5LvLines.scopeOne);
}

/// The right decision card at the LTDB.
List<String> _decideRight(M5LvComplaint c) => M5LvLines.decideText[c.kind == M5LvKind.dtrLow ? M5LvDecide.lowDocket : M5LvDecide.okLine]!;

/// One complaint played right (the coworker refused if he is dealt on it).
/// [onProbe] runs after each house probed on the line; [stopOnLine] ends the
/// helper once every house is probed.
Future<void> _complaint(WidgetTester t, M5LvDeal d, int i, {Future<void> Function(int h)? onProbe, bool stopOnLine = false}) async {
  final c = d.complaints[i];
  await _askAndScope(t, c);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'route deck');
  await _pump(t, 500);
  await _pickRight(t, c.area ? M5LvLines.routeAreaRight : M5LvLines.routeOneRight);
  await _pump(t, 800);
  if (!c.area) {
    await _reason(t, M5LvLines.whyRight[c.why]!);
    return;
  }
  final his = i == d.coworkerAt;
  if (his && d.coworkerProbe == 1) await _refuseCoworker(t);
  for (var ph = 0; ph < 3; ph++) {
    await _button(t, M5LvLines.terminalLabel(ph));
    if (his && d.coworkerProbe == 2 && ph == 0) await _refuseCoworker(t);
  }
  expect(find.text('${M5LvLines.ltdbLabel} B'), findsOneWidget, reason: 'the notebook row');
  await _button(t, M5LvLines.decide);
  await _pickRight(t, _decideRight(c));
  await _pump(t, 800);
  if (c.kind == M5LvKind.dtrLow) {
    await _reason(t, M5LvLines.whyRight[c.why]!);
    return;
  }
  for (var h = 0; h < M5LvGeo.houses; h++) {
    await _tapHouse(t, h);
    await onProbe?.call(h);
  }
  if (stopOnLine) return;
  await _button(t, M5LvLines.decide);
  await _pickRight(t, M5LvLines.verdictText[m5LvRightVerdict(c.kind)]!);
  await _pump(t, 900);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'docket deck');
  await _pump(t, 500);
  await _pickRight(t, c.kind == M5LvKind.sudden ? [M5LvLines.spanCard(c.dropAt)] : M5LvLines.docketRight[c.kind]!);
  await _pump(t, 800);
  await _reason(t, M5LvLines.whyRight[c.why]!);
}

M5LvComplaint _complaintOf(M5LvKind kind, {int caller = 9, int dropAt = 3, int lowPhase = 1}) => M5LvComplaint(
      kind: kind,
      caller: caller,
      phases: const [0, 1, 2, 0, 1, 2, 0, 1, 2, 1],
      lowPhase: kind == M5LvKind.onePhase ? lowPhase : -1,
      dropAt: dropAt,
      jitter: List.filled(10, 0),
      ltdbJitter: const [0, 0, 0],
      replies: List.filled(10, 0),
      why: M5LvLines.whyFor[kind]!.first,
      scopeFlip: false,
    );

M5LvRun _runOf(M5LvComplaint c) => M5LvRun(M5LvDeal(complaints: [c, c, c], coworkerAt: 0, coworkerProbe: 1));

/// A run at the LTDB (asked, scope and route right).
M5LvRun _atLtdb(M5LvComplaint c) {
  final r = _runOf(c)..ask((c.caller + 1) % 10);
  expect(r.scope(true), isNull);
  expect(r.route(true), isNull);
  expect(r.stage, M5LvStage.ltdb);
  return r;
}

void main() {
  group('rules', () {
    test('deal: three different kinds easy → hard; the coworker on a many-house complaint, 1st or 2nd probe; numbers fit the kind; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 120; s++) {
        final d = m5LvDeal(math.Random(s));
        expect(d.complaints, hasLength(3));
        final kinds = d.complaints.map((c) => c.kind.index).toList();
        expect(kinds.toSet(), hasLength(3));
        expect(kinds, [...kinds]..sort());
        expect(d.complaints[d.coworkerAt].area, isTrue);
        expect(d.coworkerProbe, inInclusiveRange(1, 2));
        for (final c in d.complaints) {
          expect(c.low(c.caller), isTrue, reason: '${c.kind}: the caller is low');
          expect(c.dropAt, inInclusiveRange(2, 4));
          for (var ph = 0; ph < 3; ph++) {
            expect(c.phases.where((p) => p == ph).length, greaterThanOrEqualTo(2));
          }
          final lows = [for (var h = 0; h < 10; h++) if (c.low(h)) h];
          if (c.kind == M5LvKind.oneHouse) {
            expect(lows, [c.caller], reason: 'only the caller');
          } else {
            expect(lows.length, greaterThanOrEqualTo(3), reason: '${c.kind}: many houses');
          }
          if (c.kind == M5LvKind.onePhase) {
            expect(lows.every((h) => c.phases[h] == c.lowPhase), isTrue);
          }
          expect(M5LvLines.whyFor[c.kind], contains(c.why));
        }
        seen.add('${kinds.join()}|${d.complaints.map((c) => c.caller).join(',')}|${d.coworkerAt}${d.coworkerProbe}');
      }
      expect(seen.length, greaterThan(60));
      expect({for (var s = 0; s < 120; s++) m5LvDeal(math.Random(s)).complaints.map((c) => c.kind.name).join()}.length, 10, reason: 'all 10 kind sets');
    });

    test('the voltage patterns: bands far apart (no 5–10 V calls)', () {
      for (var s = 0; s < 60; s++) {
        for (final c in m5LvDeal(math.Random(s)).complaints) {
          for (var ph = 0; ph < 3; ph++) {
            final v = c.ltdbVolts(ph);
            expect(c.kind == M5LvKind.dtrLow ? v < 206 : v > 230, isTrue, reason: '${c.kind} LTDB $v');
          }
          // Low and normal houses far apart (the gradual line steps down by
          // pole on purpose, checked below).
          if (c.kind == M5LvKind.gradual) continue;
          for (var h = 0; h < 10; h++) {
            final v = c.volts(h);
            expect(v < 210 || v > 225, isTrue, reason: '${c.kind} house $h $v');
          }
        }
      }
      final g = _complaintOf(M5LvKind.gradual);
      final byPole = [for (var p = 1; p <= 6; p++) g.volts([0, 1, 2, 3, 4, 9][p - 1])];
      for (var i = 1; i < 6; i++) {
        expect(byPole[i], lessThan(byPole[i - 1]), reason: 'gradual: $byPole');
      }
      final s3 = _complaintOf(M5LvKind.sudden, dropAt: 3);
      expect(s3.volts(2) - s3.volts(7), greaterThan(20), reason: 'P3 → P4 drop');
      expect((s3.volts(1) - s3.volts(2)).abs(), lessThan(5), reason: 'no drop P2 → P3');
    });

    test('ask: the scope chip before any neighbour = slip (the caller does not count); wrong scope = slip; right scope → route', () {
      final c = _complaintOf(M5LvKind.oneHouse, caller: 4);
      final r = _runOf(c);
      expect(r.ask(4), isTrue, reason: 'the caller');
      expect(r.scope(false), M5LvMistakes.askFirst);
      expect(r.ask(5), isFalse);
      expect(r.scope(true), M5LvMistakes.scopeOne);
      expect(r.stage, M5LvStage.ask);
      expect(r.scope(false), isNull);
      expect(r.stage, M5LvStage.route);
      expect(r.slips, 2);
      expect(r.caught, isNot(contains(M5LvLines.caughtAsk)));
      expect(r.route(false), M5LvMistakes.routeOne);
      expect(r.route(true), isNull);
      expect(r.roundDone, isTrue);
      final a = _runOf(_complaintOf(M5LvKind.dtrLow))..ask(0);
      expect(a.scope(false), M5LvMistakes.scopeMany);
      expect(a.scope(true), isNull);
      expect(a.route(false), M5LvMistakes.routeArea);
      expect(a.route(true), isNull);
      expect(a.stage, M5LvStage.ltdb);
    });

    test('LTDB: a live tap change is deadly; the myth is a slip; "fine" needs all three phases; a low transformer → its docket', () {
      final ok = _atLtdb(_complaintOf(M5LvKind.gradual));
      expect(ok.decide(M5LvDecide.okLine), M5LvMistakes.threePhase, reason: 'no reading');
      ok.probeLtdb(0);
      ok.probeLtdb(1);
      expect(ok.decide(M5LvDecide.okLine), M5LvMistakes.threePhase, reason: 'two phases');
      expect(ok.decide(M5LvDecide.lowDocket), M5LvMistakes.wrongDtr);
      expect(ok.decide(M5LvDecide.company), M5LvMistakes.company);
      ok.probeLtdb(2);
      expect(ok.decide(M5LvDecide.okLine), isNull);
      expect(ok.stage, M5LvStage.line);
      expect(ok.probes, 3);
      final low = _atLtdb(_complaintOf(M5LvKind.dtrLow))..probeLtdb(1);
      expect(low.decide(M5LvDecide.okLine), M5LvMistakes.wrongDtr);
      expect(low.decide(M5LvDecide.lowDocket), isNull);
      expect(low.roundDone, isTrue);
      final dead = _atLtdb(_complaintOf(M5LvKind.dtrLow))..probeLtdb(0);
      final m = dead.decide(M5LvDecide.liveTap);
      expect(m, M5LvMistakes.liveTap);
      expect(m!.deadly, isTrue);
      expect(dead.ended, isTrue);
      expect(m5LvBackToMeasure(M5LvMistakes.threePhase), isTrue);
      expect(m5LvBackToMeasure(M5LvMistakes.wrongDtr), isFalse);
    });

    test('line: verdicts are evidence-gated; the myth and a wrong verdict are slips; then the docket', () {
      M5LvRun onLine(M5LvComplaint c) {
        final r = _atLtdb(c)
          ..probeLtdb(0)
          ..probeLtdb(1)
          ..probeLtdb(2);
        expect(r.decide(M5LvDecide.okLine), isNull);
        return r;
      }

      // Gradual: three poles from near to far.
      final g = onLine(_complaintOf(M5LvKind.gradual));
      g.probeHouse(9);
      expect(g.verdict(M5LvVerdict.gradual), M5LvMistakes.evidence, reason: 'one reading');
      expect(g.verdict(M5LvVerdict.sudden), M5LvMistakes.wrongVerdict);
      expect(g.verdict(M5LvVerdict.company), M5LvMistakes.company);
      g.probeHouse(0);
      g.probeHouse(2);
      expect(g.verdict(M5LvVerdict.gradual), isNull);
      expect(g.stage, M5LvStage.docket);
      expect(g.docket(false), M5LvMistakes.wrongDocket);
      expect(g.docket(true), isNull);
      expect(g.roundDone, isTrue);
      // Sudden on P3–P4: both sides of the span.
      final s = onLine(_complaintOf(M5LvKind.sudden, dropAt: 3));
      s.probeHouse(0);
      s.probeHouse(9);
      expect(s.verdict(M5LvVerdict.sudden), M5LvMistakes.evidence, reason: 'P1 and P6 only');
      s.probeHouse(2); // P3
      s.probeHouse(7); // P4
      expect(s.verdict(M5LvVerdict.sudden), isNull);
      // One phase: two on the heavy phase, one on another.
      final o = onLine(_complaintOf(M5LvKind.onePhase, lowPhase: 1));
      o.probeHouse(1); // Y
      expect(o.verdict(M5LvVerdict.onePhase), M5LvMistakes.evidence);
      o.probeHouse(4); // Y
      o.probeHouse(0); // R
      expect(o.verdict(M5LvVerdict.onePhase), isNull);
    });

    test('line: a planned set of probes earns "রিডিং দেখে ঠিক রায়"; probing every house still passes but does not', () {
      M5LvRun onLine() {
        final r = _atLtdb(_complaintOf(M5LvKind.gradual))
          ..probeLtdb(0)
          ..probeLtdb(1)
          ..probeLtdb(2);
        expect(r.decide(M5LvDecide.okLine), isNull);
        return r;
      }

      final planned = onLine()
        ..probeHouse(0)
        ..probeHouse(2)
        ..probeHouse(9);
      expect(planned.verdict(M5LvVerdict.gradual), isNull);
      expect(planned.caught, contains(M5LvLines.caughtRead));
      final blanket = onLine();
      for (var h = 0; h < M5LvGeo.houses; h++) {
        blanket.probeHouse(h);
      }
      expect(blanket.probed.length, greaterThanOrEqualTo(m5LvBlanketProbes));
      expect(blanket.verdict(M5LvVerdict.gradual), isNull, reason: 'measuring is never a slip');
      expect(blanket.slips, 0);
      expect(blanket.caught, isNot(contains(M5LvLines.caughtRead)));
    });

    test('decks: one right card each; a low transformer always deals the live tap change; four verdicts; three span cards', () {
      for (var s = 0; s < 40; s++) {
        final rng = math.Random(s);
        for (final c in m5LvDeal(rng).complaints) {
          final route = m5LvRouteDeck(c.area, rng);
          expect(route.where((x) => x.correct), hasLength(1));
          expect(route.map((x) => x.textBn).toSet(), hasLength(3));
          if (!c.area) continue;
          final dec = m5LvDecideDeck(c, rng);
          expect(dec, hasLength(3));
          expect(dec.where((x) => x.correct), hasLength(1));
          final vals = dec.map((x) => x.value).toSet();
          expect(vals, containsAll([M5LvDecide.okLine, M5LvDecide.lowDocket]));
          if (c.kind == M5LvKind.dtrLow) expect(vals, contains(M5LvDecide.liveTap));
          if (c.kind == M5LvKind.dtrLow) continue;
          final ver = m5LvVerdictDeck(c, rng);
          expect(ver.map((x) => x.value).toSet(), M5LvVerdict.values.toSet());
          expect(ver.singleWhere((x) => x.correct).value, m5LvRightVerdict(c.kind));
          final doc = m5LvDocketDeck(c, rng);
          expect(doc, hasLength(3));
          expect(doc.where((x) => x.correct), hasLength(1));
          if (c.kind == M5LvKind.sudden) {
            expect(doc.singleWhere((x) => x.correct).textBn, M5LvLines.spanCard(c.dropAt));
            expectSameLength('spans', [for (final x in doc) x.textBn], ratio: 1.0);
          }
        }
      }
      expect(M5LvLines.spanCard(3), 'P3–P4 স্প্যানের জয়েন্ট শাটডাউনে টাইট');
    });

    test('libraries: same length, big enough, never a right marked wrong; the coworker lines are listed', () {
      expectSameLength('why', [...M5LvLines.allWhyRight, ...M5LvLines.myths]);
      expect(M5LvLines.myths.toSet().intersection(M5LvLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5LvWhy.values) {
        expectLibrary('why $w', M5LvLines.whyRight[w]!, M5LvLines.myths);
        expect(M5LvLines.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(M5LvLines.whyRight[w]!, M5LvLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectLibrary('route one', M5LvLines.routeOneRight, M5LvLines.routeOneWrong);
      expectLibrary('route area', M5LvLines.routeAreaRight, M5LvLines.routeAreaWrong);
      expectSameLength('route', [...M5LvLines.routeOneRight, ...M5LvLines.routeOneWrong, ...M5LvLines.routeAreaRight, ...M5LvLines.routeAreaWrong]);
      expect(M5LvLines.routeOneWrong.toSet().intersection(M5LvLines.routeOneRight.toSet()), isEmpty);
      expect(M5LvLines.routeAreaWrong.toSet().intersection(M5LvLines.routeAreaRight.toSet()), isEmpty);
      expectSameLength('decide', [for (final l in M5LvLines.decideText.values) ...l]);
      expectSameLength('verdict', [for (final l in M5LvLines.verdictText.values) ...l]);
      for (final k in M5LvLines.docketRight.keys) {
        expectLibrary('docket $k', M5LvLines.docketRight[k]!, M5LvLines.docketWrong);
      }
      expectSameLength('docket', [for (final l in M5LvLines.docketRight.values) ...l, ...M5LvLines.docketWrong]);
      final cw = M5LvLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.recordedLines, [cw.line, cw.exitLine]);
      expect(cw.line, contains('কোম্পানিই কম বিদ্যুৎ পাঠাচ্ছে'), reason: 'the lesson myth');
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: 'his exit is recorded');
    });

    test('English digits only; no পানি; every mistake has its picture; one deadly; keys unique', () {
      final all = <String>[
        M5LvLines.intro,
        ...M5LvLines.tasks,
        ...M5LvLines.rounds,
        ...M5LvLines.allWhyRight,
        ...M5LvLines.myths,
        ...M5LvLines.whyQ.values,
        ...M5LvLines.routeOneRight,
        ...M5LvLines.routeOneWrong,
        ...M5LvLines.routeAreaRight,
        ...M5LvLines.routeAreaWrong,
        for (final l in M5LvLines.decideText.values) ...l,
        for (final l in M5LvLines.verdictText.values) ...l,
        for (final l in M5LvLines.docketRight.values) ...l,
        ...M5LvLines.docketWrong,
        M5LvLines.spanCard(2),
        ...M5LvLines.lowReplies,
        ...M5LvLines.okReplies,
        M5LvLines.callerReply,
        ...M5LvLines.coworker.recordedLines,
        ...M5LvLines.coworker.right,
        ...M5LvLines.coworker.wrong,
        ...M5LvLines.coworker.asks,
        for (final m in M5LvMistakes.all) m.textBn,
        M5LvLines.allSet,
        M5LvLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—])পানি').hasMatch(l), isFalse, reason: l); // জল, never পানি (কোম্পানি is fine)
      }
      expect(M5LvMistakes.all.where((m) => m.deadly), [M5LvMistakes.liveTap]);
      expect(M5LvMistakes.all.map((m) => m.key).toSet(), hasLength(M5LvMistakes.all.length));
      final arts = <String>{};
      for (final m in M5LvMistakes.all) {
        expect(m.key, startsWith('5.5/m5_lv_street_read/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        arts.add(m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      final onDisk = Directory('assets/game/art/m5_lv_street_read').listSync().map((f) => f.path.replaceAll(r'\', '/')).toSet();
      expect(onDisk, arts, reason: 'no unused art');
      expect(m5LvStreetReadPacks.keys, ['do_5_5_a']);
    });

    test('notebook room: it stops above the far row and its reading chips on short and tall phones', () {
      for (final (w, h, top) in [(360.0, 640.0, 24.0), (360.0, 640.0, 0.0), (392.0, 850.0, 30.0), (412.0, 915.0, 40.0), (360.0, 560.0, 24.0)]) {
        final pad = EdgeInsets.only(top: top);
        final sh = (360 * h / w).clamp(560.0, 900.0);
        final k = math.max(w / 360, h / sh);
        final g = M5LvGeo.forScene(sh, 0);
        final chipTop = (h - sh * k) / 2 + (g.house(0).top - 30) * k;
        expect(m5LvNotebookTop(pad) + m5LvNotebookRoom(Size(w, h), pad), lessThan(chipTop), reason: '$w × $h');
      }
      // On 360 × 640 under a 24 px status bar it still has room for its lines.
      expect(m5LvNotebookRoom(const Size(360, 640), const EdgeInsets.only(top: 24)), greaterThan(80));
    });

    test('houses: tap areas inside the 360-wide street, apart, under the header and above the controls', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M5LvGeo.forScene(h, 0);
        final rects = [for (var i = 0; i < M5LvGeo.houses; i++) g.house(i)];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(150), reason: 'below the header');
          expect(r.bottom, lessThanOrEqualTo(h - 210), reason: 'the verge keeps the guide and controls off the houses');
          expect(r.width, greaterThanOrEqualTo(44));
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final x = rects[i].intersect(rects[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
        for (var p = 1; p <= 6; p++) {
          expect([for (var i = 0; i < 10; i++) M5LvGeo.poleOf(i)], contains(p), reason: 'every pole feeds a house');
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

    testWidgets('the guide comes first: a tap does not skip him; then the scope chips', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M5LvStreetReadPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5LvLines.scopeOne), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5LvLines.scopeOne), findsOneWidget);
      expect(_label(M5LvLines.scopeMany), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M5LvLines.askAsk)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final seeds = [
      _seedWhere((d) => d.complaints.first.kind == M5LvKind.oneHouse && d.complaints.last.kind == M5LvKind.sudden),
      _seedWhere((d) => d.complaints.first.kind == M5LvKind.dtrLow && d.complaints.last.kind == M5LvKind.onePhase && d.coworkerProbe == 2),
    ];
    for (final seed in seeds) {
      testWidgets('flow (seed $seed): ask, scope, route, LTDB, line, docket; the coworker refused; right reasons → pass', (t) async {
        final d = m5LvDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _complaint(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.5/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.5/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5LvLines.caughtCall), findsOneWidget);
        expect(find.text(M5LvLines.caughtAsk), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a short phone (360 × 640): the notebook never covers a far-row house or its reading chip', (t) async {
      final seed = _seedWhere((d) => d.complaints.first.kind == M5LvKind.oneHouse && d.complaints[1].kind == M5LvKind.dtrLow);
      final d = m5LvDeal(math.Random(seed));
      final c = await _open(t, seed, screen: const Size(360, 640), padTop: 24);
      expect(_k, 1.0);
      await _complaint(t, d, 0);
      await _complaint(t, d, 1);
      final houses = [for (var h = 0; h < M5LvGeo.houses; h++) _rectToScreen(_geo.house(h))];
      final notebook = find.byKey(const ValueKey('hud-notebook'));
      final chip = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('read-'));
      var rows = 0;
      await _complaint(t, d, 2, stopOnLine: true, onProbe: (h) async {
        expect(notebook, findsOneWidget, reason: 'probe $h');
        final r = t.getRect(notebook);
        for (var i = 0; i < houses.length; i++) {
          expect(r.overlaps(houses[i]), isFalse, reason: 'probe $h: notebook $r over house $i ${houses[i]}');
        }
        expect(chip, findsOneWidget);
        final cr = t.getRect(chip);
        expect(r.overlaps(cr), isFalse, reason: 'probe $h: notebook $r over the reading chip $cr');
        rows = h + 1;
      });
      expect(rows, M5LvGeo.houses);
      // Every reading is still there (two columns once one runs out).
      final latest = d.complaints[2];
      for (var h = 0; h < M5LvGeo.houses; h++) {
        expect(find.descendant(of: notebook, matching: find.text('${latest.volts(h)}')), findsWidgets, reason: 'house $h');
      }
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the scope chip before asking anyone) shows its card; the same complaint goes on', (t) async {
      final c = await _open(t, 2);
      await _scope(t, M5LvLines.scopeMany);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5LvMistakes.askFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M5LvLines.scopeOne), findsOneWidget, reason: 'the same complaint');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5LvMistakes.askFirst.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a scope chip opens big first: no answer on touch; ✕ sets it aside, ✓ answers', (t) async {
      final c = await _open(t, 2);
      await t.tap(_label(M5LvLines.scopeMany), warnIfMissed: false);
      await _pump(t, 100);
      expect(find.byKey(const ValueKey('choice-confirm')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing, reason: 'a touch is not an answer');
      // The buttons take no tap while the card opens.
      await t.tap(find.byKey(const ValueKey('choice-reject')), warnIfMissed: false);
      await t.pump();
      expect(find.byKey(const ValueKey('choice-reject')), findsOneWidget);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('choice-confirm')), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // Set aside, it still opens; ✓ answers (here the slip: no one asked yet).
      await _scope(t, M5LvLines.scopeMany);
      await _pump(t, 600);
      expect(find.text(M5LvMistakes.askFirst.textBn), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _scope(t, M5LvLines.scopeOne);
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

    testWidgets('a live tap change: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.complaints.first.kind == M5LvKind.dtrLow && d.coworkerAt != 0);
      final d = m5LvDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _askAndScope(t, d.complaints.first);
      await _pickRight(t, M5LvLines.routeAreaRight);
      await _pump(t, 800);
      await _button(t, M5LvLines.terminalLabel(0));
      await _button(t, M5LvLines.decide);
      await waitChoiceDeck(t);
      final live = _onScreen(M5LvLines.decideText[M5LvDecide.liveTap]!);
      expect(live, hasLength(1));
      await t.tap(live.single, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5LvMistakes.liveTap.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast probe waits for the coworker; listening to him is a slip and the measuring goes on', (t) async {
      final seed = _seedWhere((d) => d.coworkerAt == 0 && d.coworkerProbe == 2);
      final d = m5LvDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _askAndScope(t, d.complaints.first);
      await _pickRight(t, M5LvLines.routeAreaRight);
      await _pump(t, 800);
      await t.tap(_label(M5LvLines.terminalLabel(0)), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      // At once on the next terminal: well inside his 1.2–2.4 s timer.
      await t.tap(_label(M5LvLines.terminalLabel(1)), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.text('${M5LvLines.ltdbLabel} Y'), findsNothing, reason: 'the probe waited for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5LvLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5LvMistakes.listened.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _button(t, M5LvLines.terminalLabel(1));
      expect(find.text('${M5LvLines.ltdbLabel} Y'), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5LvMistakes.listened.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a right verdict without its readings is a slip; the deck closes for more measuring', (t) async {
      final seed = _seedWhere((d) => d.complaints.first.kind == M5LvKind.gradual && d.coworkerAt != 0);
      final d = m5LvDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _askAndScope(t, d.complaints.first);
      await _pickRight(t, M5LvLines.routeAreaRight);
      await _pump(t, 800);
      for (var ph = 0; ph < 3; ph++) {
        await _button(t, M5LvLines.terminalLabel(ph));
      }
      await _button(t, M5LvLines.decide);
      await _pickRight(t, M5LvLines.decideText[M5LvDecide.okLine]!);
      await _pump(t, 800);
      await _tapHouse(t, 9);
      await _button(t, M5LvLines.decide);
      await waitChoiceDeck(t);
      await t.tap(_onScreen(M5LvLines.verdictText[M5LvVerdict.gradual]!).single, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.text(M5LvMistakes.evidence.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'back to measuring');
      expect(_label(M5LvLines.decide), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hand: a tap ripple on the road while asking; a sweep over R/Y/B at the LTDB; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.complaints.first.kind == M5LvKind.dtrLow && d.coworkerAt != 0);
      final d = m5LvDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while asking');
      expect(scene().debugOptions, isEmpty, reason: 'a tap, not a sweep');
      // When the finger presses (the ripple), it is on the empty road.
      Offset? tip;
      for (var ms = 0; ms < 4000 && tip == null; ms += 50) {
        final f = scene().debugFrame;
        if (f != null && f.ripple != null) tip = f.tip;
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(tip, isNotNull);
      final road = Rect.fromLTRB(0, _geo.roadTop, 360, _geo.roadBottom);
      expect(road.inflate(6).contains(tip! / _k), isTrue, reason: 'on the road: $tip');
      for (var h = 0; h < 10; h++) {
        expect(_geo.house(h).contains(tip / _k), isFalse, reason: 'never on a house');
      }
      await _askAndScope(t, d.complaints.first);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own sweep');
      await _pickRight(t, M5LvLines.routeAreaRight);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the LTDB');
      expect(scene().debugOptions, hasLength(3), reason: 'R, Y and B alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _close(t, c);
    });
  });
}
