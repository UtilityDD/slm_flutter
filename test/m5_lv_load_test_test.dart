// Lesson 5.5 ('লো-ভোল্টেজ' সমস্যার সমাধান), কাজ 2 "লোড দিয়ে মাপুন": the rules
// (the deal; the readings — the needle sags under the complaint load in a
// service-fault call and holds in an inside-house call, N–E 15–22 V with a
// weak neutral; evidence-gated verdicts; the method deck's deadly picks; every
// joint; the loaded re-measure and the load-grew report), the libraries, and
// the level in the shell: the guide first, tapping him, a full clean play with
// the coworker refused and a reason picked, a slip card, three slips, the
// deadly freeze, the coworker holding the next control, the gesture hand.
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
import 'package:slm_flutter/features/game/m5_lv_load_test.dart';
import 'package:slm_flutter/features/game/m5_lv_load_test_world.dart';
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
  rungId: '5.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5LvLoadTestPacks['do_5_5_b']!;

/// The art folder may not be bundled in a test build: read it from disk.
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
M5LvLoadGeo get _geo => M5LvLoadGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design, {int ms = 300}) async {
  await t.tapAt(design * _k);
  await _pump(t, ms);
}

Future<void> _term(WidgetTester t, M5LvLoadTerm term) => _tapAt(t, _geo.termAt(term));

Future<void> _button(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5LvLoadTestPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 3000);
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2600);
}

/// One call, played right: P–N (the coworker refused on his call), the
/// complaint on, N–E, the verdict (its reason), the method, every joint, the
/// loaded re-measure (ask the customer in a load-grew call), the close.
Future<void> _playCall(WidgetTester t, M5LvLoadCall call, {required bool coworker}) async {
  await _term(t, M5LvLoadTerm.p);
  await _term(t, M5LvLoadTerm.n);
  if (coworker) await _refuse(t, M5LvLoadLines.coworkerNoLoad[call.complaint]!);
  await _button(t, M5LvLoadLines.name(call.complaint));
  await _term(t, M5LvLoadTerm.e);
  expect(find.text('${call.neOk} V').evaluate().isNotEmpty || find.text('${call.neFault} V').evaluate().isNotEmpty, isTrue,
      reason: 'N–E on the tester');
  await _button(t, M5LvLoadLines.verdictBtn);
  await _pickRight(t, M5LvLoadLines.verdictRight(call.kind));
  await _pump(t, 400);
  if (call.why != M5LvLoadWhy.joints) await _reason(t, M5LvLoadLines.whyRight[call.why]!);
  if (!call.service) {
    await _pump(t, 1500);
    return;
  }
  await _pickRight(t, M5LvLoadLines.methodRight);
  await _pump(t, 600);
  for (final j in M5LvLoadJoint.values) {
    await _tapAt(t, _geo.jointAt(j));
  }
  await _button(t, M5LvLoadLines.doneBtn);
  await _pump(t, 400);
  if (call.why == M5LvLoadWhy.joints) await _reason(t, M5LvLoadLines.whyRight[M5LvLoadWhy.joints]!);
  await _term(t, M5LvLoadTerm.p);
  await _term(t, M5LvLoadTerm.n);
  if (call.kind == M5LvLoadKind.loadGrew) await _tapAt(t, _geo.door.center, ms: 600);
  await _button(t, M5LvLoadLines.verdictBtn);
  await _pickRight(t, M5LvLoadLines.closeRight(call.kind));
  await _pump(t, 1800);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${call.kind}');
}

M5LvLoadCall _callOf(M5LvLoadKind k, {M5LvLoadAppliance complaint = M5LvLoadAppliance.pump, M5LvLoadWhy why = M5LvLoadWhy.loaded}) => M5LvLoadCall(
      kind: k,
      complaint: complaint,
      switches: [complaint, M5LvLoadAppliance.fan, M5LvLoadAppliance.light, M5LvLoadAppliance.tv],
      smallOn: null,
      nominal: 230,
      depth: switch (k) {
        M5LvLoadKind.loose => 50,
        M5LvLoadKind.weakNeutral => 40,
        M5LvLoadKind.inside => 3,
        M5LvLoadKind.loadGrew => 46,
      },
      neFault: 18,
      neOk: 2,
      reply: 0,
      why: why,
      wall: 0,
    );

M5LvLoadRun _runOf(M5LvLoadKind k) => M5LvLoadRun(M5LvLoadDeal(calls: [_callOf(k), _callOf(M5LvLoadKind.loose), _callOf(M5LvLoadKind.inside)], cwCall: 1));

/// Takes the readings a right verdict needs (P–N under the load, N–E).
void _measure(M5LvLoadRun r) {
  r
    ..tapTerm(M5LvLoadTerm.p)
    ..tapTerm(M5LvLoadTerm.n)
    ..toggle(r.call.complaint)
    ..tapTerm(M5LvLoadTerm.e);
}

const _flowSeeds = [7, 12];

void main() {
  group('rules', () {
    test('deals: three different calls, ≥2 service faults, him on a service call; the switchboard; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m5LvLoadDeal(math.Random(s));
        expect(d.calls, hasLength(3));
        expect(d.calls.map((c) => c.kind).toSet(), hasLength(3));
        expect(d.calls.where((c) => c.service).length, greaterThanOrEqualTo(2));
        expect(d.calls[d.cwCall].service, isTrue);
        for (final c in d.calls) {
          expect(m5LvLoadComplaints, contains(c.complaint));
          expect(c.switches.toSet(), {c.complaint, ...m5LvLoadSmall});
          expect(c.nominal, inInclusiveRange(226, 236));
          expect(c.neFault, inInclusiveRange(15, 22));
          expect(c.neOk, inInclusiveRange(1, 3));
          if (c.smallOn != null) expect(m5LvLoadSmall, contains(c.smallOn));
          if (!c.service) expect(c.why, isNot(M5LvLoadWhy.joints));
          if (!c.service) expect(c.why, isNot(M5LvLoadWhy.service));
          if (c.service) expect(c.why, isNot(M5LvLoadWhy.inside));
        }
        final calls = [for (final c in d.calls) '${c.kind.name}/${c.complaint.name}/${c.why.name}/${c.switches.first.name}'].join('|');
        seen.add('$calls|${d.cwCall}');
      }
      expect(seen.length, greaterThan(40));
    });

    test('readings: no load near normal; the complaint load sags a service fault and holds inside; N–E bands; supply off 0 V', () {
      for (final k in M5LvLoadKind.values) {
        final r = _runOf(k)
          ..tapTerm(M5LvLoadTerm.p)
          ..tapTerm(M5LvLoadTerm.n);
        expect(r.reading, inInclusiveRange(226, 236), reason: '$k no load');
        r.toggle(r.call.complaint);
        if (k == M5LvLoadKind.inside) {
          expect(r.reading, greaterThanOrEqualTo(220), reason: 'holds');
        } else {
          expect(r.reading, lessThanOrEqualTo(196), reason: '$k sags');
        }
        // The small loads never look like the complaint.
        r
          ..toggle(r.call.complaint)
          ..toggle(M5LvLoadAppliance.fan)
          ..toggle(M5LvLoadAppliance.light)
          ..toggle(M5LvLoadAppliance.tv);
        expect(r.reading, greaterThanOrEqualTo(212), reason: '$k small loads');
        r.tapTerm(M5LvLoadTerm.e);
        expect(r.pair, {M5LvLoadTerm.n, M5LvLoadTerm.e}, reason: 'the lead put on first moves');
        if (k == M5LvLoadKind.weakNeutral) {
          expect(r.reading, inInclusiveRange(15, 22));
        } else {
          expect(r.reading, inInclusiveRange(1, 3), reason: 'clear of the 5–10 V threshold');
        }
        expect(r.neSeen, isTrue);
        r.supplyOn = false;
        expect(r.reading, 0);
      }
    });

    test('evidence-gated verdict: right without the loaded reading / without N–E = a slip (it stands); wrong = a slip (back)', () {
      final a = _runOf(M5LvLoadKind.loose);
      var p = a.pickVerdict(M5LvLoadVerdict.loose);
      expect(p.mistake, M5LvLoadMistakes.noLoad);
      expect(p.accepted, isTrue);
      expect(a.stage, M5LvLoadStage.method);

      final b = _runOf(M5LvLoadKind.loose)
        ..tapTerm(M5LvLoadTerm.p)
        ..tapTerm(M5LvLoadTerm.n)
        ..toggle(M5LvLoadAppliance.pump);
      expect(b.loaded, isTrue);
      expect(b.pickVerdict(M5LvLoadVerdict.loose).mistake, M5LvLoadMistakes.noNe);

      final c = _runOf(M5LvLoadKind.weakNeutral);
      _measure(c);
      p = c.pickVerdict(M5LvLoadVerdict.loose);
      expect((p.mistake, p.accepted), (M5LvLoadMistakes.wrongVerdict, false));
      expect(c.stage, M5LvLoadStage.measure);
      expect(c.pickVerdict(M5LvLoadVerdict.company).mistake, M5LvLoadMistakes.companyMyth);
      expect(c.pickVerdict(M5LvLoadVerdict.transformer).mistake, M5LvLoadMistakes.oneHouse);
      p = c.pickVerdict(M5LvLoadVerdict.weak);
      expect((p.mistake, p.accepted), (null, true));
      expect(c.slips, 3);
      expect(c.caught, containsAll([M5LvLoadLines.caughtLoad, M5LvLoadLines.caughtNe]));

      final g = _runOf(M5LvLoadKind.loadGrew);
      _measure(g);
      expect(g.pickVerdict(M5LvLoadVerdict.loadSkip).mistake, M5LvLoadMistakes.skipJoints);
      final i = _runOf(M5LvLoadKind.inside);
      _measure(i);
      expect(i.pickVerdict(M5LvLoadVerdict.loadSkip).mistake, M5LvLoadMistakes.wrongVerdict);
      p = i.pickVerdict(M5LvLoadVerdict.inside);
      expect((p.mistake, p.accepted), (null, true));
      expect(i.callDone, isTrue, reason: 'inside: no joints');
    });

    test('method: a plain tool on live joints / a bare-hand neutral = deadly; seal / neutral to earth = slips; right = supply off', () {
      for (final m in M5LvLoadLines.methodDeadly) {
        final r = _runOf(M5LvLoadKind.loose);
        _measure(r);
        r.pickVerdict(M5LvLoadVerdict.loose);
        final x = r.pickMethod(m)!;
        expect(x.deadly, isTrue, reason: '$m');
        expect(r.ended, isTrue);
      }
      final r = _runOf(M5LvLoadKind.loose);
      _measure(r);
      r.pickVerdict(M5LvLoadVerdict.loose);
      expect(r.pickMethod(M5LvLoadMethod.sealCut), M5LvLoadMistakes.sealCut);
      expect(r.pickMethod(M5LvLoadMethod.neutralEarth), M5LvLoadMistakes.neutralEarth);
      expect(r.stage, M5LvLoadStage.method);
      expect(r.pickMethod(M5LvLoadMethod.right), isNull);
      expect(r.supplyOn, isFalse);
      expect(r.stage, M5LvLoadStage.tighten);
      expect(r.red, isNull);
    });

    test('joints: হয়ে গেছে with one left = a slip; all four → supply back; the close needs the loaded re-measure', () {
      final r = _runOf(M5LvLoadKind.loose);
      _measure(r);
      r
        ..pickVerdict(M5LvLoadVerdict.loose)
        ..pickMethod(M5LvLoadMethod.right)
        ..tighten(M5LvLoadJoint.poleP)
        ..tapTerm(M5LvLoadTerm.p)
        ..tapTerm(M5LvLoadTerm.n);
      expect(r.tight, {M5LvLoadJoint.poleP, M5LvLoadJoint.meterP, M5LvLoadJoint.meterN});
      expect(r.doneTightening(), M5LvLoadMistakes.jointLeft);
      r.tighten(M5LvLoadJoint.poleN);
      expect(r.doneTightening(), isNull);
      expect(r.supplyOn, isTrue);
      expect(r.stage, M5LvLoadStage.remeasure);
      // Fixed: the needle holds under the load now.
      r
        ..tapTerm(M5LvLoadTerm.p)
        ..tapTerm(M5LvLoadTerm.n);
      expect(r.on, contains(M5LvLoadAppliance.pump));
      expect(r.reading, greaterThanOrEqualTo(220));
      expect(r.reLoaded, isTrue);
      expect(r.pickClose(M5LvLoadClose.report).mistake, M5LvLoadMistakes.wrongClose);
      final p = r.pickClose(M5LvLoadClose.fixed);
      expect((p.mistake, p.accepted), (null, true));
      expect(r.callDone, isTrue);

      final n = _runOf(M5LvLoadKind.loose);
      _measure(n);
      n
        ..pickVerdict(M5LvLoadVerdict.loose)
        ..pickMethod(M5LvLoadMethod.right);
      for (final j in M5LvLoadJoint.values) {
        n.tighten(j);
      }
      n.doneTightening();
      n.toggle(M5LvLoadAppliance.pump);
      n
        ..tapTerm(M5LvLoadTerm.p)
        ..tapTerm(M5LvLoadTerm.n);
      expect(n.reLoaded, isFalse, reason: 'the load was switched off');
      expect(n.pickClose(M5LvLoadClose.fixed).mistake, M5LvLoadMistakes.noRemeasure);
    });

    test('load grew: still sags after the joints; the report wants the customer asked; myths in the close are slips', () {
      final r = _runOf(M5LvLoadKind.loadGrew);
      _measure(r);
      r
        ..pickVerdict(M5LvLoadVerdict.loose)
        ..pickMethod(M5LvLoadMethod.right);
      for (final j in M5LvLoadJoint.values) {
        r.tighten(j);
      }
      r
        ..doneTightening()
        ..tapTerm(M5LvLoadTerm.p)
        ..tapTerm(M5LvLoadTerm.n);
      expect(r.reading, lessThanOrEqualTo(196), reason: 'still sags');
      expect(r.pickClose(M5LvLoadClose.fixed).mistake, M5LvLoadMistakes.wrongClose);
      expect(r.pickClose(M5LvLoadClose.company).mistake, M5LvLoadMistakes.companyMyth);
      expect(r.pickClose(M5LvLoadClose.lowOk).mistake, M5LvLoadMistakes.lowOk);
      expect(r.ask(), M5LvLoadLines.newOne(M5LvLoadAppliance.pump));
      final p = r.pickClose(M5LvLoadClose.report);
      expect((p.mistake, p.accepted), (null, true));
      expect(r.caught, contains(M5LvLoadLines.caughtReport));

      final n = _runOf(M5LvLoadKind.loadGrew);
      _measure(n);
      n
        ..pickVerdict(M5LvLoadVerdict.loose)
        ..pickMethod(M5LvLoadMethod.right);
      for (final j in M5LvLoadJoint.values) {
        n.tighten(j);
      }
      n
        ..doneTightening()
        ..tapTerm(M5LvLoadTerm.p)
        ..tapTerm(M5LvLoadTerm.n);
      expect(n.pickClose(M5LvLoadClose.report).mistake, M5LvLoadMistakes.askFirst);
      // The other calls' replies never name a new appliance.
      for (final k in [M5LvLoadKind.loose, M5LvLoadKind.weakNeutral, M5LvLoadKind.inside]) {
        expect(M5LvLoadLines.noneNew, contains(_runOf(k).ask()));
      }
    });

    test('the first P–N reading is noted (for the coworker), loaded or not; the next calls start clean', () {
      final r = _runOf(M5LvLoadKind.loose);
      expect(r.tapTerm(M5LvLoadTerm.p), isFalse);
      expect(r.tapTerm(M5LvLoadTerm.n), isTrue);
      expect(r.pnFirstLoaded, isFalse);
      expect(r.toggle(M5LvLoadAppliance.pump), isFalse, reason: 'only the first');
      final s = _runOf(M5LvLoadKind.loose)..toggle(M5LvLoadAppliance.pump);
      s.tapTerm(M5LvLoadTerm.n);
      expect(s.tapTerm(M5LvLoadTerm.p), isTrue);
      expect(s.pnFirstLoaded, isTrue);
      s
        ..passCoworker()
        ..stage = M5LvLoadStage.done
        ..next();
      expect(s.cwCall, 1, reason: 'the next service call');
      expect((s.red, s.black, s.loaded, s.neSeen, s.asked, s.on.isEmpty, s.supplyOn), (null, null, false, false, false, true, true));
      s
        ..passCoworker()
        ..stage = M5LvLoadStage.done;
      expect(s.cwCall, -1, reason: 'no service call left');
    });

    test('English digits; no পানি; the guide never says লোড; pictures exist; two deadly; keys unique', () {
      final all = <String>[
        ...M5LvLoadLines.spoken,
        ...M5LvLoadLines.allWhyRight,
        ...M5LvLoadLines.myths,
        ...M5LvLoadLines.allVerdicts,
        ...M5LvLoadLines.methodRight,
        ...M5LvLoadLines.methodWrong,
        ...M5LvLoadLines.allClose,
        for (final s in M5LvLoadLines.coworkerScripts) ...[...s.recordedLines, ...s.right, ...s.wrong],
        for (final m in M5LvLoadMistakes.all) m.textBn,
        ...M5LvLoadLines.calls,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।])পানি').hasMatch(l), isFalse, reason: l); // the locked word is জল (কোম্পানি is fine)
      }
      final guide = [
        for (final a in m5LvLoadComplaints) ...[M5LvLoadLines.intro(a), M5LvLoadLines.callStart(a)],
        ...M5LvLoadLines.tasks,
        ...M5LvLoadLines.whyQ.values,
        for (final s in M5LvLoadLines.coworkerScripts) ...s.asks,
        M5LvLoadLines.heldNoLoad,
        M5LvLoadLines.heldLowOk,
        M5LvLoadLines.allSet,
        M5LvLoadLines.fail,
      ];
      for (final l in guide) {
        expect(l.contains('লোড'), isFalse, reason: 'the guide gives no answer: $l');
      }
      expect(M5LvLoadMistakes.all.where((m) => m.deadly).toSet(), {M5LvLoadMistakes.liveSpanner, M5LvLoadMistakes.bareNeutral});
      expect(M5LvLoadMistakes.all.map((m) => m.key).toSet(), hasLength(M5LvLoadMistakes.all.length));
      for (final m in M5LvLoadMistakes.all) {
        expect(m.key, startsWith('5.5/m5_lv_load_test/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      // Every picture in the folder is used.
      final used = {for (final m in M5LvLoadMistakes.all) m.art.split('/').last};
      final files = Directory('assets/game/art/m5_lv_load_test').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m5LvLoadTestPacks.keys, ['do_5_5_b']);
    });

    test('libraries: one right of three, same length, big enough; every card maps to its rule', () {
      expectSameLength('why', [...M5LvLoadLines.allWhyRight, ...M5LvLoadLines.myths]);
      expect(M5LvLoadLines.myths.toSet().intersection(M5LvLoadLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5LvLoadWhy.values) {
        expectLibrary('why $w', M5LvLoadLines.whyRight[w]!, M5LvLoadLines.myths);
      }
      expectSameLength('verdict', M5LvLoadLines.allVerdicts);
      expectSameLength('method', [...M5LvLoadLines.methodRight, ...M5LvLoadLines.methodWrong]);
      expectSameLength('close', M5LvLoadLines.allClose);
      expectLibrary('method', M5LvLoadLines.methodRight, M5LvLoadLines.methodWrong);
      for (final k in M5LvLoadKind.values) {
        expectLibrary('verdict $k', M5LvLoadLines.verdictRight(k), M5LvLoadLines.verdictWrong(k));
        expectLibrary('close $k', M5LvLoadLines.closeRight(k), M5LvLoadLines.closeWrong(k));
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(M5LvLoadLines.verdictRight(k), M5LvLoadLines.verdictWrong(k), math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          for (final o in deal) {
            expect(M5LvLoadLines.verdictOf(o.textBn) == M5LvLoadLines.rightVerdict(k), o.correct, reason: o.textBn);
          }
        }
      }
      for (final t in M5LvLoadLines.allClose) {
        expect(M5LvLoadLines.closeText[M5LvLoadLines.closeOf(t)], contains(t));
      }
      for (final t in [...M5LvLoadLines.methodRight, ...M5LvLoadLines.methodWrong]) {
        expect(M5LvLoadLines.methodText[M5LvLoadLines.methodOf(t)], contains(t));
      }
      for (final s in M5LvLoadLines.coworkerScripts) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
      }
    });

    test('the flow seeds cover every kind of call, both reason moments', () {
      final calls = [for (final s in _flowSeeds) ...m5LvLoadDeal(math.Random(s)).calls];
      expect(calls.map((c) => c.kind).toSet(), M5LvLoadKind.values.toSet());
      expect(calls.any((c) => c.why == M5LvLoadWhy.joints), isTrue);
      expect(calls.any((c) => c.why != M5LvLoadWhy.joints && c.service), isTrue);
    });

    test('rival lines: his new pushes listed for recording; his exit is recorded', () {
      final pushes = {for (final s in M5LvLoadLines.coworkerScripts) s.line};
      expect(pushes, hasLength(4), reason: 'three no-load lines (one per appliance) + the low-voltage myth');
      expect(M5LvLoadLines.coworkerLowOk.line, 'একটু লো-ভোল্টেজ হলে কিছু হয় না, যন্ত্রপাতি তো চলছেই। চলো, পরের কলে যাই।');
      for (final a in m5LvLoadComplaints) {
        expect(M5LvLoadLines.coworkerNoLoad[a]!.line, contains(M5LvLoadLines.name(a)));
      }
      expect(LearnVoice.resolve(M5LvLoadLines.coworkerExit, rival: true), isNotNull);
    });

    test('tap areas do not overlap and stay on the 360-wide scene', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M5LvLoadGeo.forScene(h, 0);
        final rects = [
          for (final t in M5LvLoadTerm.values) g.termHit(t),
          g.jointHit(M5LvLoadJoint.poleP),
          g.jointHit(M5LvLoadJoint.poleN),
          g.doorHit,
          g.restHit(true),
          g.restHit(false),
        ];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(120), reason: 'below the header');
          expect(r.bottom, lessThan(h - 60), reason: 'above the switchboard');
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final x = rects[i].intersect(rects[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
        expect(g.tester.left, greaterThan(g.board.right), reason: 'h $h');
        // Clear of the corner guide's sprite (bottom left, up to x ≈ 213).
        for (final r in [g.restHit(true), g.restHit(false), g.doorHit, g.trainee, g.tester]) {
          expect(r.left > 214 || r.bottom < h - 190, isTrue, reason: 'h $h: $r');
        }
      }
    });

    test('the tightening hint shows how, never what: clear of every joint and control', () {
      for (final inset in [0.0, 34.0]) {
        for (final h in [640.0, 700.0, 780.0, 900.0]) {
          final g = M5LvLoadGeo.forScene(h, inset);
          final at = g.tightenHint;
          final keepOff = [
            for (final j in M5LvLoadJoint.values) g.jointHit(j).inflate(24),
            for (final t in M5LvLoadTerm.values) g.termHit(t).inflate(24),
            g.doorHit.inflate(24),
            g.restHit(true).inflate(24),
            g.restHit(false).inflate(24),
            g.tester.inflate(24),
            g.board.inflate(24),
          ];
          for (final r in keepOff) {
            expect(r.contains(at), isFalse, reason: 'h $h inset $inset: $at in $r');
          }
          expect(at.dx, inInclusiveRange(24, 336), reason: 'on the scene');
          expect(at.dy, greaterThan(120), reason: 'below the header');
          expect(at.dy, lessThan(g.houseTop - 24), reason: 'in the sky, above the house');
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

    testWidgets('the guide comes first: a tap does not skip him; then the switchboard', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final d = m5LvLoadDeal(math.Random(3));
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5LvLoadTestPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5LvLoadLines.verdictBtn), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5LvLoadLines.verdictBtn), findsOneWidget);
      for (final a in d.calls.first.switches) {
        expect(_label(M5LvLoadLines.name(a)), findsOneWidget);
      }
      expect(find.text('--- V'), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M5LvLoadLines.askMeasure)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in _flowSeeds) {
      testWidgets('flow (seed $seed): three calls measured under load, him refused, joints, re-measure; reasons → pass', (t) async {
        final deal = m5LvLoadDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (final (i, call) in deal.calls.indexed) {
          await _playCall(t, call, coworker: i == deal.cwCall);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.mistakes, isEmpty);
        expect(s.rungProgress['5.5/do/1'], 'cleared');
        expect(s.starsByRung['5.5/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5LvLoadLines.caughtCall), findsOneWidget);
        expect(find.text(M5LvLoadLines.caughtJoints), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the needle on the tester: P–N sags under the complaint in a service call', (t) async {
      // A seed whose first call is a service fault and not his call.
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
        final d = m5LvLoadDeal(math.Random(s));
        return d.calls.first.kind == M5LvLoadKind.loose && d.cwCall != 0 && d.calls.first.smallOn == null;
      });
      final call = m5LvLoadDeal(math.Random(seed)).calls.first;
      final c = await _open(t, seed);
      await _term(t, M5LvLoadTerm.p);
      await _term(t, M5LvLoadTerm.n);
      expect(find.text('${call.nominal} V'), findsOneWidget);
      await _button(t, M5LvLoadLines.name(call.complaint));
      expect(find.text('${call.nominal - call.depth} V'), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a slip (a wrong verdict) shows its card; back to the readings after it', (t) async {
      final c = await _open(t, 2);
      await _button(t, M5LvLoadLines.verdictBtn);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5LvLoadLines.allVerdicts.where((x) => !M5LvLoadLines.verdictRight(m5LvLoadDeal(math.Random(2)).calls.first.kind).contains(x)).toList());
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(_label(M5LvLoadLines.verdictBtn), findsOneWidget, reason: 'measuring again');
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      final right = M5LvLoadLines.verdictRight(m5LvLoadDeal(math.Random(2)).calls.first.kind);
      for (var i = 0; i < 3; i++) {
        await _button(t, M5LvLoadLines.verdictBtn);
        await waitChoiceDeck(t);
        final wrong = _onScreen(M5LvLoadLines.allVerdicts.where((x) => !right.contains(x)).toList());
        await t.tap(wrong.first, warnIfMissed: false);
        await confirmChoice(t);
        await _pump(t, 900);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a plain spanner / bare hand on the live joints: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
        final d = m5LvLoadDeal(math.Random(s));
        return d.calls.first.service && d.cwCall != 0;
      });
      final call = m5LvLoadDeal(math.Random(seed)).calls.first;
      final c = await _open(t, seed);
      await _term(t, M5LvLoadTerm.p);
      await _term(t, M5LvLoadTerm.n);
      await _button(t, M5LvLoadLines.name(call.complaint));
      await _term(t, M5LvLoadTerm.e);
      await _button(t, M5LvLoadLines.verdictBtn);
      await _pickRight(t, M5LvLoadLines.verdictRight(call.kind));
      await _pump(t, 400);
      if (call.why != M5LvLoadWhy.joints) await _reason(t, M5LvLoadLines.whyRight[call.why]!);
      await waitChoiceDeck(t);
      final deadly = _onScreen([for (final m in M5LvLoadLines.methodDeadly) ...M5LvLoadLines.methodText[m]!]);
      expect(deadly, hasLength(1), reason: 'one deadly-class card is always dealt');
      await t.tap(deadly.single, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.where((x) => x.deadly), hasLength(1));
      await _close(t, c);
    });

    testWidgets('a fast play: the next control waits for the coworker; listening is a slip and the call goes on', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m5LvLoadDeal(math.Random(s)).cwCall == 0);
      final call = m5LvLoadDeal(math.Random(seed)).calls.first;
      final c = await _open(t, seed);
      await _term(t, M5LvLoadTerm.p);
      await t.tapAt(_geo.termAt(M5LvLoadTerm.n) * _k);
      await t.pump(const Duration(milliseconds: 100));
      // At once on the switch: well inside his 1.2–2.4 s timer.
      await t.tap(_label(M5LvLoadLines.name(call.complaint)));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.text('${call.nominal - call.depth} V'), findsNothing, reason: 'the switch waited for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final listen = _onScreen(M5LvLoadLines.coworkerNoLoad[call.complaint]!.wrong);
      expect(listen, isNotEmpty);
      await t.tap(listen.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.text(M5LvLoadMistakes.listenNoLoad.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_label(M5LvLoadLines.verdictBtn), findsOneWidget, reason: 'the call goes on');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5LvLoadMistakes.listenNoLoad.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle while measuring → a doorway ripple or a probe lift; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 7);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while measuring');
      expect(scene().debugOptions, isEmpty, reason: 'a tap / drag, never a sweep over the switches');
      await _pump(t, 6000);
      await _button(t, M5LvLoadLines.verdictBtn);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own sweep');
      await _close(t, c);
    });
  });
}
