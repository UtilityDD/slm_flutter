// The Module 7 rank gate "সুপারভাইজারের ডকেট: সইয়ের দায়" (m7_gate_permit_day):
// the deal (F1 first, F12 last, eight more in day order, every lesson group
// once, 4–6 of 10 lawful, 1–2 deadly-class, the coworker on a slip-class fork),
// the engine's rules (every deadly and slip row of the module table after the
// rulings, one slip per move, the needless stop, a compliant tap, listening),
// a clean engine play of every deal, the objects (same ids on a lawful and an
// unlawful version, sizes, taps), the option libraries (lengths within 1.3×),
// English digits, the coworker's lines (the lesson's myths word for word,
// recorded or listed) and every spoken line listed, the mistakes, and the page:
// the guide first, idle = zero frames, a full clean play to the rank-up (incl.
// a close-up, a reason pick, the fix decks, the coworker held and refused), a
// deadly move (freeze → near-miss), listening to the coworker (a slip, the step
// resolves), three slips (strike-out), and the gesture hint (presses nothing).
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
import 'package:slm_flutter/features/game/m7_gate_permit_day.dart';
import 'package:slm_flutter/features/game/m7_gate_permit_day_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: 'm7/gate',
  kind: CatalogRungKind.gate,
  lessonId: '7.10',
  lessonTitleBn: '',
  ladderStep: 210,
);

final _pack = m7GatePacks['gate_m7']!;

int _seedWhere(bool Function(M7GDeal d) ok) {
  for (var s = 1; s < 60000; s++) {
    if (ok(dealM7G(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

M7GDeal _dealWhere(bool Function(M7GDeal d) ok) => dealM7G(math.Random(_seedWhere(ok)));

/// A run at the first step of [fork] whose version is [ver] (all the steps
/// before it judged cleanly).
M7GRun _runAt(M7GFork fork, String ver) {
  final d = _dealWhere((d) => d.steps.any((s) => s.fork == fork && s.ver.id == ver));
  final r = M7GRun(d);
  while (r.step.fork != fork) {
    _pass(r);
  }
  expect(r.step.ver.id, ver);
  return r;
}

/// Judges the step now cleanly (a lawful 'এগোন'; an unlawful 'থামান', the
/// breach, the fix) and moves on.
void _pass(M7GRun r) {
  final v = r.step.ver;
  if (v.lawful) {
    final o = r.go();
    expect(o.mistake, isNull, reason: '${r.fork}');
    expect(o.resolved, isTrue);
  } else {
    expect(r.halt().halted, isTrue, reason: '${r.fork} ${v.id}');
    final o = r.tapObject(v.breach.first);
    expect(o.mistake, isNull);
    expect(o.reason, M7GReasonKind.fix);
    r.fixPlays();
  }
  r.advance();
}

String _nk(String s) => s
    .replaceAll(String.fromCharCode(0x09DF), String.fromCharCodes([0x09AF, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DC), String.fromCharCodes([0x09A1, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DD), String.fromCharCodes([0x09A2, 0x09BC]));

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
  await _until(t, () => cards.hitTestable().evaluate().length == 3, maxMs: 12000, reason: 'deck up');
}

/// Picks the right card of the deck now up (and its এগিয়ে যান when there is one).
Future<void> _pickDeckRight(WidgetTester t, M7GateProbe p) async {
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

/// Swipe up (এগোন) or down (থামান) on the field copy.
Future<void> _swipe(WidgetTester t, {required bool up}) async {
  await t.fling(find.byKey(const ValueKey('m7g-clip')), Offset(0, up ? -160 : 160), 900);
  await t.pump();
  await _pump(t, 200);
}

Future<ProviderContainer> _openPage(WidgetTester t, int seed, M7GateProbe probe) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M7GatePermitDayPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
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

Future<void> _waitWait(WidgetTester t, M7GateProbe p) => _until(t, () => p.phase == 'wait', maxMs: 20000, reason: 'the step waits (phase ${p.phase})');

/// Plays the step now cleanly through the page. [cw]: on the coworker's step
/// the first swipe waits for him; he is refused.
Future<void> _playStep(WidgetTester t, M7GateProbe p, {bool look = false}) async {
  await _waitWait(t, p);
  final r = p.run!;
  final s = r.step;
  if (look) {
    final id = p.objectIds.first;
    await _tapKey(t, 'm7g-obj-$id');
    expect(p.phase, 'closeup');
    await _tapKey(t, 'm7g-lens-close');
    expect(p.phase, 'wait');
  }
  if (s.cw && !p.coworkerUp) {
    await _swipe(t, up: s.ver.lawful);
    await _until(t, () => p.coworkerUp, maxMs: 6000, reason: 'he comes at the first swipe on the field copy');
    expect(p.phase, 'wait', reason: 'the swipe waited for him');
    expect(r.step, same(s), reason: 'nothing was judged while he talks');
    expect(find.text(M7GateLines.script(s.fork).line), findsWidgets);
    await _pickDeckRight(t, p);
    await _pump(t, 1500);
    expect(r.ended, isFalse);
    await _waitWait(t, p);
  }
  final i = r.i;
  if (s.ver.lawful) {
    final first = !r.firstGoDone;
    await _swipe(t, up: true);
    if (first) {
      await _until(t, () => p.busy, maxMs: 6000, reason: 'the first right এগোন puts ◆ on the table');
      await _pickDeckRight(t, p);
    }
  } else {
    await _swipe(t, up: false);
    expect(p.phase, 'halted', reason: '${s.fork} ${s.ver.id}');
    final id = s.ver.breach.first;
    await _tapKey(t, id == 'field' ? 'm7g-clip' : 'm7g-obj-$id');
    await _until(t, () => p.busy, maxMs: 6000, reason: 'the breach puts ◆ on the table');
    await _pickDeckRight(t, p);
  }
  if (!r.isLast || i != r.i) {
    await _until(t, () => p.run!.i != i || p.phase == 'closing' || p.phase == 'done', maxMs: 12000, reason: 'the job moves on');
  }
}

void main() {
  group('rules', () {
    test('the deal: F1 first, F12 last, eight in day order, every lesson group once, 4–6 lawful, 1–2 deadly, the coworker on a slip-class fork', () {
      final sigs = <String>{};
      final seenVer = <String>{};
      final forks = <M7GFork>{};
      var tenMen = <int>{};
      for (var s = 0; s < 500; s++) {
        final d = dealM7G(math.Random(s));
        expect(d.steps, hasLength(10));
        expect(d.steps.first.fork, M7GFork.permit);
        expect(d.steps.last.fork, M7GFork.ret);
        final mid = d.steps.sublist(1, 9).map((x) => x.fork).toList();
        expect(mid.toSet(), hasLength(8), reason: 'no fork twice');
        expect(mid, orderedEquals(<M7GFork>[...mid]..sort((a, b) => a.dayOrder.compareTo(b.dayOrder))), reason: 'day order');
        expect(mid, isNot(contains(M7GFork.permit)));
        expect(mid, isNot(contains(M7GFork.ret)));
        // Every lesson group of the module once.
        final lessons = {for (final f in d.forks) f.lesson};
        for (final l in ['7.3', '7.4', '7.5', '7.6', '7.7', '7.8', '7.9', '7.10']) {
          expect(lessons, contains(l), reason: 'lesson $l seed $s');
        }
        expect(d.lawfulCount, inInclusiveRange(4, 6), reason: 'seed $s');
        expect(d.deadlyCount, inInclusiveRange(1, 2), reason: 'seed $s');
        // The spots follow the day.
        expect([for (final x in d.steps) x.spot], orderedEquals(<int>[for (final x in d.steps) x.spot]..sort()));
        // The coworker: once, on a slip-class fork type, never on a deadly version.
        final cws = d.steps.where((x) => x.cw).toList();
        expect(cws, hasLength(1));
        expect(cws.single.fork.coworkerFork, isTrue);
        expect(cws.single.ver.deadly, isFalse);
        expect(d.crew.length, inInclusiveRange(3, 4));
        expect(d.crew.toSet(), hasLength(d.crew.length));
        expect(d.climberPos, lessThan(d.n));
        expect(d.upPos, lessThan(d.n));
        expect(d.altNo, isNot(d.ptwNo));
        for (final x in d.steps) {
          if (x.fork == M7GFork.hook) expect(x.flip, !d.laneLeft, reason: 'the hook scene follows the lane side');
          seenVer.add('${x.fork.name}.${x.ver.id}');
          forks.add(x.fork);
        }
        sigs.add([for (final x in d.steps) '${x.fork.index}${x.ver.id}${x.flip}${x.cw}'].join(',') + d.crew.join() + d.climberPos.toString());
        tenMen = {...tenMen, ...d.crew};
      }
      expect(forks, M7GFork.values.toSet());
      expect(tenMen.length, m7gMen.length, reason: 'all ~10 men are dealt');
      expect(sigs.length, greaterThan(450));
      expect(seenVer, {for (final f in M7GFork.values) for (final v in m7gVersions(f)) '${f.name}.${v.id}'});
    });

    test('a clean play of every deal reaches the pass with no slip; only the first right এগোন asks why', () {
      for (var s = 0; s < 400; s++) {
        final d = dealM7G(math.Random(s));
        final r = M7GRun(d);
        var whyGo = 0;
        for (var i = 0; i < 10; i++) {
          expect(r.i, i);
          final v = r.step.ver;
          if (v.lawful) {
            final o = r.go();
            if (o.reason == M7GReasonKind.whyGo) whyGo++;
            expect(o.pay, o.reason == M7GReasonKind.whyGo ? 0 : 10);
            expect(o.mistake, isNull);
            r.advance();
          } else {
            _pass(r);
          }
        }
        r.finish();
        expect(r.passed, isTrue, reason: 'seed $s');
        expect(r.slips, 0);
        expect(r.percent, 100);
        expect(whyGo, d.lawfulCount > 0 ? 1 : 0, reason: 'seed $s');
        expect(r.caught, isNotEmpty);
      }
    });

    test('deadly: a wrong এগোন on a deadly-class step ends the play with that row', () {
      var n = 0;
      for (final f in M7GFork.values) {
        for (final v in m7gVersions(f).where((v) => v.deadly)) {
          final r = _runAt(f, v.id);
          final o = r.go();
          expect(o.mistake, v.mistake!.m, reason: '$f ${v.id}');
          expect(o.deadly, isTrue);
          expect(r.ended, isTrue);
          expect(r.slips, 0);
          // Nothing more counts once it has ended.
          expect(r.go().mistake, isNull);
          n++;
        }
      }
      expect(n, 8, reason: 'F1 ×2, F3 ×2, F7 ×3, F12 ×1 — the module table (R1, R2, R10, R13, N1, N2, R4)');
      final deadly = {
        M7GMistakes.ptwBlank, M7GMistakes.ptwVerbal, M7GMistakes.gloveBad, M7GMistakes.hookLive,
        M7GMistakes.hookNoTest, M7GMistakes.hookNoEarth, M7GMistakes.headCount,
      };
      for (final x in M7GMistakes.allWithLesson) {
        expect(x.m.deadly, deadly.contains(x), reason: x.m.key);
      }
    });

    test('slips: a wrong এগোন on a slip-class step plays out and costs one; a halt on a lawful step is a needless stop; a compliant tap costs', () {
      for (final f in M7GFork.values) {
        for (final v in m7gVersions(f)) {
          if (v.deadly) continue;
          if (v.lawful) {
            final r = _runAt(f, 'lawful');
            final o = r.halt();
            expect(o.mistake, M7GMistakes.needless[f]!.m, reason: 'a needless stop at $f');
            expect(r.halted, isFalse, reason: 'the step waits again');
            expect(o.resolved, isFalse);
            expect(r.slips, 1);
            expect(r.go().resolved, isTrue, reason: 'it then goes on');
          } else {
            final r = _runAt(f, v.id);
            final g = r.go();
            expect(g.mistake, v.mistake!.m, reason: '$f ${v.id}');
            expect(g.deadly, isFalse);
            expect(g.resolved, isTrue);
            expect(r.slips, 1);
            expect(r.percent, 85);
            expect(r.ended, isFalse);
            // The other way: halt, a compliant object, then the breach.
            final h = _runAt(f, v.id);
            expect(h.halt().halted, isTrue);
            final ids = m7gObjectIds(h.deal, h.i).followedBy(const ['field']).where((id) => !v.breach.contains(id)).toList();
            final c = h.tapObject(ids.first);
            expect(c.mistake, M7GMistakes.compliant[f]!.m, reason: 'a compliant tap at $f');
            expect(h.halted, isTrue, reason: 'still halted');
            expect(h.tapObject(v.breach.first).reason, M7GReasonKind.fix);
            expect(h.slips, 1);
          }
        }
      }
    });

    test('taps before the halt are looks (free); the first touch of an unlawful step judges nothing; fix and listening', () {
      final r = _runAt(M7GFork.climber, 'training');
      expect(r.tapObject('card_climber').mistake, isNull, reason: 'a tap before the halt is only a look');
      expect(r.slips, 0);
      r.halt();
      expect(r.tapObject('card_climber').reason, M7GReasonKind.fix);
      r.fixPlays();
      expect(r.fixed, isTrue);
      expect(r.halted, isFalse);
      r.advance();
      expect(r.fixed, isFalse);
      // Listening to the coworker: one slip, the step resolves as 'এগোন'.
      final l = _runAt(M7GFork.climber, 'lawful');
      final o = l.listened();
      expect(o.mistake, M7GMistakes.listened[M7GFork.climber]!.m);
      expect(o.resolved, isTrue);
      expect(o.deadly, isFalse, reason: 'every gate variant stays a slip (X2)');
      expect(l.slips, 1);
      // 3 slips = 55 %: still a pass mark; the page strikes out at three.
      for (var i = 0; i < 2; i++) {
        l.halt();
      }
      expect(l.slips, 3);
      expect(l.percent, 55);
      // The field copy follows the permit step.
      final p = _runAt(M7GFork.permit, 'numbers');
      expect(p.fieldNo, isNot(p.deal.ptwNo));
      expect(p.fieldBlank, isFalse);
      final b = _runAt(M7GFork.permit, 'verbal');
      expect(b.fieldBlank, isTrue);
      b.halt();
      b.tapObject('issuer');
      b.fixPlays();
      expect(b.fieldBlank, isFalse);
      expect(b.fieldIssuer, isTrue);
      expect(b.fieldNo, b.deal.ptwNo);
      final k = _runAt(M7GFork.permit, 'blank');
      expect(k.fieldIssuer, isFalse);
      expect(k.fieldLines, contains('ইস্যুকারীর ঘর: ফাঁকা'));
    });

    test('hint rects: the head-count step sweeps fixed anchors, the same on a lawful and an up version; the breach sets cover every drawn defect; F4 owner says the same in a lawful and a no-notice version', () {
      var sawUp = false;
      var sawLawful = false;
      for (var seed = 0; seed < 200; seed++) {
        final d = dealM7G(math.Random(seed));
        for (var i = 0; i < d.steps.length; i++) {
          final st = d.steps[i];
          if (st.fork == M7GFork.ret) {
            final hid = [for (final o in m7gObjects(d, i)) if (o.id == 'hid') o.r];
            final rects = m7gHintRects(d, i);
            expect(rects, m7gHintRects(d, i, fixed: true));
            expect(rects, hasLength(3));
            if (st.ver.id == 'up') {
              sawUp = true;
              expect(hid, hasLength(1));
              expect(rects.contains(hid.first), isFalse, reason: 'the hint never starts on the hidden man');
            } else {
              sawLawful = true;
            }
            expect(rects.every((r) => r.left >= 0 && r.right <= 1.0001), isTrue);
          }
          if (st.fork == M7GFork.door) {
            final o = m7gObjects(d, i).firstWhere((o) => o.id == 'owner');
            if (st.ver.id == 'noNotice' || st.ver.id == 'lawful') expect(o.txt, M7GateLines.ownerYes);
            if (st.ver.id == 'ownerNo') expect(o.txt, M7GateLines.ownerNo);
          }
        }
      }
      expect(sawUp && sawLawful, isTrue);
      Set<String> breachOf(M7GFork f, String id) => m7gVersions(f).firstWhere((v) => v.id == id).breach;
      expect(breachOf(M7GFork.permit, 'verbal'), containsAll(['issuer', 'field']));
      expect(breachOf(M7GFork.accident, 'tidy'), containsAll(['mate', 'tool', 'ladder']));
      expect(breachOf(M7GFork.accident, 'back'), containsAll(['hurt', 'leader']));
    });

    test('objects: the same ids on a lawful and an unlawful version, every breach drawn, sizes fit a finger, no two taps stacked', () {
      for (var s = 0; s < 120; s++) {
        final d = dealM7G(math.Random(s));
        for (var i = 0; i < d.steps.length; i++) {
          final st = d.steps[i];
          final objs = m7gObjects(d, i);
          final ids = objs.map((o) => o.id).toList();
          expect(ids.toSet(), hasLength(ids.length), reason: 'unique ids at ${st.fork}');
          for (final o in objs) {
            expect(o.r.left, greaterThanOrEqualTo(-0.0001), reason: '${o.id} at ${st.fork}');
            expect(o.r.right, lessThanOrEqualTo(1.0001), reason: '${o.id} at ${st.fork}');
            expect(o.r.top, greaterThanOrEqualTo(-0.0001), reason: '${o.id} at ${st.fork}');
            expect(o.r.bottom, lessThanOrEqualTo(1.0001), reason: '${o.id} at ${st.fork}');
            if (o.hit) {
              expect(o.r.width * 360, greaterThanOrEqualTo(30), reason: '${o.id} at ${st.fork} is wide enough to tap');
              expect(o.r.height * 450, greaterThanOrEqualTo(36), reason: '${o.id} at ${st.fork} is tall enough to tap');
              expect(o.lines, isNotEmpty, reason: 'a close-up for ${o.id}');
              expect(o.title, isNotEmpty);
            }
          }
          // Every breach can be tapped (the field copy is the clipboard).
          for (final b in st.ver.breach) {
            expect(b == 'field' || ids.contains(b), isTrue, reason: '${st.fork} ${st.ver.id}: $b drawn');
          }
          // A hit target never sits on another's centre (the hidden man is on top).
          final hits = [for (final o in objs) if (o.hit && o.id != 'hid') o];
          for (final a in hits) {
            for (final b in hits) {
              if (a.id == b.id) continue;
              expect(b.r.contains(a.r.center), isFalse, reason: '${a.id} sits on ${b.id} at ${st.fork}');
            }
          }
          // A halted breach tap is only ever one object's.
          final fixedIds = m7gObjectIds(d, i, fixed: true);
          if (!{M7GFork.permit, M7GFork.kit, M7GFork.ret}.contains(st.fork)) {
            expect(m7gObjectIds(d, i), fixedIds, reason: 'same objects on both versions at ${st.fork}');
          }
        }
        // The lane's two AB switches can always be looked at.
        for (var i = 0; i < d.steps.length; i++) {
          if (d.steps[i].spot == 1) {
            expect(m7gObjectIds(d, i), containsAll(['abJob', 'abMain']));
          }
        }
      }
      // Giveaway checks: close-ups carry the same number of rows lawful or not.
      for (final f in [M7GFork.climber, M7GFork.kit, M7GFork.seal, M7GFork.line, M7GFork.hook, M7GFork.door]) {
        for (final v in m7gVersions(f).where((v) => !v.lawful)) {
          final a = _dealWhere((d) => d.steps.any((s) => s.fork == f && s.ver.id == 'lawful'));
          final b = _dealWhere((d) => d.steps.any((s) => s.fork == f && s.ver.id == v.id));
          final ia = a.steps.indexWhere((s) => s.fork == f);
          final ib = b.steps.indexWhere((s) => s.fork == f);
          final la = {for (final o in m7gObjects(a, ia)) o.id: o.lines.length};
          final lb = {for (final o in m7gObjects(b, ib)) o.id: o.lines.length};
          if (f == M7GFork.kit && v.id == 'stock') continue;
          for (final id in la.keys.where(lb.containsKey)) {
            expect(lb[id], la[id], reason: 'close-up detail of $id is the same at ${f.name} ${v.id}');
          }
        }
      }
    });

    test('F7: the live cue is the line the hook hangs on (the job DTR vs the other DTR); the tester and the earth are on the job span', () {
      final lawful = _dealWhere((d) => d.steps.any((s) => s.fork == M7GFork.hook && s.ver.lawful));
      final live = _dealWhere((d) => d.steps.any((s) => s.fork == M7GFork.hook && s.ver.id == 'live'));
      final il = lawful.steps.indexWhere((s) => s.fork == M7GFork.hook);
      final iv = live.steps.indexWhere((s) => s.fork == M7GFork.hook);
      final hl = m7gObjects(lawful, il).firstWhere((o) => o.id == 'hook');
      final hv = m7gObjects(live, iv).firstWhere((o) => o.id == 'hook');
      final laneHalf = lawful.laneLeft ? hl.r.center.dx < .5 : hl.r.center.dx > .5;
      expect(laneHalf, isTrue, reason: 'lawful: the hook is on the lane span');
      final mainHalf = live.laneLeft ? hv.r.center.dx > .5 : hv.r.center.dx < .5;
      expect(mainHalf, isTrue, reason: 'unlawful: the hook is on the main-road line');
      expect(hl.lines, hv.lines, reason: 'the hook reads the same close up');
      // The two switches read open/locked vs closed.
      final ab = {for (final o in m7gObjects(lawful, il)) o.id: o};
      expect(ab['abJob']!.lines.join(), contains('খোলা'));
      expect(ab['abJob']!.lines.join(), contains('তালা'));
      expect(ab['abMain']!.lines.join(), contains('লাগানো'));
      expect(ab['abJob']!.lines.join(), contains('HG'));
      expect(ab['tester']!.lines.first, contains('0 V'));
      expect(ab['earth']!.lines.first, contains('লাগানো'));
      // No DO anywhere in the gate's drawn words.
      for (var s = 0; s < 80; s++) {
        final d = dealM7G(math.Random(s));
        for (var i = 0; i < 10; i++) {
          for (final o in m7gObjects(d, i)) {
            for (final l in [...o.lines, o.title, o.txt]) {
              expect(RegExp(r'\bDO\b').hasMatch(l), isFalse, reason: l);
              expect(l, isNot(contains('AB বন্ধ')));
            }
          }
        }
      }
    });

    test('F12: lawful plays never show a man up the pole; some park a van or cart where one could hide; the line-up is the head-count', () {
      var parked = 0, up = 0;
      for (var s = 0; s < 300; s++) {
        final d = dealM7G(math.Random(s));
        final i = d.steps.length - 1;
        final ids = m7gObjects(d, i).map((o) => o.id).toSet();
        final men = ids.where((x) => RegExp(r'^g\d$').hasMatch(x)).length;
        if (d.steps.last.ver.deadly) {
          up++;
          expect(ids, contains('hid'));
          expect(men, d.n - 1, reason: 'one still up the pole');
        } else {
          expect(ids, isNot(contains('hid')));
          expect(men, d.n, reason: 'every man of the morning line-up on the ground');
          if (ids.contains('park')) parked++;
        }
        // The morning line-up shows as many cards as men.
        final j = d.steps.indexWhere((x) => x.fork == M7GFork.climber);
        if (j >= 0) {
          final cards = m7gObjects(d, j).where((o) => o.kind == M7GKind.idCard).length;
          expect(cards, d.n);
        }
      }
      expect(parked, greaterThan(30));
      expect(up, greaterThan(30));
    });

    test('F2: the climber\'s card shows one defect in the live checks (no age rule); every card has the same rows', () {
      for (final v in ['training', 'auth', 'cert', 'reg']) {
        final d = _dealWhere((d) => d.steps.any((s) => s.fork == M7GFork.climber && s.ver.id == v));
        final i = d.steps.indexWhere((s) => s.fork == M7GFork.climber);
        final cards = m7gObjects(d, i).where((o) => o.kind == M7GKind.idCard).toList();
        expect(cards.map((c) => c.lines.length).toSet(), {6});
        final bad = cards.firstWhere((c) => c.id == 'card_climber');
        final ok = cards.where((c) => c.id != 'card_climber');
        final defects = switch (v) {
          'training' => 'চলছে',
          'auth' => 'অনুমোদন: ফাঁকা',
          'cert' => 'নং: —',
          _ => 'নেই',
        };
        expect(bad.lines.join('|'), contains(defects), reason: v);
        for (final c in ok) {
          expect(c.lines.join('|'), isNot(contains(defects)), reason: 'the other men are fit');
        }
        expect(bad.lines.join(), isNot(contains('জন্ম')), reason: 'X3: no birth-year rule');
        expect(bad.lines.join(), isNot(contains('18')));
      }
    });

    test('F3: the glove cuff shows IS 4770 · টাইপ 4 (never "11 kV গ্লাভস"); an unrated glove is a lower type or unmarked', () {
      expect(M7GateLines.gloveCuff, 'IS 4770 · টাইপ 4');
      for (var s = 0; s < 100; s++) {
        final d = dealM7G(math.Random(s));
        for (var i = 0; i < 10; i++) {
          if (d.steps[i].fork != M7GFork.kit) continue;
          final g = m7gObjects(d, i).firstWhere((o) => o.id == 'gloves');
          final id = d.steps[i].ver.id;
          if (id == 'unrated') {
            expect(g.lines.first, anyOf(contains('টাইপ 2'), contains('কিছু লেখা নেই')));
          } else {
            expect(g.lines.first, contains('টাইপ 4'));
          }
          expect(g.lines.join(), isNot(contains('11 kV গ্লাভস')));
          expect(g.lines[1], id == 'torn' ? contains('ছেঁড়া') : contains('অটুট'));
          final h = m7gObjects(d, i).where((o) => o.id == 'helmet');
          if (h.isNotEmpty) expect(h.single.lines.first, id == 'helmet' ? contains('কিছু নেই') : contains('IS 2925'));
        }
      }
    });

    test('option libraries: fix and reason decks 1 right of ≥ 2, wrong of ≥ 5; every set within 1.3×; coworker options too', () {
      for (final e in M7GateLines.fixRight.entries) {
        final wrong = M7GateLines.fixWrongOf(e.key);
        expectLibrary('fix ${e.key}', e.value, wrong);
        expectSameLength('fix ${e.key}', [...e.value, ...wrong]);
      }
      for (final f in M7GFork.values) {
        for (final v in m7gVersions(f)) {
          if (v.lawful) continue;
          expect(M7GateLines.fixRight.containsKey(v.fix), isTrue, reason: '${f.name}.${v.id}');
          expect(M7GateLines.fixGroup[v.fix], isNotNull, reason: '${v.fix}: its own wrong cards');
        }
      }
      for (final f in M7GFork.values) {
        final key = f.name;
        expect(M7GateLines.whyGoRight.containsKey(key), isTrue, reason: key);
        expectLibrary('why $key', M7GateLines.whyGoRight[key]!, M7GateLines.whyWrongOf(key));
        expectSameLength('why $key', [...M7GateLines.whyGoRight[key]!, ...M7GateLines.whyWrongOf(key)]);
      }
      expectLibrary('closing', M7GateLines.closingRight, M7GateLines.whyWrongOf('closing'));
      expectSameLength('closing', [...M7GateLines.closingRight, ...M7GateLines.whyWrongOf('closing')]);
      for (final cw in M7GateLines.coworkers) {
        expectLibrary('coworker', cw.right, cw.wrong);
        expectSameLength('coworker ${cw.line}', [...cw.right, ...cw.wrong]);
      }
      expectSameLength('excuses', M7GateLines.excuses);
      // dealChoices gives three different cards each time.
      final rng = math.Random(2);
      for (var i = 0; i < 40; i++) {
        final o = dealChoices(M7GateLines.fixRight['hook.live']!, M7GateLines.fixWrongOf('hook.live'), rng);
        expect(o.map((x) => x.textBn).toSet(), hasLength(3));
        expect(o.where((x) => x.correct), hasLength(1));
      }
    });

    test('English digits on screen; owner term rules in the new text', () {
      final bnDigit = RegExp('[০-৯]');
      final lines = <String>[
        ...M7GateLines.newGuideLines,
        ...M7GateLines.newRivalLines,
        ...M7GateLines.newCrewLines,
        ...M7GateLines.excuses,
        ...M7GateLines.whyExcuses,
        for (final v in M7GateLines.whyGoWrong.values) ...v,
        ...M7GateLines.closingRight,
        ...M7GateLines.cwRight,
        ...M7GateLines.cwWrong,
        for (final v in M7GateLines.fixRight.values) ...v,
        for (final v in M7GateLines.fixWrong.values) ...v,
        for (final v in M7GateLines.whyGoRight.values) ...v,
        for (final f in M7GFork.values) ...[M7GateLines.caught(f), M7GateLines.crew(f)],
        M7GateLines.caughtPush,
        M7GateLines.caughtClose,
        M7GateLines.docketTitle,
        M7GateLines.docketCall(412),
        M7GateLines.ptwNo(412),
        M7GateLines.gloveCuff,
        M7GateLines.gloveCuffLow,
        M7GateLines.noticeGiven,
        M7GateLines.noticeNot,
      ];
      for (var s = 0; s < 100; s++) {
        final d = dealM7G(math.Random(s));
        for (var i = 0; i < d.steps.length; i++) {
          for (final o in m7gObjects(d, i)) {
            lines.addAll([...o.lines, o.title, o.txt]);
          }
        }
        final r = M7GRun(d);
        lines.addAll(r.fieldLines);
      }
      for (final l in lines) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
      // Owner term rules (the lesson myths are quoted as they are).
      final myths = {for (final cw in M7GateLines.coworkers) cw.line};
      for (final l in lines.where((l) => !myths.contains(l))) {
        expect(RegExp('মৃত(?!্যু)').hasMatch(l), isFalse, reason: 'ডেড, not মৃত: $l');
        expect(l, isNot(contains('এলটি')), reason: l);
        expect(l, isNot(contains('এইচটি')), reason: l);
        expect(l, isNot(contains('কেভি')), reason: l);
        expect(l, isNot(contains('অন ')), reason: 'ON, not অন: $l');
        expect(l, isNot(contains('অফ ')), reason: 'OFF, not অফ: $l');
        expect(l, isNot(contains('AB বন্ধ')), reason: l);
        expect(l, isNot(contains('11 kV গ্লাভস')), reason: l);
        expect(RegExp(r'\bDO\b').hasMatch(l), isFalse, reason: 'no DO in Module 7: $l');
        expect([0x09DF, 0x09DC, 0x09DD].any((c) => l.contains(String.fromCharCode(c))), isFalse, reason: 'base + nukta: $l');
      }
      for (final w in ['ডকেট', 'শাটডাউন', 'গ্লাভস']) {
        expect(lines.any((l) => l.contains(w)), isTrue, reason: 'locked word $w used');
      }
      expect(lines.any((l) => l.contains('গ্ল্যাভস') || l.contains('ডকেট্') || l.contains('শাট-ডাউন')), isFalse);
    });

    test("the coworker's lines: lesson myths word for word, recorded or listed; every spoken line listed", () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List;
      String myth(String id, int i) {
        final c = lessons.firstWhere((x) => (x as Map)['id'] == id) as Map;
        return _nk(((c['content'] as Map)['myth_buster'] as Map)['myths'][i]['myth'] as String);
      }

      expect(M7GateLines.pushClimber.line, myth('7.10', 1));
      expect(M7GateLines.pushKit.line, myth('7.6', 0));
      expect(M7GateLines.pushDoor.line, myth('7.9', 0));
      expect(M7GateLines.pushSeal.line, myth('7.5', 1));
      expect(M7GateLines.pushLine.line, myth('7.3', 1));
      expect(M7GateLines.pushOil.line, myth('7.8', 0));
      expect(M7GateLines.pushAccident.line, myth('7.7', 0));
      for (final f in M7GFork.values.where((f) => f.coworkerFork)) {
        expect(M7GateLines.coworkers, contains(M7GateLines.script(f)), reason: f.name);
      }
      for (final cw in M7GateLines.coworkers) {
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: cw.exitLine);
        expect(M7GateLines.newRivalLines, contains(cw.line));
      }
      final unrecorded = [for (final cw in M7GateLines.coworkers) if (LearnVoice.resolve(cw.line, rival: true) == null) cw.line];
      // ignore: avoid_print
      print('M7 gate rival lines with no clip yet: ${unrecorded.length}\n${unrecorded.join('\n')}');
      final guide = M7GateLines.newGuideLines;
      for (final l in [
        M7GateLines.intro, M7GateLines.ask, M7GateLines.haltAsk, M7GateLines.lensClose, ...M7GateLines.tapTasks,
        ...M7GateLines.tapWhy, ...M7GateLines.questions, M7GateLines.refused, M7GateLines.fail,
        M7GateLines.deadlyWord, M7GateLines.nearMissWord, M7GateLines.coworkerAsk,
        M7GateLines.promoted(M7GateLines.rankTo),
        for (final m in M7GMistakes.all) m.textBn,
      ]) {
        expect(guide, contains(l), reason: 'listed for the voice pass: $l');
      }
      for (final f in M7GFork.values) {
        expect(M7GateLines.newCrewLines, contains(M7GateLines.crew(f)), reason: 'the crew\'s words are listed');
      }
      for (final cw in M7GateLines.coworkers) {
        for (final a in cw.asks) {
          expect(guide, contains(a));
        }
      }
      expect(M7GateLines.questions, ['কেন এগোতে দিলেন?', 'আইন মতো এখন কী?', 'আজকের সইয়ে আপনি কী দায় নিয়েছিলেন?']);
      expect(M7GateLines.badge, 'আইন কি বলে?');
      expect(M7GateLines.promoted('সুপারভাইজার'), contains('আইন কি বলে?'));
      expect(M7GateLines.rankTo, 'সুপারভাইজার');
      // Crew words as the spec's flow gives them, the same on every version.
      expect(M7GateLines.crew(M7GFork.ret), 'কাজ শেষ — PTW ফেরত দিয়ে লাইন চালু করতে বলি?');
      expect(M7GateLines.crew(M7GFork.permit), 'লাইন বন্ধ করা আছে, এই নিন।');
    });

    test('the mistakes: unique keys, pictures, 7.x lesson points, the module table after the rulings; no Bangladesh source words', () {
      final keys = <String>{};
      for (final x in M7GMistakes.allWithLesson) {
        expect(keys.add(x.m.key), isTrue, reason: x.m.key);
        expect(x.m.key, startsWith('m7/gate/'));
        expect(File(x.m.art).existsSync(), isTrue, reason: x.m.art);
        expect(x.m.lessonPoint, isNotNull);
        expect(x.lessonId, startsWith('7.'));
        expect(M7GMistakes.lessonOf(x.m), x.lessonId);
        expect(x.m.textBn, isNotEmpty);
        expect(x.m.textBn, isNot(contains('বাংলাদেশ')));
      }
      for (final f in M7GFork.values) {
        expect(M7GMistakes.needless[f]!.lessonId, f.lesson);
        expect(M7GMistakes.listened[f]!.m.deadly, isFalse);
      }
      for (final f in M7GFork.values) {
        for (final v in m7gVersions(f).where((v) => !v.lawful)) {
          expect(v.mistake!.m.deadly, v.deadly, reason: '${f.name}.${v.id}');
          expect(v.mistake!.lessonId, anyOf(f.lesson, '7.6', '7.4', '7.10'), reason: '${f.name}.${v.id}');
        }
      }
      final used = {for (final x in M7GMistakes.allWithLesson) x.m.art.split('/').last};
      final files = {for (final f in Directory('assets/game/art/m7_gate_permit_day').listSync()) f.uri.pathSegments.last};
      expect(files, used, reason: 'every picture in the folder is used');
      // Lesson points exist in the live lesson.
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List;
      for (final x in M7GMistakes.allWithLesson) {
        final c = lessons.firstWhere((l) => (l as Map)['id'] == x.lessonId) as Map;
        final n = ((c['content'] as Map)['sections'] as List).fold<int>(0, (a, s) => a + ((s as Map)['points'] as List).length);
        expect(x.m.lessonPoint!, lessThan(n), reason: '${x.m.key} points into ${x.lessonId}');
      }
    });

    test('the scene: stage and clipboard fit every phone height; the guide asks the same line at every step', () {
      for (final h in [560.0, 700.0, 900.0]) {
        for (final inset in [0.0, 24.0]) {
          final g = M7GGeo(h, inset);
          expect(g.stage.height, greaterThanOrEqualTo(280));
          expect(g.stage.bottom, lessThanOrEqualTo(g.clip.top + 12), reason: 'the stage ends where the clipboard starts');
          expect(g.clip.bottom, lessThanOrEqualTo(h - inset));
          expect(g.clip.width, greaterThanOrEqualTo(300));
          expect(g.bubble.bottom, lessThanOrEqualTo(g.stage.top));
        }
      }
      expect(M7GateLines.ask, 'এগোতে দেবেন?');
      expect(M7GateLines.tapTasks, hasLength(3));
      expect(M7GateLines.intro, startsWith('আজ একটা পুরো কাজের দায় আপনার সইয়ে'));
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
      final p = M7GateProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7GatePermitDayPage(ctx: _ctx, pack: _pack, muted: true, seed: 4, probe: p))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      expect(p.phase, 'intro');
      await t.tapAt(const Offset(200, 500));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      expect(p.phase, 'wait');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    for (final reduce in [false, true]) {
      testWidgets('idle at a step draws zero frames (reduce motion: $reduce)', (t) async {
        if (reduce) {
          t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = M7GateProbe();
        final c = await _openPage(t, 7, p);
        expect(p.phase, 'wait');
        await _pump(t, 14000);
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(frames, lessThan(12), reason: 'idle step');
        expect(t.takeException(), isNull);
        await _closePage(t, c);
      });
    }

    testWidgets('look: a tap on anything opens its close-up (free); a tap on empty scene is ignored', (t) async {
      final p = M7GateProbe();
      final c = await _openPage(t, 7, p);
      expect(p.phase, 'wait');
      await t.tapAt(const Offset(30, 380));
      await t.pump();
      expect(p.phase, 'wait', reason: 'empty scene is ignored');
      await _tapKey(t, 'm7g-clip');
      expect(p.phase, 'closeup');
      expect(find.text(M7GateLines.fieldCopy), findsWidgets);
      expect(find.text('কাজ: 11 kV শাটডাউন'), findsWidgets);
      await _tapKey(t, 'm7g-lens-close');
      expect(p.phase, 'wait');
      await _tapKey(t, 'm7g-obj-${p.objectIds.first}');
      expect(p.phase, 'closeup');
      await _tapKey(t, 'm7g-lens-close');
      expect(p.run!.slips, 0);
      expect(p.run!.i, 0);
      await _closePage(t, c);
    });

    testWidgets('a full clean play to the rank-up: close-up, the first right এগোন asks why, halt → breach → fix decks, the coworker held and refused, the closing reason', (t) async {
      // The longest play: 4 lawful, 6 unlawful, with a deadly-class version among the unlawful.
      final seed = _seedWhere((d) => d.lawfulCount == 4 && d.deadlyCount == 2 && d.steps[1].ver.lawful);
      final p = M7GateProbe();
      final c = await _openPage(t, seed, p);
      final d = p.deal!;
      for (var i = 0; i < 10; i++) {
        expect(p.run!.i, i);
        await _playStep(t, p, look: i == 0);
        if (i == 9) break;
      }
      // The closing reason after F12.
      await _until(t, () => p.phase == 'closing', maxMs: 12000);
      expect(p.busy, isTrue);
      await _pickDeckRight(t, p);
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 12000);
      expect(find.text(M7GateLines.rankTo), findsOneWidget);
      expect(find.text(M7GateLines.badge), findsOneWidget);
      expect(find.text(M7GateLines.caughtPush), findsOneWidget, reason: 'the coworker was refused');
      expect(find.text(M7GateLines.caughtClose), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['m7/gate'], 'cleared');
      expect(save.rankIndex, 7, reason: 'সিনিয়র → সুপারভাইজার');
      expect(save.mistakes, isEmpty);
      expect(save.starsByRung['m7/gate'] ?? 0, greaterThanOrEqualTo(2));
      expect(p.run!.slips, 0);
      expect(p.run!.passed, isTrue);
      expect(d.deadlyCount, 2);
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
    }, timeout: const Timeout(Duration(minutes: 8)));

    testWidgets('a wrong এগোন on a deadly-class step: freeze, then the near-miss card', (t) async {
      final seed = _seedWhere((d) => d.steps.first.ver.deadly);
      final p = M7GateProbe();
      final c = await _openPage(t, seed, p);
      await _swipe(t, up: true);
      await _until(t, () => p.phase == 'freeze', maxMs: 3000, reason: 'the swipe up on a deadly-class permit');
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('harm')), findsOneWidget);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 7000);
      expect(find.text(p.run!.step.ver.mistake!.m.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['m7/gate'], isNot('cleared'));
      await _closePage(t, c);
    });

    testWidgets('a needless stop and a compliant tap are slips; three strike the gate out (a slip shows its card first)', (t) async {
      final seed = _seedWhere((d) => d.steps.first.ver.lawful);
      final p = M7GateProbe();
      final c = await _openPage(t, seed, p);
      for (var n = 1; n <= 3; n++) {
        await _swipe(t, up: false);
        if (n < 3) {
          await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
          expect(find.text(M7GMistakes.needless[M7GFork.permit]!.m.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await t.pump();
          await _until(t, () => p.phase == 'wait', maxMs: 4000);
          expect(p.run!.halted, isFalse, reason: 'the step waits again');
        }
      }
      await _until(t, () => find.byType(StruckOutCard).evaluate().isNotEmpty, maxMs: 4000);
      expect(p.run!.slips, 3);
      expect(c.read(gameSaveProvider).rungProgress['m7/gate'], isNot('cleared'));
      await _closePage(t, c);
    });

    testWidgets('halted: a tap on a compliant object is a slip and the step stays halted; empty scene is ignored', (t) async {
      final seed = _seedWhere((d) => !d.steps.first.ver.lawful && d.steps.first.ver.id == 'numbers');
      final p = M7GateProbe();
      final c = await _openPage(t, seed, p);
      await _swipe(t, up: false);
      expect(p.phase, 'halted');
      await t.tapAt(const Offset(30, 380));
      await t.pump();
      expect(p.run!.slips, 0, reason: 'empty scene is ignored');
      await _tapKey(t, 'm7g-obj-issuer');
      await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
      expect(find.text(M7GMistakes.compliant[M7GFork.permit]!.m.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await t.pump();
      await _until(t, () => p.phase == 'halted', maxMs: 4000);
      expect(p.run!.slips, 1);
      expect(p.run!.halted, isTrue);
      await _tapKey(t, 'm7g-clip');
      await _until(t, () => p.busy, maxMs: 4000, reason: 'the breach: ◆ and the fix deck');
      await _pickDeckRight(t, p);
      await _until(t, () => p.run!.i == 1, maxMs: 12000);
      expect(p.run!.slips, 1);
      await _closePage(t, c);
    });

    testWidgets('listening to the coworker is a slip and the step resolves as এগোন (one slip in total)', (t) async {
      final seed = _seedWhere((d) => d.steps[1].cw && d.steps[0].ver.lawful && d.steps[1].ver.lawful);
      final p = M7GateProbe();
      final c = await _openPage(t, seed, p);
      await _playStep(t, p);
      await _waitWait(t, p);
      expect(p.run!.i, 1);
      expect(p.run!.step.cw, isTrue);
      await _swipe(t, up: true);
      await _until(t, () => p.coworkerUp, maxMs: 6000, reason: 'he comes at the first swipe');
      await _waitDeckUp(t);
      final wrong = [for (final x in M7GateLines.cwWrong) if (_label(x).evaluate().isNotEmpty) _label(x)];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(M7GMistakes.listened[p.run!.fork]!.m.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await t.pump();
      await _until(t, () => p.run!.i == 2, maxMs: 12000, reason: 'the step resolved as এগোন');
      expect(p.run!.slips, 1, reason: 'one slip in total');
      await _closePage(t, c);
    });

    testWidgets('gesture hint at a step: shown while it waits (a sweep, then swipes on the field copy), pressing nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M7GateProbe();
      final c = await _openPage(t, 11, p);
      expect(p.phase, 'wait');
      await _pump(t, 9500);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget, reason: 'idle at a step');
      expect(p.phase, 'wait', reason: 'a hint presses nothing');
      expect(p.run!.slips, 0);
      expect(p.run!.i, 0);
      expect(find.byType(MistakeCard), findsNothing);
      // The close-up: the hand taps its close control.
      await _tapKey(t, 'm7g-clip');
      expect(p.phase, 'closeup');
      await _pump(t, 9500);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget, reason: 'idle on the close-up');
      expect(p.phase, 'closeup');
      await _closePage(t, c);
    });
  });
}
