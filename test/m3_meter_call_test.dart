// Lesson 3.8 (সার্ভিস কেবিল ও এনার্জি মিটার), কাজ 2 "গ্রাহকের ডাক": the rules
// (look at the four spots and find the fault; the flicker call: supply OFF +
// insulated tool on the loose terminal; the fast meter: explain politely, keep
// the seal; the burnt call: the LT line's neutral, shutdown first, never a
// bare hand), the deal, the libraries, and the level in the shell: idle perf,
// the guide first, tapping the guide, a full clean play (the coworker
// refused), a slip card (acting before looking), and the deadly freeze (a
// plain tool on the live terminals).
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_meter_call.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3MeterCallPacks['do_3_8_b']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_meter_call/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
    }
    return rootBundle.load(key);
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
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3MeterCallGeo get _geo => M3MeterCallGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _look(WidgetTester t, M3MeterCallSpot s) async {
  await t.tapAt(_geo.spotHit(s).center * _k);
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
    builder: (_) => M3MeterCallPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Plays call [i] right: the coworker refused on his call, every spot looked
/// at, then the job (flicker: supply OFF, insulated tool, the loose
/// terminal) or the right action; then the reason.
Future<void> _playRight(WidgetTester t, M3MeterCallDeal deal, int i) async {
  final c = deal.cases[i];
  var first = true;
  for (final s in M3MeterCallSpot.values) {
    await _look(t, s);
    if (first && i == deal.callAt) {
      first = false;
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, (c.kind == M3MeterCallKind.burnt ? M3MeterCallLines.coworkerNeutral : M3MeterCallLines.coworkerSeal).right);
      await _pump(t, 2500);
    }
  }
  if (c.kind == M3MeterCallKind.flicker) {
    await t.tap(_label(M3MeterCallLines.supplyOn));
    await _pump(t, 200);
    await t.tap(_label(M3MeterCallLines.insulated));
    await _pump(t, 200);
    await t.tapAt(_geo.terminal(c.loose) * _k);
    await _pump(t, 1500);
  } else {
    await t.tap(find.text(M3MeterCallLines.decide));
    await _pump(t, 900);
    await _pickRight(t, M3MeterCallLines.actRight(c));
    await _pump(t, 1500);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'call $i ${c.kind}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'call $i');
  await _pump(t, 700);
  await _pickRight(t, M3MeterCallLines.whyRight(c));
  await _pump(t, 4000);
}

void main() {
  group('rules', () {
    test('deals: one call of each kind, fresh; the coworker never on the flicker call', () {
      final seen = <String>{};
      final calls = <int>{};
      for (var s = 0; s < 80; s++) {
        final d = dealM3MeterCall(math.Random(s));
        expect(d.cases.length, 3);
        expect(d.cases.map((c) => c.kind).toSet(), M3MeterCallKind.values.toSet());
        expect(d.cases.map((c) => c.look).toSet().length, 3);
        expect(d.cases[d.callAt].kind, isNot(M3MeterCallKind.flicker));
        calls.add(d.callAt);
        seen.add(d.cases.map((c) => '${c.kind.name}${c.loose.name}${c.cause.name}${c.breakRight}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(calls, {0, 1, 2});
    });

    M3MeterCallRun run1(M3MeterCallCase c) => M3MeterCallRun(M3MeterCallDeal(cases: [c], callAt: 0));
    const flicker = M3MeterCallCase(id: 'x', kind: M3MeterCallKind.flicker, loose: M3MeterCallTerm.nIn);
    const fast = M3MeterCallCase(id: 'x', kind: M3MeterCallKind.fastMeter, cause: M3MeterCallCause.leak);
    const burnt = M3MeterCallCase(id: 'x', kind: M3MeterCallKind.burnt);

    test('the fault: flicker → meter, fast meter → house, burnt → the LT line; looks show it', () {
      expect(flicker.fault, M3MeterCallSpot.meter);
      expect(fast.fault, M3MeterCallSpot.house);
      expect(burnt.fault, M3MeterCallSpot.line);
      final a = run1(burnt);
      expect(a.found, isFalse);
      expect(a.inspect(M3MeterCallSpot.cable), contains('অক্ষত'));
      expect(a.inspect(M3MeterCallSpot.line), contains('নিউট্রাল কাটা'));
      expect(a.found, isTrue);
      expect(run1(fast).inspect(M3MeterCallSpot.house), contains('লিকেজ'));
      expect(run1(fast).inspect(M3MeterCallSpot.meter), contains('সিল অক্ষত'));
    });

    test('flicker: the terminals answer only after the meter was looked at; the others are tight; a tool is needed', () {
      final a = run1(flicker);
      expect(a.tapTerminal(M3MeterCallTerm.nIn), isNull);
      a.inspect(M3MeterCallSpot.meter);
      expect(a.tapTerminal(M3MeterCallTerm.pIn), M3MeterCallTap.tight);
      expect(a.tapTerminal(M3MeterCallTerm.nIn), M3MeterCallTap.needTool);
      expect(a.shown, isFalse);
      a
        ..toggleSupply()
        ..pickTool(M3MeterCallTool.insulated);
      expect(a.tapTerminal(M3MeterCallTerm.nIn), M3MeterCallTap.fixed);
      expect(a.fixed, isTrue);
      expect(a.caught, containsAll([M3MeterCallLines.caughtLoose, M3MeterCallLines.caughtSafeTool]));
    });

    test('flicker: a plain tool on the live panel is deadly; a plain tool switched off, or supply ON, is a slip', () {
      final a = run1(flicker)
        ..inspect(M3MeterCallSpot.meter)
        ..pickTool(M3MeterCallTool.plain);
      expect(a.tapTerminal(M3MeterCallTerm.nIn), M3MeterCallTap.mistake);
      expect(a.mistake, M3MeterCallMistakes.livePlainTool);
      expect(a.ended, isTrue);
      final b = run1(flicker)
        ..inspect(M3MeterCallSpot.meter)
        ..toggleSupply()
        ..pickTool(M3MeterCallTool.plain);
      b.tapTerminal(M3MeterCallTerm.nIn);
      expect(b.mistake, M3MeterCallMistakes.plainTool);
      expect(b.slips, 1);
      final c = run1(flicker)
        ..inspect(M3MeterCallSpot.meter)
        ..pickTool(M3MeterCallTool.insulated);
      c.tapTerminal(M3MeterCallTerm.nIn);
      expect(c.mistake, M3MeterCallMistakes.supplyOn);
      expect(c.slips, 1);
      expect(c.deadly, isNull);
    });

    test('the deck: right after looking; right before finding = slip; each wrong books its mistake; bare hand = deadly', () {
      final a = run1(fast)..inspect(M3MeterCallSpot.house);
      expect(a.choose(M3MeterCallLines.fastLeak.first), isNull);
      expect(a.caught, containsAll([M3MeterCallLines.caughtLoad, M3MeterCallLines.caughtPolite]));
      final b = run1(fast)..inspect(M3MeterCallSpot.meter);
      expect(b.choose(M3MeterCallLines.fastLeak.last), M3MeterCallMistakes.noLook);
      expect(b.slips, 1);
      expect(run1(fast).choose(M3MeterCallLines.fastNewMeter), M3MeterCallMistakes.meterBlamed);
      expect(run1(fast).choose(M3MeterCallLines.fastSeal), M3MeterCallMistakes.sealCut);
      expect(run1(fast).choose(M3MeterCallLines.fastScold), M3MeterCallMistakes.rude);
      expect(run1(burnt).choose(M3MeterCallLines.burntDrop), M3MeterCallMistakes.dropNeutral);
      expect(run1(burnt).choose(M3MeterCallLines.burntMeter), M3MeterCallMistakes.neutralMissed);
      final d = run1(burnt);
      expect(d.choose(M3MeterCallLines.burntBare), M3MeterCallMistakes.bareNeutral);
      expect(d.deadly, M3MeterCallMistakes.bareNeutral);
      expect(d.slips, 0);
      final ok = run1(burnt)..inspect(M3MeterCallSpot.line);
      expect(ok.choose(M3MeterCallLines.burntRight.last), isNull);
      expect(ok.caught, contains(M3MeterCallLines.caughtNeutral));
      // The fridge call's right options are not the leak's.
      const fridge = M3MeterCallCase(id: 'x', kind: M3MeterCallKind.fastMeter);
      expect(M3MeterCallLines.actRight(fridge), M3MeterCallLines.fastFridge);
    });

    test('listening to him: the seal cut (slip) on the fast meter; a bare hand (deadly) on the burnt call', () {
      final a = run1(fast);
      expect(a.listen(), M3MeterCallMistakes.sealCut);
      expect(a.slips, 1);
      final b = run1(burnt);
      expect(b.listen(), M3MeterCallMistakes.bareNeutral);
      expect(b.ended, isTrue);
    });

    test('every spot looked at = thorough (+5)', () {
      final a = run1(burnt);
      for (final s in M3MeterCallSpot.values) {
        a.inspect(s);
      }
      expect(a.thorough, isTrue);
    });

    test('three slips fail the level (percent below 55 after a 4th; 55 after 3)', () {
      final run = M3MeterCallRun(const M3MeterCallDeal(cases: [fast, fast, fast], callAt: 0));
      for (var i = 0; i < 3; i++) {
        expect(run.choose(M3MeterCallLines.fastNewMeter), M3MeterCallMistakes.meterBlamed);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; the mistakes book', () {
      for (final c in const [flicker, fast, burnt, M3MeterCallCase(id: 'x', kind: M3MeterCallKind.fastMeter)]) {
        final right = M3MeterCallLines.whyRight(c);
        final wrong = M3MeterCallLines.whyWrong(c);
        expectLibrary('why ${c.kind.name}', right, wrong);
        expectSameLength('why ${c.kind.name}', [...right, ...wrong]);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
        if (c.kind == M3MeterCallKind.flicker) continue;
        final ar = M3MeterCallLines.actRight(c);
        final aw = M3MeterCallLines.actWrong(c);
        expectLibrary('act ${c.kind.name}', ar, aw);
        expectSameLength('act ${c.kind.name}', [...ar, ...aw]);
      }
      for (final cw in [M3MeterCallLines.coworkerSeal, M3MeterCallLines.coworkerNeutral]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      }
      final keys = <String>{};
      for (final m in M3MeterCallMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('3.8/m3_meter_call/'));
        keys.add(m.key);
      }
      expect(keys.length, M3MeterCallMistakes.all.length);
      // Every mistake the deck can book is in the book.
      for (final c in const [fast, burnt]) {
        for (final m in M3MeterCallLines.actWrongMistake(c).values) {
          expect(M3MeterCallMistakes.all, contains(m));
        }
      }
      expect(m3MeterCallPacks.keys, ['do_3_8_b']);
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
          child: MaterialApp(home: M3MeterCallPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m3_meter_call ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      var seed = 0;
      while (dealM3MeterCall(math.Random(seed)).cases[0].kind == M3MeterCallKind.flicker) {
        seed++;
      }
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3MeterCallPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3MeterCallLines.decide), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3MeterCallLines.decide), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final ask = M3MeterCallLines.ask(dealM3MeterCall(math.Random(3)).cases[0].kind);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: look, find, fix safely — the coworker refused → pass', (t) async {
      const seed = 1;
      final deal = dealM3MeterCall(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.8/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3MeterCallLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      await _close(t, c);
    });

    testWidgets('acting before looking: the slip card, then the next call', (t) async {
      var seed = 0;
      while (true) {
        final d = dealM3MeterCall(math.Random(seed));
        if (d.cases[0].kind != M3MeterCallKind.flicker && d.callAt != 0) break;
        seed++;
      }
      final c0 = dealM3MeterCall(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await t.tap(find.text(M3MeterCallLines.decide));
      await _pump(t, 900);
      await _pickRight(t, M3MeterCallLines.actRight(c0));
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3MeterCallMistakes.noLook.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('a plain tool on the live terminals: deadly — freeze first, then the card', (t) async {
      var seed = 0;
      while (dealM3MeterCall(math.Random(seed)).cases[0].kind != M3MeterCallKind.flicker) {
        seed++;
      }
      final c0 = dealM3MeterCall(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await _look(t, M3MeterCallSpot.meter);
      await t.tap(_label(M3MeterCallLines.plain));
      await _pump(t, 200);
      await t.tapAt(_geo.terminal(c0.loose) * _k);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3MeterCallMistakes.livePlainTool.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
