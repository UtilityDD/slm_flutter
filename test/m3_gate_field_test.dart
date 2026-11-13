// Module 3 rank gate (m3_gate_field.dart, pack gate_m3): the rules of all
// seven stations (every over-call is a slip), the option libraries, the art
// on disk, and a full clean play in the shell that unlocks the টেকনিশিয়ান
// rank; the coworker comes even on a fast play; a deadly pick freezes (no
// control takes a touch) and shows its card; three slips strike out; the
// gesture hint shows after idle; the idle screen stays quiet.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_gate_field.dart';
import 'package:slm_flutter/features/game/m3_gate_field_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _rung = 'm3/gate';
final _pack = m3GateFieldPacks['gate_m3']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.gate,
      lessonId: '3.10',
      lessonTitleBn: 'টেকনিশিয়ানের ডকেট · র‍্যাঙ্ক গেট',
      ladderStep: 89,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = [
    for (final x in right)
      if (_label(x).evaluate().isNotEmpty) _label(x),
  ];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

Future<void> _tapKey(WidgetTester t, String key, {int ms = 400}) async {
  final f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await t.tap(f, warnIfMissed: false);
  await _pump(t, ms);
}

Future<void> _tapLabel(WidgetTester t, String l, {int ms = 400}) async {
  expect(_label(l), findsOneWidget, reason: l);
  await t.tap(_label(l), warnIfMissed: false);
  await _pump(t, ms);
}

Future<void> _reason(WidgetTester t, String q, List<String> right) async {
  await _pump(t, 3000);
  expect(find.text(q), findsWidgets);
  await _pickRight(t, right);
  await _pump(t, 3500);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M3GateFieldPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 600);
  expect(find.byType(GuideIntro), findsOneWidget);
  expect(find.text('শুরু'), findsNothing);
  await waitIntro(t);
  await _pump(t, 400);
  expect(find.byKey(const ValueKey('docket-modal')), findsOneWidget);
  expect(find.textContaining('শুরু'), findsNothing, reason: 'no start button');
  await t.tap(find.text(M3GateLines.docketOk));
  await _pump(t, 800);
  return c;
}

Future<void> _playSld(WidgetTester t) async {
  expect(find.text('SLD পড়া'), findsOneWidget);
  await _tapKey(t, 'sym-ab');
  await _tapKey(t, 'sym-no');
  await _tapLabel(t, M3GateLines.planOk);
  await _reason(t, M3GateLines.whySldQ, M3GateLines.whySldRight);
}

Future<void> _playPatrol(WidgetTester t, M3GateRun deal) async {
  expect(find.text('লাইন পেট্রোল'), findsOneWidget);
  for (final p in M3Part.values) {
    await _tapKey(t, 'part-${p.name}', ms: 300);
    await _tapKey(t, deal.faults[p] == null ? 'judge-ok' : 'judge-bad', ms: 500);
  }
  await _reason(t, M3GateLines.whyPatrolQ, M3GateLines.whyPatrolRight);
}

/// Station 3 up to the reason card's proceed (the DTR station opens next).
Future<void> _playFuseLa(WidgetTester t, M3GateRun deal) async {
  expect(find.text('DO ও LA'), findsOneWidget);
  for (var i = 0; i < 3; i++) {
    if (i != deal.dropped) await _tapKey(t, 'do-$i', ms: 1200);
  }
  await _tapKey(t, 'link-rated', ms: 600);
  await _tapKey(t, 'la', ms: 300);
  await _tapKey(t, deal.laFault == null ? 'judge-ok' : 'judge-bad', ms: 300);
  await _pump(t, 3000);
  expect(find.text(M3GateLines.whyFuseQ), findsWidgets);
  await _pickRight(t, M3GateLines.whyFuseRight);
}

bool _ltOn(WidgetTester t) {
  final paint = t.widget<CustomPaint>(find.descendant(of: find.byKey(const ValueKey('yard')), matching: find.byType(CustomPaint)).first);
  return (paint.painter! as M3DtrPainter).ltOn;
}

/// The ids (from [ids]) the idle hand sweeps, in its order ('?' for a rect
/// with no keyed hit, e.g. the plan button).
List<String> _sweptIds(WidgetTester t, List<String> ids) {
  final hint = find.byType(IdleHint).first;
  final box = t.renderObject<RenderBox>(hint);
  return [
    for (final o in t.state<IdleHintState>(hint).debugOptions)
      ids.firstWhere((id) {
        final f = find.byKey(ValueKey(id));
        return f.evaluate().isNotEmpty && (box.globalToLocal(t.getCenter(f)) - o.center).distance < 2;
      }, orElse: () => '?'),
  ];
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZlFx.setMuted(true);
  });

  group('rules', () {
    test('deal: three faulty parts, every dealt choice varies; plays differ', () {
      final noMid = <bool>{};
      final la = <M3LaFault?>{};
      final guard = <M3GuardFault>{};
      final faults = <String>{};
      for (var s = 0; s < 60; s++) {
        final r = M3GateRun(s);
        expect(r.faults.values.where((f) => f != null), hasLength(3));
        noMid.add(r.noMid);
        la.add(r.laFault);
        guard.add(r.guardFault);
        faults.add(r.faults.entries.map((e) => '${e.key.name}${e.value?.name}').join());
      }
      expect(noMid, {true, false});
      expect(la, {null, M3LaFault.crack, M3LaFault.hanging});
      expect(guard, M3GuardFault.values.toSet());
      expect(faults.length, greaterThan(8));
    });

    test('1 SLD: wrong symbol a slip, missing NO deadly, AB + NO plans', () {
      final r = M3GateRun(1);
      expect(r.markSym(M3SldSym.la), M3GateMistakes.wrongSymbol);
      expect(r.markSym(M3SldSym.dtrA), M3GateMistakes.wrongSymbol);
      expect(r.slips, 2);
      expect(r.confirmPlan(), isNull, reason: 'nothing marked: no cost');
      expect(r.planned, isFalse);
      r.markSym(M3SldSym.ab);
      expect(r.confirmPlan(), M3GateMistakes.ringBackfeed);
      expect(r.deadly, M3GateMistakes.ringBackfeed);

      final n = M3GateRun(1)..markSym(M3SldSym.no);
      expect(n.confirmPlan(), M3GateMistakes.sourceAb);
      n.markSym(M3SldSym.ab);
      expect(n.confirmPlan(), isNull);
      expect(n.planned, isTrue);
    });

    test('2 patrol: a wrong verdict either way is a slip (an over-call is not free)', () {
      final r = M3GateRun(2);
      for (final p in M3Part.values) {
        final f = r.faults[p];
        if (f == null) {
          expect(r.partFault(p), M3GateMistakes.soundFlagged, reason: 'flagging a sound part costs');
          expect(r.judged(p), isFalse);
          expect(r.partOk(p), isNull);
        } else {
          expect(r.partOk(p), M3GateMistakes.forFault(f));
          expect(r.partFault(p), isNull);
        }
      }
      expect(r.slips, 5, reason: 'three missed faults + two over-calls');
      expect(r.patrolDone, isTrue);
    });

    test('3 DO and LA: all three open first; thick wire deadly; LA verdicts', () {
      final r = M3GateRun(3);
      expect(r.chooseLink(M3Link.rated), M3GateMistakes.allThree);
      for (var i = 0; i < 3; i++) {
        r.openDo(i);
      }
      expect(r.allDoOpen, isTrue);
      expect(r.chooseLink(M3Link.anyWire), M3GateMistakes.anyWire);
      expect(r.chooseLink(M3Link.overRated), M3GateMistakes.overRated);
      expect(r.chooseLink(M3Link.rated), isNull);
      expect(M3GateRun(3).chooseLink(M3Link.thickWire), M3GateMistakes.thickWire);

      var s = 0;
      while (M3GateRun(s).laFault != M3LaFault.hanging) {
        s++;
      }
      final bad = M3GateRun(s);
      expect(bad.laOk(), M3GateMistakes.laHanging);
      expect(bad.laReplace(), isNull);
      expect(bad.laJudged, isTrue);
      expect(bad.laReplace(), isNull, reason: 'judged: no second cost');
      expect(bad.slips, 1);
      s = 0;
      while (M3GateRun(s).laFault != null) {
        s++;
      }
      final good = M3GateRun(s);
      expect(good.laReplace(), M3GateMistakes.laSound, reason: 'replacing a healthy LA is a slip');
      expect(good.laJudged, isFalse);
      expect(good.laOk(), isNull);
      expect(good.laJudged, isTrue);
      expect(good.slips, 1);
    });

    test('4 DTR: health first, LT on is deadly, LT off turns the tap', () {
      var s = 0;
      while (!(M3GateRun(s).gelPinkDealt && M3GateRun(s).oilLeakDealt)) {
        s++;
      }
      final r = M3GateRun(s);
      expect(r.turnTap(), isNull);
      expect(r.tapped, isFalse);
      expect(r.gelOk(), M3GateMistakes.gelPink);
      expect(r.oilOk(), M3GateMistakes.oilLeak);
      expect(r.gelReplace(), isNull);
      expect(r.oilReport(), isNull);
      expect(r.turnTap(), M3GateMistakes.tapLive);
      expect(r.ended, isTrue);
      expect(r.turnTap(), isNull, reason: 'nothing more after a death');

      final ok = M3GateRun(s)
        ..gelReplace()
        ..oilReport()
        ..switchLtOff();
      expect(ok.turnTap(), isNull);
      expect(ok.tap, ok.tapTo);

      s = 0;
      while (M3GateRun(s).gelPinkDealt || M3GateRun(s).oilLeakDealt) {
        s++;
      }
      final dry = M3GateRun(s);
      expect(dry.gelReplace(), M3GateMistakes.gelDry, reason: 'blue gel replaced: an over-call');
      expect(dry.oilReport(), M3GateMistakes.oilDry, reason: 'a dry tank reported: an over-call');
      expect(dry.healthDone, isFalse);
      expect(dry.gelOk(), isNull);
      expect(dry.oilOk(), isNull);
      expect(dry.slips, 2);
    });

    test('5 pillar: PPE, test, the blown fuse, copper deadly, hot spot before lock', () {
      final r = M3GateRun(5);
      expect(r.testBus(), M3GateMistakes.pillarPpe);
      r
        ..pGloves = true
        ..pShield = true;
      expect(r.tapFuse(r.blownWay, r.blownPh), M3GateMistakes.noTest);
      expect(r.testBus(), isNull);
      expect(r.tapFuse((r.blownWay + 1) % 3, r.blownPh), M3GateMistakes.wrongFuse, reason: 'pulling a sound fuse costs');
      expect(r.pickingFuse, isFalse);
      expect(r.tapFuse(r.blownWay, r.blownPh), isNull);
      expect(r.pickingFuse, isTrue);
      expect(r.fitHrc(M3Hrc.bigger), M3GateMistakes.hrcBigger);
      expect(r.fitHrc(M3Hrc.same), isNull);
      expect(r.lock(), M3GateMistakes.hotspot);
      expect(r.tighten((r.hotBolt + 1) % 6), M3GateMistakes.wrongBolt, reason: 'a sound bolt is no hot spot');
      expect(r.tightened, isFalse);
      expect(r.tighten(r.hotBolt), isNull);
      expect(r.tighten((r.hotBolt + 1) % 6), isNull, reason: 'found: no more cost');
      expect(r.lock(), isNull);
      expect(r.locked, isTrue);
      expect(r.slips, 6, reason: 'PPE, no test, a sound fuse, bigger HRC, hot spot, a sound bolt');

      final c = M3GateRun(5)
        ..pGloves = true
        ..pShield = true
        ..testBus();
      c.tapFuse(c.blownWay, c.blownPh);
      expect(c.fitHrc(M3Hrc.copperStrip), M3GateMistakes.copperStrip);
      expect(c.deadly, isNotNull);
    });

    test('6 service and 7 guard: slips per step, bare-hand neutral and guard deadly', () {
      final r = M3GateRun(6);
      expect(r.serviceChoose(right: false), M3GateMistakes.wrongCore);
      expect(r.serviceChoose(right: true), isNull);
      expect(r.serviceChoose(right: false), M3GateMistakes.noBearer);
      expect(r.serviceChoose(right: true), isNull);
      expect(r.serviceChoose(right: false), M3GateMistakes.noDrip);
      expect(r.serviceChoose(right: true), isNull);
      expect(r.serviceChoose(right: false), M3GateMistakes.neutralBare);
      expect(r.deadly, M3GateMistakes.neutralBare);

      final g = M3GateRun(7);
      expect(g.touchGuard(g.guardFault), M3GateMistakes.guardBare);
      final h = M3GateRun(7)..gGloves = true;
      expect(h.energise(), h.guardFault == M3GuardFault.brokenWire ? M3GateMistakes.guardWire : M3GateMistakes.guardEarth);
      final other = M3GuardFault.values.firstWhere((f) => f != h.guardFault);
      expect(h.touchGuard(other), M3GateMistakes.guardSpot, reason: 'a spot with nothing wrong costs');
      expect(h.guardFixed, isFalse);
      expect(h.touchGuard(h.guardFault), isNull);
      expect(h.energise(), isNull);
    });

    test('the mark: 15 per slip; two slips still pass (the third strikes out on the page)', () {
      final r = M3GateRun(8);
      for (var i = 0; i < M3GateStation.values.length; i++) {
        r.advanceStation();
      }
      expect(r.done, isTrue);
      r.slips = 2;
      expect(r.percent, 70);
      expect(r.passed, isTrue);
      r.slips = 3;
      expect(r.percent, 55, reason: 'the mark a struck-out play records');
    });

    test('after a death no rule acts any more', () {
      final r = M3GateRun(9)..markSym(M3SldSym.ab);
      expect(r.confirmPlan(), M3GateMistakes.ringBackfeed);
      expect(r.ended, isTrue);
      final slips = r.slips;
      expect(r.markSym(M3SldSym.no), isNull);
      expect(r.marked.contains(M3SldSym.no), isFalse);
      expect(r.confirmPlan(), isNull);
      expect(r.markSym(M3SldSym.la), isNull);
      for (final p in M3Part.values) {
        expect(r.partOk(p), isNull);
        expect(r.partFault(p), isNull);
      }
      expect(r.chooseLink(M3Link.anyWire), isNull);
      expect(r.laReplace(), isNull);
      expect(r.testBus(), isNull);
      expect(r.serviceChoose(right: false), isNull);
      expect(r.touchGuard(r.guardFault), isNull);
      expect(r.energise(), isNull);
      expect(r.slips, slips);
    });

    test('6 service deals: three options a step, one right, shuffled per play', () {
      final orders = <String>{};
      for (var s = 0; s < 30; s++) {
        final r = M3GateRun(s);
        for (var i = 0; i < 4; i++) {
          final d = r.serviceDeal(i);
          expect(d, hasLength(3));
          expect(d.where((o) => o.correct), hasLength(1));
          expect(d.map((o) => o.textBn).toSet(), hasLength(3));
          expect(r.serviceDeal(i).map((o) => o.textBn).toList(), d.map((o) => o.textBn).toList(), reason: 'stable within a play');
        }
        final cable = r.serviceDeal(0);
        expect(cable.map((o) => o.textBn).toSet(), {M3GateLines.cableTwin, M3GateLines.cableFour, M3GateLines.cableBare});
        expect(cable.firstWhere((o) => o.correct).textBn, r.threePhase ? M3GateLines.cableFour : M3GateLines.cableTwin);
        orders.add(r.serviceDeal(2).map((o) => o.textBn).join('|'));
      }
      expect(orders.length, greaterThan(2), reason: 'the right option is not always in one place');
    });
  });

  group('content', () {
    test('reason libraries: ≥2 right, ≥5 wrong, lengths within 1.3×', () {
      final libs = {
        'sld': (M3GateLines.whySldRight, M3GateLines.whySldWrong),
        'patrol': (M3GateLines.whyPatrolRight, M3GateLines.whyPatrolWrong),
        'fuse': (M3GateLines.whyFuseRight, M3GateLines.whyFuseWrong),
        'dtr': (M3GateLines.whyDtrRight, M3GateLines.whyDtrWrong),
        'pillar': (M3GateLines.whyPillarRight, M3GateLines.whyPillarWrong),
        'service': (M3GateLines.whyServiceRight, M3GateLines.whyServiceWrong),
        'guard': (M3GateLines.whyGuardRight, M3GateLines.whyGuardWrong),
      };
      for (final e in libs.entries) {
        expectLibrary(e.key, e.value.$1, e.value.$2);
        expectSameLength(e.key, [...e.value.$1, ...e.value.$2]);
      }
      final cw = M3GateLines.coworker;
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 2, minWrong: 4);
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      for (final three in [true, false]) {
        for (var i = 0; i < 4; i++) {
          final (right, wrong) = M3GateLines.serviceOptions(i, threePhase: three);
          expect(wrong, hasLength(2));
          expectSameLength('service $i', [right, ...wrong]);
        }
      }
    });

    test('no giveaways: the guide never calls a part fine; AB-1 wording follows 3.10', () {
      // No verdict line ("এটা তো ঠিক আছে।", "এই ফিউজ ঠিক আছে —") before a decision.
      final verdict = RegExp('ঠিক আছে(।| —)');
      for (final l in M3GateLines.recordable) {
        expect(verdict.hasMatch(l), isFalse, reason: l);
      }
      expect(M3GateMistakes.sourceAb.textBn.contains('প্রথম বিচ্ছিন্ন'), isFalse);
      expect(M3GateMistakes.sourceAb.textBn, contains('অন-লোডে'));
      // The neutral step: every wrong option is a bare hand (deadly, as before),
      // worded apart so the right one is not the only one without 'খালি হাতে'.
      final (_, bare) = M3GateLines.serviceOptions(3, threePhase: false);
      for (final w in bare) {
        expect(w.contains('খালি হাতে') || w.contains('গ্লাভস খুলে'), isTrue, reason: w);
      }
      expect(bare.any((w) => !w.contains('খালি হাতে')), isTrue);
      // The guide's restatements never name a hidden fault (the hot spot).
      for (final l in M3GateLines.tasks.values.expand((x) => x)) {
        expect(l.contains('ঢিলা'), isFalse, reason: l);
      }
      // The key words of a right option show up on a wrong one too.
      for (final (step, word) in [(1, 'বিয়ারার'), (2, 'লুপ'), (2, 'U'), (2, 'নিচে'), (3, 'লাইভ'), (3, 'গ্লাভস')]) {
        final (right, wrong) = M3GateLines.serviceOptions(step, threePhase: false);
        expect(right, contains(word));
        expect(wrong.any((w) => w.contains(word)), isTrue, reason: 'step $step: "$word" only on the right option');
      }
    });

    test('a deal: one right, three different options', () {
      final d = dealChoices(M3GateLines.whyDtrRight, M3GateLines.whyDtrWrong, math.Random(9));
      expect(d.where((o) => o.correct), hasLength(1));
      expect(d.map((o) => o.textBn).toSet(), hasLength(3));
    });

    test('mistakes: unique keys led by their lesson id, art on disk, six deadly', () {
      final keys = <String>{};
      for (final m in M3GateMistakes.all) {
        expect(m.key, matches(RegExp(r'^3\.(10|[1-9])/m3_gate_field/[a-z-]+$')), reason: m.key);
        expect(keys.add(m.key), isTrue, reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.textBn.length, lessThan(140), reason: m.key);
        expect(m.lessonPoint, isNotNull, reason: m.key);
      }
      expect(M3GateMistakes.all.where((m) => m.deadly).map((m) => m.key).toSet(), {
        '3.10/m3_gate_field/ring-no',
        '3.4/m3_gate_field/thick-wire',
        '3.6/m3_gate_field/tap-live',
        '3.7/m3_gate_field/copper-strip',
        '3.8/m3_gate_field/neutral-bare',
        '3.9/m3_gate_field/guard-bare',
      });
      expect(M3GateMistakes.lessonOf('3.10/m3_gate_field/ring-no'), '3.10');
    });

    test('lines for recording; Bangla digits never on screen; no পানি', () {
      expect(M3GateLines.recordable, isNotEmpty);
      final bnDigit = RegExp('[০-৯]');
      final all = [
        ...M3GateLines.recordable,
        ...M3GateLines.stationTitles.values,
        ...M3GateLines.linkNames.values,
        ...M3GateLines.hrcNames.values,
        for (var i = 0; i < 4; i++) ...[
          for (final three in [true, false]) ...[
            M3GateLines.serviceOptions(i, threePhase: three).$1,
            ...M3GateLines.serviceOptions(i, threePhase: three).$2,
          ],
        ],
        M3GateLines.docketOk,
        M3GateRankText.stamp,
        for (final m in M3GateMistakes.all) m.textBn,
      ];
      for (final l in all) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
    });
  });

  group('page', () {
    testWidgets('a full clean play: seven stations, the coworker refused, টেকনিশিয়ান unlocked', (t) async {
      const seed = 4;
      final deal = M3GateRun(seed);
      final c = await _open(t, seed);

      // 1–3 — SLD, patrol, DO and LA.
      await _playSld(t);
      await _playPatrol(t, deal);
      await _playFuseLa(t, deal);
      await _pump(t, 3500);

      // 4 — DTR; the coworker comes and is refused.
      expect(find.text('DTR ও ট্যাপ'), findsOneWidget);
      await _pickRight(t, M3GateLines.coworker.right);
      await _pump(t, 2500);
      await _tapKey(t, 'gel', ms: 300);
      await _tapKey(t, deal.gelPinkDealt ? 'judge-bad' : 'judge-ok', ms: 500);
      await _tapKey(t, 'oil', ms: 300);
      await _tapKey(t, deal.oilLeakDealt ? 'judge-bad' : 'judge-ok', ms: 500);
      await _tapKey(t, 'lt-switch');
      await _tapKey(t, 'tap');
      await _reason(t, M3GateLines.whyDtrQ, M3GateLines.whyDtrRight);

      // 5 — feeder pillar.
      expect(find.text('ফিডার পিলার'), findsOneWidget);
      await _tapKey(t, 'door');
      await _tapLabel(t, M3GateLines.gloves, ms: 200);
      await _tapLabel(t, M3GateLines.faceShield, ms: 200);
      await _tapKey(t, 'bus');
      await _tapKey(t, 'fuse-${deal.blownWay}-${deal.blownPh}');
      await _tapKey(t, 'hrc-same', ms: 1500);
      await _tapKey(t, 'bolt-${deal.hotBolt}');
      await _tapLabel(t, M3GateLines.lockDoor);
      await _reason(t, M3GateLines.whyPillarQ, M3GateLines.whyPillarRight);

      // 6 — service drop: one deck per step.
      expect(find.text('সার্ভিস ড্রপ'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await waitChoiceDeck(t);
        final right = deal.serviceDeal(i).firstWhere((o) => o.correct).textBn;
        await _tapLabel(t, right, ms: 0);
        await confirmChoice(t);
        await _pump(t, i < 3 ? 1500 : 400);
      }
      await _reason(t, M3GateLines.whyServiceQ, M3GateLines.whyServiceRight);

      // 7 — guard.
      expect(find.text('ক্রেডল গার্ডিং'), findsOneWidget);
      await _tapLabel(t, M3GateLines.gloves, ms: 200);
      await _tapKey(t, 'guard-${deal.guardFault.name}', ms: 1500);
      await _tapLabel(t, M3GateLines.guardOn);
      await _reason(t, M3GateLines.whyGuardQ, M3GateLines.whyGuardRight);
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.rankIndex, 3);
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3GateRankText.stamp), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the coworker comes even on a fast play: the LT switch waits for him', (t) async {
      const seed = 4;
      final deal = M3GateRun(seed);
      final c = await _open(t, seed);
      await _playSld(t);
      await _playPatrol(t, deal);
      await _playFuseLa(t, deal);
      await _pump(t, 300);
      expect(find.text('DTR ও ট্যাপ'), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'he has not come yet');
      // Straight to the LT switch, before he turns up by himself.
      await t.tap(find.byKey(const ValueKey('lt-switch')), warnIfMissed: false);
      await t.pump();
      expect(_ltOn(t), isTrue, reason: 'the switch waits for him');
      await waitChoiceDeck(t);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'he came at once');
      // While he is on, the scene takes no move.
      await t.tap(find.byKey(const ValueKey('lt-switch')), warnIfMissed: false);
      await t.pump();
      expect(_ltOn(t), isTrue);
      // Listening is a slip (its card), and the job goes on.
      final wrong = [
        for (final w in M3GateLines.coworker.wrong)
          if (_label(w).evaluate().isNotEmpty) _label(w),
      ];
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.text(M3GateMistakes.coworkerLt.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapKey(t, 'lt-switch');
      expect(_ltOn(t), isFalse, reason: 'after him the switch works');
      expect(c.read(gameSaveProvider).mistakes.single.key, M3GateMistakes.coworkerLt.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a station pays its ◆ once, from the table after the reason (not on the move)', (t) async {
      final c = await _open(t, 4);
      int score() => t.widget<FullSceneFrame>(find.byType(FullSceneFrame)).levelScore;
      await _tapKey(t, 'sym-ab');
      await _tapKey(t, 'sym-no');
      await _tapLabel(t, M3GateLines.planOk, ms: 1500);
      expect(score(), 0, reason: 'the ◆ wait on the table');
      // The praise window: a second tap on the plan cannot score or slip.
      if (_label(M3GateLines.planOk).evaluate().isNotEmpty) await t.tap(_label(M3GateLines.planOk), warnIfMissed: false);
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // The reason deck is up (tableBusy). The docket chip's handler is gated by
      // _canAct alone; called straight (past any shield) it must do nothing.
      await waitChoiceDeck(t);
      final docket = find.descendant(of: find.byKey(const ValueKey('station-chip')), matching: find.byType(GestureDetector));
      expect(docket, findsOneWidget);
      t.widget<GestureDetector>(docket).onTap!();
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing, reason: 'no move while the table is busy');
      expect(score(), 0);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _pickRight(t, M3GateLines.whySldRight);
      await _pump(t, 1500);
      expect(score(), 20);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('flagging a sound part is a slip with its card; the guide never calls it fine', (t) async {
      const seed = 4;
      final deal = M3GateRun(seed);
      final sound = M3Part.values.firstWhere((p) => deal.faults[p] == null);
      final c = await _open(t, seed);
      await _playSld(t);
      await _tapKey(t, 'part-${sound.name}', ms: 300);
      await _tapKey(t, 'judge-bad', ms: 800);
      expect(find.text(M3GateMistakes.soundFlagged.textBn), findsOneWidget);
      expect(find.textContaining('এটা তো ঠিক আছে'), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3GateMistakes.soundFlagged.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips fail the gate: the struck-out card insists on the lesson', (t) async {
      final c = await _open(t, 6);
      for (final (i, sym) in [M3SldSym.la, M3SldSym.dtrA].indexed) {
        await _tapKey(t, 'sym-${sym.name}', ms: 800);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      expect(find.byType(StruckOutCard), findsNothing);
      await _tapKey(t, 'sym-earth', ms: 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'the third slip shows its card first');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-row')), findsNothing, reason: 'no control after the strike-out');
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey(_rung), isTrue);
      expect(s.rungProgress[_rung], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('tapping the guide restates the task a different way, at no cost', (t) async {
      final c = await _open(t, 4);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      final tasks = M3GateLines.tasks[M3GateStation.sld]!;
      expect(lines.every(tasks.contains), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.widget<FullSceneFrame>(find.byType(FullSceneFrame)).levelScore, 0);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep over every symbol after idle; a touch hides it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 3);
      IdleHintState frameHint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(t.widget<IdleHint>(find.byType(IdleHint).first).waiting, isTrue);
      await _pump(t, 9000);
      expect(frameHint().showing, isTrue, reason: 'idle on the SLD: the hand sweeps');
      expect(frameHint().debugOptions, hasLength(M3SldSym.values.length + 1), reason: 'every symbol and the plan button, not one');
      // The hand enters at the first rect: never the enum order (AB-1, NO first).
      final syms = [for (final s in M3SldSym.values) 'sym-${s.name}'];
      final swept = _sweptIds(t, syms);
      expect(swept.where((id) => id != '?').toSet(), syms.toSet(), reason: '$swept');
      expect(swept.first, isNot('sym-ab'), reason: '$swept');
      expect(swept.take(2).toSet(), isNot({'sym-ab', 'sym-no'}), reason: '$swept');
      expect(swept.where((id) => id != '?').toList(), isNot(syms), reason: '$swept');
      await _tapKey(t, 'sym-ab', ms: 200);
      expect(frameHint().showing, isFalse, reason: 'a touch hides it');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint at the DTR: the sweep does not follow the procedure', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 4;
      final deal = M3GateRun(seed);
      final c = await _open(t, seed);
      await _playSld(t);
      await _playPatrol(t, deal);
      await _playFuseLa(t, deal);
      await _pump(t, 3500);
      expect(find.text('DTR ও ট্যাপ'), findsOneWidget);
      await _pickRight(t, M3GateLines.coworker.right);
      await _pump(t, 9000);
      expect(t.state<IdleHintState>(find.byType(IdleHint).first).showing, isTrue);
      const steps = ['gel', 'oil', 'lt-switch', 'tap'];
      final swept = _sweptIds(t, steps);
      expect(swept.toSet(), steps.toSet(), reason: '$swept');
      expect(swept.first, isNot('gel'), reason: '$swept');
      expect(swept, isNot(steps), reason: '$swept');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('planning without the NO point: the scene freezes, then the deadly card', (t) async {
      final c = await _open(t, 5);
      await _tapKey(t, 'sym-ab');
      await t.tap(_label(M3GateLines.planOk));
      await _pump(t, 700);
      expect(find.byKey(const ValueKey('freeze')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      // Frozen: no control or docket chip takes a touch.
      expect(find.byKey(const ValueKey('plan-row')), findsNothing);
      expect(find.byKey(const ValueKey('station-chip')), findsNothing);
      await t.tap(find.byKey(const ValueKey('sym-no')), warnIfMissed: false);
      await t.pump();
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3GateMistakes.ringBackfeed.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong symbol is a slip with its card', (t) async {
      final c = await _open(t, 6);
      await _tapKey(t, 'sym-la', ms: 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3GateMistakes.wrongSymbol.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        var rebuilds = 0;
        debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final c = await _open(t, 3);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m3_gate_field ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        debugOnRebuildDirtyWidget = null;
        expect(t.takeException(), isNull);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await _close(t, c);
      });
    }
  });
}
