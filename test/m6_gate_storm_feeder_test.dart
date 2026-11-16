// The Module 6 rank gate "ঝড়ের রাত: ফিডার ফেরান" (m6_gate_storm_feeder): the
// deal (six fault families from lesson facts, never the same twice in a row,
// device states varied over seeds), the engine's rules (every deadly and slip
// row of the module table after the rulings, one slip per move), a clean
// engine play of every family to the pass, the option libraries (lengths
// within 1.3×), English digits, the coworker's lines (recorded or listed) and
// every spoken line listed, the mistakes, and the page: the guide first, idle
// = zero frames (with and without reduced motion), a full clean play to the
// rank-up (incl. reason picks, the coworker held and refused, the crew deck),
// a deadly move (freeze → near-miss), listening to the coworker (deadly),
// three slips (strike-out), and the gesture hint (presses nothing).
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
import 'package:slm_flutter/features/game/m6_gate_storm_feeder.dart';
import 'package:slm_flutter/features/game/m6_gate_storm_feeder_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: 'm6/gate',
  kind: CatalogRungKind.gate,
  lessonId: '6.11',
  lessonTitleBn: '',
  ladderStep: 180,
);

final _pack = m6GatePacks['gate_m6']!;

int _seedWhere(bool Function(M6GDeal d) ok) {
  for (var s = 1; s < 60000; s++) {
    if (ok(dealM6G(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

M6GRun _runWhere(bool Function(M6GDeal d) ok) => M6GRun(dealM6G(math.Random(_seedWhere(ok))));

bool _plain(M6GDeal d) => d.stuck == null && d.partSeat == null && !d.incomplete && !d.tieClosed && d.leads.values.every((l) => l == M6GLead.ok);

// --- the engine: a clean play --------------------------------------------------
void _ok(M6GOutcome o, String why) {
  expect(o.mistake, isNull, reason: why);
}

void _ptw(M6GRun r, M6GReq q) {
  final first = r.radio(q);
  _ok(first, 'ptw $q');
  if (!r.complete.contains(q)) {
    final again = r.radio(q);
    _ok(again, 'ptw again $q');
    expect(again.reason, M6GReason.reAsk);
  }
  expect(r.complete, contains(q));
}

void _readyAb(M6GRun r, M6GDev ab) {
  r.look(ab);
  if (r.leadFixDue(ab)) {
    final fix = r.crew(ab);
    expect(fix.note, M6GateLines.leadFixed);
  }
}

void _open(M6GRun r, M6GDev ab) {
  _readyAb(r, ab);
  expect(r.handleDrop(ab), isNull, reason: 'handle on $ab');
  _ok(r.stroke(ab, stalled: false), 'open $ab');
  if (r.stuck == ab) {
    r.look(ab);
    expect(r.look(ab).note, contains('আটকে'));
    expect(r.handleDrop(ab), isNull);
    expect(r.stroke(ab, stalled: false).note, M6GateLines.freed);
  }
  r.look(ab);
}

void _close(M6GRun r, M6GDev ab) {
  expect(r.handleDrop(ab), isNull, reason: 'close $ab');
  _ok(r.stroke(ab, stalled: false), 'close $ab');
  if (r.partSeat == ab) {
    expect(r.look(ab).note, contains('আধখানা'));
    expect(r.handleDrop(ab), isNull);
    expect(r.stroke(ab, stalled: false).note, M6GateLines.seated);
  }
  r.look(ab);
}

M6GOutcome _pickRight(M6GRun r, M6GDeck d) {
  final o = r.pick(d, M6GCard.right);
  _ok(o, 'deck $d');
  return o;
}

void _bank(M6GRun r) {
  if (!r.deal.swollen) return;
  _ok(r.handleDrop(M6GDev.bank)!, 'bank off');
  for (var i = 0; i < 5; i++) {
    r.wait();
  }
  _ok(r.rodClamp(), 'clamp');
  for (var i = 0; i < 3; i++) {
    _ok(r.rodHook(i), 'hook $i');
  }
  final c = r.crew(M6GDev.bank);
  expect(c.deck, M6GDeck.bank);
  _pickRight(r, M6GDeck.bank);
}

/// Plays a dealt feeder through the engine with no slip; returns the run.
M6GRun _cleanPlay(M6GDeal d) {
  final r = M6GRun(d);
  final f = d.fam;
  final m = r.mark(f.sec);
  _ok(m, 'mark');
  expect(m.reason, M6GReason.find);
  void lit(M6GOutcome o) {
    _ok(o, 'restore');
    expect(o.lit, isTrue, reason: 'the light is back ($f)');
    expect(r.restored, isTrue);
  }

  switch (f) {
    case M6GFam.branch:
      _ok(r.radio(M6GReq.s3Info), 's3');
      _ptw(r, M6GReq.rcNrPtw);
      _open(r, M6GDev.abA);
      expect(r.test(M6GDev.branch).note, M6GateLines.testerDead);
      expect(r.earth(M6GDev.branch).reason, M6GReason.gaps);
      expect(r.crew(M6GDev.branch).deck, M6GDeck.storm);
      _pickRight(r, M6GDeck.storm);
      expect(r.earth(M6GDev.abA).note, M6GateLines.earthOff);
      _close(r, M6GDev.abA);
      lit(r.radio(M6GReq.s3Close));
      expect(r.rcNormalDone, isTrue, reason: 'R-12 back to normal with S-3');
    case M6GFam.main || M6GFam.ug:
      if (f == M6GFam.ug) expect(r.radio(M6GReq.relay).reason, M6GReason.relay);
      _ptw(r, f == M6GFam.ug ? M6GReq.cbOffPtw : M6GReq.rcNrPtw);
      _open(r, M6GDev.ab1);
      _open(r, M6GDev.ab2);
      if (d.tieClosed) {
        expect(r.isolated(M6GSec.main), isFalse, reason: 'the tie is a source until it is open');
        _open(r, M6GDev.abT);
      }
      expect(r.test(M6GDev.span).note, M6GateLines.testerDead);
      expect(r.earth(M6GDev.ab1).reason, d.tieClosed ? M6GReason.tie : M6GReason.bothEnds);
      _bank(r);
      final dev = f == M6GFam.ug ? M6GDev.ug : M6GDev.span;
      final deck = f == M6GFam.ug ? M6GDeck.joint : M6GDeck.storm;
      expect(r.crew(dev).deck, deck);
      _pickRight(r, deck);
      expect(r.earth(M6GDev.ab2).note, M6GateLines.earthOff);
      _close(r, M6GDev.ab1);
      _close(r, M6GDev.ab2);
      lit(r.radio(f == M6GFam.ug ? M6GReq.cbOn : M6GReq.rcNormal));
    case M6GFam.dtrOil || M6GFam.coord:
      _ptw(r, M6GReq.dtrPtw);
      _ok(r.lt(M6GLt.offLock), 'lt off');
      expect(r.test(M6GDev.ltbox).note, M6GateLines.testerDead);
      if (f == M6GFam.coord) {
        expect(r.crew(M6GDev.ltbox).deck, M6GDeck.jugaad);
        expect(_pickRight(r, M6GDeck.jugaad).reason, M6GReason.fuse);
      }
      _open(r, M6GDev.dtr);
      expect(r.test(M6GDev.dtr).note, M6GateLines.testerDead);
      expect(r.earth(M6GDev.dtr).reason, M6GReason.gaps);
      if (f == M6GFam.dtrOil) {
        expect(r.crew(M6GDev.dtr).deck, M6GDeck.oil);
        final o = _pickRight(r, M6GDeck.oil);
        expect(o.done, isTrue);
        expect(o.reason, M6GReason.oil);
        break;
      }
      if (d.stripCut) {
        expect(r.crew(M6GDev.dtr).deck, M6GDeck.strip);
        _pickRight(r, M6GDeck.strip);
      }
      expect(r.crew(M6GDev.dtr).deck, M6GDeck.hg);
      _pickRight(r, M6GDeck.hg);
      expect(r.earth(M6GDev.dtr).note, M6GateLines.earthOff);
      _close(r, M6GDev.dtr);
      lit(r.lt(M6GLt.on));
    case M6GFam.ltWay:
      _ptw(r, M6GReq.dtrPtw);
      _ok(r.lt(M6GLt.offLock), 'lt off');
      expect(r.test(M6GDev.ltbox).note, M6GateLines.testerDead);
      expect(r.crew(M6GDev.house).deck, M6GDeck.nick);
      _pickRight(r, M6GDeck.nick);
      expect(r.crew(M6GDev.ltbox).deck, M6GDeck.hrc);
      expect(_pickRight(r, M6GDeck.hrc).reason, M6GReason.fuse);
      lit(r.lt(M6GLt.on));
  }
  if (r.twistDue) {
    final tw = r.crew(M6GDev.house);
    expect(tw.deck, d.twist == M6GTwist.lcd ? M6GDeck.twistLcd : M6GDeck.twistBlank);
    _pickRight(r, tw.deck!);
  }
  r.finish();
  return r;
}

/// A run made dead and ready for work on its HT section (no slip).
M6GRun _deadMain(bool Function(M6GDeal d) ok) {
  final r = _runWhere((d) => (d.fam == M6GFam.ug || d.fam == M6GFam.main) && _plain(d) && ok(d));
  r.mark(M6GSec.main);
  if (r.fam == M6GFam.ug) r.radio(M6GReq.relay);
  _ptw(r, r.ptwReq);
  _open(r, M6GDev.ab1);
  _open(r, M6GDev.ab2);
  r.test(M6GDev.ab1);
  _ok(r.earth(M6GDev.ab1), 'earth');
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

/// Picks the right card of the deck now up (and its এগিয়ে যান when there is one).
Future<void> _pickDeckRight(WidgetTester t, M6GateProbe p) async {
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

/// A belt token onto a device (the panorama panned to it first).
Future<void> _use(WidgetTester t, M6GateProbe p, M6GTok tok, M6GDev d) async {
  p.panTo(d);
  await t.pump();
  await _tapKey(t, 'm6g-tok-${tok.name}');
  expect(p.phase, 'lifted');
  await _tapKey(t, 'm6g-dev-${d.name}');
}

Future<void> _look(WidgetTester t, M6GateProbe p, M6GDev d) async {
  await _use(t, p, M6GTok.eye, d);
  expect(p.phase, 'lens');
  await _tapKey(t, 'm6g-lens-close');
}

Future<void> _radio(WidgetTester t, M6GateProbe p, M6GDev d, M6GReq q) async {
  await _use(t, p, M6GTok.radio, d);
  expect(p.phase, 'radio');
  await _tapKey(t, 'm6g-req-${q.name}');
  await t.longPress(find.byKey(const ValueKey('m6g-send')), warnIfMissed: false);
  await t.pump();
  await _pump(t, 200);
}

Future<void> _stroke(WidgetTester t, M6GateProbe p, M6GDev d) async {
  await _use(t, p, M6GTok.handle, d);
  expect(p.phase, 'stroke', reason: 'the handle on ${d.name}');
  await t.drag(find.byKey(const ValueKey('m6g-lever')), const Offset(0, 320));
  await t.pump();
  await _pump(t, 200);
}

Future<ProviderContainer> _openPage(WidgetTester t, int seed, M6GateProbe probe) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M6GateStormFeederPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
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
    test('the deal: six families from lesson facts, states per family, varied, never the same twice in a row', () {
      final fams = <M6GFam>{};
      final pushes = <M6GPush>{};
      final sigs = <String>{};
      var stuck = 0, part = 0, bad = 0, swollen = 0, twist = 0, incomplete = 0, tie = 0;
      for (var s = 0; s < 500; s++) {
        final d = dealM6G(math.Random(s));
        fams.add(d.fam);
        pushes.add(d.push);
        for (final e in d.reqOrder.entries) {
          expect(e.value.toSet(), m6gReqsOf(e.key).toSet(), reason: 'every request offered');
        }
        if (d.stuck != null) {
          stuck++;
          expect(d.pathAbs, contains(d.stuck));
          expect(d.stuck, isNot(M6GDev.dtr), reason: 'never where the AB\'s HT side stays live');
        }
        expect(d.feederNo, isNot(5), reason: 'ফিডার-5 is the tie');
        if (d.partSeat != null) {
          part++;
          expect(d.pathAbs, contains(d.partSeat));
        }
        if (d.leads.values.any((l) => l != M6GLead.ok)) bad++;
        if (d.swollen) {
          swollen++;
          expect(d.bank, isTrue);
          expect(d.fam.mainDead, isTrue, reason: 'a swollen unit only where the main is dead');
        }
        if (d.stripCut) expect(d.fam, M6GFam.coord, reason: 'in F-D the DTR goes to the shop');
        if (d.fam == M6GFam.dtrOil) expect(d.twist, M6GTwist.none, reason: 'the burnt DTR stays out');
        if (d.twist != M6GTwist.none) twist++;
        if (d.incomplete) incomplete++;
        if (d.tieClosed) {
          tie++;
          expect(d.fam.mainDead, isTrue, reason: 'the tie is left closed only where the main is the dead section');
        }
        if (d.fam == M6GFam.ug) expect(d.excavator, isFalse);
        expect(d.way, inInclusiveRange(1, d.ways));
        expect(d.push, switch (d.fam) {
          M6GFam.branch => M6GPush.b,
          M6GFam.main => d.swollen ? isIn([M6GPush.b, M6GPush.c]) : M6GPush.b,
          M6GFam.ug => isIn([M6GPush.a, M6GPush.d, M6GPush.e]),
          M6GFam.dtrOil => M6GPush.g,
          M6GFam.coord || M6GFam.ltWay => M6GPush.f,
        });
        sigs.add('${d.fam}${d.stuck}${d.partSeat}${d.leads}${d.bank}${d.swollen}${d.kva}${d.twist}${d.push}${d.feederNo}');
        // Never the same family twice in a row.
        for (final a in M6GFam.values) {
          expect(dealM6G(math.Random(s), avoid: a).fam, isNot(a));
        }
      }
      expect(fams, M6GFam.values.toSet());
      expect(pushes, M6GPush.values.toSet());
      expect(sigs.length, greaterThan(400));
      expect(stuck, inInclusiveRange(40, 200));
      expect(part, inInclusiveRange(40, 200));
      expect(bad, greaterThan(150));
      expect(swollen, greaterThan(20));
      expect(twist, greaterThan(100));
      expect(incomplete, greaterThan(100));
      expect(tie, inInclusiveRange(20, 120));
    });

    test('a clean play of every family (all device states) reaches the pass with no slip', () {
      final seen = <String>{};
      for (var s = 0; s < 400; s++) {
        final d = dealM6G(math.Random(s));
        final r = _cleanPlay(d);
        expect(r.passed, isTrue, reason: 'seed $s ${d.fam}');
        expect(r.slips, 0);
        expect(r.percent, 100);
        seen.add('${d.fam}${d.stuck != null}${d.partSeat != null}${d.swollen}${d.stripCut}${d.twist}${d.incomplete}');
      }
      expect(seen.length, greaterThan(40));
    });

    test('deadly: crew up without the PTW, without both ends open, without the earth; on a section in service', () {
      final c = _runWhere((d) => d.fam == M6GFam.ug && _plain(d));
      c.mark(M6GSec.main);
      c.radio(M6GReq.relay);
      expect(c.crew(M6GDev.ug).mistake, M6GMistakes.noPtw.m, reason: 'N8');
      final b = _runWhere((d) => d.fam == M6GFam.main && _plain(d));
      b.mark(M6GSec.main);
      expect(b.crew(M6GDev.span).mistake, M6GMistakes.noNonReclose.m, reason: 'R3: the recloser line');
      final i = _runWhere((d) => d.fam == M6GFam.ug && _plain(d));
      i.mark(M6GSec.main);
      i.radio(M6GReq.relay);
      _ptw(i, M6GReq.cbOffPtw);
      _open(i, M6GDev.ab1);
      expect(i.crew(M6GDev.ug).mistake, M6GMistakes.crewLive.m, reason: 'R1: one end only (6.2 myth)');
      final e = _runWhere((d) => d.fam == M6GFam.ug && _plain(d));
      e.mark(M6GSec.main);
      e.radio(M6GReq.relay);
      _ptw(e, M6GReq.cbOffPtw);
      _open(e, M6GDev.ab1);
      _open(e, M6GDev.ab2);
      e.test(M6GDev.ab1);
      expect(e.crew(M6GDev.ug).mistake, M6GMistakes.handsNoEarth.m, reason: 'X1: 0 V but no earth');
      // Earth first (a slip), never tested, then hands on: deadly (X1 / M5-2).
      final n = _runWhere((d) => d.fam == M6GFam.ug && _plain(d));
      n.mark(M6GSec.main);
      n.radio(M6GReq.relay);
      _ptw(n, M6GReq.cbOffPtw);
      _open(n, M6GDev.ab1);
      _open(n, M6GDev.ab2);
      expect(n.earth(M6GDev.ab1).mistake, M6GMistakes.earthUntested.m);
      expect(n.crew(M6GDev.ug).mistake, M6GMistakes.handsNoEarth.m, reason: 'X1: hands before the 0 V');
      expect(n.ended, isTrue);
      // The LT way: no PTW = deadly (X1, lesson 6.6 'PTW, PPE').
      final lp = _runWhere((d) => d.fam == M6GFam.ltWay);
      lp.mark(M6GSec.lt);
      lp.lt(M6GLt.offLock);
      lp.test(M6GDev.ltbox);
      expect(lp.crew(M6GDev.house).mistake, M6GMistakes.noPtw.m, reason: 'X1 on the LT path');
      final a = _runWhere((d) => d.fam == M6GFam.dtrOil && _plain(d));
      a.mark(M6GSec.dtr);
      expect(a.crew(M6GDev.span).mistake, M6GMistakes.crewLive.m, reason: 'the main is in service');
      expect(M6GMistakes.crewLive.m.textBn, contains('দুই প্রান্তে আইসোলেটর খুলে, টেস্টারে ডেড প্রমাণ করে, আর্থ দিয়ে'));
    });

    test('the tie AB-T (M6-10): left closed, ফিডার-5 (tripped) can come back — 0 V and dark, earth allowed, crew deadly; opened off-load; it stays open', () {
      M6GRun tied() {
        final r = _runWhere((d) => d.fam == M6GFam.ug && d.stuck == null && d.partSeat == null && !d.incomplete && d.tieClosed && d.leads.values.every((l) => l == M6GLead.ok));
        r.mark(M6GSec.main);
        r.radio(M6GReq.relay);
        _ptw(r, M6GReq.cbOffPtw);
        _open(r, M6GDev.ab1);
        _open(r, M6GDev.ab2);
        return r;
      }

      expect(M6GateLines.look(tied(), M6GDev.abT), contains('তিনটে ব্লেডই লাগানো'), reason: 'the lens shows it closed');
      final t = tied();
      expect(t.isolated(M6GSec.main), isFalse, reason: 'a source still connected');
      expect(t.isolated(M6GSec.main, tie: false), isTrue, reason: 'but dead now');
      expect(t.test(M6GDev.span).note, M6GateLines.testerDead, reason: 'honest with the dark windows');
      final te = t.earth(M6GDev.ab1);
      expect(te.mistake, isNull, reason: 'earths guard against ফিডার-5 coming back');
      expect(te.reason, isNull, reason: 'the ◆ waits for the tie');
      expect(t.crew(M6GDev.ug).mistake, M6GMistakes.crewLive.m, reason: 'R1: the tie left closed');
      // Earthed first, then the tie opened: its ◆ now.
      final late = tied();
      late.test(M6GDev.span);
      _ok(late.earth(M6GDev.ab1), 'earth');
      _readyAb(late, M6GDev.abT);
      expect(late.handleDrop(M6GDev.abT), isNull);
      final lo = late.stroke(M6GDev.abT, stalled: false);
      expect(lo.mistake, isNull);
      expect(lo.reason, M6GReason.tie);
      late.look(M6GDev.abT);
      expect(late.isolated(M6GSec.main), isTrue);
      // Opening it before the breaker OFF is confirmed is an opening on load.
      final early = _runWhere((d) => d.fam == M6GFam.ug && d.tieClosed);
      early.mark(M6GSec.main);
      early.look(M6GDev.abT);
      expect(early.handleDrop(M6GDev.abT)!.mistake, M6GMistakes.abOnLoad.m);
      // Opened after the OFF: the section is dead; the earth asks about the tie.
      final ok = tied();
      _open(ok, M6GDev.abT);
      expect(ok.test(M6GDev.span).note, M6GateLines.testerDead);
      final e = ok.earth(M6GDev.ab1);
      expect(e.mistake, isNull);
      expect(e.reason, M6GReason.tie);
      // A tie already open stays open: no cost, no stroke.
      final n = _runWhere((d) => d.fam == M6GFam.main && !d.tieClosed);
      n.mark(M6GSec.main);
      expect(n.abOpen[M6GDev.abT], isTrue);
      final keep = n.handleDrop(M6GDev.abT)!;
      expect(keep.mistake, isNull);
      expect(keep.say, M6GateLines.tieStays);
      expect(n.slips, 0);
      // On another family the tie is open and the main is in service.
      final a = _runWhere((d) => d.fam == M6GFam.coord);
      expect(a.abOpen[M6GDev.abT], isTrue);
    });

    test('deadly: an AB opened on load or before OFF is confirmed (R4, X3/N2), closed after the line is ON (R5)', () {
      final a = _runWhere((d) => d.fam == M6GFam.branch && _plain(d));
      a.mark(M6GSec.branch);
      a.look(M6GDev.ab1);
      expect(a.handleDrop(M6GDev.ab1)!.mistake, M6GMistakes.abOnLoad.m, reason: 'the main carries load');
      final c = _runWhere((d) => d.fam == M6GFam.ug && _plain(d));
      c.mark(M6GSec.main);
      c.look(M6GDev.ab1);
      expect(c.handleDrop(M6GDev.ab1)!.mistake, M6GMistakes.abOnLoad.m, reason: 'the breaker not confirmed OFF yet');
      final d = _runWhere((d) => d.fam == M6GFam.coord && _plain(d));
      d.mark(M6GSec.dtr);
      _ptw(d, M6GReq.dtrPtw);
      d.look(M6GDev.dtr);
      expect(d.handleDrop(M6GDev.dtr)!.mistake, M6GMistakes.abOnLoad.m, reason: 'N2: the DTR AB before its LT switch');
      // After the ON, closing an AB is closing on load.
      final r = _runWhere((d) => d.fam == M6GFam.ug && _plain(d) && !d.bank);
      r.mark(M6GSec.main);
      r.radio(M6GReq.relay);
      _ptw(r, M6GReq.cbOffPtw);
      _open(r, M6GDev.ab1);
      _open(r, M6GDev.ab2);
      r.test(M6GDev.ab1);
      r.earth(M6GDev.ab1);
      r.crew(M6GDev.ug);
      r.pick(M6GDeck.joint, M6GCard.right);
      r.earth(M6GDev.ab1);
      _close(r, M6GDev.ab1);
      expect(r.radio(M6GReq.cbOn).note, M6GateLines.onNoLight, reason: 'AB-2 still open');
      expect(r.handleDrop(M6GDev.ab2), isNull);
      expect(r.stroke(M6GDev.ab2, stalled: false).mistake, M6GMistakes.abCloseOnLoad.m);
      // The F-E restore the wrong way round: LT ON, then the DTR AB.
      final e = _runWhere((d) => d.fam == M6GFam.coord && _plain(d) && !d.stripCut);
      e.mark(M6GSec.dtr);
      _ptw(e, M6GReq.dtrPtw);
      e.lt(M6GLt.offLock);
      e.test(M6GDev.ltbox);
      e.crew(M6GDev.ltbox);
      e.pick(M6GDeck.jugaad, M6GCard.right);
      _open(e, M6GDev.dtr);
      e.test(M6GDev.dtr);
      e.earth(M6GDev.dtr);
      e.crew(M6GDev.dtr);
      e.pick(M6GDeck.hg, M6GCard.right);
      e.earth(M6GDev.dtr);
      expect(e.lt(M6GLt.on).lit, isFalse);
      expect(e.handleDrop(M6GDev.dtr), isNull);
      expect(e.stroke(M6GDev.dtr, stalled: false).mistake, M6GMistakes.abCloseOnLoad.m);
    });

    test('deadly: an earth on a live section (R29), the bank touched before the rod (R8), the hook before the clamp (R9)', () {
      final l = _runWhere((d) => d.fam == M6GFam.ug && _plain(d));
      l.mark(M6GSec.main);
      expect(l.earth(M6GDev.ab1).mistake, M6GMistakes.earthLive.m);
      final st = _runWhere((d) => d.fam == M6GFam.branch && d.stuck == M6GDev.abA && !d.incomplete && d.leads[M6GDev.abA] == M6GLead.ok);
      st.mark(M6GSec.branch);
      st.radio(M6GReq.s3Info);
      _ptw(st, M6GReq.rcNrPtw);
      st.look(M6GDev.abA);
      expect(st.handleDrop(M6GDev.abA), isNull);
      st.stroke(M6GDev.abA, stalled: false);
      expect(st.stuck, M6GDev.abA);
      expect(st.test(M6GDev.abA).note, M6GateLines.testerDead, reason: 'S-3 is open: nothing feeds the stuck phase');
      final sto = st.earth(M6GDev.abA);
      expect(sto.mistake, M6GMistakes.gapsUnseen.m, reason: 'R35 / M6-3: a slip, not deadly');
      expect(st.ended, isFalse);
      // Seen stuck and earthed anyway: the same slip.
      final ss = _runWhere((d) => d.fam == M6GFam.main && d.stuck == M6GDev.ab1 && !d.incomplete && d.leads[M6GDev.ab1] == M6GLead.ok);
      ss.mark(M6GSec.main);
      _ptw(ss, M6GReq.rcNrPtw);
      ss.look(M6GDev.ab1);
      expect(ss.handleDrop(M6GDev.ab1), isNull);
      ss.stroke(M6GDev.ab1, stalled: false);
      expect(ss.look(M6GDev.ab1).note, contains('আটকে'));
      _open(ss, M6GDev.ab2);
      ss.test(M6GDev.ab1);
      expect(ss.earth(M6GDev.ab1).mistake, M6GMistakes.gapsUnseen.m, reason: 'a stuck phase logged open');
      final bk = _deadMain((d) => d.swollen);
      expect(bk.crew(M6GDev.bank).mistake, M6GMistakes.bankTouch.m);
      final hk = _deadMain((d) => d.swollen);
      expect(hk.rodHook(0).mistake, M6GMistakes.rodHook.m);
    });

    test('deadly: the crew decks (recharge, non-fuse, bare hands, strip) and charging before the cause or with the earth on', () {
      final o = _runWhere((d) => d.fam == M6GFam.dtrOil);
      expect(o.pick(M6GDeck.oil, M6GCard.deadly).mistake, M6GMistakes.recharge.m);
      for (final dk in [M6GDeck.jugaad, M6GDeck.hg, M6GDeck.hrc]) {
        expect(_runWhere((d) => true).pick(dk, M6GCard.deadly).mistake, M6GMistakes.nonFuse.m);
      }
      expect(_runWhere((d) => true).pick(M6GDeck.nick, M6GCard.deadly).mistake, M6GMistakes.bareAb.m);
      expect(_runWhere((d) => true).pick(M6GDeck.strip, M6GCard.deadly).mistake, M6GMistakes.stripCut.m);
      // ON before the cause is fixed; ON with the earth still on.
      final f = _deadMain((d) => !d.swollen);
      expect(f.radio(f.fam == M6GFam.ug ? M6GReq.cbOn : M6GReq.rcNormal).mistake, M6GMistakes.chargeCrew.m, reason: 'the earth is on');
      final g = _deadMain((d) => !d.swollen);
      g.earth(M6GDev.ab1);
      expect(g.radio(g.fam == M6GFam.ug ? M6GReq.cbOn : M6GReq.rcNormal).mistake, M6GMistakes.chargeFault.m, reason: 'the cause is still there');
      // F-D: the burnt DTR's AB লাগানো = recharge; F-E with the strip cut.
      final dd = _runWhere((d) => d.fam == M6GFam.dtrOil && _plain(d));
      dd.mark(M6GSec.dtr);
      dd.lt(M6GLt.offLock);
      _ptw(dd, M6GReq.dtrPtw);
      _open(dd, M6GDev.dtr);
      expect(dd.handleDrop(M6GDev.dtr), isNull);
      expect(dd.stroke(M6GDev.dtr, stalled: false).mistake, M6GMistakes.recharge.m);
      final s = _runWhere((d) => d.fam == M6GFam.coord && _plain(d) && d.stripCut);
      s.mark(M6GSec.dtr);
      _ptw(s, M6GReq.dtrPtw);
      s.lt(M6GLt.offLock);
      s.test(M6GDev.ltbox);
      s.crew(M6GDev.ltbox);
      s.pick(M6GDeck.jugaad, M6GCard.right);
      // The strip never looked at: the deck goes straight to the HG.
      s.handleDrop(M6GDev.dtr); // a slip: the lead not looked at
      expect(s.slips, 1);
      expect(s.handleDrop(M6GDev.dtr), isNull);
      s.stroke(M6GDev.dtr, stalled: false);
      s.test(M6GDev.dtr);
      s.bladesSeen.add(M6GDev.dtr);
      s.earth(M6GDev.dtr);
      expect(s.crew(M6GDev.dtr).deck, M6GDeck.hg, reason: 'the cut strip was never seen');
      s.pick(M6GDeck.hg, M6GCard.right);
      s.earth(M6GDev.dtr);
      expect(s.handleDrop(M6GDev.dtr), isNull);
      expect(s.stroke(M6GDev.dtr, stalled: false).mistake, M6GMistakes.stripCut.m, reason: 'M6-1');
      // LT work with the supply on (X4).
      final lt = _runWhere((d) => d.fam == M6GFam.ltWay);
      lt.mark(M6GSec.lt);
      expect(lt.crew(M6GDev.house).mistake, M6GMistakes.liveLt.m);
    });

    test('listening to the coworker is deadly in every variant (X2)', () {
      for (final p in M6GPush.values) {
        final r = _runWhere((d) => d.push == p);
        expect(r.listened().deadly, isTrue, reason: '$p');
        expect(r.ended, isTrue);
      }
      // He waits on the path's decisive control.
      final g = _runWhere((d) => d.push == M6GPush.g);
      g.mark(M6GSec.dtr);
      expect(g.coworkerMoment(M6GTok.crew, M6GDev.dtr), isTrue);
      expect(g.coworkerMoment(M6GTok.eye, M6GDev.dtr), isFalse);
      final f = _runWhere((d) => d.push == M6GPush.f);
      expect(f.coworkerMoment(M6GTok.crew, M6GDev.ltbox), isFalse, reason: 'not before the find');
      f.mark(f.fam.sec);
      expect(f.coworkerMoment(M6GTok.crew, M6GDev.ltbox), isTrue);
      // (d): the handle on AB-1 before the OFF is confirmed; listening = an AB on load.
      final dd = _runWhere((d) => d.push == M6GPush.d);
      dd.mark(M6GSec.main);
      expect(dd.coworkerMoment(M6GTok.handle, M6GDev.ab1), isTrue);
      expect(dd.push, M6GPush.d);
      expect(dd.listened(), M6GMistakes.abOnLoad.m);
      // (d) with the PTW first: he cannot be skipped — (a) at the crew drop.
      final dp = _runWhere((d) => d.push == M6GPush.d && !d.incomplete);
      dp.mark(M6GSec.main);
      _ptw(dp, M6GReq.cbOffPtw);
      expect(dp.coworkerMoment(M6GTok.handle, M6GDev.ab1), isFalse);
      expect(dp.push, M6GPush.a);
      expect(dp.coworkerMoment(M6GTok.crew, M6GDev.ug), isTrue);
      expect(dp.listened(), M6GMistakes.crewLive.m);
      // (c): the first crew drop on the main section, the bank or the damage.
      final cc = _runWhere((d) => d.push == M6GPush.c);
      cc.mark(M6GSec.main);
      expect(cc.coworkerMoment(M6GTok.crew, M6GDev.span), isTrue, reason: 'cannot be skipped by leaving the bank');
      expect(cc.push, M6GPush.c);
      final cb = _runWhere((d) => d.push == M6GPush.c);
      cb.mark(M6GSec.main);
      expect(cb.coworkerMoment(M6GTok.crew, M6GDev.bank), isTrue);
    });

    test('slips: wrong section, needless outage, asking again, the lead, a stall, earth before 0 V, gaps unseen, relay', () {
      final w = _runWhere((d) => d.fam == M6GFam.branch);
      expect(w.mark(M6GSec.dtr).mistake, M6GMistakes.wrongSec.m);
      expect(w.marked, isFalse);
      expect(w.radio(M6GReq.s3Open).say, M6GateLines.markFirst, reason: 'nothing but looking before the find');
      w.mark(M6GSec.branch);
      expect(w.radio(M6GReq.cbOffPtw).mistake, M6GMistakes.needless.m, reason: 'S-3 already isolated the branch');
      expect(w.radio(M6GReq.dtrOff).mistake, M6GMistakes.needless.m);
      final a = _runWhere((d) => d.fam == M6GFam.main && _plain(d));
      a.mark(M6GSec.main);
      _ptw(a, M6GReq.rcNrPtw);
      expect(a.radio(M6GReq.rcNrPtw).mistake, M6GMistakes.askAgain.m);
      expect(a.handleDrop(M6GDev.ab1)!.mistake, M6GMistakes.leadBad.m, reason: 'handle grabbed before looking at the lead');
      expect(a.handleDrop(M6GDev.ab1), isNull, reason: 'now it is looked at');
      expect(a.stroke(M6GDev.ab1, stalled: true).mistake, M6GMistakes.stall.m);
      expect(a.abOpen[M6GDev.ab1] ?? false, isFalse, reason: 'a stall leaves it as it was');
      final bad = _runWhere((d) => d.fam == M6GFam.main && !d.incomplete && d.leads[M6GDev.ab1] == M6GLead.cut);
      bad.mark(M6GSec.main);
      _ptw(bad, M6GReq.rcNrPtw);
      bad.look(M6GDev.ab1);
      final lead = bad.handleDrop(M6GDev.ab1)!;
      expect(lead.mistake, M6GMistakes.leadBad.m, reason: 'M6-1: a cut lead is a slip');
      expect(lead.note, M6GateLines.leadFixed, reason: 'the crew fixes it after the slip');
      expect(bad.handleDrop(M6GDev.ab1), isNull);
      final e = _runWhere((d) => d.fam == M6GFam.main && _plain(d));
      e.mark(M6GSec.main);
      _ptw(e, M6GReq.rcNrPtw);
      _open(e, M6GDev.ab1);
      _open(e, M6GDev.ab2);
      expect(e.earth(M6GDev.ab1).mistake, M6GMistakes.earthUntested.m, reason: 'N3');
      final gp = _runWhere((d) => d.fam == M6GFam.main && _plain(d));
      gp.mark(M6GSec.main);
      _ptw(gp, M6GReq.rcNrPtw);
      _open(gp, M6GDev.ab1);
      gp.look(M6GDev.ab2);
      gp.handleDrop(M6GDev.ab2);
      gp.stroke(M6GDev.ab2, stalled: false);
      gp.test(M6GDev.ab1);
      expect(gp.earth(M6GDev.ab1).mistake, M6GMistakes.gapsUnseen.m, reason: 'R35');
      final rl = _runWhere((d) => d.fam == M6GFam.ug && _plain(d) && !d.bank);
      rl.mark(M6GSec.main);
      _ptw(rl, M6GReq.cbOffPtw);
      _open(rl, M6GDev.ab1);
      _open(rl, M6GDev.ab2);
      rl.test(M6GDev.ab1);
      rl.earth(M6GDev.ab1);
      final noRelay = rl.crew(M6GDev.ug);
      expect(noRelay.mistake, M6GMistakes.noRelay.m);
      expect(noRelay.deck, M6GDeck.joint, reason: 'the deck still opens after the slip');
    });

    test('slips: the rod early, a swollen unit left, a part-seated blade, re-fusing before the cause, LT not locked, deck slips', () {
      final rod = _deadMain((d) => d.swollen);
      rod.handleDrop(M6GDev.bank);
      rod.rodClamp();
      expect(rod.rodHook(0).mistake, M6GMistakes.rodEarly.m, reason: 'R10: before 5 game minutes');
      expect(rod.rodHook(1).mistake, isNull, reason: 'once a play');
      final o2 = rod.rodHook(2);
      expect(o2.reason, isNull, reason: 'no ◆ after the slip');
      expect(rod.rodded, hasLength(3));
      // A swollen unit left at the ON.
      final sw = _deadMain((d) => d.swollen);
      sw.crew(sw.fam == M6GFam.ug ? M6GDev.ug : M6GDev.span);
      sw.pick(sw.fam == M6GFam.ug ? M6GDeck.joint : M6GDeck.storm, M6GCard.right);
      sw.earth(M6GDev.ab1);
      _close(sw, M6GDev.ab1);
      _close(sw, M6GDev.ab2);
      final on = sw.radio(sw.fam == M6GFam.ug ? M6GReq.cbOn : M6GReq.rcNormal);
      expect(on.mistake, M6GMistakes.swollenLeft.m);
      expect(on.lit, isTrue);
      // A part-seated blade not re-seated at the ON.
      final ps = _runWhere((d) => d.fam == M6GFam.branch && d.partSeat == M6GDev.abA && d.stuck == null && !d.incomplete && d.leads[M6GDev.abA] == M6GLead.ok);
      ps.mark(M6GSec.branch);
      ps.radio(M6GReq.s3Info);
      _ptw(ps, M6GReq.rcNrPtw);
      _open(ps, M6GDev.abA);
      ps.test(M6GDev.abA);
      ps.earth(M6GDev.abA);
      ps.crew(M6GDev.branch);
      ps.pick(M6GDeck.storm, M6GCard.right);
      ps.earth(M6GDev.abA);
      ps.handleDrop(M6GDev.abA);
      ps.stroke(M6GDev.abA, stalled: false);
      expect(ps.partSeat, M6GDev.abA);
      final psOn = ps.radio(M6GReq.s3Close);
      expect(psOn.mistake, M6GMistakes.partSeat.m);
      // The HG before the jugaad is out; the HRC before the nick is sealed.
      final hg = _runWhere((d) => d.fam == M6GFam.coord);
      expect(hg.pick(M6GDeck.hg, M6GCard.right).mistake, M6GMistakes.refuseEarly.m);
      expect(hg.hgDone, isFalse);
      final hr = _runWhere((d) => d.fam == M6GFam.ltWay);
      expect(hr.pick(M6GDeck.hrc, M6GCard.right).mistake, M6GMistakes.refuseEarly.m);
      // LT switch OFF only (no lock, no tag): one slip, the deck opens.
      final lt = _runWhere((d) => d.fam == M6GFam.ltWay);
      lt.mark(M6GSec.lt);
      _ptw(lt, M6GReq.dtrPtw);
      lt.lt(M6GLt.offOnly);
      final n4 = lt.crew(M6GDev.house);
      expect(n4.mistake, M6GMistakes.ltNoLock.m);
      expect(n4.deck, M6GDeck.nick);
      // Every deck's slip card is a slip with a lesson source.
      final slipOf = {
        M6GDeck.storm: M6GMistakes.stormLeft, M6GDeck.joint: M6GMistakes.selfJoint, M6GDeck.oil: M6GMistakes.tankOpen,
        M6GDeck.jugaad: M6GMistakes.refuseEarly, M6GDeck.hg: M6GMistakes.wrongRating, M6GDeck.strip: M6GMistakes.stripLeft,
        M6GDeck.nick: M6GMistakes.nickOpen, M6GDeck.hrc: M6GMistakes.wrongHrc, M6GDeck.bank: M6GMistakes.swollenLeft,
        M6GDeck.twistLcd: M6GMistakes.meterWrong, M6GDeck.twistBlank: M6GMistakes.meterWrong,
      };
      for (final e in slipOf.entries) {
        final r = _runWhere((d) => true);
        expect(r.pick(e.key, M6GCard.slip).mistake, e.value.m, reason: '${e.key}');
        expect(r.slips, 1);
      }
      // The HRC without gloves and the puller after a proven isolation: a slip (A5/X4).
      final pp = _runWhere((d) => true);
      expect(pp.pick(M6GDeck.hrc, M6GCard.slip, text: M6GateLines.hrcNoPpe.first).mistake, M6GMistakes.noPpe.m);
      expect(pp.hrcDone, isFalse);
      expect(M6GMistakes.noPpe.m.deadly, isFalse);
      // Ruling M6-4: the tank opened on a dead, earthed DTR is a slip, not deadly.
      expect(M6GMistakes.tankOpen.m.deadly, isFalse);
    });

    test('the crew decks: one right, a deadly where the deck has one, three different cards', () {
      final rng = math.Random(3);
      for (final dk in M6GDeck.values) {
        for (var i = 0; i < 20; i++) {
          final r = _runWhere((d) => true);
          final cards = r.deckFor(dk, rng);
          expect(cards, hasLength(3));
          expect(cards.map((c) => c.$1).toSet(), hasLength(3));
          expect(cards.where((c) => c.$2 == M6GCard.right), hasLength(1));
          final hasDeadly = M6GateLines.deckCards(dk, M6GCard.deadly).isNotEmpty &&
              {M6GDeck.oil, M6GDeck.jugaad, M6GDeck.hg, M6GDeck.strip, M6GDeck.nick, M6GDeck.hrc}.contains(dk);
          expect(cards.where((c) => c.$2 == M6GCard.deadly), hasLength(hasDeadly ? 1 : 0), reason: '$dk');
        }
      }
      // The HG ratings follow lesson 6.3 point 0.
      expect(m6gHgAmp(25), '2A');
      expect(m6gHgAmp(63), '5A');
      expect(m6gHgAmp(100), '10A');
    });

    test('option libraries: reasons 1 right of ≥ 2, wrong of ≥ 5; every card set and chip set within 1.3×', () {
      for (final r in M6GReason.values) {
        for (final f in M6GFam.values) {
          final right = M6GateLines.whyRight(r, fam: f);
          final wrong = M6GateLines.whyWrong(r);
          expectLibrary('${r.name} ${f.name}', right, wrong);
          expectSameLength('${r.name} ${f.name}', [...right, ...wrong]);
        }
      }
      for (final dk in M6GDeck.values) {
        for (final kva in [25, 63, 100]) {
          final all = M6GateLines.deckAll(dk, kva: kva);
          expect(M6GateLines.deckCards(dk, M6GCard.right, kva: kva), isNotEmpty);
          expect(all.length, greaterThanOrEqualTo(3), reason: '$dk');
          expect(all.toSet().length, all.length, reason: '$dk duplicates');
          expectSameLength('deck $dk $kva', all);
        }
      }
      for (final cw in M6GateLines.coworkers) {
        expectLibrary('coworker', cw.right, cw.wrong);
        expectSameLength('coworker ${cw.line}', [...cw.right, ...cw.wrong]);
      }
      for (final d in m6gRadioDevs) {
        expectSameLength('radio ${d.name}', [for (final q in m6gReqsOf(d)) M6GateLines.req(q)]);
      }
      expectSameLength('LT switch', [for (final c in M6GLt.values) M6GateLines.lt(c)]);
    });

    test('English digits on screen; owner term rules in the new text', () {
      final bnDigit = RegExp('[০-৯]');
      final lines = <String>[
        ...M6GateLines.newGuideLines,
        ...M6GateLines.newRivalLines,
        ...M6GateLines.excuses,
        for (final r in M6GReason.values) ...[for (final f in M6GFam.values) ...M6GateLines.whyRight(r, fam: f), ...M6GateLines.whyWrong(r), M6GateLines.caught(r)],
        for (final dk in M6GDeck.values) for (final k in [25, 63, 100]) ...M6GateLines.deckAll(dk, kva: k),
        for (final cw in M6GateLines.coworkers) ...[...cw.right, ...cw.wrong],
        for (final q in M6GReq.values) M6GateLines.req(q),
        for (final c in M6GLt.values) M6GateLines.lt(c),
        for (final d in M6GDev.values) M6GateLines.dev(d),
        for (final t in M6GTok.values) M6GateLines.tok(t),
      ];
      for (var s = 0; s < 150; s++) {
        final d = dealM6G(math.Random(s));
        final r = M6GRun(d);
        lines.add(M6GateLines.call(d.feederNo));
        for (final dev in M6GDev.values) {
          lines.add(M6GateLines.look(r, dev));
        }
        for (final q in M6GReq.values) {
          lines.add(M6GateLines.reply(d, q, complete: true));
          lines.add(M6GateLines.reply(d, q, complete: false));
        }
      }
      for (final l in lines) {
        expect(l, isNotEmpty);
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
      // Owner term rules (new text only; the lesson myths are quoted as they are).
      final myths = {M6GateLines.pushA.line, M6GateLines.pushB.line, M6GateLines.pushC.line, M6GateLines.pushD.line, M6GateLines.pushF.line};
      for (final l in lines.where((l) => !myths.contains(l))) {
        expect(RegExp('মৃত(?!্যু)').hasMatch(l), isFalse, reason: 'ডেড, not মৃত: $l');
        expect(l, isNot(contains('এলটি')), reason: l);
        expect(l, isNot(contains('কেভি')), reason: l);
        expect(l, isNot(contains('অফ ')), reason: 'OFF, not অফ: $l');
        expect(l, isNot(contains('AB বন্ধ')), reason: l);
        expect([0x09DF, 0x09DC, 0x09DD].any((c) => l.contains(String.fromCharCode(c))), isFalse, reason: 'base + nukta: $l');
      }
    });

    test("the coworker's lines: lesson myths word for word, recorded or listed; every spoken line listed", () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List;
      String myth(String id, int i) {
        final c = lessons.firstWhere((x) => (x as Map)['id'] == id) as Map;
        return _nk(((c['content'] as Map)['myth_buster'] as Map)['myths'][i]['myth'] as String);
      }

      expect(M6GateLines.pushA.line, myth('6.2', 0));
      expect(M6GateLines.pushB.line, myth('6.8', 0));
      expect(M6GateLines.pushC.line, myth('6.7', 0));
      expect(M6GateLines.pushD.line, myth('6.4', 0));
      expect(LearnVoice.resolve(M6GateLines.pushD.line, rival: true), isNotNull, reason: '(d) reuses the recorded 6.4 myth clip');
      expect(M6GateLines.pushF.line, myth('6.9', 1));
      for (final cw in M6GateLines.coworkers) {
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: cw.exitLine);
        expect(M6GateLines.newRivalLines, contains(cw.line));
      }
      final unrecorded = [for (final cw in M6GateLines.coworkers) if (LearnVoice.resolve(cw.line, rival: true) == null) cw.line];
      // ignore: avoid_print
      print('M6 gate rival lines with no clip yet: ${unrecorded.length}\n${unrecorded.join('\n')}');
      final guide = M6GateLines.newGuideLines;
      for (final l in [
        M6GateLines.intro, ...M6GateLines.tasks, ...M6GateLines.tapWhy, M6GateLines.markFirst, M6GateLines.radioWhere,
        M6GateLines.noUse, M6GateLines.lit, M6GateLines.refused, M6GateLines.fixRight, M6GateLines.fail,
        for (final r in M6GReason.values) M6GateLines.question(r),
        for (final cw in M6GateLines.coworkers) ...cw.asks,
        M6GateLines.promoted(M6GateLines.rankTo),
        for (final m in M6GMistakes.all) m.textBn,
      ]) {
        expect(guide, contains(l), reason: 'listed for the voice pass: $l');
      }
      expect(M6GateLines.badge, 'যন্ত্র গুরু');
      expect(M6GateLines.promoted('সিনিয়র'), contains('যন্ত্র গুরু'));
    });

    test('the mistakes: unique keys, pictures, 6.x lesson points, the module table after the rulings', () {
      final keys = <String>{};
      for (final x in M6GMistakes.values) {
        expect(keys.add(x.m.key), isTrue, reason: x.m.key);
        expect(x.m.key, startsWith('m6/gate/'));
        expect(File(x.m.art).existsSync(), isTrue, reason: x.m.art);
        expect(x.m.lessonPoint, isNotNull);
        expect(x.lessonId, startsWith('6.'));
        expect(M6GMistakes.lessonOf(x.m), x.lessonId);
      }
      final deadly = {
        M6GMistakes.crewLive, M6GMistakes.noNonReclose, M6GMistakes.noPtw, M6GMistakes.abOnLoad, M6GMistakes.abCloseOnLoad,
        M6GMistakes.earthLive, M6GMistakes.handsNoEarth, M6GMistakes.bankTouch, M6GMistakes.rodHook, M6GMistakes.nonFuse,
        M6GMistakes.liveLt, M6GMistakes.recharge, M6GMistakes.bareAb, M6GMistakes.stripCut, M6GMistakes.chargeCrew,
        M6GMistakes.chargeFault,
      };
      for (final x in M6GMistakes.values) {
        expect(x.m.deadly, deadly.contains(x), reason: x.m.key);
      }
      // Ruling texts carried.
      expect(M6GMistakes.stall.m.textBn, contains('দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত'));
      expect(M6GMistakes.swollenLeft.m.textBn, contains('ফোলা ক্যাপাসিটর = ভেতরে ফল্ট, ফেটে যেতে পারে — সার্ভিস থেকে সরান'));
      expect(M6GMistakes.leadBad.m.deadly, isFalse, reason: 'M6-1: the handle earth lead is a slip');
      final used = {for (final x in M6GMistakes.values) x.m.art.split('/').last};
      final files = {for (final f in Directory('assets/game/art/m6_gate_storm_feeder').listSync()) f.uri.pathSegments.last};
      expect(files, used, reason: 'every picture in the folder is used');
    });

    test('the panorama: devices never overlap, every device reachable by pan, the belt on screen', () {
      for (final h in [560.0, 700.0, 900.0]) {
        final g = M6GGeo(h, 0);
        for (var i = 0; i < M6GDev.values.length; i++) {
          final r = g.devWorld(i);
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
          for (var j = i + 1; j < M6GDev.values.length; j++) {
            expect(r.overlaps(g.devWorld(j)), isFalse, reason: 'devices $i/$j at $h');
          }
          final s = g.dev(i, M6GGeo.panFor(i));
          expect(s.center.dx, inInclusiveRange(0, 360), reason: 'device $i reachable');
          expect(g.pano.contains(Offset(s.center.dx.clamp(1, 359), s.center.dy)), isTrue, reason: 'device $i in the panorama at $h');
        }
        for (final t in g.tokens) {
          expect(t.left, greaterThanOrEqualTo(0));
          expect(t.right, lessThanOrEqualTo(360));
          expect(t.width, greaterThanOrEqualTo(44));
        }
        expect(g.tokens, hasLength(7));
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
      final p = M6GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6GateStormFeederPage(ctx: _ctx, pack: _pack, muted: true, seed: 4, probe: p))));
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
      testWidgets('idle on the panorama draws zero frames (reduce motion: $reduce)', (t) async {
        if (reduce) {
          t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = M6GateProbe();
        final c = await _openPage(t, 7, p);
        expect(p.phase, 'idle');
        await _pump(t, 14000);
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(frames, lessThan(12), reason: 'idle panorama');
        expect(t.takeException(), isNull);
        await _closePage(t, c);
      });
    }

    testWidgets('a full clean play (F-C): find ◆, relay ◆, PTW, isolate, 0 V, earth ◆, the coworker held and refused, the jointer ◆, restore ◆ → rank-up', (t) async {
      final seed = _seedWhere((d) => d.fam == M6GFam.ug && d.push == M6GPush.a && _plain(d) && !d.bank && d.twist == M6GTwist.none);
      final p = M6GateProbe();
      final c = await _openPage(t, seed, p);
      // Find: read the breaker, chalk the main line → ◆.
      await _use(t, p, M6GTok.eye, M6GDev.cb);
      expect(p.phase, 'lens');
      expect(find.textContaining('শর্ট সার্কিট'), findsWidgets, reason: 'the lens shows the relay window');
      await _tapKey(t, 'm6g-lens-close');
      await _tapKey(t, 'm6g-chalk');
      expect(p.phase, 'chalk');
      await _tapKey(t, 'm6g-sec-main');
      await _pickDeckRight(t, p);
      expect(p.run!.marked, isTrue);
      // The relay logged → ◆; the PTW with the breaker OFF confirmed.
      await _radio(t, p, M6GDev.cb, M6GReq.relay);
      await _pickDeckRight(t, p);
      expect(p.run!.relayLogged, isTrue);
      await _radio(t, p, M6GDev.cb, M6GReq.cbOffPtw);
      expect(p.run!.complete, contains(M6GReq.cbOffPtw));
      // Both ends: look (the lead), one firm stroke, look (the gaps).
      for (final ab in [M6GDev.ab1, M6GDev.ab2]) {
        await _look(t, p, ab);
        await _stroke(t, p, ab);
        expect(p.run!.abOpen[ab], isTrue, reason: '$ab open');
        await _look(t, p, ab);
      }
      await _use(t, p, M6GTok.tester, M6GDev.ab1);
      expect(p.run!.tested, contains(M6GSec.main));
      await _use(t, p, M6GTok.earth, M6GDev.ab1);
      await _pickDeckRight(t, p);
      expect(p.run!.earthed, contains(M6GSec.main));
      // The crew on the road crossing: he comes first, the drop waits for him.
      await _use(t, p, M6GTok.crew, M6GDev.ug);
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he comes at the decisive control');
      expect(p.phase, 'idle', reason: 'the crew drop waited for him');
      expect(find.text(M6GateLines.pushA.line), findsWidgets);
      await _pickDeckRight(t, p);
      await _pump(t, 1500);
      expect(p.run!.ended, isFalse);
      // Now the crew goes: the 'কী কাজ?' deck → the jointer → ◆.
      await _use(t, p, M6GTok.crew, M6GDev.ug);
      await _until(t, () => p.phase == 'deck', maxMs: 3000);
      await _pickDeckRight(t, p);
      await _until(t, () => p.run!.fixed && p.busy, maxMs: 4000, reason: 'the joint ◆');
      await _pickDeckRight(t, p);
      // Restore: earths off, AB লাগানো both, then the breaker ON → ◆ → pass.
      await _use(t, p, M6GTok.earth, M6GDev.ab1);
      expect(p.run!.earthed, isEmpty);
      await _stroke(t, p, M6GDev.ab1);
      await _stroke(t, p, M6GDev.ab2);
      expect(p.run!.abOpen[M6GDev.ab1], isFalse);
      expect(p.run!.abOpen[M6GDev.ab2], isFalse);
      expect(p.run!.abOpen[M6GDev.abT], isTrue, reason: 'the tie stays open');
      await _radio(t, p, M6GDev.cb, M6GReq.cbOn);
      expect(p.run!.restored, isTrue);
      await _pickDeckRight(t, p);
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000);
      expect(find.text(M6GateLines.rankTo), findsOneWidget);
      expect(find.text(M6GateLines.badge), findsOneWidget);
      expect(find.text(M6GateLines.caughtPush), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['m6/gate'], 'cleared');
      expect(save.rankIndex, 6, reason: 'অ্যাডভান্সড → সিনিয়র');
      expect(save.mistakes, isEmpty);
      expect(save.starsByRung['m6/gate'] ?? 0, greaterThanOrEqualTo(2));
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
      await _closePage(t, c);
    });

    testWidgets('a deadly move plays out: freeze, then the near-miss card', (t) async {
      final seed = _seedWhere((d) => d.fam == M6GFam.branch);
      final p = M6GateProbe();
      final c = await _openPage(t, seed, p);
      await _tapKey(t, 'm6g-chalk');
      await _tapKey(t, 'm6g-sec-branch');
      await _pickDeckRight(t, p);
      // AB-1 on the loaded main line (R4).
      await _use(t, p, M6GTok.handle, M6GDev.ab1);
      await _until(t, () => p.phase == 'freeze', maxMs: 3000, reason: 'an AB on load');
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('harm')), findsOneWidget);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M6GMistakes.abOnLoad.m.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['m6/gate'], isNot('cleared'));
      await _closePage(t, c);
    });

    testWidgets("listening to the coworker is deadly (F-F: 'মোটা তার বা পাত')", (t) async {
      final seed = _seedWhere((d) => d.fam == M6GFam.ltWay);
      final p = M6GateProbe();
      final c = await _openPage(t, seed, p);
      await _tapKey(t, 'm6g-chalk');
      await _tapKey(t, 'm6g-sec-lt');
      await _pickDeckRight(t, p);
      await _use(t, p, M6GTok.handle, M6GDev.ltbox);
      expect(p.phase, 'lt');
      await _tapKey(t, 'm6g-lt-offLock');
      await t.longPress(find.byKey(const ValueKey('m6g-send')), warnIfMissed: false);
      await _pump(t, 300);
      expect(p.run!.ltOff, isTrue);
      await _use(t, p, M6GTok.crew, M6GDev.ltbox);
      await _until(t, () => p.coworkerUp, maxMs: 4000, reason: 'he comes at the fuse fit');
      await _waitDeckUp(t);
      final wrong = [for (final x in M6GateLines.pushF.wrong) if (_label(x).evaluate().isNotEmpty) _label(x)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      await _until(t, () => p.phase == 'freeze', maxMs: 4000);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M6GMistakes.nonFuse.m.textBn), findsOneWidget);
      await _closePage(t, c);
    });

    testWidgets('three slips strike the gate out (a slip shows its card first)', (t) async {
      final seed = _seedWhere((d) => d.fam == M6GFam.dtrOil);
      final p = M6GateProbe();
      final c = await _openPage(t, seed, p);
      for (var n = 1; n <= 3; n++) {
        await _tapKey(t, 'm6g-chalk');
        await _tapKey(t, 'm6g-sec-${n.isOdd ? 'main' : 'lt'}');
        if (n < 3) {
          await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
          expect(find.text(M6GMistakes.wrongSec.m.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await t.pump();
          await _until(t, () => p.phase == 'idle', maxMs: 4000);
        }
      }
      await _until(t, () => find.byType(StruckOutCard).evaluate().isNotEmpty, maxMs: 4000);
      expect(p.run!.slips, 3);
      expect(c.read(gameSaveProvider).rungProgress['m6/gate'], isNot('cleared'));
      await _closePage(t, c);
    });

    testWidgets('the panorama pans by swipe; a tool held shows the same frame on every device', (t) async {
      final p = M6GateProbe();
      final c = await _openPage(t, 11, p);
      expect(p.pan, 0);
      await t.drag(find.byKey(const ValueKey('m6g-pano')), const Offset(-300, 0));
      await _pump(t, 200);
      expect(p.pan, greaterThan(100), reason: 'a swipe pans');
      await _tapKey(t, 'm6g-tok-crew');
      expect(p.phase, 'lifted');
      // Before the find, a tool on a device only says what to do first (no cost).
      final dev = M6GDev.values.firstWhere((d) => find.byKey(ValueKey('m6g-dev-${d.name}')).evaluate().isNotEmpty && d != M6GDev.bank);
      await _tapKey(t, 'm6g-dev-${dev.name}');
      expect(p.run!.slips, 0);
      expect(p.run!.ended, isFalse);
      await _closePage(t, c);
    });

    testWidgets('gesture hint on the panorama: shown while it waits, pressing nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M6GateProbe();
      final c = await _openPage(t, 11, p);
      expect(p.phase, 'idle');
      await _pump(t, 9500);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget, reason: 'idle on the panorama');
      expect(p.phase, 'idle', reason: 'a hint presses nothing');
      expect(p.run!.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _closePage(t, c);
    });
  });
}
