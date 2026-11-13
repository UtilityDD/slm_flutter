// Lesson 1.9 (ঝড়-বৃষ্টিতে কাজ), কাজ 1 "আকাশ পড়ুন": the weather rules (rain at
// general maintenance vs an emergency repair with waterproof gloves, wind
// above 40–50 km/h, lightning = the red line), the deal, reason libraries that
// fit the moment's weather, his recorded lines, and the level in the shell:
// idle perf, the guide first, a full clean play (spot the signs, the phone,
// the gloves, the decision, the reasons, the coworker refused), a needless
// stop that is final, caps the stars at 1 and takes 5 off the mark (the guide
// says the rule in the past tense as he comes down), taps that all look the
// same, the deadly freeze (working on in lightning, also on his say-so),
// listening in the wind = a slip, three slips strike out, a fast stop on his
// moment waits for him while a fast "work on" is the call itself (deadly in
// lightning, a slip in wind, no coworker), reason decks where a wrong card
// names the weather too, and the gesture hint.
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
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/sky_read.dart';
import 'package:slm_flutter/features/game/sky_world.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '1.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.9',
  lessonTitleBn: '',
  ladderStep: 26,
  doIndex: 1,
  doCount: 2,
);

final _pack = skyReadPacks['do_1_9_a']!;

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
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  // A right reason zooms and waits for এগিয়ে যান; his deck just closes.
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen (the scene fits it).
const _k = 392 / 360;
SkyGeo get _geo => SkyGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => SkyReadPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 2600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Plays moment [i] right: on his moment he comes, is refused, and the
/// trainee comes down; otherwise spot every sign, check the phone, gloves
/// when needed, and decide. Then the reason.
Future<void> _playRight(WidgetTester t, SkyDeal deal, int i) async {
  final c = deal.cases[i];
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on moment $i');
    await waitChoiceDeck(t);
    await _pickRight(t, SkyLines.coworker.right);
    await _pump(t, 2600);
  } else {
    for (final s in c.signs) {
      final r = s == SkySign.wind ? skyTreesRect(_geo) : skySignRect(s, _geo, c.bolt);
      await t.tapAt(_screen(r.center));
      await _pump(t, 300);
    }
    await t.tap(_label(SkyLines.phone));
    await _pump(t, 500);
    expect(find.text(SkyLines.kmh(c.windKmh)), findsOneWidget);
    await t.tap(_label(SkyLines.phoneClose));
    await _pump(t, 400);
    if (c.needsGloves) {
      await t.tap(_label(SkyLines.gloves));
      await _pump(t, 300);
    }
    await t.tap(find.text(c.mustStop ? SkyLines.stop : SkyLines.go));
    await _pump(t, 2600);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'moment $i');
  await waitChoiceDeck(t);
  await _pickRight(t, SkyLines.whyRight(c));
  await _pump(t, i == 3 ? 7000 : 6500);
}

void main() {
  group('rules', () {
    test('deals: four moments, lightning 3rd or 4th, a strong wind, a moment to work on; he comes where the work must stop', () {
      final seen = <String>{};
      final kinds = <SkyKind>{};
      final calls = <SkyKind>{};
      for (var s = 0; s < 80; s++) {
        final d = dealSky(math.Random(s));
        expect(d.cases.length, 4);
        final bolts = [
          for (final (i, c) in d.cases.indexed)
            if (c.bolt != SkyBolt.none) i,
        ];
        expect(bolts, hasLength(1));
        expect(bolts.single, inInclusiveRange(2, 3));
        expect(d.cases.where((c) => c.kind == SkyKind.wind), isNotEmpty);
        expect(d.cases.where((c) => !c.mustStop), isNotEmpty, reason: 'always stopping must not win');
        expect(d.cases[d.callAt].mustStop, isTrue);
        calls.add(d.cases[d.callAt].kind);
        for (final c in d.cases) {
          kinds.add(c.kind);
          // Never the grey zone between the readings.
          expect(c.windKmh > 25 && c.windKmh < 45, isFalse);
          expect(c.windy, c.kind == SkyKind.wind);
          if (c.kind == SkyKind.rainJob) expect(c.job, SkyJob.maintenance);
          if (c.kind == SkyKind.rainUrgent) expect(c.job, SkyJob.emergency);
        }
        seen.add(d.cases.map((c) => '${c.kind.name}${c.job.name}${c.windKmh}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(kinds, containsAll(SkyKind.values));
      expect(calls, containsAll([SkyKind.wind, SkyKind.boltFar, SkyKind.boltNear]));
    });

    SkyCase sky(SkyKind k, {SkyJob job = SkyJob.maintenance, int wind = 15}) => SkyCase(id: 'x', kind: k, job: job, windKmh: wind);
    SkyRun run1(SkyCase c) => SkyRun(SkyDeal(cases: [c], callAt: 0));

    test('lightning (far or near, any job): working on is deadly; stopping is right', () {
      for (final k in [SkyKind.boltFar, SkyKind.boltNear]) {
        for (final job in SkyJob.values) {
          final c = sky(k, job: job);
          expect(c.hazard, SkyHazard.bolt);
          final a = run1(c)..check(SkyCheck.phone)..check(SkyCheck.gloves);
          final m = a.decide(stop: false);
          expect(m, SkyMistakes.stayBolt);
          expect(m!.deadly, isTrue);
          expect(a.ended, isTrue);
          final b = run1(c);
          expect(b.decide(stop: false, pushed: true)!.deadly, isTrue, reason: 'on his say-so too');
          final ok = run1(c);
          expect(ok.decide(stop: true), isNull);
          expect(ok.caught, contains(SkyLines.caughtBolt));
          if (k == SkyKind.boltFar) expect(ok.caught, contains(SkyLines.caughtFar));
        }
      }
    });

    test('wind at 45 km/h and above (in doubt, stop): working on is a slip; rain at general maintenance: a slip', () {
      for (final w in [45, 50, 65]) {
        final a = run1(sky(SkyKind.wind, wind: w, job: SkyJob.emergency))..check(SkyCheck.phone);
        expect(a.decide(stop: false), SkyMistakes.stayWind);
        expect(a.slips, 1);
        expect(a.shown, isTrue);
        expect(a.deadly, isNull);
      }
      final r = run1(sky(SkyKind.rainJob))..check(SkyCheck.phone)..check(SkyCheck.gloves);
      expect(r.decide(stop: false), SkyMistakes.stayRain);
      expect(r.slips, 1);
      final ok = run1(sky(SkyKind.rainJob));
      expect(ok.decide(stop: true), isNull);
      expect(ok.caught, contains(SkyLines.caughtRain));
    });

    test('working on: only after checking the weather; an emergency in the rain only with waterproof gloves', () {
      final a = run1(sky(SkyKind.calm));
      expect(a.decide(stop: false), SkyMistakes.unchecked);
      final b = run1(sky(SkyKind.calm))..check(SkyCheck.phone);
      expect(b.decide(stop: false), isNull);
      expect(b.caught, contains(SkyLines.caughtGo));
      final urgent = sky(SkyKind.rainUrgent, job: SkyJob.emergency);
      expect(urgent.mustStop, isFalse);
      expect(urgent.needsGloves, isTrue);
      final c = run1(urgent)..check(SkyCheck.phone);
      expect(c.decide(stop: false), SkyMistakes.noGloves);
      final d = run1(urgent)
        ..check(SkyCheck.phone)
        ..check(SkyCheck.gloves);
      expect(d.decide(stop: false), isNull);
      expect(d.caught, contains(SkyLines.caughtGloves));
    });

    test('a needless stop is final and no slip, but it is counted (stars capped at 1, mark less 5): no second try at the moment', () {
      final a = run1(sky(SkyKind.calm));
      expect(a.decide(stop: true), isNull);
      expect(a.shown, isTrue, reason: 'the stop is final');
      expect(a.slips, 0);
      expect(a.needless, 1);
      expect(a.caught, isEmpty, reason: 'nothing caught for a needless stop');
      // Decided: pressing "work on" now does nothing (no free retry).
      a.check(SkyCheck.phone);
      expect(a.decide(stop: false), isNull);
      expect(a.needless, 1);
      expect(a.caught, isEmpty);
      final b = run1(sky(SkyKind.rainUrgent, job: SkyJob.emergency));
      expect(b.decide(stop: true), isNull);
      expect(b.decide(stop: true), isNull);
      expect(b.needless, 1, reason: 'one stop per moment');
      expect(b.percent, 100, reason: 'no slip: stopping is the worker\'s right');
      expect(b.mark, 95, reason: 'but the recorded mark is not full');
      expect(SkyLines.needless(sky(SkyKind.calm)), SkyLines.needlessCalm);
      expect(SkyLines.needless(sky(SkyKind.rainUrgent, job: SkyJob.emergency)), SkyLines.needlessUrgent);
    });

    test('spotting: only the signs really there count; thorough = every sign + the phone', () {
      final c = sky(SkyKind.boltNear, job: SkyJob.emergency);
      expect(c.signs, {SkySign.wet, SkySign.bolt});
      final r = run1(c);
      expect(r.spot([SkySign.wind]), isEmpty);
      expect(r.spot([SkySign.bolt, SkySign.wind]), {SkySign.bolt});
      r.check(SkyCheck.phone);
      expect(r.thorough, isFalse);
      r.spot([SkySign.wet]);
      expect(r.thorough, isTrue);
      expect(r.misses, 1, reason: 'the wind tap found nothing');
      final calm = run1(sky(SkyKind.calm))..check(SkyCheck.phone);
      expect(calm.thorough, isTrue, reason: 'nothing to spot in a calm sky');
      // Tapping all over the scene is not reading it.
      final spam = run1(sky(SkyKind.wind, wind: 55))..check(SkyCheck.phone);
      spam
        ..spot([SkySign.bolt])
        ..spot([])
        ..spot([SkySign.wind, SkySign.wet]);
      expect(spam.spotted, {SkySign.wind});
      expect(spam.thorough, isFalse);
    });

    test('the sign areas sit where the art draws them', () {
      final g = _geo;
      expect(skySignRect(SkySign.wet, g, SkyBolt.none).contains(Offset(SkyGeo.cx, (g.topY + g.groundY) / 2)), isTrue);
      expect(skySignRect(SkySign.wind, g, SkyBolt.none).contains(g.pins[2]), isTrue);
      expect(skySignRect(SkySign.bolt, g, SkyBolt.far).contains(Offset(290, g.horizonY - 60)), isTrue);
      expect(gallopOf(55), greaterThan(gallopOf(20) * 5));
    });

    test('the lesson\'s numbers, English digits only; every mistake has its picture and a lesson point (0–2)', () {
      final all = <String>[
        SkyLines.intro,
        ...SkyLines.tasks,
        ...SkyLines.rainJobWhy,
        ...SkyLines.wetWhy,
        ...SkyLines.windWhy,
        ...SkyLines.allBoltWhy,
        ...SkyLines.goCalmWhy,
        ...SkyLines.goRainWhy,
        ...SkyLines.goMyths,
        ...SkyLines.stopExcuses,
        ...SkyLines.boltFalse,
        ...SkyLines.windFalse,
        ...SkyLines.rainJobFalse,
        SkyLines.cloudFalse,
        SkyLines.needlessCalm,
        SkyLines.needlessUrgent,
        ...SkyLines.coworker.recordedLines,
        ...SkyLines.coworker.right,
        ...SkyLines.coworker.wrong,
        ...SkyLines.coworker.asks,
        for (final m in SkyMistakes.all) m.textBn,
        SkyLines.kmh(55),
        SkyLines.allSet,
        SkyLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(SkyLines.windWhy.first, contains('40–50 km/h'));
      expect(SkyMistakes.stayWind.textBn, contains('40–50 km/h'));
      expect(SkyMistakes.all.where((m) => m.deadly), [SkyMistakes.stayBolt]);
      // The pro-tip card has no lesson point (it is not in the wind section).
      expect(SkyMistakes.unchecked.lessonPoint, isNull);
      for (final m in SkyMistakes.all) {
        if (m != SkyMistakes.unchecked) expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(m.key, startsWith('1.9/sky/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(SkyMistakes.stayBolt.lessonPoint, 1);
      expect(SkyMistakes.stayWind.lessonPoint, 2);
      expect(SkyMistakes.stayRain.lessonPoint, 0);
    });

    test('quick bonus ≈ 85 % of a thorough play: 80 s', () {
      expect(_pack.quickMs, 80000);
      expect(skyReadPacks.keys, ['do_1_9_a']);
    });

    test('reasons fit the moment, same length, big enough; his lines are recorded', () {
      final every = <String>{
        ...SkyLines.rainJobWhy,
        ...SkyLines.wetWhy,
        ...SkyLines.windWhy,
        ...SkyLines.allBoltWhy,
        ...SkyLines.goCalmWhy,
        ...SkyLines.goRainWhy,
        ...SkyLines.goMyths,
        ...SkyLines.stopExcuses,
        ...SkyLines.boltFalse,
        ...SkyLines.windFalse,
        ...SkyLines.rainJobFalse,
        SkyLines.cloudFalse,
      }.toList();
      expectSameLength('why', every, ratio: 1.25);
      final samples = [
        for (final s in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) ...dealSky(math.Random(s)).cases,
      ];
      for (final k in SkyKind.values) {
        expect(samples.where((c) => c.kind == k), isNotEmpty, reason: '$k');
      }
      for (final c in samples) {
        final right = SkyLines.whyRight(c);
        final wrong = SkyLines.whyWrong(c);
        expectLibrary('${c.kind}', right, wrong);
        for (final w in wrong) {
          expect(right, isNot(contains(w)));
        }
        // A wrong card is never a true lesson rule.
        final rules = {...SkyLines.rainJobWhy, ...SkyLines.wetWhy, ...SkyLines.windWhy, ...SkyLines.allBoltWhy, ...SkyLines.goCalmWhy, ...SkyLines.goRainWhy};
        expect(wrong.toSet().intersection(rules), isEmpty, reason: '${c.kind}');
        if (c.mustStop) {
          expect(wrong, containsAll([...SkyLines.falseStopRules(c.hazard!), SkyLines.cloudFalse, ...SkyLines.stopExcuses]));
        } else {
          expect(wrong, SkyLines.goMyths);
        }
        if (c.bolt == SkyBolt.far) expect(right, contains(SkyLines.boltFarWhy));
        if (c.bolt == SkyBolt.near) expect(right, contains(SkyLines.boltNearWhy));
        for (var s = 0; s < 10; s++) {
          final deal = SkyLines.deal(c, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
          expect(right, contains(deal.firstWhere((o) => o.correct).textBn));
          for (final o in deal.where((o) => !o.correct)) {
            expect(wrong, contains(o.textBn));
          }
          // After a stop the weather word is no tell: one wrong card always
          // states a false rule about this very weather.
          if (c.mustStop) {
            final rules = SkyLines.falseStopRules(c.hazard!);
            expect(deal.where((o) => !o.correct && rules.contains(o.textBn)), isNotEmpty, reason: '${c.kind}');
          }
        }
      }
      final cw = SkyLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      for (final l in cw.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
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
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: SkyReadPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
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
        debugPrint('PERF sky_read ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('a stormy moment waits quietly too (rain, wind or lightning)', (t) async {
      // A deal that opens on a stop moment he is not dealt to.
      var seed = 0;
      while (true) {
        final d = dealSky(math.Random(seed));
        if (d.cases[0].signs.isNotEmpty && d.callAt != 0) break;
        seed++;
      }
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: SkyReadPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await waitIntro(t);
      await _pump(t, 14000);
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      var seed = 2;
      while (dealSky(math.Random(seed)).callAt == 0) {
        seed++;
      }
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: SkyReadPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(SkyLines.stop), findsNothing);
      await waitIntro(t);
      await _pump(t, 2600);
      expect(find.text(SkyLines.stop), findsOneWidget);
      expect(find.text(SkyLines.jobBn(dealSky(math.Random(seed)).cases[0].job)), findsOneWidget, reason: 'the docket');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      var seed = 0;
      while (dealSky(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(SkyLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: read the sky each moment, refuse him, right call and reason each time → pass', (t) async {
      // A deal with an emergency in the rain (the gloves) and him on lightning or wind.
      var seed = 1;
      while (!dealSky(math.Random(seed)).cases.any((c) => c.needsGloves)) {
        seed++;
      }
      final deal = dealSky(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 4; i++) {
        await _playRight(t, deal, i);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.9/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.9/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(SkyLines.caughtCall), findsOneWidget);
      expect(find.text(SkyLines.caughtGloves), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a needless stop is final and caps the stars at 1: no card, no ◆, the rule in the past tense as he comes down', (t) async {
      var seed = 0;
      while (true) {
        final d = dealSky(math.Random(seed));
        if (!d.cases.first.mustStop && d.callAt != 0) break;
        seed++;
      }
      final deal = dealSky(math.Random(seed));
      final c = await _open(t, seed);
      expect(c.read(guideDirectorProvider).line, isNot(SkyLines.needless(deal.cases.first)));
      await t.tap(find.text(SkyLines.stop));
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(StruckOutCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no ◆ on the table');
      expect(find.text(SkyLines.stop), findsNothing, reason: 'the stop is final: no second try');
      expect(find.text(SkyLines.go), findsNothing);
      expect(c.read(guideDirectorProvider).line, SkyLines.needless(deal.cases.first));
      // The next job comes by itself.
      await _pump(t, 4500);
      expect(find.text(SkyLines.stop), findsOneWidget);
      for (var i = 1; i < 4; i++) {
        await _playRight(t, deal, i);
      }
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty, reason: 'no slip');
      expect(s.rungProgress['1.9/do/0'], 'cleared');
      expect(s.starsByRung['1.9/do/0'], 1, reason: 'a needless stop caps the stars at 1');
      expect(find.byType(LevelPassPanel), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      var seed = 0;
      late SkyDeal deal;
      while (true) {
        deal = dealSky(math.Random(seed));
        if (deal.cases[3].bolt != SkyBolt.none && deal.callAt == 3) break;
        seed++;
      }
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        // Work on without even checking the weather: a slip whatever the sky.
        await t.tap(find.text(SkyLines.go));
        await _pump(t, 600);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'moment $i is no lightning');
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget, reason: 'slip ${i + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 2800);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.9/do/0'], isNot('cleared'));
      expect(s.mistakes.where((m) => m.deadly), isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    /// Opens with reduced motion (the weather turns at once) and returns right
    /// after the guide's intro, before he would come by himself (1.2–2.4 s).
    Future<ProviderContainer> openFast(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: SkyReadPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      return c;
    }

    Future<void> closeFast(WidgetTester t, ProviderContainer c) async {
      await _close(t, c);
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    }

    testWidgets('a fast stop on his moment waits for him: he comes before the trainee comes down', (t) async {
      var seed = 0;
      while (dealSky(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = dealSky(math.Random(seed));
      final c = await openFast(t, seed);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not here yet');
      await t.tap(find.text(SkyLines.stop));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the press brings him in now');
      expect(find.text(SkyLines.whyStop), findsNothing, reason: 'no reason deck before he has spoken');
      await waitChoiceDeck(t);
      await _pickRight(t, SkyLines.coworker.right);
      await _pump(t, 2600);
      await waitChoiceDeck(t);
      expect(find.text(SkyLines.whyStop), findsWidgets);
      await _pickRight(t, SkyLines.whyRight(deal.cases[0]));
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await closeFast(t, c);
    });

    testWidgets('a fast "work on" on his lightning moment is the call: the deadly freeze, no coworker', (t) async {
      var seed = 0;
      while (true) {
        final d = dealSky(math.Random(seed));
        if (d.callAt == 2 && d.cases[2].bolt != SkyBolt.none && !d.cases[0].mustStop && !d.cases[1].mustStop) break;
        seed++;
        expect(seed, lessThan(5000));
      }
      final c = await openFast(t, seed);
      // Two calm moments first: stop needlessly (fast, final), on to moment 3.
      for (var i = 0; i < 2; i++) {
        expect(await _pumpUntil(t, find.text(SkyLines.stop)), isTrue, reason: 'moment $i');
        await t.tap(find.text(SkyLines.stop));
        await _pump(t, 300);
        expect(find.text(SkyLines.stop), findsNothing, reason: 'the stop is final');
      }
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not here yet');
      expect(await _pumpUntil(t, find.text(SkyLines.go)), isTrue);
      await t.tap(find.text(SkyLines.go));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsNothing, reason: '"work on" is never held for him');
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'working on in lightning is deadly');
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his moment has passed');
      await closeFast(t, c);
    });

    testWidgets('a fast "work on" on his wind moment is a slip with no coworker', (t) async {
      var seed = 0;
      while (true) {
        final d = dealSky(math.Random(seed));
        if (d.callAt == 0 && d.cases[0].kind == SkyKind.wind) break;
        seed++;
      }
      // Pressed fast: the press is the call (a slip), he never comes.
      final c = await openFast(t, seed);
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(find.text(SkyLines.go));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsNothing, reason: '"work on" is never held for him');
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, SkyMistakes.stayWind.key);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his moment has passed');
      await closeFast(t, c);
    });

    testWidgets('a stop on his wind moment brings him in; listening to him there is a slip, not deadly', (t) async {
      var seed = 0;
      while (true) {
        final d = dealSky(math.Random(seed));
        if (d.callAt == 0 && d.cases[0].kind == SkyKind.wind) break;
        seed++;
      }
      final c = await openFast(t, seed);
      await t.tap(find.text(SkyLines.stop));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await waitChoiceDeck(t);
      final wrong = _onScreen(SkyLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, SkyMistakes.stayWind.key);
      expect(s.mistakes.single.deadly, isFalse);
      await closeFast(t, c);
    });

    testWidgets('gesture hint: the hand shows after idle on a waiting moment and on the open phone, never in the intro', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      var seed = 0;
      while (dealSky(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final hand = find.byKey(const ValueKey('gesture-hint'));
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: SkyReadPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
      ));
      for (var i = 0; i < 20 && find.byType(GuideIntro).evaluate().isNotEmpty; i++) {
        await t.pump(const Duration(milliseconds: 500));
        expect(hand, findsNothing, reason: 'no hand during the guide\'s intro');
      }
      await waitIntro(t);
      await _pump(t, 2600);
      expect(hand, findsNothing);
      await _pump(t, 9000);
      expect(hand, findsOneWidget, reason: 'a stuck player gets the sweep');
      await t.tap(_label(SkyLines.phone));
      await _pump(t, 300);
      expect(hand, findsNothing, reason: 'a touch hides it');
      await _pump(t, 9000);
      expect(hand, findsOneWidget, reason: 'the open phone: tap to put it away');
      await t.tap(_label(SkyLines.phoneClose));
      await _pump(t, 300);
      expect(hand, findsNothing);
      await _close(t, c);
    });

    testWidgets('a tap on the scene looks the same, sign or not; the real signs are named after the reason', (t) async {
      var seed = 0;
      late SkyDeal deal;
      while (true) {
        deal = dealSky(math.Random(seed));
        if (deal.callAt != 0 && deal.cases[0].kind == SkyKind.wind) break;
        seed++;
      }
      final c = await _open(t, seed);
      final sky0 = deal.cases[0];
      // A sign (the bent trees) and a spot with no sign (the field, left of the pole).
      await t.tapAt(_screen(skyTreesRect(_geo).center));
      await _pump(t, 400);
      await t.tapAt(_screen(Offset(30, _geo.horizonY - 100)));
      await _pump(t, 400);
      bool keyed(Widget w, String p) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(p);
      final marks = find.byWidgetPredicate((w) => keyed(w, 'tap-'));
      expect(marks, findsNWidgets(2));
      expect(find.byWidgetPredicate((w) => keyed(w, 'ring-')), findsNothing);
      expect(find.text(SkyLines.signBn(SkySign.wind, sky0)), findsNothing);
      await t.tap(_label(SkyLines.phone));
      await _pump(t, 500);
      await t.tap(_label(SkyLines.phoneClose));
      await _pump(t, 400);
      await t.tap(find.text(SkyLines.stop));
      await _pump(t, 2600);
      await waitChoiceDeck(t);
      expect(marks, findsNothing, reason: 'the marks go with the decision');
      await _pickRight(t, SkyLines.whyRight(sky0));
      expect(await _pumpUntil(t, find.text(SkyLines.signBn(SkySign.wind, sky0)), maxMs: 3000), isTrue);
      await _close(t, c);
    });

    testWidgets('working on in lightning: the scene freezes first, then the card (near-miss)', (t) async {
      var seed = 0;
      late SkyDeal deal;
      late int bolt;
      while (true) {
        deal = dealSky(math.Random(seed));
        bolt = deal.cases.indexWhere((c) => c.bolt != SkyBolt.none);
        if (deal.callAt < bolt) break;
        seed++;
      }
      final c = await _open(t, seed);
      for (var i = 0; i < bolt; i++) {
        await _playRight(t, deal, i);
      }
      await t.tap(find.text(SkyLines.go));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, SkyMistakes.stayBolt.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him in lightning = deadly: freeze, then the card', (t) async {
      var seed = 0;
      late SkyDeal deal;
      while (true) {
        deal = dealSky(math.Random(seed));
        if (deal.cases[deal.callAt].bolt != SkyBolt.none) break;
        seed++;
      }
      final c = await _open(t, seed);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(SkyLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('pressing stop on his moment: he cuts in before the trainee comes down', (t) async {
      var seed = 0;
      while (dealSky(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final c = await _open(t, seed);
      // He may already be on his way; if the buttons are still up, press stop.
      if (find.byType(CoworkerPeek).evaluate().isEmpty && find.text(SkyLines.stop).evaluate().isNotEmpty) {
        await t.tap(find.text(SkyLines.stop));
        await _pump(t, 200);
        expect(find.byType(ChoiceDeck), findsNothing, reason: 'no reason deck before he has spoken');
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      await _pickRight(t, SkyLines.coworker.right);
      await _pump(t, 2600);
      expect(find.text(SkyLines.whyStop), findsWidgets);
      await _close(t, c);
    });
  });
}
