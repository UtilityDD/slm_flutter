// Lesson 2.10, কাজ (দিনের শেষে): rules of the bench (wipe → inspect → care →
// its place, or the tag), the deal, fair reason libraries that fit the tool,
// the coworker's choices, and the level in the shell (idle perf; guide first;
// a full clean flow; a slip card; three slips; the deadly freeze; the
// coworker's deadly push).
import 'dart:async';
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
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_tool_care.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.10',
  lessonTitleBn: '',
  ladderStep: 30,
  doIndex: 1,
  doCount: 1,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seed(bool Function(CareDeal d) ok) {
  for (var s = 0;; s++) {
    if (ok(dealCare(math.Random(s)))) return s;
  }
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
}

const _pliersWet = CareTool(id: 'a', kind: CareKind.pliers, need: CareNeed.wet);
const _spannerRust = CareTool(id: 'b', kind: CareKind.spanner, need: CareNeed.rusty);
const _meter = CareTool(id: 'c', kind: CareKind.meter, need: CareNeed.meter);
const _crimperLeak = CareTool(id: 'd', kind: CareKind.crimper, flaw: CareFlaw.leak);
const _pliersCrack = CareTool(id: 'e', kind: CareKind.pliers, flaw: CareFlaw.crack);
const _driver = CareTool(id: 'f', kind: CareKind.screwdriver);

CareRun _runOf(List<CareTool> tools) => CareRun(CareDeal(tools: tools, callRound: 0));

void main() {
  group('rules', () {
    test('every deal: pliers + spanner + two more, one or two damaged, one needing more than a wipe', () {
      for (var s = 0; s < 100; s++) {
        final d = dealCare(math.Random(s));
        expect(d.tools.length, 4);
        final kinds = d.tools.map((t) => t.kind).toSet();
        expect(kinds.length, 4);
        expect(kinds, containsAll([CareKind.pliers, CareKind.spanner]));
        final flawed = d.tools.where((t) => t.flawed).length;
        expect(flawed, inInclusiveRange(1, 2));
        for (final t in d.tools) {
          expect(t.kind == CareKind.meter, t.need == CareNeed.meter);
          if (t.kind == CareKind.meter) expect(t.flawed, isFalse);
          if (t.flawed) expect(t.need, CareNeed.plain);
          if (t.need == CareNeed.rusty) expect(t.kind, CareKind.spanner);
          if (t.flaw == CareFlaw.crack) expect(t.kind, anyOf(CareKind.pliers, CareKind.screwdriver), reason: 'only insulated grips crack');
        }
        expect(d.tools.any((t) => t.need == CareNeed.wet || t.need == CareNeed.rusty), isTrue);
        expect(d.callRound, inInclusiveRange(0, 3));
        expect(d.tools.map((t) => t.id).toSet().length, 4);
      }
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 80; s++) dealCare(math.Random(s))];
      expect(deals.map((d) => d.tools.first.kind).toSet().length, 5);
      expect({for (final d in deals) for (final t in d.tools) t.flaw}, containsAll(CareFlaw.values));
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2, 3});
      expect(deals.map((d) => d.tools.where((t) => t.flawed).length).toSet(), {1, 2});
    });

    test('a clean play: dry, de-rust then oil, meter off and coiled, the leaking crimper tagged', () {
      final run = _runOf([_pliersWet, _spannerRust, _meter, _crimperLeak]);
      // Wet pliers: half a wipe is clean of dirt but still damp.
      run.wipe(0.7);
      expect(run.dirt, 0);
      expect(run.wet, greaterThan(0));
      run.wipe(0.3);
      expect(run.wet, 0);
      expect(run.store().verdict, CareVerdict.right);
      expect(run.shown, isTrue);
      expect(run.store().verdict, CareVerdict.none, reason: 'nothing more on a decided tool');
      run.next();
      // Rusty spanner: brush, then a drop of oil, then its place.
      run.wipe(1);
      run.brush(1);
      expect(run.rust, 0);
      expect(run.oilAt(CareZones.metalSpot(CareKind.spanner)).verdict, CareVerdict.ok);
      expect(run.store().verdict, CareVerdict.right);
      run.next();
      run.wipe(1);
      expect(run.dialOff().verdict, CareVerdict.ok);
      expect(run.coilLeads().verdict, CareVerdict.ok);
      expect(run.store().verdict, CareVerdict.right);
      run.next();
      expect(run.retire().verdict, CareVerdict.right);
      expect(run.retiredNow, isTrue);
      run.next();
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.stored, {'a', 'b', 'c'});
      expect(run.retired, {'d'});
      expect(run.caught, containsAll([CareLines.caughtDry, CareLines.caughtRust, CareLines.caughtMeter, CareLines.caughtRetire]));
    });

    test('putting away too soon: wet, dirty, rust left, no oil, meter on, leads twisted are slips', () {
      final wet = _runOf([_pliersWet]);
      wet.wipe(0.65);
      expect(wet.store().mistake, CareMistakes.wet);
      final dirty = _runOf([_driver]);
      expect(dirty.store().mistake, CareMistakes.dirty);
      final rust = _runOf([_spannerRust])..wipe(1);
      expect(rust.store().mistake, CareMistakes.rustLeft);
      rust.brush(1);
      expect(rust.store().mistake, CareMistakes.noOil);
      final meter = _runOf([_meter])..wipe(1);
      expect(meter.store().mistake, CareMistakes.meterOn);
      meter.dialOff();
      expect(meter.store().mistake, CareMistakes.leadsTwisted);
      meter.coilLeads();
      expect(meter.store().verdict, CareVerdict.right);
      expect(rust.slips, 2);
      expect(rust.ended, isFalse);
    });

    test('oil: on the metal only, after the rust, a thin coat; never on the meter', () {
      final r = _runOf([_spannerRust])..wipe(1);
      expect(r.oilAt(CareZones.metalSpot(CareKind.spanner)).mistake, CareMistakes.oilOnRust);
      r.brush(1);
      for (var i = 0; i < kCareMaxOil; i++) {
        expect(r.oilAt(CareZones.metalSpot(CareKind.spanner)).verdict, CareVerdict.ok);
      }
      expect(r.oilAt(CareZones.metalSpot(CareKind.spanner)).mistake, CareMistakes.overOil);
      expect(r.oil.length, kCareMaxOil);
      final p = _runOf([_pliersWet]);
      expect(p.oilAt(CareZones.insulationSpot).mistake, CareMistakes.oilInsulation);
      expect(p.oilAt(CareZones.metalSpot(CareKind.pliers)).verdict, CareVerdict.ok, reason: 'the joint takes oil');
      final m = _runOf([_meter]);
      expect(m.oilAt(CareZones.metalSpot(CareKind.meter)).mistake, CareMistakes.oilMeter);
    });

    test('faults: hidden under the grime until wiped; kept = slip (a cracked grip is deadly); a good tool retired = slip', () {
      final leak = _runOf([_crimperLeak]);
      expect(leak.flawShows, isFalse);
      expect(leak.wipe(0.3), isFalse);
      expect(leak.wipe(0.3), isTrue, reason: 'the leak comes into view');
      expect(leak.wipe(0.3), isFalse, reason: 'only once');
      expect(leak.store().mistake, CareMistakes.leakKept);
      expect(leak.ended, isFalse);
      expect(leak.retire().verdict, CareVerdict.right);

      for (final f in [CareFlaw.bent, CareFlaw.widened]) {
        final k = f == CareFlaw.bent ? CareKind.screwdriver : CareKind.spanner;
        final r = _runOf([CareTool(id: 'x', kind: k, flaw: f)]);
        expect(r.store().mistake, CareMistakes.kept(f));
      }

      final crack = _runOf([_pliersCrack])..wipe(1);
      final o = crack.store();
      expect(o.verdict, CareVerdict.deadly);
      expect(o.mistake, CareMistakes.crackKept);
      expect(crack.ended, isTrue);

      final good = _runOf([_driver]);
      expect(good.retire().mistake, CareMistakes.goodRetired);
      expect(good.slips, 1);
    });

    test('the coworker pushes what fits the tool; listening is a slip, or deadly on a cracked grip', () {
      expect(_runOf([_pliersCrack]).push, CarePush.crack);
      final r = _runOf([_spannerRust]);
      expect(r.push, CarePush.grease);
      r.brush(1);
      expect(r.push, CarePush.toss, reason: 'rust gone: no grease push');
      expect(_runOf([_meter]).push, CarePush.toss);
      final a = _runOf([_driver]);
      expect(a.listen(CarePush.toss).mistake, CareMistakes.skipCare);
      expect(a.listen(CarePush.grease).mistake, CareMistakes.overOil);
      expect(a.slips, 2);
      final b = _runOf([_pliersCrack]);
      expect(b.listen(CarePush.crack).verdict, CareVerdict.deadly);
      expect(b.deadly, CareMistakes.crackKept);
    });

    test('the tool\'s space maps both ways', () {
      const s = Size(276, 124);
      for (final p in const [Offset(0, 0), Offset(84, 82), Offset(300, 120)]) {
        final back = careToolPoint(s, careLocalPoint(s, p));
        expect((back - p).distance, lessThan(0.01));
      }
      expect(CareZones.onDial(CareZones.dial), isTrue);
      expect(CareZones.onLeads(CareZones.leadsSpot), isTrue);
      expect(CareZones.onInsulation(CareKind.pliers, CareZones.insulationSpot), isTrue);
      expect(CareZones.onInsulation(CareKind.screwdriver, CareZones.insulationSpot), isTrue);
      for (final k in CareKind.values) {
        expect(CareZones.onInsulation(k, CareZones.metalSpot(k)), isFalse);
      }
    });

    test('reason and choice libraries: same length, big enough, fit the tool', () {
      expectSameLength('store', [for (final n in CareNeed.values) ...CareLines.storeRight(n), ...CareLines.storeMyths]);
      for (final n in CareNeed.values) {
        expectLibrary('store ${n.name}', CareLines.storeRight(n), CareLines.storeWrong(n));
      }
      const faults = [CareFlaw.crack, CareFlaw.bent, CareFlaw.widened, CareFlaw.leak];
      expectSameLength('retire', [for (final f in faults) ...CareLines.retireRight(f), ...CareLines.retireExcuses]);
      for (final f in faults) {
        expectLibrary('retire ${f.name}', CareLines.retireRight(f), CareLines.retireWrong(f));
        for (final r in CareLines.retireRight(f)) {
          expect(CareLines.retireWrong(f), isNot(contains(r)));
        }
      }
      for (final p in CarePush.values) {
        final c = CareLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
      }
      expect(CareMistakes.all.where((m) => m.deadly), [CareMistakes.crackKept]);
      expect(CareMistakes.all.map((m) => m.key).toSet().length, CareMistakes.all.length);
      expect(m2ToolCarePacks.keys, ['do_2_10_a']);
      expect(CareLines.recordLines, isNotEmpty);
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

    Future<(ProviderContainer, CareDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealCare(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2ToolCarePage(ctx: _ctx, pack: m2ToolCarePack210, muted: true, seed: seed),
      )));
      await _pump(t, 1500);
      await waitIntro(t);
      return (c, deal);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    Future<void> chip(WidgetTester t, int i) async {
      await t.tap(_label(CareLines.kit[i]), warnIfMissed: false);
      await _pump(t, 200);
    }

    Rect toolRect(WidgetTester t) => t.getRect(_label(CareLines.toolLabel).last);

    Future<void> tapTool(WidgetTester t, Offset p) async {
      final r = toolRect(t);
      await t.tapAt(r.topLeft + careLocalPoint(r.size, p));
      await _pump(t, 250);
    }

    /// Four strokes across the tool with what is in hand.
    Future<void> rub(WidgetTester t) async {
      final r = toolRect(t);
      for (final y in [0.3, 0.45, 0.6, 0.75]) {
        final g = await t.startGesture(Offset(r.left + 8, r.top + r.height * y));
        for (var i = 1; i <= 20; i++) {
          await g.moveTo(Offset(r.left + 8 + (r.width - 16) * i / 20, r.top + r.height * y));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await t.pump(const Duration(milliseconds: 60));
      }
    }

    /// The whole right care of [tool]; returns the right reasons for its deck.
    Future<List<String>> care(WidgetTester t, CareTool tool) async {
      await chip(t, 0);
      await rub(t);
      if (tool.flawed) {
        await chip(t, 3);
        await tapTool(t, const Offset(150, 60));
        return CareLines.retireRight(tool.flaw);
      }
      if (tool.need == CareNeed.rusty) {
        await chip(t, 1);
        await rub(t);
        await chip(t, 2);
        await tapTool(t, CareZones.metalSpot(tool.kind));
      }
      if (tool.need == CareNeed.meter) {
        await tapTool(t, CareZones.dial);
        await tapTool(t, CareZones.leadsSpot);
      }
      await t.tap(find.text(CareLines.store));
      return CareLines.storeRight(tool.need);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the bench (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2ToolCarePage(ctx: _ctx, pack: m2ToolCarePack210, muted: true, seed: _seed((d) => d.callRound >= 1))),
        ));
        await t.pump(const Duration(milliseconds: 100));
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
        debugPrint('PERF tool care ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(find.text(CareLines.store), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('guide first: no start button, a tap does not skip; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: M2ToolCarePage(ctx: _ctx, pack: m2ToolCarePack210, muted: true, seed: _seed((d) => d.callRound == 3))),
      ));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(360, 800));
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      final guide = t.getRect(find.byType(AiLinemanGuide).last);
      final heard = <String>{};
      for (var i = 0; i < 3; i++) {
        await t.tapAt(guide.bottomRight - const Offset(50, 50));
        await _pump(t, 200);
        final line = c.read(guideDirectorProvider).line;
        expect(line, contains(CareLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, care for every tool (tag the damaged), reasons → pass', (t) async {
      final seed = _seed((d) => d.callRound == 0 && d.tools.first.flaw != CareFlaw.crack && d.tools.any((x) => x.need == CareNeed.rusty) && d.tools.any((x) => x.kind == CareKind.meter));
      final (c, deal) = await open(t, seed);

      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [for (final p in CarePush.values) ...CareLines.coworker(p).right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      for (final tool in deal.tools) {
        final right = await care(t, tool);
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${tool.kind} ${tool.flaw} ${tool.need}');
        await _pickRight(t, right);
        await _pump(t, 3500);
      }
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.10/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.10/do/0'], greaterThan(0));
      expect(find.text(CareLines.caughtCall), findsOneWidget);
      expect(find.text(CareLines.caughtRust), findsOneWidget);
      expect(find.text(CareLines.caughtRetire), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: putting a dirty tool away is a slip card; three slips fail the level', (t) async {
      final (c, _) = await open(t, _seed((d) => d.callRound == 3 && !d.tools.first.flawed));
      await t.tap(find.text(CareLines.store));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      // A sound tool tagged: slip two.
      await chip(t, 3);
      await tapTool(t, const Offset(150, 60));
      await _pump(t, 400);
      expect(find.text(CareMistakes.goodRetired.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      await tapTool(t, const Offset(150, 60));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.10/do/0'), isTrue);
      expect(s.rungProgress['2.10/do/0'], isNot('cleared'));
      expect(s.mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('deadly: a cracked grip put away freezes the scene first, then the card', (t) async {
      final (c, _) = await open(t, _seed((d) => d.callRound >= 1 && d.tools.first.flaw == CareFlaw.crack));
      await chip(t, 0);
      await rub(t);
      await t.tap(find.text(CareLines.store));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(CareMistakes.crackKept.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to "একটু ফাটা তো" is deadly (freeze, then the card)', (t) async {
      final (c, _) = await open(t, _seed((d) => d.callRound == 0 && d.tools.first.flaw == CareFlaw.crack));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(CareLines.coworkerCrack.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      expect(find.text(CareMistakes.crackKept.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
