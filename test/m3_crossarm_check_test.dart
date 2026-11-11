// Lesson 3.3 (ক্রস-আর্ম ও ক্ল্যাম্প), কাজ 2 "কঙ্কালের স্বাস্থ্য": the rules
// (look from below before climbing; a rusty or bent arm is reported — climbing
// it is deadly; a slipped or rusty clamp is reported; up the pole every bolt
// tried, the spring washer fitted, the right torque — too much snaps the
// bolt), the deal, the reason libraries, and the level in the shell: idle
// perf, the guide first, a full clean play (the coworker refused), a needless
// report that is not scored, a slip card, an over-torque that keeps the pole,
// and the deadly freeze (climbing the weak arm on his say-so).
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
import 'package:slm_flutter/features/game/m3_crossarm_check.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3CrossarmCheckPacks['do_3_3_b']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_crossarm_check/')) {
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
M3CrossarmGeo get _geo => M3CrossarmGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Offset _partAt(M3CrossarmPart p) => switch (p) {
      M3CrossarmPart.arm => Offset(300, _geo.armY),
      M3CrossarmPart.clamp => _geo.clampHit.center,
      M3CrossarmPart.brace => _geo.braceHit.center,
    };

Future<void> _look(WidgetTester t, M3CrossarmPart p) async {
  await t.tapAt(_partAt(p) * _k);
  await _pump(t, 500);
}

Future<void> _bolt(WidgetTester t, int i) async {
  await t.tapAt(_geo.bolts[i] * _k);
  await _pump(t, 300);
}

/// Hold the wrench for [ms] and let go.
Future<void> _torque(WidgetTester t, int ms) async {
  final g = await t.startGesture(t.getCenter(_label(M3CrossarmCheckLines.torque)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

/// Into the band (0.58–0.80 of an 1800 ms sweep).
const _rightHold = 1250;

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
    builder: (_) => M3CrossarmCheckPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// Plays pole [i] right: look at the arm (his pole: he is refused) and the
/// clamp; report a fault, or climb and try every bolt, fit missing washers,
/// tighten loose nuts in the band, done. Then the reason.
Future<void> _playRight(WidgetTester t, M3CrossarmDeal deal, int i) async {
  final p = deal.poles[i];
  await _look(t, M3CrossarmPart.arm);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes on the weak arm');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    final cw = p.fault == M3CrossarmFault.bentArm ? M3CrossarmCheckLines.coworkerBent : M3CrossarmCheckLines.coworkerRust;
    await _pickRight(t, cw.right);
    await _pump(t, 2000);
  }
  await _look(t, M3CrossarmPart.clamp);
  await _look(t, M3CrossarmPart.brace);
  if (p.report) {
    await t.tap(find.text(M3CrossarmCheckLines.report));
  } else {
    await t.tap(find.text(M3CrossarmCheckLines.climb));
    await _pump(t, 1200);
    expect(find.text(M3CrossarmCheckLines.done), findsOneWidget, reason: 'up the pole');
    for (var b = 0; b < 3; b++) {
      await _bolt(t, b);
      final spec = p.bolts[b];
      if (!spec.washer) {
        await t.tap(_label(M3CrossarmCheckLines.washer));
        await _pump(t, 300);
      }
      if (spec.loose || !spec.washer) await _torque(t, _rightHold);
    }
    await t.tap(find.text(M3CrossarmCheckLines.done));
  }
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i ${p.fault}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'pole $i');
  await _pump(t, 700);
  await _pickRight(t, M3CrossarmCheckLines.whyRight(p));
  await _pump(t, 4000);
}

void main() {
  group('rules', () {
    test('deals: a weak arm (his pole), a pole to fix, and one more; fresh every play', () {
      final seen = <String>{};
      final calls = <int>{};
      final thirds = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m3CrossarmDeal(math.Random(s));
        expect(d.poles.length, 3);
        expect(d.poles.where((p) => p.deadly).length, 1);
        expect(d.poles[d.callAt].deadly, isTrue, reason: 'he comes on the weak arm');
        final fix = d.poles.where((p) => !p.report && p.bolts.any((b) => b.loose) && p.bolts.any((b) => !b.washer));
        expect(fix, isNotEmpty, reason: 'a loose nut and a missing spring washer every play');
        for (final p in d.poles) {
          expect(p.bolts.length, 3);
          if (p.report) expect(p.bolts.every((b) => b.ok), isTrue);
        }
        final third = d.poles.firstWhere((p) => p.id == 'p2');
        thirds.add(third.report ? third.fault.name : (third.bolts.every((b) => b.ok) ? 'sound' : 'bolt'));
        calls.add(d.callAt);
        seen.add(d.poles.map((p) => '${p.fault.name}${p.bolts.map((b) => '${b.loose}${b.washer}').join()}').join('|'));
      }
      expect(seen.length, greaterThan(30), reason: 'every play is dealt fresh');
      expect(calls, {0, 1, 2});
      expect(thirds, {'slippedClamp', 'rustClamp', 'bolt', 'sound'});
    });

    M3CrossarmCheckRun run1(M3CrossarmPole p) => M3CrossarmCheckRun(M3CrossarmDeal(poles: [p], callAt: 0));
    const sound = M3CrossarmPole(id: 'x', fault: M3CrossarmFault.none);
    const fixPole = M3CrossarmPole(id: 'x', fault: M3CrossarmFault.none, bolts: [
      M3CrossarmBoltSpec(loose: true),
      M3CrossarmBoltSpec(washer: false),
      M3CrossarmBoltSpec(),
    ]);
    void lookAll(M3CrossarmCheckRun r) {
      for (final p in M3CrossarmPart.values) {
        r.look(p);
      }
    }

    test('a rusty or bent arm: climbing is deadly (even unlooked); a report after looking is right', () {
      for (final f in [M3CrossarmFault.rustArm, M3CrossarmFault.bentArm]) {
        final p = M3CrossarmPole(id: 'x', fault: f);
        final a = run1(p);
        expect(a.climb()!.deadly, isTrue);
        expect(a.ended, isTrue);
        final b = run1(p)..look(M3CrossarmPart.arm);
        expect(b.report(), M3CrossarmReport.done);
        expect(b.shown, isTrue);
        expect(b.caught, contains(M3CrossarmCheckLines.caughtArm));
      }
      expect(run1(const M3CrossarmPole(id: 'x', fault: M3CrossarmFault.rustArm)).climb(), M3CrossarmCheckMistakes.climbRust);
      expect(run1(const M3CrossarmPole(id: 'x', fault: M3CrossarmFault.bentArm)).climb(), M3CrossarmCheckMistakes.climbBent);
    });

    test('a slipped or rusty clamp: climbing is a slip; reported after looking at the clamp is right', () {
      final a = run1(const M3CrossarmPole(id: 'x', fault: M3CrossarmFault.slippedClamp));
      expect(a.climb(), M3CrossarmCheckMistakes.climbSlipped);
      expect(a.slips, 1);
      expect(a.deadly, isNull);
      final b = run1(const M3CrossarmPole(id: 'x', fault: M3CrossarmFault.rustClamp));
      expect(b.climb(), M3CrossarmCheckMistakes.climbRustClamp);
      final ok = run1(const M3CrossarmPole(id: 'x', fault: M3CrossarmFault.rustClamp))..look(M3CrossarmPart.arm);
      expect(ok.report(), M3CrossarmReport.needlessUnseen, reason: 'the clamp not looked at yet');
      expect(ok.shown, isFalse);
      ok.look(M3CrossarmPart.clamp);
      expect(ok.report(), M3CrossarmReport.done);
      expect(ok.caught, contains(M3CrossarmCheckLines.caughtClamp));
    });

    test('a report on a sound pole is not scored: no mistake, the pole stays', () {
      final a = run1(fixPole)..look(M3CrossarmPart.arm);
      expect(a.report(), M3CrossarmReport.needlessSound);
      expect(a.shown, isFalse);
      expect(a.needless, 1);
      expect(a.slips, 0);
    });

    test('climbing a sound pole without looking at arm and clamp is a slip', () {
      final a = run1(sound)..look(M3CrossarmPart.arm);
      expect(a.climb(), M3CrossarmCheckMistakes.noLook);
      final b = run1(sound)
        ..look(M3CrossarmPart.arm)
        ..look(M3CrossarmPart.clamp);
      expect(b.climb(), isNull);
      expect(b.up, isTrue);
      expect(b.caught, contains(M3CrossarmCheckLines.caughtLook));
    });

    test('up the pole: try every bolt, washer then torque in the band → right', () {
      final a = run1(fixPole);
      lookAll(a);
      a.climb();
      expect(a.check(0)!.loose, isTrue);
      expect(a.torque(0.4), M3CrossarmTorque.under);
      expect(a.bolts[0].loose, isTrue, reason: 'too little stays loose');
      expect(a.torque(0.7), M3CrossarmTorque.right);
      expect(a.bolts[0].loose, isFalse);
      a.check(1);
      expect(a.fitWasher(), isTrue);
      expect(a.bolts[1].loose, isTrue, reason: 'the nut came off for the washer');
      expect(a.torque(0.66), M3CrossarmTorque.right);
      a.check(2);
      expect(a.fitWasher(), isFalse, reason: 'it has one');
      expect(a.finish(), isNull);
      expect(a.shown, isTrue);
      expect(a.slips, 0);
      expect(a.caught, containsAll([M3CrossarmCheckLines.caughtTorque, M3CrossarmCheckLines.caughtWasher]));
    });

    test('up the pole: a bolt untried, a loose nut left, no washer, over-torque', () {
      M3CrossarmCheckRun upRun() {
        final r = run1(fixPole);
        lookAll(r);
        r.climb();
        return r;
      }

      final a = upRun()
        ..check(0)
        ..check(1);
      expect(a.finish(), M3CrossarmCheckMistakes.missedBolt);
      final b = upRun()
        ..check(0)
        ..check(1)
        ..check(2);
      expect(b.finish(), M3CrossarmCheckMistakes.looseLeft);
      final c = upRun()..check(0);
      c.torque(0.7);
      c
        ..check(1)
        ..torque(0.7)
        ..check(2);
      expect(c.finish(), M3CrossarmCheckMistakes.noWasher, reason: 'tight but no spring washer');
      final d = upRun()..check(0);
      expect(d.torque(0.95), M3CrossarmTorque.over);
      expect(d.slips, 1);
      expect(d.shown, isFalse, reason: 'the pole goes on');
      expect(d.bolts[0].loose, isTrue, reason: 'a new bolt, finger-tight');
      expect(d.torque(0.7), M3CrossarmTorque.right);
    });

    test('three slips fail the level (percent below 55)', () {
      final run = M3CrossarmCheckRun(const M3CrossarmDeal(poles: [sound, sound, sound], callAt: 0));
      for (var i = 0; i < 3; i++) {
        expect(run.climb(), M3CrossarmCheckMistakes.noLook);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; art', () {
      final poles = [
        for (final f in M3CrossarmFault.values) M3CrossarmPole(id: 'x', fault: f),
        fixPole,
        const M3CrossarmPole(id: 'x', fault: M3CrossarmFault.none, bolts: [M3CrossarmBoltSpec(loose: true, washer: false), M3CrossarmBoltSpec(), M3CrossarmBoltSpec()]),
      ];
      final all = <String>[];
      for (final p in poles) {
        final right = M3CrossarmCheckLines.whyRight(p);
        final wrong = M3CrossarmCheckLines.whyWrong(p);
        expectLibrary('why ${p.fault.name}', right, wrong);
        all.addAll([...right, ...wrong]);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      expectSameLength('why', all.toSet().toList());
      for (final cw in [M3CrossarmCheckLines.coworkerBent, M3CrossarmCheckLines.coworkerRust]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      }
      final keys = <String>{};
      for (final m in M3CrossarmCheckMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('3.3/m3_crossarm_check/'));
        expect(keys.add(m.key), isTrue, reason: m.key);
      }
      expect(m3CrossarmCheckPacks.keys, ['do_3_3_b']);
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
          child: MaterialApp(home: M3CrossarmCheckPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m3_crossarm_check ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3CrossarmCheckPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3CrossarmCheckLines.climb), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3CrossarmCheckLines.climb), findsOneWidget);
      expect(find.text(M3CrossarmCheckLines.report), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M3CrossarmCheckLines.askGround)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: look, report the weak, fix the loose and the bare, coworker refused → pass', (t) async {
      final deal = m3CrossarmDeal(math.Random(1));
      final c = await _open(t, 1);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.3/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.3/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3CrossarmCheckLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a report on a sound pole is not scored: no card, the guide says the rule, the pole stays', (t) async {
      var seed = 0;
      while (m3CrossarmDeal(math.Random(seed)).poles[0].report) {
        seed++;
      }
      final c = await _open(t, seed);
      await _look(t, M3CrossarmPart.arm);
      await t.tap(find.text(M3CrossarmCheckLines.report));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(guideDirectorProvider).line, M3CrossarmCheckLines.needlessSound);
      expect(find.text(M3CrossarmCheckLines.climb), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('up without trying every bolt: the slip card, then the next pole', (t) async {
      var seed = 0;
      while (m3CrossarmDeal(math.Random(seed)).poles[0].report) {
        seed++;
      }
      final c = await _open(t, seed);
      await _look(t, M3CrossarmPart.arm);
      await _look(t, M3CrossarmPart.clamp);
      await t.tap(find.text(M3CrossarmCheckLines.climb));
      await _pump(t, 1200);
      await _bolt(t, 0);
      await t.tap(find.text(M3CrossarmCheckLines.done));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3CrossarmCheckMistakes.missedBolt.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M3CrossarmCheckLines.climb), findsOneWidget, reason: 'the next pole, from the ground');
      await _close(t, c);
    });

    testWidgets('too much torque snaps the bolt: a slip card, and the pole goes on', (t) async {
      var seed = 0;
      while (true) {
        final p = m3CrossarmDeal(math.Random(seed)).poles[0];
        if (!p.report && p.bolts.any((b) => b.loose)) break;
        seed++;
      }
      final p = m3CrossarmDeal(math.Random(seed)).poles[0];
      final c = await _open(t, seed);
      await _look(t, M3CrossarmPart.arm);
      await _look(t, M3CrossarmPart.clamp);
      await t.tap(find.text(M3CrossarmCheckLines.climb));
      await _pump(t, 1200);
      await _bolt(t, p.bolts.indexWhere((b) => b.loose));
      await _torque(t, 2200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3CrossarmCheckMistakes.overTorque.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.text(M3CrossarmCheckLines.done), findsOneWidget, reason: 'still up the same pole');
      await _close(t, c);
    });

    testWidgets('his "একটু হেলে আছে, চলবে": listening = deadly — freeze first, then the card', (t) async {
      var seed = 0;
      while (m3CrossarmDeal(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = m3CrossarmDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _look(t, M3CrossarmPart.arm);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final cw = deal.poles[0].fault == M3CrossarmFault.bentArm ? M3CrossarmCheckLines.coworkerBent : M3CrossarmCheckLines.coworkerRust;
      final wrong = _onScreen(cw.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, deal.poles[0].fault == M3CrossarmFault.bentArm ? M3CrossarmCheckMistakes.climbBent.key : M3CrossarmCheckMistakes.climbRust.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
