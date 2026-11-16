// Lesson 7.4 (PTW: একটি আইনি চুক্তি), কাজ 1 "সইয়ের আগে": the rules (a
// fault still in the permit at the signature = slip; the field copy without
// the issuer's signature torn off and taken = deadly; a needless send-back or
// a correct box = slip; a smudged line asked about is put right, a clear one
// costs nothing; a carbon slip needs the lower copy signed before the tear;
// the control-room copy stays), the deal, the libraries, the coworker
// (listening = a slip here, B1), the drawn places, and the level in the
// shell: the guide first, a full clean play (peel, ask, send back, sign by
// tracing, tear; a reason pick each permit; the coworker refused), the slip
// card keeps the permit, three slips, the deadly freeze, the pen waits for
// him on a fast play, the praise window takes no touch, and the gesture hand
// shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m7_ptw_sign.dart';
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
  rungId: '7.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7PtwSignPacks['do_7_4_a']!;
typedef L = M7PtwSignLines;
typedef Mk = M7PtwSignMistakes;
typedef G = M7PtwSheetGeo;

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
M7PtwGeo get _geo => M7PtwGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7PtwRun get _live => M7PtwSignProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

/// Peel the top sheet up by its corner (a drag up), or lay it back (a drag
/// down on the folded sheet).
Future<void> _peel(WidgetTester t) async {
  final up = !_live.peeled;
  if (up) {
    await t.dragFrom(_geo.corner.center * _k, const Offset(0, -60));
  } else {
    await t.dragFrom(_geo.spine.center * _k, const Offset(0, 50));
  }
  await _pump(t, 300);
  expect(_live.peeled, up, reason: 'peeled $up');
}

Future<void> _pen(WidgetTester t) => _tapAt(t, _geo.pen.center);

/// Trace the dotted line on the sheet on show.
Future<void> _trace(WidgetTester t, {double share = 1}) async {
  final a = _geo.lineStart.translate(-4, -2);
  final b = Offset.lerp(_geo.lineStart, _geo.lineEnd, share)!.translate(share >= 1 ? 4 : 0, 1);
  final gesture = await t.startGesture(a * _k);
  for (var i = 1; i <= 24; i++) {
    final p = Offset.lerp(a, b, i / 24)!.translate(0, (i.isEven ? 3 : -3).toDouble());
    await gesture.moveTo(p * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _pump(t, 300);
}

Future<void> _sendBack(WidgetTester t) async {
  await t.dragFrom(_geo.spine.center.translate(40, 0) * _k, const Offset(0, -70));
  await _pump(t, 400);
}

Rect _boxRect(M7PtwBox b, [int line = 0]) => _geo.map(switch (b) {
      M7PtwBox.number => G.number,
      M7PtwBox.feeder => G.feeder,
      M7PtwBox.date => G.date,
      M7PtwBox.time => G.time,
      M7PtwBox.issuer => G.issuer,
      M7PtwBox.condition => G.cond(line),
      M7PtwBox.receiver => G.receiver,
    });

Future<void> _box(WidgetTester t, M7PtwBox b, [int line = 0]) => _tapAt(t, _boxRect(b, line).center.translate(30, 0));

/// Tear stub [i] (0: the top sheet's copy) off.
Future<void> _tear(WidgetTester t, int i) async {
  await t.dragFrom(_geo.tab(i).centerLeft.translate(8, 0) * _k, const Offset(110, 0));
  await _pump(t, 400);
}

int _fieldTab(M7PtwPermit p) => p.fieldOnTop ? 0 : 1;

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7PtwSignPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7PtwDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m7PtwDeal(math.Random(s))));

/// The coworker comes on his permit: refuse him.
Future<void> _refuse(WidgetTester t, M7PtwPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// One permit played right (the coworker refused if he is dealt on it).
Future<void> _playPermit(WidgetTester t, M7PtwDeal d, int i) async {
  final p = d.permits[i];
  expect(_live.index, i);
  if (d.coworkerPermit == i) await _refuse(t, d.push);
  // Look at both copies first (free).
  await _peel(t);
  await _peel(t);
  switch (p.fault) {
    case M7PtwFault.clean || M7PtwFault.carbonSlip:
      break;
    case M7PtwFault.smudged:
      await _box(t, M7PtwBox.condition, p.smudgeLine);
      expect(_live.fixed, isTrue, reason: 'the smudged line explained');
    case M7PtwFault.fieldNoIssuer || M7PtwFault.controlNoIssuer || M7PtwFault.blankBox || M7PtwFault.numberDiff:
      await _sendBack(t);
      expect(_live.phase, M7PtwPhase.boxPick, reason: '${p.fault}: he asks where');
      // Point at the box on the copy that has the fault.
      if (p.fault != M7PtwFault.numberDiff && _live.shown != p.oddCopy) await _peel(t);
      await _box(t, p.faultBox!);
      expect(_live.fixed, isTrue, reason: '${p.fault}: put right');
      if (_live.peeled) await _peel(t);
  }
  await _pen(t);
  expect(_live.penUp, isTrue);
  await _trace(t);
  expect(_live.topSigned, isTrue, reason: '${p.fault}: signed');
  if (p.fault == M7PtwFault.carbonSlip) {
    expect(_live.lowerSigned, isFalse);
    await _peel(t);
    await _trace(t);
    expect(_live.lowerSigned, isTrue, reason: 'the lower copy signed too');
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${p.fault}');
  await _tear(t, _fieldTab(p));
  expect(_live.roundDone, isTrue, reason: '${p.fault}: the field copy taken');
  final why = _live.why;
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${p.fault})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[why]!);
  await _pump(t, 3000);
}

M7PtwPermit _permitOf(M7PtwFault f, {bool fieldOnTop = true, M7PtwCopy? odd, M7PtwBox blank = M7PtwBox.date, int smudge = 0}) => M7PtwPermit(
      fault: f,
      fieldOnTop: fieldOnTop,
      number: 4817,
      oddNumber: 4871,
      feeder: L.feeders.first,
      date: '14/11/2026',
      time: '09:40',
      conditions: const [0, 1],
      oddCopy: odd ??
          switch (f) {
            M7PtwFault.fieldNoIssuer => M7PtwCopy.field,
            M7PtwFault.controlNoIssuer => M7PtwCopy.control,
            _ => M7PtwCopy.control,
          },
      blankKind: blank,
      smudgeLine: smudge,
    );

/// A run whose first permit is [first].
M7PtwRun _runOf(M7PtwPermit first) => M7PtwRun(M7PtwDeal(
      permits: [first, _permitOf(M7PtwFault.clean), _permitOf(M7PtwFault.clean)],
      coworkerPermit: 0,
      push: M7PtwPush.noRead,
    ));

/// Pen up and a full trace on the sheet on show.
(bool, DoMistake?) _sign(M7PtwRun r) {
  r.pickPen();
  return r.trace(1);
}

void _same(M7PtwRun r) {
  final a = r.sheet(M7PtwCopy.control), b = r.sheet(M7PtwCopy.field);
  expect((a.number, a.date, a.time, a.issuerSigned, a.smudged), (b.number, b.date, b.time, b.issuerSigned, b.smudged));
}

void main() {
  group('rules', () {
    test('deals: one clean and two different faults; the deadly case at most once, ~1 play in 3; plays differ', () {
      final seen = <String>{};
      final faults = <M7PtwFault>{};
      final pushes = <M7PtwPush>{};
      final coworkerAt = <int>{};
      var deadly = 0, fieldTop = 0;
      for (var s = 0; s < 150; s++) {
        final d = m7PtwDeal(math.Random(s));
        expect(d.permits, hasLength(3));
        final kinds = d.permits.map((p) => p.fault).toList();
        expect(kinds.where((f) => f == M7PtwFault.clean), hasLength(1), reason: '$kinds');
        expect(kinds.toSet(), hasLength(3), reason: 'two different faults: $kinds');
        if (kinds.contains(M7PtwFault.fieldNoIssuer)) deadly++;
        for (final p in d.permits) {
          faults.add(p.fault);
          if (p.fieldOnTop) fieldTop++;
          expect(p.oddNumber, isNot(p.number));
          expect('${p.oddNumber}', hasLength(4));
          expect(p.conditions.toSet(), hasLength(2));
          if (p.fault == M7PtwFault.fieldNoIssuer) expect(p.oddCopy, M7PtwCopy.field);
          if (p.fault == M7PtwFault.controlNoIssuer) expect(p.oddCopy, M7PtwCopy.control);
          if (p.fault == M7PtwFault.smudged) expect(p.oddCopy, p.topCopy, reason: 'the smudge is on the sheet he wrote');
          expect(RegExp(r'^\d\d:\d\d$').hasMatch(p.time), isTrue, reason: p.time);
        }
        expect(d.permits.map((p) => p.feeder).toSet(), hasLength(3));
        expect(d.permits.map((p) => p.date).toSet(), hasLength(1), reason: 'one day');
        pushes.add(d.push);
        coworkerAt.add(d.coworkerPermit);
        seen.add('${d.permits.map((p) => '${p.fault.index}${p.fieldOnTop}${p.oddCopy.index}${p.number}').join('|')}${d.coworkerPermit}${d.push.index}');
      }
      expect(seen.length, greaterThan(140));
      expect(faults, M7PtwFault.values.toSet());
      expect(deadly, inInclusiveRange(30, 75), reason: 'about one play in three');
      expect(fieldTop, inInclusiveRange(160, 290), reason: 'which copy is on top is dealt');
      expect(pushes, M7PtwPush.values.toSet());
      expect(coworkerAt, {0, 1, 2});
    });

    test('every permit is dated today', () {
      final d = m7PtwDeal(math.Random(7), today: DateTime(2026, 3, 4));
      expect(d.permits.map((p) => p.date).toSet(), {'04/03/2026'});
      final now = DateTime.now();
      expect(m7PtwDeal(math.Random(8)).permits.first.date, '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}');
    });

    test('a near-miss number is always a different 4-digit number', () {
      for (var s = 0; s < 400; s++) {
        final r = math.Random(s);
        final n = 2000 + r.nextInt(7900);
        final m = m7PtwNearMiss(n, r);
        expect(m, isNot(n));
        expect('$m', hasLength(4));
      }
    });

    test('the copies: a fault shows on its own copy only; put right, both copies alike', () {
      for (final f in M7PtwFault.values) {
        final r = _runOf(_permitOf(f, odd: f == M7PtwFault.fieldNoIssuer ? M7PtwCopy.field : M7PtwCopy.control, blank: M7PtwBox.time, smudge: 1));
        final c = r.sheet(M7PtwCopy.control), fl = r.sheet(M7PtwCopy.field);
        switch (f) {
          case M7PtwFault.clean || M7PtwFault.carbonSlip:
            _same(r);
          case M7PtwFault.fieldNoIssuer:
            expect((c.issuerSigned, fl.issuerSigned), (true, false));
          case M7PtwFault.controlNoIssuer:
            expect((c.issuerSigned, fl.issuerSigned), (false, true));
          case M7PtwFault.blankBox:
            expect((c.time, fl.time), (null, '09:40'));
            expect(c.date, isNotNull);
          case M7PtwFault.numberDiff:
            expect((c.number, fl.number), (4871, 4817));
          case M7PtwFault.smudged:
            expect((c.smudged, fl.smudged), (1, 1), reason: 'the carbon carries the smudge');
        }
        expect(c.conditions, fl.conditions);
        r.fixed = true;
        _same(r);
        expect(r.sheet(M7PtwCopy.control).smudged, isNull);
      }
    });

    test('a clean permit: signed, the carbon comes through; the control-room copy stays (slip); the field copy taken; a send-back is needless (R29)', () {
      final r = _runOf(_permitOf(M7PtwFault.clean));
      expect(r.sendBack(), Mk.needlessBack);
      expect(r.phase, M7PtwPhase.deciding);
      expect(r.trace(1), (false, null), reason: 'no pen yet');
      expect(r.pickPen(), isTrue);
      expect(r.trace(0.6), (false, null), reason: 'under 80 % of the line');
      expect(r.trace(1), (true, null));
      expect(r.phase, M7PtwPhase.signed);
      expect(r.lowerSigned, isTrue);
      expect(r.sendBack(), Mk.needlessBack, reason: 'signed, a sound permit sent back is still needless');
      expect(r.phase, M7PtwPhase.signed);
      expect(r.tear(M7PtwCopy.control), Mk.wrongTear);
      expect(r.tear(M7PtwCopy.field), isNull);
      expect(r.roundDone, isTrue);
      expect(r.sendBack(), isNull, reason: 'torn off: nothing goes back');
      expect(r.why, M7PtwWhy.duty);
      expect(r.slips, 3);
      expect(r.caught, isNot(contains(L.caughtField)), reason: 'not a clean permit');
    });

    test('signing with a fault still in it: control-room copy unsigned, a blank box, different numbers, a smudge not asked = slips (R3)', () {
      for (final (f, m) in [
        (M7PtwFault.controlNoIssuer, Mk.controlBlank),
        (M7PtwFault.blankBox, Mk.blankBox),
        (M7PtwFault.numberDiff, Mk.copiesDiffer),
        (M7PtwFault.smudged, Mk.notUnderstood),
      ]) {
        final r = _runOf(_permitOf(f));
        expect(_sign(r), (true, m), reason: '$f');
        expect(r.slips, 1);
        expect(r.signedFaulty, isTrue);
        expect(r.tear(M7PtwCopy.field), isNull, reason: '$f: the permit goes on');
        expect(r.why, M7PtwWhy.duty, reason: 'the reason fits what was done');
      }
    });

    test('the field copy without the issuer\'s signature: signed, no slip yet; torn off and taken = deadly (R1)', () {
      final r = _runOf(_permitOf(M7PtwFault.fieldNoIssuer));
      expect(_sign(r), (true, null));
      expect(r.tear(M7PtwCopy.control), Mk.wrongTear);
      final m = r.tear(M7PtwCopy.field);
      expect(m, Mk.fieldBlank);
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
    });

    test('signed, then the blank issuer box seen: it can still go back before any tear; re-signed, the field copy is safe', () {
      for (final fieldOnTop in [true, false]) {
        final r = _runOf(_permitOf(M7PtwFault.fieldNoIssuer, fieldOnTop: fieldOnTop));
        expect(_sign(r), (true, null));
        if (r.shown != M7PtwCopy.field) r.togglePeel();
        expect(r.sheet(M7PtwCopy.field).issuerSigned, isFalse, reason: 'seen after signing');
        expect(r.sendBack(), isNull, reason: 'a late send-back is allowed');
        expect(r.phase, M7PtwPhase.boxPick);
        expect(r.penUp, isFalse);
        expect(r.tear(M7PtwCopy.field), isNull, reason: 'nothing tears while he asks where');
        r.togglePeel();
        expect(r.shown, M7PtwCopy.control);
        expect(r.pickBox(M7PtwBox.issuer), Mk.wrongBox, reason: 'the control-room copy is signed: that box is correct');
        r.togglePeel();
        expect(r.pickBox(M7PtwBox.issuer), isNull);
        expect((r.fixed, r.topSigned, r.lowerSigned, r.phase), (true, false, false, M7PtwPhase.deciding), reason: 'signed afresh');
        if (r.peeled) r.togglePeel();
        expect(_sign(r), (true, null));
        expect(r.tear(M7PtwCopy.field), isNull, reason: 'the issuer signed it: no deadly');
        expect(r.deadly, isNull);
        expect(r.why, M7PtwWhy.noIssuer);
        expect(r.caught, contains(L.caughtNoIssuer));
        expect(r.slips, 1);
      }
    });

    test('send back: a correct box = slip; the faulty box is put right, then sign and take it', () {
      for (final f in [M7PtwFault.fieldNoIssuer, M7PtwFault.controlNoIssuer, M7PtwFault.blankBox, M7PtwFault.numberDiff, M7PtwFault.smudged]) {
        final r = _runOf(_permitOf(f, blank: M7PtwBox.time));
        r.pickPen();
        expect(r.sendBack(), isNull, reason: '$f');
        expect(r.phase, M7PtwPhase.boxPick);
        expect(r.penUp, isFalse, reason: 'the pen goes down');
        expect(r.trace(1), (false, null));
        expect(r.ask(0), isNull, reason: 'a condition tap now points at a box');
        final wrong = M7PtwBox.values.firstWhere((b) => b != r.permit.faultBox);
        expect(r.pickBox(wrong), Mk.wrongBox, reason: '$f');
        expect(r.phase, M7PtwPhase.boxPick);
        final oneCopy = f == M7PtwFault.fieldNoIssuer || f == M7PtwFault.controlNoIssuer || f == M7PtwFault.blankBox;
        if (oneCopy && r.shown != r.permit.oddCopy) {
          expect(r.pickBox(r.permit.faultBox!), Mk.wrongBox, reason: '$f: that box is fine on this copy');
          r.togglePeel();
          expect(r.shown, r.permit.oddCopy);
        }
        expect(r.pickBox(r.permit.faultBox!), isNull);
        expect(r.fixed, isTrue);
        if (r.peeled) r.togglePeel();
        _same(r);
        expect(_sign(r), (true, null), reason: '$f');
        expect(r.tear(M7PtwCopy.field), isNull, reason: '$f');
        expect(r.why, switch (f) {
          M7PtwFault.fieldNoIssuer => M7PtwWhy.noIssuer,
          M7PtwFault.smudged => M7PtwWhy.asked,
          _ => M7PtwWhy.sentBack,
        });
        expect(r.slips, f == M7PtwFault.controlNoIssuer || f == M7PtwFault.blankBox ? 2 : 1, reason: '$f');
        expect(r.caught, contains(f == M7PtwFault.fieldNoIssuer ? L.caughtNoIssuer : L.caughtBack));
      }
      expect(_permitOf(M7PtwFault.blankBox, blank: M7PtwBox.date).faultBox, M7PtwBox.date);
      expect(_permitOf(M7PtwFault.clean).faultBox, isNull);
      expect(_permitOf(M7PtwFault.carbonSlip).faultBox, isNull);
      // A permit already put right is not sent back again.
      final r = _runOf(_permitOf(M7PtwFault.numberDiff));
      r.sendBack();
      r.pickBox(M7PtwBox.number);
      expect(r.sendBack(), Mk.needlessBack);
    });

    test('ask: a clear line "as it is written" at no cost; the smudged line (unreadable on every copy) is explained', () {
      final r = _runOf(_permitOf(M7PtwFault.smudged, fieldOnTop: true, odd: M7PtwCopy.field, smudge: 1));
      expect(r.sheet(M7PtwCopy.field).smudged, 1);
      expect(r.sheet(M7PtwCopy.control).smudged, 1, reason: 'the copy beneath cannot be read either');
      expect(r.ask(0), M7PtwAsk.asIs);
      expect(r.fixed, isFalse);
      r.togglePeel();
      expect(r.ask(0), M7PtwAsk.asIs);
      r.togglePeel();
      expect(r.ask(1), M7PtwAsk.cleared);
      expect(r.fixed, isTrue);
      expect(r.slips, 0);
      expect(r.sheet(M7PtwCopy.control).smudged, isNull, reason: 'explained: both copies clear');
      expect(_sign(r), (true, null));
      expect(r.tear(M7PtwCopy.field), isNull);
      expect(r.why, M7PtwWhy.asked);
      expect(r.caught, containsAll([L.caughtAsked, L.caughtField]));
    });

    test('carbon slip: the lower copy unsigned; a tear before it = slip; peel and sign it; then take the field copy', () {
      final r = _runOf(_permitOf(M7PtwFault.carbonSlip, fieldOnTop: false));
      expect(r.sendBack(), Mk.needlessBack, reason: 'nothing to send back before the signature');
      expect(_sign(r), (true, null));
      expect(r.lowerSigned, isFalse);
      expect(r.sheet(M7PtwCopy.field).receiverSigned, isFalse, reason: 'the field copy is beneath');
      expect(r.tear(M7PtwCopy.field), Mk.carbonMissed);
      expect(r.trace(1), (false, null), reason: 'the top sheet is signed already');
      r.togglePeel();
      expect(r.trace(0.5), (false, null));
      expect(r.trace(1), (true, null));
      expect(r.lowerSigned, isTrue);
      expect(r.tear(M7PtwCopy.field), isNull);
      expect(r.why, M7PtwWhy.lowerToo);
      expect(r.caught, contains(L.caughtLower));
      expect(r.slips, 2);
    });

    test('the dotted line: coverage counts slices on the line only', () {
      List<Offset> line(double a, double b, {double dy = 0}) => [
            for (var i = 0; i <= 30; i++) Offset(G.lineX0 + (G.lineX1 - G.lineX0) * (a + (b - a) * i / 30), G.lineY + dy),
          ];
      expect(G.coverage(line(0, 1)), 1);
      expect(G.coverage(line(0, 0.5)), closeTo(0.5, 0.06));
      expect(G.coverage(line(0, 1, dy: 40)), 0, reason: 'far off the line');
      expect(G.coverage([const Offset(G.lineX0 + 1, G.lineY), const Offset(G.lineX1 - 1, G.lineY)]), 0.1, reason: 'one long jump is not a stroke');
      expect(G.boxAt(G.cond(1).center), (M7PtwBox.condition, 1));
      expect(G.boxAt(G.spine.center), isNull);
      expect(G.boxAt(G.corner.center), isNull, reason: 'the corner is no box');
    });

    test('three slips and the play fails; each permit counts its own slips; listening is a slip (B1)', () {
      final r = _runOf(_permitOf(M7PtwFault.clean));
      for (var i = 0; i < 3; i++) {
        r.sendBack();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      expect(r.pushSlip(), Mk.listened);
      expect(Mk.listened.deadly, isFalse);
      expect(r.percent, 40);
      _sign(r);
      r
        ..tear(M7PtwCopy.field)
        ..next();
      expect(r.thorough, isTrue);
      expect((r.phase, r.peeled, r.penUp, r.topSigned, r.fixed), (M7PtwPhase.deciding, false, false, false, false));
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; the deadly set; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.issuerBubbles,
        for (final c in M7PtwCopy.values) L.copy(c),
        L.ptw,
        L.number,
        L.feeder,
        L.date,
        L.time,
        L.issuer,
        L.conditions,
        L.receiver,
        L.sendBack,
        ...L.permits,
        ...L.feeders,
        ...L.conditionLines,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        L.callHeld,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$)').hasMatch(l), isFalse, reason: l);
        expect(l.contains('কেভি'), isFalse, reason: 'kV in English letters: $l');
        expect(l.contains('গ্লাভ্স'), isFalse, reason: l);
        // য় / ড় / ঢ় as base + nukta.
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.fieldBlank});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.4/m7_ptw_sign/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: 'lesson 7.4 has three points');
      }
      const dir = 'assets/game/art/m7_ptw_sign/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used (no .gitkeep left)');
      expect(m7PtwSignPacks.keys, ['do_7_4_a']);
      expect(_pack.titleBn, 'সইয়ের আগে');
    });

    test('condition lines come from lesson 7.4\'s own words', () {
      final lesson = File('tool/all_training_chapters_bn.json').readAsStringSync();
      // Lesson words each line rests on (nukta forms normalised).
      String norm(String s) => s.replaceAll('\u09DF', '\u09AF\u09BC').replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC');
      final text = norm(lesson);
      for (final w in ['বিচ্ছিন্ন', 'ডেড', 'আর্থ', 'তালা', 'ট্যাগ', 'টিমের সুরক্ষা', 'নিরাপদ অবস্থায় ফেরত', 'কোন পারমিটের অধীনে']) {
        expect(text.contains(norm(w)), isTrue, reason: w);
      }
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7PtwWhy.values) {
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
      expect(L.whyQ.values.toSet(), hasLength(5), reason: 'the spec\'s five questions');
    });

    test('rival lines: his exit is recorded; his two new pushes and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'ওপরের কপিতে সই করলেই হলো, নিচেরটা কে দেখে? চলো, দেরি হচ্ছে!',
        'পড়ার কী আছে? সই করে দাও, গাড়ি দাঁড়িয়ে আছে!',
      ]);
      expect({for (final p in M7PtwPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.whyQ.values, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      for (final cw in L.allCoworkers) {
        for (final a in cw.asks) {
          expect(L.newGuideLines.contains(a) || a == 'কী করবেন?' || a == 'ওর কথা শুনবেন, না নিয়ম?', isTrue, reason: a);
        }
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_ptw_sign: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas stay on the scene, under the header, clear of the guide, its bubble and each other', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M7PtwGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final rects = <Rect>[g.book, g.pen, g.tab(0), g.tab(1)];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 20), reason: 'h $h: $r');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        for (final (i, a) in rects.indexed) {
          for (final b in rects.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        expect(g.pen.height, greaterThanOrEqualTo(34));
        expect(g.tab(0).height * _k, greaterThanOrEqualTo(40), reason: 'a finger-sized stub');
        expect(g.bubble.bottom, lessThan(g.book.top), reason: 'his bubble never covers the book');
      }
      // The sheet's boxes never overlap; the corner and the spine are clear of them.
      final boxes = [for (final (_, _, r) in G.boxes) r];
      for (final (i, a) in boxes.indexed) {
        for (final b in boxes.skip(i + 1)) {
          expect(a.overlaps(b), isFalse, reason: '$a / $b');
        }
        expect(a.overlaps(G.corner) || a.overlaps(G.spine), isFalse, reason: '$a');
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

    testWidgets('the guide comes first: a tap does not skip him; then the book — the copy beneath only when peeled', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      const seed = 3;
      await t.pumpWidget(ProviderScope(child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M7PtwSignPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final p = m7PtwDeal(math.Random(seed)).permits.first;
      expect(find.text(L.copy(p.topCopy)), findsOneWidget);
      expect(find.text(L.copy(p.lowerCopy)), findsNothing, reason: 'nothing side by side');
      await _peel(t);
      expect(find.text(L.copy(p.lowerCopy)), findsOneWidget);
      expect(find.text(L.copy(p.topCopy)), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    final cleanFirstAlone = _seedWhere((d) => d.permits.first.fault == M7PtwFault.clean && d.coworkerPermit != 0);
    testWidgets('tapping the guide repeats the task, a different way each time; a clear line asked costs nothing', (t) async {
      final c = await _open(t, cleanFirstAlone);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askCheck)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _box(t, M7PtwBox.condition, 0);
      expect(find.text(L.issuerAsIs), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pen(t);
      expect(c.read(guideDirectorProvider).line, contains(L.askSign));
      await _close(t, c);
    });

    // A play with the deadly case put right and a smudge; one with a carbon
    // slip and a send-back fault.
    final flowSeeds = [
      _seedWhere((d) => d.permits.any((p) => p.fault == M7PtwFault.fieldNoIssuer) && d.permits.any((p) => p.fault == M7PtwFault.smudged)),
      _seedWhere((d) => d.permits.any((p) => p.fault == M7PtwFault.carbonSlip) && d.permits.any((p) => p.fault == M7PtwFault.numberDiff) && d.coworkerPermit == 0),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three permits — peel, ask, send back, sign, tear; reasons; he is refused → pass', (t) async {
        final d = m7PtwDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playPermit(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.4/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.4/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (needless send-back) shows its card; the same permit goes on after it', (t) async {
      final c = await _open(t, cleanFirstAlone);
      await _sendBack(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.needlessBack.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0, reason: 'the same permit');
      await _pen(t);
      await _trace(t, share: 0.5);
      expect(_live.topSigned, isFalse, reason: 'half the line is no signature');
      await _trace(t);
      expect(_live.topSigned, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.needlessBack.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, cleanFirstAlone);
      for (var i = 0; i < 3; i++) {
        await _sendBack(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final deadlyFirstAlone = _seedWhere((d) => d.permits.first.fault == M7PtwFault.fieldNoIssuer && d.coworkerPermit != 0);
    testWidgets('the field copy without the issuer\'s signature taken: the counter freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, deadlyFirstAlone);
      final p = _live.permit;
      await _pen(t);
      await _trace(t);
      expect(find.byType(MistakeCard), findsNothing, reason: 'no slip at the signature');
      await _tear(t, _fieldTab(p));
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.fieldBlank.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('signed, then the blank issuer box seen: swipe it back, show the box, sign afresh, take it safely', (t) async {
      final c = await _open(t, deadlyFirstAlone);
      final p = _live.permit;
      await _pen(t);
      await _trace(t);
      expect(_live.phase, M7PtwPhase.signed);
      expect(c.read(guideDirectorProvider).line, contains(L.askTear), reason: 'the neutral check line');
      if (_live.shown != M7PtwCopy.field) await _peel(t);
      expect(_live.sheet(M7PtwCopy.field).issuerSigned, isFalse);
      await _sendBack(t);
      expect(_live.phase, M7PtwPhase.boxPick, reason: 'a late send-back works');
      expect(find.text(L.issuerWhere), findsOneWidget);
      await _box(t, M7PtwBox.issuer);
      expect(_live.fixed, isTrue);
      expect(_live.topSigned, isFalse, reason: 'signed afresh');
      if (_live.peeled) await _peel(t);
      await _pen(t);
      await _trace(t);
      expect(_live.topSigned, isTrue);
      await _tear(t, _fieldTab(p));
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.roundDone, isTrue);
      expect(_live.why, M7PtwWhy.noIssuer);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('pen up on the folded-up sheet: no ink, and the hand shows to lay it back', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, cleanFirstAlone);
      await _pen(t);
      await _peel(t);
      await _trace(t);
      expect(_live.topSigned, isFalse);
      expect(_live.lowerSigned, isFalse);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      await _peel(t);
      await _trace(t);
      expect(_live.topSigned, isTrue, reason: 'laid back: the trace signs');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final himFirst = _seedWhere((d) => d.coworkerPermit == 0 && d.permits.first.fault == M7PtwFault.clean);
    testWidgets('listening to him is a slip: its card, then the permit goes on', (t) async {
      final c = await _open(t, himFirst);
      final d = m7PtwDeal(math.Random(himFirst));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker(d.push).wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.listened.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listened.key);
      await _close(t, c);
    });

    testWidgets('a fast play: the pen waits for the coworker; he cuts in at once', (t) async {
      final c = await _open(t, himFirst);
      final d = m7PtwDeal(math.Random(himFirst));
      // At once, inside his timer: the pen.
      await _pen(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.penUp, isFalse, reason: 'the pen stayed down');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworker(d.push).right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _pen(t);
      expect(_live.penUp, isTrue, reason: 'after him the pen comes up');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, cleanFirstAlone);
      final p = _live.permit;
      await _pen(t);
      await _trace(t);
      await _tear(t, _fieldTab(p));
      expect(_live.roundDone, isTrue);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.corner.center * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(_geo.spine.center * _k, const Offset(0, -70));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.peeled, isFalse);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[_live.why]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a send-back: he asks where; a correct box is a slip; the faulty box is put right', (t) async {
      final seed = _seedWhere((d) => d.permits.first.fault == M7PtwFault.numberDiff && d.coworkerPermit != 0);
      final c = await _open(t, seed);
      await _sendBack(t);
      expect(find.text(L.issuerWhere), findsOneWidget);
      expect(c.read(guideDirectorProvider).line, contains(L.askWhere));
      await _box(t, M7PtwBox.feeder);
      expect(find.text(Mk.wrongBox.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _box(t, M7PtwBox.number);
      expect(_live.fixed, isTrue);
      expect(find.text(L.issuerFixed), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.wrongBox.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: a nudge on the corner first; then three taps on nothing show a hand that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, cleanFirstAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the book not looked at');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      await _peel(t);
      expect(scene().showing, isFalse);
      await _peel(t);
      // Three taps on nothing (the wall behind the counter) show the hand.
      final empty = const Offset(250, 150) * _k;
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
