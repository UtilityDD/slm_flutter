// Lesson 3.8 (সার্ভিস কেবিল ও এনার্জি মিটার), কাজ 2 "গ্রাহকের ডাক": the rules
// (look at the four spots and find the fault; the flicker call: supply OFF +
// insulated tool on the loose terminal; the fast meter: explain politely, keep
// the seal; the burnt call: the LT line's neutral, shutdown first, never a
// bare hand), the deal, the libraries, and the level in the shell: idle perf,
// the guide first, tapping the guide, a full clean play (the coworker
// refused), a slip card (acting before looking), the deadly freeze (a
// plain tool on the live terminals), three slips strike out, the coworker
// comes even on a fast decision, and on the burnt call only once the LT line
// was looked at (his push about the neutral fits then).
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
import 'package:slm_flutter/features/game/do_parts.dart' show DoBigButton;
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
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
import 'support/reason_proceed.dart';

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
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3MeterCallGeo get _geo => M3MeterCallGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _look(WidgetTester t, M3MeterCallSpot s) async {
  await t.tapAt(_geo.spotHit(s).center * _k);
  await _pump(t, 400);
}

/// The first seed whose deal passes [ok].
int _seedWhere(bool Function(M3MeterCallDeal d) ok) {
  var s = 0;
  while (!ok(dealM3MeterCall(math.Random(s)))) {
    s++;
  }
  return s;
}

CoworkerScript _script(M3MeterCallDeal d) => d.cases[d.callAt].kind == M3MeterCallKind.burnt ? M3MeterCallLines.coworkerNeutral : M3MeterCallLines.coworkerSeal;

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

    test('flicker: the terminals answer only after the meter was looked at; without a tool every terminal is the same (no reveal)', () {
      final a = run1(flicker);
      expect(a.tapTerminal(M3MeterCallTerm.nIn), isNull);
      a.inspect(M3MeterCallSpot.meter);
      for (final t in M3MeterCallTerm.values) {
        expect(a.tapTerminal(t), M3MeterCallTap.needTool, reason: t.name);
      }
      expect(a.shown, isFalse);
      expect(a.needless, 0);
      a
        ..toggleSupply()
        ..pickTool(M3MeterCallTool.insulated);
      // Safely on a sound terminal: only needless (no slip, the round goes on).
      expect(a.tapTerminal(M3MeterCallTerm.pIn), M3MeterCallTap.tight);
      expect(a.needless, 1);
      expect(a.slips, 0);
      expect(a.shown, isFalse);
      expect(a.tapTerminal(M3MeterCallTerm.nIn), M3MeterCallTap.fixed);
      expect(a.fixed, isTrue);
      expect(a.caught, containsAll([M3MeterCallLines.caughtLoose, M3MeterCallLines.caughtSafeTool]));
    });

    test('flicker: the live panel is live at every terminal — a plain tool on a sound one is deadly too; supply ON there is a slip', () {
      final a = run1(flicker)
        ..inspect(M3MeterCallSpot.meter)
        ..pickTool(M3MeterCallTool.plain);
      expect(a.tapTerminal(M3MeterCallTerm.pOut), M3MeterCallTap.mistake);
      expect(a.mistake, M3MeterCallMistakes.livePlainTool);
      expect(a.deadly, M3MeterCallMistakes.livePlainTool);
      final b = run1(flicker)
        ..inspect(M3MeterCallSpot.meter)
        ..pickTool(M3MeterCallTool.insulated);
      expect(b.tapTerminal(M3MeterCallTerm.pOut), M3MeterCallTap.mistake);
      expect(b.mistake, M3MeterCallMistakes.supplyOn);
      expect(b.slips, 1);
      expect(b.needless, 0);
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
      expect(run1(fast).choose(M3MeterCallLines.fastScoldLeak), M3MeterCallMistakes.rude);
      // The other load's polite explanation is wrong (the window shows which).
      final w = run1(fast)..inspect(M3MeterCallSpot.house);
      expect(w.choose(M3MeterCallLines.fastFridge.last), M3MeterCallMistakes.noLook);
      expect(w.slips, 1);
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

    test('no giveaway word: what the right cards say also sits on the wrong ones', () {
      const fridge = M3MeterCallCase(id: 'x', kind: M3MeterCallKind.fastMeter);
      Set<String> words(String o) => o.split(RegExp(r'[\s,—\-!?]+')).where((w) => w.isNotEmpty).toSet();
      // Every word of every right card (dealChoices deals either) also sits,
      // as a whole word, on at least one wrong card of the same deck.
      for (final c in const [fast, fridge, burnt]) {
        final wrongWords = M3MeterCallLines.actWrong(c).expand(words).toSet();
        for (final r in M3MeterCallLines.actRight(c)) {
          expect(words(r).difference(wrongWords), isEmpty, reason: '${c.kind.name}/${c.cause.name}: "$r"');
        }
      }
      int inWrong(M3MeterCallCase c, String word) => M3MeterCallLines.actWrong(c).where((o) => o.contains(word)).length;
      expect(inWrong(burnt, 'শাটডাউন'), greaterThanOrEqualTo(2));
      expect(inWrong(burnt, 'লাইনের'), greaterThanOrEqualTo(1));
      expect(inWrong(burnt, 'এলটি'), greaterThanOrEqualTo(1));
      expect(inWrong(burnt, 'নিউট্রাল'), greaterThanOrEqualTo(2));
      expect(inWrong(burnt, 'সারাই'), greaterThanOrEqualTo(1));
      for (final c in const [fast, fridge]) {
        expect(inWrong(c, 'ভদ্রভাবে'), greaterThanOrEqualTo(1), reason: c.cause.name);
        expect(inWrong(c, 'ধীরে বুঝিয়ে'), greaterThanOrEqualTo(1), reason: c.cause.name);
        expect(inWrong(c, 'মিটার নয়'), greaterThanOrEqualTo(1), reason: c.cause.name);
        expect(inWrong(c, c.cause == M3MeterCallCause.leak ? 'লিকেজ' : 'ফ্রিজ'), greaterThanOrEqualTo(1), reason: c.cause.name);
      }
    });

    test('every spot looked at = thorough (+5)', () {
      final a = run1(burnt);
      for (final s in M3MeterCallSpot.values) {
        a.inspect(s);
      }
      expect(a.thorough, isTrue);
    });

    test('the mark: 15 off per slip (55 after three; the page strikes out at the third)', () {
      final run = M3MeterCallRun(const M3MeterCallDeal(cases: [fast, fast, fast], callAt: 0));
      for (var i = 0; i < 3; i++) {
        expect(run.choose(M3MeterCallLines.fastNewMeter), M3MeterCallMistakes.meterBlamed);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
      // (On the page the third slip strikes out first: see 'three slips'.)
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

    testWidgets('three slips strike out: the StruckOutCard, no pass', (t) async {
      const seed = 2;
      final deal = dealM3MeterCall(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        final k = deal.cases[i];
        if (k.kind == M3MeterCallKind.flicker) {
          // The insulated tool with the supply left ON: a slip.
          await _look(t, M3MeterCallSpot.meter);
          await t.tap(_label(M3MeterCallLines.insulated));
          await _pump(t, 200);
          await t.tapAt(_geo.terminal(k.loose) * _k);
          await _pump(t, 1500);
        } else {
          await t.tap(find.text(M3MeterCallLines.decide));
          await _pump(t, 900);
          if (i == deal.callAt) {
            expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3000), isTrue);
            await _pickRight(t, _script(deal).right);
            await _pump(t, 2500);
            await t.tap(find.text(M3MeterCallLines.decide));
            await _pump(t, 900);
          }
          // The right action before looking: a slip.
          await _pickRight(t, M3MeterCallLines.actRight(k));
          await _pump(t, 1500);
        }
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'call $i ${k.kind}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 1500);
        }
      }
      expect(await _pumpUntil(t, find.byType(StruckOutCard), maxMs: 4000), isTrue);
      expect(find.byType(LevelPassPanel), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.8/do/1'], isNot('cleared'));
      expect(s.mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a fast decision cannot skip the coworker: সিদ্ধান্ত নিই waits for him', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = dealM3MeterCall(math.Random(seed));
      final k = deal.cases[0];
      final c = await _open(t, seed);
      // No look at all: straight to the decision.
      await t.tap(find.text(M3MeterCallLines.decide));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in before the deck');
      expect(_onScreen(M3MeterCallLines.actRight(k)), isEmpty, reason: 'the action deck waits');
      await _pickRight(t, _script(deal).right);
      await _pump(t, 2500);
      await t.tap(find.text(M3MeterCallLines.decide));
      await _pump(t, 900);
      await waitChoiceDeck(t);
      expect(_onScreen(M3MeterCallLines.actRight(k)), hasLength(1), reason: 'now the action deck');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the burnt call: his push about the neutral waits for a look at the LT line', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0 && d.cases[0].kind == M3MeterCallKind.burnt);
      final c = await _open(t, seed);
      for (final s in [M3MeterCallSpot.house, M3MeterCallSpot.cable, M3MeterCallSpot.meter]) {
        await _look(t, s);
      }
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _look(t, M3MeterCallSpot.line);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _close(t, c);
    });

    testWidgets('no giveaway: every look tag looks the same; the praise window takes no input', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0 && d.cases[0].kind != M3MeterCallKind.flicker);
      final k = dealM3MeterCall(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      for (final s in M3MeterCallSpot.values) {
        await _look(t, s);
      }
      // One neutral tag for the fault and the sound spots alike (no red/green verdict).
      expect(find.byIcon(Icons.visibility_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.error_rounded), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      await t.tap(find.text(M3MeterCallLines.decide));
      await _pump(t, 900);
      await waitChoiceDeck(t);
      final r = _onScreen(M3MeterCallLines.actRight(k));
      expect(r, hasLength(1));
      await t.tap(r.single, warnIfMissed: false);
      await confirmChoice(t);
      // The ◆ on the table: no decision button, no scene hint, taps do nothing.
      await _pump(t, 500);
      expect(find.text(M3MeterCallLines.decide), findsNothing);
      expect(t.widget<IdleHint>(find.byType(IdleHint).first).waiting, isFalse);
      await t.tapAt(_geo.spotHit(M3MeterCallSpot.meter).center * _k);
      await _pump(t, 200);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      // Then the reason deck as usual; the play goes on to the next call.
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pickRight(t, M3MeterCallLines.whyRight(k));
      await _pump(t, 4000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hints: taps on nothing call a sweep over all four spots; then a tap on সিদ্ধান্ত নিই only', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      const hand = ValueKey('gesture-hint');
      final seed = _seedWhere((d) => d.callAt != 0 && d.cases[0].kind != M3MeterCallKind.flicker);
      final c = await _open(t, seed);
      IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      // Three taps on empty ground left of the trainee: the hand shows now.
      for (var i = 0; i < 3; i++) {
        await t.tapAt(const Offset(20, 400) * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byKey(hand), findsOneWidget, reason: 'confused taps call the hand');
      expect(hint().debugOptions, hasLength(4), reason: 'it glides over every spot alike, never the fault alone');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // Every spot looked at: after a quiet spell the hand taps the decision button.
      for (final s in M3MeterCallSpot.values) {
        await _look(t, s);
      }
      expect(find.byKey(hand), findsNothing, reason: 'any touch hides it');
      for (var ms = 0; ms < 12000 && !hint().showing; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(hand), findsOneWidget);
      expect(t.getRect(find.byType(DoBigButton)).inflate(4).contains(hint().debugFrame!.tip), isTrue);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'a hint never presses');
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

    testWidgets('no giveaway order: the two tools change sides across calls', (t) async {
      final sides = <bool>{};
      var seed = 0;
      for (var opened = 0; opened < 8 && sides.length < 2; seed++) {
        if (dealM3MeterCall(math.Random(seed)).cases[0].kind != M3MeterCallKind.flicker) continue;
        opened++;
        final c = await _open(t, seed);
        final ins = t.getCenter(_label(M3MeterCallLines.insulated));
        final plain = t.getCenter(_label(M3MeterCallLines.plain));
        sides.add(ins.dx < plain.dx);
        expect(t.takeException(), isNull);
        await _close(t, c);
      }
      expect(sides, {true, false}, reason: 'the insulated tool must not always sit left of the plain one');
    });
  });
}
