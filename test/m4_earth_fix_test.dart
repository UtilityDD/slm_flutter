// Lesson 4.6 (সঠিক আর্থিং পরীক্ষা ও রক্ষণাবেক্ষণ), কাজ 2 "আর্থ মেরামত": the rules
// (inspect the joint, the strip and the pit → the right fix → its steps in
// order → measure again → sign off; a cut earth left = deadly; a high earth
// left or no measuring after the fix = slips), the deal, the libraries, and
// the level in the shell: idle perf, the guide first, a full clean play (the
// coworker refused), a wrong fix (the round goes on), signing off without
// measuring, and the deadly freeze (listening to him).
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
import 'package:slm_flutter/features/game/m4_earth_fix.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '4.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4EarthFixPacks['do_4_6_b']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m4_earth_fix/')) {
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
M4EarthFixGeo get _geo => M4EarthFixGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _look(WidgetTester t, M4EarthFixSpot s) async {
  await t.tapAt(_geo.spotHit(s).center * _k);
  await _pump(t, 400);
}

String _tester() {
  final f = find.byKey(const ValueKey('tester-value'));
  return f.evaluate().isEmpty ? '' : (f.evaluate().first.widget as Text).data ?? '';
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
    builder: (_) => M4EarthFixPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// Looks at the fine spots, then the fault (his round: he is refused); the
/// right fix; its steps in order.
Future<void> _findAndFix(WidgetTester t, M4EarthFixDeal deal, int i) async {
  final c = deal.cases[i];
  for (final s in M4EarthFixSpot.values) {
    if (s != c.at) await _look(t, s);
  }
  await _look(t, c.at);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes on the cut round');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, M4EarthFixLines.coworker.right);
    await _pump(t, 1500);
  }
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the fix deck, round $i');
  await _pump(t, 700);
  await _pickRight(t, M4EarthFixLines.fixRight(c.fault));
  await _pump(t, 1200);
  for (final id in c.steps) {
    await t.tap(_label(M4EarthFixLines.step(id)), warnIfMissed: false);
    await _pump(t, 300);
  }
  await _pump(t, 600);
}

Future<void> _measure(WidgetTester t) async {
  await t.tap(find.text(M4EarthFixLines.measure));
  await _pump(t, 1300);
}

Future<void> _playRight(WidgetTester t, M4EarthFixDeal deal, int i) async {
  final c = deal.cases[i];
  await _measure(t);
  expect(_tester(), M4EarthFixLines.ohm(c.before), reason: 'the weak earth reads high');
  await _findAndFix(t, deal, i);
  expect(find.byType(MistakeCard), findsNothing, reason: 'round $i ${c.fault}');
  await _measure(t);
  expect(_tester(), M4EarthFixLines.ohm(c.after));
  await t.tap(find.text(M4EarthFixLines.signOff));
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i ${c.fault}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'round $i');
  await _pump(t, 700);
  await _pickRight(t, M4EarthFixLines.whyRight(c.fault));
  await _pump(t, 4000);
}

int _seedWhere(bool Function(M4EarthFixDeal d) ok) {
  var s = 0;
  while (!ok(m4EarthFixDeal(math.Random(s)))) {
    s++;
  }
  return s;
}

void main() {
  group('rules', () {
    test('deals: loose, cut and dry once each in a fresh order; he comes on the cut round; readings', () {
      final seen = <String>{};
      final looseAt = <M4EarthFixSpot>{};
      for (var s = 0; s < 80; s++) {
        final d = m4EarthFixDeal(math.Random(s));
        expect(d.cases.length, 3);
        expect(d.cases.map((c) => c.fault).toSet(), M4EarthFixFault.values.toSet());
        expect(d.cases[d.callAt].fault, M4EarthFixFault.cut);
        for (final c in d.cases) {
          expect(c.after, lessThan(5), reason: 'under the lesson target after the fix');
          if (c.fault == M4EarthFixFault.cut) {
            expect(c.before, isNull, reason: 'a cut strip reads over range');
            expect(c.at, M4EarthFixSpot.strip);
          } else {
            expect(c.before, greaterThan(8), reason: 'above the lesson target before the fix');
          }
          if (c.fault == M4EarthFixFault.dry) expect(c.at, M4EarthFixSpot.pit);
          if (c.fault == M4EarthFixFault.loose) looseAt.add(c.at);
        }
        seen.add(d.cases.map((c) => '${c.fault.name}${c.at.name}${c.before}${c.after}').join('|'));
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(looseAt, {M4EarthFixSpot.joint, M4EarthFixSpot.pit});
    });

    M4EarthFixRun run1(M4EarthFixFault f, {M4EarthFixSpot? at}) => M4EarthFixRun(M4EarthFixDeal(cases: [
          M4EarthFixCase(
            id: 'x',
            fault: f,
            at: at ?? (f == M4EarthFixFault.cut ? M4EarthFixSpot.strip : M4EarthFixSpot.pit),
            before: f == M4EarthFixFault.cut ? null : 22.4,
            after: 3.4,
          ),
        ], callAt: 0));
    void fix(M4EarthFixRun r) {
      r.pickFix(right: true);
      for (final id in r.current.steps) {
        expect(r.step(id), isNull);
      }
    }

    test('look at all three, the right fix, its steps, measure, sign off: right and thorough', () {
      for (final f in M4EarthFixFault.values) {
        final r = run1(f);
        expect(r.inspect(M4EarthFixSpot.joint), f == M4EarthFixFault.cut ? isFalse : anything);
        r.inspect(M4EarthFixSpot.strip);
        r.inspect(M4EarthFixSpot.pit);
        expect(r.found, isTrue);
        expect(r.measure(), f == M4EarthFixFault.cut ? isNull : 22.4);
        expect(r.retested, isFalse);
        fix(r);
        expect(r.fixed, isTrue);
        expect(r.measure(), 3.4);
        expect(r.retested, isTrue);
        expect(r.signOff(), isNull);
        expect(r.shown, isTrue);
        expect(r.thorough, isTrue);
        expect(r.caught, containsAll([M4EarthFixLines.caughtInspect, M4EarthFixLines.caughtFix(f), M4EarthFixLines.caughtRetest]));
      }
    });

    test('a loose joint is found where it is (body clamp or the pit)', () {
      final r = run1(M4EarthFixFault.loose, at: M4EarthFixSpot.joint);
      expect(r.inspect(M4EarthFixSpot.pit), isFalse);
      expect(r.inspect(M4EarthFixSpot.joint), isTrue);
    });

    test('signing off with the earth still cut is deadly (also after a wrong step)', () {
      final r = run1(M4EarthFixFault.cut)..inspect(M4EarthFixSpot.strip);
      expect(r.signOff(), M4EarthFixMistakes.cutLeft);
      expect(r.ended, isTrue);
      final g = run1(M4EarthFixFault.cut)..pickFix(right: true);
      expect(g.giveIn()!.deadly, isTrue, reason: 'listening to him half-way');
    });

    test('a high earth left (rusty, dry) is a slip; no measuring after the fix is a slip', () {
      for (final f in [M4EarthFixFault.loose, M4EarthFixFault.dry]) {
        final r = run1(f);
        expect(r.signOff(), M4EarthFixMistakes.highLeft);
        expect(r.slips, 1);
        expect(r.deadly, isNull);
      }
      final r = run1(M4EarthFixFault.dry);
      fix(r);
      expect(r.signOff(), M4EarthFixMistakes.noRetest);
      expect(r.slips, 1);
      final m = run1(M4EarthFixFault.dry)..measure();
      fix(m);
      expect(m.signOff(), M4EarthFixMistakes.noRetest, reason: 'the measure before the fix does not count');
    });

    test('a wrong fix and a step out of order are slips; the round goes on', () {
      final r = run1(M4EarthFixFault.loose);
      expect(r.pickFix(right: false), M4EarthFixMistakes.wrongFixLoose);
      expect(r.shown, isFalse);
      expect(r.fixPicked, isFalse);
      expect(r.pickFix(right: true), isNull);
      expect(r.step('tight'), M4EarthFixMistakes.orderLoose);
      expect(r.stepsDone, 0);
      expect(r.step('open'), isNull);
      expect(r.step('open'), isNull, reason: 'a done step again is ignored');
      expect(r.slips, 2);
      expect(r.stepsDone, 1);
      expect(run1(M4EarthFixFault.cut).step('clean'), isNull, reason: 'no steps before the fix is chosen');
    });

    test('three slips fail the level (percent 55)', () {
      final d = M4EarthFixDeal(cases: [
        for (var i = 0; i < 3; i++) const M4EarthFixCase(id: 'x', fault: M4EarthFixFault.dry, at: M4EarthFixSpot.pit, before: 22.4, after: 3.4),
      ], callAt: 0);
      final run = M4EarthFixRun(d);
      for (var i = 0; i < 3; i++) {
        expect(run.signOff(), M4EarthFixMistakes.highLeft);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; mistakes book', () {
      for (final f in M4EarthFixFault.values) {
        final fr = M4EarthFixLines.fixRight(f);
        final fw = M4EarthFixLines.fixWrong(f);
        expectLibrary('fix ${f.name}', fr, fw);
        expectSameLength('fix ${f.name}', [...fr, ...fw]);
        final wr = M4EarthFixLines.whyRight(f);
        expectLibrary('why ${f.name}', wr, M4EarthFixLines.whyWrong);
        expectSameLength('why ${f.name}', [...wr, ...M4EarthFixLines.whyWrong]);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(fr, fw, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
        for (final o in M4EarthFixFault.values) {
          if (o != f) expect(M4EarthFixLines.fixRight(f).toSet().intersection(M4EarthFixLines.fixRight(o).toSet()), isEmpty);
        }
        expect(m4EarthFixSteps(f).toSet().length, m4EarthFixSteps(f).length);
      }
      final cw = M4EarthFixLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final all = M4EarthFixMistakes.all;
      expect(all.map((m) => m.key).toSet().length, all.length);
      for (final m in all) {
        expect(m.key, startsWith('4.6/m4_earth_fix/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(all.where((m) => m.deadly), [M4EarthFixMistakes.cutLeft]);
      for (final f in M4EarthFixFault.values) {
        expect(all, containsAll([M4EarthFixMistakes.wrongFix(f), M4EarthFixMistakes.order(f)]));
      }
      expect(m4EarthFixPacks.keys, ['do_4_6_b']);
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
          child: MaterialApp(home: M4EarthFixPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m4_earth_fix ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4EarthFixPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M4EarthFixLines.signOff), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M4EarthFixLines.signOff), findsOneWidget);
      expect(find.text(M4EarthFixLines.measure), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M4EarthFixLines.askFind)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: look, fix, steps, measure, sign off — three rounds, the coworker refused → pass', (t) async {
      const seed = 5;
      final deal = m4EarthFixDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.6/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.6/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M4EarthFixLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      expect(find.text(M4EarthFixLines.caughtInspect), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a wrong fix: the slip card, then the round goes on', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final c0 = m4EarthFixDeal(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await _look(t, c0.at);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      final wrong = _onScreen(M4EarthFixLines.fixWrong(c0.fault));
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4EarthFixMistakes.wrongFix(c0.fault).key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M4EarthFixLines.signOff), findsOneWidget, reason: 'same round, hands free');
      await _look(t, c0.at);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the fix deck again');
      await _close(t, c);
    });

    testWidgets('fixed but not measured: the slip card, then the next round', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final deal = m4EarthFixDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _findAndFix(t, deal, 0);
      await t.tap(find.text(M4EarthFixLines.signOff));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4EarthFixMistakes.noRetest.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, M4EarthFixLines.askFind, reason: 'round two');
      await _close(t, c);
    });

    testWidgets('his "ঝুলিয়ে রাখো": listening = deadly — freeze first, then the card', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final c = await _open(t, seed);
      await _look(t, M4EarthFixSpot.strip);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'the fix waits for him');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(M4EarthFixLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4EarthFixMistakes.cutLeft.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
