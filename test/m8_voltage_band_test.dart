// Lesson 8.4 (গ্রিড কোড), কাজ 2 "ভোল্টেজ সীমায় রাখো": the rules (the entry is
// right inside the band, +6 % / -9 % per the live lesson; a low round also
// needs the capacitor bank ON; normal rounds are right untouched; stray steps
// out of the band, a wrong entry and listening to the coworker are the only
// slips; nothing here is deadly), the deal (never 6-9 %, 1-3 steps, the
// capacitor lamp tells nothing alone), the libraries, the drawn places, and
// the level in the shell: the guide first, hold-steps and the twist switch, a
// full clean play (a reason pick each round, the coworker refused), the
// consequence close-ups, three slips, listening to him, the pen waiting for
// him on a fast play, and the gesture hand while the level waits.
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_voltage_band.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '8.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8VoltageBandPacks['do_8_4_b']!;
typedef L = M8VoltageBandLines;
typedef Mk = M8VoltageBandMistakes;

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
M8VbGeo get _geo => M8VbGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8VbRun get _live => M8VoltageBandProbe.run!;

/// Press and hold [r] (the ring is full at 0.8 s), then let go.
Future<void> _hold(WidgetTester t, Rect r, {int ms = 1000}) async {
  final g = await t.startGesture(r.center * _k);
  await _pump(t, ms);
  await g.up();
  await _pump(t, 700);
}

/// A short tap on [r]: down and up well before the ring is full.
Future<void> _short(WidgetTester t, Rect r) async {
  final g = await t.startGesture(r.center * _k);
  await t.pump(const Duration(milliseconds: 120));
  await g.up();
  await _pump(t, 200);
}

/// Twist the capacitor switch: a drag across it.
Future<void> _twist(WidgetTester t) async {
  final from = _geo.cap.center * _k;
  final to = from + const Offset(70, 0);
  final g = await t.startGesture(from);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 800);
}

Future<void> _pen(WidgetTester t) async {
  await t.tapAt(_geo.pen.center * _k);
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8VoltageBandPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8VbDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8VbDeal(math.Random(s))));

/// The coworker is on screen: refuse him.
Future<void> _refuse(WidgetTester t, M8VbPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
  expect(find.byType(CoworkerPeek), findsNothing);
}

/// Listen to him (a wrong card, confirmed).
Future<void> _listen(WidgetTester t, M8VbPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  final wrong = _onScreen(L.coworker(p).wrong);
  expect(wrong, isNotEmpty);
  await t.tap(wrong.first, warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 800);
}

/// One round played right (the coworker refused if he is dealt on it).
Future<void> _playRound(WidgetTester t, M8VbDeal d, int i) async {
  final his = d.coworkerRound == i;
  Future<void> maybeHim() async {
    if (his && find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t, d.push);
  }

  final r = d.rounds[i];
  await maybeHim();
  if (r.kind == M8VbKind.low) {
    await _twist(t);
    expect(_live.capOn, isTrue, reason: 'the bank ON');
  }
  var guard = 0;
  while (!_live.inBand && guard++ < 6) {
    await maybeHim();
    final before = _live.tap;
    await _hold(t, _live.kv > d.bus.hi ? _geo.lower : _geo.raise);
    expect(_live.tap, isNot(before), reason: 'a hold steps the tap');
  }
  expect(_live.inBand, isTrue, reason: 'round $i in the band');
  await maybeHim();
  await _pen(t);
  if (his && !_live.roundDone) {
    // The pen waited for him.
    await _refuse(t, d.push);
    await _pen(t);
  }
  final why = _live.why;
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
  expect(_live.roundDone, isTrue, reason: 'round $i written');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (round $i)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[why]!);
  await _pump(t, 3000);
}

/// A run of three rounds as given (kv per round; the coworker on the third).
M8VbRun _runOf(List<M8VbRound> rounds, {M8VbBus bus = M8VbBus.kv11}) =>
    M8VbRun(M8VbDeal(bus: bus, rounds: rounds, coworkerRound: 2, push: M8VbPush.logIt));

M8VbRound _r(M8VbKind k, double kv, {bool? cap, int tap = 5}) =>
    M8VbRound(kind: k, startKv: kv, startTap: tap, capStartOn: cap ?? (k == M8VbKind.high));

List<M8VbRound> _three(M8VbRound a) => [a, _r(M8VbKind.normal, 11.0), _r(M8VbKind.normal, 11.0)];

void main() {
  group('rules', () {
    test('band and steps: +6 % / -9 % of the declared value, 1.5 % a step, the bank a little', () {
      for (final b in M8VbBus.values) {
        expect(b.hi, closeTo(b.nominal * 1.06, 1e-9));
        expect(b.lo, closeTo(b.nominal * 0.91, 1e-9));
        expect(b.step, closeTo(b.nominal * 0.015, 1e-9));
        expect(b.capRise, lessThan(b.step), reason: 'the bank adds less than one step');
        expect(b.capRise, greaterThan(0));
      }
      expect(M8VbBus.kv11.label, '11 kV');
      expect(M8VbBus.kv33.label, '33 kV');
    });

    test('deals: one bus, at least one high and one low, 1-3 steps, never 6-9 %, the lamp tells nothing alone, plays differ', () {
      final seen = <String>{};
      final pushes = <M8VbPush>{};
      final buses = <M8VbBus>{};
      final his = <int>{};
      final normalCap = <bool>{};
      final capAlone = <bool>{};
      final orders = <String>{};
      for (var s = 0; s < 400; s++) {
        final d = m8VbDeal(math.Random(s));
        final kinds = [for (final r in d.rounds) r.kind];
        expect(d.rounds, hasLength(3));
        expect(kinds, contains(M8VbKind.high));
        expect(kinds, contains(M8VbKind.low));
        for (final r in d.rounds) {
          final pct = (r.startKv / d.bus.nominal - 1) * 100;
          final (lo, hi) = m8VbPool(d.bus, r.kind);
          expect(r.startKv, inInclusiveRange(lo - 0.006, hi + 0.006));
          expect(r.startTap, inInclusiveRange(4, 6));
          switch (r.kind) {
            case M8VbKind.high:
              expect(pct, greaterThanOrEqualTo(7), reason: 'high rounds are +7 % or more, never 6-9 %');
              expect(r.capStartOn, isTrue, reason: 'the bank starts ON in a high round');
              expect(r.stepsNeeded(d.bus), inInclusiveRange(1, 3));
            case M8VbKind.low:
              expect(pct, lessThanOrEqualTo(-9.999), reason: 'low rounds are -10 % or less');
              expect(r.capStartOn, isFalse, reason: 'the bank starts OFF in every low round');
              expect(r.stepsNeeded(d.bus), inInclusiveRange(1, 3));
              capAlone.add(r.capAloneHelps(d.bus));
            case M8VbKind.normal:
              expect(pct, inInclusiveRange(-5, 5));
              normalCap.add(r.capStartOn);
              expect(r.stepsNeeded(d.bus), 0);
              // The bank ON alone keeps a normal round inside the band.
              expect(r.startKv + d.bus.capRise, lessThanOrEqualTo(d.bus.hi));
          }
        }
        expect(d.coworkerRound, inInclusiveRange(0, 2));
        pushes.add(d.push);
        buses.add(d.bus);
        his.add(d.coworkerRound);
        orders.add(kinds.map((k) => k.index).join());
        seen.add('${d.bus.index}|${d.rounds.map((r) => '${r.kind.index}${r.startKv}${r.startTap}${r.capStartOn}').join()}|${d.coworkerRound}${d.push.index}');
      }
      expect(seen.length, greaterThan(300));
      expect(pushes, M8VbPush.values.toSet());
      expect(buses, M8VbBus.values.toSet());
      expect(his, {0, 1, 2});
      expect(normalCap, {true, false}, reason: 'the bank is OFF in about half of the normal rounds');
      expect(capAlone, {true, false}, reason: 'the bank alone helps on some low deals, not on others');
      expect(orders.length, greaterThan(6), reason: 'random order');
    });

    test('a high round: written at once = a slip with the LA / insulator close-up; stepped down into the band = right (tapDown)', () {
      final a = _runOf(_three(_r(M8VbKind.high, 12.1)));
      expect(a.inBand, isFalse);
      expect(a.insetNow, M8VbInset.high);
      expect(a.log(), Mk.highLogged);
      expect(a.closedWrong, isTrue);
      expect(a.roundDone, isTrue);
      expect(a.slips, 1);
      expect(a.entries[0], 12.1, reason: 'written as it stands');
      final b = _runOf(_three(_r(M8VbKind.high, 12.1)));
      for (var i = 0; i < 2; i++) {
        expect(b.step(-1), isTrue);
        expect(b.inBand, isFalse, reason: 'two steps are not enough from 12.1 (11.77)');
      }
      expect(b.step(-1), isTrue);
      expect(b.kv, closeTo(12.1 - 3 * 0.165, 1e-9));
      expect(b.inBand, isTrue);
      expect(b.insetNow, isNull);
      expect(b.log(), isNull);
      expect(b.slips, 0);
      expect(b.why, M8VbWhy.tapDown);
      expect(b.caught, [L.caughtHigh]);
    });

    test('a low round: the bank OFF written = a slip even when the taps fixed it; ON and in the band = right; ON but still out = the low slip with the pump close-up', () {
      final a = _runOf(_three(_r(M8VbKind.low, 9.7)));
      expect(a.step(1), isTrue);
      expect(a.step(1), isTrue);
      expect(a.inBand, isTrue, reason: 'two steps fix 9.7 (10.03)');
      expect(a.capOn, isFalse);
      expect(a.insetNow, isNull, reason: 'no close-up: the voltage is fine');
      expect(a.log(), Mk.capOffLow);
      expect(a.closedWrong, isTrue);
      final b = _runOf(_three(_r(M8VbKind.low, 9.7)));
      expect(b.twistCap(), isTrue);
      expect(b.kv, closeTo(9.7 + 11 * 0.012, 1e-9));
      expect(b.inBand, isFalse, reason: 'not enough alone on this deal');
      expect(b.insetNow, M8VbInset.low);
      expect(b.step(1), isTrue);
      expect(b.inBand, isFalse, reason: '9.832 + 0.165 = 9.997 is still below -9 %');
      expect(b.step(1), isTrue);
      expect(b.inBand, isTrue);
      expect(b.log(), isNull);
      expect(b.why, M8VbWhy.tapUpCap);
      expect(b.caught, [L.caughtLow]);
      final c = _runOf(_three(_r(M8VbKind.low, 9.7)));
      c.twistCap();
      expect(c.log(), Mk.lowLogged);
      expect(c.insetNow, M8VbInset.low);
      // The tap stops at the end of its range (nothing moves, nothing costs).
      final d = _runOf(_three(_r(M8VbKind.high, 12.1)));
      for (var i = 0; i < 9; i++) {
        d.step(-1);
      }
      expect(d.note, M8VbNote.tapEnd);
      expect(d.tap, 1);
      expect(d.stepsUsed, 4);
      expect(d.slips, 0);
    });

    test('a low round the bank alone fixes: twist and write, nothing else (capOn)', () {
      final r = _runOf(_three(_r(M8VbKind.low, 9.9)));
      expect(r.twistCap(), isTrue);
      expect(r.inBand, isTrue);
      expect(r.log(), isNull);
      expect(r.stepsUsed, 0);
      expect(r.why, M8VbWhy.capOn);
      expect(M8VbRound(kind: M8VbKind.low, startKv: 9.9, startTap: 5, capStartOn: false).capAloneHelps(M8VbBus.kv11), isTrue);
      expect(M8VbRound(kind: M8VbKind.low, startKv: 9.7, startTap: 5, capStartOn: false).capAloneHelps(M8VbBus.kv11), isFalse);
    });

    test('a normal round: written untouched = right (noChange); only the bank ON = right (capOn); stray steps out of the band then written = a slip', () {
      final a = _runOf([_r(M8VbKind.normal, 11.1, cap: false), _r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7)]);
      expect(a.log(), isNull);
      expect(a.why, M8VbWhy.noChange);
      expect(a.slips, 0);
      expect(a.caught, [L.caughtNormal]);
      final b = _runOf([_r(M8VbKind.normal, 11.4, cap: false), _r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7)]);
      expect(b.twistCap(), isTrue);
      expect(b.inBand, isTrue, reason: 'the bank ON never takes a normal round out');
      expect(b.log(), isNull);
      expect(b.why, M8VbWhy.capOn);
      final c = _runOf([_r(M8VbKind.normal, 11.4, cap: true), _r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7)]);
      c.step(1);
      expect(c.inBand, isTrue, reason: '11.4 + 0.165 = 11.565 is still inside');
      c.step(1);
      expect(c.inBand, isFalse, reason: '11.73 is above +6 %');
      expect(c.insetNow, M8VbInset.high);
      expect(c.log(), Mk.highLogged);
      final d = _runOf([_r(M8VbKind.normal, 11.0, cap: true), _r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7)]);
      d.step(1);
      d.step(-1);
      expect(d.log(), isNull);
      expect(d.why, M8VbWhy.inBand, reason: 'a step and back, written in the band');
    });

    test('the bank is never switched OFF: twisting it again says it is ON and changes nothing', () {
      final r = _runOf([_r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7), _r(M8VbKind.normal, 11.0)]);
      expect(r.capOn, isTrue);
      expect(r.twistCap(), isFalse);
      expect(r.note, M8VbNote.capAlready);
      expect(r.capOn, isTrue);
      expect(r.capTurned, isFalse);
    });

    test('listening to him: the entry is written as it stands and the one slip is his push (the close-up belongs to it)', () {
      final a = _runOf(_three(_r(M8VbKind.high, 12.1)));
      expect(a.insetNow, M8VbInset.high);
      expect(a.listen(M8VbPush.logIt), Mk.listenLogIt);
      expect(a.slips, 1);
      expect(a.entries[0], 12.1);
      expect(a.closedWrong, isTrue);
      expect(a.roundDone, isTrue);
      final b = _runOf([_r(M8VbKind.normal, 11.0), _r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7)]);
      expect(b.insetNow, isNull, reason: 'in the band: just the slip');
      expect(b.listen(M8VbPush.skipTap), Mk.listenSkipTap);
      expect(b.slips, 1);
      expect(Mk.push(M8VbPush.logIt).deadly, isFalse);
      expect(Mk.push(M8VbPush.skipTap).deadly, isFalse);
    });

    test('three slips and the play fails (55 passes); every slip closes its round; next round starts clean', () {
      final r = _runOf([_r(M8VbKind.high, 12.1), _r(M8VbKind.low, 9.7), _r(M8VbKind.high, 12.2)]);
      expect(r.log(), isNotNull);
      expect(r.thorough, isFalse);
      expect(r.log(), isNull, reason: 'the round is closed');
      expect(r.step(-1), isFalse);
      r.next();
      expect(r.index, 1);
      expect(r.thorough, isTrue);
      expect(r.tap, 5);
      expect(r.capOn, isFalse);
      expect(r.stepsUsed, 0);
      expect(r.log(), isNotNull);
      r.next();
      expect(r.log(), isNotNull);
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue, reason: 'done, no deadly, 55 passes (the 3rd slip strikes out on the page)');
      expect(M8VbRun(M8VbDeal(bus: M8VbBus.kv11, rounds: [for (var i = 0; i < 3; i++) _r(M8VbKind.high, 12.1)], coworkerRound: 0, push: M8VbPush.logIt)).passed, isFalse);
    });

    test('perfect play from any deal: at most 3 steps (+ the bank on low), no slip, the reason fits what was done', () {
      for (var s = 0; s < 400; s++) {
        final d = m8VbDeal(math.Random(s));
        final r = M8VbRun(d);
        for (var i = 0; i < 3; i++) {
          final round = d.rounds[i];
          if (round.kind == M8VbKind.low) expect(r.twistCap(), isTrue);
          var n = 0;
          while (!r.inBand) {
            expect(r.step(r.kv > d.bus.hi ? -1 : 1), isTrue);
            n++;
            expect(n, lessThanOrEqualTo(3), reason: 'seed $s round $i');
          }
          final why = r.why;
          expect(r.log(), isNull, reason: 'seed $s round $i');
          expect(L.whyRight.containsKey(why), isTrue);
          expect(switch (round.kind) {
            M8VbKind.high => why == M8VbWhy.tapDown,
            M8VbKind.low => why == M8VbWhy.tapUpCap || why == M8VbWhy.capOn,
            M8VbKind.normal => why == M8VbWhy.noChange,
          }, isTrue);
          r.next();
        }
        expect(r.slips, 0);
        expect(r.passed, isTrue);
        expect(r.percent, 100);
      }
    });

    test('the dial: numerals only, the needle angle runs 80-120 % of the declared value', () {
      for (final b in M8VbBus.values) {
        expect(m8VbFrac(b, b.nominal * 0.8), 0);
        expect(m8VbFrac(b, b.nominal * 1.2), closeTo(1, 1e-9));
        expect(m8VbFrac(b, b.nominal), closeTo(0.5, 1e-9));
        expect(m8VbFrac(b, b.nominal * 2), 1);
      }
      expect(m8VbReading(11.2), '11.2');
      expect(m8VbReading(34.0), '34.0');
    });

    test('English digits only; jol not pani; owner terms; nukta form; every mistake has its picture; nothing deadly; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        for (final n in M8VbNote.values) L.note(n),
        L.raise,
        L.lower,
        L.panelLabel,
        for (var n = 1; n <= 3; n++) L.entryLabel(n),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8VbPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtHigh,
        L.caughtLow,
        L.caughtNormal,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|অন-|-অন|অন ').hasMatch(l), isFalse, reason: 'ON / OFF in English: $l');
        expect(l.contains('বন্ধ'), isFalse, reason: 'বন্ধ on a switch reads as OFF: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'য় ড় ঢ় as base + nukta: $l');
        expect(RegExp('কেভি|এলটি|এইচটি').hasMatch(l), isFalse, reason: 'kV, LT, HT in English letters: $l');
      }
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'M8-1: nothing in 8.4 is deadly');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.4/m8_voltage_band/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(m8VbLessonPoint, inInclusiveRange(0, 3));
      const dir = 'assets/game/art/m8_voltage_band/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m8VoltageBandPacks.keys, ['do_8_4_b']);
      expect(_pack.titleBn, L.title);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(L.myths.length, greaterThanOrEqualTo(5));
      for (final w in M8VbWhy.values) {
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

    test('rival lines: his exit is recorded; his two new pushes and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'ভোল্টেজ একটু কম-বেশি হলে কিছু যায় আসে না, খাতায় লিখে দাও!',
        'ট্যাপ চেঞ্জার দেখার দরকার নেই, কাল যা ছিল তাই আছে!',
      ]);
      expect({for (final p in M8VbPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      // Every line the guide speaks in this level: new ones listed, the rest
      // already recorded (shared kit lines).
      final spoken = <String>[
        L.intro,
        ...L.tasks,
        for (final n in M8VbNote.values) L.note(n),
        ...L.whyQ.values,
        for (final cw in L.allCoworkers) ...cw.asks,
        for (final p in M8VbPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.quick,
        ...L.tapWhy,
      ];
      for (final l in spoken) {
        expect(L.newGuideLines.contains(l) || LearnVoice.resolve(l) != null, isTrue, reason: 'unlisted spoken line: $l');
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_voltage_band: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, clear of the header, the guide and his bubble', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M8VbGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final bubble = Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81);
        final hits = g.controls;
        for (final r in [...hits, g.tapBox, g.meter, g.window, g.oltc]) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
        }
        for (final r in hits) {
          expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the guide row');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          if (h >= 700) expect(r.overlaps(bubble), isFalse, reason: 'h $h: $r under the bubble');
        }
        for (final (i, a) in hits.indexed) {
          for (final b in hits.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        expect(g.raise.height, greaterThanOrEqualTo(48));
        expect(g.lower.height, greaterThanOrEqualTo(48));
        expect(g.raise.width, greaterThanOrEqualTo(48));
        expect(g.pen.height, greaterThanOrEqualTo(48));
        expect(g.cap.height, greaterThanOrEqualTo(48));
        expect(g.raise.overlaps(g.tapBox), isFalse);
        expect(g.lower.overlaps(g.tapBox), isFalse);
        expect(g.insetBox.bottom, lessThan(g.meter.bottom + 150));
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

    testWidgets('the guide comes first: a tap does not skip him; then the panel is there and nothing is written', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M8VoltageBandPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsNothing);
      expect(_live.entries, [null, null, null]);
      expect(_live.slips, 0);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    // The hold buttons and the twist switch: on a seed whose first round has
    // no coworker (he would take the stage).
    final calm = _seedWhere((d) => d.coworkerRound != 0 && d.rounds[0].kind != M8VbKind.normal);
    testWidgets('a short tap on RAISE / LOWER does nothing; a hold steps one position; a touch on the bank without a twist does nothing, a twist puts it ON', (t) async {
      final c = await _open(t, calm);
      final tap0 = _live.tap;
      final kv0 = _live.kv;
      await _short(t, _geo.raise);
      await _short(t, _geo.lower);
      expect(_live.tap, tap0, reason: 'short taps do nothing');
      expect(_live.kv, kv0);
      await _hold(t, _geo.raise);
      expect(_live.tap, tap0 + 1);
      expect(_live.kv, closeTo(kv0 + _live.bus.step, 1e-9));
      await _hold(t, _geo.lower);
      expect(_live.tap, tap0);
      expect(_live.kv, closeTo(kv0, 1e-9));
      // A hold let go before the ring is full: nothing.
      await _hold(t, _geo.raise, ms: 500);
      expect(_live.tap, tap0);
      final capOn0 = _live.capOn;
      await t.tapAt(_geo.cap.center * _k);
      await _pump(t, 400);
      expect(_live.capOn, capOn0, reason: 'a plain touch on the switch does not turn it');
      if (!capOn0) {
        await _twist(t);
        expect(_live.capOn, isTrue);
        expect(_live.kv, closeTo(kv0 + _live.bus.capRise, 1e-9));
      } else {
        await _twist(t);
        expect(_live.capOn, isTrue, reason: 'never switched OFF');
      }
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    // One play with each push on each kind of round.
    final flowSeeds = [
      _seedWhere((d) => d.push == M8VbPush.logIt && d.rounds[d.coworkerRound].kind == M8VbKind.high),
      _seedWhere((d) => d.push == M8VbPush.skipTap && d.rounds[d.coworkerRound].kind == M8VbKind.low),
      _seedWhere((d) => d.push == M8VbPush.logIt && d.rounds[d.coworkerRound].kind == M8VbKind.normal && !d.rounds[d.coworkerRound].capStartOn),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three rounds, hold-steps, the bank, the entry, reasons; he is refused → pass', (t) async {
        final d = m8VbDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRound(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.4/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.4/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final highFirst = _seedWhere((d) => d.rounds[0].kind == M8VbKind.high && d.coworkerRound != 0);
    testWidgets('a wrong entry on a high round: the LA / insulator close-up first, then the slip card; the round is closed as written', (t) async {
      final c = await _open(t, highFirst);
      await _pen(t);
      expect(find.byKey(const ValueKey('inset-high')), findsOneWidget, reason: 'the close-up comes first');
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(MistakeCard)), isTrue);
      expect(find.byKey(const ValueKey('inset-high')), findsNothing);
      expect(find.text(Mk.highLogged.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.highLogged.key);
      expect(s.mistakes.single.deadly, isFalse);
      expect(_live.entries[0], isNotNull);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(_live.index, 1, reason: 'on to the next round');
      expect(_live.tap, _live.round.startTap);
      await _close(t, c);
    });

    final lowFirst = _seedWhere((d) => d.rounds[0].kind == M8VbKind.low && d.coworkerRound != 0);
    testWidgets('a low round: logged out of the band = the pump close-up; fixed by the taps but the bank OFF = the card, no close-up', (t) async {
      final c = await _open(t, lowFirst);
      await _pen(t);
      expect(find.byKey(const ValueKey('inset-low')), findsOneWidget, reason: 'the pump smokes');
      expect(await _pumpUntil(t, find.byType(MistakeCard)), isTrue);
      expect(find.text(Mk.lowLogged.textBn), findsOneWidget);
      await _close(t, c);
      final c2 = await _open(t, lowFirst);
      var guard = 0;
      while (!_live.inBand && guard++ < 5) {
        await _hold(t, _geo.raise);
      }
      expect(_live.inBand, isTrue);
      expect(_live.capOn, isFalse);
      await _pen(t);
      expect(find.byKey(const ValueKey('inset-low')), findsNothing, reason: 'in the band: no close-up');
      expect(find.byKey(const ValueKey('inset-high')), findsNothing);
      expect(find.text(Mk.capOffLow.textBn), findsOneWidget);
      expect(c2.read(gameSaveProvider).mistakes.last.key, Mk.capOffLow.key);
      await _close(t, c2);
    });

    final allOut = _seedWhere((d) => d.rounds.every((r) => r.kind != M8VbKind.normal));
    testWidgets('three slips strike the level out (a wrong entry each round; the coworker listened to)', (t) async {
      final d = m8VbDeal(math.Random(allOut));
      final c = await _open(t, allOut);
      for (var i = 0; i < 3; i++) {
        if (d.coworkerRound == i && find.byType(CoworkerPeek).evaluate().isEmpty) {
          await _pen(t); // the pen waits for him
        }
        if (d.coworkerRound == i) {
          await _listen(t, d.push);
        } else {
          await _pen(t);
        }
        expect(await _pumpUntil(t, find.byType(MistakeCard), maxMs: 6000) || find.byType(StruckOutCard).evaluate().isNotEmpty, isTrue, reason: 'slip $i');
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 800);
          expect(_live.index, i + 1, reason: 'the next round');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, hasLength(3));
      expect(s.mistakes.every((x) => !x.deadly), isTrue);
      expect(s.rungProgress['8.4/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    final hisFirst = _seedWhere((d) => d.coworkerRound == 0);
    testWidgets('a fast play: the pen waits for the coworker, he cuts in at once; after him the entry is written', (t) async {
      final c = await _open(t, hisFirst, settle: false);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he is not here yet');
      await _pen(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.entries[0], isNull, reason: 'nothing was written');
      expect(_live.roundDone, isFalse);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworker(_live.deal.push).right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_live.coworkerMoment, isTrue);
      await _pen(t);
      expect(_live.entries[0], isNotNull, reason: 'after him the entry is written');
      expect(c.read(gameSaveProvider).mistakes.every((x) => x.key.startsWith('8.4/m8_voltage_band/')), isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him writes the entry as it stands: one slip, his push, the card; the round moves on', (t) async {
      final c = await _open(t, hisFirst, settle: false);
      await _pen(t);
      await _listen(t, _live.deal.push);
      expect(await _pumpUntil(t, find.byType(MistakeCard), maxMs: 6000), isTrue);
      final key = Mk.push(_live.deal.push).key;
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, key);
      expect(_live.slips, 1, reason: 'the close-up belongs to the same slip');
      expect(_live.entries[0], isNotNull);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(_live.index, 1);
      await _close(t, c);
    });

    testWidgets('the reason deck takes no touch; a hold on the panel behind it does nothing', (t) async {
      final d = m8VbDeal(math.Random(calm));
      final c = await _open(t, calm);
      final r = d.rounds[0];
      if (r.kind == M8VbKind.low) await _twist(t);
      var guard = 0;
      while (!_live.inBand && guard++ < 6) {
        await _hold(t, _live.kv > d.bus.hi ? _geo.lower : _geo.raise);
      }
      await _pen(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      final tap = _live.tap;
      await t.startGesture(_geo.raise.center * _k).then((g) async {
        await _pump(t, 1000);
        await g.up();
      });
      expect(_live.tap, tap, reason: 'locked while the ◆ waits and the deck is up');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle shows a sweep that presses nothing; two short taps on RAISE give a hold hand; a touch on the bank gives a nudge', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, calm);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the panel');
      // The sweep glides over RAISE, LOWER, the bank and the pen alike.
      expect(scene().debugOptions.length, anyOf(0, 4), reason: 'never a pick');
      expect(scene().debugFrame?.ripple, isNull, reason: 'the sweep presses nothing');
      expect(_live.slips, 0);
      // Two short taps on RAISE: a hold hand on THAT button.
      await _short(t, _geo.raise);
      await _short(t, _geo.raise);
      await _pump(t, 200);
      expect(scene().showing, isTrue, reason: 'two short taps');
      expect(scene().debugOptions, isEmpty, reason: 'a hold hand, not a sweep');
      var ring = false;
      for (var i = 0; i < 80 && !ring; i++) {
        await t.pump(const Duration(milliseconds: 50));
        ring = scene().debugFrame?.ring != null;
      }
      expect(ring, isTrue, reason: 'the ring fills on RAISE');
      expect(_live.tap, _live.round.startTap, reason: 'a hint presses nothing');
      // The bank touched without a twist: a short generic nudge.
      await t.tapAt(_geo.cap.center * _k);
      await _pump(t, 200);
      expect(scene().showing, isTrue, reason: 'a touch on the bank');
      expect(scene().debugOptions, isEmpty);
      var trail = false;
      for (var i = 0; i < 80 && !trail; i++) {
        await t.pump(const Duration(milliseconds: 50));
        trail = scene().debugFrame?.trailFrom != null;
      }
      expect(trail, isTrue, reason: 'a drag nudge over the bank');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
