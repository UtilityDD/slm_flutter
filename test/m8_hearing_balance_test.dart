// Lesson 8.1 (WBERC পরিচিতি), the Do level "জনশুনানির দাঁড়িপাল্লা": the rules
// (the file on the bench or the company's own pad; every finished sentence is a
// weight in his side's pan; the mic taken away mid-sentence drops nothing; a
// first-come order tilts the beam on most deals while a deliberate turn for the
// quiet side balances it; the foul officer; the ruling with one 30 s extension
// and no second slip; the appeal deck), the deal, the libraries, the coworker's
// single myth-2 push (listening = a slip, never deadly here), and the level in
// the shell: the guide first, a full clean play (a reason pick each, the
// coworker refused, on the file or on the first mic drag), the file on the pad,
// the officer's stamp, the tilt and its extension, three slips, the mic taken
// away mid-sentence, and the gesture hand shows how (never what) only while the
// level waits (and never at the foul moment).
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
import 'package:slm_flutter/features/game/m8_hearing_balance.dart';
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
  rungId: '8.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8HearingBalancePacks['do_8_1_b']!;
typedef L = M8HearingLines;
typedef Mk = M8HearingMistakes;

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

M8HearingRun get _live => M8HearingProbe.run!;

Future<void> _dragTo(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from);
  await g.moveBy(const Offset(0, -24));
  await t.pump(const Duration(milliseconds: 30));
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from + const Offset(0, -24), to, i / 8)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 250);
}

Future<void> _dragFile(WidgetTester t, {required bool bench}) =>
    _dragTo(t, t.getCenter(find.byKey(const ValueKey('file-box'))), t.getCenter(find.byKey(ValueKey(bench ? 'bench-target' : 'pad-target'))));

Future<void> _dragSheet(WidgetTester t, {required bool bench}) =>
    _dragTo(t, t.getCenter(find.byKey(const ValueKey('foul-sheet'))), t.getCenter(find.byKey(ValueKey(bench ? 'bench-target' : 'pad-target'))));

Future<void> _dragMic(WidgetTester t, M8Hand h) => _dragTo(t, t.getCenter(find.byKey(const ValueKey('mic'))), t.getCenter(find.byKey(ValueKey('hand-${h.id}'))));

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8HearingBalancePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8Deal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworkerMyth.right);
  await _pump(t, 2600);
}

/// The file on the bench, its reason, and (dealt on the file) the coworker.
Future<void> _proposal(WidgetTester t, M8Deal d) async {
  await _dragFile(t, bench: true);
  if (d.coworkerOn == M8CwOn.file) {
    await _refuse(t);
    expect(_live.fileDone, isFalse, reason: 'the drag waited for him');
    await _dragFile(t, bench: true);
  }
  expect(_live.fileRight, isTrue);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[M8Why.proposal]!);
  await _pump(t, 2500);
  expect(_live.phase, M8Phase.hearing);
}

/// A deliberate play: the hand that brings the pans closest to level is served
/// (the quiet side first when they are equal); nothing is served that would
/// pull a level pair apart or push a tilted one further.
M8Hand? _pickBalanced(M8HearingRun r) {
  final up = r.raisedHands;
  if (up.isEmpty) return null;
  int after(M8Hand h) {
    final left = h.sentences - r.heardOf(h);
    final o = r.office + (h.side == M8Side.office ? left : 0);
    final m = r.home + (h.side == M8Side.home ? left : 0);
    return (o - m).abs();
  }

  final sorted = [...up]..sort((a, b) {
      final c = after(a).compareTo(after(b));
      if (c != 0) return c;
      return (a.side == r.deal.quiet ? 0 : 1).compareTo(b.side == r.deal.quiet ? 0 : 1);
    });
  final best = sorted.first;
  if (r.balanced) return after(best) <= M8Timing.tolerance ? best : null;
  // Not level yet: the lighter side's turn (the quiet side when equal).
  final lighter = r.home < r.office ? M8Side.home : (r.office < r.home ? M8Side.office : r.deal.quiet);
  final mine = sorted.where((h) => h.side == lighter);
  return mine.isEmpty ? null : mine.first;
}

/// The whole hearing played in the page: balanced, the foul officer stopped, the
/// mic refused to him once (dealt on the mic).
Future<void> _hear(WidgetTester t, M8Deal d, {int maxMs = 160000}) async {
  var cw = d.coworkerOn == M8CwOn.file;
  var foulDone = false;
  for (var ms = 0; ms < maxMs && _live.phase == M8Phase.hearing; ms += 100) {
    final r = _live;
    if (r.foul == M8Foul.walking && !foulDone) {
      await _dragSheet(t, bench: true);
      foulDone = true;
      expect(r.foul, M8Foul.caught);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the foul reason');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8Why.foul]!);
      await _pump(t, 2500);
      continue;
    }
    if (r.ruleReady) break;
    if (!r.talking && r.micLockMs == 0) {
      final h = _pickBalanced(r);
      if (h != null) {
        await _dragMic(t, h);
        if (!cw) {
          cw = true;
          await _refuse(t);
          expect(r.served, 0, reason: 'the first mic drag waited for him');
          continue;
        }
        continue;
      }
    }
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// A play to the end: ruling reason, appeal deck (right card), result.
Future<void> _rulingAndAppeal(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 8000), isTrue, reason: 'the ruling reason deck');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[M8Why.bothSides]!);
  await _pump(t, 2500);
  await _appealRight(t);
}

Future<void> _appealRight(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byKey(const ValueKey('protester')), maxMs: 6000), isTrue, reason: 'the unhappy party');
  expect(_live.phase, M8Phase.appeal);
  await waitChoiceDeck(t);
  final right = L.appealRight[_live.deal.appealRight];
  await pickChoice(t, right, proceed: false);
  await _pump(t, 4000);
}

/// Everything except the hearing's clock, jumped to its end (the foul over).
void _skipHearing(M8HearingRun r) {
  r.foul = M8Foul.caught;
  r.clockMs = r.hearingMs;
}

/// A run in the hearing (the file on the bench).
M8HearingRun _hearingRun(int seed) {
  final r = M8HearingRun(m8Deal(math.Random(seed)), rng: math.Random(seed));
  r.fileDrop(M8Target.bench);
  r.startHearing();
  return r;
}

/// The hearing played in logic: [pick] chooses the next hand [gapMs] after the
/// last sentence ended; the foul officer is stopped at once.
M8HearingRun _simulate(int seed, M8Hand? Function(M8HearingRun r) pick, {int gapMs = 1500}) {
  final r = _hearingRun(seed);
  var wait = 0;
  for (var step = 0; step < 4000 && !r.ruleReady; step++) {
    if (r.foul == M8Foul.walking) r.sheetDrop(M8Target.bench);
    if (r.speaking == null) {
      wait += 100;
      if (wait >= gapMs) {
        final h = pick(r);
        if (h != null && r.serve(h.id)) wait = 0;
      }
    } else {
      wait = 0;
    }
    r.advance(100);
  }
  return r;
}

M8Hand? _firstCome(M8HearingRun r) {
  final up = r.raisedHands..sort((a, b) => a.riseMs.compareTo(b.riseMs));
  return up.isEmpty ? null : up.first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('rules', () {
    test('the deal: the loud side (dealt) has 7 short turns and the quiet 3–4 longer ones; at least 5 more sentences; its hands rise first', () {
      final loudSides = <M8Side>{};
      final cw = <M8CwOn>{};
      for (var s = 0; s < 300; s++) {
        final d = m8Deal(math.Random(s));
        loudSides.add(d.loud);
        cw.add(d.coworkerOn);
        final loud = d.hands.where((h) => h.side == d.loud).toList();
        final quiet = d.hands.where((h) => h.side == d.quiet).toList();
        expect(loud, hasLength(7), reason: 'seed $s');
        expect(quiet.length, inInclusiveRange(3, 4), reason: 'seed $s');
        expect(loud.every((h) => h.sentences >= 1 && h.sentences <= 2), isTrue);
        expect(quiet.every((h) => h.sentences >= 2 && h.sentences <= 3), isTrue);
        expect(d.sentencesOf(d.loud) - d.sentencesOf(d.quiet), greaterThanOrEqualTo(5), reason: 'seed $s');
        expect(d.sentencesOf(d.quiet), inInclusiveRange(6, 9));
        expect(d.hands.map((h) => h.id), [for (var i = 0; i < d.hands.length; i++) i], reason: 'ids follow the rising order');
        for (var i = 1; i < d.hands.length; i++) {
          expect(d.hands[i].riseMs, greaterThanOrEqualTo(d.hands[i - 1].riseMs));
        }
        expect(d.hands.take(3).every((h) => h.side == d.loud), isTrue, reason: 'first come = the loud side (seed $s)');
        for (final side in M8Side.values) {
          final seats = d.hands.where((h) => h.side == side).map((h) => h.seat).toList();
          expect(seats.toSet(), hasLength(seats.length), reason: 'one seat each');
          expect(seats.every((x) => x >= 0 && x < M8Geo.seatsPerSide), isTrue);
        }
        // The hearing is too short to hear everyone, long enough for a balanced plan.
        const sent = M8Timing.sentenceMs;
        final all = d.hands.fold(0, (a, h) => a + h.sentences);
        expect(d.hearingMs, lessThan(all * sent + 10 * 1000), reason: 'seed $s');
        expect(d.hearingMs, greaterThan(2 * d.sentencesOf(d.quiet) * sent), reason: 'seed $s');
        expect(d.hearingMs, inInclusiveRange(45000, 75000));
        expect(d.foulAtMs, inInclusiveRange((d.hearingMs * 0.3).round(), (d.hearingMs * 0.56).round()));
        for (final h in d.hands) {
          expect(h.riseMs, lessThan((d.hearingMs * 0.62).round()), reason: 'every hand rises in time to be heard');
        }
      }
      expect(loudSides, {M8Side.office, M8Side.home});
      expect(cw, {M8CwOn.file, M8CwOn.mic});
    });

    test('plays differ: sentences, looks, seats, the foul time, the appeal party and the right phrasing are dealt', () {
      final times = <int>{};
      final foul = <int>{};
      final sentences = <String>{};
      final seats = <int>{};
      final parties = <M8Side>{};
      final phr = <int>{};
      for (var s = 0; s < 80; s++) {
        final d = m8Deal(math.Random(s));
        times.add(d.hearingMs);
        foul.add(d.foulAtMs);
        parties.add(d.appealSide);
        phr.add(d.appealRight);
        for (final h in d.hands) {
          sentences.addAll(h.lines);
          seats.add(h.seat);
        }
      }
      expect(times.length, greaterThan(3));
      expect(foul.length, greaterThan(40));
      expect(sentences.length, greaterThan(20));
      expect(seats.length, 9);
      expect(parties, {M8Side.office, M8Side.home});
      expect(phr, {0, 1});
    });

    test('the file: on the bench = right (once); on the company\'s own pad = a slip (R7, myth 1) and the file is gone from the hand', () {
      final r = M8HearingRun(m8Deal(math.Random(1)));
      expect(r.fileDrop(M8Target.bench).ready, isTrue);
      expect(r.fileRight, isTrue);
      expect(r.caught, [L.caughtFile]);
      expect(r.fileDrop(M8Target.pad).ready, isFalse, reason: 'dropped once');
      expect(r.slips, 0);
      final p = M8HearingRun(m8Deal(math.Random(2)));
      final s = p.fileDrop(M8Target.pad);
      expect(s.mistake, Mk.fileOnPad);
      expect(p.slips, 1);
      expect(p.fileRight, isFalse);
      expect(p.caught, isEmpty);
      expect(p.phase, M8Phase.proposal);
      p.startHearing();
      expect(p.phase, M8Phase.hearing, reason: 'the file walks itself to the bench');
    });

    test('no mic before the hearing, none on a seated speaker; a hand serves from its rise; a sentence takes 2.8 s and drops one weight', () {
      final r = M8HearingRun(m8Deal(math.Random(3)));
      expect(r.serve(0), isFalse, reason: 'still the proposal');
      r.fileDrop(M8Target.bench);
      r.startHearing();
      final first = r.hands.first;
      expect(r.raised(first), isFalse, reason: 'his hand is not up at 0');
      expect(r.serve(first.id), isFalse);
      while (!r.raised(first)) {
        r.advance(100);
      }
      expect(r.raisedHands, contains(first));
      expect(r.serve(first.id), isTrue);
      expect(r.talking, isTrue);
      r.advance(2700);
      expect(r.office + r.home, 0, reason: 'not yet');
      r.advance(100);
      expect(r.office + r.home, 1);
      expect(r.weightsOf(first.side), 1);
      expect(r.heardOf(first), 1);
    });

    test('a hand with two sentences goes on talking and drops two weights; then his hand is down and the mic is free', () {
      final d = m8Deal(math.Random(5));
      final r = M8HearingRun(d)
        ..fileDrop(M8Target.bench)
        ..startHearing();
      final h = r.hands.firstWhere((x) => x.sentences == 2);
      while (!r.raised(h)) {
        r.advance(100);
      }
      r.serve(h.id);
      for (var i = 0; i < 60; i++) {
        r.advance(100);
      }
      expect(r.heardOf(h), 2);
      expect(r.weightsOf(h.side), 2);
      expect(r.speaking, isNull);
      expect(r.raised(h), isFalse);
      expect(r.serve(h.id), isFalse, reason: 'he has said it all');
    });

    test('taking the mic away mid-sentence drops nothing; a sentence done before stays; the mic can go back to him', () {
      final r = _hearingRun(7);
      final h = r.hands.first;
      while (!r.raised(h)) {
        r.advance(100);
      }
      r.serve(h.id);
      r.advance(M8Timing.sentenceMs - 200);
      r.pullMic();
      expect(r.talking, isFalse);
      r.advance(5000);
      expect(r.office + r.home, 0, reason: 'nothing dropped while the mic is away');
      r.dropAway();
      expect(r.speaking, isNull);
      expect(r.heardOf(h), 0);
      r.advance(3000);
      expect(r.office + r.home, 0, reason: 'nobody is speaking');
      // A sentence that finished before the mic left stays; the next one is lost.
      final two = r.hands.firstWhere((x) => x.sentences == 2 && r.raised(x));
      r.serve(two.id);
      r.advance(M8Timing.sentenceMs);
      expect(r.office + r.home, 1);
      r.advance(1000);
      r.pullMic();
      r.advance(M8Timing.sentenceMs);
      expect(r.office + r.home, 1, reason: 'the unfinished sentence dropped nothing');
      expect(r.serve(two.id), isTrue, reason: 'back to him: the sentence starts afresh');
      r.advance(M8Timing.sentenceMs);
      expect(r.heardOf(two), 2);
    });

    test('the beam: positive for more home weights, clamped, level at 0; level needs both pans loaded and a difference of at most one', () {
      final r = _hearingRun(1);
      expect(r.angle, 0);
      expect(r.balanced, isFalse, reason: 'empty pans are not a ruling');
      r.office = 3;
      r.home = 0;
      expect(r.angle, lessThan(0));
      expect(r.balanced, isFalse);
      r.office = 2;
      r.home = 3;
      expect(r.angle, greaterThan(0));
      expect(r.balanced, isTrue);
      r.office = 9;
      r.home = 2;
      expect(r.angle, -0.42);
      expect(r.balanced, isFalse);
      r.office = 1;
      r.home = 1;
      expect(r.balanced, isFalse, reason: 'both pans must hold real weight');
    });

    test('serving the hands in the order they rise tilts the beam on most deals; a deliberate turn for the quiet side levels it on every deal', () {
      var firstTilted = 0;
      var balancedOk = 0;
      var slowOk = 0;
      const n = 300;
      for (var s = 0; s < n; s++) {
        final a = _simulate(s, _firstCome);
        if (!a.balanced) firstTilted++;
        final b = _simulate(s, _pickBalanced);
        if (b.balanced) balancedOk++;
        expect(b.balanced, isTrue, reason: 'seed $s: office ${b.office} home ${b.home}');
        if (_simulate(s, _pickBalanced, gapMs: 2500).balanced) slowOk++;
      }
      debugPrint('M8 first-come tilts $firstTilted of $n deals; balanced play levels $balancedOk of $n, a slow player (2.5 s a turn) $slowOk');
      expect(firstTilted / n, greaterThan(0.85), reason: 'first come, first served must fail on most deals');
      expect(balancedOk, n);
      expect(slowOk / n, greaterThan(0.9), reason: 'a slower player still has time to balance');
    });

    test('the foul officer: he leaves at the dealt time and reaches his pad in 5 s; the sheet on the bench = right, on the pad = a slip', () {
      final r = _hearingRun(11);
      expect(r.foul, M8Foul.none);
      while (r.clockMs < r.deal.foulAtMs - 100) {
        r.advance(100);
      }
      expect(r.foul, M8Foul.none);
      r.advance(100);
      expect(r.foul, M8Foul.walking);
      r.advance(M8Timing.foulWindowMs - 200);
      expect(r.foul, M8Foul.walking);
      expect(r.pendingSlip, isNull);
      r.advance(300);
      expect(r.foul, M8Foul.stamped);
      expect(r.pendingSlip, Mk.officerStamp, reason: 'he reached the pad first');
      expect(r.slips, 1);
      expect(r.sheetDrop(M8Target.bench).ready, isFalse, reason: 'too late');
      // On the bench in time.
      final c = _hearingRun(11);
      while (c.foul != M8Foul.walking) {
        c.advance(100);
      }
      c.advance(2000);
      final ok = c.sheetDrop(M8Target.bench);
      expect(ok.ready, isTrue);
      expect(ok.mistake, isNull);
      expect(c.foul, M8Foul.caught);
      expect(c.caught, contains(L.caughtRate));
      c.advance(8000);
      expect(c.pendingSlip, isNull);
      expect(c.slips, 0);
      // On his own pad: he stamps.
      final p = _hearingRun(11);
      while (p.foul != M8Foul.walking) {
        p.advance(100);
      }
      final bad = p.sheetDrop(M8Target.pad);
      expect(bad.mistake, Mk.officerStamp);
      expect(p.foul, M8Foul.stamped);
      expect(p.slips, 1);
      p.advance(8000);
      expect(p.slips, 1, reason: 'one slip, not two');
    });

    test('no ruling before the officer is dealt with, the hearing time is up and the speaker is done (or everyone has been heard)', () {
      final r = _hearingRun(4);
      r.clockMs = r.hearingMs;
      expect(r.ruleReady, isFalse, reason: 'the foul moment never came');
      r.foul = M8Foul.caught;
      expect(r.ruleReady, isTrue);
      r.speaking = r.hands.first.id;
      expect(r.ruleReady, isFalse, reason: 'he is still talking');
      r.speaking = null;
      final e = _hearingRun(4);
      e.foul = M8Foul.caught;
      for (final h in e.hands) {
        e.heard[h.id] = h.sentences;
      }
      expect(e.clockMs, lessThan(e.hearingMs));
      expect(e.ruleReady, isTrue, reason: 'everyone was heard');
    });

    test('the ruling: level = the order and the praise; tilted the first time = a slip, 30 s more and fresh hands; tilted again = no second slip', () {
      final r = _hearingRun(21);
      r.foul = M8Foul.caught;
      r.clockMs = r.hearingMs;
      final first = r.hearingMs;
      r.office = 7;
      r.home = 1;
      final a = r.rule();
      expect(a.levelled, isFalse);
      expect(a.mistake, Mk.tilt);
      expect(r.slips, 1);
      expect(r.phase, M8Phase.hearing);
      expect(r.hearingMs, first + M8Timing.extendMs);
      expect(r.ruleReady, isFalse, reason: '30 s more hearing');
      final late = r.hands.where((h) => h.late).toList();
      expect(late, isNotEmpty);
      expect(late.every((h) => h.side == M8Side.home), isTrue, reason: 'the lighter side raises fresh hands');
      expect(late.fold(0, (s, h) => s + h.sentences), greaterThanOrEqualTo(6));
      expect(late.every((h) => h.riseMs > first && !r.shown(h) == (h.riseMs > r.clockMs)), isTrue);
      for (final side in M8Side.values) {
        final seats = r.hands.where((h) => h.side == side).map((h) => h.seat).toList();
        expect(seats.toSet(), hasLength(seats.length), reason: 'fresh hands take free seats');
      }
      // Hear the fresh hands: the beam levels.
      var guard = 0;
      while (!r.ruleReady && guard++ < 2000) {
        final up = r.raisedHands.where((h) => h.late);
        if (r.speaking == null && up.isNotEmpty) r.serve(up.first.id);
        r.advance(100);
        if (r.balanced && r.speaking == null) break;
      }
      expect(r.balanced, isTrue, reason: 'office ${r.office} home ${r.home}');
      r.clockMs = r.hearingMs;
      r.speaking = null;
      expect(r.ruleReady, isTrue);
      final b = r.rule();
      expect(b.levelled, isTrue);
      expect(b.mistake, isNull);
      expect(r.slips, 1);
      expect(r.caught, containsAll([L.caughtBoth, L.caughtRate]));
      // Still tilted at the second ruling: no second slip.
      final t = _hearingRun(22);
      t.foul = M8Foul.caught;
      t.clockMs = t.hearingMs;
      t.rule();
      t.clockMs = t.hearingMs;
      expect(t.ruleReady, isTrue);
      final c = t.rule();
      expect(c.levelled, isFalse);
      expect(c.mistake, isNull);
      expect(t.slips, 1, reason: 'the same tilt is not slipped twice');
      expect(t.phase, M8Phase.ruling);
      expect(t.caught, isNot(contains(L.caughtBoth)));
    });

    test('hearing only one side: a slip; empty pans: a slip; the tilt cannot be bought back with the loud side', () {
      for (final side in M8Side.values) {
        final r = _hearingRun(30);
        r.foul = M8Foul.caught;
        r.clockMs = r.hearingMs;
        if (side == M8Side.office) {
          r.office = 9;
        } else {
          r.home = 9;
        }
        expect(r.rule().mistake, Mk.tilt, reason: '$side only');
      }
    });

    test('the appeal: the right place ends the play with the APTEL line; every wrong place is its own slip; only after the ruling', () {
      final r = _hearingRun(40);
      expect(r.appealPick(right: true), isNull);
      expect(r.phase, M8Phase.hearing, reason: 'not the time');
      r.foul = M8Foul.caught;
      r.clockMs = r.hearingMs;
      r.office = 5;
      r.home = 5;
      expect(r.rule().levelled, isTrue);
      r.startAppeal();
      expect(r.phase, M8Phase.appeal);
      expect(r.appealPick(right: false), Mk.wrongAppeal);
      expect(r.slips, 1);
      expect(r.phase, M8Phase.appeal, reason: 'the same deck goes on');
      expect(r.appealPick(right: true), isNull);
      expect(r.done, isTrue);
      expect(r.appealRight, isTrue);
      expect(r.caught, contains(L.caughtAppeal));
      expect(r.percent, 85);
      expect(r.passed, isTrue);
      expect(r.thorough, isFalse);
    });

    test('listening to him is a slip here, never deadly (M8-1, X2/B1); the mic lies in the aisle for 10 s of hearing; the mark falls 15 a slip', () {
      expect(Mk.listenMyth.deadly, isFalse);
      final r = _hearingRun(8);
      final h = r.hands.first;
      while (!r.raised(h)) {
        r.advance(100);
      }
      expect(r.pushSlip(), Mk.listenMyth);
      expect(r.slips, 1);
      expect(r.percent, 85);
      expect(r.micLockMs, M8Timing.micLockMs);
      expect(r.serve(h.id), isFalse, reason: 'the mic lies in the aisle');
      r.advance(9900);
      expect(r.serve(h.id), isFalse);
      r.advance(200);
      expect(r.micLockMs, 0);
      expect(r.serve(h.id), isTrue);
      r.pushSlip();
      r.pushSlip();
      expect(r.percent, 55);
      expect(r.passed, isFalse, reason: 'not finished');
    });

    test('a clean play passes with 100', () {
      final r = _simulate(3, _pickBalanced);
      expect(r.balanced, isTrue);
      expect(r.rule().levelled, isTrue);
      r.startAppeal();
      expect(r.appealPick(right: true), isNull);
      expect(r.percent, 100);
      expect(r.passed, isTrue);
      expect(r.thorough, isTrue);
    });
  });

  group('content', () {
    test('libraries: every reason set within 1.3x, ≥ 2 right and ≥ 5 wrong, the coworker\'s cards and the appeal deck too', () {
      for (final w in M8Why.values) {
        expectSameLength('why $w', [...L.whyRight[w]!, ...L.whyWrong[w]!]);
        expectLibrary('why $w', L.whyRight[w]!, L.whyWrong[w]!);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.whyWrong[w]!, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.allWhyRight.toSet().intersection(L.allWhyWrong.toSet()), isEmpty);
      expect(L.whyQ.values, ['প্রস্তাবটা কমিশনের টেবিলে কেন দিলেন?', 'কেন দুই পক্ষকেই মাইক দিলেন?', 'কোম্পানির অফিসারকে রেটে সিল মারতে দিলেন না কেন?']);
      expectSameLength('appeal', [...L.appealRight, ...L.appealWrong]);
      expectLibrary('appeal', L.appealRight, L.appealWrong);
      final cw = L.coworkerMyth;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong, minRight: 2);
    });

    test('the speakers\' captions: 14 per side, no duplicates, short, no verdict on who is right', () {
      for (final side in M8Side.values) {
        final lines = L.says(side);
        expect(lines, hasLength(14));
        expect(lines.toSet(), hasLength(14));
        for (final l in lines) {
          expect(l.length, lessThan(45), reason: l);
        }
      }
      expect({...L.officeSays}.intersection({...L.homeSays}), isEmpty);
    });

    test('English digits only; jol not pani; base + nukta; ON/OFF; DEAD not mrito; every mistake has its picture; no deadly; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.rulingAnnounced,
        L.moreHearing,
        L.hearingEnds,
        ...L.tapWhy,
        L.bannerLabel,
        L.fileLabel,
        L.sheetLabel,
        L.benchLabel,
        L.padLabel,
        L.micLabel,
        L.sceneLabel,
        L.orderLabel,
        L.protest,
        L.hand(3),
        ...L.officeSays,
        ...L.homeSays,
        ...L.appealRight,
        ...L.appealWrong,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.allWhyWrong,
        ...L.coworkerMyth.recordedLines,
        ...L.coworkerMyth.right,
        ...L.coworkerMyth.wrong,
        ...L.coworkerMyth.asks,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtFile,
        L.caughtBoth,
        L.caughtRate,
        L.caughtAppeal,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp('[Ѐ-ӿऀ-ॿ஀-௿؀-ۿ]').hasMatch(l), isFalse, reason: l);
        expect(RegExp('(^| )(অন|অফ)( |\$)').hasMatch(l), isFalse, reason: 'ON/OFF in English letters: $l');
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('মরা'), isFalse, reason: l);
        expect(l.contains('সরকারি'), isFalse, reason: 'the commission is independent: $l');
        expect(RegExp('এলটি|এইচটি|কেভি').hasMatch(l), isFalse, reason: 'LT/HT/kV in English letters: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'M8-1: 8.1 is slip-only');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.1/m8_hearing_balance/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 4));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_hearing_balance/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n != '.gitkeep').toSet();
      expect(files, used);
      expect(m8HearingBalancePacks.keys, ['do_8_1_b']);
    });

    test('the five slips are exactly the spec\'s; the coworker\'s line is the live myth 2 word for word + his shortcut; the cards quote the live text', () {
      expect(Mk.all.map((m) => m.key.split('/').last).toSet(), {'file-on-pad', 'officer-stamp', 'tilt', 'wrong-appeal', 'listen-myth'});
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync(encoding: utf8)) as List<dynamic>;
      final l81 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.1');
      final content = l81['content'] as Map;
      final myths = (content['myth_buster'] as Map)['myths'] as List<dynamic>;
      String norm(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');
      expect(norm(L.coworkerMyth.line), startsWith(norm((myths[1] as Map)['myth'] as String).replaceAll('।', '')));
      final reality2 = norm((myths[1] as Map)['reality'] as String);
      expect(reality2, contains('সাপ্লাই কোড'));
      expect(reality2, contains('CEA-এর সেফটি রেগুলেশন'));
      expect(norm(L.coworkerMyth.right.first), contains('সাপ্লাই কোড'));
      expect(norm(L.coworkerMyth.right.last), contains(norm('আইন না জানলে নিজের অজান্তেই অপরাধ')));
      final all = norm(jsonEncode(l81));
      expect(all, contains(norm('একদিকে গ্রাহকের স্বার্থ')));
      expect(all, contains(norm('নতুন রেট ঘোষণা করে')));
      expect(all, contains('APTEL'));
      expect(all, contains(norm('বিশেষ আদালত')));
      expect(norm(Mk.tilt.textBn), contains('একদিকে গ্রাহকের স্বার্থ, অন্যদিকে কোম্পানির স্থায়িত্ব'));
      expect(Mk.officerStamp.textBn, contains('কোম্পানি শুধু প্রস্তাব দেয়'));
    });

    test('rival lines: his exit is recorded; his myth push and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['WBERC শুধুমাত্র বড় অফিসারদের ব্যাপার, লাইনম্যানদের এতে কোনো ভূমিকা নেই — চলো, চা খেয়ে আসি।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, L.rulingAnnounced, L.moreHearing, L.hearingEnds, ...L.whyQ.values, 'সাথীর কথা শুনবেন?', L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_hearing_balance: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the world: figures, tables, targets and the bubble leave the aisle clear on every screen height; targets are 48 dp or more', () {
      for (final h in [600.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M8Geo.forScene(h, 0);
        expect(g.bench.overlaps(g.padTarget), isFalse, reason: 'the two targets are separate');
        expect(g.bench.width, greaterThanOrEqualTo(48));
        expect(g.padTarget.width, greaterThanOrEqualTo(48));
        expect(g.padTarget.height, greaterThanOrEqualTo(48));
        expect(g.bench.height, closeTo(g.padTarget.height, 10), reason: 'equal weight on screen');
        for (final side in M8Side.values) {
          for (var i = 0; i < M8Geo.seatsPerSide; i++) {
            final s = g.seat(side, i);
            expect(s.bottom, lessThan(560), reason: 'seat $i');
            expect(s.overlaps(g.trainee), isFalse);
            expect(s.overlaps(g.micHome), isFalse);
            expect(s.overlaps(g.fileHome), isFalse);
            expect(s.overlaps(g.protester), isFalse);
            expect(s.top, greaterThan(g.bubble.bottom), reason: 'the caption sits above the seats');
            for (var j = i + 1; j < M8Geo.seatsPerSide; j++) {
              expect(s.overlaps(g.seat(side, j)), isFalse);
            }
          }
        }
        expect(g.trainee.overlaps(g.micHome), isFalse);
        expect(g.trainee.overlaps(g.fileHome), isFalse);
        expect(g.micHome.width, greaterThanOrEqualTo(44));
        expect(g.bubble.top, greaterThan(g.bench.bottom));
        expect(g.balance.bottom, lessThanOrEqualTo(g.bench.top));
      }
    });
  });

  group('page', () {
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the hall, the bench and the pad (equal), the file, the balance', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8HearingBalancePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 800);
      expect(find.byKey(const ValueKey('bench-target')), findsOneWidget);
      expect(find.byKey(const ValueKey('pad-target')), findsOneWidget);
      expect(find.byKey(const ValueKey('file-box')), findsOneWidget);
      expect(find.byKey(const ValueKey('balance')), findsOneWidget);
      expect(find.byKey(const ValueKey('proposal-officer')), findsOneWidget);
      expect(find.byKey(const ValueKey('mic')), findsNothing, reason: 'the mic comes with the hearing');
      expect(_live.phase, M8Phase.proposal);
      expect(_label(L.benchLabel), findsOneWidget);
      expect(_label(L.padLabel), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.mic);
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final said = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        said.add(c.read(guideDirectorProvider).line);
      }
      expect(said.every((l) => l.contains(L.askFile)), isTrue, reason: '$said');
      expect(said.first, isNot(said.last));
      await _close(t, c);
    });

    // A play with the coworker on the file and one with him on the first mic drag.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerOn == M8CwOn.file),
      _seedWhere((d) => d.coworkerOn == M8CwOn.mic),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed, coworker on the ${m8Deal(math.Random(seed)).coworkerOn.name}): file, both sides heard, the foul stopped, a reason each, the coworker refused → pass', (t) async {
        final d = m8Deal(math.Random(seed));
        final c = await _open(t, seed);
        await _proposal(t, d);
        await _hear(t, d);
        expect(_live.balanced, isTrue, reason: 'office ${_live.office} home ${_live.home}');
        expect(_live.foul, M8Foul.caught);
        await _rulingAndAppeal(t);
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.1/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.1/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtFile), findsOneWidget);
        expect(find.text(L.caughtBoth), findsOneWidget);
        expect(find.text(L.caughtRate), findsOneWidget);
        expect(find.text(L.caughtAppeal), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the file on the company\'s own stamp pad: a slip card (the file does not move on its own to the bench first), then the hearing begins', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.mic);
      final c = await _open(t, seed);
      await _dragFile(t, bench: false);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.fileOnPad.textBn), findsOneWidget);
      expect(_live.phase, M8Phase.proposal);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no reason for a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.phase, M8Phase.hearing);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.fileOnPad.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      expect(find.byKey(const ValueKey('mic')), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the proposal\'s reason: a wrong card burns the table (no slip), a right retry pays 5', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.mic);
      final c = await _open(t, seed);
      await _dragFile(t, bench: true);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await waitChoiceDeck(t);
      final wrong = [for (final w in L.whyWrong[M8Why.proposal]!) if (_label(w).evaluate().isNotEmpty) _label(w)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'a wrong reason is not a strike');
      await _pickRight(t, L.whyRight[M8Why.proposal]!);
      await _pump(t, 2500);
      expect(_live.phase, M8Phase.hearing);
      await _close(t, c);
    });

    testWidgets('the officer reaches his pad: a slip card; the clock waited; the hearing goes on', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      _live.clockMs = d.foulAtMs - 200;
      await _pump(t, 600);
      expect(_live.foul, M8Foul.walking);
      expect(find.byKey(const ValueKey('foul-officer')), findsOneWidget);
      await _pump(t, M8Timing.foulWindowMs + 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.officerStamp.textBn), findsOneWidget);
      expect(_live.foul, M8Foul.stamped);
      final clock = _live.clockMs;
      await _pump(t, 4000);
      expect(_live.clockMs, clock, reason: 'the hearing clock is paused while the card shows');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byKey(const ValueKey('foul-officer')), findsNothing);
      expect(_live.clockMs, greaterThan(clock));
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.officerStamp.key);
      await _close(t, c);
    });

    testWidgets('the sheet dragged onto the pad: the same slip', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      _live.clockMs = d.foulAtMs - 200;
      await _pump(t, 700);
      expect(_live.foul, M8Foul.walking);
      await _dragSheet(t, bench: false);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.officerStamp.textBn), findsOneWidget);
      expect(_live.slips, 1);
      await _close(t, c);
    });

    testWidgets('the tilt: a slip card, then 30 s more with fresh hands; level then = the order; tilted again = no second slip', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      _skipHearing(_live);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.tilt.textBn), findsOneWidget);
      expect(_live.extended, isTrue);
      expect(_live.hands.any((h) => h.late), isTrue);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(_live.phase, M8Phase.hearing);
      expect(find.byType(MistakeCard), findsNothing);
      // Hear the fresh hands.
      for (var k = 0; k < 400 && !(_live.balanced && !_live.talking); k++) {
        final up = _live.raisedHands.where((h) => h.late);
        if (!_live.talking && up.isNotEmpty) {
          await _dragMic(t, up.first);
        } else {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      expect(_live.balanced, isTrue, reason: 'office ${_live.office} home ${_live.home}');
      _live.clockMs = _live.hearingMs;
      await _pump(t, 800);
      expect(c.read(gameSaveProvider).mistakes.length, 1, reason: 'one slip for the tilt');
      await _rulingAndAppeal(t);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['8.1/do/1'], 'cleared');
      expect(s.mistakes.single.key, Mk.tilt.key);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('tilted at both rulings: one slip only, the order comes without the praise or a reason, then the appeal', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      _skipHearing(_live);
      await _pump(t, 600);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      _live.clockMs = _live.hearingMs;
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing, reason: 'no second slip for the same tilt');
      expect(_live.slips, 1);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('protester')), maxMs: 6000), isTrue);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the appeal deck, not a reason deck');
      await _appealRight(t);
      await _pump(t, 2500);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtBoth), findsNothing);
      await _close(t, c);
    });

    testWidgets('the mic taken away mid-sentence drops nothing; a sentence finished stays in the pan', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      for (var k = 0; k < 300 && _live.raisedHands.isEmpty; k++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final h = _live.raisedHands.first;
      await _dragMic(t, h);
      expect(_live.talking, isTrue);
      expect(find.text(h.lines.first), findsWidgets, reason: 'his caption');
      await _pump(t, 1200);
      // Lift the mic off him and let go on the floor.
      final from = t.getCenter(find.byKey(const ValueKey('mic')));
      await _dragTo(t, from, const Offset(190, 640));
      expect(_live.speaking, isNull, reason: 'he stopped: the mic is back');
      await _pump(t, M8Timing.sentenceMs + 1000);
      expect(_live.office + _live.home, 0, reason: 'nothing dropped');
      expect(find.byType(MistakeCard), findsNothing, reason: 'not a slip');
      // Serve him again: one sentence is a weight.
      await _dragMic(t, h);
      await _pump(t, M8Timing.sentenceMs + 600);
      expect(_live.office + _live.home, 1);
      await _close(t, c);
    });

    testWidgets('the coworker on the first mic drag: that drag waits for him; listening is a slip; the mic lies in the aisle for 10 s and nobody is served', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.mic);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      for (var k = 0; k < 300 && _live.raisedHands.isEmpty; k++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final h = _live.raisedHands.first;
      await _dragMic(t, h);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      expect(_live.served, 0, reason: 'he cut in before the first serve');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = [for (final w in L.coworkerMyth.wrong) if (_label(w).evaluate().isNotEmpty) _label(w)];
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.listenMyth.textBn), findsOneWidget);
      expect(_live.micLockMs, greaterThan(0));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      final lock = _live.micLockMs;
      await _pump(t, 3000);
      expect(_live.micLockMs, lessThan(lock));
      expect(find.byType(Draggable<String>).evaluate().where((e) => (e.widget as Draggable<String>).data == 'mic'), isEmpty, reason: 'the mic lies in the aisle');
      await _pump(t, 8000);
      expect(_live.micLockMs, 0);
      expect(find.byKey(const ValueKey('mic')), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listenMyth.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('three slips (the file on the pad, the tilt, a wrong appeal) strike the level out', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.mic);
      final c = await _open(t, seed);
      await _dragFile(t, bench: false);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      _skipHearing(_live);
      await _pump(t, 600);
      expect(find.text(Mk.tilt.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      _live.clockMs = _live.hearingMs;
      expect(await _pumpUntil(t, find.byKey(const ValueKey('protester')), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = [for (final w in L.appealWrong) if (_label(w).evaluate().isNotEmpty) _label(w)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.where((m) => m.deadly), isEmpty);
      await _close(t, c);
    });

    testWidgets('a wrong place for the appeal: a slip card, the same deck goes on, the right card ends the play', (t) async {
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      await _proposal(t, d);
      _live
        ..foul = M8Foul.caught
        ..office = 5
        ..home = 5
        ..clockMs = _live.hearingMs;
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 6000), isTrue, reason: 'the ruling reason');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8Why.bothSides]!);
      await _pump(t, 2500);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('protester')), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = [for (final w in L.appealWrong) if (_label(w).evaluate().isNotEmpty) _label(w)];
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.wrongAppeal.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(_live.phase, M8Phase.appeal);
      await _appealRight(t);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['8.1/do/1'], 'cleared');
      expect(s.mistakes.single.key, Mk.wrongAppeal.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: the file waits: a nudge up, then a sweep over the bench AND the pad alike; none at the foul moment; a raised hand: a nudge, then a sweep over all raised hands', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerOn == M8CwOn.file);
      final d = m8Deal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'idle with the file in hand');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await t.tapAt(const Offset(30, 600));
      await t.pump(const Duration(milliseconds: 200));
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      await _pump(t, 26000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions.length, 2, reason: 'a sweep over the bench and the pad alike');
      // The proposal done, the hearing: hands up and the mic idle.
      GestureHints.debugEnableInTests = false;
      await _proposal(t, d);
      GestureHints.debugEnableInTests = true;
      for (var k = 0; k < 400 && _live.raisedHands.length < 2; k++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(_live.raisedHands.length, greaterThanOrEqualTo(2));
      var sweep = false;
      for (var k = 0; k < 4 && !sweep; k++) {
        await _pump(t, 9000);
        if (scene().showing && scene().debugOptions.isNotEmpty) {
          sweep = true;
          final up = _live.raisedHands;
          expect(scene().debugOptions.length, up.length, reason: 'every raised hand alike, both sides');
          expect({for (final h in up) h.side}.length, greaterThanOrEqualTo(1));
        }
        await t.tapAt(const Offset(190, 640));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(sweep, isTrue, reason: 'the sweep over the raised hands came');
      // The foul moment: no hand.
      _live.clockMs = d.foulAtMs - 200;
      await _pump(t, 800);
      expect(_live.foul, M8Foul.walking);
      for (var k = 0; k < 3; k++) {
        await _pump(t, 1400);
        expect(scene().showing, isFalse, reason: 'no hint at the foul moment');
      }
      await _close(t, c);
    });
  });
}
