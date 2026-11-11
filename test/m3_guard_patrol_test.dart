// Lesson 3.9 (গার্ড ওয়্যার ও ক্রেডল গার্ডিং), কাজ 1 "জালের পাহারা": the rules
// (tag every fault on the guard and its earths, then report — or "all fine" on
// a sound crossing; a missed fault = slip; a wrong tag = not scored, the round
// stays; a bare hand on the guard = deadly), the deal, the reason libraries,
// and the level in the shell: idle perf, the guide first, tapping the guide, a
// full clean play (the coworker refused), a wrong tag, a slip card, and the
// deadly freeze (listening to him).
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
import 'package:slm_flutter/features/game/m3_guard_patrol.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m3GuardPatrolPacks['do_3_9_a']!;

typedef _S = M3GuardPatrolSpot;
typedef _F = M3GuardPatrolFault;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_guard_patrol/')) {
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
M3GuardPatrolGeo get _geo => M3GuardPatrolGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tag(WidgetTester t, M3GuardPatrolSpot s) async {
  await t.tapAt(_geo.hit(s).center * _k);
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
    builder: (_) => M3GuardPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// Plays crossing [i] right: tags every fault; on his crossing, he is
/// refused; reports; the reason.
Future<void> _playRight(WidgetTester t, M3GuardPatrolDeal deal, int i) async {
  final c = deal.cases[i];
  for (final s in c.faults.keys) {
    await _tag(t, s);
  }
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on his crossing');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, M3GuardPatrolLines.coworker.right);
    await _pump(t, 1500);
  }
  await t.tap(find.text(c.healthy ? M3GuardPatrolLines.allOk : M3GuardPatrolLines.report));
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i ${c.faults}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'round $i');
  await _pump(t, 700);
  await _pickRight(t, M3GuardPatrolLines.whyRight(c));
  await _pump(t, 4000);
}

void main() {
  group('rules', () {
    test('deals: road, rail and telecom once each; his crossing has the snapped wire; no fault twice; an earth fault every play', () {
      final seen = <String>{};
      final calls = <int>{};
      var healthy = 0;
      for (var s = 0; s < 300; s++) {
        final d = m3GuardPatrolDeal(math.Random(s));
        expect(d.cases.map((c) => c.crossing).toSet(), M3GuardPatrolCrossing.values.toSet());
        final all = [for (final c in d.cases) ...c.faults.values];
        expect(all.toSet().length, all.length, reason: 'no fault twice: $all');
        expect(all.where((f) => f == _F.broken).length, 1);
        expect(all.any((f) => f == _F.earthGone || f == _F.earthBare), isTrue, reason: '$all');
        final call = d.cases[d.callAt];
        expect(call.has(_F.broken), isTrue);
        expect(call.faults.length, 2);
        for (final c in d.cases) {
          expect(c.faults.length, lessThanOrEqualTo(2));
          for (final e in c.faults.entries) {
            final earth = e.value == _F.earthGone || e.value == _F.earthBare;
            expect(m3GuardPatrolIsEarth(e.key), earth, reason: '${e.key} ${e.value}');
            if (e.value == _F.gap) expect(e.key, _S.spanM);
          }
          if (c.healthy) healthy++;
        }
        calls.add(d.callAt);
        seen.add(d.cases.map((c) => '${c.crossing.name}${c.faults}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(200), reason: 'every play is dealt fresh');
      expect(calls, {0, 1, 2});
      expect(healthy, greaterThan(30), reason: 'a sound crossing sometimes');
    });

    M3GuardPatrolRun run1(Map<M3GuardPatrolSpot, M3GuardPatrolFault> f) =>
        M3GuardPatrolRun(M3GuardPatrolDeal(cases: [M3GuardPatrolCase(id: 'x', crossing: M3GuardPatrolCrossing.road, faults: f)], callAt: 0));

    test('every fault tagged → report is right; a sound crossing with no tag → right', () {
      final a = run1({_S.earthL: _F.earthGone, _S.spanR: _F.rust});
      expect(a.toggle(_S.earthL), isTrue);
      expect(a.toggle(_S.spanR), isTrue);
      expect(a.report(), isNull);
      expect(a.shown, isTrue);
      expect(a.thorough, isTrue);
      expect(a.caught, containsAll([M3GuardPatrolLines.caught[_F.earthGone], M3GuardPatrolLines.caught[_F.rust]]));
      final ok = run1({});
      expect(ok.report(), isNull);
      expect(ok.shown, isTrue);
      expect(ok.caught, [M3GuardPatrolLines.caughtOk]);
    });

    test('a fault left untagged is a slip (its own card); "all fine" over a fault too', () {
      for (final f in M3GuardPatrolFault.values) {
        final spot = switch (f) {
          _F.earthGone || _F.earthBare => _S.earthR,
          _ => _S.spanM,
        };
        final a = run1({spot: f});
        expect(a.report(), M3GuardPatrolMistakes.missed(f));
        expect(a.slips, 1);
        expect(a.shown, isTrue);
      }
      final b = run1({_S.spanL: _F.sag, _S.earthL: _F.earthBare})..toggle(_S.spanL);
      expect(b.report(), M3GuardPatrolMistakes.missedEarthBare);
    });

    test('a tag on a sound spot alone is not scored: the round stays; untag and report', () {
      final a = run1({_S.spanL: _F.broken})
        ..toggle(_S.spanL)
        ..toggle(_S.earthR);
      expect(a.report(), isNull);
      expect(a.shown, isFalse);
      expect(a.needless, 1);
      expect(a.slips, 0);
      expect(a.toggle(_S.earthR), isFalse, reason: 'tap again takes the tag off');
      expect(a.report(), isNull);
      expect(a.shown, isTrue);
      expect(a.thorough, isFalse);
    });

    test('a bare hand on the guard is always deadly (the stolen earth named when so)', () {
      final a = run1({_S.spanM: _F.broken, _S.earthL: _F.earthGone});
      expect(a.touch(), M3GuardPatrolMistakes.touchNoEarth);
      expect(a.ended, isTrue);
      final b = run1({_S.spanM: _F.broken, _S.spanL: _F.rust});
      expect(b.touch(), M3GuardPatrolMistakes.touchGuard);
      expect(b.touch(), isNull, reason: 'once');
      expect(M3GuardPatrolMistakes.touchNoEarth.deadly && M3GuardPatrolMistakes.touchGuard.deadly, isTrue);
    });

    test('three slips: percent 55', () {
      final d = M3GuardPatrolDeal(cases: [
        for (var i = 0; i < 3; i++) M3GuardPatrolCase(id: 'x$i', crossing: M3GuardPatrolCrossing.rail, faults: const {_S.spanL: _F.rust}),
      ], callAt: 0);
      final run = M3GuardPatrolRun(d);
      for (var i = 0; i < 3; i++) {
        expect(run.report(), M3GuardPatrolMistakes.missedRust);
        run.next();
        expect(run.tags, isEmpty);
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; art; keys', () {
      final sets = <String, M3GuardPatrolCase>{
        'ok': const M3GuardPatrolCase(id: 'x', crossing: M3GuardPatrolCrossing.road, faults: {}),
        for (final f in M3GuardPatrolFault.values)
          f.name: M3GuardPatrolCase(id: 'x', crossing: M3GuardPatrolCrossing.road, faults: {f == _F.earthGone || f == _F.earthBare ? _S.earthL : _S.spanM: f}),
      };
      for (final e in sets.entries) {
        final right = M3GuardPatrolLines.whyRight(e.value);
        final wrong = M3GuardPatrolLines.whyWrong(e.value);
        expectLibrary('why ${e.key}', right, wrong);
        expectSameLength('why ${e.key}', [...right, ...wrong]);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      final cw = M3GuardPatrolLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final all = M3GuardPatrolMistakes.all;
      expect(all.map((m) => m.key).toSet().length, all.length);
      expect(all.length, M3GuardPatrolFault.values.length + 2);
      for (final m in all) {
        expect(m.key, startsWith('3.9/m3_guard_patrol/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m3GuardPatrolPacks.keys, ['do_3_9_a']);
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

    // A seed whose first crossing is not his (no coworker during the check).
    int quietSeed() {
      var s = 0;
      while (m3GuardPatrolDeal(math.Random(s)).callAt == 0) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3GuardPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: quietSeed())),
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
        debugPrint('PERF m3_guard_patrol ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3GuardPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3GuardPatrolLines.allOk), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3GuardPatrolLines.allOk), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, quietSeed());
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M3GuardPatrolLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: every fault tagged, a sound crossing passed, the coworker refused → pass', (t) async {
      var seed = 0;
      while (!m3GuardPatrolDeal(math.Random(seed)).cases.any((c) => c.healthy)) {
        seed++;
      }
      final deal = m3GuardPatrolDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.9/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.9/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3GuardPatrolLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      await _close(t, c);
    });

    testWidgets('a tag on a sound spot: no card, the guide says so, the round stays', (t) async {
      var seed = 0;
      while (true) {
        final d = m3GuardPatrolDeal(math.Random(seed));
        if (d.callAt != 0 && !d.cases[0].faults.containsKey(_S.spanL)) break;
        seed++;
      }
      final deal = m3GuardPatrolDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (final s in deal.cases[0].faults.keys) {
        await _tag(t, s);
      }
      await _tag(t, _S.spanL);
      await t.tap(find.text(M3GuardPatrolLines.report));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(guideDirectorProvider).line, M3GuardPatrolLines.needless);
      expect(find.text(M3GuardPatrolLines.report), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('"all fine" over a fault: the slip card', (t) async {
      var seed = 0;
      while (true) {
        final d = m3GuardPatrolDeal(math.Random(seed));
        if (d.callAt != 0 && d.cases[0].faults.isNotEmpty) break;
        seed++;
      }
      final deal = m3GuardPatrolDeal(math.Random(seed));
      final c = await _open(t, seed);
      await t.tap(find.text(M3GuardPatrolLines.allOk));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final first = M3GuardPatrolSpot.values.firstWhere((s) => deal.cases[0].faults.containsKey(s));
      expect(c.read(gameSaveProvider).mistakes.single.key, M3GuardPatrolMistakes.missed(deal.cases[0].faults[first]!).key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('listening to him = a bare hand on the hanging wire: deadly — freeze first, then the card', (t) async {
      var seed = 0;
      while (m3GuardPatrolDeal(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = m3GuardPatrolDeal(math.Random(seed));
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 9000), isTrue, reason: 'he comes even with no tag');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(M3GuardPatrolLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1400);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      final want = deal.cases[0].has(_F.earthGone) ? M3GuardPatrolMistakes.touchNoEarth : M3GuardPatrolMistakes.touchGuard;
      expect(s.mistakes.single.key, want.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
