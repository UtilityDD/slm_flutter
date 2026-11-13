// Lesson 5.8 (ট্রান্সফরমারের সাধারণ সমস্যা), কাজ 1 "লক্ষণ থেকে কারণ": the
// rules (strike only what a test ruled out; the list closed only with the
// evidence in and every ruled-out cause struck; the verdict per case; a
// spanner on a live or untested bushing = deadly; a DO on load = slip), the
// deal, the libraries, the coworker's pushes, and the level in the shell:
// the guide first, a full clean play (a reason pick each case, the coworker
// refused), a slip card that keeps the case, three slips, the deadly freeze
// (spanner on live; listening to his deadly push), the next control waits
// for him on a fast play, the praise window takes no touch, and the gesture
// hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m5_cause_strike.dart';
import 'package:slm_flutter/features/game/m5_cause_strike_world.dart';
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
  rungId: '5.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5CauseStrikePacks['do_5_8_a']!;
typedef L = M5CauseStrikeLines;
typedef Mk = M5CauseStrikeMistakes;

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
M5CauseGeo get _geo => M5CauseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, M5Tool tool) async {
  await t.tap(_label(L.tool(tool)));
  await _pump(t, 300);
}

Future<void> _strike(WidgetTester t, M5Cause c) async {
  await t.drag(_label(L.cause(c)), const Offset(-100, 0));
  await _pump(t, 400);
}

Future<void> _swipeUp(WidgetTester t, Offset design) async {
  await t.dragFrom(design * _k, const Offset(0, -110));
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5CauseStrikePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M5CauseDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5CauseDeal(math.Random(s))));

/// The coworker comes (his case's gate reached): refuse him.
Future<void> _refuse(WidgetTester t, M5Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// 'তালিকা শেষ' → the right verdict card → the right reason.
Future<void> _close3(WidgetTester t, M5Case c, M5WhyTopic why) async {
  await t.tap(_label(L.listDone));
  await _pump(t, 500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'list closed (${c.kind})');
  await _pickRight(t, L.verdictRight[c.verdict]!);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  await _pickRight(t, L.whyRight[why]!);
  await _pump(t, 6000);
}

/// One case played right (the coworker refused if he is dealt on it).
Future<void> _playCase(WidgetTester t, M5CauseDeal d, int i) async {
  final c = d.cases[i];
  final him = d.coworkerCase == i ? d.push : null;
  final g = _geo;
  switch (c.kind) {
    case M5CaseKind.noise:
      await t.longPress(_label(L.tool(M5Tool.ear)));
      await _pump(t, 400);
      if (him == M5Push.hum) await _refuse(t, him!);
      if (c.loud) {
        await _tool(t, M5Tool.tong);
        await _tapAt(t, g.cableHit.center);
        await _strike(t, M5Cause.overload);
        // The load is normal: listen again (the noise has not stopped).
        await t.longPress(_label(L.tool(M5Tool.ear)));
        await _pump(t, 400);
      }
    case M5CaseKind.ltDead:
      await _tool(t, M5Tool.meter);
      for (var p = 0; p < 3; p++) {
        await _tapAt(t, g.terminalHit(p).center);
      }
      if (him == M5Push.live) await _refuse(t, him!);
      await _swipeUp(t, g.swipeFrom);
      await _strike(t, M5Cause.htFuse);
      await _tapAt(t, g.leverHit.center);
      await _tool(t, M5Tool.hotStick);
      for (var p = 0; p < 3; p++) {
        await _tapAt(t, g.doHit(p).center);
      }
      await _tool(t, M5Tool.tester);
      await _tapAt(t, g.bushingHit(c.deadPhase).center);
      expect(find.text(L.testerDead), findsOneWidget);
      await _tool(t, M5Tool.spanner);
      await _tapAt(t, g.bushingHit(c.deadPhase).center);
      expect(find.text(c.loose ? L.nutLoose : L.nutFirm), findsOneWidget);
      if (!c.loose) await _strike(t, M5Cause.bushingConn);
    case M5CaseKind.leak:
      await _swipeUp(t, g.stain(c.freshStain));
      if (him == M5Push.climb) await _refuse(t, him!);
      for (final x in m5CaseCauses[M5CaseKind.leak]!) {
        if (x != m5CauseOf(c.source)) await _strike(t, x);
      }
      await _tapAt(t, g.gaugeHit.center);
      await _tool(t, M5Tool.watch);
      await _pump(t, 5600);
      if (him == M5Push.small) await _refuse(t, him!);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${c.kind}');
  await _close3(t, c, d.why[i]);
}

M5Case _noise({bool loud = true}) => M5Case(kind: M5CaseKind.noise, place: M5Place.field, suspects: m5CaseCauses[M5CaseKind.noise]!, loud: loud);
M5Case _lt({bool loose = false, int dead = 1}) =>
    M5Case(kind: M5CaseKind.ltDead, place: M5Place.market, suspects: m5CaseCauses[M5CaseKind.ltDead]!, loose: loose, deadPhase: dead);
M5Case _leak({bool large = true, M5LeakSource src = M5LeakSource.weld, int fresh = 2}) =>
    M5Case(kind: M5CaseKind.leak, place: M5Place.school, suspects: m5CaseCauses[M5CaseKind.leak]!, large: large, source: src, freshStain: fresh);

M5CauseRun _runOf(M5Case first) => M5CauseRun(M5CauseDeal(
      cases: [first, if (first.kind != M5CaseKind.noise) _noise(), if (first.kind != M5CaseKind.ltDead) _lt(), if (first.kind != M5CaseKind.leak) _leak()],
      coworkerCase: 0,
      push: m5PushesFor(first).isEmpty ? M5Push.live : m5PushesFor(first).first,
      why: const [M5WhyTopic.report, M5WhyTopic.switchOff, M5WhyTopic.twoStruck],
    ));

void main() {
  group('rules', () {
    test('deals: one patient of each kind at three places; his push fits his case; the reason fits; plays differ', () {
      final seen = <String>{};
      final pushes = <M5Push>{};
      final whys = <M5WhyTopic>{};
      var loud = 0, loose = 0, large = 0;
      for (var s = 0; s < 120; s++) {
        final d = m5CauseDeal(math.Random(s));
        expect(d.cases.map((c) => c.kind).toSet(), M5CaseKind.values.toSet());
        expect(d.cases.map((c) => c.place).toSet(), hasLength(3));
        for (final c in d.cases) {
          expect(c.suspects.toSet(), m5CaseCauses[c.kind]!.toSet());
          expect(c.deadPhase, inInclusiveRange(0, 2));
          expect(c.freshStain, inInclusiveRange(0, 2));
          if (c.gaugeLow) expect(c.large, isTrue, reason: 'a low gauge only with a large leak');
        }
        expect(m5PushesFor(d.cases[d.coworkerCase]), contains(d.push));
        for (final (i, w) in d.why.indexed) {
          final c = d.cases[i];
          final fits = switch (c.kind) {
            M5CaseKind.noise => c.loud ? {M5WhyTopic.overload, M5WhyTopic.report} : {M5WhyTopic.hum},
            M5CaseKind.ltDead => {M5WhyTopic.switchOff, c.loose ? M5WhyTopic.tighten : M5WhyTopic.replace},
            M5CaseKind.leak => {M5WhyTopic.twoStruck, c.large ? M5WhyTopic.repair : M5WhyTopic.watch},
          };
          expect(fits, contains(w), reason: '${c.kind} $w');
        }
        pushes.add(d.push);
        whys.addAll(d.why);
        final n = d.cases.firstWhere((c) => c.kind == M5CaseKind.noise);
        final l = d.cases.firstWhere((c) => c.kind == M5CaseKind.ltDead);
        final k = d.cases.firstWhere((c) => c.kind == M5CaseKind.leak);
        if (n.loud) loud++;
        if (l.loose) loose++;
        if (k.large) large++;
        seen.add('${d.cases.map((c) => '${c.kind.name}${c.place.index}${c.suspects.first.index}').join()}|${n.loud}|${l.deadPhase}${l.loose}|'
            '${k.source.name}${k.freshStain}${k.large}${k.gaugeLow}|${d.coworkerCase}${d.push.name}');
      }
      expect(seen.length, greaterThan(100));
      expect(pushes, M5Push.values.toSet().difference({M5Push.humLate}), reason: 'humLate is never dealt');
      expect(whys, M5WhyTopic.values.toSet());
      for (final x in [loud, loose, large]) {
        expect(x, inInclusiveRange(30, 90));
      }
    });

    test('শব্দ (loud): listen → tong → strike ওভারলোড → listen again → list → report; every shortcut a slip', () {
      final r = _runOf(_noise());
      expect(r.strike(M5Cause.overload), Mk.strikeNoise, reason: 'no load check yet');
      expect(r.strike(M5Cause.windingShort), Mk.strikeNoise, reason: 'no test rules it out');
      expect(r.finishList(), Mk.evidenceNoise, reason: 'not even heard');
      r.listen();
      expect(r.finishList(), Mk.evidenceNoise, reason: 'internal verdict before the load check');
      expect(r.slips, 4);
      r.tong();
      expect(r.ruledOut, {M5Cause.overload});
      expect(r.strike(M5Cause.overload), isNull);
      expect(r.struck, {M5Cause.overload});
      expect(r.finishList(), Mk.evidenceNoise, reason: 'not heard again after the load check');
      r.listen();
      expect(r.heardAfterLoad, isTrue);
      expect(r.finishList(), isNull);
      expect(r.verdictUp, isTrue);
      expect(r.pickVerdict(false), Mk.verdictLoud);
      expect(r.pickVerdict(true), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtReport));
      expect(r.slips, 6);
      expect(r.kase.verdict, M5Verdict.report);
      // The list closed with ওভারলোড standing after all the tests.
      final o = _runOf(_noise())
        ..listen()
        ..tong()
        ..listen();
      expect(o.finishList(), Mk.openNoise, reason: 'ওভারলোড still standing');
    });

    test('শব্দ (hum): heard → the list closes with nothing struck → normal; reporting it is a slip', () {
      final r = _runOf(_noise(loud: false));
      r.listen();
      expect(r.finishList(), isNull);
      expect(r.pickVerdict(false), Mk.verdictHum);
      expect(r.pickVerdict(true), isNull);
      expect(r.kase.verdict, M5Verdict.normal);
      expect(r.caught, contains(L.caughtHum));
    });

    test('এক ফেজ: a spanner with the LT on or a DO closed is deadly; a DO on load is a slip', () {
      final a = _runOf(_lt());
      final m = a.spanner(1);
      expect(m, Mk.liveSpanner);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = _runOf(_lt());
      expect(b.openDo(0), Mk.doOnLoad);
      expect(b.doOpen[0], isFalse, reason: 'it stays in');
      for (var i = 0; i < 3; i++) {
        b.meter(i);
      }
      expect(b.lever(), isTrue);
      expect(b.openDo(0), isNull);
      expect(b.doOpen[0], isTrue);
      expect(b.spanner(1), Mk.liveSpanner, reason: 'two DOs still closed');
    });

    test('এক ফেজ: DOs open but no 0 V on that bushing = deadly (R2)', () {
      final r = _runOf(_lt());
      for (var i = 0; i < 3; i++) {
        r.meter(i);
      }
      r.lever();
      for (var i = 0; i < 3; i++) {
        r.openDo(i);
      }
      expect(r.test(0), isTrue);
      final m = r.spanner(1);
      expect(m, Mk.untested);
      expect(m!.deadly, isTrue);
    });

    test('এক ফেজ (firm): meter, look, switch off, test, spanner → strike both → replace', () {
      final r = _runOf(_lt());
      expect(r.strike(M5Cause.htFuse), Mk.strikeLt, reason: 'the DOs not looked at');
      for (var i = 0; i < 3; i++) {
        r.meter(i);
      }
      r.lookUp();
      expect(r.strike(M5Cause.htFuse), isNull);
      expect(r.finishList(), Mk.evidenceLt, reason: 'the bushing not checked');
      expect(r.test(1), isFalse, reason: 'the DOs still in: it reads live');
      r.lever();
      for (var i = 0; i < 3; i++) {
        r.openDo(i);
      }
      expect(r.test(1), isTrue);
      expect(r.spanner(1), isNull);
      expect(r.deadChecked, isTrue);
      expect(r.strike(M5Cause.ltWinding), Mk.strikeLt, reason: 'never ruled out');
      expect(r.finishList(), Mk.openLt);
      expect(r.strike(M5Cause.bushingConn), isNull);
      expect(r.finishList(), isNull);
      expect(r.pickVerdict(true), isNull);
      expect(r.kase.verdict, M5Verdict.replace);
      expect(r.caught, contains(L.caughtOff));
    });

    test('এক ফেজ (loose): the bushing connection is the cause — striking it is a slip; tighten', () {
      final r = _runOf(_lt(loose: true, dead: 2));
      for (var i = 0; i < 3; i++) {
        r.meter(i);
      }
      r
        ..lookUp()
        ..strike(M5Cause.htFuse)
        ..lever();
      for (var i = 0; i < 3; i++) {
        r.openDo(i);
      }
      r.test(0);
      expect(r.spanner(0), isNull);
      expect(r.deadChecked, isFalse, reason: 'a healthy phase is no check');
      r.test(2);
      r.spanner(2);
      expect(r.deadChecked, isTrue);
      expect(r.strike(M5Cause.bushingConn), Mk.strikeLt);
      expect(r.finishList(), isNull);
      expect(r.kase.verdict, M5Verdict.tighten);
    });

    test('এক ফেজ: the symptom is metered on the transformer as found — the lever waits; isolated, the dials read 0 and add nothing', () {
      final r = _runOf(_lt(dead: 0));
      expect(r.lever(), isFalse, reason: 'no phase metered yet');
      expect(r.ltOn, isTrue);
      r
        ..meter(0)
        ..meter(1);
      expect(r.lever(), isFalse, reason: 'two of three');
      r.meter(2);
      expect(r.lever(), isTrue);
      expect(r.asFound, isFalse);
      expect(m5PushGateReached(M5Push.live, r), isFalse, reason: 'never "tighten it live" on a switched-off transformer');
      // A dial reads the incoming side: live on healthy phases until every DO is open.
      M5CauseRig rig() => M5CauseRig(place: M5Place.market, doOpen: r.doOpen, ltOn: r.ltOn, meter: r.metered, deadPhase: 0);
      expect([for (var i = 0; i < 3; i++) m5DialLive(rig(), i)], [false, true, true], reason: 'LT off, DOs in');
      r
        ..openDo(0)
        ..openDo(1);
      expect([for (var i = 0; i < 3; i++) m5DialLive(rig(), i)], [false, true, true], reason: 'one DO still in (the tester agrees: live)');
      expect(r.test(1), isFalse);
      r.openDo(2);
      expect([for (var i = 0; i < 3; i++) m5DialLive(rig(), i)], [false, false, false], reason: 'every DO open: every dial 0');
      expect(r.test(1), isTrue);
      // A meter once isolated adds nothing to the evidence.
      final s = _runOf(_lt());
      s.meter(0);
      s.doOpen = [true, true, true];
      s
        ..meter(1)
        ..meter(2);
      expect(s.metered, {0}, reason: 'isolated, the meter tells nothing');
      expect(m5PushGateReached(M5Push.live, s), isFalse);
    });

    test('তেল: old stains lead nowhere; the fresh one rules out two causes; gauge and drip before the verdict', () {
      final r = _runOf(_leak(src: M5LeakSource.dent, fresh: 1));
      expect(r.trace(0), isFalse);
      expect(r.strike(M5Cause.gasket), Mk.strikeLeak);
      expect(r.trace(1), isTrue);
      expect(r.ruledOut, {M5Cause.gasket, M5Cause.weld});
      expect(r.strike(M5Cause.impact), Mk.strikeLeak, reason: 'the dent is the source');
      r.strike(M5Cause.gasket);
      expect(r.finishList(), Mk.evidenceLeak, reason: 'no gauge, no drip watch');
      r
        ..gauge()
        ..drip();
      expect(r.finishList(), Mk.openLeak);
      r.strike(M5Cause.weld);
      expect(r.finishList(), isNull);
      expect(r.pickVerdict(false), Mk.verdictLeak);
      expect(r.pickVerdict(true), isNull);
      expect(r.kase.verdict, M5Verdict.repair);
      final s = _runOf(_leak(large: false));
      expect(s.kase.verdict, M5Verdict.watch);
    });

    test('the coworker comes at his case\'s gate only', () {
      final r = _runOf(_lt());
      expect(m5PushGateReached(M5Push.live, r), isFalse);
      r
        ..meter(0)
        ..meter(1);
      expect(m5PushGateReached(M5Push.live, r), isFalse);
      r.meter(2);
      expect(m5PushGateReached(M5Push.live, r), isTrue);
      // "Hum" comes after the noise is heard and before the load test.
      final h = _runOf(_noise());
      expect(h.push, M5Push.hum);
      expect(m5PushGateReached(M5Push.hum, h), isFalse);
      h.listen();
      expect(m5PushGateReached(M5Push.hum, h), isTrue);
      h.tong();
      expect(h.push, M5Push.hum, reason: 'heard first: the dealt push stands');
      // The load checked before the noise was heard: "the load is fine, let
      // it run" after the second listen instead.
      final g = _runOf(_noise())..tong();
      expect(g.push, M5Push.humLate);
      expect(m5PushGateReached(M5Push.humLate, g), isFalse);
      g.listen();
      expect(m5PushGateReached(M5Push.humLate, g), isTrue);
      expect(m5PushGateReached(M5Push.hum, g), isFalse);
      expect(Mk.push(M5Push.humLate), Mk.pushReport);
      final k = _runOf(_leak());
      expect(m5PushGateReached(M5Push.climb, k), isFalse);
      k.trace(k.kase.freshStain);
      expect(m5PushGateReached(M5Push.climb, k), isTrue);
      expect(m5PushGateReached(M5Push.small, k), isFalse);
      k
        ..gauge()
        ..drip();
      expect(m5PushGateReached(M5Push.small, k), isTrue);
      expect(m5PushesFor(_noise(loud: false)), isEmpty, reason: 'he never says "hum" on a real hum');
      expect(m5PushesFor(_leak(large: false)), [M5Push.climb], reason: '"ও কিছু না" only on a large leak');
    });

    test('three slips and the play fails; a clean play passes', () {
      final r = _runOf(_noise());
      for (var i = 0; i < 3; i++) {
        r.finishList();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.listen();
      r.finishList();
      expect(r.percent, 40);
    });

    test('tool rows: the case\'s tools, the dead-phase row never in its working order; rows differ', () {
      expect(m5CauseInWorkOrder(const [M5Tool.meter, M5Tool.hotStick, M5Tool.tester, M5Tool.spanner]), isTrue);
      final rows = <String>{};
      for (var s = 0; s < 60; s++) {
        final rng = math.Random(s);
        final n = m5CauseToolRow(M5CaseKind.noise, rng);
        final l = m5CauseToolRow(M5CaseKind.ltDead, rng);
        final k = m5CauseToolRow(M5CaseKind.leak, rng);
        expect(n.toSet(), {M5Tool.ear, M5Tool.tong, M5Tool.meter});
        expect(l.toSet(), {M5Tool.meter, M5Tool.hotStick, M5Tool.tester, M5Tool.spanner});
        expect(k.toSet(), {M5Tool.watch, M5Tool.ear, M5Tool.tong});
        expect(m5CauseInWorkOrder(l), isFalse, reason: '$l');
        rows.add('${n.map((t) => t.name)}|${l.map((t) => t.name)}|${k.map((t) => t.name)}');
      }
      expect(rows.length, greaterThan(20));
    });

    test('English digits only; jol not pani; every mistake has its picture; three deadly; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        L.rule,
        ...L.tasks,
        L.oldStain,
        L.meterFirst,
        L.clipTitle,
        L.listDone,
        for (final k in M5CaseKind.values) ...[L.complaint(k), L.round(k)],
        for (final c in M5Cause.values) L.cause(c),
        for (final t in M5Tool.values) L.tool(t),
        ...L.allVerdicts,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M5Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.liveSpanner, Mk.untested, Mk.climbLive});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('5.8/m5_cause_strike/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      for (final k in M5CaseKind.values) {
        for (final m in [Mk.strikeEarly(k), Mk.listOpen(k), Mk.evidenceFirst(k)]) {
          expect(m.lessonPoint, m5LessonPoint(k), reason: m.key);
        }
      }
      for (final f in [m5HumSteady, m5HumLoud]) {
        expect(File('assets/$f').existsSync(), isTrue, reason: f);
      }
      // Every file in the art folder is used.
      final used = {for (final m in Mk.all) m.art.split('/').last, m5HumSteady.split('/').last, m5HumLoud.split('/').last};
      final files = Directory('assets/game/art/m5_cause_strike').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m5CauseStrikePacks.keys, ['do_5_8_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M5WhyTopic.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final v in M5Verdict.values) {
        final right = L.verdictRight[v]!;
        final wrong = L.verdictWrong(v);
        expectLibrary('verdict $v', right, wrong);
        expectSameLength('verdict $v', [...right, ...wrong]);
        expect(wrong.toSet().intersection(right.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his five new pushes are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      final pushes = {for (final p in M5Push.values) L.coworker(p).line};
      expect(pushes, hasLength(5));
      expect(pushes, {
        'লোড তো ঠিকই আছে, শব্দ-টব্দ চলতে দাও, রিপোর্টের দরকার নেই।',
        'চালু অবস্থাতেই বুশিং-এর নাটটা টাইট করে দাও, বন্ধ করার ঝামেলা কে করে?',
        'ওপরে উঠে আঙুল দিয়ে দেখো কোথা দিয়ে পড়ছে, বন্ধ করার দরকার নেই।',
        'সামান্য তেল পড়ছে, ও কিছু না — চলতে দাও।',
        'হামিং তো সব ট্রান্সফরমারই করে, চলতে দাও।',
      });
      for (final l in pushes) {
        // Not recorded yet (the director records them with tool/rival_clip.py):
        // until then the line is silent and its caption held.
        debugPrint('RIVAL m5_cause_strike: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, clear of the clipboard, the guide and the tool row', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5CauseGeo.forScene(h, 0);
        final rects = <Rect>[
          for (var i = 0; i < 3; i++) ...[g.doHit(i), g.bushingHit(i), g.terminalHit(i), g.stainHit(i)],
          g.gaugeHit,
          g.leverHit,
          g.cableHit,
        ];
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(125), reason: 'below the header');
          expect(r.bottom, lessThan(h - 95), reason: 'above the tool row');
          expect(r.overlaps(M5CauseGeo.clipboard), isFalse, reason: 'h $h: $r');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          // The guide's speech bubble (right side, above him) lets taps
          // through but hides what is under it: keep the targets clear of it.
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, g.groundY - 129, 360, g.groundY - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse, reason: 'h $h: $i/$j');
          }
        }
        expect(M5Clip.height(4), lessThanOrEqualTo(g.ltBox.top - M5CauseGeo.clipboard.top + 0.5), reason: 'h $h: the clipboard above the LT box');
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

    testWidgets('the guide comes first: a tap does not skip him; then the clipboard and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5CauseStrikePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m5CauseDeal(math.Random(3));
      expect(find.text(L.clipTitle), findsOneWidget);
      for (final c in d.cases.first.suspects) {
        expect(_label(L.cause(c)), findsOneWidget);
      }
      expect(_label(L.listDone), findsOneWidget);
      for (final tool in m5CauseToolRow(d.cases.first.kind, math.Random(1))) {
        expect(_label(L.tool(tool)), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final d = m5CauseDeal(math.Random(5));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.ask(d.cases.first.kind))), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with a deadly-class push (refused), one with a slip-class push.
    final flowSeeds = [
      _seedWhere((d) => d.push == M5Push.live && d.cases.any((c) => c.kind == M5CaseKind.noise && c.loud)),
      _seedWhere((d) => d.push == M5Push.small || d.push == M5Push.hum),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three patients, tests, strikes, verdicts, reasons; he is refused → pass', (t) async {
        final d = m5CauseDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playCase(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.8/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.8/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtStrike), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (the list closed with no test) shows its card; the same case goes on after it', (t) async {
      const seed = 2;
      final d = m5CauseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await t.tap(_label(L.listDone));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      final want = Mk.evidenceFirst(d.cases.first.kind);
      expect(find.text(want.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(L.cause(d.cases.first.suspects.first)), findsOneWidget, reason: 'the same case');
      expect(c.read(gameSaveProvider).mistakes.single.key, want.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a cause struck with no test is a slip: the row stays standing', (t) async {
      const seed = 4;
      final d = m5CauseDeal(math.Random(seed));
      final c = await _open(t, seed);
      final cause = d.cases.first.suspects.first;
      await _strike(t, cause);
      expect(find.text(Mk.strikeEarly(d.cases.first.kind).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.strikeEarly(d.cases.first.kind).key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await t.tap(_label(L.listDone));
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

    final ltFirst = _seedWhere((d) => d.cases.first.kind == M5CaseKind.ltDead);
    testWidgets('a spanner on the live bushing: the scene freezes first, then the card (near-miss)', (t) async {
      final d = m5CauseDeal(math.Random(ltFirst));
      final c = await _open(t, ltFirst);
      await _tool(t, M5Tool.spanner);
      await _tapAt(t, _geo.bushingHit(d.cases.first.deadPhase).center);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.liveSpanner.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final ltFirstAlone = _seedWhere((d) => d.cases.first.kind == M5CaseKind.ltDead && d.coworkerCase != 0);
    testWidgets('the lever before the meter: no slip, the guide asks for the phases first; metered, it switches off', (t) async {
      final c = await _open(t, ltFirstAlone);
      await _tapAt(t, _geo.leverHit.center);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.meterFirst));
      // Still ON: a DO opened now is on load.
      await _tool(t, M5Tool.hotStick);
      await _tapAt(t, _geo.doHit(0).center);
      expect(find.text(Mk.doOnLoad.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tool(t, M5Tool.meter);
      for (var p = 0; p < 3; p++) {
        await _tapAt(t, _geo.terminalHit(p).center);
      }
      await _tapAt(t, _geo.leverHit.center);
      await _tool(t, M5Tool.hotStick);
      await _tapAt(t, _geo.doHit(0).center);
      expect(find.byType(MistakeCard), findsNothing, reason: 'switched off: the DO opens');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.doOnLoad.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final liveFirst = _seedWhere((d) => d.cases.first.kind == M5CaseKind.ltDead && d.coworkerCase == 0);
    testWidgets('listening to "tighten it live" = deadly: freeze, then the card', (t) async {
      final c = await _open(t, liveFirst);
      await _tool(t, M5Tool.meter);
      for (var p = 0; p < 3; p++) {
        await _tapAt(t, _geo.terminalHit(p).center);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerLive.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.liveSpanner.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: the next control waits for the coworker; he cuts in at once', (t) async {
      final c = await _open(t, liveFirst);
      await _tool(t, M5Tool.meter);
      for (var p = 0; p < 3; p++) {
        await t.tapAt(_geo.terminalHit(p).center * _k);
        await t.pump(const Duration(milliseconds: 60));
      }
      // At once, well inside his 1.2–2.4 s timer: the swipe up the structure.
      await t.dragFrom(_geo.swipeFrom * _k, const Offset(0, -110));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerLive.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      // The swipe that waited did nothing: the HT fuse is not ruled out yet.
      await _strike(t, M5Cause.htFuse);
      expect(find.text(Mk.strikeLt.textBn), findsOneWidget);
      await _close(t, c);
    });

    final humFirst = _seedWhere((d) => d.cases.first.kind == M5CaseKind.noise && d.coworkerCase == 0 && d.push == M5Push.hum);
    testWidgets('the load checked before the noise is heard: he comes after the second listen with "the load is fine"', (t) async {
      final c = await _open(t, humFirst);
      await _tool(t, M5Tool.tong);
      await _tapAt(t, _geo.cableHit.center);
      await _strike(t, M5Cause.overload);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not before the noise is heard');
      await t.longPress(_label(L.tool(M5Tool.ear)));
      await _pump(t, 400);
      await _refuse(t, M5Push.humLate);
      await t.tap(_label(L.listDone));
      await _pump(t, 500);
      await _pickRight(t, L.verdictRight[M5Verdict.report]!);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final noiseFirst = _seedWhere((d) => d.cases.first.kind == M5CaseKind.noise && d.coworkerCase != 0);
    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m5CauseDeal(math.Random(noiseFirst));
      final c = await _open(t, noiseFirst);
      final first = d.cases.first;
      await t.longPress(_label(L.tool(M5Tool.ear)));
      await _pump(t, 400);
      if (first.loud) {
        await _tool(t, M5Tool.tong);
        await _tapAt(t, _geo.cableHit.center);
        await _strike(t, M5Cause.overload);
        await t.longPress(_label(L.tool(M5Tool.ear)));
        await _pump(t, 400);
      }
      await t.tap(_label(L.listDone));
      await _pump(t, 500);
      await _pickRight(t, L.verdictRight[first.verdict]!);
      // The ◆ wait on the table: the list and its rows take nothing.
      for (var k = 0; k < 4; k++) {
        await t.tap(_label(L.listDone), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, L.whyRight[d.why[0]]!);
      await _pump(t, 3000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: the ear\'s hold ring first; three taps on nothing show the hand; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m5CauseDeal(math.Random(noiseFirst));
      final c = await _open(t, noiseFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the ear not heard yet');
      expect(scene().debugOptions, isEmpty, reason: 'a hold, not a pick');
      await t.longPress(_label(L.tool(M5Tool.ear)));
      await _pump(t, 400);
      expect(scene().showing, isFalse);
      // Three taps on nothing (the sky over the tank) while waiting show the hand at once.
      final empty = Offset(119, _geo.y(0.3)) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      // The verdict cards up: the scene's hand stays away (the deck has its own).
      final first = d.cases.first;
      if (first.loud) {
        await _tool(t, M5Tool.tong);
        await _tapAt(t, _geo.cableHit.center);
        await _strike(t, M5Cause.overload);
        await t.longPress(_label(L.tool(M5Tool.ear)));
        await _pump(t, 400);
      }
      await t.tap(_label(L.listDone));
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse);
      await _close(t, c);
    });

    testWidgets('gesture hand in the dead-phase case: a sweep over every tool alike', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, ltFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, hasLength(4), reason: 'all four tools');
      expect(scene().debugFrame?.ripple, isNull);
      await _close(t, c);
    });
  });
}
