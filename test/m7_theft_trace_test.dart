// Lesson 7.5 (বিদ্যুৎ চুরি), কাজ 1 "তারের পিছু পিছু": the rules (the chalk
// follows the finger only on its wire, stops off it, rubs out backwards; a
// verdict only on a fully traced wire — the pin on the theft point right, on
// another point of a theft wire a bounce, on a legal wire a slip; 'ঠিক আছে'
// right on a legal wire, a slip on a theft; the meter close-up the same; the
// report needs both recipients), the deal (two lanes with the other conductor,
// 1–2 thefts each, crossing roots, an old patch on a legal wire, the meter's
// four cases), the libraries, the lines listed for recording, no deadly
// (ruling M7-6), and the level in the shell: the guide first, full clean
// plays (traces by drag, pins, previews, reasons, the coworker refused after
// the first pin or at the send), a false pin, listening to him, three slips,
// the ঠিক আছে preview, and the gesture hand.
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_theft_trace.dart';
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
  rungId: '7.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7TheftTracePacks['do_7_5_a']!;
typedef L = M7TheftTraceLines;
typedef Mk = M7TheftTraceMistakes;

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      // Another build may be rewriting the test asset folder: an empty
      // manifest then (the art comes from disk below).
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
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

Future<void> _pickRight(WidgetTester t, List<String> right, {bool proceed = true}) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  if (proceed) {
    await tapReasonProceed(t);
  } else {
    await confirmChoice(t);
  }
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M7TtRun get _live => M7TheftTraceProbe.run!;
M7TtGeo get _g => M7TheftTraceProbe.geo!;
Offset _screen(Offset design) => design * _k;

/// A geometry for the rules (the test screen's scene height).
final _geo = M7TtGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

String _nukta(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

/// Drags the finger along [pts] (design px) from the first; true when the
/// item ends traced.
Future<bool> _dragAlong(WidgetTester t, List<Offset> pts) async {
  final g = await t.startGesture(_screen(pts.first));
  await t.pump(const Duration(milliseconds: 16));
  for (final p in pts.skip(1)) {
    await g.moveTo(_screen(p));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
  return _live.traced;
}

/// Traces lane wire [id] (or the meter) from its start to its end.
Future<bool> _trace(WidgetTester t, int id) => _dragAlong(t, _live.pathOf(id, _g));

/// Drags the notebook's red pin onto point [i].
Future<void> _pinOn(WidgetTester t, int i) async {
  final nb = _g.notebook.topLeft;
  final from = nb + M7TtSketch.pinHome;
  final to = nb + m7TtStationAt(_live.spots!, i);
  final g = await t.startGesture(_screen(from));
  await t.pump(const Duration(milliseconds: 16));
  for (var k = 1; k <= 12; k++) {
    await g.moveTo(_screen(Offset.lerp(from, to, k / 12)!));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

/// 'ঠিক আছে' through its preview (✓).
Future<void> _ok(WidgetTester t) async {
  await t.tap(_label(L.okLabel));
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue, reason: 'the preview opens');
  await _pump(t, 400);
}

/// Waits a moment and answers whatever deck rises: a reason (the right card,
/// then এগিয়ে যান) or the coworker (refused).
Future<void> _settle(WidgetTester t, {int ms = 2200}) async {
  for (var waited = 0; waited < ms; waited += 100) {
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty && _onScreen(L.coworker.right).isNotEmpty) {
      await _pump(t, 400);
      await _pickRight(t, L.coworker.right, proceed: false);
      await _pump(t, 2600);
      waited = 0;
      continue;
    }
    if (find.byType(ChoiceDeck).evaluate().isNotEmpty && _onScreen(L.allWhyRight).length == 1 && find.byType(CoworkerPeek).evaluate().isEmpty) {
      await _pump(t, 400);
      await _pickRight(t, L.allWhyRight);
      await _pump(t, 1200);
      waited = 0;
      continue;
    }
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// The right verdict on the traced item.
Future<void> _rightVerdict(WidgetTester t) async {
  final sp = _live.spots!;
  final i = sp.indexWhere(kM7TtTheftSpots.contains);
  if (i < 0) {
    await _ok(t);
  } else {
    await _pinOn(t, i);
  }
  expect(find.byType(MistakeCard), findsNothing);
}

/// One item (a lane wire, or the meter): traced (retrying after the
/// coworker), then judged right.
Future<void> _playItem(WidgetTester t, int id) async {
  for (var attempt = 0; attempt < 3 && !_live.traced; attempt++) {
    await _settle(t, ms: 600);
    await _trace(t, id);
  }
  expect(_live.traced, isTrue, reason: 'item $id traced');
  await _rightVerdict(t);
  await _settle(t);
}

/// The whole play right; the coworker refused wherever he comes.
Future<void> _playAll(WidgetTester t) async {
  for (var lane = 0; lane < kM7TtLanes; lane++) {
    expect(_live.round, lane);
    for (final w in [..._live.lane.wires]..shuffle(math.Random(lane))) {
      await _playItem(t, w.id);
    }
    await _settle(t, ms: 1600);
  }
  expect(_live.onMeter, isTrue);
  await _playItem(t, 0);
  await _settle(t, ms: 1600);
  expect(_live.onReport, isTrue);
  await t.tap(_label(L.who(M7TtWho.supervisor)));
  await _pump(t, 200);
  await t.tap(_label(L.who(M7TtWho.vigilance)));
  await _pump(t, 200);
  for (var attempt = 0; attempt < 3 && !_live.sent; attempt++) {
    await t.tap(_label(L.send));
    await _pump(t, 300);
    await _settle(t);
  }
  expect(_live.sent, isTrue);
  await _settle(t, ms: 3000);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7TheftTracePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7TtDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7TtDeal(math.Random(s))));

/// A run on [deal] (for the rules).
M7TtRun _runOf(int seed) => M7TtRun(m7TtDeal(math.Random(seed)));

/// Feeds the finger along wire [id]'s path from the start (design px).
M7TtStep _feed(M7TtRun r, int id, {double upTo = 1}) {
  final pts = r.pathOf(id, _geo);
  final id0 = r.grab(pts.first, _geo);
  expect(id0, id, reason: 'grabbed at its start');
  r.begin(id);
  var last = M7TtStep.none;
  final n = (pts.length * upTo).round();
  for (var i = 1; i < n; i++) {
    final s = r.trace(pts[i], _geo);
    if (s != M7TtStep.none) last = s;
    if (s == M7TtStep.off || s == M7TtStep.done) return s;
  }
  return last;
}

M7TtWire _wireOf(M7TtRun r, M7TtWireKind k) => r.lane.wires.firstWhere((w) => w.kind == k);

int _seedLane0With(M7TtWireKind k) => _seedWhere((d) => d.lanes[0].wires.any((w) => w.kind == k));

void main() {
  group('rules', () {
    test('deals: two lanes, the other conductor; 1–2 thefts, 4–5 wires to 3–4 houses; crossing roots; a patched legal wire; plays differ', () {
      final seen = <String>{};
      final meters = <M7TtMeterCase>{};
      final kinds = <M7TtWireKind>{};
      final atSend = <bool>{};
      final symptom = <bool>{};
      final counts = <int>{};
      final upPatched = <bool>{};
      var intact = 0;
      for (var s = 0; s < 400; s++) {
        final d = m7TtDeal(math.Random(s));
        expect(d.lanes, hasLength(kM7TtLanes));
        expect(d.lanes[0].cond, isNot(d.lanes[1].cond));
        for (final l in d.lanes) {
          final thefts = l.wires.where((w) => w.kind != M7TtWireKind.legal).toList();
          expect(thefts.length, inInclusiveRange(1, 2), reason: 'seed $s');
          expect(thefts.map((w) => w.kind).toSet(), hasLength(thefts.length), reason: 'kinds differ in a lane');
          expect(l.wires.length, inInclusiveRange(4, 5));
          expect(l.houses.length, inInclusiveRange(3, 4));
          counts.add(l.wires.length);
          // One service wire per house (legal, upstream or loop); a hook is extra.
          for (final h in l.houses) {
            final service = l.wires.where((w) => w.house == h && w.kind != M7TtWireKind.hook).toList();
            expect(service, hasLength(1), reason: 'seed $s house $h');
            final hooks = l.wires.where((w) => w.house == h && w.kind == M7TtWireKind.hook);
            for (final hk in hooks) {
              expect(service.single.kind, isNot(M7TtWireKind.upstream));
              expect(hk.side, -service.single.side, reason: 'the hook on the other side');
            }
          }
          expect(l.wires.any((w) => w.kind == M7TtWireKind.legal && w.patched), isTrue, reason: 'old tape on a legal wire');
          // The roots are not in the houses' order (the wires cross).
          final byEnd = [...l.wires]..sort((a, b) => _geo.end(a).dx.compareTo(_geo.end(b).dx));
          final rootsInEndOrder = [for (final w in byEnd) w.rootX];
          final sorted = [...rootsInEndOrder]..sort();
          expect(rootsInEndOrder, isNot(sorted), reason: 'seed $s');
          expect(l.wires.map((w) => w.rootX).toSet(), hasLength(l.wires.length));
          kinds.addAll(l.wires.map((w) => w.kind));
          for (final w in l.wires.where((w) => w.kind == M7TtWireKind.upstream)) {
            upPatched.add(w.patched);
          }
        }
        meters.add(d.meter.kase);
        if (d.meter.kase == M7TtMeterCase.intact) intact++;
        atSend.add(d.coworkerAtSend);
        symptom.add(d.symptomFirst);
        final lanes = [for (final l in d.lanes) '${l.cond}${l.houses}${[for (final w in l.wires) '${w.house}${w.kind.index}${w.rootX}${w.patched}']}'].join('|');
        seen.add('$lanes${d.meter.kase}${d.coworkerAtSend}');
      }
      expect(seen.length, greaterThan(390));
      expect(meters, M7TtMeterCase.values.toSet());
      expect(intact / 400, inInclusiveRange(0.15, 0.35), reason: 'an intact meter about a quarter of plays');
      expect(kinds, M7TtWireKind.values.toSet());
      expect(atSend, {true, false});
      expect(symptom, {true, false});
      expect(counts, {4, 5});
      expect(upPatched, {true, false}, reason: 'old tape is no tell: an upstream wire can carry it too');
    });

    test('the trace: only from a root; along its wire to the end; off the wire it stops (the chalk stays); back along it rubs out', () {
      final r = _runOf(3);
      final w = r.lane.wires.first;
      final pts = r.pathOf(w.id, _geo);
      expect(r.grab(pts[pts.length ~/ 2], _geo), isNull, reason: 'not from the middle of a wire');
      expect(r.grab(_geo.root(w) + const Offset(0, 60), _geo), isNull);
      expect(_feed(r, w.id, upTo: 0.5), M7TtStep.moved);
      final half = r.s;
      expect(half, greaterThan(40));
      // Off the wire: it stops, the chalk stays.
      expect(r.trace(pts[pts.length ~/ 2] + const Offset(60, 0), _geo), M7TtStep.off);
      expect(r.s, half);
      // Back along it: it rubs out.
      expect(r.trace(pts[16], _geo), M7TtStep.moved);
      expect(r.s, lessThan(half));
      // A grab at the head goes on; on to the end.
      expect(r.grab(r.head(_geo)!, _geo), w.id);
      for (final p in pts.skip(16)) {
        if (r.trace(p, _geo) == M7TtStep.done) break;
      }
      expect(r.traced, isTrue);
      expect(r.spots, m7TtWireSpots(w));
      expect(r.chalk(_geo).length, greaterThan(10));
      // Traced: nothing else traces until the verdict.
      expect(r.canTrace, isFalse);
      expect(r.grab(_geo.root(r.lane.wires.last), _geo), isNull);
    });

    test('a far jump along the same wire is not followed (the finger must stay on it)', () {
      final r = _runOf(4);
      final w = r.lane.wires.first;
      final pts = r.pathOf(w.id, _geo);
      r.begin(r.grab(pts.first, _geo)!);
      expect(r.trace(pts[pts.length - 3], _geo), M7TtStep.off);
      expect(r.s, 0);
    });

    test('verdicts on a lane: pin on the theft point right; another point bounces; a pin on a legal wire and ঠিক আছে on a theft are slips', () {
      for (final kind in [M7TtWireKind.hook, M7TtWireKind.upstream, M7TtWireKind.loop]) {
        final r = _runOf(_seedLane0With(kind));
        final w = _wireOf(r, kind);
        expect(r.pin(0), (M7TtOutcome.none, null), reason: 'no pin before the trace');
        expect(_feed(r, w.id), M7TtStep.done);
        final sp = r.spots!;
        final at = sp.indexWhere(kM7TtTheftSpots.contains);
        expect(at, switch (kind) { M7TtWireKind.hook => 0, M7TtWireKind.upstream => sp.contains(M7TtSpot.patch) ? 2 : 1, _ => 2 });
        expect(sp.where(kM7TtTheftSpots.contains), hasLength(1), reason: 'one theft point per wire');
        final other = at == 0 ? 1 : 0;
        expect(r.pin(other), (M7TtOutcome.bounce, null));
        expect(r.slips, 0);
        expect(r.ok(), (M7TtOutcome.slip, Mk.okOn(m7TtWireTheft(kind)!)));
        expect(r.slips, 1);
        expect(r.traced, isTrue, reason: 'the verdict is still due');
        expect(r.pin(at), (M7TtOutcome.right, null));
        expect(r.judged, {w.id});
        expect(r.found, [m7TtWireTheft(kind)]);
        expect(r.caught, contains(L.caught(m7TtWireTheft(kind)!)));
        expect(r.traced, isFalse);
      }
      final r = _runOf(5);
      final legal = _wireOf(r, M7TtWireKind.legal);
      _feed(r, legal.id);
      expect(r.pin(0), (M7TtOutcome.slip, Mk.falsePin));
      expect(r.ok(), (M7TtOutcome.right, null));
      expect(r.judged, {legal.id});
      expect(Mk.okOn(M7TtTheft.hook), Mk.okHook);
      expect(Mk.okOn(M7TtTheft.upstream), Mk.okUpstream);
      expect(Mk.okOn(M7TtTheft.loop), Mk.okLoop);
    });

    test('the meter: through its terminals (a bypass leads past them); pin or ঠিক আছে by its case', () {
      for (final kase in M7TtMeterCase.values) {
        final r = _runOf(_seedWhere((d) => d.meter.kase == kase));
        r.round = kM7TtLanes;
        expect(r.onMeter, isTrue);
        final pts = r.pathOf(0, _geo);
        final passes = pts.any((p) => (p - _geo.meterIn).distance < 1) && pts.any((p) => (p - _geo.meterOut).distance < 1);
        expect(passes, kase != M7TtMeterCase.bypass, reason: '$kase: through the terminals or past them');
        expect(_feed(r, 0), M7TtStep.done);
        final sp = r.spots!;
        final at = sp.indexWhere(kM7TtTheftSpots.contains);
        if (kase == M7TtMeterCase.intact) {
          expect(at, -1);
          expect(r.pin(1), (M7TtOutcome.slip, Mk.falseMeter));
          expect(r.ok(), (M7TtOutcome.right, null));
        } else {
          expect(r.ok(), (M7TtOutcome.slip, Mk.okOn(m7TtMeterTheft(kase)!)));
          expect(r.pin(0), (M7TtOutcome.bounce, null), reason: 'the incoming cable is no theft point');
          expect(r.pin(at), (M7TtOutcome.right, null));
          expect(r.found, [m7TtMeterTheft(kase)]);
        }
        expect(r.meterDone, isTrue);
        expect(r.canTrace, isFalse);
      }
      expect(Mk.okOn(M7TtTheft.sealCut), Mk.missSeal);
      expect(Mk.okOn(M7TtTheft.magnet), Mk.missMagnet);
      expect(Mk.okOn(M7TtTheft.bypass), Mk.missBypass);
    });

    test('a lane ends when every wire is judged; the rounds run lane, lane, meter, report; the report needs both recipients', () {
      final r = _runOf(7);
      for (var lane = 0; lane < kM7TtLanes; lane++) {
        for (final w in r.lane.wires) {
          expect(r.laneDone, isFalse);
          _feed(r, w.id);
          final at = r.spots!.indexWhere(kM7TtTheftSpots.contains);
          at < 0 ? r.ok() : r.pin(at);
        }
        expect(r.laneDone, isTrue);
        r.nextRound();
      }
      expect(r.onMeter, isTrue);
      _feed(r, 0);
      final at = r.spots!.indexWhere(kM7TtTheftSpots.contains);
      at < 0 ? r.ok() : r.pin(at);
      r.nextRound();
      expect(r.onReport, isTrue);
      expect(r.send(), (M7TtOutcome.slip, Mk.sendBoth));
      r.toggle(M7TtWho.supervisor);
      expect(r.send(), (M7TtOutcome.slip, Mk.sendBoth));
      r.toggle(M7TtWho.vigilance);
      expect(r.send(), (M7TtOutcome.right, null));
      expect(r.caught, contains(L.caughtReport));
      expect(r.slips, 2);
      r.nextRound();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 70);
    });

    test('reasons: the first of each theft kind, the first ঠিক আছে, every meter verdict', () {
      final r = _runOf(9);
      expect(r.wantsWhy(M7TtTheft.hook), isTrue);
      expect(r.wantsWhy(M7TtTheft.hook), isFalse);
      expect(r.wantsWhy(M7TtTheft.loop), isTrue);
      expect(r.wantsWhy(null), isTrue);
      expect(r.wantsWhy(null), isFalse);
      r.round = kM7TtLanes;
      expect(r.wantsWhy(null), isTrue);
      expect(r.wantsWhy(M7TtTheft.magnet), isTrue);
    });

    test('no deadly in this level (ruling M7-6); listening to him is a slip (X2/B1)', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      final r = _runOf(1);
      expect(r.pushSlip(), Mk.pushListen);
      expect(r.slips, 1);
    });

    test('English digits; no পানি, মৃত, অন/অফ, AB বন্ধ; base + nukta; mistakes: keys, pictures, lesson points; every art file used', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.bounce,
        L.okLabel,
        L.okPreviewWire,
        L.okPreviewMeter,
        L.notebook,
        L.pinLabel,
        L.meterJob,
        for (var i = 0; i < 4; i++) L.house(i),
        L.lane(0),
        L.lane(1),
        L.reportTitle,
        L.reportTo,
        L.send,
        for (final w in M7TtWho.values) L.who(w),
        for (final x in M7TtTheft.values) L.found(x),
        for (final x in M7TtTheft.values) L.caught(x),
        L.caughtReport,
        L.caughtCall,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.allWhyWrong,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(l.contains('অন ') || l.contains('অফ '), isFalse, reason: 'ON/OFF in English: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
      }
      expect(L.house(2), 'বাড়ি 3');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.5/m7_theft_trace/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m7_theft_trace/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7TheftTracePacks.keys, ['do_7_5_a']);
    });

    test('the coworker\'s push is lesson 7.5 myth 2 word for word; the listen card is its reality', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l75 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.5');
      final myths = ((l75['content'] as Map<String, dynamic>)['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>;
      final myth2 = myths[1] as Map<String, dynamic>;
      expect(L.coworker.line, _nukta(myth2['myth'] as String));
      expect(_nukta(myth2['reality'] as String), contains('শনাক্ত করা এবং রিপোর্ট করার প্রধান দায়িত্ব'));
      expect(Mk.pushListen.textBn, contains('পুলিশ আইন-শৃঙ্খলা রক্ষায় সাহায্য করে'));
      final text = _nukta(jsonEncode(l75));
      // The lesson's own words behind the mistakes.
      for (final w in ['হুকিং', 'মিটারের আগে থেকে (Upstream)', 'চুম্বক', 'বাইপাস', 'সিল', 'ভিজিল্যান্স', 'সুপারভাইজার', 'নির্ভুল']) {
        expect(text, contains(w), reason: w);
      }
    });

    test('libraries: same length, big enough, a rule never marked wrong', () {
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(L.wrongFor.keys.toSet(), M7TtWhy.values.toSet());
      expect(L.whyQ.keys.toSet(), M7TtWhy.values.toSet());
      final sets = <String, (List<String>, List<String>)>{
        for (final e in L.whyTheft.entries) 'theft ${e.key}': (e.value, L.wrongFor[e.key.index < 3 ? M7TtWhy.theft : M7TtWhy.meterBad]!),
        for (final e in L.whyTheft.entries) 'symptom vs ${e.key}': (L.whySymptom, L.wrongFor[M7TtWhy.symptom]!),
        'legal': (L.whyLegal, L.wrongFor[M7TtWhy.legal]!),
        'meterOk': (L.whyMeterOk, L.wrongFor[M7TtWhy.meterOk]!),
        'report': (L.whyReport, L.wrongFor[M7TtWhy.report]!),
      };
      for (final e in sets.entries) {
        final (right, wrong) = e.value;
        expectSameLength('why ${e.key}', [...right, ...wrong]);
        expectLibrary(e.key, right, wrong);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      // A meter theft's cards also fit the lane pool (both questions use them).
      for (final x in [M7TtTheft.sealCut, M7TtTheft.magnet, M7TtTheft.bypass]) {
        expectSameLength('meter $x', [...L.whyTheft[x]!, ...L.wrongFor[M7TtWhy.meterBad]!]);
      }
      expectSameLength('choice', [...L.coworker.right, ...L.coworker.wrong]);
      expectLibrary('choice', L.coworker.right, L.coworker.wrong, minRight: 3);
      expect(L.coworker.asks, contains('কী করবেন?'));
      expectSameLength('recipients', [for (final w in M7TtWho.values) L.who(w)], ratio: 1.5);
    });

    test('lines: his exit is recorded; his new push and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
        L.newGuideLines,
        containsAll([L.intro, ...L.tasks, L.bounce, ...L.whyQ.values, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]),
      );
      expect(L.newGuideLines, contains('ও বলছে চুরি ধরা পুলিশের কাজ। কী বলবেন?'));
      // Every spoken line is in the lists (guide, coworker, reused clips).
      final spoken = L.spokenLines.toSet();
      for (final l in [L.intro, ...L.tasks, ...L.tapWhy, L.bounce, ...L.whyQ.values, ...L.coworker.asks, L.coworker.line, L.coworkerExit, L.callHeld, L.allSet, L.quick, L.fail, for (final m in Mk.all) m.textBn]) {
        expect(spoken, contains(l), reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_theft_trace: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the drawn places: roots apart on the line, ends on the walls in view and clear of the guide; the notebook, the report and the close-up in view', () {
      for (final h in [560.0, 640.0, 780.0, 900.0]) {
        final g = M7TtGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 184, 360, h);
        for (var s = 0; s < 60; s++) {
          final d = m7TtDeal(math.Random(s));
          for (final l in d.lanes) {
            final roots = [for (final w in l.wires) g.root(w)];
            for (final (i, a) in roots.indexed) {
              expect(a.dy, greaterThan(140), reason: 'below the header');
              for (final b in roots.skip(i + 1)) {
                expect((a - b).distance, greaterThan(2 * kM7TtGrab - 8), reason: 'roots apart');
              }
            }
            for (final w in l.wires) {
              final pts = g.wirePoints(w);
              for (final p in pts) {
                expect(p.dx, inInclusiveRange(4, 356), reason: 'h $h: $p');
              }
              final e = g.end(w);
              expect(guide.contains(e), isFalse, reason: 'h $h: an end under the guide');
              expect(e.dy, lessThan(g.groundY));
            }
          }
          final mp = g.meterPoints(d.meter);
          for (final p in mp) {
            expect(guide.contains(p), isFalse, reason: 'h $h: the close-up path under the guide');
          }
          expect(mp.first.dy, greaterThan(140));
          expect(mp.last.dy, lessThan(h - 20));
        }
        expect(g.notebook.top, greaterThan(140));
        expect(g.notebook.bottom, lessThan(h - 20));
        expect(g.notebook.left, greaterThanOrEqualTo(0));
        expect(g.notebook.right, lessThanOrEqualTo(360));
        expect(g.report.bottom, lessThan(h - 84), reason: 'h $h: the report above the guide row');
        // The ঠিক আছে box and the stations sit inside the notebook.
        expect(M7TtSketch.okBox.right, lessThanOrEqualTo(g.notebook.width));
        expect(M7TtSketch.okBox.bottom, lessThanOrEqualTo(g.notebook.height));
        expect(M7TtSketch.okBox.height, greaterThanOrEqualTo(48), reason: 'touch target ≥ 48 dp (playbook §2)');
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

    testWidgets('the guide comes first: a tap does not skip him; then the lane, no notebook yet', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7TheftTracePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.sceneLabel), findsOneWidget);
      expect(_label(L.notebook), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task a different way', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askTrace)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final flowSeeds = [
      _seedWhere((d) => !d.coworkerAtSend && d.meter.kase != M7TtMeterCase.intact && d.symptomFirst),
      _seedWhere((d) => d.coworkerAtSend && d.meter.kase == M7TtMeterCase.intact),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): two lanes, the meter, the report — traces, pins, previews, reasons; he is refused → pass', (t) async {
        final c = await _open(t, seed);
        await _playAll(t);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.mistakes, isEmpty);
        expect(s.rungProgress['7.5/do/0'], 'cleared');
        expect(s.starsByRung['7.5/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtReport), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final legalFirst = _seedWhere((d) => !d.coworkerAtSend);
    testWidgets('the notebook opens only at the wire\'s end; a pin on a legal wire is a slip with its card; ঠিক আছে then goes on', (t) async {
      final c = await _open(t, legalFirst);
      final w = _live.lane.wires.firstWhere((w) => w.kind == M7TtWireKind.legal);
      final pts = _live.pathOf(w.id, _g);
      // Half way: no notebook.
      await _dragAlong(t, pts.sublist(0, pts.length ~/ 2));
      expect(_label(L.notebook), findsNothing);
      expect(_live.traced, isFalse);
      expect(_live.s, greaterThan(0));
      // On from the head to the end.
      await _dragAlong(t, pts.sublist(pts.length ~/ 2 - 1));
      expect(_live.traced, isTrue);
      expect(_label(L.notebook), findsOneWidget);
      await _pinOn(t, 1);
      expect(find.text(Mk.falsePin.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.falsePin.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_label(L.notebook), findsOneWidget, reason: 'the verdict is still due');
      await _ok(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.judged, contains(w.id));
      await _close(t, c);
    });

    testWidgets('ঠিক আছে: a tap opens the preview and answers nothing; ✕ sets it aside; ✓ answers', (t) async {
      final c = await _open(t, legalFirst);
      final w = _live.lane.wires.firstWhere((w) => w.kind == M7TtWireKind.legal);
      await _trace(t, w.id);
      await t.tap(_label(L.okLabel));
      await _pump(t, 500);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(_live.judged, isEmpty);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(find.byWidgetPredicate((x) => x is CardAside && x.aside), findsOneWidget);
      expect(_live.judged, isEmpty);
      await _ok(t);
      expect(_live.judged, {w.id});
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, legalFirst);
      final w = _live.lane.wires.firstWhere((w) => w.kind == M7TtWireKind.legal);
      await _trace(t, w.id);
      for (var i = 0; i < 3; i++) {
        await _pinOn(t, 0);
        if (i < 2) {
          expect(find.text(Mk.falsePin.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final himAfterPin = _seedWhere((d) => !d.coworkerAtSend && !d.symptomFirst);
    testWidgets('after the first right pin\'s reason he comes; the next trace waits; listening = a slip, then the lane goes on', (t) async {
      final c = await _open(t, himAfterPin);
      final w = _live.lane.wires.firstWhere((w) => w.kind != M7TtWireKind.legal);
      await _trace(t, w.id);
      await _rightVerdict(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.allWhyRight);
      // Straight to the next wire: the drag waits for him.
      final next = _live.lane.wires.firstWhere((x) => !_live.judged.contains(x.id));
      await _trace(t, next.id);
      expect(_live.traced, isFalse, reason: 'the trace waits for him');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.text(Mk.pushListen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.pushListen.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(await _trace(t, next.id), isTrue, reason: 'after him the trace goes');
      await _close(t, c);
    });

    testWidgets('gesture hand: at the lane\'s start a sweep over the roots that presses nothing; none while the notebook preview is open', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, legalFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the lane');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(_live.active, isNull, reason: 'the hand traces nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
