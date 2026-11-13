// The Module 5 rank gate "অ্যাডভান্সডের ডকেট: এক রাতের কেস" (m5_gate_case): the
// deal (six cases from lesson facts, night/day, clues never conflicting, the
// pole top's damage, varied over seeds), the dispatch engine's rules (every
// deadly and slip of the module table, one slip per move), the option
// libraries (lengths within 1.3×), English digits, the coworker's lines
// (recorded or listed for the director), the mistakes, and the page: the guide
// first, idle = zero frames (with and without reduced motion), a full clean
// case to the rank-up (incl. reason picks, the coworker held and refused), a
// deadly move (freeze → near-miss), three slips (strike-out), and the gesture
// hint (a sweep over the four tools that presses nothing).
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
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_gate_case.dart';
import 'package:slm_flutter/features/game/m5_gate_case_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: 'm5/gate',
  kind: CatalogRungKind.gate,
  lessonId: '5.10',
  lessonTitleBn: '',
  ladderStep: 150,
);

final _pack = m5GateCasePacks['gate_m5']!;

int _seedWhere(bool Function(M5Deal d) ok) {
  for (var s = 1; s < 6000; s++) {
    if (ok(dealM5(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

/// A run with the deal of the first seed that meets [ok].
M5Run _runWhere(bool Function(M5Deal d) ok) => M5Run(dealM5(math.Random(_seedWhere(ok))));

const _van = M5Chip.van;
M5Spot _s(int i) => M5Spot.section(i);

/// Gathers the clues, takes the PTW, reads the FPI pair: a clean start.
void _cleanStart(M5Run r) {
  for (final a in m5InfoAsks) {
    r.ask(a);
  }
  if (r.kase.lockOut) {
    r.ask(M5Ask.ptw);
    r.placePtw();
  }
  if (r.deal.hasFpi) {
    for (final i in r.deal.fpiPair) {
      expect(r.dispatch(_van, M5Spot.fpiAt(i), M5Order.fpi).mistake, isNull);
    }
  }
}

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

/// Pumps until [ok] or [maxMs] (no failure).
Future<void> _wait(WidgetTester t, bool Function() ok, {int maxMs = 3500}) async {
  for (var ms = 0; ms < maxMs && !ok(); ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _waitDeckUp(WidgetTester t) async {
  final cards = find.descendant(of: find.byType(ChoiceDeck), matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.button ?? false)));
  await _until(t, () => cards.hitTestable().evaluate().length == 3, maxMs: 10000, reason: 'deck up');
}

/// Taps the right card of the deck now up (and its এগিয়ে যান when there is one).
Future<void> _pickRight(WidgetTester t, M5GateProbe p) async {
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
  await _pump(t, 300);
}

Future<void> _tapKey(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await t.tap(f, warnIfMissed: false);
  await t.pump();
  await _pump(t, 150);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, M5GateProbe probe) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M5GateCasePage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
  )));
  await _pump(t, 600);
  await waitIntro(t);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Phone → one menu item.
Future<void> _phone(WidgetTester t, M5Ask a) async {
  await _tapKey(t, 'm5-tool-phone');
  await _tapKey(t, 'm5-ask-${a.name}');
}

/// Chip → map spot → order → hold the radio.
Future<void> _dispatch(WidgetTester t, M5Chip c, M5Spot s, M5Order o) async {
  await _tapKey(t, 'm5-chip-${c.name}');
  await _tapKey(t, 'm5-spot-${s.id}');
  await _tapKey(t, 'm5-order-${o.name}');
  await t.longPress(find.byKey(const ValueKey('m5-send')), warnIfMissed: false);
  await t.pump();
}

void main() {
  group('rules', () {
    test('the deal: six cases from lesson facts, clues never missing, damage per case, varied', () {
      final sigs = <String>{};
      final cases = <M5Case>{};
      final pushes = <M5Push>{};
      var nightLock = 0, dayLock = 0, fpi = 0, knock = 0;
      for (var s = 0; s < 400; s++) {
        final d = dealM5(math.Random(s));
        cases.add(d.kase);
        pushes.add(d.push);
        expect(d.hasFpi || d.customersClue || d.repeats, isTrue, reason: 'a clue names the place');
        expect(d.k, inInclusiveRange(0, 3));
        expect(d.villages.toSet(), hasLength(4));
        expect(d.menu.toSet(), M5Ask.values.toSet(), reason: 'the menu is always complete');
        expect(d.orders.contains(M5Order.lightsOff), d.night);
        expect(d.orders.toSet().length, d.orders.length);
        expect(d.ugSteps.toSet(), M5UgStep.values.toSet());
        for (final i in d.decoys.keys) {
          expect(i, isNot(d.k), reason: 'a decoy is never at the fault');
        }
        expect(d.decoys.length, inInclusiveRange(1, 2));
        switch (d.kase) {
          case M5Case.storm:
            expect(d.wooded, contains(d.k));
            expect(d.damages.values.toSet().difference({M5Damage.branch, M5Damage.puncture}), isEmpty);
            expect(d.damages.values, contains(d.culprit));
          case M5Case.clear:
            expect(d.culprit, isIn([M5Damage.bird, M5Damage.melted]));
          case M5Case.wind:
            expect(d.damages.values.toList(), [M5Damage.clash]);
          case M5Case.fallen:
            expect(d.damages.values, contains(M5Damage.broken));
          case M5Case.cable:
            expect(d.k, d.ugAt, reason: 'the UG fault is at the road crossing');
            expect(d.damages, isEmpty);
          case M5Case.night:
            expect(d.night, isTrue);
            expect(d.push, M5Push.waitMorning, reason: 'lesson 5.7 myth at night');
            expect(d.damages, isEmpty);
        }
        if (d.kase.closeView) {
          expect(d.worn.length, inInclusiveRange(1, 2));
          expect(d.worn.intersection(d.damages.keys.toSet()), isEmpty, reason: 'a look-alike is sound');
          if (d.knockOn) knock++;
        }
        if (!d.night) expect(d.push, M5Push.chargeDay);
        if (d.kase.lockOut) d.night ? nightLock++ : dayLock++;
        if (d.hasFpi) fpi++;
        sigs.add('${d.kase.name}${d.night}${d.k}${d.hasFpi}${d.customersClue}${d.repeats}${d.damages}${d.villages.join()}${d.menu.first}');
      }
      expect(cases, M5Case.values.toSet());
      expect(pushes, M5Push.values.toSet());
      expect(nightLock, greaterThan(40));
      expect(dayLock, greaterThan(40));
      expect(fpi, inInclusiveRange(120, 320));
      expect(knock, greaterThan(30));
      expect(sigs.length, greaterThan(380), reason: 'every play dealt fresh');
    });

    test('deadly: hands before the PTW, climb before the earth, charging a faulted line or with crew on it', () {
      final lock = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      lock.ask(M5Ask.relay);
      final o = lock.dispatch(_van, _s(0), M5Order.earth);
      expect(o.mistake, M5GateMistakes.handsNoPtw.m);
      expect(o.deadly, isTrue);
      expect(lock.ended, isTrue);

      final climb = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      _cleanStart(climb);
      expect(climb.dispatch(_van, _s(climb.deal.k), M5Order.climb).mistake, M5GateMistakes.climbNoEarth.m);

      final charge = _runWhere((d) => d.kase == M5Case.clear && !d.night);
      _cleanStart(charge);
      expect(charge.ask(M5Ask.charge).mistake, M5GateMistakes.chargeFault.m, reason: 'R8: before the fault is found and repaired');

      final crew = _runWhere((d) => d.kase == M5Case.wind && !d.night);
      _cleanStart(crew);
      final k = crew.deal.k;
      crew.dispatch(_van, _s(k), M5Order.look);
      crew.dispatch(_van, _s(k), M5Order.earth);
      expect(crew.dispatch(_van, _s(k), M5Order.climb).closeView, isTrue);
      crew.cvPick(M5Part.span, right: true);
      expect(crew.cvDone(), isNull);
      expect(crew.repaired, isTrue);
      final lc = M5Run(crew.deal)..repaired = true..up = true;
      expect(lc.ask(M5Ask.lineClear).mistake, M5GateMistakes.clearCrewUp.m, reason: 'line clear with the crew up');
      final ch = M5Run(crew.deal)..repaired = true..earthed.add(k);
      expect(ch.ask(M5Ask.charge).mistake, M5GateMistakes.chargeCrew.m, reason: 'R12: an earth still on');
      final noClear = M5Run(crew.deal)..repaired = true;
      expect(noClear.ask(M5Ask.charge).mistake, M5GateMistakes.chargeCrew.m, reason: 'R12: before line clear');
    });

    test('deadly: the fallen wire zone, the live line (case F), the megger on a cable not isolated', () {
      final wire = _runWhere((d) => d.kase == M5Case.fallen && !d.night);
      _cleanStart(wire);
      final k = wire.deal.k;
      wire.dispatch(_van, _s(k), M5Order.look);
      expect(wire.located, isTrue);
      expect(wire.dispatch(_van, _s(k), M5Order.earth).mistake, M5GateMistakes.wireZone.m, reason: 'R13: before the far cordon');

      final live = _runWhere((d) => d.kase == M5Case.night);
      live.ask(M5Ask.relay);
      expect(live.dispatch(_van, _s(live.deal.k), M5Order.climb).mistake, M5GateMistakes.climbLive.m, reason: 'R19/R7');

      final ug = _runWhere((d) => d.kase == M5Case.cable);
      _cleanStart(ug);
      expect(ug.ug(M5UgStep.megger).mistake, M5GateMistakes.meggerLive.m, reason: 'R23');
      final ug2 = _runWhere((d) => d.kase == M5Case.cable);
      ug2.ask(M5Ask.relay);
      expect(ug2.ug(M5UgStep.isolate).mistake, M5GateMistakes.handsNoPtw.m, reason: 'R1: isolating without the PTW');
    });

    test('slips: one per move — no PTW patrol, blind start, blind patrol, lone night mate, needless order, hands before the find', () {
      final a = _runWhere((d) => d.kase == M5Case.clear && !d.night);
      expect(a.dispatch(_van, _s(0), M5Order.look).mistake, M5GateMistakes.patrolNoPtw.m, reason: 'R6');
      expect(a.slips, 1, reason: 'one slip per move');

      final b = _runWhere((d) => d.kase == M5Case.clear && !d.night);
      b.ask(M5Ask.ptw);
      b.placePtw();
      expect(b.dispatch(_van, _s(0), M5Order.look).mistake, M5GateMistakes.blindStart.m);

      final c = _runWhere((d) => d.kase == M5Case.clear && !d.night && d.customersClue);
      c.ask(M5Ask.ptw);
      c.placePtw();
      c.ask(M5Ask.customers);
      expect(c.supported(), {c.deal.k});
      final off = (c.deal.k + 1) % 4;
      final o = c.dispatch(_van, _s(off), M5Order.look);
      expect(o.mistake, M5GateMistakes.blindPatrol.m);
      expect(o.before, isNull, reason: 'no ◆ for a blind patrol');

      final n = _runWhere((d) => d.kase == M5Case.storm && d.night);
      _cleanStart(n);
      expect(n.dispatch(M5Chip.mateA, _s(n.deal.k), M5Order.look).mistake, M5GateMistakes.nightAlone.m, reason: 'R27');

      final e = _runWhere((d) => d.kase == M5Case.storm && !d.night && d.hasFpi);
      _cleanStart(e);
      expect(e.dispatch(_van, _s(0), M5Order.cordon).mistake, M5GateMistakes.needless.m);
      expect(e.dispatch(_van, const M5Spot.fpiAt(0), M5Order.earth).mistake, M5GateMistakes.needless.m, reason: 'nothing to earth at an FPI');
      final fp = _runWhere((d) => d.kase == M5Case.storm && !d.night && d.hasFpi);
      fp.ask(M5Ask.relay);
      expect(fp.dispatch(_van, const M5Spot.fpiAt(1), M5Order.climb).mistake, M5GateMistakes.handsNoPtw.m, reason: 'an FPI pole is on the line too');
      final h = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      _cleanStart(h);
      expect(h.dispatch(_van, _s(h.deal.k), M5Order.earth).mistake, M5GateMistakes.handsBeforeFound.m, reason: 'earth before the fault is found');
      // Found already: an earth at another section is needless, not 'before the find'.
      final h2 = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      _cleanStart(h2);
      h2.dispatch(_van, _s(h2.deal.k), M5Order.look);
      expect(h2.located, isTrue);
      expect(h2.dispatch(_van, _s((h2.deal.k + 1) % 4), M5Order.earth).mistake, M5GateMistakes.needless.m);
    });

    test('deadly: a climb or a bamboo poke at an FPI pole (nothing earthed there), hands after the line clear', () {
      final fp = _runWhere((d) => d.kase == M5Case.storm && !d.night && d.hasFpi);
      _cleanStart(fp);
      final o = fp.dispatch(_van, const M5Spot.fpiAt(1), M5Order.climb);
      expect(o.mistake, M5GateMistakes.climbNoEarth.m, reason: 'R2/R4: no tester, no earth at an FPI pole');
      expect(o.deadly, isTrue);
      final fb = _runWhere((d) => d.kase == M5Case.storm && !d.night && d.hasFpi);
      _cleanStart(fb);
      expect(fb.dispatch(_van, const M5Spot.fpiAt(0), M5Order.bamboo).mistake, M5GateMistakes.bamboo.m);

      // After the line clear the PTW is back: an earth (or the cable ends) is deadly.
      final r = _runWhere((d) => d.kase == M5Case.wind && !d.night);
      _cleanStart(r);
      final k = r.deal.k;
      r.dispatch(_van, _s(k), M5Order.look);
      r.dispatch(_van, _s(k), M5Order.earth);
      r.dispatch(_van, _s(k), M5Order.climb);
      r.cvPick(M5Part.span, right: true);
      expect(r.cvDone(), isNull);
      r.callDown();
      expect(r.ask(M5Ask.lineClear).mistake, isNull);
      final after = r.dispatch(_van, _s(k), M5Order.earth);
      expect(after.mistake, M5GateMistakes.handsAfterClear.m);
      expect(after.deadly, isTrue);
      final ug = _runWhere((d) => d.kase == M5Case.cable);
      _cleanStart(ug);
      ug.repaired = true;
      expect(ug.ask(M5Ask.lineClear).mistake, isNull);
      expect(ug.ug(M5UgStep.isolate).mistake, M5GateMistakes.handsAfterClear.m);
    });

    test('the fallen wire: the far cordon finds and rings it, a rope beside it is a slip (R16), the bamboo poke (R20)', () {
      // Case D: the far cordon before any sighting is right, finds the wire, pays the cordon reason.
      final d = _runWhere((d) => d.kase == M5Case.fallen && !d.night && !d.hasFpi);
      _cleanStart(d);
      final k = d.deal.k;
      final c = d.dispatch(_van, _s(k), M5Order.cordon);
      expect(c.mistake, isNull);
      expect(c.note, M5GateLines.corded);
      expect(c.reason, M5Reason.cordon);
      expect(c.firstReport, isTrue, reason: 'the ring is a report: the coworker can come');
      expect(d.located && d.cordoned, isTrue);
      // With FPIs, the find still needs the pair (slip after the report).
      final f = _runWhere((d) => d.kase == M5Case.fallen && !d.night && d.hasFpi && d.customersClue);
      for (final a in m5InfoAsks) {
        f.ask(a);
      }
      f.ask(M5Ask.ptw);
      f.placePtw();
      final fc = f.dispatch(_van, _s(f.deal.k), M5Order.cordon);
      expect(fc.mistake, M5GateMistakes.noFpiPair.m);
      expect(fc.slipAfter, isTrue);
      expect(f.cordoned, isTrue);

      // A rope beside the wire: a slip (M5-4 text); it finds the wire but rings nothing.
      final r = _runWhere((d) => d.kase == M5Case.fallen && !d.night);
      _cleanStart(r);
      final rk = r.deal.k;
      final ro = r.dispatch(_van, _s(rk), M5Order.rope);
      expect(ro.mistake, M5GateMistakes.ropeClose.m);
      expect(r.located, isTrue);
      expect(r.cordoned, isFalse);
      expect(r.dispatch(_van, _s(rk), M5Order.earth).mistake, M5GateMistakes.wireZone.m, reason: 'still no far cordon');
      final r2 = _runWhere((d) => d.kase == M5Case.fallen && !d.night);
      _cleanStart(r2);
      expect(r2.dispatch(_van, _s((r2.deal.k + 1) % 4), M5Order.rope).mistake, M5GateMistakes.needless.m);
      expect(M5GateMistakes.ropeClose.m.textBn, contains('তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে 10 মিটার'));

      // Bamboo: deadly on the live line (case F) and before tester + earth; needless after them.
      final live = _runWhere((d) => d.kase == M5Case.night);
      live.ask(M5Ask.relay);
      expect(live.dispatch(_van, _s(live.deal.k), M5Order.bamboo).mistake, M5GateMistakes.bamboo.m, reason: 'R20');
      final b = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      _cleanStart(b);
      b.dispatch(_van, _s(b.deal.k), M5Order.look);
      expect(b.dispatch(_van, _s(b.deal.k), M5Order.bamboo).mistake, M5GateMistakes.bamboo.m, reason: 'a tool on the line before the tester');
      final b2 = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      _cleanStart(b2);
      b2.dispatch(_van, _s(b2.deal.k), M5Order.look);
      b2.dispatch(_van, _s(b2.deal.k), M5Order.earth);
      expect(b2.dispatch(_van, _s(b2.deal.k), M5Order.bamboo).mistake, M5GateMistakes.needless.m);
      final nb = _runWhere((d) => d.kase == M5Case.storm && !d.night);
      nb.ask(M5Ask.relay);
      expect(nb.dispatch(_van, _s(0), M5Order.bamboo).mistake, M5GateMistakes.handsNoPtw.m, reason: 'R1 first');
    });

    test('the remedy deck: one ঠিক আছে card and two remedies every time, sound part or damaged', () {
      final none = M5GateLines.remedy(M5Remedy.none).toSet();
      final rng = math.Random(3);
      for (var i = 0; i < 400; i++) {
        for (final r in M5Remedy.values) {
          final deck = m5RemedyDeck(r, rng);
          expect(deck, hasLength(3));
          expect(deck.where((o) => o.correct), hasLength(1));
          expect(deck.where((o) => none.contains(o.textBn)), hasLength(1), reason: 'exactly one M5Remedy.none card (${r.name})');
          expect(deck.map((o) => o.textBn).toSet(), hasLength(3));
          expect(M5GateLines.remedy(r), contains(deck.firstWhere((o) => o.correct).textBn));
        }
      }
    });

    test('the coworker fits the clock: the charge push at night is dealt at 2 a.m.', () {
      for (var s = 0; s < 400; s++) {
        final d = dealM5(math.Random(s));
        if (d.push == M5Push.chargeNight || d.kase == M5Case.night) {
          expect(d.hour, 2, reason: 'his line says রাত দুটো');
          expect(M5GateLines.intro(d), contains('রাত 2টা'));
        }
      }
    });

    test('the find: FPI pair needed (slip after the report), locate ◆ and the first patrol ◆ otherwise', () {
      final f = _runWhere((d) => d.kase == M5Case.clear && !d.night && d.hasFpi && d.customersClue);
      for (final a in m5InfoAsks) {
        f.ask(a);
      }
      f.ask(M5Ask.ptw);
      f.placePtw();
      final o = f.dispatch(_van, _s(f.deal.k), M5Order.look);
      expect(o.mistake, M5GateMistakes.noFpiPair.m);
      expect(o.slipAfter, isTrue);
      expect(o.before, M5Reason.hypothesis);
      expect(o.firstReport, isTrue);
      expect(f.located, isTrue);

      final g = _runWhere((d) => d.kase == M5Case.clear && !d.night && d.hasFpi);
      _cleanStart(g);
      final p = g.dispatch(_van, _s(g.deal.k), M5Order.look);
      expect(p.mistake, isNull);
      expect(p.before, M5Reason.hypothesis);
      expect(p.reason, M5Reason.locate);
      expect(p.note, M5GateLines.sighting(g.deal));
    });

    test('a clean overhead case: earth ◆, close view, verdict, line clear, charge → passed at 100', () {
      for (final kase in [M5Case.storm, M5Case.clear, M5Case.wind, M5Case.fallen]) {
        final r = _runWhere((d) => d.kase == kase && d.knockOn == (kase != M5Case.wind));
        _cleanStart(r);
        final k = r.deal.k;
        expect(r.dispatch(_van, _s(k), M5Order.look).reason, M5Reason.locate, reason: kase.name);
        if (kase == M5Case.fallen) expect(r.dispatch(_van, _s(k), M5Order.cordon).reason, M5Reason.cordon);
        expect(r.dispatch(_van, _s(k), M5Order.earth).reason, M5Reason.earth);
        expect(r.dispatch(_van, _s(k), M5Order.climb).closeView, isTrue);
        // A sound look-alike: 'ঠিক আছে' is its right card (no cost).
        r.cvPick(r.deal.worn.first, right: true);
        for (final part in r.deal.damages.keys) {
          r.cvPick(part, right: true);
        }
        expect(r.cvDone(), isNull);
        final v = r.verdict(M5Verdict.permanent, root: true);
        expect(v.mistake, isNull);
        expect(v.reason, r.asksRoot ? M5Reason.history : M5Reason.permanent);
        expect(r.callDown().note, M5GateLines.cameDown);
        expect(r.ask(M5Ask.lineClear).mistake, isNull);
        final ch = r.ask(M5Ask.charge);
        expect(ch.lit, isTrue);
        expect(ch.reason, M5Reason.lineClear);
        expect(r.passed, isTrue, reason: kase.name);
        expect(r.percent, 100);
      }
    });

    test('close view: a missed knock-on and a wrong card are one slip per press each', () {
      final r = _runWhere((d) => d.kase == M5Case.storm && d.knockOn);
      _cleanStart(r);
      final k = r.deal.k;
      r.dispatch(_van, _s(k), M5Order.look);
      r.dispatch(_van, _s(k), M5Order.earth);
      r.dispatch(_van, _s(k), M5Order.climb);
      final parts = r.deal.damages.keys.toList();
      r.cvPick(parts.first, right: false);
      r.cvPick(parts.first, right: true);
      expect(r.cvDone(), M5GateMistakes.cvMissed.m, reason: 'one damage untouched');
      expect(r.repaired, isFalse);
      r.cvPick(parts.last, right: false);
      r.cvPick(parts.last, right: true);
      expect(r.cvDone(), M5GateMistakes.cvWrong.m, reason: 'a wrong card on the way');
      expect(r.repaired, isTrue);
      expect(r.slips, 2);

      // A wrong pick before a missed-knock-on press is not wiped by it.
      final c = _runWhere((d) => d.kase == M5Case.storm && d.knockOn);
      _cleanStart(c);
      c.dispatch(_van, _s(c.deal.k), M5Order.look);
      c.dispatch(_van, _s(c.deal.k), M5Order.earth);
      c.dispatch(_van, _s(c.deal.k), M5Order.climb);
      final cp = c.deal.damages.keys.toList();
      c.cvPick(cp.first, right: false);
      c.cvPick(cp.first, right: true);
      expect(c.cvDone(), M5GateMistakes.cvMissed.m);
      c.cvPick(cp.last, right: true);
      expect(c.cvDone(), M5GateMistakes.cvWrong.m, reason: 'the earlier wrong pick carries over');
      expect(c.slips, 2);
    });

    test('verdict, UG order, line clear early, the coworker: slips', () {
      final r = _runWhere((d) => d.kase == M5Case.storm && d.repeats);
      r.ask(M5Ask.logbook);
      r.repaired = true;
      expect(r.verdict(M5Verdict.transient).mistake, M5GateMistakes.verdictWrong.m);
      expect(r.verdict(M5Verdict.permanent, root: false).mistake, M5GateMistakes.repairOnly.m);
      expect(r.verdict(M5Verdict.permanent, root: true).reason, M5Reason.history);
      final f = _runWhere((d) => d.kase == M5Case.night);
      expect(f.rightVerdict, M5Verdict.transient);

      final early = _runWhere((d) => d.kase == M5Case.clear);
      expect(early.ask(M5Ask.lineClear).mistake, M5GateMistakes.clearEarly.m);
      expect(early.ended, isFalse);

      final ug = _runWhere((d) => d.kase == M5Case.cable);
      _cleanStart(ug);
      expect(ug.ug(M5UgStep.team).mistake, M5GateMistakes.ugTeamFirst.m);
      expect(ug.ug(M5UgStep.guessDig).mistake, M5GateMistakes.ugGuessDig.m);
      expect(ug.ug(M5UgStep.selfJoint).mistake, M5GateMistakes.ugSelfJoint.m);
      expect(ug.ug(M5UgStep.isolate).mistake, isNull);
      expect(ug.ug(M5UgStep.megger).reason, M5Reason.megger);
      expect(ug.ug(M5UgStep.team).mistake, isNull);
      expect(ug.ug(M5UgStep.peg).mistake, M5GateMistakes.ugPegFirst.m, reason: 'R33');
      expect(ug.ug(M5UgStep.owners).reason, M5Reason.dig);
      final peg = ug.ug(M5UgStep.peg);
      expect(peg.verdict, isTrue);
      expect(ug.repaired, isTrue);

      final wait = _runWhere((d) => d.push == M5Push.waitMorning);
      expect(wait.listened(), M5GateMistakes.coworkerWait.m);
      expect(wait.ended, isFalse);
      final push = _runWhere((d) => d.push == M5Push.chargeNight);
      expect(push.listened().deadly, isTrue, reason: 'R8 / R29: asking for a charge on his word');
      expect(push.ended, isTrue);
    });

    test('case F: ground patrol is fine without the PTW; the glow shows only with the lights off', () {
      final r = _runWhere((d) => d.kase == M5Case.night);
      for (final a in m5InfoAsks) {
        r.ask(a);
      }
      expect(r.ask(M5Ask.ptw).ptwSlip, isFalse, reason: 'the line is in service');
      if (r.deal.hasFpi) {
        for (final i in r.deal.fpiPair) {
          expect(r.dispatch(_van, M5Spot.fpiAt(i), M5Order.fpi).mistake, isNull);
        }
      }
      final look = r.dispatch(_van, _s(r.deal.k), M5Order.look);
      expect(look.mistake, isNull, reason: 'R7: ground patrol of an in-service line');
      expect(look.note, M5GateLines.searchlightNothing);
      final glow = r.dispatch(_van, _s(r.deal.k), M5Order.lightsOff);
      expect(glow.note, M5GateLines.glow);
      expect(glow.verdict, isTrue);
      expect(r.verdict(M5Verdict.transient, root: true).reason, isIn([M5Reason.transient, M5Reason.history]));
    });

    test('option libraries: 1 right of ≥ 2, wrong from ≥ 5, all within 1.3×', () {
      for (final r in M5Reason.values) {
        for (final fpi in [false, true]) {
          final right = M5GateLines.whyRight(r, fpi: fpi);
          final wrong = M5GateLines.whyWrong(r);
          expectLibrary('${r.name} $fpi', right, wrong);
          expectSameLength('${r.name} $fpi', [...right, ...wrong]);
        }
      }
      final allRemedies = <String>[];
      for (final m in M5Remedy.values) {
        expectLibrary('remedy ${m.name}', M5GateLines.remedy(m), M5GateLines.remedyWrong(m));
        allRemedies.addAll(M5GateLines.remedy(m));
      }
      expectSameLength('remedies', allRemedies);
      for (final cw in M5GateLines.coworkers) {
        expectLibrary('coworker', cw.right, cw.wrong);
        expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      }
      // Every damage has a remedy of its own; a sound part's card is 'ঠিক আছে'.
      expect(m5RemedyFor(null), M5Remedy.none);
      for (final d in M5Damage.values) {
        expect(m5RemedyFor(d), isNot(M5Remedy.none));
      }
    });

    test('English digits on screen; the case lines', () {
      final bn = RegExp('[০-৯]');
      final lines = <String>[
        ...M5GateLines.tasks, ...M5GateLines.excuses, ...M5GateLines.decoys, M5GateLines.glow, M5GateLines.corded,
        for (final r in M5Reason.values) ...[M5GateLines.question(r), ...M5GateLines.whyRight(r), ...M5GateLines.whyRight(r, fpi: true), ...M5GateLines.whyWrong(r), M5GateLines.caught(r)],
        for (final m in M5Remedy.values) ...M5GateLines.remedy(m),
        for (final s in M5UgStep.values) ...[M5GateLines.ug(s), if (M5GateLines.ugNote(s).isNotEmpty) M5GateLines.ugNote(s)],
        for (final m in M5GateMistakes.all) m.textBn,
        for (final cw in M5GateLines.coworkers) ...[cw.line, ...cw.right, ...cw.wrong, ...cw.asks],
      ];
      for (var s = 0; s < 120; s++) {
        final d = dealM5(math.Random(s));
        lines.add(M5GateLines.intro(d));
        for (final a in M5Ask.values) {
          lines.add(M5GateLines.answer(d, a));
          lines.add(M5GateLines.ask(a));
        }
        for (final o in M5Order.values) {
          lines.add(M5GateLines.order(o, night: d.night));
        }
        lines.add(M5GateLines.sighting(d));
        lines.add(M5GateLines.people(d));
      }
      for (final l in lines) {
        expect(l, isNotEmpty);
        expect(bn.hasMatch(l), isFalse, reason: l);
      }
      final f = dealM5(math.Random(_seedWhere((d) => d.kase == M5Case.night)));
      expect(M5GateLines.intro(f), contains('বারবার ট্রিপ'));
      final day = dealM5(math.Random(_seedWhere((d) => d.kase.lockOut && !d.night)));
      expect(M5GateLines.intro(day), startsWith('দুপুর'));
    });

    test("the coworker's lines: recorded, or listed for the director", () {
      for (final cw in M5GateLines.coworkers) {
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: cw.exitLine);
        final recorded = LearnVoice.resolve(cw.line, rival: true) != null;
        expect(recorded || M5GateLines.newRivalLines.contains(cw.line), isTrue, reason: cw.line);
      }
      expect(M5GateLines.newRivalLines.toSet(), {for (final cw in M5GateLines.coworkers) cw.line});
      expect(M5GateLines.waitMorning.line, 'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।', reason: 'lesson 5.7 myth word for word');
    });

    test('the mistakes: unique keys, pictures, lesson points, the module table', () {
      final keys = <String>{};
      for (final x in M5GateMistakes.values) {
        expect(keys.add(x.m.key), isTrue, reason: x.m.key);
        expect(x.m.key, startsWith('m5/gate/'));
        expect(File(x.m.art).existsSync(), isTrue, reason: x.m.art);
        expect(x.m.lessonPoint, isNotNull);
        expect(['5.1', '5.2', '5.3', '5.4', '5.7', '5.9'], contains(x.lessonId));
        expect(M5GateMistakes.lessonOf(x.m), x.lessonId);
      }
      final deadly = {
        M5GateMistakes.handsNoPtw, M5GateMistakes.climbNoEarth, M5GateMistakes.chargeFault, M5GateMistakes.chargeCrew,
        M5GateMistakes.clearCrewUp, M5GateMistakes.wireZone, M5GateMistakes.climbLive, M5GateMistakes.meggerLive,
        M5GateMistakes.handsAfterClear, M5GateMistakes.bamboo,
      };
      for (final x in M5GateMistakes.values) {
        expect(x.m.deadly, deadly.contains(x), reason: x.m.key);
      }
      // Ruling texts carried word for word.
      expect(M5GateMistakes.patrolNoPtw.m.textBn, contains('টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে PTW বাধ্যতামূলক'));
      // M5-3: the PTW is never framed as a must for sending a ground patrol.
      expect(M5GateMistakes.patrolNoPtw.m.textBn, isNot(startsWith('লক-আউট ফিডারে PTW ছাড়াই')));
      expect(M5GateLines.question(M5Reason.ptw), isNot(contains('দল পাঠানোর')));
      expect(M5GateMistakes.ugPegFirst.m.textBn, contains('খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান'));
      expect(M5GateMistakes.wireZone.m.textBn, contains('তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে 10 মিটার'));
      // Every picture in the folder is used.
      final used = {for (final x in M5GateMistakes.values) x.m.art.split('/').last};
      final files = {for (final f in Directory('assets/game/art/m5_gate_case').listSync()) f.uri.pathSegments.last};
      expect(files, used);
    });

    test('the close view parts sit on screen and never overlap; map spots in the map', () {
      for (final h in [560.0, 780.0, 900.0]) {
        final g = M5Geo(h, 0);
        for (var i = 0; i < 7; i++) {
          final r = g.part(i);
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          for (var j = i + 1; j < 7; j++) {
            expect(r.overlaps(g.part(j)), isFalse, reason: 'parts $i/$j at $h');
          }
        }
        for (var i = 0; i < 4; i++) {
          expect(g.map.contains(g.section(i).center), isTrue);
        }
        expect(g.notes.height, greaterThan(60), reason: 'notes readable at $h');
        expect(g.tools, hasLength(4));
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

    testWidgets('the guide comes first with the case: no start button, a tap does not skip', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final p = M5GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5GateCasePage(ctx: _ctx, pack: _pack, muted: true, seed: 4, probe: p))));
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
      testWidgets('idle at the tailgate draws zero frames (reduce motion: $reduce)', (t) async {
        if (reduce) {
          t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = M5GateProbe();
        final c = await _open(t, 7, p);
        expect(p.phase, 'idle');
        await _pump(t, 14000);
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(frames, lessThan(12), reason: 'idle tailgate');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a full clean case: clues, PTW, patrol, the coworker held and refused, earth, close view, report, line clear → rank-up', (t) async {
      final seed = _seedWhere((d) => d.kase == M5Case.storm && !d.night && d.customersClue && !d.hasFpi && d.knockOn && d.repeats);
      final p = M5GateProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      final k = d.k;
      // The control room: the clues (raw notes on the sheet).
      await _phone(t, M5Ask.relay);
      expect(find.text(M5GateLines.answer(d, M5Ask.relay)), findsOneWidget);
      await _phone(t, M5Ask.weather);
      await _phone(t, M5Ask.customers);
      await _phone(t, M5Ask.logbook);
      // The PTW onto the clipboard → ◆.
      await _phone(t, M5Ask.ptw);
      await _tapKey(t, 'm5-ptw-slip');
      expect(p.phase, 'slip');
      await _tapKey(t, 'm5-clipboard');
      await _pickRight(t, p);
      expect(p.run!.ptwOn, isTrue);
      // The first patrol → ◆ hypothesis → the report → ◆ locate.
      await _dispatch(t, _van, _s(k), M5Order.look);
      await _pickRight(t, p);
      await _until(t, () => p.run!.located && p.busy, maxMs: 6000, reason: 'the report is back');
      expect(find.text(M5GateLines.sighting(d)), findsOneWidget);
      await _pickRight(t, p);
      // The coworker is due (the first report is back): the next tailgate
      // touch waits for him — the chip does not lift.
      await _tapKey(t, 'm5-chip-van');
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he comes on the next touch');
      expect(p.phase, 'idle', reason: 'the chip waited for him');
      expect(find.text(M5GateLines.chargeDay.line), findsWidgets);
      await _pickRight(t, p);
      await _pump(t, 1200);
      // Make safe: tester + earth → ◆; climb → the close view.
      await _dispatch(t, _van, _s(k), M5Order.earth);
      await _until(t, () => p.busy, maxMs: 6000);
      await _pickRight(t, p);
      await _dispatch(t, _van, _s(k), M5Order.climb);
      await _until(t, () => p.phase == 'view', maxMs: 6000, reason: 'up the pole');
      for (final part in d.damages.keys) {
        await _tapKey(t, 'm5-part-${part.name}');
        expect(p.phase, 'remedy');
        await _pickRight(t, p);
        await _until(t, () => p.phase == 'view', maxMs: 3000);
      }
      await _tapKey(t, 'm5-view-done');
      await _pickRight(t, p);
      // The report.
      await _until(t, () => p.phase == 'verdict', maxMs: 3000);
      await _tapKey(t, 'm5-verdict-permanent');
      if (p.run!.asksRoot) await _tapKey(t, 'm5-root-yes');
      await _tapKey(t, 'm5-verdict-submit');
      await _pickRight(t, p);
      // Line clear: everybody down, line clear, charge → the villages light → ◆.
      await _until(t, () => p.phase == 'idle', maxMs: 3000);
      await _tapKey(t, 'm5-tool-radio');
      await _tapKey(t, 'm5-call-down');
      await t.longPress(find.byKey(const ValueKey('m5-send')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.run!.crewOnLine, isFalse);
      await _phone(t, M5Ask.lineClear);
      await _phone(t, M5Ask.charge);
      await _pickRight(t, p);
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000);
      expect(find.text(M5GateLines.rankTo), findsOneWidget);
      expect(find.text(M5GateLines.badge), findsOneWidget);
      expect(find.text(M5GateLines.caughtCharge), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['m5/gate'], 'cleared');
      expect(save.rankIndex, 5, reason: 'স্কিলড → অ্যাডভান্সড');
      expect(save.mistakes, isEmpty);
      expect(save.starsByRung['m5/gate'] ?? 0, greaterThanOrEqualTo(2));
      expect(p.run!.slips, 0);
      // The pass panel waits quietly.
      await _pump(t, 14000);
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12), reason: 'idle on the pass panel');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('case F at night: the van patrols, lights off finds the glow, the coworker refused, the report ends it', (t) async {
      final seed = _seedWhere((d) => d.kase == M5Case.night && d.customersClue && !d.hasFpi);
      final p = M5GateProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      expect(find.byKey(const ValueKey('m5-order-lightsOff')), findsNothing);
      await _phone(t, M5Ask.customers);
      await _dispatch(t, _van, _s(d.k), M5Order.lightsOff);
      // Lesson 5.7's myth as the first patrol is sent — before anything is reported.
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he cuts in as the van is sent');
      expect(find.text(M5GateLines.glow), findsNothing, reason: 'nothing is reported yet');
      expect(find.text(M5GateLines.waitMorning.line), findsWidgets);
      await _pickRight(t, p);
      await _pump(t, 1200); // he leaves, the van goes
      await _pickRight(t, p); // the first patrol ◆
      await _until(t, () => p.run!.located && p.busy, maxMs: 6000, reason: 'the glow is reported');
      expect(find.text(M5GateLines.glow), findsOneWidget);
      await _pickRight(t, p); // the locate ◆
      await _until(t, () => p.phase == 'verdict', maxMs: 3000);
      await _tapKey(t, 'm5-verdict-transient');
      if (p.run!.asksRoot) await _tapKey(t, 'm5-root-yes');
      await _tapKey(t, 'm5-verdict-submit');
      await _pickRight(t, p);
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['m5/gate'], 'cleared');
      expect(save.rankIndex, 5);
      expect(p.run!.ptwOn, isFalse, reason: 'a ground patrol of a live line needs no PTW');
      expect(find.text(M5GateLines.caughtNight), findsOneWidget);
      expect(find.text(M5GateLines.caughtPair), findsOneWidget);
      await _close(t, c);
    });

    testWidgets("listening to the 'wait till morning' coworker costs exactly one slip (-10)", (t) async {
      final seed = _seedWhere((d) => d.kase == M5Case.storm && d.night && d.push == M5Push.waitMorning && d.customersClue && !d.hasFpi);
      final p = M5GateProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      await _phone(t, M5Ask.customers);
      await _phone(t, M5Ask.ptw);
      await _tapKey(t, 'm5-ptw-slip');
      await _tapKey(t, 'm5-clipboard');
      await _pickRight(t, p); // the PTW reason
      await _pump(t, 600);
      final before = p.score;
      expect(before, greaterThan(10));
      await _dispatch(t, _van, _s(d.k), M5Order.look);
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he cuts in at the first patrol');
      await _waitDeckUp(t);
      final wrong = [for (final x in M5GateLines.waitMorning.wrong) if (_label(x).evaluate().isNotEmpty) _label(x)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
      expect(find.text(M5GateMistakes.coworkerWait.m.textBn), findsOneWidget);
      await _pump(t, 600);
      expect(before - p.score, 10, reason: 'the slip takes -10 once');
      expect(p.run!.slips, 1);
      await _close(t, c);
    });

    testWidgets('case E: the cable sheet — isolate, megger ◆, team, owners ◆, peg — then the report and line clear', (t) async {
      final seed = _seedWhere((d) => d.kase == M5Case.cable && !d.night && d.customersClue && !d.hasFpi);
      final p = M5GateProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      await _phone(t, M5Ask.relay);
      await _phone(t, M5Ask.customers);
      await _phone(t, M5Ask.ptw);
      await _tapKey(t, 'm5-ptw-slip');
      await _tapKey(t, 'm5-clipboard');
      await _pickRight(t, p);
      await _dispatch(t, _van, _s(d.k), M5Order.look);
      await _pickRight(t, p);
      await _until(t, () => p.run!.located && p.busy, maxMs: 6000);
      await _pickRight(t, p);
      await _until(t, () => p.phase == 'ug' || p.coworkerUp, maxMs: 4000, reason: 'the cable sheet opens');
      await _wait(t, () => p.coworkerUp);
      if (p.coworkerUp) {
        await _pickRight(t, p);
        await _pump(t, 1200);
      }
      expect(p.phase, 'ug');
      await _tapKey(t, 'm5-ug-isolate');
      await _tapKey(t, 'm5-ug-megger');
      await _pickRight(t, p);
      await _until(t, () => p.phase == 'ug', maxMs: 3000);
      await _tapKey(t, 'm5-ug-team');
      await _tapKey(t, 'm5-ug-owners');
      await _pickRight(t, p);
      await _until(t, () => p.phase == 'ug', maxMs: 3000);
      await _tapKey(t, 'm5-ug-peg');
      await _until(t, () => p.phase == 'verdict', maxMs: 3000);
      await _tapKey(t, 'm5-verdict-permanent');
      if (p.run!.asksRoot) await _tapKey(t, 'm5-root-yes');
      await _tapKey(t, 'm5-verdict-submit');
      await _pickRight(t, p);
      await _until(t, () => p.phase == 'idle', maxMs: 3000);
      await _tapKey(t, 'm5-tool-radio');
      await _tapKey(t, 'm5-call-down');
      await t.longPress(find.byKey(const ValueKey('m5-send')), warnIfMissed: false);
      await _pump(t, 300);
      await _phone(t, M5Ask.lineClear);
      await _phone(t, M5Ask.charge);
      await _pickRight(t, p);
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000);
      expect(c.read(gameSaveProvider).rungProgress['m5/gate'], 'cleared');
      expect(p.run!.slips, 0);
      expect(find.text(M5GateLines.caught(M5Reason.dig)), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a deadly move plays out: freeze, then the near-miss card', (t) async {
      final seed = _seedWhere((d) => d.kase == M5Case.clear && !d.night);
      final p = M5GateProbe();
      final c = await _open(t, seed, p);
      await _phone(t, M5Ask.relay);
      await _dispatch(t, _van, _s(0), M5Order.climb);
      await _until(t, () => p.phase == 'freeze', maxMs: 3000, reason: 'hands on before the PTW');
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('harm')), findsOneWidget);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M5GateMistakes.handsNoPtw.m.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['m5/gate'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('three slips strike the gate out', (t) async {
      final seed = _seedWhere((d) => d.kase == M5Case.wind && !d.night);
      final p = M5GateProbe();
      final c = await _open(t, seed, p);
      for (var n = 1; n <= 3; n++) {
        // A cordon on a locked-out feeder with no PTW: a slip each time.
        await _dispatch(t, _van, _s(n % 4), M5Order.cordon);
        if (n < 3) {
          await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
          expect(find.text(M5GateMistakes.patrolNoPtw.m.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await t.pump();
          await _until(t, () => p.phase == 'idle', maxMs: 6000, reason: 'the crew is back');
        }
      }
      await _until(t, () => find.byType(StruckOutCard).evaluate().isNotEmpty, maxMs: 4000);
      expect(p.run!.slips, 3);
      expect(c.read(gameSaveProvider).rungProgress['m5/gate'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('gesture hint at the tailgate: a sweep over the four tools, pressing none', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M5GateProbe();
      final c = await _open(t, 11, p);
      expect(p.phase, 'idle');
      await _pump(t, 9500);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget, reason: 'idle at the tailgate');
      final hint = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(hint.debugOptions, hasLength(4), reason: 'phone, radio, clipboard, map — all alike');
      expect(p.phase, 'idle', reason: 'a hint presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
