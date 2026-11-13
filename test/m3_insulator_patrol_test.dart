// Lesson 3.2 (ইনসুলেটর পরিচিতি), কাজ 2 "দূরবিনে টহল": the rules (mark every
// faulty insulator through the binoculars, then "সব ঠিক" or "রিপোর্ট"; a
// missed fault, a sound pole reported or a sound insulator marked is a slip;
// a report with nothing marked is not scored; climbing the live pole on his
// say-so is deadly), the deal, the reason libraries, and the level in the
// shell: idle perf, the guide first, a full clean play (the coworker
// refused), the unscored report (a neutral line), a slip card, three slips
// strike out, the coworker on a fast play and on the sound pole, the gesture
// hint (and none over a card), and the deadly freeze.
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
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_insulator_patrol.dart';
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
  rungId: '3.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3InsulatorPatrolPacks['do_3_2_b']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_insulator_patrol/')) {
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

Future<void> _mark(WidgetTester t, M3InsulatorPatrolKind kind, int i) async {
  await t.tapAt(M3InsulatorPatrolGeo.unitHit(kind, i).center * _k);
  await _pump(t, 200);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {int settleMs = 1500}) async {
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
    builder: (_) => M3InsulatorPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, settleMs);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Plays pole [i] right: (his pole: he is refused first) every fault marked,
/// then report — or "সব ঠিক" on the sound pole; then the reason.
Future<void> _playRight(WidgetTester t, M3InsulatorPatrolDeal deal, int i) async {
  final p = deal.poles[i];
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, M3InsulatorPatrolLines.coworker.right);
    await _pump(t, 2000);
  }
  for (final f in p.faulty) {
    await _mark(t, p.kind, f);
  }
  await t.tap(find.text(p.sound ? M3InsulatorPatrolLines.ok : M3InsulatorPatrolLines.report));
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i ${p.kind} ${p.faults}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'pole $i');
  await _pump(t, 700);
  await _pickRight(t, M3InsulatorPatrolLines.whyRight(p));
  await _pump(t, 4000);
}

M3InsulatorPatrolDeal _deal(int s) => m3InsulatorPatrolDeal(math.Random(s));

void main() {
  group('rules', () {
    test('deals: pin, disc and shackle once each; one sound pole; 1–2 faults on the others; he comes at any pole, the sound one too', () {
      final seen = <String>{};
      final calls = <int>{};
      var onSound = 0;
      final kinds = <M3InsulatorPatrolFault>{};
      var decoys = 0;
      for (var s = 0; s < 120; s++) {
        final d = _deal(s);
        expect(d.poles.map((p) => p.kind).toSet(), M3InsulatorPatrolKind.values.toSet());
        expect(d.poles.where((p) => p.sound).length, 1);
        for (final p in d.poles) {
          expect(p.units.length, M3InsulatorPatrolGeo.count(p.kind));
          if (!p.sound) expect(p.faulty.length, inInclusiveRange(1, 2));
          expect(p.faults.toSet().length, p.faults.length, reason: 'no fault twice on a pole');
          for (final u in p.units) {
            if (u.fault != null) expect(m3InsulatorPatrolFaultsFor(p.kind, u.body), contains(u.fault));
            if (u.body == M3InsulatorPatrolBody.polymer) expect(u.bad, isFalse);
          }
          if (p.hasPolymer || p.hasGlass) decoys++;
          kinds.addAll(p.faults);
        }
        if (d.poles[d.callAt].sound) onSound++;
        calls.add(d.callAt);
        seen.add(d.poles.map((p) => '${p.kind.name}${p.units.map((u) => '${u.body.index}${u.fault?.index}').join()}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(100), reason: 'every play is dealt fresh');
      expect(calls, {0, 1, 2});
      expect(onSound, inInclusiveRange(20, 70), reason: 'his arrival must not mean a faulty pole (about a third on the sound one)');
      expect(kinds, M3InsulatorPatrolFault.values.toSet(), reason: 'every fault turns up');
      expect(decoys, greaterThan(40));
    });

    M3InsulatorPatrolRun run1(M3InsulatorPatrolKind kind, Map<int, M3InsulatorPatrolFault> faults, {Map<int, M3InsulatorPatrolBody> bodies = const {}}) =>
        M3InsulatorPatrolRun(M3InsulatorPatrolDeal(poles: [
          M3InsulatorPatrolPole(id: 'x', kind: kind, units: [
            for (var i = 0; i < M3InsulatorPatrolGeo.count(kind); i++) M3InsulatorPatrolUnit(bodies[i] ?? M3InsulatorPatrolBody.porcelain, faults[i]),
          ]),
        ], callAt: 0));

    test('every fault marked, then report: right; the caught list names it', () {
      final a = run1(M3InsulatorPatrolKind.disc, {4: M3InsulatorPatrolFault.crack, 8: M3InsulatorPatrolFault.salt});
      expect(a.toggle(4), isTrue);
      expect(a.toggle(8), isTrue);
      expect(a.decide(report: true), isNull);
      expect(a.shown, isTrue);
      expect(a.thorough, isTrue);
      expect(a.caught, containsAll([M3InsulatorPatrolLines.caught[M3InsulatorPatrolFault.crack], M3InsulatorPatrolLines.caught[M3InsulatorPatrolFault.salt]]));
    });

    test('a mark can be cleared again', () {
      final a = run1(M3InsulatorPatrolKind.pin, {0: M3InsulatorPatrolFault.burnt});
      expect(a.toggle(1), isTrue);
      expect(a.toggle(1), isFalse);
      a.toggle(0);
      expect(a.decide(report: true), isNull);
    });

    test('"সব ঠিক" on a sound pole is right (a polymer or glass decoy left alone)', () {
      final a = run1(M3InsulatorPatrolKind.pin, {}, bodies: {1: M3InsulatorPatrolBody.polymer});
      expect(a.decide(report: false), isNull);
      expect(a.caught, containsAll([M3InsulatorPatrolLines.caughtSound, M3InsulatorPatrolLines.caughtDecoy]));
      expect(a.thorough, isTrue);
    });

    test('"সব ঠিক" on a faulty pole: the slip names the fault', () {
      for (final f in [M3InsulatorPatrolFault.sharp, M3InsulatorPatrolFault.bird]) {
        final a = run1(M3InsulatorPatrolKind.shackle, {2: f});
        expect(a.decide(report: false), M3InsulatorPatrolMistakes.missed(f));
        expect(a.slips, 1);
      }
    });

    test('a fault left unmarked, a sound insulator marked, a sound pole reported: slips', () {
      final a = run1(M3InsulatorPatrolKind.disc, {0: M3InsulatorPatrolFault.chipped, 5: M3InsulatorPatrolFault.burnt})..toggle(0);
      expect(a.decide(report: true), M3InsulatorPatrolMistakes.missedBurnt);
      final b = run1(M3InsulatorPatrolKind.disc, {3: M3InsulatorPatrolFault.shattered}, bodies: {3: M3InsulatorPatrolBody.glass, 4: M3InsulatorPatrolBody.glass, 5: M3InsulatorPatrolBody.glass})
        ..toggle(3)
        ..toggle(4);
      expect(b.decide(report: true), M3InsulatorPatrolMistakes.falseMark);
      final c = run1(M3InsulatorPatrolKind.pin, {}, bodies: {2: M3InsulatorPatrolBody.polymer})..toggle(2);
      expect(c.decide(report: true), M3InsulatorPatrolMistakes.falseAlarm);
    });

    test('a report with nothing marked is not scored: no mistake, the pole stays', () {
      final a = run1(M3InsulatorPatrolKind.pin, {1: M3InsulatorPatrolFault.crack});
      expect(a.decide(report: true), isNull);
      expect(a.shown, isFalse);
      expect(a.needless, 1);
      expect(a.slips, 0);
    });

    test('up the live pole on his say-so: deadly', () {
      final a = run1(M3InsulatorPatrolKind.pin, {1: M3InsulatorPatrolFault.chipped});
      final m = a.climb()!;
      expect(m.deadly, isTrue);
      expect(m, M3InsulatorPatrolMistakes.climbLive);
      expect(a.ended, isTrue);
      expect(a.decide(report: true), isNull, reason: 'nothing after the end');
    });

    test('the pure run: three slips leave 55 % (the page strikes out at the third, see the page test)', () {
      final d = M3InsulatorPatrolDeal(poles: [
        for (var i = 0; i < 3; i++)
          const M3InsulatorPatrolPole(id: 'x', kind: M3InsulatorPatrolKind.pin, units: [
            M3InsulatorPatrolUnit(M3InsulatorPatrolBody.porcelain, M3InsulatorPatrolFault.crack),
            M3InsulatorPatrolUnit(M3InsulatorPatrolBody.porcelain),
            M3InsulatorPatrolUnit(M3InsulatorPatrolBody.porcelain),
          ]),
      ], callAt: 0);
      final run = M3InsulatorPatrolRun(d);
      for (var i = 0; i < 3; i++) {
        expect(run.decide(report: false), M3InsulatorPatrolMistakes.missedCrack);
        run.next();
        expect(run.marks, isEmpty);
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
    });

    test('the guide reply after he is refused is neutral: no verdict before the decision', () {
      const held = M3InsulatorPatrolLines.callHeld;
      for (final w in ['রিপোর্ট', 'সব ঠিক', 'খারাপ', 'ভালো']) {
        expect(held.contains(w), isFalse, reason: w);
      }
      expect(M3InsulatorPatrolMistakes.climbLive.textBn, contains('শাটডাউন'), reason: 'the climb is deadly on any live pole, not only a faulty one');
    });

    test('the view: every insulator inside the lens, hit areas ≥ 48 and apart', () {
      for (final k in M3InsulatorPatrolKind.values) {
        final n = M3InsulatorPatrolGeo.count(k);
        for (var i = 0; i < n; i++) {
          final h = M3InsulatorPatrolGeo.unitHit(k, i);
          expect(h.width, greaterThanOrEqualTo(48));
          expect(h.height, greaterThanOrEqualTo(48));
          expect(M3InsulatorPatrolGeo.inLens(h.center), isTrue, reason: '$k $i');
          expect(M3InsulatorPatrolGeo.inLens(M3InsulatorPatrolGeo.unitBody(k, i).topCenter), isTrue, reason: '$k $i');
          for (var j = i + 1; j < n; j++) {
            expect(h.overlaps(M3InsulatorPatrolGeo.unitHit(k, j)), isFalse, reason: '$k $i/$j overlap');
          }
        }
      }
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; the mistakes', () {
      void lib(String name, List<String> right, List<String> wrong) {
        expectLibrary(name, right, wrong);
        expectSameLength(name, [...right, ...wrong]);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }

      for (final f in M3InsulatorPatrolFault.values) {
        final p = M3InsulatorPatrolPole(id: 'x', kind: M3InsulatorPatrolKind.disc, units: [
          M3InsulatorPatrolUnit(f == M3InsulatorPatrolFault.shattered ? M3InsulatorPatrolBody.glass : M3InsulatorPatrolBody.porcelain, f),
        ]);
        lib('why ${f.name}', M3InsulatorPatrolLines.whyRight(p), M3InsulatorPatrolLines.whyWrong(p));
        expect(M3InsulatorPatrolLines.caught[f], isNotNull);
      }
      const sound = M3InsulatorPatrolPole(id: 'x', kind: M3InsulatorPatrolKind.pin, units: [
        M3InsulatorPatrolUnit(M3InsulatorPatrolBody.polymer),
        M3InsulatorPatrolUnit(M3InsulatorPatrolBody.glass),
      ]);
      lib('why ok', M3InsulatorPatrolLines.whyRight(sound), M3InsulatorPatrolLines.whyWrong(sound));
      expect(M3InsulatorPatrolLines.whyRight(sound), containsAll([M3InsulatorPatrolLines.polymerWhy, M3InsulatorPatrolLines.glassWhy]));
      const plain = M3InsulatorPatrolPole(id: 'x', kind: M3InsulatorPatrolKind.shackle, units: [M3InsulatorPatrolUnit(M3InsulatorPatrolBody.porcelain)]);
      expect(M3InsulatorPatrolLines.whyRight(plain), M3InsulatorPatrolLines.okWhy, reason: 'the reason fits the pole');
      final cw = M3InsulatorPatrolLines.coworker;
      lib('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final keys = <String>{};
      for (final m in M3InsulatorPatrolMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('3.2/m3_insulator_patrol/'));
        expect(keys.add(m.key), isTrue, reason: m.key);
      }
      expect(M3InsulatorPatrolMistakes.all.where((m) => m.deadly), [M3InsulatorPatrolMistakes.climbLive]);
      expect(m3InsulatorPatrolPacks.keys, ['do_3_2_b']);
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
        // A seed where he does not come on the first pole.
        var seed = 0;
        while (_deal(seed).callAt == 0) {
          seed++;
        }
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3InsulatorPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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
        debugPrint('PERF m3_insulator_patrol ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      var seed = 0;
      while (_deal(seed).callAt == 0) {
        seed++;
      }
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3InsulatorPatrolPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3InsulatorPatrolLines.report), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3InsulatorPatrolLines.report), findsOneWidget);
      expect(find.text(M3InsulatorPatrolLines.ok), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      var seed = 0;
      while (_deal(seed).callAt == 0) {
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
      expect(lines.every((l) => l.contains(M3InsulatorPatrolLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: every fault marked and reported, the sound pole passed, the coworker refused → pass', (t) async {
      var seed = 1;
      while (!_deal(seed).poles.any((p) => p.faulty.length == 2)) {
        seed++;
      }
      final deal = _deal(seed);
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.2/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3InsulatorPatrolLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a report with nothing marked is not scored: no card, the guide asks for the marks', (t) async {
      var seed = 0;
      while (_deal(seed).callAt == 0) {
        seed++;
      }
      final c = await _open(t, seed);
      await t.tap(find.text(M3InsulatorPatrolLines.report));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(guideDirectorProvider).line, M3InsulatorPatrolLines.markFirst);
      expect(find.text(M3InsulatorPatrolLines.report), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the empty-report line is neutral: it never says a fault is there (same on the sound pole)', (t) async {
      expect(M3InsulatorPatrolLines.markFirst.contains('খারাপ'), isFalse);
      var seed = 0;
      while (_deal(seed).callAt == 0 || !_deal(seed).poles[0].sound) {
        seed++;
      }
      final c = await _open(t, seed);
      await t.tap(find.text(M3InsulatorPatrolLines.report));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, M3InsulatorPatrolLines.markFirst);
      await _close(t, c);
    });

    testWidgets('three slips strike out: the StruckOutCard, no fourth card', (t) async {
      var seed = 0;
      while (_deal(seed).callAt == 0) {
        seed++;
      }
      final deal = _deal(seed);
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        final p = deal.poles[i];
        if (i == deal.callAt) {
          expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
          await _pickRight(t, M3InsulatorPatrolLines.coworker.right);
          await _pump(t, 2000);
        }
        if (p.sound) {
          await _mark(t, p.kind, 0);
          await t.tap(find.text(M3InsulatorPatrolLines.report));
        } else {
          await t.tap(find.text(M3InsulatorPatrolLines.ok));
        }
        await _pump(t, 1000);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 1500);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M3InsulatorPatrolLines.report), findsNothing, reason: 'the play is over');
      expect(c.read(gameSaveProvider).rungProgress['3.2/do/1'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a fast call on his pole does not skip him: he comes first, then the call counts', (t) async {
      var seed = 0;
      while (_deal(seed).callAt != 0) {
        seed++;
      }
      final p = _deal(seed).poles[0];
      final c = await _open(t, seed, settleMs: 100);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet come by himself');
      await t.tap(find.text(M3InsulatorPatrolLines.ok));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the fast tap brings him in');
      expect(find.byType(MistakeCard), findsNothing, reason: 'the call waited for him');
      await _pickRight(t, M3InsulatorPatrolLines.coworker.right);
      await _pump(t, 2000);
      for (final f in p.faulty) {
        await _mark(t, p.kind, f);
      }
      await t.tap(find.text(p.sound ? M3InsulatorPatrolLines.ok : M3InsulatorPatrolLines.report));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('he also comes on the sound pole: refused, the guide stays neutral, then "সব ঠিক" is right', (t) async {
      var seed = 0;
      while (_deal(seed).callAt != 0 || !_deal(seed).poles[0].sound) {
        seed++;
      }
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes on a sound pole too');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M3InsulatorPatrolLines.coworker.right);
      await _pump(t, 2000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he has left');
      await t.tap(find.text(M3InsulatorPatrolLines.ok));
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: three taps on nothing sweep the hand over every insulator and both buttons', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      var seed = 0;
      while (_deal(seed).callAt == 0) {
        seed++;
      }
      final p = _deal(seed).poles[0];
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await t.tapAt(const Offset(330, 420) * _k);
        await _pump(t, 150);
      }
      final hint = t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      expect(hint.showing, isTrue);
      expect(hint.debugOptions, hasLength(M3InsulatorPatrolGeo.count(p.kind) + 2));
      await t.tapAt(const Offset(330, 420) * _k);
      await _pump(t, 200);
      expect(hint.showing, isFalse, reason: 'a touch hides it');
      await _close(t, c);
    });

    testWidgets('gesture hint: never while a slip card waits', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      var seed = 0;
      while (_deal(seed).callAt == 0 || _deal(seed).poles[0].sound) {
        seed++;
      }
      final c = await _open(t, seed);
      await t.tap(find.text(M3InsulatorPatrolLines.ok));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await _pump(t, 12000);
      final hint = t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      expect(hint.showing, isFalse, reason: 'no hint over a card');
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('"সব ঠিক" on a faulty pole: the slip card names the missed fault', (t) async {
      var seed = 0;
      while (_deal(seed).callAt == 0 || _deal(seed).poles[0].sound) {
        seed++;
      }
      final p0 = _deal(seed).poles[0];
      final c = await _open(t, seed);
      await t.tap(find.text(M3InsulatorPatrolLines.ok));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3InsulatorPatrolMistakes.missed(p0.units[p0.faulty.first].fault!).key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M3InsulatorPatrolLines.report), findsOneWidget, reason: 'the next pole');
      await _close(t, c);
    });

    testWidgets('up the live pole on his say-so: deadly — freeze first, then the card', (t) async {
      var seed = 0;
      while (_deal(seed).callAt != 0) {
        seed++;
      }
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M3InsulatorPatrolLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3InsulatorPatrolMistakes.climbLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
